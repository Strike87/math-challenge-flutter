import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  test('BRAIN-02 observation operands are finite and supplied as a pair', () {
    expect(
      () => BrainObservation(
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        correctAnswer: '4',
        submittedAnswer: '3',
        correct: false,
        timedOut: false,
        responseTimeMs: 800,
        masteryBefore: 20,
        masteryAfter: 20,
        leftOperand: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => BrainObservation(
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        correctAnswer: '4',
        submittedAnswer: '3',
        correct: false,
        timedOut: false,
        responseTimeMs: 800,
        masteryBefore: 20,
        masteryAfter: 20,
        leftOperand: double.nan,
        rightOperand: 2,
      ),
      throwsArgumentError,
    );
  });

  test('BRAIN-02 evidence retains opaque tags and validates confidence', () {
    final evidence = MisconceptionEvidence(
      tag: ' caller-supplied tag ',
      type: MisconceptionType.signRule,
      reason: MisconceptionReason.oppositeSignSameMagnitude,
      confidence: 0.95,
    );

    expect(evidence.tag, ' caller-supplied tag ');
    expect(
      () => MisconceptionEvidence(tag: 'bad-confidence', confidence: 1.1),
      throwsArgumentError,
    );
    expect(
      () => MisconceptionEvidence(
        tag: 'incompatible-rule',
        type: MisconceptionType.signRule,
        reason: MisconceptionReason.reversedDivisionOperands,
      ),
      throwsArgumentError,
    );
  });
}
