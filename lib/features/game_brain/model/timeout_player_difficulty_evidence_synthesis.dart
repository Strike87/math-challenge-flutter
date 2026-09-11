import '../../../models/enums.dart';
import '../domain/context_evidence.dart';
import '../memory/timeout_concentration_scenario_evidence_memory.dart';
import '../scenario/timeout_concentration_scenario_matcher.dart';

enum TimeoutPlayerDifficultyEvidenceAuthority { none }

final class TimeoutPlayerDifficultyEvidenceSlice {
  TimeoutPlayerDifficultyEvidenceSlice._({
    required this.context,
    required this.targetDifficulty,
    required this.comparatorDifficulty,
    required List<TimeoutConcentrationScenarioEvidenceEntry> entries,
  }) : entries = List.unmodifiable(entries);

  final ContextEvidenceKey context;
  final Difficulty targetDifficulty;
  final Difficulty comparatorDifficulty;
  final List<TimeoutConcentrationScenarioEvidenceEntry> entries;

  Set<TimeoutConcentrationScenarioMatchState> get dispositions =>
      Set.unmodifiable(entries.map((entry) => entry.match.state));

  TimeoutPlayerDifficultyEvidenceAuthority get authority =>
      TimeoutPlayerDifficultyEvidenceAuthority.none;

  bool get mayAffectGameplay => false;
}

final class TimeoutPlayerDifficultyEvidenceSynthesizer {
  const TimeoutPlayerDifficultyEvidenceSynthesizer();

  TimeoutPlayerDifficultyEvidenceSlice synthesize({
    required TimeoutConcentrationScenarioEvidenceMemory memory,
    required ContextEvidenceKey context,
    required Difficulty targetDifficulty,
    required Difficulty comparatorDifficulty,
  }) =>
      TimeoutPlayerDifficultyEvidenceSlice._(
        context: context,
        targetDifficulty: targetDifficulty,
        comparatorDifficulty: comparatorDifficulty,
        entries: [
          for (final entry in memory.entries)
            if (entry.match.evaluation.context == context &&
                entry.match.evaluation.targetDifficulty == targetDifficulty &&
                entry.match.evaluation.comparatorDifficulty ==
                    comparatorDifficulty)
              entry,
        ],
      );
}
