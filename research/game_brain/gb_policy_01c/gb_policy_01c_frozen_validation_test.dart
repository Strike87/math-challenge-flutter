import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

const repetitionsPerFixture = 100;
const _manifestPath =
    'research/game_brain/gb_policy_01c/validation_fixture_manifest_v1.json';
const _resultPath =
    'build/game_brain/gb_policy_01c/frozen_validation_result.json';

void main() {
  test('GB-POLICY-01C frozen semantic validation', () {
    final manifest =
        _FrozenManifest.parse(File(_manifestPath).readAsStringSync());
    final policy = TimeoutConcentrationComparatorPolicy();
    expect(policy.identity.id, 'timeout_concentration_comparator_preference');
    expect(policy.identity.version, 1);

    final result = _runFrozenValidation(manifest: manifest, policy: policy);
    final output = File(_resultPath);
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(jsonEncode(result.toJson()));

    expect(result.semanticCriteriaPass, isTrue,
        reason: jsonEncode(result.toJson()));
  });
}

_ValidationResult _runFrozenValidation({
  required _FrozenManifest manifest,
  required TimeoutConcentrationComparatorPolicy policy,
}) {
  var fixtureExactResolutionCount = 0;
  var deterministicRepeatMatchCount = 0;
  var preferredCandidateMembershipViolations = 0;
  var authorityViolations = 0;
  var mayAffectGameplayViolations = 0;
  final fixtureResults = <_FixtureResult>[];

  for (final fixture in manifest.fixtures) {
    String? baseline;
    var exactMatchCount = 0;
    var repeatMatchCount = 0;
    final observed = <String>{};
    final evidence = _buildEvidence(manifest.context, fixture);
    final preservedCandidates = evidence.candidates
        .map((candidate) => candidate.candidateDifficulty)
        .toSet();

    for (var repetition = 0; repetition < repetitionsPerFixture; repetition++) {
      final resolution = policy.resolve(evidence: evidence);
      final canonical = _canonicalObservedResolution(resolution);
      baseline ??= canonical;
      observed.add(canonical);
      if (canonical == fixture.expectedCanonicalResolution) exactMatchCount++;
      if (canonical == baseline) repeatMatchCount++;
      if (resolution.authority != ChooseDifficultyPolicyAuthority.none) {
        authorityViolations++;
      }
      if (resolution.mayAffectGameplay) mayAffectGameplayViolations++;
      if (resolution is ChooseDifficultyPreferredCandidate &&
          !preservedCandidates.contains(resolution.candidate)) {
        preferredCandidateMembershipViolations++;
      }
    }

    deterministicRepeatMatchCount += repeatMatchCount;
    final exactPass = exactMatchCount == repetitionsPerFixture;
    if (exactPass) fixtureExactResolutionCount++;
    fixtureResults.add(
      _FixtureResult(
        fixtureId: fixture.id,
        expectedCanonicalResolution: fixture.expectedCanonicalResolution,
        observedCanonicalResolutions: observed.toList()..sort(),
        exactMatchCount: exactMatchCount,
        repeatMatchCount: repeatMatchCount,
        exactPass: exactPass,
      ),
    );
  }

  final p01 = fixtureResults.singleWhere(
    (fixture) => fixture.fixtureId == 'P01_hard_to_medium',
  );
  final p02 = fixtureResults.singleWhere(
    (fixture) => fixture.fixtureId == 'P02_candidate_order_permutation',
  );
  final p03 = fixtureResults.singleWhere(
    (fixture) => fixture.fixtureId == 'P03_no_enum_order_assumption',
  );
  final medium = _canonicalResolution(
    type: 'preferred',
    candidate: Difficulty.medium,
  );
  final hard = _canonicalResolution(
    type: 'preferred',
    candidate: Difficulty.hard,
  );
  final noPreference = _canonicalResolution(type: 'no_preference');

  return _ValidationResult(
    manifest: manifest,
    fixtureExactResolutionCount: fixtureExactResolutionCount,
    deterministicRepeatMatchCount: deterministicRepeatMatchCount,
    preferredCandidateMembershipViolations:
        preferredCandidateMembershipViolations,
    authorityViolations: authorityViolations,
    mayAffectGameplayViolations: mayAffectGameplayViolations,
    candidateOrderInvariance: p01.exactPass &&
        p02.exactPass &&
        p01.observedCanonicalResolutions.length == 1 &&
        p01.observedCanonicalResolutions.single == medium &&
        p02.observedCanonicalResolutions.length == 1 &&
        p02.observedCanonicalResolutions.single == medium,
    p03NoEnumOrderAssumption: p03.exactPass &&
        p03.observedCanonicalResolutions.length == 1 &&
        p03.observedCanonicalResolutions.single == hard,
    negativeFixtureExactNoPreference: fixtureResults
        .where((fixture) => fixture.expectedCanonicalResolution == noPreference)
        .every((fixture) => fixture.exactPass),
    fixtures: fixtureResults,
  );
}

