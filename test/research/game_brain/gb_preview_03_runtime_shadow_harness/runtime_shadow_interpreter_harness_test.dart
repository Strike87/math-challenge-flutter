import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../research/game_brain/gb_preview_01_simplify_01/minimal_preview_interpreter.dart';
import '../../../../research/game_brain/gb_preview_01_simplify_01/preview_observation_evidence_v2.dart';
import '../../../../research/game_brain/gb_preview_02_shadow_interpreter_bridge/shadow_preview_evidence_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const bridge = ShadowPreviewEvidenceBridge();
  const interpreter = MinimalPreviewInterpreter();

  test('1: a supported run starts with no runtime observations', () async {
    final state = await _state();

    expect(state.debugContextEvidenceObservations, isEmpty);
  });

  test('2: a runtime observation reaches the bridge and interpreter', () async {
    final state = await _state();
    await _answer(state, correct: true);

    final result = interpreter.interpret(
      bridge.fromObservations(state.debugContextEvidenceObservations),
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(
        result.interpretationState, PreviewInterpretationState.observational);
    _expectNoAuthority(result);
  });

  test('3: skips are excluded from exclusive runtime aggregate counts',
      () async {
    final state = await _state();
    await _answer(state, correct: true);
    await _answer(state, correct: false);
    final countBeforeSkip = state.debugContextEvidenceObservationCount;
    await _skip(state);
    expect(state.debugContextEvidenceObservationCount, countBeforeSkip);
    state.debugTimeoutForTest();

    expect(state.debugContextEvidenceObservations, hasLength(3));
    final aggregate = bridge
        .fromObservations(state.debugContextEvidenceObservations)
        .aggregate
        .value!;
    expect(aggregate.evidenceCount, 3);
    expect(aggregate.correctCount, 1);
    expect(aggregate.incorrectCount, 1);
    expect(aggregate.timeoutCount, 1);
  });

  test('4: factual runtime context survives end-to-end', () async {
    final state = await _state();
    await _answer(state, correct: true);

    final context = bridge
        .fromObservations(state.debugContextEvidenceObservations)
        .factualContext
        .value!;
    expect(context, contains('operation=addition'));
    expect(context, contains('numberType=natural'));
    expect(context, contains('representation=directNumeric'));
    expect(context, contains('difficulty=easy'));
  });

  test('5: caller-declared temporal split reports a higher recent observation',
      () async {
    final state = await _state();
    await _answer(state, correct: false);
    await _answer(state, correct: true);
    final observations = state.debugContextEvidenceObservations;

    final result = interpreter.interpret(
      bridge.fromTemporalObservations(
        earlier: [observations.first],
        recent: [observations.last],
      ),
      PreviewInterpretationRequest.observedTemporalDifference,
    );

    expect(
        result.interpretationState, PreviewInterpretationState.observational);
    expect(result.temporalDifference, ObservedTemporalDifference.recentHigher);
    expect(result.explanation.toLowerCase(), isNot(contains('reliable')));
  });

  test(
      '6: runtime temporal evidence does not make reliable improvement available',
      () async {
    final state = await _state();
    await _answer(state, correct: false);
    await _answer(state, correct: true);
    final observations = state.debugContextEvidenceObservations;

    final result = interpreter.interpret(
      bridge.fromTemporalObservations(
        earlier: [observations.first],
        recent: [observations.last],
      ),
      PreviewInterpretationRequest.reliableImprovement,
    );

    expect(result.interpretationState, PreviewInterpretationState.notEvaluable);
    expect(result.missingEvidence.single, contains('ValidatedChangeReceipt'));
    _expectNoAuthority(result);
  });

  test('7: debug observations are an immutable snapshot', () async {
    final state = await _state();
    await _answer(state, correct: true);
    final observations = state.debugContextEvidenceObservations;

    expect(() => observations.clear(), throwsUnsupportedError);
    expect(state.debugContextEvidenceObservationCount, 1);
    expect(state.debugContextEvidenceObservations, hasLength(1));
  });

  test('8: bridge and interpretation do not affect canonical runtime state',
      () async {
    final state = await _state();
    await _answer(state, correct: true);
    final score = state.p[1].score;
    final skill = state.skillMap[Operation.addition.name]!;
    final mastery = skill.mastery;
    final adaptiveLevel = state.adaptLvlRaw;
    final question = state.rt.q;
    final difficulty = state.diff;

    final evidence =
        bridge.fromObservations(state.debugContextEvidenceObservations);
    interpreter.interpret(
      evidence,
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(state.p[1].score, score);
    expect(skill.mastery, mastery);
    expect(state.adaptLvlRaw, adaptiveLevel);
    expect(state.rt.q, same(question));
    expect(state.diff, difficulty);
  });

  test('9: replay retains the canonical empty run-local memory lifecycle',
      () async {
    final state = await _state();
    await _answer(state, correct: true);
    expect(state.debugContextEvidenceObservations, hasLength(1));

    await state.replayGame();
    state.rt.timer?.cancel();

    expect(state.debugContextEvidenceObservations, isEmpty);
  });

  test('A: the passive hook automatically drives preview interpretation',
      () async {
    var calls = 0;
    PreviewInterpretationResult? result;
    final state = await _state(observer: (observations) {
      calls++;
      result = interpreter.interpret(
        bridge.fromObservations(observations),
        PreviewInterpretationRequest.boundedObservationSummary,
      );
    });

    await _answer(state, correct: true);

    expect(calls, 1);
    expect(
        result?.interpretationState, PreviewInterpretationState.observational);
    _expectNoAuthority(result!);
  });

  test('B: the passive hook follows ContextEvidence admission semantics',
      () async {
    var calls = 0;
    BoundedAggregateObservation? aggregate;
    final state = await _state(observer: (observations) {
      calls++;
      aggregate = bridge.fromObservations(observations).aggregate.value;
    });

    await _answer(state, correct: true);
    await _answer(state, correct: false);
    await _skip(state);
    state.debugTimeoutForTest();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 3);
    expect(aggregate?.evidenceCount, 3);
    expect(aggregate?.correctCount, 1);
    expect(aggregate?.incorrectCount, 1);
    expect(aggregate?.timeoutCount, 1);
  });

  test('C: passive hook payloads are immutable', () async {
    Object? mutationError;
    final state = await _state(observer: (observations) {
      try {
        observations.clear();
      } catch (error) {
        mutationError = error;
      }
    });

    await _answer(state, correct: true);

    expect(mutationError, isA<UnsupportedError>());
  });

  test('D: observer failures do not interrupt canonical gameplay', () async {
    final state = await _state(observer: (_) => throw StateError('shadow'));
    final question = state.rt.q;

    await _answer(state, correct: true);

    expect(state.p[1].score, greaterThan(0));
    expect(state.p[1].total, 1);
    expect(state.skillMap[Operation.addition.name]!.count, 1);
    expect(state.rt.q, isNot(same(question)));
  });

  test('E: the passive hook can drive the production bounded interpreter',
      () async {
    final control = await _state();
    final controlConfiguredDifficulty = control.diff;
    await _answer(control, correct: true);
    final controlAdaptiveLevel = control.adaptLvlRaw;
    final controlDifficulty = control.diff;
    final controlScore = control.p[1].score;
    final controlSkillCount = control.skillMap[Operation.addition.name]!.count;

    const productionInterpreter = BoundedContextShadowInterpreter();
    var calls = 0;
    BoundedContextShadowInterpretation? result;
    final state = await _state(observer: (observations) {
      calls++;
      result = productionInterpreter.interpret(observations);
    });
    final scoreBefore = state.p[1].score;

    await _answer(state, correct: true);

    expect(calls, 1);
    expect(
        result?.state, BoundedContextShadowInterpretationState.observational);
    expect(result?.aggregate?.evidenceCount, 1);
    expect(result?.aggregate?.correctCount, 1);
    expect(result?.authority, BoundedContextShadowAuthority.none);
    expect(result?.mayAffectGameplay, isFalse);
    expect(state.p[1].score, greaterThan(scoreBefore));
    expect(controlScore, greaterThan(0));
    expect(state.adaptLvlRaw, controlAdaptiveLevel);
    expect(state.diff, controlDifficulty);
    expect(controlDifficulty, controlConfiguredDifficulty);
    expect(
      state.skillMap[Operation.addition.name]!.count,
      controlSkillCount,
    );
  });
}

