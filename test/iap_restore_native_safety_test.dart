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

  group('RT-052D/E IAP restore and native safety', () {
    test('manual restore ads_remove sets adsRemoved true', () async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);
      adapter.restoredPurchases = [
        const IapPurchase(
          productId: IapProducts.removeAdsId,
          status: IapPurchaseStatus.approved,
          transactionId: 'restore-ads',
        ),
      ];

      final restored = await state.restorePurchases();

      expect(restored, isTrue);
      expect(state.adsRemoved, isTrue);
      expect(state.coins, 0);
      expect(state.toastMessage, contains('Purchases restored'));
    });

    test('restore consumable coin products grants zero coins', () async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);
      adapter.restoredPurchases = [
        const IapPurchase(
          productId: IapProducts.largeId,
          status: IapPurchaseStatus.approved,
          transactionId: 'restore-large',
        ),
      ];

      final restored = await state.restorePurchases();

      expect(restored, isFalse);
      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, contains('No purchases'));
    });

    test('restore mixed purchases only restores ads_remove', () async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);
      adapter.restoredPurchases = [
        const IapPurchase(
          productId: IapProducts.smallId,
          status: IapPurchaseStatus.approved,
          transactionId: 'restore-small',
        ),
        const IapPurchase(
          productId: IapProducts.removeAdsId,
          status: IapPurchaseStatus.approved,
          transactionId: 'restore-ads',
        ),
      ];

      final restored = await state.restorePurchases();

      expect(restored, isTrue);
      expect(state.adsRemoved, isTrue);
      expect(state.coins, 0);
    });

    test('auto-restore on load reapplies ads_remove ownership', () async {
      final adapter = _FakeIapPurchaseAdapter(
        restoredPurchases: [
          const IapPurchase(
            productId: IapProducts.removeAdsId,
            status: IapPurchaseStatus.approved,
            transactionId: 'launch-restore-ads',
          ),
        ],
      );

      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      expect(adapter.restoreCalls, 1);
      expect(state.adsRemoved, isTrue);
      expect(Storage.getBool('mc_adsRemoved', false), isTrue);
    });

    test('already-owned ads_remove maps to restore success', () async {
      final adapter = _FakeIapPurchaseAdapter(
        buyError: const IapException(IapErrorCode.alreadyOwned),
      );
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.removeAds);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(adapter.buyCalls, [IapProducts.removeAds]);
      expect(state.adsRemoved, isTrue);
      expect(state.coins, 0);
      expect(state.toastMessage, contains('Purchases restored'));
    });

    test('user-cancelled purchase grants nothing and shows no scary error',
        () async {
      final adapter = _FakeIapPurchaseAdapter(
        buyError: const IapException(IapErrorCode.userCancelled),
      );
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.small);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(adapter.buyCalls, [IapProducts.small]);
      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, isEmpty);
    });

    test('billing unavailable grants nothing and reports billing unavailable',
        () async {
      final adapter = _FakeIapPurchaseAdapter(
        buyError: const IapException(IapErrorCode.billingUnavailable),
      );
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.medium);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, contains('billing is not available'));
    });

    test('network error grants nothing and reports retry-style message',
        () async {
      final adapter = _FakeIapPurchaseAdapter(
        buyError: const IapException(IapErrorCode.network),
      );
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.large);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, contains('Connection lost'));
    });

    test(
        'developer or unknown error grants nothing and reports generic failure',
        () async {
      final adapter = _FakeIapPurchaseAdapter(
        buyError: const IapException(IapErrorCode.developer),
      );
      final state = await _makeState(adapter: adapter);
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.small);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, contains('Purchase failed'));
    });

    test('native store unavailable grants nothing', () async {
      final state = await _makeState(
        adapter: const UnavailableIapPurchaseAdapter(),
      );
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.small);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, contains('billing is not available'));
    });

    test('simulated dev purchase path cannot run on native release', () async {
      final state = await _makeState(
        adapter: const DevIapPurchaseAdapter(isNativeRelease: true),
      );
      addTearDown(state.dispose);

      state.beginIapPurchase(IapProducts.small);
      await state
          .submitAdultGateAnswer(state.adultGateChallenge!.answer.toString());

      expect(state.coins, 0);
      expect(state.adsRemoved, isFalse);
      expect(state.toastMessage, contains('billing is not available'));
    });
  });
}

Future<GameState> _makeState({
  required IapPurchaseAdapter adapter,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
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
    adultGateFactory: () => const AdultGateChallenge(40, 2),
  );
  await state.load();
  state.toastMessage = '';
  state.toastVisible = false;
  return state;
}

class _FakeIapPurchaseAdapter implements IapPurchaseAdapter {
  _FakeIapPurchaseAdapter({
    List<IapPurchase> restoredPurchases = const [],
    this.buyError,
  }) : restoredPurchases = [...restoredPurchases];

  List<IapPurchase> restoredPurchases;
  final IapException? buyError;
  final List<IapProduct> buyCalls = [];
  final List<IapPurchase> completeCalls = [];
  int restoreCalls = 0;

  @override
  Future<void> buyProduct(IapProduct product) async {
    buyCalls.add(product);
    final error = buyError;
    if (error != null) throw error;
  }

  @override
  Future<void> completePurchase(IapPurchase purchase) async {
    completeCalls.add(purchase);
  }

  @override
  Future<List<IapPurchase>> restorePurchases() async {
    restoreCalls++;
    return restoredPurchases;
  }
}
