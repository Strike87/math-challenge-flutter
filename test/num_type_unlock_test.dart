import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
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

  Future<GameState> makeState([Map<String, Object> prefs = const {}]) async {
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
    final state = GameState(settings: settings, audio: AudioService(settings));
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  GameState makeSecondState(SettingsService settings) {
    final state = GameState(settings: settings, audio: AudioService(settings));
    addTearDown(state.dispose);
    return state;
  }

  group('RT-012 number type unlocks', () {
    test('natural numbers are unlocked by default and cost nothing', () async {
      final state = await makeState({'mc_coins': 25});

      await state.selectNumType('natural');

      expect(state.numType, NumberType.natural);
      expect(state.coins, 25);
      expect(state.currentScreen, GameScreen.config);
    });

    test('integers cost exactly 500 coins, unlock once, and persist', () async {
      final state = await makeState({'mc_coins': 750});

      await state.selectNumType('integers');

      expect(state.numType, NumberType.integers);
      expect(state.coins, 250);
      expect(state.numTypeUnlocked['integers'], 1);
      expect(Storage.getInt('mc_coins', -1), 250);
      expect(Storage.getInt('mc_numTypeUnlocked_integers', 0), 1);

      await state.selectNumType('integers');

      expect(state.coins, 250, reason: 'owned integers must not charge again');

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      expect(reloaded.coins, 250);
      expect(reloaded.numTypeUnlocked['integers'], 1);
    });

    test(
        'rationals and decimals cost exactly 1200 coins, unlock once, and persist',
        () async {
      final state = await makeState({'mc_coins': 1500});

      await state.selectNumType('rationals');

      expect(state.numType, NumberType.rationals);
      expect(state.coins, 300);
      expect(state.numTypeUnlocked['rationals'], 1);
      expect(Storage.getInt('mc_coins', -1), 300);
      expect(Storage.getInt('mc_numTypeUnlocked_rationals', 0), 1);

      await state.selectNumType('rationals');

      expect(state.coins, 300, reason: 'owned rationals must not charge again');

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      expect(reloaded.coins, 300);
      expect(reloaded.numTypeUnlocked['rationals'], 1);
    });

    test('insufficient coins do not unlock integers or make balance negative',
        () async {
      final state = await makeState({'mc_coins': 499});

      await state.selectNumType('integers');

      expect(state.numTypeUnlocked['integers'], 0);
      expect(state.coins, 499);
      expect(Storage.getInt('mc_coins', -1), 499);
      expect(Storage.getInt('mc_numTypeUnlocked_integers', 0), 0);
      expect(state.numType, NumberType.natural);
      expect(state.currentScreen, GameScreen.menu);
      expect(state.numTypeUnlockFeedback, 'integers');
      expect(state.toastVisible, isFalse);
    });

    test('insufficient coins do not unlock rationals or make balance negative',
        () async {
      final state = await makeState({'mc_coins': 1199});

      await state.selectNumType('rationals');

      expect(state.numTypeUnlocked['rationals'], 0);
      expect(state.coins, 1199);
      expect(Storage.getInt('mc_coins', -1), 1199);
      expect(Storage.getInt('mc_numTypeUnlocked_rationals', 0), 0);
      expect(state.numType, NumberType.natural);
      expect(state.currentScreen, GameScreen.menu);
      expect(state.numTypeUnlockFeedback, 'rationals');
      expect(state.toastVisible, isFalse);
    });

    test('missing ownership stays locked until exact balance is available',
        () async {
      final state = await makeState({'mc_coins': 499});
      state
        ..numTypeUnlocked = {}
        ..currentScreen = GameScreen.numType;

      await state.selectNumType('integers');

      expect(state.numTypeUnlocked, isEmpty);
      expect(state.coins, 499);
      expect(Storage.getInt('mc_coins', -1), 499);
      expect(state.currentScreen, GameScreen.numType);
      expect(state.numTypeUnlockFeedback, 'integers');
      expect(state.toastVisible, isFalse);

      state.coins = 500;
      await state.selectNumType('integers');

      expect(state.numTypeUnlocked['integers'], 1);
      expect(state.coins, 0);
      expect(Storage.getInt('mc_numTypeUnlocked_integers', 0), 1);
      expect(state.currentScreen, GameScreen.config);
      expect(state.toastMessage, '-500 🪙');
    });

    test('reset and migration contracts remain compatible with unlock flags',
        () async {
      final state = await makeState({
        'mc_numTypeUnlocked': '{"integers":true,"rationals":true}',
      });

      expect(state.numTypeUnlocked['integers'], 1);
      expect(state.numTypeUnlocked['rationals'], 1);
      expect(Storage.getInt('mc_numTypeUnlocked_integers', 0), 1);
      expect(Storage.getInt('mc_numTypeUnlocked_rationals', 0), 1);

      await state.resetAllData();

      expect(state.numTypeUnlocked['integers'], 0);
      expect(state.numTypeUnlocked['rationals'], 0);
      expect(Storage.containsKey('mc_numTypeUnlocked_integers'), isFalse);
      expect(Storage.containsKey('mc_numTypeUnlocked_rationals'), isFalse);
    });
  });
}
