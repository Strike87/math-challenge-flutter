import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const builder = ChooseDifficultyEvidenceSnapshotBuilder();
  const partitioned = BoundedContextShadowPartitionedInterpreter();
  final addition = _context(Operation.addition);
  final multiplication = _context(Operation.multiplication);
  final integers = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.integers,
  );

  BoundedContextShadowPartitionedSnapshot snapshot(
    List<ContextEvidenceObservation> observations,
  ) =>
      partitioned.interpret(observations);

  test('A: empty candidates remain empty and authority-free', () {
    final result = builder.build(
      context: addition,
      legalCandidates: const [],
      evidenceSnapshot: snapshot(const []),
    );

    expect(result.legalCandidates, isEmpty);
    expect(result.candidates, isEmpty);
    expect(result.authority, ChooseDifficultyEvidenceAuthority.none);
    expect(result.mayAffectGameplay, isFalse);
  });

  test('B: empty evidence is absent for every supplied candidate', () {
    final result = builder.build(
      context: addition,
      legalCandidates: const [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard
      ],
      evidenceSnapshot: snapshot(const []),
    );

    expect(result.candidates.map((item) => item.availability),
        everyElement(ChooseDifficultyEvidenceAvailability.absent));
    expect(
        result.candidates.map((item) => item.aggregate), everyElement(isNull));
  });

  test('C-D-M: matching partitions retain their existing aggregates', () {
    final evidence = snapshot([
      _observation(context: addition),
      _observation(
          context: addition, difficulty: Difficulty.medium, correct: false),
    ]);
    final result = builder.build(
      context: addition,
      legalCandidates: const [Difficulty.easy, Difficulty.medium],
      evidenceSnapshot: evidence,
    );

    expect(result.candidates.map((item) => item.availability), const [
      ChooseDifficultyEvidenceAvailability.present,
      ChooseDifficultyEvidenceAvailability.present,
    ]);
    expect(
        identical(result.candidates[0].aggregate,
                evidence.partitions[0].aggregate) ||
            identical(result.candidates[0].aggregate,
                evidence.partitions[1].aggregate),
        isTrue);
    expect(result.candidates[0].aggregate?.correctCount, 1);
    expect(result.candidates[1].aggregate?.incorrectCount, 1);
  });

  test('E-F-G: another candidate or context does not leak', () {
    final evidence = snapshot([
      _observation(context: addition, difficulty: Difficulty.medium),
      _observation(context: multiplication),
      _observation(context: integers),
    ]);
    final result = builder.build(
      context: addition,
      legalCandidates: const [Difficulty.easy, Difficulty.medium],
      evidenceSnapshot: evidence,
    );

    expect(result.candidates[0].availability,
        ChooseDifficultyEvidenceAvailability.absent);
    expect(result.candidates[1].availability,
        ChooseDifficultyEvidenceAvailability.present);
  });

  test('H-L: supplied order and snapshots are immutable', () {
    final supplied = <Difficulty>[
      Difficulty.hard,
      Difficulty.easy,
      Difficulty.medium
    ];
    final result = builder.build(
      context: addition,
      legalCandidates: supplied,
      evidenceSnapshot: snapshot(const []),
    );
    supplied.clear();

    expect(result.legalCandidates,
        const [Difficulty.hard, Difficulty.easy, Difficulty.medium]);
    expect(result.candidates.map((item) => item.candidate),
        const [Difficulty.hard, Difficulty.easy, Difficulty.medium]);
    expect(() => result.legalCandidates.clear(), throwsUnsupportedError);
    expect(() => result.candidates.clear(), throwsUnsupportedError);
  });

  test('I-J: duplicate and out-of-envelope candidates fail closed', () {
    for (final candidates in [
      [Difficulty.easy, Difficulty.easy],
      [Difficulty.expert],
    ]) {
      expect(
        () => builder.build(
          context: addition,
          legalCandidates: candidates,
          evidenceSnapshot: snapshot(const []),
        ),
        throwsArgumentError,
      );
    }
  });

  test('K: missing structured partition identity fails closed', () {
    final malformed = BoundedContextShadowPartitionedSnapshot([
      const BoundedContextShadowInterpretation(
        state: BoundedContextShadowInterpretationState.insufficient,
        aggregate: null,
        factualContextId: null,
        explanation: 'No bounded context observations are available.',
      ),
    ]);

    expect(
      () => builder.build(
        context: addition,
        legalCandidates: const [Difficulty.easy],
        evidenceSnapshot: malformed,
      ),
      throwsArgumentError,
    );
  });

  test('ambiguous matching partitions fail closed', () {
    final partition = const BoundedContextShadowInterpreter().interpret([
      _observation(context: addition),
    ]);
    final ambiguous = BoundedContextShadowPartitionedSnapshot([
      partition,
      partition,
    ]);

    expect(
      () => builder.build(
        context: addition,
        legalCandidates: const [Difficulty.easy],
        evidenceSnapshot: ambiguous,
      ),
      throwsArgumentError,
    );
  });

  test('a non-observational matching partition fails closed', () {
    final malformed = BoundedContextShadowPartitionedSnapshot([
      BoundedContextShadowInterpretation(
        state: BoundedContextShadowInterpretationState.insufficient,
        aggregate: null,
        factualContextId: null,
        explanation: 'No bounded context observations are available.',
        context: addition,
        difficulty: Difficulty.easy,
      ),
    ]);

    expect(
      () => builder.build(
        context: addition,
        legalCandidates: const [Difficulty.easy],
        evidenceSnapshot: malformed,
      ),
      throwsArgumentError,
    );
  });
}

ContextEvidenceKey _context(Operation operation) => ContextEvidenceKey(
      operation: operation,
      numberType: NumberType.natural,
    );

ContextEvidenceObservation _observation({
  required ContextEvidenceKey context,
  Difficulty difficulty = Difficulty.easy,
  bool correct = true,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: correct ? 4 : 3,
      correct: correct,
      timedOut: false,
      responseTimeMs: 1000,
    );
