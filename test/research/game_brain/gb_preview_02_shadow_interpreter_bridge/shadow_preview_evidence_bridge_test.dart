import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/domain/context_evidence.dart';
import 'package:math_challenge/models/enums.dart';

import '../../../../research/game_brain/gb_preview_01_simplify_01/minimal_preview_interpreter.dart';
import '../../../../research/game_brain/gb_preview_01_simplify_01/preview_observation_evidence_v2.dart';
import '../../../../research/game_brain/gb_preview_02_shadow_interpreter_bridge/shadow_preview_evidence_bridge.dart';

void main() {
  const bridge = ShadowPreviewEvidenceBridge();
  const interpreter = MinimalPreviewInterpreter();
  final context = ContextEvidenceKey(
    operation: Operation.multiplication,
    numberType: NumberType.natural,
  );

  test('1: bridges mutually exclusive correct and incorrect counts', () {
    final aggregate = bridge
        .fromObservations(
          _observations(context: context, correctCount: 8, incorrectCount: 2),
        )
        .aggregate
        .value!;

    expect(aggregate.evidenceCount, 10);
    expect(aggregate.correctCount, 8);
    expect(aggregate.incorrectCount, 2);
    expect(aggregate.timeoutCount, 0);
    expect(aggregate.accuracy, .8);
  });

  test('2: timeouts are not double-counted as incorrect', () {
    final aggregate = bridge
        .fromObservations(
          _observations(
            context: context,
            correctCount: 7,
            incorrectCount: 2,
            timeoutCount: 1,
          ),
        )
        .aggregate
        .value!;

    expect(aggregate.evidenceCount, 10);
    expect(aggregate.correctCount, 7);
    expect(aggregate.incorrectCount, 2);
    expect(aggregate.timeoutCount, 1);
  });

  test('3: factual context identity preserves supplied fields', () {
    final factualContext = bridge
        .fromObservations(_observations(context: context, correctCount: 1))
        .factualContext;

    expect(factualContext.isPresent, isTrue);
    expect(factualContext.value, contains('operation=multiplication'));
    expect(factualContext.value, contains('numberType=natural'));
    expect(factualContext.value, contains('representation=directNumeric'));
    expect(factualContext.value, contains('difficulty=medium'));
  });

  test('4: bounded summary round-trips through the interpreter', () {
    final result = interpreter.interpret(
      bridge.fromObservations(_observations(context: context, correctCount: 1)),
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(
        result.interpretationState, PreviewInterpretationState.observational);
    _expectNoAuthority(result);
  });

  test('5: explicit temporal order can report a higher recent observation', () {
    final result = interpreter.interpret(
      bridge.fromTemporalObservations(
        earlier:
            _observations(context: context, correctCount: 4, incorrectCount: 6),
        recent:
            _observations(context: context, correctCount: 8, incorrectCount: 2),
      ),
      PreviewInterpretationRequest.observedTemporalDifference,
    );

    expect(
        result.interpretationState, PreviewInterpretationState.observational);
    expect(result.temporalDifference, ObservedTemporalDifference.recentHigher);
    expect(result.explanation, contains('RECENT_HIGHER'));
    expect(result.explanation.toLowerCase(), isNot(contains('reliable')));
  });

  test('6: temporal observations do not make reliable improvement evaluable',
      () {
    final evidence = bridge.fromTemporalObservations(
      earlier:
          _observations(context: context, correctCount: 4, incorrectCount: 6),
      recent:
          _observations(context: context, correctCount: 8, incorrectCount: 2),
    );
    final result = interpreter.interpret(
      evidence,
      PreviewInterpretationRequest.reliableImprovement,
    );

    expect(result.interpretationState, PreviewInterpretationState.notEvaluable);
    expect(result.missingEvidence.single, contains('ValidatedChangeReceipt'));
  });

  test('7: empty aggregate input remains missing', () {
    final evidence = bridge.fromObservations(const []);
    final result = interpreter.interpret(
      evidence,
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(evidence.aggregate.state, EvidenceSlotState.missing);
    expect(evidence.factualContext.state, EvidenceSlotState.missing);
    expect(result.interpretationState, PreviewInterpretationState.insufficient);
  });

  test('8: an empty temporal side leaves comparison missing', () {
    final evidence = bridge.fromTemporalObservations(
      earlier: const [],
      recent: _observations(context: context, correctCount: 1),
    );
    final result = interpreter.interpret(
      evidence,
      PreviewInterpretationRequest.observedTemporalDifference,
    );

    expect(evidence.temporalComparison.state, EvidenceSlotState.missing);
    expect(result.interpretationState, PreviewInterpretationState.insufficient);
  });

  test('9: null contexts are rejected', () {
    expect(
      () => bridge.fromObservations([_observation(context: null)]),
      throwsArgumentError,
    );
  });

  test('10: mixed context keys are rejected', () {
    final addition = ContextEvidenceKey(
      operation: Operation.addition,
      numberType: NumberType.natural,
    );
    expect(
      () => bridge.fromObservations([
        _observation(context: context),
        _observation(context: addition),
      ]),
      throwsArgumentError,
    );
  });

  test('11: mixed difficulties are rejected', () {
    expect(
      () => bridge.fromObservations([
        _observation(context: context, difficulty: Difficulty.easy),
        _observation(context: context, difficulty: Difficulty.medium),
      ]),
      throwsArgumentError,
    );
  });

  test('12: sparse evidence is not invented', () {
    final evidence = bridge.fromObservations(
      _observations(context: context, correctCount: 1),
    );

    expect(evidence.sparseEvidence.state, EvidenceSlotState.missing);
  });

  test('13: conflicting evidence is not invented', () {
    final evidence = bridge.fromObservations(
      _observations(context: context, correctCount: 1),
    );

    expect(evidence.conflictingEvidence.state, EvidenceSlotState.missing);
  });

  test('14: bridge output is deterministic', () {
    final observations =
        _observations(context: context, correctCount: 8, incorrectCount: 2);
    final first = bridge.fromObservations(observations);
    final second = bridge.fromObservations(observations);

    expect(first.aggregate, second.aggregate);
    expect(first.factualContext, second.factualContext);
    expect(first.temporalComparison.state, second.temporalComparison.state);
    expect(first.sparseEvidence.state, second.sparseEvidence.state);
    expect(first.conflictingEvidence.state, second.conflictingEvidence.state);
  });

  test('15: all exercised interpreter results have no authority', () {
    final summary = interpreter.interpret(
      bridge.fromObservations(_observations(context: context, correctCount: 1)),
      PreviewInterpretationRequest.boundedObservationSummary,
    );
    final temporal = interpreter.interpret(
      bridge.fromTemporalObservations(
        earlier: _observations(context: context, incorrectCount: 1),
        recent: _observations(context: context, correctCount: 1),
      ),
      PreviewInterpretationRequest.observedTemporalDifference,
    );
    final unavailable = interpreter.interpret(
      bridge.fromObservations(_observations(context: context, correctCount: 1)),
      PreviewInterpretationRequest.reliableImprovement,
    );

    for (final result in [summary, temporal, unavailable]) {
      _expectNoAuthority(result);
    }
  });
}

List<ContextEvidenceObservation> _observations({
  required ContextEvidenceKey context,
  int correctCount = 0,
  int incorrectCount = 0,
  int timeoutCount = 0,
}) =>
    [
      for (var i = 0; i < correctCount; i++) _observation(context: context),
      for (var i = 0; i < incorrectCount; i++)
        _observation(context: context, correct: false),
      for (var i = 0; i < timeoutCount; i++)
        _observation(context: context, timedOut: true),
    ];

ContextEvidenceObservation _observation({
  ContextEvidenceKey? context,
  Difficulty difficulty = Difficulty.medium,
  bool correct = true,
  bool timedOut = false,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: timedOut ? null : (correct ? 4 : 3),
      correct: timedOut ? false : correct,
      timedOut: timedOut,
      responseTimeMs: 1000,
    );

void _expectNoAuthority(PreviewInterpretationResult result) {
  expect(result.authority, PreviewAuthority.none);
  expect(result.mayAffectGameplay, isFalse);
}
