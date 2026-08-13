import '../../../models/enums.dart';
import 'misconception_evidence.dart';

/// Advisory, explainable guidance derived from bounded session evidence.
enum BrainRecommendationType {
  none,
  maintain,
  reinforceOperation,
  considerHarderDifficulty,
}

/// The deterministic session conclusion supporting a recommendation.
enum BrainRecommendationReason {
  repeatedMisconception,
  recovering,
  stableUnderstanding,
  insufficientEvidence,
}

/// Immutable recommendation metadata for future presentation or integration.
final class BrainRecommendation {
  BrainRecommendation({
    required this.type,
    required this.reason,
    required this.currentDifficulty,
    required this.supportingObservationCount,
    this.targetOperation,
    this.suggestedDifficulty,
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

  final BrainRecommendationType type;
  final BrainRecommendationReason reason;
  final Operation? targetOperation;
  final Difficulty currentDifficulty;
  final Difficulty? suggestedDifficulty;
  final MisconceptionType? misconceptionType;
  final int supportingObservationCount;
}
