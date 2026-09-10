import '../../../models/enums.dart';
import '../decision/difficulty_candidate_topology_handoff.dart';
import '../est/bounded_outcome_comparability.dart';
import '../est/bounded_outcome_comparison.dart';

enum TimeoutTimingComparability { comparable, notComparable, unknown }

enum TimeoutConcentrationEvaluationState {
  notEvaluable,
  descriptivelyCompatible,
  noDirectionalConcentration,
  descriptivelyIncompatible,
}

enum TimeoutConcentrationNotEvaluableReason {
  incompleteEvidence,
  observedComparisonNotComparable,
  observedComparisonUnresolved,
  timingNotComparable,
  timingUnknown,
  topologyPairMismatch,
  difficultyBindingMismatch,
  comparisonRequirementMismatch,
  malformedComparison,
}

enum TimeoutConcentrationEvaluationAuthority { none }

final class TimeoutConcentrationEvaluation {
  const TimeoutConcentrationEvaluation._({
    required this.state,
    required this.notEvaluableReason,
    required this.targetDifficulty,
    required this.comparatorDifficulty,
    required this.observedTimeoutRateDifference,
    required this.timingComparability,
  });

  final TimeoutConcentrationEvaluationState state;
  final TimeoutConcentrationNotEvaluableReason? notEvaluableReason;
  final Difficulty targetDifficulty;
  final Difficulty comparatorDifficulty;
  final double? observedTimeoutRateDifference;
  final TimeoutTimingComparability timingComparability;

  TimeoutConcentrationEvaluationAuthority get authority =>
      TimeoutConcentrationEvaluationAuthority.none;

  bool get mayAffectGameplay => false;
}

final class TimeoutConcentrationEvaluator {
  const TimeoutConcentrationEvaluator();

  TimeoutConcentrationEvaluation evaluate({
    required Difficulty targetDifficulty,
    required Difficulty comparatorDifficulty,
    required DifficultyCandidateTopologyHandoff topology,
    required BoundedComparabilityAssessment comparability,
    required TimeoutTimingComparability timingComparability,
  }) {
    if (topology.reference != comparatorDifficulty ||
        topology.candidate != targetDifficulty) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.topologyPairMismatch,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    if (comparability.requirement.difficulty !=
        BoundedDifficultyComparability.difficultyMayDiffer) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.comparisonRequirementMismatch,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    final comparison = comparability.comparison;
    if ((comparison.first.difficulty != null &&
            comparison.first.difficulty != comparatorDifficulty) ||
        (comparison.second.difficulty != null &&
            comparison.second.difficulty != targetDifficulty)) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.difficultyBindingMismatch,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    if (comparison.state == BoundedOutcomeComparisonState.incompletePair) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.incompleteEvidence,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    if (comparability.state == BoundedComparabilityState.unresolved) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.observedComparisonUnresolved,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    if (comparability.state == BoundedComparabilityState.notComparable) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.observedComparisonNotComparable,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    if (timingComparability == TimeoutTimingComparability.notComparable) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.timingNotComparable,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    if (timingComparability == TimeoutTimingComparability.unknown) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.timingUnknown,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    final difference = comparison.timeoutRateDifference;
    if (difference == null || !difference.isFinite) {
      return _notEvaluable(
        TimeoutConcentrationNotEvaluableReason.malformedComparison,
        targetDifficulty,
        comparatorDifficulty,
        timingComparability,
      );
    }
    return TimeoutConcentrationEvaluation._(
      state: difference > 0
          ? TimeoutConcentrationEvaluationState.descriptivelyCompatible
          : difference == 0
              ? TimeoutConcentrationEvaluationState.noDirectionalConcentration
              : TimeoutConcentrationEvaluationState.descriptivelyIncompatible,
      notEvaluableReason: null,
      targetDifficulty: targetDifficulty,
      comparatorDifficulty: comparatorDifficulty,
      observedTimeoutRateDifference: difference,
      timingComparability: timingComparability,
    );
  }

  TimeoutConcentrationEvaluation _notEvaluable(
    TimeoutConcentrationNotEvaluableReason reason,
    Difficulty targetDifficulty,
    Difficulty comparatorDifficulty,
    TimeoutTimingComparability timingComparability,
  ) =>
      TimeoutConcentrationEvaluation._(
        state: TimeoutConcentrationEvaluationState.notEvaluable,
        notEvaluableReason: reason,
        targetDifficulty: targetDifficulty,
        comparatorDifficulty: comparatorDifficulty,
        observedTimeoutRateDifference: null,
        timingComparability: timingComparability,
      );
}
