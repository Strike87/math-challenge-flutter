import 'brain_observation.dart';
import 'misconception_evidence.dart';

/// One immutable session record pairing an observation with policy output.
///
/// The original observation remains available unchanged for BRAIN-01's opaque
/// tag aggregation. BRAIN-03 uses only [misconceptionEvidence] when it has a
/// deterministic [MisconceptionEvidence.type].
final class BrainMemoryEntry {
  const BrainMemoryEntry({
    required this.observation,
    this.misconceptionEvidence,
  });

  final BrainObservation observation;
  final MisconceptionEvidence? misconceptionEvidence;
}
