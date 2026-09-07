import 'bounded_outcome_comparison.dart';

enum BoundedComparabilityState {
  unresolved,
  notComparable,
  comparable,
}

enum BoundedDifficultyComparability {
  sameDifficultyRequired,
  difficultyMayDiffer,
}

enum BoundedComparabilityAuthority { none }

enum BoundedComparabilityReason {
  incompletePair,
  contextMismatch,
  difficultyMismatch,
}

final class BoundedComparabilityRequirement {
  const BoundedComparabilityRequirement({
    required this.difficulty,
  });

  final BoundedDifficultyComparability difficulty;
}

final class BoundedComparabilityAssessment {
  const BoundedComparabilityAssessment._({
    required this.comparison,
    required this.requirement,
    required this.state,
    required this.reasons,
  });

  final BoundedOutcomeComparison comparison;
  final BoundedComparabilityRequirement requirement;
  final BoundedComparabilityState state;
  final Set<BoundedComparabilityReason> reasons;

  BoundedComparabilityAuthority get authority =>
      BoundedComparabilityAuthority.none;

  bool get mayAffectGameplay => false;
}

final class BoundedComparabilityAssessor {
  const BoundedComparabilityAssessor();

  BoundedComparabilityAssessment assess({
    required BoundedOutcomeComparison comparison,
    required BoundedComparabilityRequirement requirement,
  }) {
    if (comparison.state == BoundedOutcomeComparisonState.incompletePair) {
      return _assessment(
        comparison: comparison,
        requirement: requirement,
        state: BoundedComparabilityState.unresolved,
        reasons: {BoundedComparabilityReason.incompletePair},
      );
    }
    if (comparison.state == BoundedOutcomeComparisonState.contextMismatch) {
      return _assessment(
        comparison: comparison,
        requirement: requirement,
        state: BoundedComparabilityState.notComparable,
        reasons: {BoundedComparabilityReason.contextMismatch},
      );
    }
    if (requirement.difficulty ==
            BoundedDifficultyComparability.sameDifficultyRequired &&
        comparison.first.difficulty != comparison.second.difficulty) {
      return _assessment(
        comparison: comparison,
        requirement: requirement,
        state: BoundedComparabilityState.notComparable,
        reasons: {BoundedComparabilityReason.difficultyMismatch},
      );
    }
    return _assessment(
      comparison: comparison,
      requirement: requirement,
      state: BoundedComparabilityState.comparable,
      reasons: const {},
    );
  }

  BoundedComparabilityAssessment _assessment({
    required BoundedOutcomeComparison comparison,
    required BoundedComparabilityRequirement requirement,
    required BoundedComparabilityState state,
    required Set<BoundedComparabilityReason> reasons,
  }) =>
      BoundedComparabilityAssessment._(
        comparison: comparison,
        requirement: requirement,
        state: state,
        reasons: Set.unmodifiable(reasons),
      );
}
