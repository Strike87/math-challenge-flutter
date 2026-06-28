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
  });
}
