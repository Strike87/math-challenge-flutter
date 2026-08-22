import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/experience/question_experience_observation.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const presented = QuestionPresentedSnapshot(
    operation: Operation.division,
    numberType: NumberType.rationals,
    difficulty: Difficulty.hard,
    answerStyle: AnswerStyle.choice4,
  );

  test('represents a minimal effective Phase-1 presentation context', () {
    expect(presented.operation, Operation.division);
    expect(presented.numberType, NumberType.rationals);
    expect(presented.difficulty, Difficulty.hard);
    expect(presented.answerStyle, AnswerStyle.choice4);
  });

  test('constructs an experience from canonical values and one terminal value',
      () {
    const observation = QuestionExperienceObservation(
      presented: QuestionPresentedSnapshot(
        operation: Operation.addition,
        numberType: NumberType.natural,
        difficulty: Difficulty.easy,
        answerStyle: AnswerStyle.trueFalse,
      ),
      terminal: AnsweredCorrect(),
    );

    expect(observation.presented.operation, Operation.addition);
    expect(observation.presented.numberType, NumberType.natural);
    expect(observation.presented.difficulty, Difficulty.easy);
    expect(observation.presented.answerStyle, AnswerStyle.trueFalse);
    expect(observation.terminal, const AnsweredCorrect());
  });

  test('represents answered outcomes as distinct terminal variants', () {
    const correct = AnsweredCorrect();
    const incorrect = AnsweredIncorrect();

    expect(correct, isA<QuestionTerminalObservation>());
    expect(incorrect, isA<QuestionTerminalObservation>());
    expect(correct, isNot(equals(incorrect)));
  });

  test('represents question timeout separately from answered outcomes', () {
    const timeout = QuestionTimedOut();

    expect(timeout, isNot(equals(const AnsweredCorrect())));
    expect(timeout, isNot(equals(const AnsweredIncorrect())));
  });

  test('represents skipped separately from question timeout', () {
    const skipped = QuestionSkipped();
    const timeout = QuestionTimedOut();

    expect(skipped, isNot(equals(timeout)));
  });

  test('represents replacement without an answered result', () {
    const replaced = QuestionReplaced();

    expect(replaced, isNot(equals(const AnsweredIncorrect())));
    expect(replaced, isNot(equals(const AnsweredCorrect())));
  });

  test('represents abandonment separately from timeout and incorrect', () {
    const abandoned = QuestionAbandoned();
    const timeout = QuestionTimedOut();

    expect(abandoned, isNot(equals(timeout)));
    expect(abandoned, isNot(equals(const AnsweredIncorrect())));
  });

  test('composes immutable presented and terminal facts deterministically', () {
    const observation = QuestionExperienceObservation(
      presented: presented,
      terminal: QuestionReplaced(),
    );
    const equivalent = QuestionExperienceObservation(
      presented: QuestionPresentedSnapshot(
        operation: Operation.division,
        numberType: NumberType.rationals,
        difficulty: Difficulty.hard,
        answerStyle: AnswerStyle.choice4,
      ),
      terminal: QuestionReplaced(),
    );

    expect(observation.presented, presented);
    expect(observation.terminal, isA<QuestionReplaced>());
    expect(observation, equivalent);
    expect(observation.hashCode, equivalent.hashCode);
  });
}
