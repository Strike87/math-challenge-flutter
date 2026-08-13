import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  final additionContext = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );

  ContextEvidenceObservation observation({
    ContextEvidenceKey? context,
    bool unsupported = false,
    bool correct = true,
    bool timedOut = false,
  }) =>
      ContextEvidenceObservation(
        context: unsupported ? null : context ?? additionContext,
        difficulty: Difficulty.easy,
        correctAnswer: 4,
        submittedAnswer: timedOut ? null : (correct ? 4 : 3),
        correct: correct,
        timedOut: timedOut,
        responseTimeMs: 800,
      );

  test('supported context returns deterministic insufficient exposure', () {
    final first = GameBrain().observeContextEvidence(observation());
    final second = GameBrain().observeContextEvidence(observation());

    expect(first.status, ContextEvidenceStatus.insufficientEvidence);
    expect(first.reasonCode, ContextEvidenceReason.insufficientExposure);
    expect(first.context, additionContext);
    expect(first.exposureCount, 1);
    expect(first.correctCount, 1);
    expect(first.incorrectCount, 0);
    expect(first.timeoutCount, 0);
    expect(first.explanation, second.explanation);
  });

  test('unsupported context is discarded with an explicit reason', () {
    final memory = ContextEvidenceMemory();
    final result = GameBrain(contextEvidenceMemory: memory)
        .observeContextEvidence(observation(unsupported: true));

    expect(result.status, ContextEvidenceStatus.insufficientEvidence);
    expect(result.reasonCode, ContextEvidenceReason.unsupportedContext);
    expect(result.context, isNull);
    expect(result.exposureCount, 0);
    expect(memory.observations, isEmpty);
  });

  test('context memory is immutable to callers and capped at ten', () {
    final memory = ContextEvidenceMemory();
    final brain = GameBrain(contextEvidenceMemory: memory);
    brain.observeContextEvidence(observation(timedOut: true, correct: false));
    for (var index = 0; index < 10; index++) {
      brain.observeContextEvidence(observation(correct: index.isEven));
    }
    final result = brain.observeContextEvidence(observation(correct: true));

    expect(memory.observations, hasLength(10));
    expect(() => memory.observations.clear(), throwsUnsupportedError);
    expect(result.exposureCount, 10);
    expect(result.correctCount, 5);
    expect(result.incorrectCount, 5);
    expect(result.timeoutCount, 0);
  });

  test('related mathematical contexts never receive propagated evidence', () {
    final subtractionContext = ContextEvidenceKey(
      operation: Operation.subtraction,
      numberType: NumberType.natural,
    );
    final brain = GameBrain();
    brain.observeContextEvidence(observation());
    final subtraction = brain.observeContextEvidence(
      observation(context: subtractionContext, correct: false),
    );

    expect(subtraction.context, subtractionContext);
    expect(subtraction.exposureCount, 1);
    expect(subtraction.correctCount, 0);
    expect(subtraction.incorrectCount, 1);
  });

  test('context observation does not invoke any legacy evaluation seam', () {
    final policy = _ForbiddenPolicy();
    final reasoner = _ForbiddenReasoner();
    final recommendation = _ForbiddenRecommendationPolicy();
    final brain = GameBrain(
      policy: policy,
      learnerReasoner: reasoner,
      recommendationPolicy: recommendation,
    );

    brain.observeContextEvidence(observation());

    expect(policy.calls, 0);
    expect(reasoner.calls, 0);
    expect(recommendation.calls, 0);
    expect(brain.memory.entries, isEmpty);
  });

  test('explanation contains observables without learner claims', () {
    final brain = GameBrain();
    brain.observeContextEvidence(observation(correct: false));
    final result = brain.observeContextEvidence(
      observation(correct: false, timedOut: true),
    );

    expect(result.explanation, contains('2 observations'));
    expect(result.explanation, contains('0 correct'));
    expect(result.explanation, contains('2 incorrect'));
    expect(result.explanation, contains('1 timed out'));
    for (final forbidden in [
      'confidence',
      'probability',
      'misconception',
      'learner',
      'mechanism',
      'stable',
      'difficulty',
    ]) {
      expect(result.explanation.toLowerCase(), isNot(contains(forbidden)));
    }
  });

  test('rejects contradictory or negative-time observations', () {
    expect(
      () => ContextEvidenceObservation(
        context: additionContext,
        difficulty: Difficulty.easy,
        correctAnswer: 4,
        submittedAnswer: null,
        correct: true,
        timedOut: true,
        responseTimeMs: 800,
      ),
      throwsArgumentError,
    );
    expect(
      () => ContextEvidenceObservation(
        context: additionContext,
        difficulty: Difficulty.easy,
        correctAnswer: 4,
        submittedAnswer: 4,
        correct: true,
        timedOut: false,
        responseTimeMs: -1,
      ),
      throwsArgumentError,
    );
  });

  test('rejects non-basic context keys', () {
    expect(
      () => ContextEvidenceKey(
        operation: Operation.master,
        numberType: NumberType.natural,
      ),
      throwsArgumentError,
    );
  });
}

final class _ForbiddenPolicy implements BrainDecisionPolicy {
  int calls = 0;

  @override
  BrainDecision decide(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  ) {
    calls++;
    throw StateError('Legacy policy must not run.');
  }
}

final class _ForbiddenReasoner implements LearnerReasoner {
  int calls = 0;

  @override
  SessionEvidence reason(List<BrainMemoryEntry> entries, Operation operation) {
    calls++;
    throw StateError('Legacy reasoner must not run.');
  }
}

final class _ForbiddenRecommendationPolicy implements RecommendationPolicy {
  int calls = 0;

  @override
  BrainRecommendation recommend(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
  ) {
    calls++;
    throw StateError('Legacy recommendation policy must not run.');
  }
}
