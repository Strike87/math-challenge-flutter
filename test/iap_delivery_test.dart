import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  group('RT-052B/C IAP delivery', () {
    test('product constants expose the exact source ids and option ids', () {
      expect(IapProducts.small.productId, '100_coins');
      expect(IapProducts.small.purchaseOptionId, '100-coins-buy');
      expect(IapProducts.medium.productId, '500_coins');
      expect(IapProducts.medium.purchaseOptionId, '500-coins-buy');
      expect(IapProducts.large.productId, '1200_coins');
      expect(IapProducts.large.purchaseOptionId, '1200-coins-buy');
      expect(IapProducts.removeAds.productId, 'ads_remove');
      expect(IapProducts.removeAds.purchaseOptionId, 'ads-remove-buy');

      expect(IapProducts.byProductId('100_coins'), same(IapProducts.small));
      expect(IapProducts.byProductId('500_coins'), same(IapProducts.medium));
      expect(IapProducts.byProductId('1200_coins'), same(IapProducts.large));
      expect(
        IapProducts.byProductId('ads_remove'),
        same(IapProducts.removeAds),
      );
    });

    for (final testCase in [
      (product: IapProducts.small, expectedCoins: 100),
      (product: IapProducts.medium, expectedCoins: 550),
      (product: IapProducts.large, expectedCoins: 1400),
    ]) {
      test(
          'approved ${testCase.product.productId} grants ${testCase.expectedCoins} coins and stores tx before completion',
          () async {
        late GameState state;
        final snapshots = <String>[];
        final adapter = _FakeIapPurchaseAdapter(
          onComplete: (purchase) {
            snapshots.add(
              '${state.coins}:${state.adsRemoved}:${state.debugIapDeliveredTxs.contains(purchase.transactionKey)}',
            );
          },
        );
        state = await _makeState(adapter: adapter);
        addTearDown(state.dispose);

        final purchase = IapPurchase(
          productId: testCase.product.productId,
          status: IapPurchaseStatus.approved,
          transactionId: 'tx-${testCase.product.productId}',
        );

        final delivered = await state.handleIapPurchase(purchase);

        expect(delivered, isTrue);
        expect(state.coins, testCase.expectedCoins);
        expect(state.adsRemoved, isFalse);
        expect(
          state.debugIapDeliveredTxs,
          contains(purchase.transactionKey),
        );
        expect(adapter.completeCalls, hasLength(1));
        expect(adapter.completeCalls.single.transactionKey,
            purchase.transactionKey);
        expect(snapshots, [
          '${testCase.expectedCoins}:false:true',
        ]);
      });
    }

    test('ads_remove sets adsRemoved and persists across reload', () async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      final purchase = IapPurchase(
        productId: IapProducts.removeAdsId,
        status: IapPurchaseStatus.approved,
        transactionId: 'tx-remove-ads',
      );

      final delivered = await state.handleIapPurchase(purchase);

      expect(delivered, isTrue);
      expect(state.adsRemoved, isTrue);
      expect(state.coins, 0);
      expect(adapter.completeCalls, hasLength(1));
      expect(
        state.debugIapDeliveredTxs,
        contains(purchase.transactionKey),
      );

      final reloaded = await _makeState(
        adapter: _FakeIapPurchaseAdapter(),
        resetPrefs: false,
      );
      addTearDown(reloaded.dispose);

      expect(reloaded.adsRemoved, isTrue);
      expect(reloaded.coins, 0);
      expect(
        reloaded.debugIapDeliveredTxs,
        contains(purchase.transactionKey),
      );
    });

    test('duplicate approved transactions do not double-grant but still finish',
        () async {
      late GameState state;
      final adapter = _FakeIapPurchaseAdapter(
        onComplete: (purchase) {
          expect(
            state.debugIapDeliveredTxs,
            contains(purchase.transactionKey),
          );
        },
      );
      state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      final purchase = IapPurchase(
        productId: IapProducts.smallId,
        status: IapPurchaseStatus.approved,
        transactionId: 'tx-duplicate',
      );

      final first = await state.handleIapPurchase(purchase);
      final second = await state.handleIapPurchase(purchase);

      expect(first, isTrue);
      expect(second, isFalse);
      expect(state.coins, 100);
      expect(state.adsRemoved, isFalse);
      expect(state.debugIapDeliveredTxs, hasLength(1));
      expect(adapter.completeCalls, hasLength(2));
      expect(
        adapter.completeCalls.every(
          (call) => call.transactionKey == purchase.transactionKey,
        ),
        isTrue,
      );
    });

    test('unknown approved products are completed but grant nothing', () async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      final purchase = IapPurchase(
        productId: 'mystery_product',
        status: IapPurchaseStatus.approved,
        transactionId: 'tx-unknown',
      );

      final delivered = await state.handleIapPurchase(purchase);

      expect(delivered, isFalse);
      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.debugIapDeliveredTxs, isEmpty);
      expect(adapter.completeCalls, hasLength(1));
    });

    for (final status in [
      IapPurchaseStatus.pending,
      IapPurchaseStatus.failed,
      IapPurchaseStatus.cancelled,
    ]) {
      test('non-approved $status purchases grant nothing and are not finished',
          () async {
        final adapter = _FakeIapPurchaseAdapter();
        final state = await _makeState(adapter: adapter);
        addTearDown(state.dispose);

        final purchase = IapPurchase(
          productId: IapProducts.smallId,
          status: status,
          transactionId: 'tx-${status.name}',
        );

        final delivered = await state.handleIapPurchase(purchase);

        expect(delivered, isFalse);
        expect(state.coins, 0);
        expect(state.adsRemoved, isFalse);
        expect(state.debugIapDeliveredTxs, isEmpty);
        expect(adapter.completeCalls, isEmpty);
      });
    }
  });
}

Future<GameState> _makeState({
  required _FakeIapPurchaseAdapter adapter,
  Map<String, Object> prefs = const {},
  bool resetPrefs = true,
}) async {
  if (resetPrefs) {
    SharedPreferences.setMockInitialValues(prefs);
  }
  await Storage.init();

  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: true,
      reduceMotion: true,
      animSpeed: 1,
    );

  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    iapAdapter: adapter,
  );
  await state.load();
  return state;
}

class _FakeIapPurchaseAdapter implements IapPurchaseAdapter {
  _FakeIapPurchaseAdapter({this.onComplete});

  final void Function(IapPurchase purchase)? onComplete;
  final List<IapProduct> buyCalls = [];
  final List<IapPurchase> completeCalls = [];
  int restoreCalls = 0;

  @override
  String? priceFor(String productId) => 'Store price';

  @override
  Future<void> buyProduct(IapProduct product) async {
    buyCalls.add(product);
  }

  @override
  Future<void> completePurchase(IapPurchase purchase) async {
    completeCalls.add(purchase);
    onComplete?.call(purchase);
  }

  @override
  Future<List<IapPurchase>> restorePurchases() async {
    restoreCalls++;
    return const [];
  }
}
