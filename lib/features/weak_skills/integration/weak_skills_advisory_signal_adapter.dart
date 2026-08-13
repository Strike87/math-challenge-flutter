import '../../game_brain/domain/brain_decision.dart';
import '../../game_brain/domain/brain_recommendation.dart';
import '../../game_brain/domain/learner_hypothesis.dart';
import '../../../models/enums.dart';
import '../domain/weak_skills_advisory_signal.dart';

const _weakSkillsOperations = {
  Operation.addition,
  Operation.subtraction,
  Operation.multiplication,
  Operation.division,
};

/// Converts the narrow BRAIN-04 recommendation contract into Weak Skills input.
WeakSkillsAdvisorySignal? weakSkillsAdvisorySignalFor(
  BrainDecision decision,
) {
  final recommendation = decision.recommendation;
  if (recommendation == null ||
      recommendation.type != BrainRecommendationType.reinforceOperation ||
      recommendation.reason !=
          BrainRecommendationReason.repeatedMisconception ||
      decision.sessionEvidence?.hypothesis !=
          LearnerHypothesis.repeatedMisconception ||
      recommendation.targetOperation == null ||
      !_weakSkillsOperations.contains(recommendation.targetOperation)) {
    return null;
  }

  return WeakSkillsAdvisorySignal(
    targetOperation: recommendation.targetOperation!,
    recommendationType: recommendation.type,
    recommendationReason: recommendation.reason,
    learnerHypothesis: decision.sessionEvidence!.hypothesis,
    misconceptionType: recommendation.misconceptionType,
    supportingObservationCount: recommendation.supportingObservationCount,
  );
}
