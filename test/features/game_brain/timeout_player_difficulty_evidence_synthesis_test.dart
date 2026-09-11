import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const synthesizer = TimeoutPlayerDifficultyEvidenceSynthesizer();
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
        requiredObservations: [],
        comparableConditions: [],
        supportingEvidence: [],
        contradictingEvidence: [],
        alternativeExplanations: [],
        missingEvidence: [],
        epistemicRequirements: [],
        attributionLimitations: [],
      ),
      acceptanceState: ScenarioAcceptanceState.accepted,
    ),
  ]);

  TimeoutConcentrationScenarioMatch match({
    ContextEvidenceKey? evidenceContext,
    Difficulty target = Difficulty.hard,
    Difficulty comparator = Difficulty.easy,
    (bool, bool) timeouts = (false, true),
  }) {
    ContextEvidenceObservation observation(
            Difficulty difficulty, bool timedOut) =>
        ContextEvidenceObservation(
          context: evidenceContext ?? context,
          difficulty: difficulty,
          correctAnswer: 4,
          submittedAnswer: timedOut ? null : 4,
          correct: !timedOut,
          timedOut: timedOut,
          responseTimeMs: 1000,
        );
    final comparison = const BoundedOutcomeComparator().compare(
      firstObservations: [observation(comparator, timeouts.$1)],
      secondObservations: [observation(target, timeouts.$2)],
    );
    final evaluation = const TimeoutConcentrationEvaluator().evaluate(
      targetDifficulty: target,
      comparatorDifficulty: comparator,
      topology: DifficultyCandidateTopologyHandoff(
        reference: comparator,
        candidate: target,
        relation: DifficultyCandidateRelation.higherThanReference,
        legalCandidates: [Difficulty.easy, Difficulty.medium, Difficulty.hard],
      ),
      comparability: BoundedComparabilityAssessor().assess(
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

  TimeoutPlayerDifficultyEvidenceSlice synthesize(
    TimeoutConcentrationScenarioEvidenceMemory memory, {
    ContextEvidenceKey? queryContext,
    Difficulty target = Difficulty.hard,
    Difficulty comparator = Difficulty.easy,
  }) =>
      synthesizer.synthesize(
        memory: memory,
        context: queryContext ?? context,
        targetDifficulty: target,
        comparatorDifficulty: comparator,
      );

  test('empty memory retains the requested triple without a disposition', () {
    final slice = synthesize(
      TimeoutConcentrationScenarioEvidenceMemory(capacity: 1),
    );
    expect(slice.context, same(context));
    expect(slice.targetDifficulty, Difficulty.hard);
    expect(slice.comparatorDifficulty, Difficulty.easy);
    expect(slice.entries, isEmpty);
    expect(slice.dispositions, isEmpty);
    expect(slice.authority, TimeoutPlayerDifficultyEvidenceAuthority.none);
    expect(slice.mayAffectGameplay, isFalse);
  });

  test(
      'filters all three dimensions together and retains exact ordered entries',
      () {
    final otherContext = ContextEvidenceKey(
      operation: Operation.subtraction,
      numberType: NumberType.natural,
    );
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 7);
    final matches = [
      match(evidenceContext: otherContext),
      match(timeouts: (true, false)),
      match(target: Difficulty.medium),
      match(timeouts: (false, false)),
      match(comparator: Difficulty.medium),
      match(),
      match(
        evidenceContext: otherContext,
        target: Difficulty.medium,
        comparator: Difficulty.hard,
      ),
    ];
    for (final evidence in matches) {
      memory.record(scenarioLibrary: scenarioLibrary, match: evidence);
    }
    final before = memory.entries;
    final sequencesBefore = before.map((entry) => entry.sequence).toList();
    final slice = synthesize(memory);
    final expected = [before[1], before[3], before[5]];
    expect(slice.entries, orderedEquals(expected));
    for (var i = 0; i < expected.length; i++) {
      expect(slice.entries[i], same(expected[i]));
      expect(slice.entries[i].match, same(expected[i].match));
    }
    expect(slice.entries.map((entry) => entry.match.state), [
      TimeoutConcentrationScenarioMatchState.contradicted,
      TimeoutConcentrationScenarioMatchState.notMatched,
      TimeoutConcentrationScenarioMatchState.matched,
    ]);
    expect(slice.dispositions, {
      TimeoutConcentrationScenarioMatchState.matched,
      TimeoutConcentrationScenarioMatchState.notMatched,
      TimeoutConcentrationScenarioMatchState.contradicted,
    });
    expect(memory.entries, orderedEquals(before));
    expect(memory.entries.map((entry) => entry.sequence), sequencesBefore);
    for (var i = 0; i < before.length; i++) {
      expect(memory.entries[i], same(before[i]));
    }
    expect(
      memory.record(scenarioLibrary: scenarioLibrary, match: match()).sequence,
      8,
    );
    expect(slice.entries, orderedEquals(expected));
  });

  test('equivalent non-identical query contexts give deterministic selection',
      () {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 2);
    final entry =
        memory.record(scenarioLibrary: scenarioLibrary, match: match());
    final equivalent = ContextEvidenceKey(
      operation: context.operation,
      numberType: context.numberType,
      representation: context.representation,
    );
    expect(equivalent, isNot(same(context)));
    final first = synthesize(memory);
    final second = synthesize(memory, queryContext: equivalent);
    final third = synthesize(memory, queryContext: equivalent);
    expect(second.context, same(equivalent));
    for (final slice in [first, second, third]) {
      expect(slice.entries.single, same(entry));
      expect(slice.entries, orderedEquals(first.entries));
      expect(slice.dispositions, first.dispositions);
    }
  });

  test('duplicate records survive while their disposition appears once', () {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 3);
    final duplicate = match();
    final first =
        memory.record(scenarioLibrary: scenarioLibrary, match: duplicate);
    final second =
        memory.record(scenarioLibrary: scenarioLibrary, match: duplicate);
    final slice = synthesize(memory);
    expect(slice.entries, orderedEquals([first, second]));
    expect(slice.entries[0], same(first));
    expect(slice.entries[1], same(second));
    expect(slice.entries[0].match, same(duplicate));
    expect(slice.entries[1].match, same(duplicate));
    expect(
        slice.dispositions, {TimeoutConcentrationScenarioMatchState.matched});

    final conflict = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match(timeouts: (true, false)),
    );
    final conflictingSlice = synthesize(memory);
    expect(conflictingSlice.entries, orderedEquals([first, second, conflict]));
    expect(conflictingSlice.dispositions, {
      TimeoutConcentrationScenarioMatchState.matched,
      TimeoutConcentrationScenarioMatchState.contradicted,
    });
    expect(slice.entries, orderedEquals([first, second]));
    expect(
        slice.dispositions, {TimeoutConcentrationScenarioMatchState.matched});
  });

  test(
      'returned collections reject mutation and survive subsequent FIFO eviction',
      () {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
    final entry =
        memory.record(scenarioLibrary: scenarioLibrary, match: match());
    final slice = synthesize(memory);
    expect(() => slice.entries.add(entry), throwsUnsupportedError);
    expect(() => slice.entries.clear(), throwsUnsupportedError);
    expect(
      () => slice.dispositions
          .add(TimeoutConcentrationScenarioMatchState.notMatched),
      throwsUnsupportedError,
    );
    expect(() => slice.dispositions.clear(), throwsUnsupportedError);
    memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match(timeouts: (true, false)),
    );
    expect(slice.entries.single, same(entry));
    expect(
        slice.dispositions, {TimeoutConcentrationScenarioMatchState.matched});
    expect(synthesize(memory).dispositions, {
      TimeoutConcentrationScenarioMatchState.contradicted,
    });
    expect(slice.authority, TimeoutPlayerDifficultyEvidenceAuthority.none);
    expect(slice.mayAffectGameplay, isFalse);
  });

  for (final pair in [
    (Difficulty.hard, Difficulty.hard),
    (Difficulty.easy, Difficulty.hard),
  ]) {
    test('unobserved query pair $pair stays empty without topology validation',
        () {
      final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
      final entry =
          memory.record(scenarioLibrary: scenarioLibrary, match: match());
      final slice = synthesize(memory, target: pair.$1, comparator: pair.$2);
      expect(slice.targetDifficulty, pair.$1);
      expect(slice.comparatorDifficulty, pair.$2);
      expect(slice.entries, isEmpty);
      expect(slice.dispositions, isEmpty);
      expect(memory.entries.single, same(entry));
    });
  }

  test('source depends only on governed evidence contracts', () {
    final source = File(
      'lib/features/game_brain/model/'
      'timeout_player_difficulty_evidence_synthesis.dart',
    ).readAsStringSync();
    expect(
      RegExp(r'\bimport\s+[^;]+;')
          .allMatches(source)
          .map((match) => match.group(0)),
      unorderedEquals([
        "import '../../../models/enums.dart';",
        "import '../domain/context_evidence.dart';",
        "import '../memory/timeout_concentration_scenario_evidence_memory.dart';",
        "import '../scenario/timeout_concentration_scenario_matcher.dart';",
      ]),
    );
    final codeOnly = _withoutCommentsAndStrings(source);
    for (final prohibited in [
      'ContextEvidenceObservation',
      'BoundedOutcomeDescriptiveSummarizer',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'DifficultyCandidateTopologyHandoff',
      'ScenarioKnowledgeLibrary',
      'ScenarioDefinition',
      'TimeoutConcentrationEvaluator',
      'GameState',
      'LearnerSnapshot',
      'PlayerExperienceModel',
      'mastery',
      'ability',
      'Adaptive',
      'Recommendation',
      'CandidateEvaluation',
      'Policy',
      'SharedPreferences',
      'database',
      'telemetry',
      'runtime',
      'Wilson',
      'minimum',
      'threshold',
      'pValue',
      'confidence',
      'reliableChange',
      'trend',
      'recency',
      'majority',
      'playerId',
      'learnerId',
      'profileId',
      'accountId',
      'deviceId',
      'runId',
      'sessionId',
      'dominantDisposition',
      'latestDisposition',
      'resolvedDisposition',
      'preferredDisposition',
      'majorityDisposition',
      'DateTime',
      'Difficulty.values',
      '.index',
      '.sort(',
      '.record(',
    ]) {
      expect(
        codeOnly.toLowerCase(),
        isNot(contains(prohibited.toLowerCase())),
        reason: 'Production model must not reference $prohibited',
      );
    }
    expect(codeOnly, isNot(matches(r'\b(export|part)\b')));
  });
}

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
