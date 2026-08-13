import '../../../../models/enums.dart';
import '../../domain/brain_observation.dart';
import '../../domain/brain_recommendation.dart';
import '../../domain/learner_hypothesis.dart';
import '../../domain/session_evidence.dart';
import 'recommendation_policy.dart';

/// Conservative, deterministic BRAIN-04 recommendation policy.
final class DefaultRecommendationPolicy implements RecommendationPolicy {
  const DefaultRecommendationPolicy();

  @override
  BrainRecommendation recommend(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
  ) {
    final reason = _reasonFor(sessionEvidence.hypothesis);
    switch (sessionEvidence.hypothesis) {
      case LearnerHypothesis.repeatedMisconception:
        return _repeatedMisconception(observation, sessionEvidence, reason);
      case LearnerHypothesis.recovering:
        return _recovering(observation, sessionEvidence, reason);
      case LearnerHypothesis.stableUnderstanding:
        return _stableUnderstanding(observation, sessionEvidence, reason);
      case LearnerHypothesis.insufficientEvidence:
        return _insufficientEvidence(observation, sessionEvidence, reason);
    }
  }

  BrainRecommendation _repeatedMisconception(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
    BrainRecommendationReason reason,
  ) =>
      BrainRecommendation(
        type: BrainRecommendationType.reinforceOperation,
        reason: reason,
        targetOperation: observation.operation,
        currentDifficulty: observation.difficulty,
        suggestedDifficulty: _previousDifficulty(observation.difficulty),
        misconceptionType: sessionEvidence.latestMisconception?.type,
        supportingObservationCount: sessionEvidence.supportingObservationCount,
      );

  BrainRecommendation _recovering(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
    BrainRecommendationReason reason,
  ) =>
      BrainRecommendation(
        type: BrainRecommendationType.maintain,
        reason: reason,
        currentDifficulty: observation.difficulty,
        misconceptionType: sessionEvidence.latestMisconception?.type,
        supportingObservationCount: sessionEvidence.supportingObservationCount,
      );

  BrainRecommendation _stableUnderstanding(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
    BrainRecommendationReason reason,
  ) {
    final suggestedDifficulty = _nextDifficulty(observation.difficulty);
    return BrainRecommendation(
      type: suggestedDifficulty == null
          ? BrainRecommendationType.maintain
          : BrainRecommendationType.considerHarderDifficulty,
      reason: reason,
      currentDifficulty: observation.difficulty,
      suggestedDifficulty: suggestedDifficulty,
      supportingObservationCount: sessionEvidence.supportingObservationCount,
    );
  }

  BrainRecommendation _insufficientEvidence(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
    BrainRecommendationReason reason,
  ) =>
      BrainRecommendation(
        type: BrainRecommendationType.none,
        reason: reason,
        currentDifficulty: observation.difficulty,
        supportingObservationCount: sessionEvidence.supportingObservationCount,
      );

  BrainRecommendationReason _reasonFor(LearnerHypothesis hypothesis) {
    switch (hypothesis) {
      case LearnerHypothesis.repeatedMisconception:
        return BrainRecommendationReason.repeatedMisconception;
      case LearnerHypothesis.recovering:
        return BrainRecommendationReason.recovering;
      case LearnerHypothesis.stableUnderstanding:
        return BrainRecommendationReason.stableUnderstanding;
      case LearnerHypothesis.insufficientEvidence:
        return BrainRecommendationReason.insufficientEvidence;
    }
  }

  Difficulty? _previousDifficulty(Difficulty difficulty) =>
      difficulty.index == 0 ? null : Difficulty.values[difficulty.index - 1];

  Difficulty? _nextDifficulty(Difficulty difficulty) =>
      difficulty.index == Difficulty.values.length - 1
          ? null
          : Difficulty.values[difficulty.index + 1];
}
