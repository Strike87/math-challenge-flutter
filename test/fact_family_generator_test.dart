import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';

void main() {
  const basic = {
    Operation.addition,
    Operation.subtraction,
    Operation.multiplication,
    Operation.division,
  };

  group('canonical fact-family generator', () {
    test('build projects a generator-created structured fact', () {
      final question = QuestionGenerator(rng: Random(8)).build(
        type: Operation.multiplication,
        diff: Difficulty.hard,
        numType: NumberType.natural,
      );

      expect(question.fact, isNotNull);
      expect(question.fact!.operation, question.type);
      expect(question.fact!.difficulty, question.diff);
      expect(question.fact!.numberType, question.numType);
      expect(question.fact!.isMathematicallyValid, isTrue);
    });

    test('Easy declines non-commutative facts with no distinct direct form',
        () {
      final fact = _fact(
        operation: Operation.subtraction,
        left: 13,
        right: 5,
        result: 8,
        representation: FactRepresentation.direct,
        difficulty: Difficulty.easy,
      );

      final related = QuestionGenerator(rng: Random(1)).buildRelated(
        fact: fact,
        diff: Difficulty.easy,
        numType: NumberType.natural,
        allowedOperations: {Operation.subtraction},
      );

      expect(related, isNull);
    });

    test('Easy rejects missing-left and missing-right related forms', () {
      final fact = _fact(
        operation: Operation.addition,
        left: 8,
        right: 5,
        result: 13,
        representation: FactRepresentation.direct,
        difficulty: Difficulty.easy,
      );

      expect(
        QuestionGenerator(rng: Random(2)).buildRelated(
          fact: fact,
          diff: Difficulty.easy,
          numType: NumberType.natural,
          allowedOperations: {Operation.addition},
          excludedRepresentations: {FactRepresentation.direct},
        ),
        isNull,
      );
    });

    test('inverse candidates obey the target operation range', () {
      final easyMultiplication = _fact(
        operation: Operation.multiplication,
        left: 8,
        right: 7,
        result: 56,
        representation: FactRepresentation.direct,
        difficulty: Difficulty.easy,
      );

      expect(
        _findRelated(
            easyMultiplication, basic, (q) => q.type == Operation.division),
        isNull,
      );
    });

    test('Medium and Hard allow missing representations', () {
      for (final difficulty in [Difficulty.medium, Difficulty.hard]) {
        final fact = _fact(
          operation: Operation.multiplication,
          left: 8,
          right: 7,
          result: 56,
          representation: FactRepresentation.direct,
          difficulty: difficulty,
        );
        final representations = <FactRepresentation>{};
        for (var seed = 0; seed < 40; seed++) {
          final related = QuestionGenerator(rng: Random(seed)).buildRelated(
            fact: fact,
            diff: difficulty,
            numType: NumberType.natural,
            allowedOperations: {Operation.multiplication},
          );
          representations.add(related!.fact!.representation);
        }
        expect(
            representations,
            containsAll([
              FactRepresentation.missingLeft,
              FactRepresentation.missingRight
            ]));
      }
    });

    test('commutativity is addition/multiplication only', () {
      final multiplication = _fact(
        operation: Operation.multiplication,
        left: 8,
        right: 7,
        result: 56,
        representation: FactRepresentation.missingLeft,
        difficulty: Difficulty.hard,
      );
      final reversed = _findRelated(
          multiplication,
          {Operation.multiplication},
          (q) =>
              q.fact!.representation == FactRepresentation.direct &&
              q.fact!.left == 7 &&
              q.fact!.right == 8);
      expect(reversed, isNotNull);

      final subtraction = _fact(
        operation: Operation.subtraction,
        left: 50,
        right: 20,
        result: 30,
        representation: FactRepresentation.missingLeft,
        difficulty: Difficulty.hard,
      );
      for (var seed = 0; seed < 40; seed++) {
        final q = QuestionGenerator(rng: Random(seed)).buildRelated(
          fact: subtraction,
          diff: Difficulty.hard,
          numType: NumberType.natural,
          allowedOperations: {Operation.subtraction},
        );
        expect(q!.fact!.left, 50);
        expect(q.fact!.right, 20);
      }
    });

    test('inverse variants require mixed effective scope', () {
      final multiplication = _fact(
        operation: Operation.multiplication,
        left: 8,
        right: 7,
        result: 56,
        representation: FactRepresentation.missingLeft,
        difficulty: Difficulty.hard,
      );
      expect(
        _findRelated(multiplication, {Operation.multiplication},
            (q) => q.type == Operation.division),
        isNull,
      );
      final inverse = _findRelated(
        multiplication,
        basic,
        (q) => q.type == Operation.division && q.fact!.isMathematicallyValid,
      );
      expect(inverse, isNotNull);
      expect(inverse!.fact!.left, 56);
      expect(inverse.fact!.right == 7 || inverse.fact!.right == 8, isTrue);
    });

    test('division never swaps operands in same-operation forms', () {
      final division = _fact(
        operation: Operation.division,
        left: 56,
        right: 7,
        result: 8,
        representation: FactRepresentation.missingLeft,
        difficulty: Difficulty.hard,
      );

      for (var seed = 0; seed < 40; seed++) {
        final related = QuestionGenerator(rng: Random(seed)).buildRelated(
          fact: division,
          diff: Difficulty.hard,
          numType: NumberType.natural,
          allowedOperations: {Operation.division},
        );
        expect(related!.fact!.left, 56);
        expect(related.fact!.right, 7);
      }
    });

    test('Addition-only scope never returns Subtraction', () {
      final addition = _fact(
        operation: Operation.addition,
        left: 20,
        right: 15,
        result: 35,
        representation: FactRepresentation.missingLeft,
        difficulty: Difficulty.medium,
      );

      expect(
        _findRelated(addition, {Operation.addition},
            (question) => question.type == Operation.subtraction),
        isNull,
      );
    });

    test('Mixed effective scope permits Addition to Subtraction', () {
      final addition = _fact(
        operation: Operation.addition,
        left: 20,
        right: 15,
        result: 35,
        representation: FactRepresentation.missingLeft,
        difficulty: Difficulty.medium,
      );

      final inverse = _findRelated(
        addition,
        basic,
        (question) =>
            question.type == Operation.subtraction &&
            question.fact!.isMathematicallyValid,
      );
      expect(inverse, isNotNull);
      expect(inverse!.fact!.left, 35);
    });

    test('unsafe division facts decline before inverse generation', () {
      final unsafe = _fact(
        operation: Operation.division,
        left: 0,
        right: 0,
        result: 0,
        representation: FactRepresentation.direct,
        difficulty: Difficulty.medium,
      );

      expect(
        QuestionGenerator(rng: Random(3)).buildRelated(
          fact: unsafe,
          diff: Difficulty.medium,
          numType: NumberType.natural,
          allowedOperations: basic,
        ),
        isNull,
      );
    });

    test('Integer and Rational related forms preserve canonical legality', () {
      for (final numberType in [NumberType.integers, NumberType.rationals]) {
        final source = List.generate(
          40,
          (seed) => QuestionGenerator(rng: Random(seed)).build(
            type: Operation.addition,
            diff: Difficulty.medium,
            numType: numberType,
          ),
        ).firstWhere(
            (question) => !question.fact!.allowsRelatedMissingRepresentations);
        final related = _findRelated(
            source.fact!,
            {Operation.addition},
            (q) =>
                q.fact!.representation == FactRepresentation.direct &&
                q.fact!.left == source.fact!.right &&
                q.fact!.right == source.fact!.left);
        expect(related, isNotNull);
        expect(related!.numType, numberType);
        expect(related.fact!.numberType, numberType);
        expect(related.fact!.representation, FactRepresentation.direct);
        expect(related.fact!.isMathematicallyValid, isTrue);
      }
    });

    test('invalid requests decline without changing normal generation', () {
      final source = QuestionGenerator(rng: Random(22)).build(
        type: Operation.addition,
        diff: Difficulty.medium,
        numType: NumberType.natural,
      );
      expect(
        QuestionGenerator(rng: Random(23)).buildRelated(
          fact: source.fact!,
          diff: Difficulty.hard,
          numType: NumberType.natural,
          allowedOperations: {Operation.addition},
        ),
        isNull,
      );
      expect(source.choices, hasLength(4));
      expect(source.choices, contains(source.ans));
    });
  });
}

MathFact _fact({
  required Operation operation,
  required num left,
  required num right,
  required num result,
  required FactRepresentation representation,
  required Difficulty difficulty,
}) =>
    MathFact(
      operation: operation,
      left: left,
      right: right,
      result: result,
      representation: representation,
      difficulty: difficulty,
      numberType: NumberType.natural,
    );

dynamic _findRelated(
    MathFact fact, Set<Operation> scope, bool Function(dynamic) match) {
  for (var seed = 0; seed < 80; seed++) {
    final related = QuestionGenerator(rng: Random(seed)).buildRelated(
      fact: fact,
      diff: fact.difficulty,
      numType: fact.numberType,
      allowedOperations: scope,
    );
    if (related != null && match(related)) return related;
  }
  return null;
}
