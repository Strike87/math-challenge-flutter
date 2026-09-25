import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/features/game_brain/integration/adaptive_shadow_integration.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_coordinator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TargetClashRunConfig config(Difficulty difficulty) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  Future<GameState> makeState({
    QuestionGenerator? generator,
    Random? random,
    AdaptiveShadowEvaluator? adaptiveShadowEvaluator,
    ContextEvidenceShadowObserver? contextObserver,
    P1F01IntegrityStore? p1F01IntegrityStore,
    P1F01StudyCoordinator? p1F01StudyCoordinator,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final state = GameState(
      settings: SettingsService()
        ..load(
          dark: false,
          sound: false,
          vibration: false,
          dyslexia: false,
          colorblind: false,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 1,
        ),
      audio: _NoOpAudioService(),
      questionGenerator: generator ?? _TargetClashQuestionGenerator(),
      runRandom: random,
      adaptiveShadowEvaluator: adaptiveShadowEvaluator,
      contextEvidenceShadowObserver: contextObserver,
      p1F01IntegrityStore: p1F01IntegrityStore,
      p1F01StudyCoordinator: p1F01StudyCoordinator,
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  void answer(GameState state, {bool correct = true}) {
    final question = state.targetClashQuestion!;
    state.onTargetClashAnswer(
      correct
          ? question.correctAnswer
          : PresentationAnswer.values.firstWhere(
              (answer) => answer != question.correctAnswer,
            ),
    );
  }

  void complete(GameState state) {
    while (state.rt.gameActive) {
      answer(state);
    }
  }

  test('all valid Target Clash snapshots start with a typed timer', () async {
    for (final difficulty in [
      Difficulty.easy,
      Difficulty.medium,
      Difficulty.hard,
    ]) {
      final state = await makeState();
      state.debugStartTargetClashForTest(config(difficulty));

      expect(state.rt.q, isNull);
      expect(state.targetClashQuestion, isNotNull);
      expect(state.rt.isWarmUp, isFalse);
      expect(state.activeAdaptive, isFalse);
      expect(state.activeRunSnapshot!.timingStyle, TimingStyle.perQuestion);
      expect(state.rt.timer!.isActive, isTrue);
    }
  });

  test('quit clears Target Clash runtime but terminal state remains until quit',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final timer = state.rt.timer;
    await state.quitToMenu();

    expect(state.activeRunSnapshot, isNull);
    expect(state.isTargetClash, isFalse);
    expect(state.targetClashRuntime, isNull);
    expect(state.targetClashQuestion, isNull);
    expect(state.targetClashTarget, isNull);
    expect(state.rt.gameActive, isFalse);
    expect(state.rt.accepting, isFalse);
    expect(timer!.isActive, isFalse);
  });

  test('typed answers and timeout resolve exactly one token', () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final initialTarget = state.targetClashTarget;

    state.onAnswer(1);
    expect(state.targetClashRuntime!.resolvedCount, 0);
    answer(state);
    final nextTimer = state.rt.timer;
    expect(state.targetClashRuntime!.resolvedCount, 1);
    answer(state);
    expect(state.targetClashRuntime!.resolvedCount, 2);
    state.debugTimeoutForTest();

    expect(state.targetClashRuntime!.resolvedCount, 3);
    expect(state.targetClashRuntime!.score, greaterThanOrEqualTo(0));
    expect(state.targetClashRuntime!.combo, 0);
    expect(state.targetClashRuntime!.phase, TargetClashPhase.ordinaryStage2);
    expect(state.targetClashTarget, isNot(initialTarget));
    expect(state.rt.timer, isNot(same(nextTimer)));
    state.debugTimeoutForTest();
    expect(state.targetClashRuntime!.resolvedCount, 4);
  });

  test('timeout retains a non-boundary target and opens a fresh timer',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.medium));
    final target = state.targetClashTarget;
    final timer = state.rt.timer;
    state.debugTimeoutForTest();

    expect(state.targetClashRuntime!.resolvedCount, 1);
    expect(state.targetClashRuntime!.score, 0);
    expect(state.targetClashRuntime!.combo, 0);
    expect(state.targetClashTarget, target);
    expect(state.rt.timer, isNot(same(timer)));
    expect(timer!.isActive, isFalse);
  });

  test('a stale Target Clash timeout token cannot resolve the next question',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final staleToken = state.debugCurrentQuestionToken;
    answer(state);
    final resolvedBeforeStaleTimeout = state.targetClashRuntime!.resolvedCount;

    state.debugTimeoutForTokenForTest(staleToken);

    expect(state.targetClashRuntime!.resolvedCount, resolvedBeforeStaleTimeout);
  });

  test('Triple consumes one injected permutation and does not reshuffle',
      () async {
    const expected = [
      [
        PresentationAnswer.lessThan,
        PresentationAnswer.equalTo,
        PresentationAnswer.greaterThan
      ],
      [
        PresentationAnswer.lessThan,
        PresentationAnswer.greaterThan,
        PresentationAnswer.equalTo
      ],
      [
        PresentationAnswer.equalTo,
        PresentationAnswer.lessThan,
        PresentationAnswer.greaterThan
      ],
      [
        PresentationAnswer.equalTo,
        PresentationAnswer.greaterThan,
        PresentationAnswer.lessThan
      ],
      [
        PresentationAnswer.greaterThan,
        PresentationAnswer.lessThan,
        PresentationAnswer.equalTo
      ],
      [
        PresentationAnswer.greaterThan,
        PresentationAnswer.equalTo,
        PresentationAnswer.lessThan
      ],
    ];
    for (var index = 0; index < expected.length; index++) {
      final random = _FixedRandom(index);
      final state = await makeState(random: random);
      state.debugStartTargetClashForTest(config(Difficulty.medium));
      for (var i = 0; i < 5; i++) {
        answer(state);
      }
      final stage2Target = state.targetClashTarget;
      answer(state);

      final runtime = state.targetClashRuntime!;
      expect(runtime.phase, TargetClashPhase.triple);
      expect(random.nextIntCalls, 1);
      expect(runtime.currentTarget, stage2Target);
      expect(runtime.preparedStage!.questions.map((q) => q.correctAnswer),
          expected[index]);
      answer(state);
      expect(random.nextIntCalls, 1);
    }
  });

  test('Easy skips Triple and each profile completes at its frozen count',
      () async {
    final easy = await makeState();
    easy.debugStartTargetClashForTest(config(Difficulty.easy));
    for (var i = 0; i < 6; i++) {
      answer(easy);
    }
    expect(easy.targetClashRuntime!.phase, TargetClashPhase.boss);

    for (final expected in [
      (Difficulty.easy, 12),
      (Difficulty.medium, 16),
      (Difficulty.hard, 17),
    ]) {
      final state = await makeState();
      state.debugStartTargetClashForTest(config(expected.$1));
      complete(state);
      expect(state.targetClashRuntime!.finished, isTrue);
      expect(state.targetClashRuntime!.resolvedCount, expected.$2);
    }
  });

  test('an early Boss defeat resolves directly into a prepared Final',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final boss = TargetClashQuestionGenerator(
      questionGenerator: _TargetClashQuestionGenerator(),
    ).prepareStage(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.integers,
      requests: TargetClashRuntimeState.bossRequests(Difficulty.easy),
    );
    state.debugInstallTargetClashRuntimeForTest(
      TargetClashRuntimeState.debugBossStateForTest(boss, bossHealth: 1),
    );
    final oldTimer = state.rt.timer;

    answer(state);

    final runtime = state.targetClashRuntime!;
    expect(runtime.phase, TargetClashPhase.finalTarget);
    expect(runtime.phase, isNot(TargetClashPhase.technicalFailure));
    expect(runtime.generationFailure, isNull);
    expect(runtime.bossesDefeated, 1);
    expect(runtime.bossQuestionsResolved, 1);
    expect(runtime.stageQuestionIndex, 0);
    expect(runtime.currentQuestion, isNotNull);
    expect(runtime.preparedStage, isNot(same(boss.stage)));
    expect(runtime.preparedStage!.questions, hasLength(3));
    expect(state.rt.timer, isNot(same(oldTimer)));
    expect(state.rt.timer!.isActive, isTrue);
  });

  test('an early Boss defeat fails closed when Final preparation fails',
      () async {
    final state = await makeState(
      generator: _FailAtBoundaryQuestionGenerator(_FailurePoint.stage2),
    );
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final boss = TargetClashQuestionGenerator(
      questionGenerator: _TargetClashQuestionGenerator(),
    ).prepareStage(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.integers,
      requests: TargetClashRuntimeState.bossRequests(Difficulty.easy),
    );
    state.debugInstallTargetClashRuntimeForTest(
      TargetClashRuntimeState.debugBossStateForTest(boss, bossHealth: 1),
    );

    answer(state);

    expect(state.targetClashRuntime!.phase, TargetClashPhase.technicalFailure);
    expect(state.adGameCount, 0);
  });

  test('completed Target Clash runtime and snapshot remain until quit',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(state);
    final timer = state.rt.timer;

    expect(state.activeRunSnapshot, isNotNull);
    expect(state.isTargetClash, isTrue);
    expect(state.targetClashRuntime, isNotNull);
    expect(state.targetClashRuntime!.finished, isTrue);
    expect(state.targetClashQuestion, isNull);
    expect(state.targetClashTarget, isNull);
    expect(state.rt.gameActive, isFalse);
    expect(state.rt.accepting, isFalse);
    expect(timer!.isActive, isFalse);

    await state.quitToMenu();

    expect(state.activeRunSnapshot, isNull);
    expect(state.isTargetClash, isFalse);
    expect(state.targetClashRuntime, isNull);
    expect(state.targetClashQuestion, isNull);
    expect(state.targetClashTarget, isNull);
    expect(state.rt.gameActive, isFalse);
    expect(state.rt.accepting, isFalse);
    expect(timer.isActive, isFalse);
  });

  test('Hard Triple Fever consumes its next three terminal resolutions',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.hard));
    for (var i = 0; i < 9; i++) {
      answer(state);
    }
    expect(state.targetClashRuntime!.phase, TargetClashPhase.boss);
    expect(state.targetClashRuntime!.feverRemaining, 3);
    state.debugTimeoutForTest();
    expect(state.targetClashRuntime!.feverRemaining, 2);
    answer(state);
    expect(state.targetClashRuntime!.feverRemaining, 1);
    answer(state);
    expect(state.targetClashRuntime!.feverRemaining, 0);
    expect(state.targetClashRuntime!.phase,
        isNot(TargetClashPhase.technicalFailure));
  });

  test('technical generation failures do not record normal completion',
      () async {
    for (final failure in _FailurePoint.values) {
      final state = await makeState(
        generator: _FailAtBoundaryQuestionGenerator(failure),
      );
      state.debugStartTargetClashForTest(config(Difficulty.medium));
      while (state.rt.gameActive) {
        answer(state);
      }
      expect(state.targetClashRuntime!.finished, isFalse, reason: failure.name);
      expect(
          state.targetClashRuntime!.phase, TargetClashPhase.technicalFailure);
      expect(state.targetClashQuestion, isNull);
      expect(state.adGameCount, 0);
      expect(state.gamesPlayed, 0);
      expect(state.cloudDirty, isFalse);
    }
  });

  test('successful Target Clash records only its completed-game ad cadence',
      () async {
    final state = await makeState();
    final before = (
      games: state.gamesPlayed,
      cloud: state.cloudDirty,
      coins: state.coins,
      highScores: List.of(state.highScores),
      achievements: Map.of(state.achievements),
      skills: Map.of(state.skillMap),
      ads: state.adGameCount,
    );
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    complete(state);
    await Future<void>.delayed(Duration.zero);

    expect(state.gamesPlayed, before.games);
    expect(state.cloudDirty, before.cloud);
    expect(state.coins, before.coins);
    expect(state.highScores, before.highScores);
    expect(state.achievements, before.achievements);
    expect(state.skillMap, before.skills);
    expect(state.adGameCount, before.ads + 1);
    state.debugTimeoutForTest();
    expect(state.adGameCount, before.ads + 1);
  });

  test('Target Clash bypasses GameBrain and replay creates a fresh runtime',
      () async {
    var adaptiveCalls = 0;
    var contextCalls = 0;
    final state = await makeState(
      adaptiveShadowEvaluator: (_, __) {
        adaptiveCalls++;
        return const AdaptiveIntegrationDecision.noAdaptation();
      },
      contextObserver: (_) => contextCalls++,
    );
    final run = config(Difficulty.medium);
    state.debugStartTargetClashForTest(run);
    final oldRuntime = state.targetClashRuntime;
    final oldTimer = state.rt.timer;
    answer(state);
    expect(state.debugHasContextEvidenceObserver, isFalse);
    expect(state.debugQuestionExperienceObservationCount, 0);
    expect(state.debugContextEvidenceObservationCount, 0);
    expect(state.debugP1F01IntegrityRunEligible, isFalse);
    expect(adaptiveCalls, 0);
    expect(contextCalls, 0);
    await state.replayGame();
    expect(state.activeRunSnapshot!.targetClashConfig, same(run));
    expect(state.targetClashRuntime, isNot(same(oldRuntime)));
    expect(oldTimer!.isActive, isFalse);
    expect(state.targetClashRuntime!.phase, TargetClashPhase.ordinaryStage1);
  });

  test('Target Clash does not open or close a P1 window', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('tc02d_p1_');
    final integrity = P1F01IntegrityStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}${Platform.pathSeparator}integrity.db',
    );
    final coordinator = P1F01StudyCoordinator.production(
      integrityStore: integrity,
    );
    final state = await makeState(
      p1F01IntegrityStore: integrity,
      p1F01StudyCoordinator: coordinator,
    );
    addTearDown(() async {
      await coordinator.close();
      await integrity.close();
      await directory.delete(recursive: true);
    });
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    state.debugStartGameFromSnapshot(GameRunSnapshot(
      runType: GameRunType.normal,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 2,
    ));
    expect(state.debugP1F01IntegrityRunEligible, isTrue);
    expect(state.debugP1BeginWindowCallCount, 1);
    expect(state.debugP1FinishWindowCallCount, 0);

    state.debugStartTargetClashForTest(config(Difficulty.easy));
    await state.debugDrainP1Study();
    final normalFinal = await state.debugP1F01IntegritySnapshot();
    expect(normalFinal, isNotNull);
    final normalSequence = normalFinal!.localWindowSequence;
    expect(state.debugP1F01IntegrityRunEligible, isFalse);
    expect(state.debugP1BeginWindowCallCount, 1);
    expect(state.debugP1FinishWindowCallCount, 1);

    complete(state);
    await state.debugDrainP1Study();
    expect((await state.debugP1F01IntegritySnapshot())!.localWindowSequence,
        normalSequence);
    expect(state.debugP1FinishWindowCallCount, 1);
    await state.quitToMenu();
    expect(state.debugP1FinishWindowCallCount, 1);
  });

  test('normal Standard numeric answers still resolve', () async {
    final state = await makeState(generator: QuestionGenerator(rng: Random(1)));
    state.debugStartGameFromSnapshot(GameRunSnapshot(
      runType: GameRunType.normal,
      mode: GameMode.standard,
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      answerStyle: AnswerStyle.choice4,
      players: 1,
      questionTarget: 1,
    ));
    final total = state.rt.totalTurns;
    state.onAnswer(state.rt.q!.ans);
    expect(state.rt.totalTurns, greaterThan(total));
  });
}

