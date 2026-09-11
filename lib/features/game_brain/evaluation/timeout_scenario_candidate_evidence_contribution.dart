import '../../../models/enums.dart';
import '../domain/context_evidence.dart';
import '../memory/timeout_concentration_scenario_evidence_memory.dart';
import '../model/timeout_player_difficulty_evidence_synthesis.dart';
import '../scenario/timeout_concentration_scenario_matcher.dart';

enum TimeoutScenarioCandidateEvidenceContributionAuthority { none }

final class TimeoutScenarioCandidateEvidenceContribution {
  const TimeoutScenarioCandidateEvidenceContribution._({
    required this.sourceEvidence,
  });

  static const int synthesisVersion = 1;
  static const String scenarioId = 'TimeoutConcentrationAtDifficulty';

  final TimeoutPlayerDifficultyEvidenceSlice sourceEvidence;

  ContextEvidenceKey get context => sourceEvidence.context;
  Difficulty get candidateDifficulty => sourceEvidence.targetDifficulty;
  Difficulty get comparatorDifficulty => sourceEvidence.comparatorDifficulty;
  List<TimeoutConcentrationScenarioEvidenceEntry> get entries =>
      sourceEvidence.entries;
  Set<TimeoutConcentrationScenarioMatchState> get dispositions =>
      sourceEvidence.dispositions;

  TimeoutScenarioCandidateEvidenceContributionAuthority get authority =>
      TimeoutScenarioCandidateEvidenceContributionAuthority.none;

  bool get mayAffectGameplay => false;
}

final class TimeoutScenarioCandidateEvidenceSynthesizer {
  const TimeoutScenarioCandidateEvidenceSynthesizer();

  TimeoutScenarioCandidateEvidenceContribution synthesize({
    required TimeoutPlayerDifficultyEvidenceSlice evidence,
  }) =>
      TimeoutScenarioCandidateEvidenceContribution._(sourceEvidence: evidence);
}
