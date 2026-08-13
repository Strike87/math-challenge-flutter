import '../../../../models/enums.dart';
import '../../domain/brain_memory_entry.dart';
import '../../domain/learner_hypothesis.dart';
import '../../domain/misconception_evidence.dart';
import '../../domain/session_evidence.dart';
import 'learner_reasoner.dart';

/// Deterministic BRAIN-03 reasoning over bounded, in-memory session records.
final class DefaultLearnerReasoner implements LearnerReasoner {
  const DefaultLearnerReasoner();

  static const int repeatedThreshold = 2;
  static const int stableThreshold = 3;
  static const int recoveryCorrectThreshold = 2;

  @override
  SessionEvidence reason(
    List<BrainMemoryEntry> entries,
    Operation operation,
  ) {
    final operationEntries = entries
        .where((entry) => entry.observation.operation == operation)
        .toList(growable: false);
    final typedEvidence = operationEntries
        .map((entry) => entry.misconceptionEvidence)
        .whereType<MisconceptionEvidence>()
        .where((evidence) => evidence.type != null)
        .toList(growable: false);
    final counts = <MisconceptionType, int>{};
    for (final evidence in typedEvidence) {
      counts[evidence.type!] = (counts[evidence.type!] ?? 0) + 1;
    }

    final latest = typedEvidence.isEmpty ? null : typedEvidence.last;
    final correctCount =
        operationEntries.where((entry) => entry.observation.correct).length;
    final recoveryType = _recoveryType(operationEntries, counts);
    final repeatedType = _uniqueRepeatedType(counts);
    final isStable = operationEntries.length >= stableThreshold &&
        correctCount == operationEntries.length &&
        typedEvidence.isEmpty;

    final (hypothesis, supportingObservationCount) = recoveryType != null
        ? (LearnerHypothesis.recovering, recoveryCorrectThreshold)
        : repeatedType != null
            ? (LearnerHypothesis.repeatedMisconception, counts[repeatedType]!)
            : isStable
                ? (
                    LearnerHypothesis.stableUnderstanding,
                    operationEntries.length
                  )
                : (LearnerHypothesis.insufficientEvidence, 0);

    return _summary(
      operation: operation,
      operationEntries: operationEntries,
      correctCount: correctCount,
      counts: counts,
      latest: latest,
      hypothesis: hypothesis,
      supportingObservationCount: supportingObservationCount,
    );
  }

  MisconceptionType? _recoveryType(
    List<BrainMemoryEntry> entries,
    Map<MisconceptionType, int> counts,
  ) {
    if (entries.length < recoveryCorrectThreshold) return null;
    final recoveryEntries =
        entries.sublist(entries.length - recoveryCorrectThreshold);
    if (recoveryEntries.any((entry) => !entry.observation.correct)) return null;

    if (recoveryEntries
        .any((entry) => entry.misconceptionEvidence?.type != null)) {
      return null;
    }

    final candidates = counts.entries
        .where((entry) => entry.value >= repeatedThreshold)
        .map((entry) => entry.key)
        .toList(growable: false);
    return candidates.length == 1 ? candidates.single : null;
  }

  MisconceptionType? _uniqueRepeatedType(
    Map<MisconceptionType, int> counts,
  ) {
    if (counts.isEmpty) return null;
    final highestCount = counts.values.reduce((a, b) => a > b ? a : b);
    if (highestCount < repeatedThreshold) return null;
    final leaders = counts.entries
        .where((entry) => entry.value == highestCount)
        .map((entry) => entry.key)
        .toList(growable: false);
    return leaders.length == 1 ? leaders.single : null;
  }

  SessionEvidence _summary({
    required Operation operation,
    required List<BrainMemoryEntry> operationEntries,
    required int correctCount,
    required Map<MisconceptionType, int> counts,
    required MisconceptionEvidence? latest,
    required LearnerHypothesis hypothesis,
    required int supportingObservationCount,
  }) =>
      SessionEvidence(
        operation: operation,
        observationCount: operationEntries.length,
        correctCount: correctCount,
        incorrectCount: operationEntries.length - correctCount,
        misconceptionCounts: counts,
        latestMisconception: latest,
        hypothesis: hypothesis,
        supportingObservationCount: supportingObservationCount,
      );
}
