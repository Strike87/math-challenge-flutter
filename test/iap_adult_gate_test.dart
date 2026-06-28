import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
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

  group('RT-052A IAP adult gate', () {
    for (final product in IapProducts.all) {
      testWidgets('${product.productId} opens adult gate before IAP adapter',
          (tester) async {
        final adapter = _FakeIapPurchaseAdapter();
        final state = await _makeState(adapter: adapter);

        state.showModal(GameModal.coinShop);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        await tester.tap(find.text('Buy'));
        await tester.pumpAndSettle();
        final productCard = find.byKey(Key('iapProduct_${product.productId}'));
        await tester.ensureVisible(productCard);
        await tester.tap(productCard);
        await tester.pump();

        expect(state.currentModal, GameModal.adultGate);
        expect(state.pendingIapProduct?.productId, product.productId);
        expect(adapter.buyCalls, isEmpty);
      });
    }

    testWidgets('wrong answer does not call adapter', (tester) async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);

      state.beginIapPurchase(IapProducts.small);
      await tester.pumpWidget(_modalHost(state));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('adultGateAnswerField')),
        '1',
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(adapter.buyCalls, isEmpty);
      expect(state.currentModal, GameModal.adultGate);
      expect(state.adultGateError, isNotEmpty);
      expect(find.text('Not quite. Please try again.'), findsOneWidget);
    });

    testWidgets('cancel closes gate without calling adapter', (tester) async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(adapter: adapter);

      state.beginIapPurchase(IapProducts.medium);
      await tester.pumpWidget(_modalHost(state));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(adapter.buyCalls, isEmpty);
      expect(state.currentModal, GameModal.none);
      expect(state.pendingIapProduct, isNull);
      expect(state.adultGateChallenge, isNull);
    });

    testWidgets(
        'correct answer calls adapter exactly once for selected product',
        (tester) async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(
        adapter: adapter,
        challengeFactory: () => const AdultGateChallenge(47, 18),
      );

      state.beginIapPurchase(IapProducts.large);
      await tester.pumpWidget(_modalHost(state));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('adultGateAnswerField')),
        '65',
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(adapter.buyCalls, hasLength(1));
      expect(adapter.buyCalls.single.productId, IapProducts.largeId);
      expect(state.currentModal, GameModal.none);
      expect(state.pendingIapProduct, isNull);
      state.dispose();
    });

    testWidgets('successful gate grants no coins and does not remove ads',
        (tester) async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(
        prefs: {'mc_coins': 7},
        adapter: adapter,
        challengeFactory: () => const AdultGateChallenge(20, 22),
      );

      state.beginIapPurchase(IapProducts.removeAds);
      await tester.pumpWidget(_modalHost(state));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('adultGateAnswerField')),
        '42',
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(adapter.buyCalls, hasLength(1));
      expect(state.coins, 7);
      expect(state.adsRemoved, isFalse);
      state.dispose();
    });

    test('new purchase attempt gets a fresh adult-gate question', () async {
      final adapter = _FakeIapPurchaseAdapter();
      final sequence = _ChallengeSequence([
        const AdultGateChallenge(11, 22),
        const AdultGateChallenge(33, 44),
      ]);
      final state = await _makeState(
        adapter: adapter,
        challengeFactory: sequence.next,
      );

      state.beginIapPurchase(IapProducts.small);
      final first = state.adultGateChallenge;
      state.cancelAdultGate();
      state.beginIapPurchase(IapProducts.medium);
      final second = state.adultGateChallenge;

      expect(first?.prompt, '11 + 22');
      expect(second?.prompt, '33 + 44');
      expect(first?.prompt, isNot(second?.prompt));
      expect(adapter.buyCalls, isEmpty);
    });

    testWidgets('local coin purchases do not show adult gate', (tester) async {
      final adapter = _FakeIapPurchaseAdapter();
      final state = await _makeState(
        prefs: {'mc_coins': 700},
        adapter: adapter,
      );

      state.showModal(GameModal.coinShop);
      await tester.pumpWidget(_modalHost(state));
      await tester.pump();
      await tester.tap(find.text('Dragon'));
      await tester.pump();

      expect(state.currentModal, GameModal.coinShop);
      expect(state.pendingIapProduct, isNull);
      expect(state.adultGateChallenge, isNull);
      expect(adapter.buyCalls, isEmpty);
      expect(state.shopOwned, contains('av_dragon'));
    });
  });
}

Future<GameState> _makeState({
  Map<String, Object> prefs = const {},
  required _FakeIapPurchaseAdapter adapter,
  AdultGateChallenge Function()? challengeFactory,
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
    adultGateFactory:
        challengeFactory ?? () => const AdultGateChallenge(47, 18),
  );
  await state.load();
  return state;
}

Widget _modalHost(GameState state, {Size size = const Size(390, 700)}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameState>.value(value: state),
      ChangeNotifierProvider<SettingsService>.value(value: state.settings),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const Scaffold(
          body: Stack(children: [ModalRouter()]),
        ),
      ),
    ),
  );
}

class _FakeIapPurchaseAdapter implements IapPurchaseAdapter {
  final List<IapProduct> buyCalls = [];
  int restoreCalls = 0;

  @override
  Future<void> buyProduct(IapProduct product) async {
    buyCalls.add(product);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }
}

class _ChallengeSequence {
  _ChallengeSequence(this._items);

  final List<AdultGateChallenge> _items;
  int _index = 0;

  AdultGateChallenge next() {
    return _items[_index++];
  }
}
