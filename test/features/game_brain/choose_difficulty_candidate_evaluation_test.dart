import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const assembler = ChooseDifficultyCandidateEvaluationAssembler();
  const contributionSynthesizer = TimeoutScenarioCandidateEvidenceSynthesizer();
  const sliceSynthesizer = TimeoutPlayerDifficultyEvidenceSynthesizer();
  final context = _context(Operation.addition);
  final otherContext = _context(Operation.multiplication);

  TimeoutScenarioCandidateEvidenceContribution contribution({
    required Difficulty candidate,
    required Difficulty comparator,
    required ContextEvidenceKey contributionContext,
    required (bool, bool) timeouts,
  }) {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
    final scenarioLibrary = _scenarioLibrary();
    memory.record(
      scenarioLibrary: scenarioLibrary,
      match: _match(
        scenarioLibrary: scenarioLibrary,
        context: contributionContext,
        target: candidate,
        comparator: comparator,
        timeouts: timeouts,
      ),
    );
    return contributionSynthesizer.synthesize(
      evidence: sliceSynthesizer.synthesize(
        memory: memory,
        context: contributionContext,
        targetDifficulty: candidate,
        comparatorDifficulty: comparator,
      ),
    );
  }

  test('assembles literal candidate order with exact evidence identities', () {
    final aggregate = const BoundedContextShadowInterpreter().interpret([
      _observation(context: context, difficulty: Difficulty.hard),
    ]).aggregate!;
    final snapshot = _snapshot(context, [
      ChooseDifficultyCandidateEvidence(
        candidate: Difficulty.hard,
        availability: ChooseDifficultyEvidenceAvailability.present,
        aggregate: aggregate,
      ),
      ChooseDifficultyCandidateEvidence(
        candidate: Difficulty.easy,
        availability: ChooseDifficultyEvidenceAvailability.absent,
        aggregate: null,
      ),
      ChooseDifficultyCandidateEvidence(
        candidate: Difficulty.medium,
        availability: ChooseDifficultyEvidenceAvailability.absent,
        aggregate: null,
      ),
    ]);
    final hardFirst = contribution(
      candidate: Difficulty.hard,
      comparator: Difficulty.easy,
      contributionContext: context,
      timeouts: (false, true),
    );
    final hardSecond = contribution(
      candidate: Difficulty.hard,
      comparator: Difficulty.medium,
      contributionContext: context,
      timeouts: (true, false),
    );
    final medium = contribution(
      candidate: Difficulty.medium,
      comparator: Difficulty.easy,
      contributionContext: context,
      timeouts: (true, true),
    );

    final result = assembler.assemble(
      snapshot: snapshot,
      timeoutContributions: [hardFirst, hardSecond, hardFirst, medium],
    );

    expect(result.context, same(context));
    expect(result.evaluations.map((item) => item.candidateDifficulty),
        [Difficulty.hard, Difficulty.easy, Difficulty.medium]);
    for (var i = 0; i < snapshot.candidates.length; i++) {
      expect(result.evaluations[i].candidateEvidence,
          same(snapshot.candidates[i]));
      expect(result.evaluations[i].availability,
          snapshot.candidates[i].availability);
    }
    final BoundedContextAggregate? typedAggregate =
        result.evaluations.first.aggregate;
    expect(typedAggregate, same(aggregate));
    expect(result.evaluations[0].timeoutContributions,
        orderedEquals([hardFirst, hardSecond, hardFirst]));
    expect(result.evaluations[0].timeoutContributions[0], same(hardFirst));
    expect(result.evaluations[0].timeoutContributions[1], same(hardSecond));
    expect(result.evaluations[1].timeoutContributions, isEmpty);
    expect(result.evaluations[2].timeoutContributions, orderedEquals([medium]));
    expect(result.evaluations[0].timeoutContributions[0].comparatorDifficulty,
        Difficulty.easy);
    expect(result.evaluations[0].timeoutContributions[1].comparatorDifficulty,
        Difficulty.medium);
    expect(
      result.evaluations[0].timeoutContributions
          .expand((item) => item.dispositions),
      containsAll([
        TimeoutConcentrationScenarioMatchState.matched,
        TimeoutConcentrationScenarioMatchState.contradicted,
      ]),
    );
    expect(() => result.evaluations.clear(), throwsUnsupportedError);
    expect(() => result.evaluations.first.timeoutContributions.clear(),
        throwsUnsupportedError);
    expect(result.authority, ChooseDifficultyCandidateEvaluationAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
    expect(result.evaluations.first.authority,
        ChooseDifficultyCandidateEvaluationAuthority.none);
    expect(result.evaluations.first.mayAffectGameplay, isFalse);
  });

  test(
      'materializes once, validates all contributions, then remains deterministic',
      () {
    final snapshot = _snapshot(context, [_absent(Difficulty.easy)]);
    final valid = contribution(
      candidate: Difficulty.easy,
      comparator: Difficulty.hard,
      contributionContext: context,
      timeouts: (true, true),
    );
    var iterations = 0;
    Iterable<TimeoutScenarioCandidateEvidenceContribution> supplied() sync* {
      iterations++;
      yield valid;
    }

    final first = assembler.assemble(
      snapshot: snapshot,
      timeoutContributions: supplied(),
    );
    final second = assembler.assemble(
      snapshot: snapshot,
      timeoutContributions: [valid],
    );

    expect(iterations, 1);
    expect(first.evaluations.single.timeoutContributions.single, same(valid));
    expect(second.evaluations.single.timeoutContributions.single, same(valid));
  });

  test('rejects a mismatched context or candidate outside snapshot', () {
    final snapshot = _snapshot(context, [_absent(Difficulty.easy)]);
    final mismatchedContext = contribution(
      candidate: Difficulty.easy,
      comparator: Difficulty.hard,
      contributionContext: otherContext,
      timeouts: (true, true),
    );
    final outsideCandidate = contribution(
      candidate: Difficulty.hard,
      comparator: Difficulty.easy,
      contributionContext: context,
      timeouts: (false, true),
    );

    for (final malformed in [mismatchedContext, outsideCandidate]) {
      expect(
        () => assembler.assemble(
          snapshot: snapshot,
          timeoutContributions: [malformed],
        ),
        throwsArgumentError,
      );
    }
  });

  test('source stays a candidate-scoped evidence assembly only', () {
    final rawSource = File(
      'lib/features/game_brain/evaluation/'
      'choose_difficulty_candidate_evaluation.dart',
    ).readAsStringSync();
    final source = _withoutCommentsAndStrings(rawSource);
    expect(
      RegExp(r'\bimport\s+[^;]+;')
          .allMatches(rawSource)
          .map((match) => match.group(0)),
      unorderedEquals([
        "import '../../../models/enums.dart';",
        "import '../decision/choose_difficulty_evidence_snapshot.dart';",
        "import '../domain/context_evidence.dart';",
        "import '../interpretation/bounded_context_shadow_interpreter.dart';",
        "import 'timeout_scenario_candidate_evidence_contribution.dart';",
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
      'TimeoutConcentrationScenarioEvidenceMemory',
      'TimeoutPlayerDifficultyEvidenceSynthesizer',
      'GameState',
      'LearnerSnapshot',
      'Recommendation',
      'Policy',
      'Adaptive',
      'SharedPreferences',
      'database',
      'telemetry',
      'mastery',
      'confidence',
      'probability',
      'threshold',
      'minimum',
      'Difficulty.values',
      '.index',
      '.sort(',
      '.record(',
    ]) {
      expect(source.toLowerCase(), isNot(contains(prohibited.toLowerCase())));
    }
    expect(source.toLowerCase(), isNot(matches(r'\bability\b')));
    expect(source, isNot(matches(r'\b(export|part)\b')));
  });
}

ChooseDifficultyEvidenceSnapshot _snapshot(
  ContextEvidenceKey context,
  List<ChooseDifficultyCandidateEvidence> candidates,
) =>
    ChooseDifficultyEvidenceSnapshot(
      context: context,
      legalCandidates:
          candidates.map((candidate) => candidate.candidate).toList(),
      candidates: candidates,
    );

ChooseDifficultyCandidateEvidence _absent(Difficulty difficulty) =>
    ChooseDifficultyCandidateEvidence(
      candidate: difficulty,
      availability: ChooseDifficultyEvidenceAvailability.absent,
      aggregate: null,
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

TimeoutConcentrationScenarioMatch _match({
  required ScenarioKnowledgeLibrary scenarioLibrary,
  required ContextEvidenceKey context,
  required Difficulty target,
  required Difficulty comparator,
  required (bool, bool) timeouts,
}) {
  ContextEvidenceObservation observation(
          Difficulty difficulty, bool timedOut) =>
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

ContextEvidenceKey _context(Operation operation) =>
    ContextEvidenceKey(operation: operation, numberType: NumberType.natural);

ContextEvidenceObservation _observation({
  required ContextEvidenceKey context,
  required Difficulty difficulty,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: 4,
      correct: true,
      timedOut: false,
      responseTimeMs: 1000,
    );

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
