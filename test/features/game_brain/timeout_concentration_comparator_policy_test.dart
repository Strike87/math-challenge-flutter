import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  final context = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );

  test('identity is frozen and preferred output has no authority', () {
    final policy = TimeoutConcentrationComparatorPolicy();
    final contribution = _contribution(
      context: context,
      target: Difficulty.hard,
      comparator: Difficulty.medium,
      states: const [TimeoutConcentrationScenarioMatchState.matched],
    );
    final source = _source(
      context: context,
      candidates: [
        _present(context, Difficulty.hard),
        _present(context, Difficulty.medium),
      ],
      contributions: [contribution],
    );

    final resolution = policy.resolve(evidence: source);

    expect(policy.identity.id, 'timeout_concentration_comparator_preference');
    expect(policy.identity.version, 1);
    expect(resolution, isA<ChooseDifficultyPreferredCandidate>());

    final preferred = resolution as ChooseDifficultyPreferredCandidate;
    expect(preferred.source, same(source));
    expect(preferred.candidate, Difficulty.medium);
    expect(preferred.authority, ChooseDifficultyPolicyAuthority.none);
    expect(preferred.mayAffectGameplay, isFalse);
  });

  test('candidate order has no semantic meaning', () {
    final policy = TimeoutConcentrationComparatorPolicy();
    final contribution = _contribution(
      context: context,
      target: Difficulty.hard,
      comparator: Difficulty.medium,
      states: const [TimeoutConcentrationScenarioMatchState.matched],
    );

    for (final candidates in [
      [
        _present(context, Difficulty.hard),
        _present(context, Difficulty.medium),
      ],
      [
        _present(context, Difficulty.medium),
        _present(context, Difficulty.hard),
      ],
    ]) {
      final result = policy.resolve(
        evidence: _source(
          context: context,
          candidates: candidates,
          contributions: [contribution],
        ),
      );

      expect(result, isA<ChooseDifficultyPreferredCandidate>());
      expect(
        (result as ChooseDifficultyPreferredCandidate).candidate,
        Difficulty.medium,
      );
    }
  });

  test('does not infer Easy Medium Hard ordinal meaning', () {
    final policy = TimeoutConcentrationComparatorPolicy();
    final result = policy.resolve(
      evidence: _source(
        context: context,
        candidates: [
          _present(context, Difficulty.easy),
          _present(context, Difficulty.hard),
        ],
        contributions: [
          _contribution(
            context: context,
            target: Difficulty.easy,
            comparator: Difficulty.hard,
            states: const [TimeoutConcentrationScenarioMatchState.matched],
          ),
        ],
      ),
    );

    expect(result, isA<ChooseDifficultyPreferredCandidate>());
    expect(
      (result as ChooseDifficultyPreferredCandidate).candidate,
      Difficulty.hard,
    );
  });

  test('abstains outside the frozen context envelope', () {
    final policy = TimeoutConcentrationComparatorPolicy();

    final outsideContexts = [
      ContextEvidenceKey(
        operation: Operation.multiplication,
        numberType: NumberType.natural,
      ),
      ContextEvidenceKey(
        operation: Operation.addition,
        numberType: NumberType.integers,
      ),
    ];

    for (final outsideContext in outsideContexts) {
      final contribution = _contribution(
        context: outsideContext,
        target: Difficulty.hard,
        comparator: Difficulty.medium,
        states: const [TimeoutConcentrationScenarioMatchState.matched],
      );

      final source = _source(
        context: outsideContext,
        candidates: [
          _present(outsideContext, Difficulty.hard),
          _present(outsideContext, Difficulty.medium),
        ],
        contributions: [contribution],
      );

      expect(
        policy.resolve(evidence: source),
        isA<ChooseDifficultyNoPreference>(),
      );
    }
  });
  test('abstains outside exact two-present-candidate envelope', () {
    final policy = TimeoutConcentrationComparatorPolicy();

    final sources = [
      _source(
        context: context,
        candidates: const [],
        contributions: const [],
      ),
      _source(
        context: context,
        candidates: [_present(context, Difficulty.hard)],
        contributions: const [],
      ),
      _source(
        context: context,
        candidates: [
          _present(context, Difficulty.easy),
          _present(context, Difficulty.medium),
          _present(context, Difficulty.hard),
        ],
        contributions: const [],
      ),
      _source(
        context: context,
        candidates: [
          _present(context, Difficulty.hard),
          _absent(Difficulty.medium),
        ],
        contributions: const [],
      ),
    ];

    for (final source in sources) {
      expect(
        policy.resolve(evidence: source),
        isA<ChooseDifficultyNoPreference>(),
      );
    }
  });

  test('requires exactly one one-entry matched contribution', () {
    final policy = TimeoutConcentrationComparatorPolicy();

    final contributionCases =
        <List<TimeoutScenarioCandidateEvidenceContribution>>[
      const [],
      [
        _contribution(
          context: context,
          target: Difficulty.hard,
          comparator: Difficulty.medium,
          states: const [],
        ),
      ],
      [
        _contribution(
          context: context,
          target: Difficulty.hard,
          comparator: Difficulty.medium,
          states: const [TimeoutConcentrationScenarioMatchState.notMatched],
        ),
      ],
      [
        _contribution(
          context: context,
          target: Difficulty.hard,
          comparator: Difficulty.medium,
          states: const [TimeoutConcentrationScenarioMatchState.contradicted],
        ),
      ],
      [
        _contribution(
          context: context,
          target: Difficulty.hard,
          comparator: Difficulty.medium,
          states: const [
            TimeoutConcentrationScenarioMatchState.matched,
            TimeoutConcentrationScenarioMatchState.matched,
          ],
        ),
      ],
      [
        _contribution(
          context: context,
          target: Difficulty.hard,
          comparator: Difficulty.medium,
          states: const [
            TimeoutConcentrationScenarioMatchState.matched,
            TimeoutConcentrationScenarioMatchState.notMatched,
          ],
        ),
      ],
    ];

    for (final contributions in contributionCases) {
      final source = _source(
        context: context,
        candidates: [
          _present(context, Difficulty.hard),
          _present(context, Difficulty.medium),
        ],
        contributions: contributions,
      );

      expect(
        policy.resolve(evidence: source),
        isA<ChooseDifficultyNoPreference>(),
      );
    }
  });

  test('abstains on duplicate or competing contributions', () {
    final policy = TimeoutConcentrationComparatorPolicy();

    final hardToMedium = _contribution(
      context: context,
      target: Difficulty.hard,
      comparator: Difficulty.medium,
      states: const [TimeoutConcentrationScenarioMatchState.matched],
    );
    final mediumToHard = _contribution(
      context: context,
      target: Difficulty.medium,
      comparator: Difficulty.hard,
      states: const [TimeoutConcentrationScenarioMatchState.matched],
    );

    for (final contributions in [
      [hardToMedium, hardToMedium],
      [hardToMedium, mediumToHard],
    ]) {
      final source = _source(
        context: context,
        candidates: [
          _present(context, Difficulty.hard),
          _present(context, Difficulty.medium),
        ],
        contributions: contributions,
      );

      expect(
        policy.resolve(evidence: source),
        isA<ChooseDifficultyNoPreference>(),
      );
    }
  });

  test('abstains when comparator is outside set or equals target', () {
    final policy = TimeoutConcentrationComparatorPolicy();

    final cases = [
      _contribution(
        context: context,
        target: Difficulty.hard,
        comparator: Difficulty.easy,
        states: const [TimeoutConcentrationScenarioMatchState.matched],
      ),
      _contribution(
        context: context,
        target: Difficulty.hard,
        comparator: Difficulty.hard,
        states: const [TimeoutConcentrationScenarioMatchState.matched],
      ),
    ];

    for (final contribution in cases) {
      final source = _source(
        context: context,
        candidates: [
          _present(context, Difficulty.hard),
          _present(context, Difficulty.medium),
        ],
        contributions: [contribution],
      );

      expect(
        policy.resolve(evidence: source),
        isA<ChooseDifficultyNoPreference>(),
      );
    }
  });

  test('production source remains bounded and non-authoritative', () {
    final rawSource = File(
      'lib/features/game_brain/policy/'
      'timeout_concentration_comparator_policy.dart',
    ).readAsStringSync();

    final source = _withoutCommentsAndStrings(rawSource).toLowerCase();

    for (final prohibited in [
      'gamestate',
      'adaptive',
      'sharedpreferences',
      'firebase',
      'telemetry',
      'analytics',
      'mastery',
      'score',
      'utility',
      'reward',
      'threshold',
      'datetime',
      'random',
      'difficulty.values',
      '.index',
      '.sort(',
      'timeoutconcentrationevaluator',
      'boundedoutcomecomparator',
      'boundedcomparabilityassessor',
    ]) {
      expect(source, isNot(contains(prohibited)));
    }

    expect(
      source,
      isNot(matches(RegExp(r'\bability\b'))),
    );
  });
}

