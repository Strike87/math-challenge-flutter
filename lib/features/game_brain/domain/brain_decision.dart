/// A shadow-only GameBrain result that makes no gameplay recommendation.
final class BrainDecision {
  BrainDecision({
    required this.isNeutral,
    required this.confidence,
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

  bool get isShadow => true;
}
