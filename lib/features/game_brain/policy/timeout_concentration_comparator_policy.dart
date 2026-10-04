import '../../../models/enums.dart';
import '../decision/choose_difficulty_evidence_snapshot.dart'
    show ChooseDifficultyEvidenceAvailability;
import '../domain/context_evidence.dart' show ContextRepresentation;
import '../evaluation/choose_difficulty_candidate_epistemic_preservation.dart';
import '../scenario/timeout_concentration_scenario_matcher.dart'
    show TimeoutConcentrationScenarioMatchState;
import 'choose_difficulty_policy_contract.dart';

final class TimeoutConcentrationComparatorPolicy
    implements VersionedChooseDifficultyPolicy {
  TimeoutConcentrationComparatorPolicy()
      : identity = ChooseDifficultyPolicyIdentity(
          id: 'timeout_concentration_comparator_preference',
          version: 1,
        );

  static const Set<Difficulty> _phase1Candidates = {
    Difficulty.easy,
    Difficulty.medium,
    Difficulty.hard,
  };

  @override
  final ChooseDifficultyPolicyIdentity identity;

  @override
  ChooseDifficultyPolicyResolution resolve({
    required ChooseDifficultyEpistemicPreservationSet evidence,
  }) {
    ChooseDifficultyNoPreference noPreference() => ChooseDifficultyNoPreference(
          source: evidence,
          identity: identity,
        );

    final context = evidence.context;

    if (context.operation != Operation.addition ||
        context.numberType != NumberType.natural ||
        context.representation != ContextRepresentation.directNumeric) {
      return noPreference();
    }

    final candidates = evidence.candidates;

    if (candidates.length != 2 ||
        candidates.map((item) => item.candidateDifficulty).toSet().length !=
            2 ||
        candidates.any(
          (item) =>
              !_phase1Candidates.contains(item.candidateDifficulty) ||
              item.availability != ChooseDifficultyEvidenceAvailability.present,
        )) {
      return noPreference();
    }

    final contributions = [
      for (final candidate in candidates)
        for (final contribution in candidate.timeoutContributions)
          (
            owner: candidate,
            contribution: contribution,
          ),
    ];

    if (contributions.length != 1) {
      return noPreference();
    }

    final owned = contributions.single;
    final owner = owned.owner;
    final contribution = owned.contribution;

    if (contribution.candidateDifficulty != owner.candidateDifficulty ||
        contribution.context != evidence.context ||
        contribution.candidateDifficulty == contribution.comparatorDifficulty) {
      return noPreference();
    }

    final otherCandidate = candidates.singleWhere(
      (item) => item.candidateDifficulty != owner.candidateDifficulty,
    );

    if (contribution.comparatorDifficulty !=
        otherCandidate.candidateDifficulty) {
      return noPreference();
    }

    if (contribution.entries.length != 1 ||
        contribution.entries.single.match.state !=
            TimeoutConcentrationScenarioMatchState.matched) {
      return noPreference();
    }

    return ChooseDifficultyPreferredCandidate(
      source: evidence,
      identity: identity,
      candidate: contribution.comparatorDifficulty,
    );
  }
}
