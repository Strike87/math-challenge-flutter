import 'misconception_evidence.dart';
import 'brain_recommendation.dart';
import 'session_evidence.dart';

/// A shadow-only GameBrain result that makes no gameplay change.
final class BrainDecision {
  BrainDecision({
    required this.isNeutral,
    required this.confidence,
    this.misconceptionEvidence,
    this.sessionEvidence,
    this.recommendation,
  }) {
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'must be a finite value from 0 to 1',
      );
    }
  }

  factory BrainDecision.neutral() =>
      BrainDecision(isNeutral: true, confidence: 0);

  final bool isNeutral;
  final double confidence;
  final MisconceptionEvidence? misconceptionEvidence;
  final SessionEvidence? sessionEvidence;
  final BrainRecommendation? recommendation;

  bool get isShadow => true;
}
