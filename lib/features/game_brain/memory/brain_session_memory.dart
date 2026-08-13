import '../../../models/enums.dart';
import '../domain/brain_observation.dart';
import '../domain/tentative_misconception_hypothesis.dart';

/// Bounded, mutable, in-memory observations for one GameBrain session.
final class BrainSessionMemory {
  BrainSessionMemory({this.capacity = 10}) {
    if (capacity <= 0) {
      throw ArgumentError.value(
          capacity, 'capacity', 'must be greater than zero');
    }
  }

  final int capacity;
  final List<BrainObservation> _observations = [];

  List<BrainObservation> get observations => List.unmodifiable(_observations);

  void record(BrainObservation observation) {
    if (_observations.length == capacity) {
      _observations.removeAt(0);
    }
    _observations.add(observation);
  }

  /// Tags remain opaque so BRAIN-01 cannot infer a taxonomy or detection rule.
  TentativeMisconceptionHypothesis? tentativeMisconceptionHypothesis() {
    final evidenceCounts = <_EvidenceKey, int>{};

    for (final observation in _observations) {
      final evidence = observation.misconceptionEvidence;
      if (evidence != null) {
        final key = _EvidenceKey(observation.operation, evidence.tag);
        evidenceCounts[key] = (evidenceCounts[key] ?? 0) + 1;
      }
    }

    return _hypothesisFrom(evidenceCounts);
  }

  TentativeMisconceptionHypothesis? _hypothesisFrom(
    Map<_EvidenceKey, int> evidenceCounts,
  ) {
    _EvidenceKey? bestKey;
    var bestCount = 1;

    for (final entry in evidenceCounts.entries) {
      if (entry.value > bestCount) {
        bestKey = entry.key;
        bestCount = entry.value;
      }
    }

    if (bestKey == null) {
      return null;
    }
    return TentativeMisconceptionHypothesis(
      operation: bestKey.operation,
      evidenceTag: bestKey.evidenceTag,
      evidenceCount: bestCount,
    );
  }

  void clear() => _observations.clear();
}

final class _EvidenceKey {
  const _EvidenceKey(this.operation, this.evidenceTag);

  final Operation operation;
  final String evidenceTag;

  @override
  bool operator ==(Object other) =>
      other is _EvidenceKey &&
      operation == other.operation &&
      evidenceTag == other.evidenceTag;

  @override
  int get hashCode => Object.hash(operation, evidenceTag);
}
