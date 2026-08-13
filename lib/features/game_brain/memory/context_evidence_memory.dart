import '../domain/context_evidence.dart';

/// Separate bounded FIFO for supported context evidence in the active run.
final class ContextEvidenceMemory {
  ContextEvidenceMemory({this.capacity = 10}) {
    if (capacity <= 0) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'must be greater than zero',
      );
    }
  }

  final int capacity;
  final List<ContextEvidenceObservation> _observations = [];

  List<ContextEvidenceObservation> get observations =>
      List.unmodifiable(_observations);

  void record(ContextEvidenceObservation observation) {
    if (_observations.length == capacity) {
      _observations.removeAt(0);
    }
    _observations.add(observation);
  }

  void clear() => _observations.clear();
}