ChooseDifficultyEpistemicPreservationSet _buildEvidence(
  ContextEvidenceKey context,
  _Fixture fixture,
) {
  final candidates = [
    for (final candidate in fixture.candidates)
      _candidateEvidence(context, candidate),
  ];
  final contributions = [
    for (final candidate in fixture.candidates)
      for (final contribution in candidate.timeoutContributions)
        _contribution(context: context, contribution: contribution),
  ];
  final snapshot = ChooseDifficultyEvidenceSnapshot(
    context: context,
    legalCandidates: [for (final candidate in candidates) candidate.candidate],
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

ChooseDifficultyCandidateEvidence _candidateEvidence(
  ContextEvidenceKey context,
  _FixtureCandidate candidate,
) {
  if (candidate.availability == ChooseDifficultyEvidenceAvailability.absent) {
    return ChooseDifficultyCandidateEvidence(
      candidate: candidate.difficulty,
      availability: ChooseDifficultyEvidenceAvailability.absent,
      aggregate: null,
    );
  }
  final aggregate = const BoundedContextShadowInterpreter().interpret([
    _observation(
        context: context, difficulty: candidate.difficulty, timedOut: false),
  ]).aggregate!;
  return ChooseDifficultyCandidateEvidence(
    candidate: candidate.difficulty,
    availability: ChooseDifficultyEvidenceAvailability.present,
    aggregate: aggregate,
  );
}

TimeoutScenarioCandidateEvidenceContribution _contribution({
  required ContextEvidenceKey context,
  required _FixtureContribution contribution,
}) {
  final scenarioLibrary = _scenarioLibrary();
  final memory = TimeoutConcentrationScenarioEvidenceMemory(
    capacity: contribution.states.isEmpty ? 1 : contribution.states.length,
  );
  for (final state in contribution.states) {
    memory.record(
      scenarioLibrary: scenarioLibrary,
      match: _match(
        scenarioLibrary: scenarioLibrary,
        context: context,
        target: contribution.target,
        comparator: contribution.comparator,
        state: state,
      ),
    );
  }
  final slice = const TimeoutPlayerDifficultyEvidenceSynthesizer().synthesize(
    memory: memory,
    context: context,
    targetDifficulty: contribution.target,
    comparatorDifficulty: contribution.comparator,
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
          context: context, difficulty: comparator, timedOut: timing.$1),
    ],
    secondObservations: [
      _observation(context: context, difficulty: target, timedOut: timing.$2),
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

DifficultyCandidateRelation _relation({
  required Difficulty reference,
  required Difficulty candidate,
}) {
  if (reference == candidate)
    return DifficultyCandidateRelation.sameAsReference;
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

String _canonicalObservedResolution(
        ChooseDifficultyPolicyResolution resolution) =>
    switch (resolution) {
      ChooseDifficultyNoPreference() =>
        _canonicalResolution(type: 'no_preference'),
      ChooseDifficultyPreferredCandidate(:final candidate) =>
        _canonicalResolution(type: 'preferred', candidate: candidate),
    };

String _canonicalResolution({required String type, Difficulty? candidate}) =>
    switch ((type, candidate)) {
      ('no_preference', null) => '{"type":"no_preference"}',
      ('preferred', final Difficulty candidate) =>
        '{"type":"preferred","candidate":"${candidate.name}"}',
      _ => throw ArgumentError('Invalid canonical resolution.'),
    };

final class _FrozenManifest {
  _FrozenManifest({required this.context, required this.fixtures});

  final ContextEvidenceKey context;
  final List<_Fixture> fixtures;

  static _FrozenManifest parse(String source) {
    final root = _object(jsonDecode(source), 'manifest');
    _exactKeys(
        root,
        const {
          'schema_version',
          'policy_id',
          'policy_version',
          'decision_context',
          'input_contract',
          'context',
          'candidate_envelope',
          'policy_rule',
          'fixtures',
        },
        'manifest');
    _equal(_int(root['schema_version'], 'schema_version'), 1, 'schema_version');
    _equal(_string(root['policy_id'], 'policy_id'),
        'timeout_concentration_comparator_preference', 'policy_id');
    _equal(_int(root['policy_version'], 'policy_version'), 1, 'policy_version');
    _equal(_string(root['decision_context'], 'decision_context'),
        'chooseDifficulty', 'decision_context');
    _equal(_string(root['input_contract'], 'input_contract'),
        'ChooseDifficultyEpistemicPreservationSet', 'input_contract');
    final context = _parseContext(_object(root['context'], 'context'));
    _parseCandidateEnvelope(
        _object(root['candidate_envelope'], 'candidate_envelope'));
    _parsePolicyRule(_object(root['policy_rule'], 'policy_rule'));
    final fixtures = [
      for (final value in _list(root['fixtures'], 'fixtures'))
        _Fixture.parse(_object(value, 'fixture')),
    ];
    if (fixtures.length != 18 ||
        fixtures.map((fixture) => fixture.id).toSet().length != 18) {
      throw FormatException('Frozen fixture count or IDs are invalid.');
    }
    const specialFixtureIds = {
      'P01_hard_to_medium',
      'P02_candidate_order_permutation',
      'P03_no_enum_order_assumption',
    };
    if (!fixtures
        .map((fixture) => fixture.id)
        .toSet()
        .containsAll(specialFixtureIds)) {
      throw FormatException('Frozen special fixture IDs are missing.');
    }
    final preferred =
        fixtures.where((fixture) => fixture.expected.isPreferred).length;
    if (preferred != 3 || fixtures.length - preferred != 15) {
      throw FormatException('Frozen expected result counts are invalid.');
    }
    return _FrozenManifest(
        context: context, fixtures: List.unmodifiable(fixtures));
  }
}

ContextEvidenceKey _parseContext(Map<String, dynamic> value) {
  _exactKeys(
      value, const {'operation', 'number_type', 'representation'}, 'context');
  final operation = _string(value['operation'], 'context.operation');
  final numberType = _string(value['number_type'], 'context.number_type');
  _equal(_string(value['representation'], 'context.representation'),
      'directNumeric', 'context.representation');
  return ContextEvidenceKey(
    operation: switch (operation) {
      'addition' => Operation.addition,
      _ => throw FormatException('Unknown operation: $operation'),
    },
    numberType: switch (numberType) {
      'natural' => NumberType.natural,
      _ => throw FormatException('Unknown number type: $numberType'),
    },
  );
}

void _parseCandidateEnvelope(Map<String, dynamic> value) {
  _exactKeys(
      value,
      const {
        'allowed_difficulties',
        'required_candidate_count_for_preference',
        'candidate_order_has_semantics',
        'all_candidates_must_have_present_evidence',
      },
      'candidate_envelope');
  final difficulties = _list(
          value['allowed_difficulties'], 'allowed_difficulties')
      .map((item) => _difficulty(_string(item, 'allowed_difficulties item')))
      .toList();
  if (difficulties.length != 3 || difficulties.toSet().length != 3) {
    throw FormatException('Invalid allowed difficulties.');
  }
  _equal(
      _int(value['required_candidate_count_for_preference'],
          'required_candidate_count_for_preference'),
      2,
      'required_candidate_count_for_preference');
  _equal(
      _bool(value['candidate_order_has_semantics'],
          'candidate_order_has_semantics'),
      false,
      'candidate_order_has_semantics');
  _equal(
      _bool(value['all_candidates_must_have_present_evidence'],
          'all_candidates_must_have_present_evidence'),
      true,
      'all_candidates_must_have_present_evidence');
}

void _parsePolicyRule(Map<String, dynamic> value) {
  _exactKeys(
      value,
      const {
        'required_total_timeout_contributions',
        'required_entries_in_contribution',
        'required_disposition',
        'target_must_differ_from_comparator',
        'comparator_must_be_preserved_candidate',
        'preferred_output',
        'fallback_output',
      },
      'policy_rule');
  _equal(
      _int(value['required_total_timeout_contributions'],
          'required_total_timeout_contributions'),
      1,
      'required_total_timeout_contributions');
  _equal(
      _int(value['required_entries_in_contribution'],
          'required_entries_in_contribution'),
      1,
      'required_entries_in_contribution');
  _equal(_string(value['required_disposition'], 'required_disposition'),
      'matched', 'required_disposition');
  _equal(
      _bool(value['target_must_differ_from_comparator'],
          'target_must_differ_from_comparator'),
      true,
      'target_must_differ_from_comparator');
  _equal(
      _bool(value['comparator_must_be_preserved_candidate'],
          'comparator_must_be_preserved_candidate'),
      true,
      'comparator_must_be_preserved_candidate');
  _equal(_string(value['preferred_output'], 'preferred_output'),
      'canonical comparatorDifficulty', 'preferred_output');
  _equal(_string(value['fallback_output'], 'fallback_output'),
      'ChooseDifficultyNoPreference', 'fallback_output');
}

final class _Fixture {
  _Fixture(
      {required this.id, required this.candidates, required this.expected});

  final String id;
  final List<_FixtureCandidate> candidates;
  final _ExpectedResolution expected;

  String get expectedCanonicalResolution => expected.canonical;

  static _Fixture parse(Map<String, dynamic> value) {
    _exactKeys(value, const {'id', 'candidates', 'expected'}, 'fixture');
    final id = _string(value['id'], 'fixture.id');
    if (!RegExp(r'^[PN][0-9]{2}_[a-z0-9_]+$').hasMatch(id)) {
      throw FormatException('Invalid fixture ID: $id');
    }
    final candidates = [
      for (final candidate in _list(value['candidates'], 'fixture.candidates'))
        _FixtureCandidate.parse(_object(candidate, 'fixture candidate')),
    ];
    if (candidates.map((candidate) => candidate.difficulty).toSet().length !=
        candidates.length) {
      throw FormatException('Fixture candidates must be unique.');
    }
    return _Fixture(
      id: id,
      candidates: List.unmodifiable(candidates),
      expected: _ExpectedResolution.parse(
          _object(value['expected'], 'fixture.expected')),
    );
  }
}

final class _FixtureCandidate {
  _FixtureCandidate({
    required this.difficulty,
    required this.availability,
    required this.timeoutContributions,
  });

  final Difficulty difficulty;
  final ChooseDifficultyEvidenceAvailability availability;
  final List<_FixtureContribution> timeoutContributions;

  static _FixtureCandidate parse(Map<String, dynamic> value) {
    _exactKeys(
        value,
        const {'difficulty', 'availability', 'timeout_contributions'},
        'fixture candidate');
    final difficulty =
        _difficulty(_string(value['difficulty'], 'candidate.difficulty'));
    final contributions = [
      for (final contribution in _list(
          value['timeout_contributions'], 'candidate.timeout_contributions'))
        _FixtureContribution.parse(
            _object(contribution, 'timeout contribution')),
    ];
    if (contributions
        .any((contribution) => contribution.target != difficulty)) {
      throw FormatException('Contribution target must match its candidate.');
    }
    return _FixtureCandidate(
      difficulty: difficulty,
      availability: _availability(
          _string(value['availability'], 'candidate.availability')),
      timeoutContributions: List.unmodifiable(contributions),
    );
  }
}

final class _FixtureContribution {
  _FixtureContribution({
    required this.target,
    required this.comparator,
    required this.states,
  });

  final Difficulty target;
  final Difficulty comparator;
  final List<TimeoutConcentrationScenarioMatchState> states;

  static _FixtureContribution parse(Map<String, dynamic> value) {
    _exactKeys(value, const {'target', 'comparator', 'entries'},
        'timeout contribution');
    return _FixtureContribution(
      target: _difficulty(_string(value['target'], 'contribution.target')),
      comparator:
          _difficulty(_string(value['comparator'], 'contribution.comparator')),
      states: List.unmodifiable([
        for (final state in _list(value['entries'], 'contribution.entries'))
          _recordedState(_string(state, 'contribution entry')),
      ]),
    );
  }
}

final class _ExpectedResolution {
  _ExpectedResolution._({required this.isPreferred, required this.canonical});

  final bool isPreferred;
  final String canonical;

  static _ExpectedResolution parse(Map<String, dynamic> value) {
    final type = _string(value['type'], 'expected.type');
    switch (type) {
      case 'no_preference':
        _exactKeys(value, const {'type'}, 'expected no_preference');
        return _ExpectedResolution._(
          isPreferred: false,
          canonical: _canonicalResolution(type: 'no_preference'),
        );
      case 'preferred':
        _exactKeys(value, const {'type', 'candidate'}, 'expected preferred');
        final candidate =
            _difficulty(_string(value['candidate'], 'expected.candidate'));
        return _ExpectedResolution._(
          isPreferred: true,
          canonical:
              _canonicalResolution(type: 'preferred', candidate: candidate),
        );
      default:
        throw FormatException('Invalid expected result type: $type');
    }
  }
}

final class _FixtureResult {
  _FixtureResult({
    required this.fixtureId,
    required this.expectedCanonicalResolution,
    required this.observedCanonicalResolutions,
    required this.exactMatchCount,
    required this.repeatMatchCount,
    required this.exactPass,
  });

  final String fixtureId;
  final String expectedCanonicalResolution;
  final List<String> observedCanonicalResolutions;
  final int exactMatchCount;
  final int repeatMatchCount;
  final bool exactPass;

  Map<String, Object> toJson() => {
        'fixture_id': fixtureId,
        'expected_canonical_resolution': expectedCanonicalResolution,
        'observed_canonical_resolutions': observedCanonicalResolutions,
        'repetitions': repetitionsPerFixture,
        'exact_match_count': exactMatchCount,
        'repeat_match_count': repeatMatchCount,
        'exact_pass': exactPass,
      };
}

final class _ValidationResult {
  static const externalPrevalidationGates = <String, String>{
    'targeted_policy_tests': 'NOT_SUPPLIED',
    'flutter_analyze': 'NOT_SUPPLIED',
    'full_non_golden_test_suite': 'NOT_SUPPLIED',
  };

  _ValidationResult({
    required this.manifest,
    required this.fixtureExactResolutionCount,
    required this.deterministicRepeatMatchCount,
    required this.preferredCandidateMembershipViolations,
    required this.authorityViolations,
    required this.mayAffectGameplayViolations,
    required this.candidateOrderInvariance,
    required this.p03NoEnumOrderAssumption,
    required this.negativeFixtureExactNoPreference,
    required this.fixtures,
  });

  final _FrozenManifest manifest;
  final int fixtureExactResolutionCount;
  final int deterministicRepeatMatchCount;
  final int preferredCandidateMembershipViolations;
  final int authorityViolations;
  final int mayAffectGameplayViolations;
  final bool candidateOrderInvariance;
  final bool p03NoEnumOrderAssumption;
  final bool negativeFixtureExactNoPreference;
  final List<_FixtureResult> fixtures;

  int get deterministicRepeatCount =>
      manifest.fixtures.length * repetitionsPerFixture;
  double get fixtureExactResolutionRate =>
      fixtureExactResolutionCount / manifest.fixtures.length;
  double get deterministicRepeatMatchRate =>
      deterministicRepeatMatchCount / deterministicRepeatCount;
  int get positiveFixtureCount =>
      manifest.fixtures.where((fixture) => fixture.expected.isPreferred).length;
  int get noPreferenceFixtureCount =>
      manifest.fixtures.length - positiveFixtureCount;
  bool get semanticCriteriaPass =>
      fixtureExactResolutionCount == manifest.fixtures.length &&
      deterministicRepeatMatchCount == deterministicRepeatCount &&
      preferredCandidateMembershipViolations == 0 &&
      authorityViolations == 0 &&
      mayAffectGameplayViolations == 0 &&
      candidateOrderInvariance &&
      p03NoEnumOrderAssumption &&
      negativeFixtureExactNoPreference;

  Map<String, Object> toJson() => {
        'schema_version': 1,
        'policy_id': 'timeout_concentration_comparator_preference',
        'policy_version': 1,
        'manifest_fixture_count': manifest.fixtures.length,
        'repetitions_per_fixture': repetitionsPerFixture,
        'total_evaluations': deterministicRepeatCount,
        'fixture_exact_resolution_count': fixtureExactResolutionCount,
        'fixture_exact_resolution_rate': fixtureExactResolutionRate,
        'deterministic_repeat_count': deterministicRepeatCount,
        'deterministic_repeat_match_count': deterministicRepeatMatchCount,
        'deterministic_repeat_match_rate': deterministicRepeatMatchRate,
        'preferred_candidate_membership_violations':
            preferredCandidateMembershipViolations,
        'authority_violations': authorityViolations,
        'mayAffectGameplay_violations': mayAffectGameplayViolations,
        'positive_fixture_count': positiveFixtureCount,
        'no_preference_fixture_count': noPreferenceFixtureCount,
        'candidate_order_invariance': candidateOrderInvariance,
        'P03_no_enum_order_assumption': p03NoEnumOrderAssumption,
        'negative_fixture_exact_no_preference':
            negativeFixtureExactNoPreference,
        'external_prevalidation_gates': externalPrevalidationGates,
        'fixtures': [for (final fixture in fixtures) fixture.toJson()],
      };
}

Difficulty _difficulty(String value) => switch (value) {
      'easy' => Difficulty.easy,
      'medium' => Difficulty.medium,
      'hard' => Difficulty.hard,
      _ => throw FormatException('Invalid difficulty: $value'),
    };

ChooseDifficultyEvidenceAvailability _availability(String value) =>
    switch (value) {
      'present' => ChooseDifficultyEvidenceAvailability.present,
      'absent' => ChooseDifficultyEvidenceAvailability.absent,
      _ => throw FormatException('Invalid availability: $value'),
    };

TimeoutConcentrationScenarioMatchState _recordedState(String value) =>
    switch (value) {
      'matched' => TimeoutConcentrationScenarioMatchState.matched,
      'notMatched' => TimeoutConcentrationScenarioMatchState.notMatched,
      'contradicted' => TimeoutConcentrationScenarioMatchState.contradicted,
      _ => throw FormatException('Invalid recorded state: $value'),
    };

Map<String, dynamic> _object(Object? value, String label) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$label must be an object.');
}

List<dynamic> _list(Object? value, String label) {
  if (value is List<dynamic>) return value;
  throw FormatException('$label must be an array.');
}

String _string(Object? value, String label) {
  if (value is String) return value;
  throw FormatException('$label must be a string.');
}

int _int(Object? value, String label) {
  if (value is int) return value;
  throw FormatException('$label must be an integer.');
}

bool _bool(Object? value, String label) {
  if (value is bool) return value;
  throw FormatException('$label must be a bool.');
}

void _exactKeys(
    Map<String, dynamic> value, Set<String> expected, String label) {
  if (value.length != expected.length ||
      !value.keys.toSet().containsAll(expected)) {
    throw FormatException('$label has unknown or missing keys.');
  }
}

void _equal<T>(T actual, T expected, String label) {
  if (actual != expected) throw FormatException('Invalid $label: $actual');
}
