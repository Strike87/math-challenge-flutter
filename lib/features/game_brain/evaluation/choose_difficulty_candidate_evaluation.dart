import '../../../models/enums.dart';
import '../decision/choose_difficulty_evidence_snapshot.dart';
import '../domain/context_evidence.dart';
import '../interpretation/bounded_context_shadow_interpreter.dart';
import 'timeout_scenario_candidate_evidence_contribution.dart';

enum ChooseDifficultyCandidateEvaluationAuthority { none }

final class ChooseDifficultyCandidateEvaluation {
  ChooseDifficultyCandidateEvaluation._({
    required this.candidateEvidence,
    required List<TimeoutScenarioCandidateEvidenceContribution>
        timeoutContributions,
  }) : timeoutContributions = List.unmodifiable(timeoutContributions);

  final ChooseDifficultyCandidateEvidence candidateEvidence;
  final List<TimeoutScenarioCandidateEvidenceContribution> timeoutContributions;

  Difficulty get candidateDifficulty => candidateEvidence.candidate;
  ChooseDifficultyEvidenceAvailability get availability =>
      candidateEvidence.availability;
  BoundedContextAggregate? get aggregate => candidateEvidence.aggregate;

  ChooseDifficultyCandidateEvaluationAuthority get authority =>
      ChooseDifficultyCandidateEvaluationAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyCandidateEvaluationSet {
  ChooseDifficultyCandidateEvaluationSet._({
    required this.context,
    required List<ChooseDifficultyCandidateEvaluation> evaluations,
  }) : evaluations = List.unmodifiable(evaluations);

  final ContextEvidenceKey context;
  final List<ChooseDifficultyCandidateEvaluation> evaluations;

  ChooseDifficultyCandidateEvaluationAuthority get authority =>
      ChooseDifficultyCandidateEvaluationAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyCandidateEvaluationAssembler {
  const ChooseDifficultyCandidateEvaluationAssembler();

  ChooseDifficultyCandidateEvaluationSet assemble({
    required ChooseDifficultyEvidenceSnapshot snapshot,
    required Iterable<TimeoutScenarioCandidateEvidenceContribution>
        timeoutContributions,
  }) {
    final contributions = timeoutContributions.toList();
    for (final contribution in contributions) {
      if (contribution.context != snapshot.context ||
          !snapshot.candidates.any(
            (candidate) =>
                candidate.candidate == contribution.candidateDifficulty,
          )) {
        throw ArgumentError('Contribution is outside the snapshot envelope.');
      }
    }

    return ChooseDifficultyCandidateEvaluationSet._(
      context: snapshot.context,
      evaluations: [
        for (final candidateEvidence in snapshot.candidates)
          ChooseDifficultyCandidateEvaluation._(
            candidateEvidence: candidateEvidence,
            timeoutContributions: [
              for (final contribution in contributions)
                if (contribution.context == snapshot.context &&
                    contribution.candidateDifficulty ==
                        candidateEvidence.candidate)
                  contribution,
            ],
          ),
      ],
    );
  }
}
