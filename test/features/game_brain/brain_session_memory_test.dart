import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  BrainObservation observation(
    int answer, {
    Operation operation = Operation.addition,
    String? evidenceTag,
  }) =>
      BrainObservation(
        operation: operation,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        correctAnswer: '4',
        submittedAnswer: '$answer',
        correct: answer == 4,
        timedOut: false,
        responseTimeMs: 800,
        masteryBefore: 20,
        masteryAfter: 20,
        misconceptionEvidence: evidenceTag == null
            ? null
            : MisconceptionEvidence(tag: evidenceTag),
      );

  test('keeps only the newest observations and exposes a read-only view', () {
    final memory = BrainSessionMemory(capacity: 2);
    memory.record(observation(1));
    memory.record(observation(2));
    memory.record(observation(3));

    expect(
        memory.observations.map((entry) => entry.submittedAnswer), ['2', '3']);
    expect(() => memory.observations.clear(), throwsUnsupportedError);
  });

  test('clear removes session observations', () {
    final memory = BrainSessionMemory();
    memory.record(observation(4));

    memory.clear();

    expect(memory.observations, isEmpty);
  });

  test('uses a default capacity of ten observations', () {
    final memory = BrainSessionMemory();
    for (var answer = 0; answer < 11; answer++) {
      memory.record(observation(answer));
    }

    expect(memory.observations, hasLength(10));
    expect(memory.observations.first.submittedAnswer, '1');
  });

  test('does not expose a hypothesis after one evidence tag', () {
    final memory = BrainSessionMemory();
    memory.record(observation(1, evidenceTag: 'sign-error'));

    expect(memory.tentativeMisconceptionHypothesis(), isNull);
  });

  test('exposes a hypothesis after two matching evidence tags', () {
    final memory = BrainSessionMemory();
    memory.record(observation(1, evidenceTag: ' sign-error '));
    memory.record(observation(2, evidenceTag: ' sign-error '));

    final hypothesis = memory.tentativeMisconceptionHypothesis();

    expect(hypothesis?.operation, Operation.addition);
    expect(hypothesis?.evidenceTag, ' sign-error ');
    expect(hypothesis?.evidenceCount, 2);
  });

  test('does not aggregate matching tags from another operation', () {
    final memory = BrainSessionMemory();
    memory.record(observation(1, evidenceTag: 'sign-error'));
    memory.record(
      observation(
        2,
        operation: Operation.subtraction,
        evidenceTag: 'sign-error',
      ),
    );

    expect(memory.tentativeMisconceptionHypothesis(), isNull);
  });

  test('selects the first-recorded hypothesis when repeated counts tie', () {
    final memory = BrainSessionMemory();
    memory.record(observation(1, evidenceTag: 'first'));
    memory.record(observation(2, evidenceTag: 'second'));
    memory.record(observation(3, evidenceTag: 'first'));
    memory.record(observation(4, evidenceTag: 'second'));

    final hypothesis = memory.tentativeMisconceptionHypothesis();

    expect(hypothesis?.evidenceTag, 'first');
    expect(hypothesis?.evidenceCount, 2);
  });

  test('rejects non-positive capacity', () {
    expect(() => BrainSessionMemory(capacity: 0), throwsArgumentError);
  });
}
