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
    addTearDown(state.dispose);
    return state;
  }

  num wrongAnswer(GameState state) =>
      state.rt.q!.choices.firstWhere((choice) => choice != state.rt.q!.ans);

  Future<void> expectQuitCancelsDelayedLoss(
    WidgetTester tester,
    Future<void> Function(GameState) triggerLoss,
  ) async {
    final state = await makeState();
    await triggerLoss(state);
    final gamesBeforeQuit = state.gamesPlayed;
    final adGamesBeforeQuit = state.adGameCount;

    await state.quitToMenu();
    await tester.pump(const Duration(seconds: 1));

    expect(state.currentScreen, GameScreen.menu);
    expect(state.currentModal, GameModal.none);
    expect(state.rt.state, 'idle');
    expect(state.gamesPlayed, gamesBeforeQuit);
    expect(state.adGameCount, adGamesBeforeQuit);
    expect(state.debugPendingInterstitialAd, isFalse);
    expect(Storage.getInt('mc_gamesPlayed', -1), gamesBeforeQuit);
    expect(Storage.getInt('mc_adGameCount', -1), adGamesBeforeQuit);
  }

  group('RT-002 question timer', () {
    test('blitz and combo use global timers', () async {
      final blitz = await makeState();
      blitz.players = 1;
      blitz.mode = GameMode.blitz;
      blitz.rt.challenge = Operation.addition;

      blitz.startGame();

      expect(
          blitz.debugQuestionTimerDurationMs(), GameConfig.blitzTimerDefault);
      expect(blitz.rt.qTimerLimit, GameConfig.blitzTimerDefault ~/ 1000);

      final combo = await makeState();
      combo.players = 1;
      combo.mode = GameMode.combo;
      combo.rt.challenge = Operation.addition;

      combo.startGame();

      expect(
          combo.debugQuestionTimerDurationMs(), GameConfig.comboTimerDefault);
      expect(combo.rt.qTimerLimit, GameConfig.comboTimerDefault ~/ 1000);
    });

    test('blitz and combo global timers keep running after an answer',
        () async {
      final blitz = await makeState();
      blitz.players = 1;
      blitz.mode = GameMode.blitz;
      blitz.rt.challenge = Operation.addition;
      blitz.startGame();
      final blitzTimer = blitz.rt.timer;
      final blitzDuration = blitz.rt.timerDurationMs;

      blitz.onAnswer(blitz.rt.q!.choices.first);

      expect(blitz.rt.timer, same(blitzTimer));
      expect(blitz.rt.timer?.isActive, isTrue);
      expect(blitz.rt.timerDurationMs, blitzDuration);

      final combo = await makeState();
      combo.players = 1;
      combo.mode = GameMode.combo;
      combo.rt.challenge = Operation.addition;
      combo.startGame();
      final comboTimer = combo.rt.timer;
      final comboDuration = combo.rt.timerDurationMs;

      combo.onAnswer(combo.rt.q!.choices.first);

      expect(combo.rt.timer, same(comboTimer));
      expect(combo.rt.timer?.isActive, isTrue);
      expect(combo.rt.timerDurationMs, comboDuration);
    });

    test('standard timer freezes immediately after an answer', () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.adaptive = false;
      state.diff = Difficulty.easy;
      state.rt.challenge = Operation.addition;
      state.startGame();

      expect(state.debugQuestionTimerDurationMs(), 10000);
      state.onAnswer(state.rt.q!.choices.first);

      expect(state.rt.timer?.isActive, isFalse);
      expect(state.rt.timerStart, 0);
      expect(state.debugQuestionTimerDurationMs(), lessThanOrEqualTo(10000));
      expect(state.debugQuestionTimerDurationMs(), greaterThan(0));
    });

    test('uses adaptive generated difficulty instead of setup difficulty',
        () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.adaptive = true;
      state.diff = Difficulty.easy;
      state.rt.challenge = Operation.addition;
      state.skillMap[Operation.addition.name]!.mastery = 93;
      state.adaptLvl = 0;
      state.adaptLvlRaw = 0;

      state.startGame();

      expect(state.rt.q!.diff, Difficulty.insane);
      expect(
        state.debugQuestionTimerDurationMs(),
        GameConfig.timerBaseMs[Difficulty.insane.name],
      );
      expect(state.debugQuestionTimerDurationMs(), isNot(10000));
    });

    test(
        'timer can be longer than setup difficulty when generated diff is easy',
        () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.adaptive = true;
      state.diff = Difficulty.hard;
      state.rt.challenge = Operation.addition;
      state.skillMap[Operation.addition.name]!.mastery = 20;
      state.adaptLvl = 0;
      state.adaptLvlRaw = 0;

      state.startGame();

      expect(state.rt.q!.diff, Difficulty.easy);
      expect(
        state.debugQuestionTimerDurationMs(),
        GameConfig.timerBaseMs[Difficulty.easy.name],
      );
      expect(state.debugQuestionTimerDurationMs(), isNot(6000));
    });

    test('non-adaptive per-question timer falls back to setup difficulty',
        () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.adaptive = false;
      state.diff = Difficulty.hard;
      state.rt.challenge = Operation.addition;
      state.skillMap[Operation.addition.name]!.mastery = 93;
      state.adaptLvl = 0;
      state.adaptLvlRaw = 0;

      state.startGame();

      expect(state.rt.q!.diff, Difficulty.hard);
      expect(
        state.debugQuestionTimerDurationMs(),
        GameConfig.timerBaseMs[Difficulty.hard.name],
      );
    });

    test('non-adaptive easy timer is not reduced by saved adaptive level',
        () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.adaptive = false;
      state.diff = Difficulty.easy;
      state.rt.challenge = Operation.addition;
      state.adaptLvl = 3;
      state.adaptLvlRaw = 3;

      state.startGame();

      expect(state.debugQuestionTimerDurationMs(), 10000);
    });

    test('survival uses phase timer instead of generated difficulty timer',
        () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.survival;
      state.adaptive = true;
      state.diff = Difficulty.hard;
      state.rt.challenge = Operation.addition;
      state.skillMap[Operation.addition.name]!.mastery = 93;
      state.adaptLvl = 0;
      state.adaptLvlRaw = 0;

      state.startGame();

      expect(state.rt.q!.diff, Difficulty.easy);
      expect(state.debugQuestionTimerDurationMs(), GameConfig.phaseTimesMs[0]);
    });

    test('master and daily boss use stage or boss timer', () async {
      final master = await makeState();
      master.startMasterMode();
      master.startGame();

      expect(
        master.debugQuestionTimerDurationMs(),
        GameConfig.masterLevels.first.time * 1000,
      );

      final boss = await makeState();
      boss.dailyBoss = GameConfig.dailyBosses.first;
      boss.startDailyBoss();
      boss.startGame();

      expect(
        boss.debugQuestionTimerDurationMs(),
        GameConfig.dailyBosses.first.time * 1000,
      );
    });

    test('each master stage uses its own source contract', () async {
      final baseOps = {
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
      };
      final baseNumTypes = {
        NumberType.natural,
        NumberType.integers,
        NumberType.rationals,
      };

      for (final entry in GameConfig.masterLevels.asMap().entries) {
        final stageIndex = entry.key;
        final level = entry.value;
        final state = await makeState();
        state.diff = Difficulty.easy;
        state.numType = NumberType.natural;
        state.rt.challenge = Operation.addition;
        state.debugSetMasterStage(stageIndex);

        state.startGame();

        expect(
          state.rt.maxTurns,
          level.goal,
          reason: '${level.name} must use stage.goal',
        );
        expect(
          state.debugQuestionTimerDurationMs(),
          level.time * 1000,
          reason: '${level.name} must use stage.time',
        );
        expect(
          state.rt.q!.diff,
          Difficulty.fromString(level.diff),
          reason: '${level.name} must use stage.diff',
        );
        expect(
          state.rt.q!.boss,
          level.boss,
          reason: '${level.name} must use stage.boss',
        );

        final expectedType = Operation.fromString(level.type);
        if (expectedType == Operation.mixed) {
          expect(
            baseOps,
            contains(state.rt.q!.type),
            reason: '${level.name} mixed stage must resolve to a base op',
          );
        } else {
          expect(
            state.rt.q!.type,
            expectedType,
            reason: '${level.name} must use stage.type',
          );
        }

        if (level.numType == 'mixed') {
          expect(
            baseNumTypes,
            contains(state.rt.q!.numType),
            reason:
                '${level.name} mixed number type must resolve to a base type',
          );
        } else {
          expect(
            state.rt.q!.numType,
            NumberType.fromString(level.numType),
            reason: '${level.name} must use stage.numType',
          );
        }
      }
    });

    test('restarting an existing question timer reuses qTimerLimit', () async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.adaptive = true;
      state.diff = Difficulty.easy;
      state.rt.challenge = Operation.addition;
      state.skillMap[Operation.addition.name]!.mastery = 93;
      state.adaptLvl = 0;
      state.adaptLvlRaw = 0;

      state.startGame();
      expect(state.rt.q!.diff, Difficulty.insane);
      expect(state.debugQuestionTimerDurationMs(), 4000);

      state.diff = Difficulty.easy;
      state.rt.qTimerLimit = 7;
      state.debugRestartQuestionTimer(resumeElapsedMs: 2000);

      expect(state.rt.qTimerLimit, 7);
      expect(state.debugQuestionTimerDurationMs(), 5000);
    });

    testWidgets('delayed-loss regression: sudden death cannot end after quit',
        (tester) async {
      await expectQuitCancelsDelayedLoss(tester, (state) async {
        state.players = 1;
        state.mode = GameMode.death;
        state.rt.challenge = Operation.addition;
        state.startGame();
        state.onAnswer(wrongAnswer(state));
      });
    });

    testWidgets('delayed-loss regression: active loss keeps feedback delay',
        (tester) async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.death;
      state.rt.challenge = Operation.addition;
      state.startGame();
      state.onAnswer(wrongAnswer(state));

      await tester.pump(const Duration(milliseconds: 599));
      expect(state.rt.gameActive, isTrue);
      expect(state.gamesPlayed, 0);

      await tester.pump(const Duration(milliseconds: 1));
      expect(state.rt.gameActive, isFalse);
      expect(state.rt.state, 'ended');
      expect(state.currentModal, GameModal.win);
      expect(state.gamesPlayed, 1);
      expect(state.adGameCount, 1);
      state.dispose();
    });

    testWidgets('delayed-loss regression: survival cannot end after quit',
        (tester) async {
      await expectQuitCancelsDelayedLoss(tester, (state) async {
        state.players = 1;
        state.mode = GameMode.survival;
        state.rt.challenge = Operation.addition;
        state.startGame();
        state.rt.survivalLives = 1;
        state.onAnswer(wrongAnswer(state));
      });
    });

    testWidgets('delayed-loss regression: Master cannot end after quit',
        (tester) async {
      await expectQuitCancelsDelayedLoss(tester, (state) async {
        state.startMasterMode();
        state.startGame();
        for (var attempt = 0; attempt < 3; attempt++) {
          state.onAnswer(wrongAnswer(state));
          if (attempt < 2) {
            await tester.pump(const Duration(milliseconds: 1300));
          }
        }
      });
    });

    testWidgets('delayed-loss regression: Daily Boss cannot end after quit',
        (tester) async {
      await expectQuitCancelsDelayedLoss(tester, (state) async {
        state.dailyBoss = GameConfig.dailyBosses.first;
        state.startDailyBoss();
        state.startGame();
        state.rt.dailyBossLives = 1;
        state.onAnswer(wrongAnswer(state));
      });
    });

    testWidgets('delayed-loss regression: old loss cannot end a new game',
        (tester) async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.death;
      state.rt.challenge = Operation.addition;
      state.startGame();
      state.onAnswer(wrongAnswer(state));

      state.mode = GameMode.standard;
      state.startGame();
      await tester.pump(const Duration(seconds: 1));

      expect(state.currentScreen, GameScreen.game);
      expect(state.currentModal, GameModal.none);
      expect(state.rt.gameActive, isTrue);
      expect(state.rt.state, 'playing');
      expect(state.gamesPlayed, 0);
      expect(state.adGameCount, 0);
      expect(state.debugPendingInterstitialAd, isFalse);
      expect(Storage.getInt('mc_gamesPlayed', -1), 0);
      expect(Storage.getInt('mc_adGameCount', -1), 0);
      state.dispose();
    });

    testWidgets('delayed-loss regression: reset cancels pending loss',
        (tester) async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.death;
      state.rt.challenge = Operation.addition;
      state.startGame();
      state.onAnswer(wrongAnswer(state));

      await state.resetAllData();
      await tester.pump(const Duration(seconds: 1));

      expect(state.currentScreen, GameScreen.menu);
      expect(state.currentModal, GameModal.none);
      expect(state.gamesPlayed, 0);
      expect(state.adGameCount, 0);
      expect(Storage.getInt('mc_gamesPlayed', -1), -1);
      expect(Storage.getInt('mc_adGameCount', -1), -1);
      state.dispose();
    });

    testWidgets('delayed-loss regression: dispose cancels pending loss',
        (tester) async {
      final state = await makeState();
      state.players = 1;
      state.mode = GameMode.death;
      state.rt.challenge = Operation.addition;
      state.startGame();
      state.onAnswer(wrongAnswer(state));

      state.dispose();
      await tester.pump(const Duration(seconds: 1));

      expect(state.gamesPlayed, 0);
      expect(state.adGameCount, 0);
      expect(state.currentModal, GameModal.none);
    });
  });
}
