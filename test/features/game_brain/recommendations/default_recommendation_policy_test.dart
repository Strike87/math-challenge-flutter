import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const policy = DefaultRecommendationPolicy();

  test(
      'repeated misconception reinforces the operation with prior tier metadata',
      () {
    final recommendation = policy.recommend(
      _observation(Difficulty.medium),
      _session(LearnerHypothesis.repeatedMisconception, support: 2),
    );

    expect(recommendation.type, BrainRecommendationType.reinforceOperation);
    expect(
        recommendation.reason, BrainRecommendationReason.repeatedMisconception);
    expect(recommendation.targetOperation, Operation.addition);
    expect(recommendation.suggestedDifficulty, Difficulty.easy);
    expect(recommendation.misconceptionType, MisconceptionType.signRule);
    expect(recommendation.supportingObservationCount, 2);
  });

  test('repeated misconception at easy has no impossible prior tier', () {
    final recommendation = policy.recommend(
      _observation(Difficulty.easy),
      _session(LearnerHypothesis.repeatedMisconception),
    );

    expect(recommendation.type, BrainRecommendationType.reinforceOperation);
    expect(recommendation.suggestedDifficulty, isNull);
  });

  for (final difficulty in Difficulty.values) {
    test(
        'stable understanding at $difficulty uses the next tier when available',
        () {
      final recommendation = policy.recommend(
        _observation(difficulty),
        _session(LearnerHypothesis.stableUnderstanding, support: 3),
      );
      final expectedNext = difficulty == Difficulty.insane
          ? null
          : Difficulty.values[difficulty.index + 1];

      expect(
        recommendation.type,
        expectedNext == null
            ? BrainRecommendationType.maintain
            : BrainRecommendationType.considerHarderDifficulty,
      );
      expect(
          recommendation.reason, BrainRecommendationReason.stableUnderstanding);
      expect(recommendation.suggestedDifficulty, expectedNext);
    });
  }

  test('recovering maintains the current context without a target', () {
    final recommendation = policy.recommend(
      _observation(Difficulty.hard),
      _session(LearnerHypothesis.recovering),
    );

    expect(recommendation.type, BrainRecommendationType.maintain);
    expect(recommendation.reason, BrainRecommendationReason.recovering);
    expect(recommendation.targetOperation, isNull);
    expect(recommendation.suggestedDifficulty, isNull);
  });

  test('insufficient or ambiguous evidence returns no intervention', () {
    final recommendation = policy.recommend(
      _observation(Difficulty.hard),
      _session(LearnerHypothesis.insufficientEvidence),
    );

    expect(recommendation.type, BrainRecommendationType.none);
    expect(
        recommendation.reason, BrainRecommendationReason.insufficientEvidence);
    expect(recommendation.suggestedDifficulty, isNull);
  });

  test('recommendation rejects a negative supporting observation count', () {
    expect(
      () => BrainRecommendation(
        type: BrainRecommendationType.none,
        reason: BrainRecommendationReason.insufficientEvidence,
        currentDifficulty: Difficulty.easy,
        supportingObservationCount: -1,
      ),
      throwsArgumentError,
    );
  });
}

BrainObservation _observation(Difficulty difficulty) => BrainObservation(
      operation: Operation.addition,
      difficulty: difficulty,
      numberType: NumberType.natural,
      correctAnswer: '4',
      submittedAnswer: '3',
      correct: false,
      timedOut: false,
      responseTimeMs: 800,
      masteryBefore: 20,
      masteryAfter: 16,
    );

SessionEvidence _session(
  LearnerHypothesis hypothesis, {
  int support = 0,
}) {
  final evidence = MisconceptionEvidence(
    tag: 'sign',
    type: MisconceptionType.signRule,
    reason: MisconceptionReason.oppositeSignSameMagnitude,
  );
  return SessionEvidence(
    operation: Operation.addition,
    observationCount: support,
    correctCount: 0,
    incorrectCount: support,
    misconceptionCounts: {MisconceptionType.signRule: support},
    latestMisconception: evidence,
    hypothesis: hypothesis,
    supportingObservationCount: support,
  );
}