enum _FailurePoint { initial, stage2, triple, boss, finalTarget }

final class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;
  int nextIntCalls = 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) {
    nextIntCalls++;
    expect(max, 6);
    return value;
  }
}

class _TargetClashQuestionGenerator extends QuestionGenerator {
  _TargetClashQuestionGenerator() : super(rng: Random(1));

  int _anchors = 0;
  int _direct = 0;
  _FailurePoint? get failurePoint => null;

  bool get _failAnchor => switch (failurePoint) {
        _FailurePoint.initial => _anchors >= 1,
        _FailurePoint.stage2 => _anchors >= 2,
        _FailurePoint.boss => _anchors >= 3,
        _FailurePoint.finalTarget => _anchors >= 4,
        _ => false,
      };

  bool get _failDirect => failurePoint == _FailurePoint.triple && _direct >= 5;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) {
    _anchors++;
    if (_failAnchor) {
      return Question(
        type: type,
        key: 'invalid:$_anchors',
        text: 'invalid',
        ans: 0,
        choices: const [0],
      );
    }
    return _question(type, diff, numType, 10 + _anchors);
  }

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) {
    _direct++;
    return _failDirect ? null : _question(type, diff, numType, result);
  }

  Question _question(
    Operation type,
    Difficulty diff,
    NumberType numType,
    num result,
  ) {
    final fact = MathFact(
      operation: type,
      left: result,
      right: 0,
      result: result,
      representation: FactRepresentation.direct,
      difficulty: diff,
      numberType: numType,
    );
    return Question(
      type: type,
      key: '$type:$result',
      text: '$result + 0',
      ans: result,
      choices: [result],
      diff: diff,
      numType: numType,
      fact: fact,
    );
  }
}

final class _FailAtBoundaryQuestionGenerator
    extends _TargetClashQuestionGenerator {
  _FailAtBoundaryQuestionGenerator(this._point);

  final _FailurePoint _point;

  @override
  _FailurePoint get failurePoint => _point;
}

final class _NoOpAudioService implements AudioService {
  @override
  int get debugTonePlayCount => 0;
  @override
  int get debugVibrationCount => 0;
  @override
  Future<void> init() async {}
  @override
  Future<void> playCorrect() async {}
  @override
  Future<void> playPowerUp() async {}
  @override
  Future<void> playStart() async {}
  @override
  Future<void> playTones(List<List<double>> tones) async {}
  @override
  Future<void> playWrong() async {}
  @override
  void vibrate(int ms) {}
  @override
  void vibrateCorrect() {}
  @override
  void vibratePattern(List<int> pattern) {}
  @override
  void vibratePowerUp() {}
  @override
  void vibrateWrong() {}
}