Future<GameState> _state({ContextEvidenceShadowObserver? observer}) async {
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
    audio: _NoOpAudioService(),
    contextEvidenceShadowObserver: observer,
  );
  await state.load();
  state
    ..rt.challenge = Operation.addition
    ..mode = GameMode.standard
    ..diff = Difficulty.easy
    ..numType = NumberType.natural
    ..selectedAnswerStyle = AnswerStyle.choice4
    ..questionCount = 10
    ..adaptive = false
    ..startGame();
  state.rt.timer?.cancel();
  addTearDown(state.dispose);
  return state;
}

Future<void> _answer(GameState state, {required bool correct}) async {
  final question = state.rt.q!;
  final answer = correct
      ? question.ans
      : question.choices.firstWhere(
          (choice) => (choice - question.ans).abs() >= 1e-9,
        );
  state.onAnswer(answer);
  await Future<void>.delayed(const Duration(milliseconds: 1350));
  state.rt.timer?.cancel();
}

Future<void> _skip(GameState state) async {
  state.skip();
  await Future<void>.delayed(const Duration(milliseconds: 1350));
  state.rt.timer?.cancel();
}

void _expectNoAuthority(PreviewInterpretationResult result) {
  expect(result.authority, PreviewAuthority.none);
  expect(result.mayAffectGameplay, isFalse);
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
