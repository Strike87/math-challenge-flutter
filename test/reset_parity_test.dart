import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
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

  group('RT-006 reset parity', () {
    test('Reset All Data removes current, legacy, settings, ad, and IAP keys',
        () async {
      final seededPrefs = {
        for (final key in GameState.debugResetStorageKeys) key: 'seed-$key',
      };
      SharedPreferences.setMockInitialValues(seededPrefs);
      await Storage.init();

      final settings = SettingsService()
        ..load(
          dark: true,
          sound: false,
          vibration: false,
          dyslexia: true,
          colorblind: true,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 0.3,
        );
      final state =
          GameState(settings: settings, audio: AudioService(settings));
      addTearDown(state.dispose);

      state
        ..coins = 500
        ..gamesPlayed = 12
        ..selectedAnswerStyle = AnswerStyle.trueFalse
        ..adaptLvlRaw = 6.5
        ..adaptLvl = 7
        ..achievements = {'first_win': true}
        ..highScores = [
          HighScore(
            name: 'Player 1',
            score: 999,
            mode: GameMode.standard,
            date: '2026-06-27',
          ),
        ]
        ..skillMap = {
          Operation.addition.name: SkillData(correct: 9, count: 10),
        }
        ..numTypeUnlocked = {'integers': 1, 'rationals': 1}
        ..loginStreak = 4
        ..dailyProgress = {'streak_star': 7}
        ..dailyCompleted = {'streak_star': true}
        ..dailyChallengeIds = ['streak_star']
        ..shopOwned = ['avatar_dragon']
        ..unlockedAvatars = ['🐲']
        ..unlockedHats = ['🎩']
        ..adsRemoved = true
        ..currentScreen = GameScreen.game
        ..currentModal = GameModal.settings
        ..isDailyBossClaimedToday = true;
      state.p[1].name = 'Reset Me';
      state.p[1].avatar = '🐲';
      state.rt.answerStyle = AnswerStyle.trueFalse;

      await state.resetAllData();

      for (final key in GameState.debugResetStorageKeys) {
        expect(Storage.containsKey(key), isFalse, reason: '$key was not reset');
      }

      expect(state.coins, 0);
      expect(state.gamesPlayed, 0);
      expect(state.selectedAnswerStyle, AnswerStyle.choice4);
      expect(state.operationQuestProgress.stars, isEmpty);
      expect(state.rt.answerStyle, AnswerStyle.choice4);
      expect(state.adaptLvlRaw, 0);
      expect(state.adaptLvl, 0);
      expect(state.achievements.values.any((unlocked) => unlocked), isFalse);
      expect(state.highScores, isEmpty);
      expect(state.skillMap[Operation.addition.name]!.correct, 0);
      expect(state.numTypeUnlocked, {'integers': 0, 'rationals': 0});
      expect(state.loginStreak, 0);
      expect(state.dailyProgress, isEmpty);
      expect(state.dailyCompleted, isEmpty);
      expect(state.dailyChallengeIds, isEmpty);
      expect(state.shopOwned, isEmpty);
      expect(state.unlockedAvatars, isEmpty);
      expect(state.unlockedHats, isEmpty);
      expect(state.adsRemoved, isFalse);
      expect(state.p[1].name, 'Player 1');
      expect(state.p[1].avatar.storageEmoji, '🐶');
      expect(state.currentScreen, GameScreen.menu);
      expect(state.currentModal, GameModal.none);
      expect(state.isDailyCoinsClaimedToday, isFalse);
      expect(state.isDailyBossClaimedToday, isFalse);

      expect(settings.dark, isFalse);
      expect(settings.sound, isTrue);
      expect(settings.vibration, isTrue);
      expect(settings.dyslexia, isFalse);
      expect(settings.colorblind, isFalse);
      expect(settings.lowPerf, isFalse);
      expect(settings.reduceMotion, isFalse);
      expect(settings.animSpeed, 1.0);
    });
  });
}
