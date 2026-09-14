import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const assembler = ChooseDifficultyCandidateEvaluationAssembler();
  const preserver = ChooseDifficultyEpistemicPreserver();
  const contributionSynthesizer = TimeoutScenarioCandidateEvidenceSynthesizer();
  const sliceSynthesizer = TimeoutPlayerDifficultyEvidenceSynthesizer();
  final context = _context(Operation.addition);

  TimeoutScenarioCandidateEvidenceContribution contribution({
    required Difficulty candidate,
    required Difficulty comparator,
    required (bool, bool) timeouts,
  }) {
    final memory = TimeoutConcentrationScenarioEvidenceMemory(capacity: 1);
    final scenarioLibrary = _scenarioLibrary();
    memory.record(
      scenarioLibrary: scenarioLibrary,
      match: _match(
        scenarioLibrary: scenarioLibrary,
        context: context,
        target: candidate,
        comparator: comparator,
        timeouts: timeouts,
      ),
    );
    return contributionSynthesizer.synthesize(
      evidence: sliceSynthesizer.synthesize(
        memory: memory,
        context: context,
        targetDifficulty: candidate,
        comparatorDifficulty: comparator,
      ),
    );
  }

  test('preserves candidate evidence literally without a verdict', () {
    final aggregate = const BoundedContextShadowInterpreter().interpret([
      _observation(context: context, difficulty: Difficulty.hard),
    ]).aggregate!;
    final first = contribution(
      candidate: Difficulty.easy,
      comparator: Difficulty.hard,
      timeouts: (false, true),
    );
    final second = contribution(
      candidate: Difficulty.easy,
      comparator: Difficulty.medium,
      timeouts: (true, false),
    );
    final third = contribution(
      candidate: Difficulty.easy,
      comparator: Difficulty.hard,
      timeouts: (false, false),
    );
    final evaluationSet = assembler.assemble(
      snapshot: _snapshot(context, [
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
      ]),
      timeoutContributions: [first, second, first, third],
    );

    final result = preserver.preserve(evaluationSet: evaluationSet);

    expect(result.sourceEvaluationSet, same(evaluationSet));
    expect(result.context, same(context));
    expect(result.candidates, hasLength(evaluationSet.evaluations.length));
    expect(result.candidates.map((item) => item.candidateDifficulty), [
      Difficulty.hard,
      Difficulty.easy,
      Difficulty.medium,
    ]);
    for (var index = 0; index < result.candidates.length; index++) {
      final candidate = result.candidates[index];
      final source = evaluationSet.evaluations[index];
      expect(candidate.sourceEvaluation, same(source));
      expect(candidate.candidateDifficulty, source.candidateDifficulty);
      expect(candidate.availability, source.availability);
    }
    final BoundedContextAggregate? typedAggregate =
        result.candidates.first.aggregate;
    expect(typedAggregate, same(aggregate));
    expect(result.candidates[1].timeoutContributions,
        same(evaluationSet.evaluations[1].timeoutContributions));
    expect(result.candidates[1].timeoutContributions,
        orderedEquals([first, second, first, third]));
    expect(result.candidates[1].timeoutContributions[0], same(first));
    expect(result.candidates[1].timeoutContributions[1], same(second));
    expect(
      result.candidates[1].timeoutContributions
          .expand((item) => item.dispositions),
      containsAll([
        TimeoutConcentrationScenarioMatchState.matched,
        TimeoutConcentrationScenarioMatchState.contradicted,
        TimeoutConcentrationScenarioMatchState.notMatched,
      ]),
    );
    expect(result.candidates.first.availability,
        ChooseDifficultyEvidenceAvailability.present);
    expect(result.candidates.first.timeoutContributions, isEmpty);
    expect(result.candidates[1].availability,
        ChooseDifficultyEvidenceAvailability.absent);
    expect(result.candidates[2].timeoutContributions, isEmpty);
    expect(() => result.candidates.clear(), throwsUnsupportedError);
    expect(
        result.authority, ChooseDifficultyEpistemicPreservationAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
    expect(result.candidates.first.authority,
        ChooseDifficultyEpistemicPreservationAuthority.none);
    expect(result.candidates.first.mayAffectGameplay, isFalse);
  });

  test('preserves empty sets and repeats deterministically', () {
    final empty = assembler.assemble(
      snapshot: _snapshot(context, []),
      timeoutContributions: const [],
    );
    final first = preserver.preserve(evaluationSet: empty);
    final second = preserver.preserve(evaluationSet: empty);

    expect(first.sourceEvaluationSet, same(empty));
    expect(first.candidates, isEmpty);
    expect(second.sourceEvaluationSet, same(empty));
    expect(second.candidates, isEmpty);
  });

  test('source remains a lossless candidate-evidence passthrough', () {
    final rawSource = File(
      'lib/features/game_brain/evaluation/'
      'choose_difficulty_candidate_epistemic_preservation.dart',
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
        "import 'choose_difficulty_candidate_evaluation.dart';",
        "import 'timeout_scenario_candidate_evidence_contribution.dart';",
      ]),
    );
    for (final prohibited in [
      'ContextEvidenceObservation',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'DifficultyCandidateTopologyHandoff',
      'ScenarioKnowledgeLibrary',
      'TimeoutConcentrationEvaluator',
      'TimeoutConcentrationScenarioMatcher',
      'TimeoutConcentrationScenarioEvidenceMemory',
      'TimeoutPlayerDifficultyEvidenceSynthesizer',
      'GameState',
      'Recommendation',
      'Policy',
      'Adaptive',
      'SharedPreferences',
      'database',
      'telemetry',
    ]) {
      expect(source.toLowerCase(), isNot(contains(prohibited.toLowerCase())));
    }
    for (final token in [
      'mastery',
      'ability',
      'confidence',
      'probability',
      'threshold',
      'reliableChange',
      'recency',
      'majority',
    ]) {
      expect(
          source, isNot(matches(RegExp('\\b$token\\b', caseSensitive: false))));
    }
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
        Difficulty.hard
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
