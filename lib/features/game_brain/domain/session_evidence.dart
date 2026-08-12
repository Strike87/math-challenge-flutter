import '../../../models/enums.dart';
import 'learner_hypothesis.dart';
import 'misconception_evidence.dart';

/// Immutable, deterministic summary for one operation in the current session.
final class SessionEvidence {
  SessionEvidence({
    required this.operation,
    required this.observationCount,
    required this.correctCount,
    required this.incorrectCount,
    required Map<MisconceptionType, int> misconceptionCounts,
    required this.latestMisconception,
    required this.hypothesis,
    required this.supportingObservationCount,
  }) : misconceptionCounts = Map.unmodifiable(misconceptionCounts);

  final Operation operation;
  final int observationCount;
  final int correctCount;
  final int incorrectCount;
  final Map<MisconceptionType, int> misconceptionCounts;
  final MisconceptionEvidence? latestMisconception;
  final LearnerHypothesis hypothesis;
  final int supportingObservationCount;
}
