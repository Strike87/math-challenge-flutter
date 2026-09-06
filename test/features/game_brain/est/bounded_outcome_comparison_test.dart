import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const comparator = BoundedOutcomeComparator();
  final addition = _context(Operation.addition);
  final multiplication = _context(Operation.multiplication);

  void expectNoDifferences(BoundedOutcomeComparison comparison) {
    expect(comparison.evidenceCountDifference, isNull);
    expect(comparison.answeredRateDifference, isNull);
    expect(comparison.correctRateDifference, isNull);
    expect(comparison.incorrectRateDifference, isNull);
    expect(comparison.timeoutRateDifference, isNull);
  }

  test('1: empty pairs are incomplete with no differences', () {
    final comparison = comparator.compare(
      firstObservations: const [],
      secondObservations: const [],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.incompletePair);
    expect(comparison.first.evidenceCount, 0);
    expect(comparison.second.evidenceCount, 0);
    expectNoDifferences(comparison);
  });

  test('2: a present first side and empty second side retain summaries', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition)],
      secondObservations: const [],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.incompletePair);
    expect(comparison.first.context, addition);
    expect(comparison.first.evidenceCount, 1);
    expect(comparison.second.evidenceCount, 0);
    expectNoDifferences(comparison);
  });

  test('3: an empty first side and present second side is incomplete', () {
    final comparison = comparator.compare(
      firstObservations: const [],
      secondObservations: [_observation(context: addition)],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.incompletePair);
    expectNoDifferences(comparison);
  });

  test('4: matching context and difficulty is descriptive', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition)],
      secondObservations: [_observation(context: addition, correct: false)],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.descriptive);
    expect(comparison.evidenceCountDifference, 0);
  });

  test('5: matching context with different difficulties is descriptive', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition)],
      secondObservations: [
        _observation(context: addition, difficulty: Difficulty.hard),
      ],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.descriptive);
    expect(comparison.first.difficulty, Difficulty.easy);
    expect(comparison.second.difficulty, Difficulty.hard);
  });

  test('6: different contexts mismatch with no differences', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition)],
      secondObservations: [_observation(context: multiplication)],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.contextMismatch);
    expectNoDifferences(comparison);
  });

  test('7: all differences are exactly second minus first', () {
    final comparison = comparator.compare(
      firstObservations: [
        _observation(context: addition),
        _observation(context: addition, correct: false),
      ],
      secondObservations: [
        _observation(context: addition),
        _observation(context: addition),
        _observation(context: addition, correct: false),
        _observation(context: addition, timedOut: true),
      ],
    );

    expect(comparison.evidenceCountDifference, 2);
    expect(comparison.answeredRateDifference, closeTo(-0.25, 1e-12));
    expect(comparison.correctRateDifference, 0);
    expect(comparison.incorrectRateDifference, closeTo(-0.25, 1e-12));
    expect(comparison.timeoutRateDifference, closeTo(0.25, 1e-12));
  });

  test('8: positive, negative, and zero rate differences are raw values', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition, timedOut: true)],
      secondObservations: [_observation(context: addition)],
    );

    expect(comparison.answeredRateDifference, 1);
    expect(comparison.correctRateDifference, 1);
    expect(comparison.incorrectRateDifference, 0);
    expect(comparison.timeoutRateDifference, -1);
  });

  test('9: one observation on each side may be descriptive', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition)],
      secondObservations: [_observation(context: addition)],
    );

    expect(comparison.state, BoundedOutcomeComparisonState.descriptive);
    expect(comparison.evidenceCountDifference, 0);
  });

  test('10: timeout classification remains exclusive through EST-02A', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition, timedOut: true)],
      secondObservations: [_observation(context: addition, timedOut: true)],
    );

    expect(comparison.first.answeredCount, 0);
    expect(comparison.first.correctCount, 0);
    expect(comparison.first.incorrectCount, 0);
    expect(comparison.first.timeoutCount, 1);
  });

  test('11: malformed first context propagates ArgumentError', () {
    expect(
      () => comparator.compare(
        firstObservations: [_observation(context: null)],
        secondObservations: [_observation(context: addition)],
      ),
      throwsArgumentError,
    );
  });

  test('12: malformed second context propagates ArgumentError', () {
    expect(
      () => comparator.compare(
        firstObservations: [_observation(context: addition)],
        secondObservations: [_observation(context: null)],
      ),
      throwsArgumentError,
    );
  });

  test('13: mixed context on either side propagates ArgumentError', () {
    expect(
      () => comparator.compare(
        firstObservations: [
          _observation(context: addition),
          _observation(context: multiplication),
        ],
        secondObservations: [_observation(context: addition)],
      ),
      throwsArgumentError,
    );
    expect(
      () => comparator.compare(
        firstObservations: [_observation(context: addition)],
        secondObservations: [
          _observation(context: addition),
          _observation(context: multiplication),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('14: mixed difficulty on either side propagates ArgumentError', () {
    expect(
      () => comparator.compare(
        firstObservations: [
          _observation(context: addition),
          _observation(context: addition, difficulty: Difficulty.medium),
        ],
        secondObservations: [_observation(context: addition)],
      ),
      throwsArgumentError,
    );
    expect(
      () => comparator.compare(
        firstObservations: [_observation(context: addition)],
        secondObservations: [
          _observation(context: addition),
          _observation(context: addition, difficulty: Difficulty.medium),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('15: identical input is descriptive and has zero differences', () {
    final observations = [
      _observation(context: addition),
      _observation(context: addition, correct: false),
      _observation(context: addition, timedOut: true),
    ];
    final comparison = comparator.compare(
      firstObservations: observations,
      secondObservations: observations,
    );

    expect(comparison.state, BoundedOutcomeComparisonState.descriptive);
    expect(comparison.evidenceCountDifference, 0);
    expect(comparison.answeredRateDifference, 0);
    expect(comparison.correctRateDifference, 0);
    expect(comparison.incorrectRateDifference, 0);
    expect(comparison.timeoutRateDifference, 0);
  });

  test('16: comparison neither mutates nor retains input lists', () {
    final first = <ContextEvidenceObservation>[_observation(context: addition)];
    final second = <ContextEvidenceObservation>[
      _observation(context: addition, correct: false),
    ];
    final comparison = comparator.compare(
      firstObservations: first,
      secondObservations: second,
    );
    first.clear();
    second
      ..clear()
      ..add(_observation(context: multiplication));

    expect(comparison.first.context, addition);
    expect(comparison.first.correctCount, 1);
    expect(comparison.second.context, addition);
    expect(comparison.second.incorrectCount, 1);
  });

  test('17: comparison has no authority or gameplay effect', () {
    final comparison = comparator.compare(
      firstObservations: [_observation(context: addition)],
      secondObservations: [_observation(context: addition)],
    );

    expect(comparison.authority, BoundedOutcomeComparisonAuthority.none);
    expect(comparison.mayAffectGameplay, isFalse);
  });

  test('18: source keeps the API generic and privately constructed', () {
    final source = File(
      'lib/features/game_brain/est/bounded_outcome_comparison.dart',
    ).readAsStringSync();
    final barrel =
        File('lib/features/game_brain/game_brain.dart').readAsStringSync();

    expect(source, contains('BoundedOutcomeComparison._('));
    expect(source, isNot(contains('BoundedOutcomeComparison({')));
    expect(source, isNot(contains('final List<ContextEvidenceObservation>')));
    expect(source, isNot(contains('minimumN')));
    expect(source, isNot(contains('threshold')));
    expect(source, isNot(contains('confidenceInterval')));
    expect(source, isNot(contains('standardError')));
    expect(source, isNot(contains('effectSize')));
    expect(source, isNot(contains('pValue')));
    expect(source, isNot(contains('bootstrap')));
    expect(source, isNot(contains('practicalSignificance')));
    expect(source, isNot(contains('scenario')));
    expect(source, isNot(contains('Difficulty.values')));
    expect(source, isNot(contains('.index')));
    expect(source, isNot(contains('earlier')));
    expect(source, isNot(contains('later')));
    expect(source, isNot(contains('historical')));
    expect(source, isNot(contains('trend')));
    expect(source, isNot(contains('improvement')));
    expect(source, isNot(contains('decline')));
    expect(source, isNot(contains('recovery')));
    expect(source, isNot(contains('stability')));
    expect(source, isNot(contains('assisted')));
    expect(source, isNot(contains('unassisted')));
    expect(
      barrel,
      contains("export 'est/bounded_outcome_comparison.dart';"),
    );
  });
}

ContextEvidenceKey _context(Operation operation) => ContextEvidenceKey(
      operation: operation,
      numberType: NumberType.natural,
    );

ContextEvidenceObservation _observation({
  required ContextEvidenceKey? context,
  Difficulty difficulty = Difficulty.easy,
  bool correct = true,
  bool timedOut = false,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: timedOut ? null : (correct ? 4 : 3),
      correct: timedOut ? false : correct,
      timedOut: timedOut,
      responseTimeMs: 1000,
    );
