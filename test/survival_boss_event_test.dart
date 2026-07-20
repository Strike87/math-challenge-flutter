import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/celebration.dart';
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

  Future<GameState> makeState() async {
    SharedPreferences.setMockInitialValues({});
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
    state.dailyChallengeIds = ['blitz_15', 'streak_7', 'division_10'];
    return state;
  }

  Future<void> answerCorrect(GameState state, WidgetTester tester) async {
    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1300));
  }

  group('RT-003 survival boss event', () {
    testWidgets('valid survival scoring follows executable reference parity',
        (tester) async {
      final state = await makeState();
      try {
        state.players = 1;
        state.mode = GameMode.survival;
        state.rt.challenge = Operation.addition;
        state.startGame();

        for (var i = 0; i < 4; i++) {
          await answerCorrect(state, tester);
        }

        final scoreBefore = state.p[1].score;
        final coinsBefore = state.coins;
        expect(state.p[1].doubleActive, isFalse);
        state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch -
            const Duration(seconds: 1).inMilliseconds;

        state.onAnswer(state.rt.q!.ans);

        // Executable-reference parity: valid Survival uses timed scoring; the
        // prose phase-bonus documentation conflicts with executable behavior.
        const baseScore = 10;
        const remainingTimeBonus = 14;
        const speedBonus = 2;
        const streakMultiplier = 1.5;
        final scoreDelta = state.p[1].score - scoreBefore;
        expect(state.rt.comboMultiplier, streakMultiplier);
        expect(GameConfig.scoreBase, baseScore);
        expect(
          scoreDelta,
          ((baseScore + remainingTimeBonus + speedBonus) * streakMultiplier)
              .round(),
        );
        expect(
          scoreDelta,
          isNot(((baseScore + GameConfig.phaseBonus[1] + 3) * streakMultiplier)
              .round()),
        );

        // Coin expectation is independent of the score calculation above.
        final coinDelta = state.coins - coinsBefore;
        expect(coinDelta, 1 + 1 + GameConfig.streakCoins[0]);

        await tester.pump(const Duration(milliseconds: 1300));
      } finally {
        state.dispose();
      }
    });

    testWidgets('fires every 10 correct without breaking phase progression',
        (tester) async {
      final state = await makeState();
      try {
        state.players = 1;
        state.mode = GameMode.survival;
        state.rt.challenge = Operation.addition;
        state.startGame();

        for (var i = 0; i < 4; i++) {
          await answerCorrect(state, tester);
        }
        expect(state.rt.survivalCorrect, 4);
        expect(state.rt.survivalPhase, 0);
        expect(state.celebration.kind, isNot(CelebrationKind.bossClear));

        await answerCorrect(state, tester);
        expect(state.rt.survivalCorrect, 5);
        expect(state.rt.survivalPhase, 1);
        expect(state.celebration.kind, isNot(CelebrationKind.bossClear));

        for (var i = 0; i < 4; i++) {
          await answerCorrect(state, tester);
        }
        expect(state.rt.survivalCorrect, 9);
        expect(state.rt.survivalPhase, 1);

        final coinsBeforeTen = state.coins;
        state.onAnswer(state.rt.q!.ans);

        expect(state.rt.survivalCorrect, 10);
        expect(state.rt.survivalPhase, 2);
        expect(
          state.coins - coinsBeforeTen,
          1 + GameConfig.survivalBossReward + 1 + GameConfig.streakCoins[1],
        );
        expect(state.reactionPill, '👹 BOSS DOWN! +5🪙');
        expect(GameConfig.survivalBosses, contains(state.bigEmoji));
        expect(state.celebration.kind, CelebrationKind.bossClear);
        expect(GameConfig.survivalBosses, contains(state.celebration.emoji));
        expect(state.celebration.message, 'BOSS DOWN! +5🪙');

        final firstBossEventId = state.celebration.id;
        await tester.pump(const Duration(milliseconds: 1300));

        for (var i = 0; i < 9; i++) {
          await answerCorrect(state, tester);
        }
        final coinsBeforeTwenty = state.coins;
        state.onAnswer(state.rt.q!.ans);

        expect(state.rt.survivalCorrect, 20);
        expect(state.rt.survivalPhase, 4);
        expect(
          state.coins - coinsBeforeTwenty,
          1 + GameConfig.survivalBossReward + 1 + GameConfig.streakCoins[2],
        );
        expect(state.celebration.kind, CelebrationKind.bossClear);
        expect(state.celebration.id, greaterThan(firstBossEventId));

        await tester.pump(const Duration(milliseconds: 1300));
      } finally {
        state.dispose();
      }
    });
  });
}
