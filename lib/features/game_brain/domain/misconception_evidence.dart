/// The small, deterministic misconception categories supported by BRAIN-02.
enum MisconceptionType {
  signRule,
  operationSubstitution,
  multiplicationFact,
  divisionInverse,
}

/// Stable machine-readable explanations for deterministic evidence.
enum MisconceptionReason {
  oppositeSignSameMagnitude,
  alternativeBasicOperation,
  adjacentMultiplicationFactor,
  reversedDivisionOperands,
}

/// Caller-tagged evidence retained verbatim for later, separately approved
/// interpretation. BRAIN-02 can additionally attach a deterministic taxonomy.
final class MisconceptionEvidence {
  MisconceptionEvidence({
    required this.tag,
    this.type,
    this.reason,
    this.confidence,
  }) {
    if (tag.trim().isEmpty) {
      throw ArgumentError.value(tag, 'tag', 'must not be empty');
    }
    if ((type == null) != (reason == null)) {
      throw ArgumentError('type and reason must be supplied together.');
    }
    if (type != null && !_isCompatible(type!, reason!)) {
      throw ArgumentError('type and reason must describe the same rule.');
    }
    if (confidence != null &&
        (!confidence!.isFinite || confidence! < 0 || confidence! > 1)) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'must be a finite value from 0 to 1',
      );
    }
  }

  final String tag;
  final MisconceptionType? type;
  final MisconceptionReason? reason;

  /// Fixed rule-strength score, not a calibrated probability.
  final double? confidence;

  static bool _isCompatible(
    MisconceptionType type,
    MisconceptionReason reason,
  ) {
    switch (type) {
      case MisconceptionType.signRule:
        return reason == MisconceptionReason.oppositeSignSameMagnitude;
      case MisconceptionType.operationSubstitution:
        return reason == MisconceptionReason.alternativeBasicOperation;
      case MisconceptionType.multiplicationFact:
        return reason == MisconceptionReason.adjacentMultiplicationFactor;
      case MisconceptionType.divisionInverse:
        return reason == MisconceptionReason.reversedDivisionOperands;
    }
  }
}
