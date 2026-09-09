import '../../../models/enums.dart';
import '../est/bounded_evidence_coverage.dart';
import 'choose_difficulty_evidence_snapshot.dart';

final class ChooseDifficultyEvidenceCoverageBridge {
  const ChooseDifficultyEvidenceCoverageBridge();

  List<BoundedEvidenceCoverageFact> project({
    required ChooseDifficultyEvidenceSnapshot snapshot,
    required Map<Difficulty, String> slotIdsByCandidate,
  }) {
    final legalCandidates = snapshot.legalCandidates;
    final evidence = snapshot.candidates;
    if (legalCandidates.toSet().length != legalCandidates.length) {
      throw ArgumentError('Legal candidates must be unique.');
    }

    final evidenceCandidates = <Difficulty>{};
    for (final entry in evidence) {
      if (!evidenceCandidates.add(entry.candidate)) {
        throw ArgumentError('Candidate evidence identities must be unique.');
      }
    }

    final legalCandidateSet = legalCandidates.toSet();
    if (evidenceCandidates.length != legalCandidateSet.length ||
        !evidenceCandidates.containsAll(legalCandidateSet) ||
        slotIdsByCandidate.length != legalCandidateSet.length ||
        !slotIdsByCandidate.keys.every(legalCandidateSet.contains)) {
      throw ArgumentError('Candidate identities must match exactly.');
    }

    final slotIds = <String>{};
    for (final slotId in slotIdsByCandidate.values) {
      if (slotId.trim().isEmpty || !slotIds.add(slotId)) {
        throw ArgumentError('Slot IDs must be nonblank and unique.');
      }
    }

    return List.unmodifiable([
      for (final entry in evidence)
        BoundedEvidenceCoverageFact(
          slotId: slotIdsByCandidate[entry.candidate]!,
          disposition:
              entry.availability == ChooseDifficultyEvidenceAvailability.present
                  ? BoundedEvidenceCoverageDisposition.present
                  : BoundedEvidenceCoverageDisposition.notObserved,
        ),
    ]);
  }
}
