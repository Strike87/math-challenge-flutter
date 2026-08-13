import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  BrainObservation observation({
    bool correct = true,
    bool timedOut = false,
    String? submittedAnswer = '4',
  }) =>
      BrainObservation(
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        correctAnswer: '4',
        submittedAnswer: submittedAnswer,
        correct: correct,
        timedOut: timedOut,
        responseTimeMs: 800,
        masteryBefore: 20,
        masteryAfter: 27,
      );

  test('invalid domain values are rejected at construction', () {
    expect(
      () => BrainDecision(isNeutral: true, confidence: 1.1),
      throwsArgumentError,
    );
    expect(
      () => LearnerSnapshot(
        masteryByOperation: const {Operation.addition: -1},
      ),
      throwsArgumentError,
    );
    expect(
      () => observation(correct: true, timedOut: true),
      throwsArgumentError,
    );
  });

  test('BRAIN-01 regression keeps constructed decisions shadow-only', () {
    final decision = BrainDecision(isNeutral: false, confidence: 0.75);

    expect(decision.isShadow, isTrue);
  });

  test('snapshot and observation retain canonical values without mutation', () {
    final source = {Operation.addition: 27.0};
    final learner = LearnerSnapshot(masteryByOperation: source);
    source[Operation.addition] = 99;

    final result = observation();

    expect(learner.masteryByOperation[Operation.addition], 27);
    expect(result.correctAnswer, '4');
    expect(result.submittedAnswer, '4');
    expect(() => learner.masteryByOperation.clear(), throwsUnsupportedError);
  });
}
