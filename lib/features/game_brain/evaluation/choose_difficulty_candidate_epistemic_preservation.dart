import '../../../models/enums.dart';
import '../decision/choose_difficulty_evidence_snapshot.dart';
import '../domain/context_evidence.dart';
import '../interpretation/bounded_context_shadow_interpreter.dart';
import 'choose_difficulty_candidate_evaluation.dart';
import 'timeout_scenario_candidate_evidence_contribution.dart';

enum ChooseDifficultyEpistemicPreservationAuthority { none }

final class ChooseDifficultyCandidateEpistemicEvidence {
  const ChooseDifficultyCandidateEpistemicEvidence._({
    required this.sourceEvaluation,
  });

  final ChooseDifficultyCandidateEvaluation sourceEvaluation;

  Difficulty get candidateDifficulty => sourceEvaluation.candidateDifficulty;
  ChooseDifficultyEvidenceAvailability get availability =>
      sourceEvaluation.availability;
  BoundedContextAggregate? get aggregate => sourceEvaluation.aggregate;
  List<TimeoutScenarioCandidateEvidenceContribution> get timeoutContributions =>
      sourceEvaluation.timeoutContributions;

  ChooseDifficultyEpistemicPreservationAuthority get authority =>
      ChooseDifficultyEpistemicPreservationAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyEpistemicPreservationSet {
  ChooseDifficultyEpistemicPreservationSet._({
    required this.sourceEvaluationSet,
    required List<ChooseDifficultyCandidateEpistemicEvidence> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final ChooseDifficultyCandidateEvaluationSet sourceEvaluationSet;

  ContextEvidenceKey get context => sourceEvaluationSet.context;
  final List<ChooseDifficultyCandidateEpistemicEvidence> candidates;

  ChooseDifficultyEpistemicPreservationAuthority get authority =>
      ChooseDifficultyEpistemicPreservationAuthority.none;
  bool get mayAffectGameplay => false;
}

final class ChooseDifficultyEpistemicPreserver {
  const ChooseDifficultyEpistemicPreserver();

  ChooseDifficultyEpistemicPreservationSet preserve({
    required ChooseDifficultyCandidateEvaluationSet evaluationSet,
  }) =>
      ChooseDifficultyEpistemicPreservationSet._(
        sourceEvaluationSet: evaluationSet,
        candidates: [
          for (final evaluation in evaluationSet.evaluations)
            ChooseDifficultyCandidateEpistemicEvidence._(
              sourceEvaluation: evaluation,
            ),
        ],
      );
}
