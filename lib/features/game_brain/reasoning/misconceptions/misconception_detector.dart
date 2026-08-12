import '../../domain/brain_observation.dart';
import '../../domain/misconception_evidence.dart';

/// A pure, stateless rule that may recognize one misconception observation.
abstract interface class MisconceptionDetector {
  MisconceptionEvidence? detect(BrainObservation observation);
}
