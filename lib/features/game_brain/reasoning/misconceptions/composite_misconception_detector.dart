import '../../domain/brain_observation.dart';
import '../../domain/misconception_evidence.dart';
import 'division_inverse_detector.dart';
import 'misconception_detector.dart';
import 'multiplication_fact_detector.dart';
import 'operation_substitution_detector.dart';
import 'sign_rule_detector.dart';

/// Returns evidence only when exactly one detector recognizes the observation.
final class CompositeMisconceptionDetector implements MisconceptionDetector {
  CompositeMisconceptionDetector({Iterable<MisconceptionDetector>? detectors})
      : _detectors = List.unmodifiable(
          detectors ??
              const <MisconceptionDetector>[
                SignRuleDetector(),
                OperationSubstitutionDetector(),
                MultiplicationFactDetector(),
                DivisionInverseDetector(),
              ],
        );

  final List<MisconceptionDetector> _detectors;

  @override
  MisconceptionEvidence? detect(BrainObservation observation) {
    final matches = <MisconceptionEvidence>[];
    for (final detector in _detectors) {
      final evidence = detector.detect(observation);
      if (evidence != null) {
        matches.add(evidence);
      }
    }
    return matches.length == 1 ? matches.single : null;
  }
}
