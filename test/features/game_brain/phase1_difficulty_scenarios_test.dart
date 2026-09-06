import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';

void main() {
  const expectedIds = [
    'StableAtCurrentDifficulty',
    'ProductiveChallengeCandidate',
    'OverchallengeCandidate',
    'UnderchallengeCandidate',
    'SparseHigherDifficultyEvidence',
    'RecentImprovementCandidate',
    'RecentDeclineCandidate',
    'RecoveryCandidate',
    'TimeoutConcentrationAtDifficulty',
    'AssistanceConditionedDifficulty',
  ];

  const expectedContracts = <String, Map<String, List<String>>>{
    'StableAtCurrentDifficulty': <String, List<String>>{
      'requiredObservations': <String>[
        'Bounded outcome evidence for the same factual context and executed difficulty across non-overlapping, provenance-preserving evidence partitions defined by the governing stability protocol.',
        'Partition identity sufficient to prevent cumulative or overlapping snapshots from being treated as separate evidence partitions.',
      ],
      'comparableConditions': <String>[
        'Factual context and executed difficulty must remain comparable across the evidence being examined.',
        'Differences in timing condition, assistance provenance, exposure provenance, answer format, operation, number domain, or other protocol-required dimensions must be controlled, explicitly modeled, or treated as unresolved.',
      ],
      'supportingEvidence': <String>[
        'A separately governed stability analysis finds the bounded outcome pattern compatible across comparable evidence partitions.',
      ],
      'contradictingEvidence': <String>[
        'A separately governed stability analysis affirmatively finds outcome patterns incompatible with stability across otherwise comparable evidence partitions.',
      ],
      'alternativeExplanations': <String>[
        'Apparent stability may result from sparse evidence, overlapping observations, repeated reuse of the same evidence, or an overly broad aggregation.',
        'Context, assistance, timing, or exposure-provenance differences may be hidden by aggregation.',
      ],
      'missingEvidence': <String>[
        'Comparable non-overlapping evidence partitions required by the governing stability protocol are unavailable.',
        'Context or provenance needed to establish comparability is missing or unresolved.',
      ],
      'epistemicRequirements': <String>[
        'Requires a separately governed stability or comparison method with explicit uncertainty and abstention behavior.',
        'Non-overlapping partitions must not be assumed statistically independent unless the governing analytical protocol justifies that assumption.',
        'Deterministic replay or software stability is not scientific evidence of player-performance stability.',
      ],
      'attributionLimitations': <String>[
        'Observed stability does not establish optimal difficulty, ability, mastery, learning, preference, recommendation, or policy suitability.',
      ],
    },
    'ProductiveChallengeCandidate': <String, List<String>>{
      'requiredObservations': <String>[
        'Bounded observable evidence required by a separately governed ProductiveChallenge measurement specification.',
        'Comparator evidence required by that specification.',
        'Every component required by that specification must originate from separately admissible observable facts with preserved provenance.',
      ],
      'comparableConditions': <String>[
        'Target and comparator evidence must satisfy the comparability conditions defined by the governed ProductiveChallenge measurement specification.',
        'Unresolved timing, assistance, exposure-provenance, mode, content-context, or other specification-required differences must prevent unsupported comparison.',
      ],
      'supportingEvidence': <String>[
        'A separately accepted ProductiveChallenge measurement specification is satisfied by governed evidence outputs under its uncertainty and abstention rules.',
      ],
      'contradictingEvidence': <String>[
        'A separately accepted ProductiveChallenge measurement specification affirmatively identifies governed evidence incompatible with the ProductiveChallenge construct.',
      ],
      'alternativeExplanations': <String>[
        'An apparent balance of observed outcomes may arise from sparse exposure, context mixture, assistance, timing, targeted exposure, selection effects, or other unresolved provenance differences.',
        'High, moderate, or low observed accuracy alone does not establish productive challenge.',
      ],
      'missingEvidence': <String>[
        'No accepted ProductiveChallenge measurement specification is available.',
        'Comparator, provenance, uncertainty, or any other evidence required by that specification is unavailable.',
      ],
      'epistemicRequirements': <String>[
        'ProductiveChallengeCandidate is an evaluative construct and cannot be established by an ad-hoc accuracy threshold.',
        'SKL-03 does not define the components of the ProductiveChallenge construct.',
        'Without an accepted observable construct and acceptance protocol, interpretation must abstain.',
      ],
      'attributionLimitations': <String>[
        'Compatibility with ProductiveChallengeCandidate does not establish learning, productive struggle, desirable difficulty, motivation, mastery, preference, recommendation, or gameplay authority.',
      ],
    },
    'OverchallengeCandidate': <String, List<String>>{
      'requiredObservations': <String>[
        'Bounded target-difficulty outcome evidence.',
        'Comparator-difficulty evidence explicitly supplied through the governed Decision Context or scenario protocol.',
        'Canonical candidate relationship or topology supplied by the canonical Decision Owner when the comparison depends on candidate structure.',
      ],
      'comparableConditions': <String>[
        'Target and comparator evidence must satisfy the factual comparability requirements of the governing measurement specification.',
        'GameBrain must not infer comparator identity or adjacency from enum order, numeric value, labels, or historical exposure.',
      ],
      'supportingEvidence': <String>[
        'A separately accepted Overchallenge measurement specification finds the target pattern compatible with OverchallengeCandidate relative to its governed comparator evidence.',
      ],
      'contradictingEvidence': <String>[
        'A separately accepted comparative analysis affirmatively identifies a governed outcome pattern incompatible with OverchallengeCandidate or affirmatively supports a competing pattern under the governing specification.',
      ],
      'alternativeExplanations': <String>[
        'Sparse exposure, timing condition, assistance, targeted exposure, answer format, operation, number domain, mode differences, or selection effects may explain the observed pattern.',
      ],
      'missingEvidence': <String>[
        'Required comparator evidence or canonical candidate topology is unavailable.',
        'Required context, exposure provenance, assistance provenance, uncertainty information, or other specification-required evidence is missing.',
        'Failure to satisfy the supporting criterion alone must be represented as insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'Requires a separately accepted comparative/evaluative measurement specification.',
        'High incorrect or timeout rates alone are insufficient to establish OverchallengeCandidate.',
      ],
      'attributionLimitations': <String>[
        'Compatibility with OverchallengeCandidate does not establish inability, frustration, cognitive overload, fixed capability, need to reduce difficulty, recommendation, or authority.',
      ],
    },
    'UnderchallengeCandidate': <String, List<String>>{
      'requiredObservations': <String>[
        'Bounded target-difficulty outcome evidence.',
        'Comparator evidence capable of testing the Underchallenge construct under a separately accepted measurement specification.',
        'Any structural relationship between candidate difficulties must be supplied by the canonical Decision Owner.',
      ],
      'comparableConditions': <String>[
        'Target and comparator evidence must satisfy the factual comparability requirements of the accepted measurement specification.',
        'Candidate relationships must not be inferred from enum order, labels, numeric values, or historical exposure.',
      ],
      'supportingEvidence': <String>[
        'A separately accepted Underchallenge measurement specification finds the target evidence compatible with UnderchallengeCandidate relative to its governed comparator conditions.',
      ],
      'contradictingEvidence': <String>[
        'A separately accepted comparative analysis affirmatively identifies a governed outcome pattern incompatible with UnderchallengeCandidate or affirmatively supports a competing pattern under the governing specification.',
      ],
      'alternativeExplanations': <String>[
        'High observed success may reflect familiar content, assistance, targeted repetition, context mixture, sparse evidence, selection effects, or other unresolved differences.',
        'Limited errors or timeouts may reflect limited exposure rather than insufficient challenge.',
      ],
      'missingEvidence': <String>[
        'Required comparator evidence or canonical candidate topology is unavailable.',
        'The observable construct required to distinguish successful performance from UnderchallengeCandidate is unavailable.',
        'Failure to satisfy the supporting criterion alone must be represented as insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'UnderchallengeCandidate must not be inferred from accuracy alone.',
        'A separately accepted evaluative construct and comparator protocol are required before supported interpretation.',
      ],
      'attributionLimitations': <String>[
        'Compatibility with UnderchallengeCandidate does not establish mastery, boredom, preference for harder content, readiness for a higher difficulty, recommendation, or gameplay authority.',
      ],
    },
    'SparseHigherDifficultyEvidence': <String, List<String>>{
      'requiredObservations': <String>[
        'Evidence-coverage information for the reference difficulty and for the candidate identified by the canonical Decision Owner as the relevant higher-difficulty comparator.',
        'Provenance sufficient to distinguish absent exposure, missing evidence, filtered evidence, evicted evidence, and admissible observed evidence.',
      ],
      'comparableConditions': <String>[
        'The higher-difficulty relationship must be supplied canonically and must not be inferred from enum order, labels, numeric values, or prior exposure.',
        'Coverage assessment must use evidence within the validity envelope required by the governing evidence-sufficiency protocol.',
      ],
      'supportingEvidence': <String>[
        'The governed evidence-sufficiency or coverage protocol affirmatively classifies the higher-difficulty evidence as insufficient for the intended inference.',
      ],
      'contradictingEvidence': <String>[
        'The governed evidence-sufficiency or coverage protocol affirmatively classifies the higher-difficulty evidence as sufficient for the intended inference.',
      ],
      'alternativeExplanations': <String>[
        'Apparent sparsity may result from missing capture, validity filtering, bounded-memory eviction, or differing opportunity availability rather than lack of exposure alone.',
      ],
      'missingEvidence': <String>[
        'Canonical identification of the relevant higher-difficulty candidate is unavailable.',
        'Evidence provenance is insufficient to distinguish no exposure from missing, excluded, filtered, or evicted evidence.',
      ],
      'epistemicRequirements': <String>[
        'Evidence sufficiency must come from a separately governed protocol; SKL-03 defines no minimum-N threshold.',
        'Sparse evidence requires abstention about fit or capability rather than conversion into negative evidence.',
      ],
      'attributionLimitations': <String>[
        'Sparse higher-difficulty evidence does not establish poor fit, inability, overchallenge, preference, need for exploration, recommendation, or authority.',
      ],
    },
    'RecentImprovementCandidate': <String, List<String>>{
      'requiredObservations': <String>[
        'Temporally ordered recent and reference evidence contained in non-overlapping, provenance-preserving evidence partitions defined by the governing change protocol.',
        'Partition boundaries sufficient to prevent overlapping or cumulative snapshots from being treated as separate temporal evidence partitions.',
        'A separately validated change criterion appropriate to the evidence type and intended claim.',
      ],
      'comparableConditions': <String>[
        'Recent and reference evidence must satisfy the comparability requirements of the validated change protocol.',
        'Context, assistance, timing, exposure provenance, operation, number domain, answer format, and other protocol-required factors must be comparable or explicitly modeled.',
      ],
      'supportingEvidence': <String>[
        'A separately validated change analysis affirmatively identifies positive change under its frozen uncertainty, false-alarm, and abstention rules.',
      ],
      'contradictingEvidence': <String>[
        'A separately validated change analysis affirmatively identifies negative change or another explicitly governed result incompatible with positive change.',
      ],
      'alternativeExplanations': <String>[
        'Sampling variation, regression to the mean, context changes, assistance differences, targeted exposure, selection effects, or overlapping evidence may create apparent recent improvement.',
      ],
      'missingEvidence': <String>[
        'A validated change criterion is unavailable.',
        'Required temporal separation, comparable reference evidence, or provenance is unavailable.',
        'Failure to establish positive change alone is insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'Episode order alone is insufficient.',
        'Observed directional change alone is insufficient for a reliable-change claim.',
        'Non-overlapping partitions must not be assumed statistically independent unless the governing analytical protocol justifies that assumption.',
        'Without an available validated change criterion, reliable RecentImprovementCandidate evaluation must abstain.',
      ],
      'attributionLimitations': <String>[
        'Supported change in bounded measured performance would not by itself establish durable learning, mastery, generalized ability improvement, causal intervention effect, recommendation, or authority.',
      ],
    },
    'RecentDeclineCandidate': <String, List<String>>{
      'requiredObservations': <String>[
        'Temporally ordered recent and reference evidence contained in non-overlapping, provenance-preserving evidence partitions defined by the governing change protocol.',
        'Partition boundaries sufficient to prevent overlapping or cumulative snapshots from being treated as separate temporal evidence partitions.',
        'A separately validated change criterion appropriate to the evidence type and intended claim.',
      ],
      'comparableConditions': <String>[
        'Recent and reference evidence must satisfy the comparability requirements of the validated change protocol.',
        'Context, assistance, timing, exposure provenance, operation, number domain, answer format, and other protocol-required factors must be comparable or explicitly modeled.',
      ],
      'supportingEvidence': <String>[
        'A separately validated change analysis affirmatively identifies negative change under its frozen uncertainty, false-alarm, and abstention rules.',
      ],
      'contradictingEvidence': <String>[
        'A separately validated change analysis affirmatively identifies positive change or another explicitly governed result incompatible with negative change.',
      ],
      'alternativeExplanations': <String>[
        'Sampling variation, regression to the mean, context changes, assistance differences, targeted exposure, selection effects, or overlapping evidence may create apparent recent decline.',
      ],
      'missingEvidence': <String>[
        'A validated change criterion is unavailable.',
        'Required temporal separation, comparable reference evidence, or provenance is unavailable.',
        'Failure to establish negative change alone is insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'Episode order alone is insufficient.',
        'Observed directional change alone is insufficient for a reliable-change claim.',
        'Non-overlapping partitions must not be assumed statistically independent unless the governing analytical protocol justifies that assumption.',
        'Without an available validated change criterion, reliable RecentDeclineCandidate evaluation must abstain.',
      ],
      'attributionLimitations': <String>[
        'Supported negative change in bounded measured performance would not establish loss of ability, loss of mastery, forgetting, motivation change, cognitive decline, recommendation, or authority.',
      ],
    },
    'RecoveryCandidate': <String, List<String>>{
      'requiredObservations': <String>[
        'Temporally ordered evidence capable of representing an earlier adverse pattern and a later positive change or return under the governing Recovery specification.',
        'Non-overlapping, provenance-preserving evidence partitions for every temporal phase required by that specification.',
        'Separately validated change criteria sufficient for every change claim required by the Recovery construct.',
      ],
      'comparableConditions': <String>[
        'Evidence partitions used to establish the earlier and later phases must satisfy the comparability requirements of the governing change protocol.',
        'Overlapping or cumulative snapshots must not be treated as separate recovery phases.',
      ],
      'supportingEvidence': <String>[
        'Governed change analysis affirmatively supports the sequence required by a separately accepted Recovery measurement specification rather than relying on a single favorable later observation.',
      ],
      'contradictingEvidence': <String>[
        'Governed analysis affirmatively identifies a temporal pattern incompatible with the required Recovery sequence, such as supported continuation or worsening where the governing specification requires recovery.',
      ],
      'alternativeExplanations': <String>[
        'Regression to the mean, changing context, assistance, targeted exposure, mode changes, sampling variation, or selective observation may create apparent recovery.',
      ],
      'missingEvidence': <String>[
        'A validated change criterion or required temporal phase is unavailable.',
        'Comparable evidence for an earlier or later phase is missing.',
        'Failure to establish the required Recovery sequence alone is insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'Recovery requires governed temporal/change evidence and cannot be inferred from episode order or one improved snapshot.',
        'Non-overlapping partitions must not be assumed statistically independent unless the governing analytical protocol justifies that assumption.',
        'If reliable change is unavailable, reliable RecoveryCandidate evaluation must abstain.',
      ],
      'attributionLimitations': <String>[
        'Recovery does not establish relearning, resilience, restored mastery, psychological recovery, causal treatment effect, recommendation, or authority.',
      ],
    },
    'TimeoutConcentrationAtDifficulty': <String, List<String>>{
      'requiredObservations': <String>[
        'Valid timeout counts and exposure denominators at the target difficulty.',
        'Valid comparator-difficulty timeout evidence under comparable timing conditions.',
        'Canonically supplied candidate identity or topology when the comparison depends on difficulty structure.',
      ],
      'comparableConditions': <String>[
        'Timing style, timer rules, factual context, and validity envelope must be comparable across target and comparator evidence.',
        'Different timing regimes must not be silently pooled.',
      ],
      'supportingEvidence': <String>[
        'A separately governed comparative analysis affirmatively identifies timeout occurrence as concentrated at the target difficulty according to its accepted comparison criterion.',
      ],
      'contradictingEvidence': <String>[
        'A separately governed comparative analysis affirmatively identifies concentration elsewhere or another governed result explicitly incompatible with target-difficulty timeout concentration.',
      ],
      'alternativeExplanations': <String>[
        'Different timing regimes, timer limits, mode rules, sparse exposure, context differences, assistance, or exposure selection may explain the observed timeout distribution.',
      ],
      'missingEvidence': <String>[
        'Comparator timeout evidence or exposure denominators are unavailable.',
        'Timing conditions required for comparability are missing or unresolved.',
        'Failure to demonstrate target-specific concentration alone is insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'Timeout events may be analyzed only as observed terminal outcomes under their valid timing context.',
        'Recorded wall-clock responseTimeMs must not be used as clean cognitive-latency evidence.',
        'Concentration requires a governed comparative method rather than a raw timeout count alone.',
      ],
      'attributionLimitations': <String>[
        'Timeout concentration does not establish slowness, processing speed, cognitive load, ability, overchallenge, preference, recommendation, or authority.',
      ],
    },
    'AssistanceConditionedDifficulty': <String, List<String>>{
      'requiredObservations': <String>[
        'Question-level evidence distinguishing assisted from unassisted exposure at the same executed difficulty.',
        'Assistance provenance sufficient to identify the assistance condition actually applicable to each observed question outcome.',
        'Comparable outcome evidence across the assistance conditions required by the governing specification.',
      ],
      'comparableConditions': <String>[
        'Assisted and unassisted evidence must be comparable on executed difficulty and the factual dimensions required by the governing specification.',
        'Assistance availability, activation, application, and usage must not be treated as interchangeable states.',
      ],
      'supportingEvidence': <String>[
        'A separately governed conditioned comparison affirmatively identifies an outcome pattern associated with assistance condition at the target difficulty.',
      ],
      'contradictingEvidence': <String>[
        'A separately governed conditioned comparison affirmatively identifies an opposite conditioned association or another governed result explicitly incompatible with the scenario\'s required conditioned pattern.',
      ],
      'alternativeExplanations': <String>[
        'Player self-selection into assistance, assistance type, question difficulty, timing, targeted exposure, mode, and other contextual differences may confound the observed association.',
      ],
      'missingEvidence': <String>[
        'Exact question-level assistance application provenance is unavailable or ambiguous.',
        'Comparable assisted or unassisted evidence is unavailable.',
        'Failure to demonstrate an assistance-conditioned pattern alone is insufficient or not evaluable rather than contradicting evidence.',
      ],
      'epistemicRequirements': <String>[
        'Aggregate power-up inventory or availability is insufficient to establish assistance-conditioned outcome evidence.',
        'Association must remain non-causal unless a separately valid causal design supports attribution.',
        'Incomplete assistance provenance requires NOT_EVALUABLE or INSUFFICIENT rather than inferred usage.',
      ],
      'attributionLimitations': <String>[
        'Assistance-conditioned association does not establish assistance effectiveness, assistance need, dependence, ability, mastery, preference, recommendation, or gameplay authority.',
      ],
    },
  };

  final entries = phase1DifficultyScenarioLibrary.entries;

  test('freezes the ten canonical identities in reference order', () {
    expect(entries, hasLength(10));
    expect(entries.map((entry) => entry.definition.id), expectedIds);
    expect(entries.map((entry) => entry.definition.name), expectedIds);
    expect(entries.map((entry) => entry.definition.id).toSet(), hasLength(10));
  });

  test('keeps definitions proposed, versioned, and contract-frozen', () {
    for (final entry in entries) {
      final definition = entry.definition;
      expect(definition.version, 1);
      expect(entry.acceptanceState, ScenarioAcceptanceState.proposed);
      expect(
        definition.questionBeingTested,
        'Is bounded evidence consistent with ${definition.name}?',
      );
      for (final requirements in [
        definition.requiredObservations,
        definition.comparableConditions,
        definition.supportingEvidence,
        definition.contradictingEvidence,
        definition.alternativeExplanations,
        definition.missingEvidence,
        definition.epistemicRequirements,
        definition.attributionLimitations,
      ]) {
        expect(requirements, isNotEmpty);
        expect(() => requirements.clear(), throwsUnsupportedError);
      }
    }
  });

  test('freezes every evidence-contract field verbatim', () {
    for (final entry in entries) {
      final definition = entry.definition;
      expect(
        <String, List<String>>{
          'requiredObservations': definition.requiredObservations,
          'comparableConditions': definition.comparableConditions,
          'supportingEvidence': definition.supportingEvidence,
          'contradictingEvidence': definition.contradictingEvidence,
          'alternativeExplanations': definition.alternativeExplanations,
          'missingEvidence': definition.missingEvidence,
          'epistemicRequirements': definition.epistemicRequirements,
          'attributionLimitations': definition.attributionLimitations,
        },
        expectedContracts[definition.id],
      );
    }
  });

  test('exposes no accepted or gameplay-authoritative scenario', () {
    expect(phase1DifficultyScenarioLibrary.acceptedDefinitions, isEmpty);
    for (final id in expectedIds) {
      expect(phase1DifficultyScenarioLibrary.acceptedById(id), isNull);
      expect(phase1DifficultyScenarioLibrary.acceptedById(id.toLowerCase()),
          isNull);
    }
    for (final entry in entries) {
      expect(entry.authority, ScenarioKnowledgeAuthority.none);
      expect(entry.mayAffectGameplay, isFalse);
    }
  });

  test('keeps the preloaded entry list immutable', () {
    expect(() => entries.clear(), throwsUnsupportedError);
  });

  test('catalog source introduces no behavior or evaluation APIs', () {
    final source = File(
      'lib/features/game_brain/scenario/phase1_difficulty_scenarios.dart',
    ).readAsStringSync();
    final codeOnly = source
        .replaceAll(RegExp(r"'(?:\\.|[^'\\])*'"), '')
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .replaceAll(RegExp(r'//.*'), '');
    final forbiddenCodeUse = RegExp(
      r'\b(?:rank|priority|precedence|recommend|preferred|policy|action|'
      r'match|evaluate|score|probability|bestScenario|preferredScenario|'
      r'minimumN|minN|minimumSampleSize|sampleSizeThreshold|'
      r'accuracyThreshold|timeoutThreshold|decisionThreshold)\w*\s*'
      r'(?:\(|:|=|;)',
    );
    final forbiddenDeclaration = RegExp(
      r'\b(?:final|var|const|class|enum|typedef|extension|mixin|'
      r'bool|int|double|num|String|Object|dynamic|void|[A-Z]\w*)\s+'
      r'(?:rank|priority|precedence|recommend|preferred|policy|action|'
      r'match|evaluate|score|probability|bestScenario|preferredScenario|'
      r'minimumN|minN|minimumSampleSize|sampleSizeThreshold|'
      r'accuracyThreshold|timeoutThreshold|decisionThreshold)\w*\b',
    );

    expect(forbiddenCodeUse.hasMatch(codeOnly), isFalse);
    expect(forbiddenDeclaration.hasMatch(codeOnly), isFalse);
    expect(codeOnly, isNot(contains('ValidatedChangeReceipt(')));
    expect(codeOnly, isNot(contains('validatedChangeReceipt:')));
    expect(source, isNot(contains('responseTimeMs:')));
    expect(source, isNot(contains('assistanceUsage:')));
    expect(source, isNot(contains('assistanceApplication:')));
  });
}
