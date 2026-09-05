import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const partitioned = BoundedContextShadowPartitionedInterpreter();
  const interpreter = BoundedContextShadowInterpreter();
  final addition = _context(Operation.addition);
  final multiplication = _context(Operation.multiplication);

  test('A: empty input produces an authority-free empty snapshot', () {
    final snapshot = partitioned.interpret(const []);

    expect(snapshot.partitions, isEmpty);
    expect(snapshot.authority, BoundedContextShadowAuthority.none);
    expect(snapshot.mayAffectGameplay, isFalse);
  });

  test('B: homogeneous evidence delegates to the existing interpreter', () {
    final observations = [_observation(context: addition)];

    expectSameInterpretation(
      partitioned.interpret(observations).partitions.single,
      interpreter.interpret(observations),
    );
  });

  test('C: different operations become separate factual partitions', () {
    final snapshot = partitioned.interpret([
      _observation(context: addition),
      _observation(context: multiplication),
    ]);

    expect(snapshot.partitions, hasLength(2));
    expect(snapshot.partitions.map((item) => item.aggregate!.evidenceCount),
        everyElement(1));
  });

  test('D: different difficulties become separate factual partitions', () {
    final snapshot = partitioned.interpret([
      _observation(context: addition, difficulty: Difficulty.easy),
      _observation(context: addition, difficulty: Difficulty.medium),
    ]);

    expect(snapshot.partitions, hasLength(2));
    expect(
        snapshot.partitions.map((item) => item.factualContextId),
        containsAll([
          'operation=addition;numberType=natural;representation=directNumeric;difficulty=easy',
          'operation=addition;numberType=natural;representation=directNumeric;difficulty=medium',
        ]));
  });

  test('E: matching context and difficulty aggregate in one partition', () {
    final snapshot = partitioned.interpret([
      _observation(context: addition),
      _observation(context: addition, correct: false),
      _observation(context: addition, timedOut: true),
    ]);

    final aggregate = snapshot.partitions.single.aggregate!;
    expect(snapshot.partitions, hasLength(1));
    expect(aggregate.evidenceCount, 3);
    expect(aggregate.correctCount, 1);
    expect(aggregate.incorrectCount, 1);
    expect(aggregate.timeoutCount, 1);
  });

  test('F: three mixed partitions retain only their own observations', () {
    final snapshot = partitioned.interpret([
      _observation(context: addition, difficulty: Difficulty.easy),
      _observation(context: addition, difficulty: Difficulty.medium),
      _observation(context: multiplication, difficulty: Difficulty.easy),
      _observation(context: multiplication, difficulty: Difficulty.easy),
    ]);

    expect(snapshot.partitions, hasLength(3));
    expect(snapshot.partitions.map((item) => item.aggregate!.evidenceCount),
        [1, 1, 2]);
  });

  test('G: exclusive outcomes remain exclusive within a partition', () {
    final aggregate = partitioned
        .interpret([
          _observation(context: addition),
          _observation(context: addition, correct: false),
          _observation(context: addition, timedOut: true),
        ])
        .partitions
        .single
        .aggregate!;

    expect(aggregate.correctCount, 1);
    expect(aggregate.incorrectCount, 1);
    expect(aggregate.timeoutCount, 1);
  });

  test('H: input permutations preserve factual partition order', () {
    final observations = [
      _observation(context: multiplication),
      _observation(context: addition, difficulty: Difficulty.medium),
      _observation(context: addition),
    ];

    expect(
      _contextIds(partitioned.interpret(observations)),
      _contextIds(partitioned.interpret(observations.reversed.toList())),
    );
  });

  test('I: partition order is canonical factual representation only', () {
    final ids = _contextIds(partitioned.interpret([
      _observation(context: multiplication),
      _observation(context: addition, difficulty: Difficulty.medium),
      _observation(context: addition),
    ]));

    expect(ids, List<String>.from(ids)..sort());
  });

  test('J: null context fails closed without a partial snapshot', () {
    expect(
      () => partitioned.interpret([
        _observation(context: addition),
        _observation(context: null),
      ]),
      throwsArgumentError,
    );
  });

  test('K: caller-list mutation does not change a returned snapshot', () {
    final observations = <ContextEvidenceObservation>[
      _observation(context: addition)
    ];
    final snapshot = partitioned.interpret(observations);
    observations
      ..clear()
      ..add(_observation(context: multiplication));

    expect(snapshot.partitions, hasLength(1));
    expect(snapshot.partitions.single.factualContextId,
        'operation=addition;numberType=natural;representation=directNumeric;difficulty=easy');
  });

  test('L: partitions are unmodifiable', () {
    final partitions =
        partitioned.interpret([_observation(context: addition)]).partitions;

    expect(
      () => partitions
          .add(interpreter.interpret([_observation(context: multiplication)])),
      throwsUnsupportedError,
    );
  });

  test('M: the public snapshot exposes interpretations, not raw observations',
      () {
    final snapshot = partitioned.interpret([_observation(context: addition)]);

    expect(
        snapshot.partitions.single, isA<BoundedContextShadowInterpretation>());
    expect(snapshot.partitions.single.aggregate!.evidenceCount, 1);
  });

  test('N: every partition retains no gameplay authority', () {
    final snapshot = partitioned.interpret([
      _observation(context: addition),
      _observation(context: multiplication),
    ]);

    for (final interpretation in snapshot.partitions) {
      expect(interpretation.authority, BoundedContextShadowAuthority.none);
      expect(interpretation.mayAffectGameplay, isFalse);
    }
  });

  test('O: repeated mixed input produces the same partitioned snapshot', () {
    final observations = [
      _observation(context: multiplication, correct: false),
      _observation(context: addition, timedOut: true),
      _observation(context: addition),
    ];
    final first = partitioned.interpret(observations);
    final second = partitioned.interpret(observations);

    expect(_contextIds(first), _contextIds(second));
    for (var index = 0; index < first.partitions.length; index++) {
      expectSameInterpretation(
          first.partitions[index], second.partitions[index]);
    }
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

List<String> _contextIds(BoundedContextShadowPartitionedSnapshot snapshot) =>
    snapshot.partitions.map((item) => item.factualContextId!).toList();

void expectSameInterpretation(
  BoundedContextShadowInterpretation actual,
  BoundedContextShadowInterpretation expected,
) {
  expect(actual.state, expected.state);
  expect(actual.factualContextId, expected.factualContextId);
  expect(actual.explanation, expected.explanation);
  expect(actual.authority, expected.authority);
  expect(actual.mayAffectGameplay, expected.mayAffectGameplay);
  expect(actual.aggregate?.evidenceCount, expected.aggregate?.evidenceCount);
  expect(actual.aggregate?.correctCount, expected.aggregate?.correctCount);
  expect(actual.aggregate?.incorrectCount, expected.aggregate?.incorrectCount);
  expect(actual.aggregate?.timeoutCount, expected.aggregate?.timeoutCount);
  expect(actual.aggregate?.accuracy, expected.aggregate?.accuracy);
}
