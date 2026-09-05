import '../../../models/enums.dart';
import '../domain/context_evidence.dart';
import '../interpretation/bounded_context_shadow_interpreter.dart';
import '../interpretation/bounded_context_shadow_partitioned_snapshot.dart';

enum ChooseDifficultyEvidenceAvailability { present, absent }

enum ChooseDifficultyEvidenceAuthority { none }

final class ChooseDifficultyCandidateEvidence {
  ChooseDifficultyCandidateEvidence({
    required this.candidate,
    required this.availability,
    required this.aggregate,
  }) {
    if ((availability == ChooseDifficultyEvidenceAvailability.present) !=
        (aggregate != null)) {
      throw ArgumentError('Availability must match aggregate presence.');
    }
  }

  final Difficulty candidate;
  final ChooseDifficultyEvidenceAvailability availability;
  final BoundedContextAggregate? aggregate;

  ChooseDifficultyEvidenceAuthority get authority =>
      ChooseDifficultyEvidenceAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyEvidenceSnapshot {
  ChooseDifficultyEvidenceSnapshot({
    required this.context,
    required List<Difficulty> legalCandidates,
    required List<ChooseDifficultyCandidateEvidence> candidates,
  })  : legalCandidates = List.unmodifiable(legalCandidates),
        candidates = List.unmodifiable(candidates);

  final ContextEvidenceKey context;
  final List<Difficulty> legalCandidates;
  final List<ChooseDifficultyCandidateEvidence> candidates;

  ChooseDifficultyEvidenceAuthority get authority =>
      ChooseDifficultyEvidenceAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyEvidenceSnapshotBuilder {
  const ChooseDifficultyEvidenceSnapshotBuilder();

  ChooseDifficultyEvidenceSnapshot build({
    required ContextEvidenceKey context,
    required List<Difficulty> legalCandidates,
    required BoundedContextShadowPartitionedSnapshot evidenceSnapshot,
  }) {
    if (legalCandidates.any((candidate) =>
            candidate != Difficulty.easy &&
            candidate != Difficulty.medium &&
            candidate != Difficulty.hard) ||
        legalCandidates.toSet().length != legalCandidates.length) {
      throw ArgumentError('Candidates must be unique Phase-1 difficulties.');
    }
    for (final partition in evidenceSnapshot.partitions) {
      if (partition.context == null || partition.difficulty == null) {
        throw ArgumentError('Every partition must have structured identity.');
      }
    }

    final candidates = legalCandidates.map((candidate) {
      final matches = evidenceSnapshot.partitions
          .where((partition) =>
              partition.context == context && partition.difficulty == candidate)
          .toList();
      if (matches.length > 1) {
        throw ArgumentError('Evidence partitions are ambiguous.');
      }
      if (matches.isEmpty) {
        return ChooseDifficultyCandidateEvidence(
          candidate: candidate,
          availability: ChooseDifficultyEvidenceAvailability.absent,
          aggregate: null,
        );
      }
      final match = matches.single;
      if (match.state !=
              BoundedContextShadowInterpretationState.observational ||
          match.aggregate == null) {
        throw ArgumentError('Matching partition is not observational.');
      }
      return ChooseDifficultyCandidateEvidence(
        candidate: candidate,
        availability: ChooseDifficultyEvidenceAvailability.present,
        aggregate: match.aggregate,
      );
    }).toList();

    return ChooseDifficultyEvidenceSnapshot(
      context: context,
      legalCandidates: legalCandidates,
      candidates: candidates,
    );
  }
}
