import '../../../models/enums.dart';
import '../../game_brain/domain/brain_recommendation.dart';
import '../../game_brain/domain/learner_hypothesis.dart';
import '../../game_brain/domain/misconception_evidence.dart';

/// Immutable supplementary advisory for an eligible Weak Skills tie.
final class WeakSkillsAdvisorySignal {
  WeakSkillsAdvisorySignal({
    required this.targetOperation,
    required this.recommendationType,
    required this.recommendationReason,
    required this.learnerHypothesis,
    required this.supportingObservationCount,
    this.misconceptionType,
  }) {
    if (supportingObservationCount < 0) {
      throw ArgumentError.value(
        supportingObservationCount,
        'supportingObservationCount',
        'must not be negative',
      );
    }
  }

  final Operation targetOperation;
  final BrainRecommendationType recommendationType;
  final BrainRecommendationReason recommendationReason;
  final LearnerHypothesis learnerHypothesis;
  final MisconceptionType? misconceptionType;
  final int supportingObservationCount;
}