ChooseDifficultyEpistemicPreservationSet _source({
  required ContextEvidenceKey context,
  required List<ChooseDifficultyCandidateEvidence> candidates,
  required List<TimeoutScenarioCandidateEvidenceContribution> contributions,
}) {
  final snapshot = ChooseDifficultyEvidenceSnapshot(
    context: context,
    legalCandidates: [
      for (final candidate in candidates) candidate.candidate,
    ],
    candidates: candidates,
  );

  final evaluations =
      const ChooseDifficultyCandidateEvaluationAssembler().assemble(
    snapshot: snapshot,
    timeoutContributions: contributions,
  );

  return const ChooseDifficultyEpistemicPreserver().preserve(
    evaluationSet: evaluations,
  );
}

ChooseDifficultyCandidateEvidence _present(
  ContextEvidenceKey context,
  Difficulty difficulty,
) {
  final aggregate = const BoundedContextShadowInterpreter().interpret([
    _observation(
      context: context,
      difficulty: difficulty,
      timedOut: false,
    ),
  ]).aggregate!;

  return ChooseDifficultyCandidateEvidence(
    candidate: difficulty,
    availability: ChooseDifficultyEvidenceAvailability.present,
    aggregate: aggregate,
  );
}

ChooseDifficultyCandidateEvidence _absent(Difficulty difficulty) =>
    ChooseDifficultyCandidateEvidence(
      candidate: difficulty,
      availability: ChooseDifficultyEvidenceAvailability.absent,
      aggregate: null,
    );

