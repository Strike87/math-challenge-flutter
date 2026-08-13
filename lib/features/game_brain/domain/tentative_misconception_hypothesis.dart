import '../../../models/enums.dart';

/// A repeated caller-supplied evidence tag observed for one operation.
final class TentativeMisconceptionHypothesis {
  TentativeMisconceptionHypothesis({
    required this.operation,
    required this.evidenceTag,
    required this.evidenceCount,
  }) {
    if (evidenceTag.trim().isEmpty) {
      throw ArgumentError.value(
          evidenceTag, 'evidenceTag', 'must not be empty');
    }
    if (evidenceCount < 2) {
      throw ArgumentError.value(
        evidenceCount,
        'evidenceCount',
        'must be at least two',
      );
    }
  }

  final Operation operation;
  final String evidenceTag;
  final int evidenceCount;
}
