import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const matcher = TimeoutConcentrationScenarioMatcher();

  TimeoutConcentrationEvaluation evaluation({
    int firstTimeouts = 0,
    int secondTimeouts = 0,
    bool incomplete = false,
  }) {
    final context = ContextEvidenceKey(
      operation: Operation.addition,
      numberType: NumberType.natural,
    );
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
    final comparability = const BoundedComparabilityAssessor().assess(
      comparison: comparison,
      requirement: const BoundedComparabilityRequirement(
        difficulty: BoundedDifficultyComparability.difficultyMayDiffer,
      ),
    );
    return const TimeoutConcentrationEvaluator().evaluate(
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
      comparability: comparability,
      timingComparability: TimeoutTimingComparability.comparable,
    );
  }

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

  test('maps compatible, no-direction, and incompatible evaluations literally',
      () {
    final scenarioLibrary = library(ScenarioAcceptanceState.accepted);

    expect(
      matcher
          .match(
            scenarioLibrary: scenarioLibrary,
            evaluation: evaluation(secondTimeouts: 1),
          )
          .state,
      TimeoutConcentrationScenarioMatchState.matched,
    );
    expect(
      matcher
          .match(
            scenarioLibrary: scenarioLibrary,
            evaluation: evaluation(firstTimeouts: 1, secondTimeouts: 1),
          )
          .state,
      TimeoutConcentrationScenarioMatchState.notMatched,
    );
    expect(
      matcher
          .match(
            scenarioLibrary: scenarioLibrary,
            evaluation: evaluation(firstTimeouts: 1),
          )
          .state,
      TimeoutConcentrationScenarioMatchState.contradicted,
    );
  });

  test('retains evaluator not-evaluable detail without duplicating it', () {
    final evaluatorResult = evaluation(incomplete: true);
    final result = matcher.match(
      scenarioLibrary: library(ScenarioAcceptanceState.accepted),
      evaluation: evaluatorResult,
    );

    expect(result.state, TimeoutConcentrationScenarioMatchState.notEvaluable);
    expect(
      result.notEvaluableReason,
      TimeoutConcentrationScenarioMatchNotEvaluableReason
          .evaluationNotEvaluable,
    );
    expect(identical(result.evaluation, evaluatorResult), isTrue);
    expect(
      result.evaluation.notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.incompleteEvidence,
    );
  });

  test('proposed and rejected definitions cannot match', () {
    final evaluatorResult = evaluation(secondTimeouts: 1);

    for (final state in [
      ScenarioAcceptanceState.proposed,
      ScenarioAcceptanceState.rejected,
    ]) {
      final result = matcher.match(
        scenarioLibrary: library(state),
        evaluation: evaluatorResult,
      );
      expect(result.state, TimeoutConcentrationScenarioMatchState.notEvaluable);
      expect(
        result.notEvaluableReason,
        TimeoutConcentrationScenarioMatchNotEvaluableReason.scenarioNotAccepted,
      );
      expect(result.definition, isNull);
    }
  });

  test('a different accepted version cannot match', () {
    final result = matcher.match(
      scenarioLibrary: library(ScenarioAcceptanceState.accepted, version: 2),
      evaluation: evaluation(secondTimeouts: 1),
    );

    expect(result.state, TimeoutConcentrationScenarioMatchState.notEvaluable);
    expect(
      result.notEvaluableReason,
      TimeoutConcentrationScenarioMatchNotEvaluableReason
          .scenarioVersionMismatch,
    );
    expect(result.definition!.version, 2);
  });

  test('retains the exact accepted definition and evaluation objects', () {
    final scenarioLibrary = library(ScenarioAcceptanceState.accepted);
    final evaluatorResult = evaluation(secondTimeouts: 1);
    final result = matcher.match(
      scenarioLibrary: scenarioLibrary,
      evaluation: evaluatorResult,
    );

    expect(
      identical(
        result.definition,
        scenarioLibrary.acceptedById('TimeoutConcentrationAtDifficulty'),
      ),
      isTrue,
    );
    expect(identical(result.evaluation, evaluatorResult), isTrue);
    expect(result.notEvaluableReason, isNull);
  });

  test('is authority-free and does not mutate its inputs', () {
    final scenarioLibrary = library(ScenarioAcceptanceState.accepted);
    final evaluatorResult = evaluation(secondTimeouts: 1);
    final entries = scenarioLibrary.entries;
    final result = matcher.match(
      scenarioLibrary: scenarioLibrary,
      evaluation: evaluatorResult,
    );

    expect(result.authority, TimeoutConcentrationScenarioMatchAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
    expect(scenarioLibrary.entries, same(entries));
    expect(identical(result.evaluation, evaluatorResult), isTrue);
  });

  test('matches the accepted Phase-1 definition without changing others', () {
    final result = matcher.match(
      scenarioLibrary: phase1DifficultyScenarioLibrary,
      evaluation: evaluation(secondTimeouts: 1),
    );

    expect(result.state, TimeoutConcentrationScenarioMatchState.matched);
    expect(
        result.definition,
        same(phase1DifficultyScenarioLibrary.acceptedById(
          'TimeoutConcentrationAtDifficulty',
        )));
    expect(
      phase1DifficultyScenarioLibrary.entries
          .where((entry) =>
              entry.acceptanceState == ScenarioAcceptanceState.accepted)
          .map((entry) => entry.definition.id),
      ['TimeoutConcentrationAtDifficulty'],
    );
  });

  test('source remains a pure accepted-definition and evaluation consumer', () {
    final source = _withoutCommentsAndStrings(File(
      'lib/features/game_brain/scenario/'
      'timeout_concentration_scenario_matcher.dart',
    ).readAsStringSync());
    final barrel =
        File('lib/features/game_brain/game_brain.dart').readAsStringSync();

    for (final pattern in [
      'ContextEvidenceObservation',
      'BoundedOutcomeDescriptiveSummarizer',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'DifficultyCandidateTopologyHandoff',
      'TimeoutTimingComparability',
      'responseTimeMs',
      'GameState',
      'AdaptiveDifficultyEngine',
      'Difficulty.values',
      '.index',
      'indexOf(',
      'sort(',
      'sorted',
      'compareTo(',
      'Wilson',
      'wilson',
      'P1Study',
      'p1_f01',
      'recommend',
      'Recommendation',
      'policy',
      'PlayerModel',
      'LearnerSnapshot',
      'minimum',
      'minN',
      'threshold',
      'significance',
      'pValue',
      'confidenceInterval',
      'precision',
    ]) {
      expect(source, isNot(contains(pattern)));
    }
    expect(source, contains('acceptedById('));
    expect(
      barrel,
      contains(
          "export 'scenario/timeout_concentration_scenario_matcher.dart';"),
    );
  });
}

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