TimeoutScenarioCandidateEvidenceContribution _contribution({
  required ContextEvidenceKey context,
  required Difficulty target,
  required Difficulty comparator,
  required List<TimeoutConcentrationScenarioMatchState> states,
}) {
  final scenarioLibrary = _scenarioLibrary();
  final memory = TimeoutConcentrationScenarioEvidenceMemory(
    capacity: states.isEmpty ? 1 : states.length,
  );

  for (final state in states) {
    memory.record(
      scenarioLibrary: scenarioLibrary,
      match: _match(
        scenarioLibrary: scenarioLibrary,
        context: context,
        target: target,
        comparator: comparator,
        state: state,
      ),
    );
  }

  final slice = const TimeoutPlayerDifficultyEvidenceSynthesizer().synthesize(
    memory: memory,
    context: context,
    targetDifficulty: target,
    comparatorDifficulty: comparator,
  );

  return const TimeoutScenarioCandidateEvidenceSynthesizer().synthesize(
    evidence: slice,
  );
}

TimeoutConcentrationScenarioMatch _match({
  required ScenarioKnowledgeLibrary scenarioLibrary,
  required ContextEvidenceKey context,
  required Difficulty target,
  required Difficulty comparator,
  required TimeoutConcentrationScenarioMatchState state,
}) {
  final timing = switch (state) {
    TimeoutConcentrationScenarioMatchState.matched => (false, true),
    TimeoutConcentrationScenarioMatchState.notMatched => (false, false),
    TimeoutConcentrationScenarioMatchState.contradicted => (true, false),
    TimeoutConcentrationScenarioMatchState.notEvaluable =>
      throw ArgumentError('notEvaluable is not recordable'),
  };

  final comparison = const BoundedOutcomeComparator().compare(
    firstObservations: [
      _observation(
        context: context,
        difficulty: comparator,
        timedOut: timing.$1,
      ),
    ],
    secondObservations: [
      _observation(
        context: context,
        difficulty: target,
        timedOut: timing.$2,
      ),
    ],
  );

  final evaluation = const TimeoutConcentrationEvaluator().evaluate(
    targetDifficulty: target,
    comparatorDifficulty: comparator,
    topology: DifficultyCandidateTopologyHandoff(
      reference: comparator,
      candidate: target,
      relation: _relation(reference: comparator, candidate: target),
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

DifficultyCandidateRelation _relation({
  required Difficulty reference,
  required Difficulty candidate,
}) {
  if (reference == candidate) {
    return DifficultyCandidateRelation.sameAsReference;
  }

  if (reference == Difficulty.easy ||
      (reference == Difficulty.medium && candidate == Difficulty.hard)) {
    return DifficultyCandidateRelation.higherThanReference;
  }

  return DifficultyCandidateRelation.lowerThanReference;
}

ContextEvidenceObservation _observation({
  required ContextEvidenceKey context,
  required Difficulty difficulty,
  required bool timedOut,
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

ScenarioKnowledgeLibrary _scenarioLibrary() => ScenarioKnowledgeLibrary([
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

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
