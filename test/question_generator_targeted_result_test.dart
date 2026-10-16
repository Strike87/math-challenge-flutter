import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';

void main() {
  const operations = [
    Operation.addition,
    Operation.subtraction,
    Operation.multiplication,
    Operation.division,
  ];
  const difficulties = [Difficulty.easy, Difficulty.medium, Difficulty.hard];
  const numberTypes = [
    NumberType.natural,
    NumberType.integers,
    NumberType.rationals,
  ];

  test('targets a known-reachable result in every canonical matrix cell', () {
    var seed = 1;
    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          final result = _reachableResult(operation, difficulty, numberType);
          final question =
              QuestionGenerator(rng: Random(seed++)).buildDirectForResult(
            type: operation,
            diff: difficulty,
            numType: numberType,
            result: result,
          );

          expect(
            question,
            isNotNull,
            reason: '$operation/$difficulty/$numberType',
          );
          final fact = question!.fact!;
          expect(question.ans, fact.result);
          expect(fact.representation, FactRepresentation.direct);
          expect(fact.isMathematicallyValid, isTrue);
          expect(fact.operation, operation);
          expect(fact.difficulty, difficulty);
          expect(fact.numberType, numberType);
          expect(fact.result, result);
        }
      }
    }
  });

  test('canonical direct domains are sorted, materializable, and RNG-neutral',
      () {
    var seed = 100;
    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          final a = QuestionGenerator(rng: Random(seed));
          final b = QuestionGenerator(rng: Random(seed++));
          final domain = b.canonicalDirectResultDomain(
              type: operation, diff: difficulty, numType: numberType);
          expect(domain, isNotEmpty,
              reason: '$operation/$difficulty/$numberType');
          expect(domain, orderedEquals([...domain]..sort()));
          expect(domain.toSet().length, domain.length,
              reason: 'canonical domain must not repeat results');
          // The public query is pure: even repeated inspection cannot perturb
          // the next ordinary generated question.
          expect(
              b.canonicalDirectResultDomain(
                  type: operation, diff: difficulty, numType: numberType),
              domain);
          final ordinaryA = a.build(
              type: operation, diff: difficulty, numType: numberType);
          final ordinaryB = b.build(
              type: operation, diff: difficulty, numType: numberType);
          _expectSameQuestion(ordinaryA, ordinaryB);
          for (final result in domain) {
            final direct = QuestionGenerator(rng: Random(1)).buildDirectForResult(
                type: operation,
                diff: difficulty,
                numType: numberType,
                result: result);
            expect(direct, isNotNull,
                reason: 'domain result $result must materialize');
            expect(direct!.fact!.result, result);
          }
        }
      }
    }
  });

  test('canonical domain excludes unsupported configurations', () {
    final generator = QuestionGenerator(rng: Random(23));
    for (final operation in Operation.values.skip(4)) {
      expect(generator.canonicalDirectResultDomain(
          type: operation,
          diff: Difficulty.easy,
          numType: NumberType.natural), isEmpty);
    }
    expect(generator.canonicalDirectResultDomain(
        type: Operation.addition,
        diff: Difficulty.easy,
        numType: NumberType.mixed), isEmpty);
  });

  test('finite independent result enumeration finds no canonical-domain omissions',
      () {
    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          final domain = QuestionGenerator(rng: Random(91))
              .canonicalDirectResultDomain(
                  type: operation, diff: difficulty, numType: numberType)
              .toSet();
          for (final result in _independentResultCandidates(
              operation, difficulty, numberType)) {
            final direct = QuestionGenerator(rng: Random(92))
                .buildDirectForResult(
                    type: operation,
                    diff: difficulty,
                    numType: numberType,
                    result: result);
            if (direct != null) {
              expect(domain, contains(result),
                  reason: '$operation/$difficulty/$numberType omits $result');
            }
          }
        }
      }
    }
  });

  test(
    'rejects unsupported, non-finite, off-grid, and unreachable requests',
    () {
      final generator = QuestionGenerator(rng: Random(2));
      for (final result in [double.infinity, double.nan]) {
        expect(
          generator.buildDirectForResult(
            type: Operation.addition,
            diff: Difficulty.easy,
            numType: NumberType.natural,
            result: result,
          ),
          isNull,
        );
      }
      expect(
        generator.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.mixed,
          result: 2,
        ),
        isNull,
      );
      expect(
        generator.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.rationals,
          result: 2.20000000005,
        ),
        isNull,
      );
      expect(
        generator.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.rationals,
          result: 2.200000000000001,
        ),
        isNull,
      );
      expect(
        generator.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.rationals,
          result: 1e-17,
        ),
        isNull,
      );
      expect(
        generator.buildDirectForResult(
          type: Operation.subtraction,
          diff: Difficulty.easy,
          numType: NumberType.integers,
          result: -1,
        ),
        isNull,
      );
      for (final operation in Operation.values.skip(4)) {
        expect(
          generator.buildDirectForResult(
            type: operation,
            diff: Difficulty.easy,
            numType: NumberType.natural,
            result: 2,
          ),
          isNull,
        );
      }
      expect(
        generator.buildDirectForResult(
          type: Operation.multiplication,
          diff: Difficulty.easy,
          numType: NumberType.natural,
          result: 7,
        ),
        isNull,
      );
      expect(
        generator.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.hard,
          numType: NumberType.rationals,
          result: 2.351,
        ),
        isNull,
      );
      for (final result in [1e-12, -1e-12]) {
        expect(
          generator.buildDirectForResult(
            type: Operation.addition,
            diff: Difficulty.easy,
            numType: NumberType.rationals,
            result: result,
          ),
          isNull,
          reason: '$result must not normalize to zero',
        );
      }
    },
  );

  test('normalizes only same-tick rational floating-point noise', () {
    final generator = QuestionGenerator(rng: Random(7));
    final question = generator.buildDirectForResult(
      type: Operation.addition,
      diff: Difficulty.easy,
      numType: NumberType.rationals,
      result: 1.1 + 1.2,
    );

    expect(question, isNotNull);
    final fact = question!.fact!;
    expect(fact.result, 2.3);
    expect(fact.rationalDecimalPlaces, 1);
    expect(fact.representation, FactRepresentation.direct);
    expect(fact.isMathematicallyValid, isTrue);
    for (final entry in [
      (Difficulty.easy, 2.2),
      (Difficulty.hard, 2.35),
      (Difficulty.insane, 2.351),
    ]) {
      expect(
        generator.buildDirectForResult(
          type: Operation.addition,
          diff: entry.$1,
          numType: NumberType.rationals,
          result: entry.$2,
        ),
        isNotNull,
        reason: '${entry.$1}/${entry.$2}',
      );
    }
  });

  test(
    'preserves boundaries, direct forms, rational precision, and seeded choice',
    () {
      final boundary = QuestionGenerator(rng: Random(3));
      expect(
        boundary.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.natural,
          result: 2,
        ),
        isNotNull,
      );
      expect(
        boundary.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.natural,
          result: 1,
        ),
        isNull,
      );

      for (final difficulty in [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
        Difficulty.expert,
        Difficulty.insane,
      ]) {
        final result = switch (difficulty) {
          Difficulty.easy || Difficulty.medium => 2.2,
          Difficulty.hard || Difficulty.expert => 2.35,
          Difficulty.insane => 2.351,
        };
        final question = boundary.buildDirectForResult(
          type: Operation.addition,
          diff: difficulty,
          numType: NumberType.rationals,
          result: result,
        )!;
        expect(
          question.fact!.rationalDecimalPlaces,
          switch (difficulty) {
            Difficulty.easy || Difficulty.medium => 1,
            Difficulty.hard || Difficulty.expert => 2,
            Difficulty.insane => 3,
          },
        );
      }
      expect(
        boundary.buildDirectForResult(
          type: Operation.addition,
          diff: Difficulty.easy,
          numType: NumberType.rationals,
          result: 1.1 + 1.1,
        ),
        isNotNull,
      );
      for (final difficulty in [Difficulty.medium, Difficulty.hard]) {
        final question = boundary.buildDirectForResult(
          type: Operation.subtraction,
          diff: difficulty,
          numType: NumberType.natural,
          result: _minFor(Operation.subtraction, difficulty),
        );
        expect(question!.fact!.representation, FactRepresentation.direct);
      }

      final first = QuestionGenerator(rng: Random(4)).buildDirectForResult(
        type: Operation.addition,
        diff: Difficulty.easy,
        numType: NumberType.natural,
        result: 10,
      )!;
      final second = QuestionGenerator(rng: Random(4)).buildDirectForResult(
        type: Operation.addition,
        diff: Difficulty.easy,
        numType: NumberType.natural,
        result: 10,
      )!;
      expect(first.key, second.key);
      expect(first.choices, second.choices);
    },
  );

  test('targets the canonical negative-right integer subtraction form', () {
    final question = QuestionGenerator(rng: Random(5)).buildDirectForResult(
      type: Operation.subtraction,
      diff: Difficulty.easy,
      numType: NumberType.integers,
      result: 27,
    )!;

    expect(question.fact!.left, 18);
    expect(question.fact!.right, -9);
    expect(question.fact!.result, 27);
  });

  test('targets only non-integer rational subtraction results from 1.x to 8.x',
      () {
    final generator = QuestionGenerator(rng: Random(6));
    for (final entry in [
      (Difficulty.easy, 1.1),
      (Difficulty.hard, 8.9),
    ]) {
      expect(
        generator.buildDirectForResult(
          type: Operation.subtraction,
          diff: entry.$1,
          numType: NumberType.rationals,
          result: entry.$2,
        ),
        isNotNull,
        reason: '${entry.$1}/${entry.$2}',
      );
    }
    for (final entry in [
      (Difficulty.easy, 2.0),
      (Difficulty.hard, 5.0),
    ]) {
      expect(
        generator.buildDirectForResult(
          type: Operation.subtraction,
          diff: entry.$1,
          numType: NumberType.rationals,
          result: entry.$2,
        ),
        isNull,
        reason: '${entry.$1}/${entry.$2}',
      );
    }
  });
}

