import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const evaluator = TimeoutConcentrationEvaluator();
  const requirement = BoundedComparabilityRequirement(
    difficulty: BoundedDifficultyComparability.difficultyMayDiffer,
  );

  DifficultyCandidateTopologyHandoff topology({
    Difficulty reference = Difficulty.easy,
    Difficulty candidate = Difficulty.hard,
    DifficultyCandidateRelation relation =
        DifficultyCandidateRelation.higherThanReference,
  }) =>
      DifficultyCandidateTopologyHandoff(
        reference: reference,
        candidate: candidate,
        relation: relation,
        legalCandidates: const [
          Difficulty.easy,
          Difficulty.medium,
          Difficulty.hard,
        ],
      );

  BoundedComparabilityAssessment assessment({
    List<ContextEvidenceObservation> first = const [],
    List<ContextEvidenceObservation> second = const [],
    BoundedComparabilityRequirement value = requirement,
  }) =>
      const BoundedComparabilityAssessor().assess(
        comparison: const BoundedOutcomeComparator().compare(
          firstObservations: first,
          secondObservations: second,
        ),
        requirement: value,
      );

  TimeoutConcentrationEvaluation evaluate({
    required BoundedComparabilityAssessment comparability,
    Difficulty target = Difficulty.hard,
    Difficulty comparator = Difficulty.easy,
    DifficultyCandidateTopologyHandoff? handoff,
    TimeoutTimingComparability timing = TimeoutTimingComparability.comparable,
  }) =>
      evaluator.evaluate(
        targetDifficulty: target,
        comparatorDifficulty: comparator,
        topology: handoff ?? topology(reference: comparator, candidate: target),
        comparability: comparability,
        timingComparability: timing,
      );

  final context = _context();
  List<ContextEvidenceObservation> observations(
    Difficulty difficulty, {
    int timeouts = 0,
    int answered = 1,
  }) =>
      [
        for (var i = 0; i < timeouts; i++)
          _observation(context, difficulty, timedOut: true),
        for (var i = 0; i < answered; i++) _observation(context, difficulty),
      ];

  test('evaluable states retain the exact EST context and orientation', () {
    final positive = evaluate(
      comparability: assessment(
        first: observations(Difficulty.easy),
        second: observations(Difficulty.hard, timeouts: 1),
      ),
    );
    final zero = evaluate(
      comparability: assessment(
        first: observations(Difficulty.easy, timeouts: 1),
        second: observations(Difficulty.hard, timeouts: 1),
      ),
    );
    final negative = evaluate(
      comparability: assessment(
        first: observations(Difficulty.easy, timeouts: 1),
        second: observations(Difficulty.hard),
      ),
    );

    expect(positive.state,
        TimeoutConcentrationEvaluationState.descriptivelyCompatible);
    expect(positive.context, same(context));
    expect(positive.observedTimeoutRateDifference, 0.5);
    expect(zero.state,
        TimeoutConcentrationEvaluationState.noDirectionalConcentration);
    expect(zero.context, same(context));
    expect(negative.state,
        TimeoutConcentrationEvaluationState.descriptivelyIncompatible);
    expect(negative.context, same(context));
    expect(positive.targetDifficulty, Difficulty.hard);
    expect(positive.comparatorDifficulty, Difficulty.easy);
    expect(positive.timingComparability, TimeoutTimingComparability.comparable);
    expect(positive.authority, TimeoutConcentrationEvaluationAuthority.none);
    expect(positive.mayAffectGameplay, isFalse);
  });

  test('fails closed for incomplete and not comparable EST', () {
    final incomplete = evaluate(
      comparability: assessment(),
      target: Difficulty.easy,
      comparator: Difficulty.easy,
      handoff: topology(
        reference: Difficulty.easy,
        candidate: Difficulty.easy,
        relation: DifficultyCandidateRelation.sameAsReference,
      ),
    );
    final notComparable = evaluate(
      comparability: assessment(
        first: observations(Difficulty.easy),
        second: [
          _observation(_context(Operation.multiplication), Difficulty.hard)
        ],
      ),
    );

    expect(incomplete.notEvaluableReason,
        TimeoutConcentrationNotEvaluableReason.incompleteEvidence);
    expect(incomplete.context, isNull);
    expect(notComparable.notEvaluableReason,
        TimeoutConcentrationNotEvaluableReason.observedComparisonNotComparable);
    expect(notComparable.context, isNull);
  });

  test('preserves not-evaluable reason precedence without context', () {
    final incomplete = assessment();
    final contextMismatch = assessment(
      first: observations(Difficulty.easy),
      second: [
        _observation(_context(Operation.multiplication), Difficulty.hard),
      ],
    );

    final topologyFirst = evaluate(
      comparability: incomplete,
      handoff:
          topology(reference: Difficulty.medium, candidate: Difficulty.hard),
    );
    final observedComparisonFirst = evaluate(
      comparability: contextMismatch,
      timing: TimeoutTimingComparability.unknown,
    );

    expect(
      topologyFirst.notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.topologyPairMismatch,
    );
    expect(topologyFirst.context, isNull);
    expect(
      observedComparisonFirst.notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.observedComparisonNotComparable,
    );
    expect(observedComparisonFirst.context, isNull);
  });

  test('requires supplied timing handoff', () {
    final comparability = assessment(
      first: observations(Difficulty.easy),
      second: observations(Difficulty.hard),
    );

    expect(
      evaluate(
        comparability: comparability,
        timing: TimeoutTimingComparability.unknown,
      ).notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.timingUnknown,
    );
    expect(
      evaluate(
        comparability: comparability,
        timing: TimeoutTimingComparability.notComparable,
      ).notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.timingNotComparable,
    );
  });

  test('requires canonical pair and EST difficulty binding', () {
    final comparability = assessment(
      first: observations(Difficulty.easy),
      second: observations(Difficulty.hard),
    );

    expect(
      evaluate(
        comparability: comparability,
        handoff:
            topology(reference: Difficulty.medium, candidate: Difficulty.hard),
      ).notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.topologyPairMismatch,
    );
    expect(
      evaluate(
        comparability: comparability,
        comparator: Difficulty.medium,
      ).notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.difficultyBindingMismatch,
    );
    expect(
      evaluate(
        comparability: comparability,
        target: Difficulty.medium,
      ).notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.difficultyBindingMismatch,
    );
  });

  test('requires difficulty-may-differ without reinterpreting topology', () {
    const same = BoundedComparabilityRequirement(
      difficulty: BoundedDifficultyComparability.sameDifficultyRequired,
    );
    final comparability = assessment(
      first: observations(Difficulty.easy),
      second: observations(Difficulty.hard),
      value: same,
    );

    expect(
      evaluate(comparability: comparability).notEvaluableReason,
      TimeoutConcentrationNotEvaluableReason.comparisonRequirementMismatch,
    );
    expect(
      evaluate(
        comparability: assessment(
          first: observations(Difficulty.easy),
          second: observations(Difficulty.hard, timeouts: 1),
        ),
        handoff: topology(
          relation: DifficultyCandidateRelation.lowerThanReference,
        ),
      ).state,
      TimeoutConcentrationEvaluationState.descriptivelyCompatible,
    );
  });

  test('is immutable and authority-free', () {
    final result = evaluate(
      comparability: assessment(
        first: observations(Difficulty.easy),
        second: observations(Difficulty.hard),
      ),
    );

    expect(result.authority, TimeoutConcentrationEvaluationAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('source remains a pure EST and topology consumer', () {
    final source = _withoutCommentsAndStrings(File(
      'lib/features/game_brain/scenario/timeout_concentration_evaluator.dart',
    ).readAsStringSync());
    final scenarios = File(
      'lib/features/game_brain/scenario/phase1_difficulty_scenarios.dart',
    ).readAsStringSync();
    final barrel =
        File('lib/features/game_brain/game_brain.dart').readAsStringSync();

    for (final pattern in [
      'Difficulty.values',
      '.index',
      'indexOf(',
      'sort(',
      'sorted',
      'compareTo(',
      'responseTimeMs',
      'Wilson',
      'wilson',
      'P1Study',
      'p1_f01',
      'GameState',
      'TimingStyle',
      'ScenarioKnowledgeLibrary',
      'phase1DifficultyScenarioLibrary',
      'recommend',
      'policy',
      'adaptive',
      'minimum',
      'minN',
      'threshold',
      'significance',
      'pValue',
      'confidenceInterval',
      'precision',
      'ContextEvidenceObservation',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'BoundedOutcomeDescriptiveSummarizer',
    ]) {
      expect(source, isNot(contains(pattern)));
    }
    expect(scenarios, contains('TimeoutConcentrationAtDifficulty'));
    expect(source, contains('BoundedComparabilityState.unresolved'));
    expect(barrel,
        contains("export 'scenario/timeout_concentration_evaluator.dart';"));
  });
}

ContextEvidenceKey _context([Operation operation = Operation.addition]) =>
    ContextEvidenceKey(operation: operation, numberType: NumberType.natural);

ContextEvidenceObservation _observation(
  ContextEvidenceKey context,
  Difficulty difficulty, {
  bool timedOut = false,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: timedOut ? null : 4,
      correct: !timedOut,
      timedOut: timedOut,
      responseTimeMs: 1000,
    );

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
