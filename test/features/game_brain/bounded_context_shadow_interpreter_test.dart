import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

import '../../../research/game_brain/gb_preview_01_simplify_01/minimal_preview_interpreter.dart';
import '../../../research/game_brain/gb_preview_01_simplify_01/preview_observation_evidence_v2.dart';
import '../../../research/game_brain/gb_preview_02_shadow_interpreter_bridge/shadow_preview_evidence_bridge.dart';

void main() {
  const interpreter = BoundedContextShadowInterpreter();
  const referenceBridge = ShadowPreviewEvidenceBridge();
  const referenceInterpreter = MinimalPreviewInterpreter();
  final context = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );

  test('1: empty observations are insufficient without an aggregate', () {
    final result = interpreter.interpret(const []);

    expect(result.state, BoundedContextShadowInterpretationState.insufficient);
    expect(result.aggregate, isNull);
    expect(result.factualContextId, isNull);
    expect(result.authority, BoundedContextShadowAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('zero-count aggregates have finite zero accuracy', () {
    final aggregate = BoundedContextAggregate(
      evidenceCount: 0,
      correctCount: 0,
      incorrectCount: 0,
      timeoutCount: 0,
    );

    expect(aggregate.accuracy, 0);
    expect(aggregate.accuracy.isNaN, isFalse);
    expect(aggregate.accuracy.isInfinite, isFalse);
  });

  test('2: one correct observation is factual and observational', () {
    final result = interpreter.interpret([_observation(context: context)]);

    expect(result.state, BoundedContextShadowInterpretationState.observational);
    expect(result.aggregate?.evidenceCount, 1);
    expect(result.aggregate?.correctCount, 1);
    expect(result.aggregate?.incorrectCount, 0);
    expect(result.aggregate?.timeoutCount, 0);
  });

  test('3: correct, wrong, and timeout remain exclusive', () {
    final result = interpreter.interpret([
      _observation(context: context),
      _observation(context: context, correct: false),
      _observation(context: context, timedOut: true),
    ]);

    expect(result.aggregate?.evidenceCount, 3);
    expect(result.aggregate?.correctCount, 1);
    expect(result.aggregate?.incorrectCount, 1);
    expect(result.aggregate?.timeoutCount, 1);
  });

  test('4: factual context IDs are deterministic', () {
    final observations = [_observation(context: context)];

    expect(
      interpreter.interpret(observations).factualContextId,
      interpreter.interpret(observations).factualContextId,
    );
    expect(
      interpreter.interpret(observations).factualContextId,
      'operation=addition;numberType=natural;representation=directNumeric;difficulty=easy',
    );
  });

  test('5: mixed contexts fail closed', () {
    final multiplication = ContextEvidenceKey(
      operation: Operation.multiplication,
      numberType: NumberType.natural,
    );

    expect(
      () => interpreter.interpret([
        _observation(context: context),
        _observation(context: multiplication),
      ]),
      throwsArgumentError,
    );
  });

  test('6: mixed difficulties fail closed', () {
    expect(
      () => interpreter.interpret([
        _observation(context: context, difficulty: Difficulty.easy),
        _observation(context: context, difficulty: Difficulty.medium),
      ]),
      throwsArgumentError,
    );
  });

  test('7: null contexts fail closed', () {
    expect(
      () => interpreter.interpret([_observation(context: null)]),
      throwsArgumentError,
    );
  });

  test('8: results expose no gameplay authority', () {
    final result = interpreter.interpret([_observation(context: context)]);

    expect(result.authority, BoundedContextShadowAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('9: explanations remain observational', () {
    final explanation = interpreter
        .interpret([_observation(context: context)])
        .explanation
        .toLowerCase();

    for (final forbidden in [
      'learned',
      'learning',
      'mastery',
      'mastered',
      'ability',
      'improved reliably',
      'struggling',
      'overchallenged',
      'underchallenged',
      'productive challenge',
      'should increase difficulty',
      'should decrease difficulty',
    ]) {
      expect(explanation, isNot(contains(forbidden)));
    }
  });

  test('10: production output matches the bounded research reference', () {
    final observations = [
      _observation(context: context),
      _observation(context: context, correct: false),
      _observation(context: context, timedOut: true),
    ];
    final production = interpreter.interpret(observations);
    final referenceEvidence = referenceBridge.fromObservations(observations);
    final reference = referenceInterpreter.interpret(
      referenceEvidence,
      PreviewInterpretationRequest.boundedObservationSummary,
    );
    final referenceAggregate = referenceEvidence.aggregate.value!;

    expect(production.state,
        BoundedContextShadowInterpretationState.observational);
    expect(reference.interpretationState,
        PreviewInterpretationState.observational);
    expect(
        production.aggregate?.evidenceCount, referenceAggregate.evidenceCount);
    expect(production.aggregate?.correctCount, referenceAggregate.correctCount);
    expect(production.aggregate?.incorrectCount,
        referenceAggregate.incorrectCount);
    expect(production.aggregate?.timeoutCount, referenceAggregate.timeoutCount);
    expect(production.aggregate?.accuracy, referenceAggregate.accuracy);
    expect(production.factualContextId, referenceEvidence.factualContext.value);
  });
}

ContextEvidenceObservation _observation({
  required ContextEvidenceKey? context,
  Difficulty difficulty = Difficulty.easy,
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
