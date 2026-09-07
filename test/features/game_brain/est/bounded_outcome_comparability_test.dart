import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const assessor = BoundedComparabilityAssessor();
  const sameDifficulty = BoundedComparabilityRequirement(
    difficulty: BoundedDifficultyComparability.sameDifficultyRequired,
  );
  const mayDiffer = BoundedComparabilityRequirement(
    difficulty: BoundedDifficultyComparability.difficultyMayDiffer,
  );
  final addition = _context(Operation.addition);
  final multiplication = _context(Operation.multiplication);

  BoundedOutcomeComparison comparison({
    required List<ContextEvidenceObservation> first,
    required List<ContextEvidenceObservation> second,
  }) =>
      const BoundedOutcomeComparator().compare(
        firstObservations: first,
        secondObservations: second,
      );

  test('1: incomplete pairs are unresolved for either requirement', () {
    final result = assessor.assess(
      comparison: comparison(first: const [], second: const []),
      requirement: sameDifficulty,
    );

    expect(result.state, BoundedComparabilityState.unresolved);
    expect(result.reasons, {BoundedComparabilityReason.incompletePair});
  });

  test('2: context mismatch is not comparable', () {
    final result = assessor.assess(
      comparison: comparison(
        first: [_observation(context: addition)],
        second: [_observation(context: multiplication)],
      ),
      requirement: sameDifficulty,
    );

    expect(result.state, BoundedComparabilityState.notComparable);
    expect(result.reasons, {BoundedComparabilityReason.contextMismatch});
  });

  test('3: equal difficulties satisfy the same-difficulty requirement', () {
    final result = assessor.assess(
      comparison: comparison(
        first: [_observation(context: addition)],
        second: [_observation(context: addition)],
      ),
      requirement: sameDifficulty,
    );

    expect(result.state, BoundedComparabilityState.comparable);
    expect(result.reasons, isEmpty);
  });

  test('4: different difficulties fail the same-difficulty requirement', () {
    final result = assessor.assess(
      comparison: comparison(
        first: [_observation(context: addition, difficulty: Difficulty.easy)],
        second: [_observation(context: addition, difficulty: Difficulty.hard)],
      ),
      requirement: sameDifficulty,
    );

    expect(result.state, BoundedComparabilityState.notComparable);
    expect(result.reasons, {BoundedComparabilityReason.difficultyMismatch});
  });

  test('5: difficulty may differ with equal difficulties', () {
    final result = assessor.assess(
      comparison: comparison(
        first: [_observation(context: addition)],
        second: [_observation(context: addition)],
      ),
      requirement: mayDiffer,
    );

    expect(result.state, BoundedComparabilityState.comparable);
    expect(result.reasons, isEmpty);
  });

  test('6: difficulty may differ with a second distinct combination', () {
    final result = assessor.assess(
      comparison: comparison(
        first: [
          _observation(context: addition, difficulty: Difficulty.medium),
        ],
        second: [_observation(context: addition, difficulty: Difficulty.easy)],
      ),
      requirement: mayDiffer,
    );

    expect(result.state, BoundedComparabilityState.comparable);
    expect(result.reasons, isEmpty);
  });

  test('7: assessment retains inputs and has no gameplay authority', () {
    final source = comparison(
      first: [_observation(context: addition)],
      second: [_observation(context: addition)],
    );
    final result = assessor.assess(
      comparison: source,
      requirement: sameDifficulty,
    );

    expect(identical(result.comparison, source), isTrue);
    expect(identical(result.requirement, sameDifficulty), isTrue);
    expect(result.authority, BoundedComparabilityAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('8: reasons cannot be externally mutated', () {
    final result = assessor.assess(
      comparison: comparison(first: const [], second: const []),
      requirement: sameDifficulty,
    );

    expect(
      () => result.reasons.add(BoundedComparabilityReason.contextMismatch),
      throwsUnsupportedError,
    );
  });

  test('9: source firewall excludes prohibited implementation concepts', () {
    final source = _withoutCommentsAndStrings(
      File(
        'lib/features/game_brain/est/bounded_outcome_comparability.dart',
      ).readAsStringSync(),
    );
    final barrel =
        File('lib/features/game_brain/game_brain.dart').readAsStringSync();

    expect(source, contains('BoundedOutcomeComparison comparison'));
    for (final pattern in [
      'minimumN',
      'threshold',
      'confidenceInterval',
      'pValue',
      'effectSize',
      'bootstrap',
      'commonSupport',
      'higherDifficulty',
      'lowerDifficulty',
      'Difficulty.values',
      '.index',
      'scenario',
      'recommendation',
      'policy',
      'temporal',
      'improvement',
      'decline',
      'assistance',
    ]) {
      expect(source, isNot(contains(pattern)));
    }
    expect(
        barrel, contains("export 'est/bounded_outcome_comparability.dart';"));
  });
}

ContextEvidenceKey _context(Operation operation) => ContextEvidenceKey(
      operation: operation,
      numberType: NumberType.natural,
    );

ContextEvidenceObservation _observation({
  required ContextEvidenceKey context,
  Difficulty difficulty = Difficulty.easy,
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
