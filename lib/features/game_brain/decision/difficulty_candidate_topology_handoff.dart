import '../../../models/enums.dart';

enum DifficultyCandidateRelation {
  lowerThanReference,
  sameAsReference,
  higherThanReference,
}

enum DifficultyCandidateTopologyAuthority { none }

final class DifficultyCandidateTopologyHandoff {
  DifficultyCandidateTopologyHandoff({
    required this.reference,
    required this.candidate,
    required this.relation,
    required List<Difficulty> legalCandidates,
  }) : legalCandidates = List.unmodifiable(legalCandidates) {
    if (legalCandidates.any((difficulty) => !_isPhase1(difficulty)) ||
        legalCandidates.toSet().length != legalCandidates.length) {
      throw ArgumentError('Candidates must be unique Phase-1 difficulties.');
    }
    if (!_isPhase1(reference) || !legalCandidates.contains(reference)) {
      throw ArgumentError('Reference must be a supplied Phase-1 candidate.');
    }
    if (!_isPhase1(candidate) || !legalCandidates.contains(candidate)) {
      throw ArgumentError('Candidate must be a supplied Phase-1 candidate.');
    }
    if ((reference == candidate) !=
        (relation == DifficultyCandidateRelation.sameAsReference)) {
      throw ArgumentError('Relation must match candidate equality.');
    }
  }

  final Difficulty reference;
  final Difficulty candidate;

  /// Relationship of candidate relative to reference.
  final DifficultyCandidateRelation relation;

  /// Canonical legal candidates supplied externally.
  final List<Difficulty> legalCandidates;

  DifficultyCandidateTopologyAuthority get authority =>
      DifficultyCandidateTopologyAuthority.none;

  bool get mayAffectGameplay => false;

  static bool _isPhase1(Difficulty difficulty) =>
      difficulty == Difficulty.easy ||
      difficulty == Difficulty.medium ||
      difficulty == Difficulty.hard;
}
