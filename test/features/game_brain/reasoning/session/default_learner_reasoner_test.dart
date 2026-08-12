import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const reasoner = DefaultLearnerReasoner();

  BrainMemoryEntry entry({
    Operation operation = Operation.addition,
    bool correct = false,
    MisconceptionType? type,
  }) =>
      BrainMemoryEntry(
        observation: BrainObservation(
          operation: operation,
          difficulty: Difficulty.easy,
          numberType: NumberType.natural,
          correctAnswer: '4',
          submittedAnswer: correct ? '4' : '3',
          correct: correct,
          timedOut: false,
          responseTimeMs: 10,
          masteryBefore: 10,
          masteryAfter: 10,
        ),
        misconceptionEvidence: type == null
            ? null
            : MisconceptionEvidence(
                tag: type.name,
                type: type,
                reason: _reasonFor(type),
              ),
      );

  test('one matching typed evidence is insufficient', () {
    final result = reasoner.reason(
      [entry(type: MisconceptionType.signRule)],
      Operation.addition,
    );
    expect(result.hypothesis, LearnerHypothesis.insufficientEvidence);
  });

  test('two matching typed evidence produces repeated misconception', () {
    final result = reasoner.reason([
      entry(type: MisconceptionType.signRule),
      entry(type: MisconceptionType.signRule),
    ], Operation.addition);
    expect(result.hypothesis, LearnerHypothesis.repeatedMisconception);
    expect(result.misconceptionCounts[MisconceptionType.signRule], 2);
  });

  test('typed evidence on another operation does not merge', () {
    final result = reasoner.reason([
      entry(type: MisconceptionType.signRule),
      entry(
        operation: Operation.subtraction,
        type: MisconceptionType.signRule,
      ),
    ], Operation.addition);
    expect(result.hypothesis, LearnerHypothesis.insufficientEvidence);
  });

  test('equal competing repeated types are ambiguous', () {
    final result = reasoner.reason([
      entry(type: MisconceptionType.signRule),
      entry(type: MisconceptionType.signRule),
      entry(type: MisconceptionType.multiplicationFact),
      entry(type: MisconceptionType.multiplicationFact),
    ], Operation.addition);
    expect(result.hypothesis, LearnerHypothesis.insufficientEvidence);
  });

  test('stable understanding requires three correct same-operation entries',
      () {
    expect(
      reasoner.reason([entry(correct: true), entry(correct: true)],
          Operation.addition).hypothesis,
      LearnerHypothesis.insufficientEvidence,
    );
    expect(
      reasoner.reason([
        entry(correct: true),
        entry(correct: true),
        entry(correct: true),
      ], Operation.addition).hypothesis,
      LearnerHypothesis.stableUnderstanding,
    );
  });

  test('wrong answers and other operations prevent stable understanding', () {
    expect(
      reasoner.reason([
        entry(correct: true),
        entry(correct: false),
        entry(correct: true),
      ], Operation.addition).hypothesis,
      LearnerHypothesis.insufficientEvidence,
    );
    expect(
      reasoner.reason([
        entry(correct: true),
        entry(correct: true),
        entry(operation: Operation.subtraction, correct: true),
      ], Operation.addition).hypothesis,
      LearnerHypothesis.insufficientEvidence,
    );
  });

  test('recovery requires repeated evidence followed by two correct entries',
      () {
    final repeated = [
      entry(type: MisconceptionType.signRule),
      entry(type: MisconceptionType.signRule),
    ];
    expect(
      reasoner.reason(
          [...repeated, entry(correct: true)], Operation.addition).hypothesis,
      LearnerHypothesis.repeatedMisconception,
    );
    expect(
      reasoner.reason([
        ...repeated,
        entry(correct: true),
        entry(correct: true),
      ], Operation.addition).hypothesis,
      LearnerHypothesis.recovering,
    );
  });

  test('recovery is ordered and a later misconception changes the result', () {
    final result = reasoner.reason([
      entry(type: MisconceptionType.signRule),
      entry(type: MisconceptionType.signRule),
      entry(correct: true),
      entry(correct: true),
      entry(type: MisconceptionType.signRule),
    ], Operation.addition);
    expect(result.hypothesis, LearnerHypothesis.repeatedMisconception);
  });

  test('bounded FIFO history changes the available session evidence', () {
    final memory = BrainSessionMemory(capacity: 2);
    final first = entry(type: MisconceptionType.signRule);
    final second = entry(type: MisconceptionType.signRule);
    final correct = entry(correct: true);
    memory.record(first.observation,
        misconceptionEvidence: first.misconceptionEvidence);
    memory.record(second.observation,
        misconceptionEvidence: second.misconceptionEvidence);
    memory.record(correct.observation);

    final result = reasoner.reason(memory.entries, Operation.addition);

    expect(memory.observations, hasLength(2));
    expect(result.hypothesis, LearnerHypothesis.insufficientEvidence);
  });
}

MisconceptionReason _reasonFor(MisconceptionType type) {
  switch (type) {
    case MisconceptionType.signRule:
      return MisconceptionReason.oppositeSignSameMagnitude;
    case MisconceptionType.operationSubstitution:
      return MisconceptionReason.alternativeBasicOperation;
    case MisconceptionType.multiplicationFact:
      return MisconceptionReason.adjacentMultiplicationFactor;
    case MisconceptionType.divisionInverse:
      return MisconceptionReason.reversedDivisionOperands;
  }
}