void _expectSameQuestion(dynamic left, dynamic right) {
  expect(right.type, left.type);
  expect(right.key, left.key);
  expect(right.text, left.text);
  expect(right.ans, left.ans);
  expect(right.choices, left.choices);
  expect(right.diff, left.diff);
  expect(right.numType, left.numType);
  expect(right.ratDP, left.ratDP);
  final leftFact = left.fact!;
  final rightFact = right.fact!;
  expect(rightFact.operation, leftFact.operation);
  expect(rightFact.left, leftFact.left);
  expect(rightFact.right, leftFact.right);
  expect(rightFact.result, leftFact.result);
  expect(rightFact.representation, leftFact.representation);
  expect(rightFact.difficulty, leftFact.difficulty);
  expect(rightFact.numberType, leftFact.numberType);
  expect(rightFact.rationalDecimalPlaces, leftFact.rationalDecimalPlaces);
}

Iterable<num> _independentResultCandidates(
    Operation operation, Difficulty difficulty, NumberType numberType) sync* {
  final max = switch (operation) {
    Operation.addition => const [20, 98, 198][difficulty.index],
    Operation.subtraction || Operation.division =>
      const [9, 44, 79][difficulty.index],
    Operation.multiplication => const [25, 100, 144][difficulty.index],
    _ => 0,
  };
  if (numberType == NumberType.rationals) {
    final factor = difficulty == Difficulty.hard ? 100 : 10;
    final upper = operation == Operation.multiplication ? 144 * factor : 32 * factor;
    for (var tick = -upper; tick <= upper; tick++) yield tick / factor;
    return;
  }
  // These bounds are independently derived from the visible operand ranges;
  // include negatives for integer direct forms.
  final upper = operation == Operation.multiplication ? max * max : max * 3;
  final lower = numberType == NumberType.integers ? -upper : 0;
  for (var value = lower; value <= upper; value++) yield value;
}

num _reachableResult(
  Operation operation,
  Difficulty difficulty,
  NumberType numberType,
) {
  if (numberType == NumberType.rationals)
    return operation == Operation.addition ||
            operation == Operation.multiplication
        ? 2.2
        : 1.1;
  final min = _minFor(operation, difficulty);
  return switch (operation) {
    Operation.addition => min * 2,
    Operation.subtraction || Operation.division => min,
    Operation.multiplication => min * min,
    _ => throw ArgumentError.value(operation),
  };
}

int _minFor(Operation operation, Difficulty difficulty) {
  final index = difficulty.index;
  return switch (operation) {
    Operation.addition => const [1, 11, 25][index],
    Operation.subtraction => const [1, 5, 15][index],
    Operation.multiplication || Operation.division => const [2, 2, 3][index],
    _ => throw ArgumentError.value(operation),
  };
}
