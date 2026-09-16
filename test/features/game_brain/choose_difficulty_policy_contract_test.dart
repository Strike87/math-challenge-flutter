import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  test('identity preserves literal values and rejects invalid values', () {
    final identity = ChooseDifficultyPolicyIdentity(id: ' policy ', version: 2);

    expect(identity.id, ' policy ');
    expect(identity.version, 2);
    expect(() => ChooseDifficultyPolicyIdentity(id: ' \t', version: 1),
        throwsArgumentError);
    expect(() => ChooseDifficultyPolicyIdentity(id: 'policy', version: 0),
        throwsArgumentError);
    expect(() => ChooseDifficultyPolicyIdentity(id: 'policy', version: -1),
        throwsArgumentError);
  });

  test('no preference preserves source and identity without authority', () {
    final source = _source(const []);
    final identity = ChooseDifficultyPolicyIdentity(id: 'v', version: 1);
    final resolution =
        ChooseDifficultyNoPreference(source: source, identity: identity);

    expect(resolution.source, same(source));
    expect(resolution.identity, same(identity));
    expect(resolution.authority, ChooseDifficultyPolicyAuthority.none);
    expect(resolution.mayAffectGameplay, isFalse);
  });

  test('preferred candidate preserves references and only accepts membership',
      () {
    final identity = ChooseDifficultyPolicyIdentity(id: 'v', version: 1);
    final source = _source(const [Difficulty.hard, Difficulty.easy]);
    final resolution = ChooseDifficultyPreferredCandidate(
      source: source,
      identity: identity,
      candidate: Difficulty.easy,
    );

    expect(resolution.source, same(source));
    expect(resolution.identity, same(identity));
    expect(resolution.candidate, same(Difficulty.easy));
    expect(resolution.authority, ChooseDifficultyPolicyAuthority.none);
    expect(resolution.mayAffectGameplay, isFalse);
    expect(
      () => ChooseDifficultyPreferredCandidate(
        source: source,
        identity: identity,
        candidate: Difficulty.medium,
      ),
      throwsArgumentError,
    );
  });

  test('candidate membership does not depend on list position', () {
    final identity = ChooseDifficultyPolicyIdentity(id: 'v', version: 1);

    for (final source in [
      _source(const [Difficulty.easy, Difficulty.hard]),
      _source(const [Difficulty.hard, Difficulty.easy]),
    ]) {
      expect(
        ChooseDifficultyPreferredCandidate(
          source: source,
          identity: identity,
          candidate: Difficulty.easy,
        ).candidate,
        Difficulty.easy,
      );
    }
  });

  test('empty source remains no preference only', () {
    final source = _source(const []);
    final identity = ChooseDifficultyPolicyIdentity(id: 'v', version: 1);

    expect(ChooseDifficultyNoPreference(source: source, identity: identity),
        isA<ChooseDifficultyNoPreference>());
    expect(
      () => ChooseDifficultyPreferredCandidate(
        source: source,
        identity: identity,
        candidate: Difficulty.easy,
      ),
      throwsArgumentError,
    );
  });

  test('source is a structural contract, not evidence interpretation', () {
    final rawSource = File(
      'lib/features/game_brain/policy/choose_difficulty_policy_contract.dart',
    ).readAsStringSync();
    final source = _withoutCommentsAndStrings(rawSource);

    expect(
      RegExp(r'\bimport\s+[^;]+;')
          .allMatches(rawSource)
          .map((match) => match.group(0)),
      unorderedEquals([
        "import '../../../models/enums.dart';",
        "import '../evaluation/choose_difficulty_candidate_epistemic_preservation.dart';",
      ]),
    );
    for (final prohibited in [
      'GameState',
      'Adaptive',
      'DifficultyCandidateTopologyHandoff',
      'BoundedOutcomeComparator',
      'BoundedComparabilityAssessor',
      'TimeoutConcentrationEvaluator',
      'TimeoutConcentrationScenarioMatcher',
      'TimeoutConcentrationScenarioEvidenceMemory',
      'TimeoutPlayerDifficultyEvidenceSynthesizer',
      'ScenarioKnowledgeLibrary',
      'SharedPreferences',
      'Firebase',
      'telemetry',
      'analytics',
      'matched',
      'notMatched',
      'contradicted',
      'confidence',
      'score',
      'rank',
      'probability',
      'threshold',
      'Difficulty.values',
      '.index',
      '.sort(',
    ]) {
      expect(source.toLowerCase(), isNot(contains(prohibited.toLowerCase())));
    }
  });
}

ChooseDifficultyEpistemicPreservationSet _source(
  List<Difficulty> candidates,
) {
  final snapshot = ChooseDifficultyEvidenceSnapshot(
    context: ContextEvidenceKey(
      operation: Operation.addition,
      numberType: NumberType.natural,
    ),
    legalCandidates: candidates,
    candidates: [
      for (final candidate in candidates)
        ChooseDifficultyCandidateEvidence(
          candidate: candidate,
          availability: ChooseDifficultyEvidenceAvailability.absent,
          aggregate: null,
        ),
    ],
  );
  final evaluations = const ChooseDifficultyCandidateEvaluationAssembler()
      .assemble(snapshot: snapshot, timeoutContributions: const []);
  return const ChooseDifficultyEpistemicPreserver()
      .preserve(evaluationSet: evaluations);
}

String _withoutCommentsAndStrings(String source) => source.replaceAll(
      RegExp(
        r'''//.*?$|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
        multiLine: true,
      ),
      '',
    );
