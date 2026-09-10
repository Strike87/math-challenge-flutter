import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const matcher = TimeoutConcentrationScenarioMatcher();
  final context = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );

  ScenarioKnowledgeLibrary library(
    ScenarioAcceptanceState state, {
    int version = 1,
  }) {
    final definition = ScenarioDefinition(
      id: 'TimeoutConcentrationAtDifficulty',
      version: version,
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
    );
    return ScenarioKnowledgeLibrary([
      GovernedScenarioDefinition(
        definition: definition,
        acceptanceState: state,
      ),
    ]);
  }

  TimeoutConcentrationEvaluation evaluation({
    int firstTimeouts = 0,
    int secondTimeouts = 0,
    bool incomplete = false,
  }) {
    List<ContextEvidenceObservation> observations(
      Difficulty difficulty,
      int timeouts,
    ) =>
        [
          for (var i = 0; i < timeouts; i++)
            ContextEvidenceObservation(
              context: context,
              difficulty: difficulty,
              correctAnswer: 4,
              submittedAnswer: null,
              correct: false,
              timedOut: true,
              responseTimeMs: 1000,
            ),
          if (!incomplete)
            ContextEvidenceObservation(
              context: context,
              difficulty: difficulty,
              correctAnswer: 4,
              submittedAnswer: 4,
              correct: true,
              timedOut: false,
              responseTimeMs: 1000,
            ),
        ];
    final comparison = const BoundedOutcomeComparator().compare(
      firstObservations: observations(Difficulty.easy, firstTimeouts),
      secondObservations: observations(Difficulty.hard, secondTimeouts),
    );
    return const TimeoutConcentrationEvaluator().evaluate(
      targetDifficulty: Difficulty.hard,
      comparatorDifficulty: Difficulty.easy,
      topology: DifficultyCandidateTopologyHandoff(
        reference: Difficulty.easy,
        candidate: Difficulty.hard,
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
  }

  TimeoutConcentrationScenarioMatch match(
    ScenarioKnowledgeLibrary scenarioLibrary, {
    int firstTimeouts = 0,
    int secondTimeouts = 1,
    bool incomplete = false,
  }) =>
      matcher.match(
        scenarioLibrary: scenarioLibrary,
        evaluation: evaluation(
          firstTimeouts: firstTimeouts,
          secondTimeouts: secondTimeouts,
          incomplete: incomplete,
        ),
      );

  test('rejects non-positive capacity', () {
    expect(
      () => TimeoutConcentrationScenarioEvidenceMemory(capacity: 0),
      throwsArgumentError,
    );
    expect(
      () => TimeoutConcentrationScenarioEvidenceMemory(capacity: -1),
      throwsArgumentError,
    );
  });

  test('records all and only evaluable match states with canonical objects',
      () {
    final scenarioLibrary = library(ScenarioAcceptanceState.accepted);
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 3);
    final matched = match(scenarioLibrary);
    final notMatched = match(
      scenarioLibrary,
      firstTimeouts: 1,
      secondTimeouts: 1,
    );
    final contradicted = match(
      scenarioLibrary,
      firstTimeouts: 1,
      secondTimeouts: 0,
    );

    final entry = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: matched,
    );
    memory.record(scenarioLibrary: scenarioLibrary, match: notMatched);
    memory.record(scenarioLibrary: scenarioLibrary, match: contradicted);

    expect(memory.entries.map((value) => value.match.state), [
      TimeoutConcentrationScenarioMatchState.matched,
      TimeoutConcentrationScenarioMatchState.notMatched,
      TimeoutConcentrationScenarioMatchState.contradicted,
    ]);
    expect(identical(entry.match, matched), isTrue);
    expect(
        entry.match.definition,
        same(scenarioLibrary.acceptedById(
          'TimeoutConcentrationAtDifficulty',
        )));
    expect(entry.match.evaluation.context, same(context));
    expect(entry.match.evaluation.targetDifficulty, Difficulty.hard);
    expect(entry.match.evaluation.comparatorDifficulty, Difficulty.easy);
    expect(
      entry.match.evaluation.state,
      TimeoutConcentrationEvaluationState.descriptivelyCompatible,
    );
    expect(entry.match.evaluation.observedTimeoutRateDifference, 0.5);
  });

  test('rejects non-recordable and structurally inconsistent matches unchanged',
      () {
    final accepted = library(ScenarioAcceptanceState.accepted);
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
    final first = memory.record(
      scenarioLibrary: accepted,
      match: match(accepted),
    );
    final notEvaluable = match(accepted, incomplete: true);
    final mismatched = TimeoutConcentrationScenarioMatch(
      state: TimeoutConcentrationScenarioMatchState.matched,
      notEvaluableReason: null,
      definition: accepted.acceptedById('TimeoutConcentrationAtDifficulty'),
      evaluation: evaluation(firstTimeouts: 1, secondTimeouts: 1),
    );

    for (final rejected in [notEvaluable, mismatched]) {
      expect(
        () => memory.record(scenarioLibrary: accepted, match: rejected),
        throwsArgumentError,
      );
      expect(memory.entries, [first]);
    }
    expect(
      memory.record(scenarioLibrary: accepted, match: match(accepted)).sequence,
      2,
    );
  });

  test('rejects unaccepted, wrong-version, and foreign definitions', () {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 2);
    final accepted = library(ScenarioAcceptanceState.accepted);
    final validEvaluation = evaluation();
    for (final scenarioLibrary in [
      library(ScenarioAcceptanceState.proposed),
      library(ScenarioAcceptanceState.rejected),
      library(ScenarioAcceptanceState.accepted, version: 2),
    ]) {
      final definition = scenarioLibrary.entries.single.definition;
      final fabricated = TimeoutConcentrationScenarioMatch(
        state: TimeoutConcentrationScenarioMatchState.matched,
        notEvaluableReason: null,
        definition: definition,
        evaluation: validEvaluation,
      );
      expect(
        () =>
            memory.record(scenarioLibrary: scenarioLibrary, match: fabricated),
        throwsArgumentError,
      );
    }
    expect(
      () => memory.record(
        scenarioLibrary: accepted,
        match: TimeoutConcentrationScenarioMatch(
          state: TimeoutConcentrationScenarioMatchState.matched,
          notEvaluableReason: null,
          definition: library(ScenarioAcceptanceState.accepted)
              .acceptedById('TimeoutConcentrationAtDifficulty'),
          evaluation: validEvaluation,
        ),
      ),
      throwsArgumentError,
    );
    expect(memory.entries, isEmpty);
  });

  test(
      'uses FIFO, preserves sequences, exposes an immutable view, and keeps duplicates',
      () {
    final scenarioLibrary = library(ScenarioAcceptanceState.accepted);
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 2);
    final first = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match(scenarioLibrary),
    );
    final second = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match(scenarioLibrary, secondTimeouts: 2),
    );
    expect(memory.entries, [first, second]);
    final third = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match(scenarioLibrary, firstTimeouts: 1, secondTimeouts: 1),
    );
    expect(memory.entries, [second, third]);
    expect(memory.entries.map((entry) => entry.sequence), [2, 3]);
    expect(
      () => memory.entries.add(first),
      throwsUnsupportedError,
    );

    final duplicates = TimeoutConcentrationScenarioEvidenceMemory(capacity: 2);
    final duplicate = match(scenarioLibrary);
    duplicates.record(scenarioLibrary: scenarioLibrary, match: duplicate);
    duplicates.record(scenarioLibrary: scenarioLibrary, match: duplicate);
    expect(duplicates.entries, hasLength(2));
  });

  test('is authority-free and source stays a narrow contract consumer', () {
    final scenarioLibrary = library(ScenarioAcceptanceState.accepted);
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
    final entry = memory.record(
      scenarioLibrary: scenarioLibrary,
      match: match(scenarioLibrary),
    );
    expect(
      memory.authority,
      TimeoutConcentrationScenarioEvidenceMemoryAuthority.none,
    );
    expect(memory.mayAffectGameplay, isFalse);
    expect(
      entry.authority,
      TimeoutConcentrationScenarioEvidenceMemoryAuthority.none,
    );
    expect(entry.mayAffectGameplay, isFalse);
    final source = _withoutCommentsAndStrings(File(
      'lib/features/game_brain/memory/'
      'timeout_concentration_scenario_evidence_memory.dart',
    ).readAsStringSync());
    for (final pattern in [
      'ContextEvidenceObservation',
      'BoundedOutcomeDescriptiveSummarizer',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'DifficultyCandidateTopologyHandoff',
      'GameState',
      'LearnerSnapshot',
      'mastery',
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
      'confidenceInterval',
      'reliableChange',
    ]) {
      expect(source, isNot(contains(pattern)));
    }
    expect(source, contains('ScenarioKnowledgeLibrary'));
    expect(source, contains('TimeoutConcentrationScenarioMatch'));
  });
}

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
