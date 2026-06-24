import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  final qgen = QuestionGenerator();

  group('QuestionGenerator', () {
    test('addition easy produces valid question', () {
      final q = qgen.build(
        type: Operation.addition,
        diff: Difficulty.easy,
        numType: NumberType.natural,
      );
      expect(q.type, Operation.addition);
      expect(q.choices.length, 4);
      expect(q.choices.contains(q.ans), isTrue);
      // The answer should be derivable from the displayed text
      expect(q.text, contains('='));
    });

    test('subtraction medium produces valid question', () {
      final q = qgen.build(
        type: Operation.subtraction,
        diff: Difficulty.medium,
        numType: NumberType.natural,
      );
      expect(q.type, Operation.subtraction);
      expect(q.choices.length, 4);
      expect(q.choices.contains(q.ans), isTrue);
    });

    test('multiplication hard produces valid question', () {
      final q = qgen.build(
        type: Operation.multiplication,
        diff: Difficulty.hard,
        numType: NumberType.natural,
      );
      expect(q.type, Operation.multiplication);
      expect(q.choices.length, 4);
      expect(q.choices.contains(q.ans), isTrue);
    });

    test('division insane produces valid question', () {
      final q = qgen.build(
        type: Operation.division,
        diff: Difficulty.insane,
        numType: NumberType.natural,
      );
      expect(q.type, Operation.division);
      expect(q.choices.length, 4);
      expect(q.choices.contains(q.ans), isTrue);
    });

    test('integers numType can produce negative answers', () {
      bool foundNegative = false;
      for (var i = 0; i < 50; i++) {
        final q = qgen.build(
          type: Operation.addition,
          diff: Difficulty.medium,
          numType: NumberType.integers,
        );
        if (q.ans < 0) {
          foundNegative = true;
          break;
        }
      }
      expect(foundNegative, isTrue, reason: 'Should produce at least one negative answer in 50 tries');
    });

    test('rationals numType produces decimal answers', () {
      bool foundDecimal = false;
      for (var i = 0; i < 50; i++) {
        final q = qgen.build(
          type: Operation.addition,
          diff: Difficulty.hard,
          numType: NumberType.rationals,
        );
        if (q.ans != q.ans.roundToDouble()) {
          foundDecimal = true;
          break;
        }
      }
      expect(foundDecimal, isTrue, reason: 'Should produce at least one decimal answer in 50 tries');
    });

    test('all 4 choices are unique', () {
      for (var i = 0; i < 20; i++) {
        final q = qgen.build(
          type: Operation.addition,
          diff: Difficulty.medium,
          numType: NumberType.natural,
        );
        expect(q.choices.toSet().length, 4, reason: 'Choices should be unique');
      }
    });

    test('generates 100 unique questions without crash', () {
      final keys = <String>{};
      for (var i = 0; i < 100; i++) {
        final q = qgen.build(
          type: Operation.multiplication,
          diff: Difficulty.medium,
          numType: NumberType.natural,
        );
        keys.add(q.key);
        expect(q.ans, isNotNull);
      }
      // With multiplication medium (2-10 × 2-10) there are 81 unique keys,
      // so 100 questions should easily produce many unique ones.
      expect(keys.length, greaterThan(30));
    });
  });
}
