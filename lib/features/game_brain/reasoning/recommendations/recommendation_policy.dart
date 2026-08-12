import '../../domain/brain_observation.dart';
import '../../domain/brain_recommendation.dart';
import '../../domain/session_evidence.dart';

/// Pure seam for producing advisory recommendations from session evidence.
abstract interface class RecommendationPolicy {
  BrainRecommendation recommend(
    BrainObservation observation,
    SessionEvidence sessionEvidence,
  );
}
