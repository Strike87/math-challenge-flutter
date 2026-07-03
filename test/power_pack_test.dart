import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
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
    final state = GameState(
      settings: settings,
      audio: AudioService(settings),
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  group('Power Pack', () {
    test('purchase stores five of each power-up for the next game', () async {
      final state = await makeState({'mc_coins': 600});
      final pack = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_powerups');

      await state.buyShopItem(pack);

      expect(state.coins, 100);
      final bonus = jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
      expect(bonus['time'], 5);
      expect(bonus['fifty'], 5);
      expect(bonus['double'], 5);
      expect(bonus['shield'], 5);
      expect(bonus['freeze'], 5);
      expect(bonus['switch'], 5);
    });

    test('next eligible single-player game consumes the bonus once', () async {
      final state = await makeState({
        'mc_puBonus': jsonEncode({
          'time': 5,
          'fifty': 5,
          'double': 5,
          'shield': 5,
          'freeze': 5,
          'switch': 5,
        }),
      });

      state.players = 1;
      state.mode = GameMode.standard;
      state.rt.challenge = Operation.addition;
      state.startGame();

      final counts = <PowerUp, int>{};
      for (final pu in state.p[1].pups) {
        counts[pu] = (counts[pu] ?? 0) + 1;
      }

      for (final pu in PowerUp.values) {
        expect(counts[pu], 5, reason: '${pu.name} should be bonus 5');
      }

      final cleared = jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
      expect(cleared.values.every((value) => value == 0), isTrue);
    });
  });

  group('Daily coin bonus', () {
    test('grants +20 coins once per day', () async {
      final state = await makeState();
      final bonus = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_daily_bonus');

      await state.buyShopItem(bonus);

      expect(state.coins, GameState.dailyBonusCoins);
      expect(state.isDailyCoinsClaimedToday, isTrue);

      await state.buyShopItem(bonus);

      expect(state.coins, GameState.dailyBonusCoins);
      expect(state.toastMessage, 'Daily bonus already claimed');
    });
  });

  group('Daily challenges', () {
    test('increment progress pays a reward only once', () async {
      final state = await makeState();
      state.dailyChallengeIds = ['blitz_15'];

      for (var i = 0; i < 15; i++) {
        state.debugUpdateDailyProgress('blitz_15');
      }

      expect(state.dailyProgress['blitz_15'], 15);
      expect(state.dailyCompleted['blitz_15'], isTrue);
      expect(state.coins, 50);

      state.debugUpdateDailyProgress('blitz_15');

      expect(state.dailyProgress['blitz_15'], 15);
      expect(state.coins, 50);
    });

    test('absolute progress pays a reward only once', () async {
      final state = await makeState();
      state.dailyChallengeIds = ['streak_7'];

      state.debugUpdateDailyProgressAbsolute('streak_7', 7);

      expect(state.dailyProgress['streak_7'], 7);
      expect(state.dailyCompleted['streak_7'], isTrue);
      expect(state.coins, 30);

      state.debugUpdateDailyProgressAbsolute('streak_7', 20);

      expect(state.dailyProgress['streak_7'], 7);
      expect(state.coins, 30);
    });

    test('completing all three active challenges unlocks Daily Grind',
        () async {
      final state = await makeState();
      state.dailyChallengeIds = ['blitz_15', 'streak_7', 'division_10'];

      state.debugUpdateDailyProgressAbsolute('blitz_15', 15);
      state.debugUpdateDailyProgressAbsolute('streak_7', 7);
      state.debugUpdateDailyProgressAbsolute('division_10', 10);

      expect(state.achievements['daily_grind'], isTrue);
    });

    test('stale saved daily challenges reset on a new day', () async {
      final state = await makeState({
        'mc_dailyChallenges': jsonEncode({
          'date': '2000-01-01',
          'challenges': ['blitz_15', 'streak_7', 'division_10'],
        }),
        'mc_dailyProgress': jsonEncode({
          'blitz_15': {'current': 15, 'completed': true},
        }),
      });

      expect(state.activeDailyChallenges.length, 3);
      expect(state.dailyProgress, isEmpty);
      expect(state.dailyCompleted, isEmpty);
    });
  });

  group('Reaction feedback', () {
    test('wrong answers use the original rotating wrong reaction copy',
        () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.rt.challenge = Operation.addition;
      state.startGame();

      final q = state.rt.q!;
      final wrongChoice =
          q.choices.firstWhere((choice) => (choice - q.ans).abs() >= 1e-9);

      state.onAnswer(wrongChoice);

      expect(
        GameConfig.wrongRx.any(state.reactionPill.startsWith),
        isTrue,
      );
      expect(state.bigEmoji, isNot('😢'));
    });
  });
}
