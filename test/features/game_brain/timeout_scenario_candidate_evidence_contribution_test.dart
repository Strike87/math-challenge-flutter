import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const modelSynthesizer = TimeoutPlayerDifficultyEvidenceSynthesizer();
  const contributionSynthesizer = TimeoutScenarioCandidateEvidenceSynthesizer();
  final context = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );
  final scenarioLibrary = ScenarioKnowledgeLibrary([
    GovernedScenarioDefinition(
      definition: ScenarioDefinition(
        id: 'TimeoutConcentrationAtDifficulty',
        version: 1,
        name: 'Timeout concentration',
        questionBeingTested: 'Question',
        requiredObservations: const [],
        comparableConditions: const [],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        alternativeExplanations: const [],
        missingEvidence: const [],
        epistemicRequirements: const [],
        attributionLimitations: const [],
      ),
      acceptanceState: ScenarioAcceptanceState.accepted,
    ),
  ]);

  TimeoutConcentrationScenarioMatch match((bool, bool) timeouts) {
    ContextEvidenceObservation observation(
      Difficulty difficulty,
      bool timedOut,
    ) =>
        ContextEvidenceObservation(
          context: context,
          difficulty: difficulty,
          correctAnswer: 4,
          submittedAnswer: timedOut ? null : 4,
          correct: !timedOut,
          timedOut: timedOut,
          responseTimeMs: 1000,
        );
    final comparison = const BoundedOutcomeComparator().compare(
      firstObservations: [observation(Difficulty.easy, timeouts.$1)],
      secondObservations: [observation(Difficulty.hard, timeouts.$2)],
    );
    final evaluation = const TimeoutConcentrationEvaluator().evaluate(
      targetDifficulty: Difficulty.hard,
      comparatorDifficulty: Difficulty.easy,
      topology: DifficultyCandidateTopologyHandoff(
        reference: Difficulty.easy,
        candidate: Difficulty.hard,
        relation: DifficultyCandidateRelation.higherThanReference,
        legalCandidates: const [
          Difficulty.easy,
          Difficulty.medium,
          Difficulty.hard,
        ],
      ),
      comparability: const BoundedComparabilityAssessor().assess(
        comparison: comparison,
        requirement: const BoundedComparabilityRequirement(
          difficulty: BoundedDifficultyComparability.difficultyMayDiffer,
        ),
      ),
      timingComparability: TimeoutTimingComparability.comparable,
    );
    return const TimeoutConcentrationScenarioMatcher().match(
      scenarioLibrary: scenarioLibrary,
      evaluation: evaluation,
    );
  }

  TimeoutPlayerDifficultyEvidenceSlice slice(
    TimeoutConcentrationScenarioEvidenceMemory memory, {
    Difficulty target = Difficulty.hard,
    Difficulty comparator = Difficulty.easy,
  }) =>
      modelSynthesizer.synthesize(
        memory: memory,
        context: context,
        targetDifficulty: target,
        comparatorDifficulty: comparator,
      );

  test('empty source retains the exact requested binding neutrally', () {
    final source = slice(
      TimeoutConcentrationScenarioEvidenceMemory(capacity: 1),
      target: Difficulty.hard,
      comparator: Difficulty.hard,
    );
    final contribution = contributionSynthesizer.synthesize(evidence: source);

    expect(TimeoutScenarioCandidateEvidenceContribution.synthesisVersion, 1);
    expect(
      TimeoutScenarioCandidateEvidenceContribution.scenarioId,
      'TimeoutConcentrationAtDifficulty',
    );
    expect(contribution.sourceEvidence, same(source));
    expect(contribution.context, same(context));
    expect(contribution.candidateDifficulty, Difficulty.hard);
    expect(contribution.comparatorDifficulty, Difficulty.hard);
    expect(contribution.entries, isEmpty);
    expect(contribution.dispositions, isEmpty);
    expect(
      contribution.authority,
      TimeoutScenarioCandidateEvidenceContributionAuthority.none,
    );
    expect(contribution.mayAffectGameplay, isFalse);
  });

  test('preserves exact ordered duplicate entries and all dispositions', () {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 4);
    final matched = match((false, true));
    final first =
        memory.record(scenarioLibrary: scenarioLibrary, match: matched);
    final second =
        memory.record(scenarioLibrary: scenarioLibrary, match: matched);
    final contradicted = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match((true, false)),
    );
    final notMatched = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match((true, true)),
    );
    final source = slice(memory);
    final contribution = contributionSynthesizer.synthesize(evidence: source);

    expect(contribution.entries,
        orderedEquals([first, second, contradicted, notMatched]));
    for (var i = 0; i < source.entries.length; i++) {
      expect(contribution.entries[i], same(source.entries[i]));
    }
    expect(contribution.dispositions, {
      TimeoutConcentrationScenarioMatchState.matched,
      TimeoutConcentrationScenarioMatchState.notMatched,
      TimeoutConcentrationScenarioMatchState.contradicted,
    });
    expect(contribution.dispositions, isNot(contains('resolved')));
    expect(contribution.entries[0].match, same(contribution.entries[1].match));
    expect(contribution.entries, same(source.entries));
  });

  test('is deterministic and does not mutate the governed source', () {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
    final entry = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match((false, true)),
    );
    final source = slice(memory);
    final before = source.entries;
    final first = contributionSynthesizer.synthesize(evidence: source);
    final second = contributionSynthesizer.synthesize(evidence: source);

    expect(first, isNot(same(second)));
    for (final contribution in [first, second]) {
      expect(contribution.sourceEvidence, same(source));
      expect(contribution.entries.single, same(entry));
      expect(contribution.entries, same(before));
      expect(contribution.dispositions, source.dispositions);
    }
    expect(memory.entries.single, same(entry));
  });

  test('source stays a typed governed-evidence wrapper only', () {
    final rawSource = File(
      'lib/features/game_brain/evaluation/'
      'timeout_scenario_candidate_evidence_contribution.dart',
    ).readAsStringSync();
    final source = _withoutCommentsAndStrings(rawSource);
    expect(
      RegExp(r'\bimport\s+[^;]+;')
          .allMatches(rawSource)
          .map((match) => match.group(0)),
      unorderedEquals([
        "import '../../../models/enums.dart';",
        "import '../domain/context_evidence.dart';",
        "import '../memory/timeout_concentration_scenario_evidence_memory.dart';",
        "import '../model/timeout_player_difficulty_evidence_synthesis.dart';",
        "import '../scenario/timeout_concentration_scenario_matcher.dart';",
      ]),
    );
    for (final prohibited in [
      'ContextEvidenceObservation',
      'BoundedOutcomeDescriptiveSummarizer',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'DifficultyCandidateTopologyHandoff',
      'DifficultyCandidateRelation',
      'ScenarioKnowledgeLibrary',
      'ScenarioDefinition',
      'TimeoutConcentrationEvaluator',
      'TimeoutConcentrationScenarioMatcher',
      'GameState',
      'LearnerSnapshot',
      'PlayerExperienceModel',
      'CandidateEvaluation',
      'Recommendation',
      'Policy',
      'Adaptive',
      'SharedPreferences',
      'database',
      'telemetry',
      'mastery',
      'ability',
      'overchallenge',
      'underchallenge',
      'confidence',
      'probability',
      'threshold',
      'minimum',
      'Wilson',
      'pValue',
      'reliableChange',
      'trend',
      'recency',
      'majority',
      'DateTime',
      'Difficulty.values',
      '.index',
      '.sort(',
      '.record(',
    ]) {
      expect(
        source.toLowerCase(),
        isNot(contains(prohibited.toLowerCase())),
        reason: 'Production source must not reference $prohibited',
      );
    }
    expect(source, isNot(matches(r'\b(export|part)\b')));
  });
}

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
