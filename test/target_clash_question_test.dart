import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';

MathFact fact(num result,
        {NumberType numberType = NumberType.natural, int? dp}) =>
    MathFact(
      operation: Operation.addition,
      left: result,
      right: 0,
      result: result,
      representation: FactRepresentation.direct,
      difficulty: Difficulty.easy,
      numberType: numberType,
      rationalDecimalPlaces: dp,
    );

void main() {
  test('relation classification preserves all three numeric comparisons', () {
    expect(PresentationAnswer.classify(10, 11), PresentationAnswer.lessThan);
    expect(PresentationAnswer.classify(11, 11), PresentationAnswer.equalTo);
    expect(PresentationAnswer.classify(12, 11), PresentationAnswer.greaterThan);
    expect(
        () => PresentationAnswer.classify(double.nan, 11), throwsArgumentError);
    expect(() => PresentationAnswer.classify(11, double.infinity),
        throwsArgumentError);
  });

  const bands = [
    TargetZone.bullseye,
    TargetZone.danger,
    TargetZone.closeCall,
    TargetZone.closeCall,
    TargetZone.normal,
    TargetZone.normal,
    TargetZone.normal,
  ];
  for (var distance = 0; distance <= 6; distance++) {
    test('distance $distance computes ${bands[distance]} and relation', () {
      final expression = fact(12);
      for (final direction in [-1, 1]) {
        final question = TargetClashQuestion.tryCreate(
          expression: expression,
          targetValue: 12 + direction * distance,
        )!;
        expect(question.expression, same(expression));
        expect(question.expressionValue, 12);
        expect(question.zone, bands[distance]);
        expect(
            question.correctAnswer,
            distance == 0
                ? PresentationAnswer.equalTo
                : direction == 1
                    ? PresentationAnswer.lessThan
                    : PresentationAnswer.greaterThan);
      }
    });
  }

  test('distance outside frozen bands is unclassifiable', () {
    expect(TargetZone.classifyDistance(-1), isNull);
    expect(TargetZone.classifyDistance(7), isNull);
    expect(TargetClashQuestion.tryCreate(expression: fact(12), targetValue: 5),
        isNull);
    expect(TargetClashQuestion.tryCreate(expression: fact(12), targetValue: 19),
        isNull);
  });

  test('natural targets require nonnegative integers', () {
    expect(TargetClashQuestion.tryCreate(expression: fact(0), targetValue: 0),
        isNotNull);
    expect(TargetClashQuestion.tryCreate(expression: fact(0), targetValue: -1),
        isNull);
    expect(TargetClashQuestion.tryCreate(expression: fact(1), targetValue: 0.5),
        isNull);
  });

  test('integer targets allow negatives but reject fractions', () {
    final expression = fact(-2, numberType: NumberType.integers);
    final question =
        TargetClashQuestion.tryCreate(expression: expression, targetValue: -3)!;
    expect(question.correctAnswer, PresentationAnswer.greaterThan);
    expect(question.zone, TargetZone.danger);
    expect(
        TargetClashQuestion.tryCreate(
            expression: expression, targetValue: -2.5),
        isNull);
  });

  test('integer distance cannot wrap across native signed integer limits', () {
    const maxInt = 0x7fffffffffffffff;
    const minInt = -0x7fffffffffffffff - 1;
    for (final pair in [(maxInt, minInt), (minInt, maxInt)]) {
      expect(
        TargetClashQuestion.tryCreate(
          expression: fact(pair.$1, numberType: NumberType.integers),
          targetValue: pair.$2,
        ),
        isNull,
      );
    }
    for (final pair in [(maxInt, maxInt - 1), (minInt, minInt + 1)]) {
      final question = TargetClashQuestion.tryCreate(
        expression: fact(pair.$1, numberType: NumberType.integers),
        targetValue: pair.$2,
      )!;
      expect(question.zone, TargetZone.danger);
      expect(
          question.correctAnswer,
          pair.$1 > pair.$2
              ? PresentationAnswer.greaterThan
              : PresentationAnswer.lessThan);
    }
  });

  for (final sample in [
    (dp: 1, result: 1.5, target: 1.4, zone: TargetZone.danger),
    (dp: 2, result: 2.35, target: 2.32, zone: TargetZone.closeCall),
    (dp: null, result: 1.5, target: 1.4, zone: TargetZone.danger),
    (dp: 1, result: 2.3, target: 2.2, zone: TargetZone.danger),
  ]) {
    test('rational dp=${sample.dp}: ${sample.result} vs ${sample.target}', () {
      final expression =
          fact(sample.result, numberType: NumberType.rationals, dp: sample.dp);
      final question = TargetClashQuestion.tryCreate(
          expression: expression, targetValue: sample.target)!;
      expect(question.correctAnswer, PresentationAnswer.greaterThan);
      expect(question.zone, sample.zone);
      expect(
          TargetClashQuestion.tryCreate(
              expression: expression, targetValue: sample.target + 0.001),
          isNull);
    });
  }

  test('rational lattice normalization handles noise, not semantic epsilon',
      () {
    final expression = fact(0.1 + 0.2, numberType: NumberType.rationals, dp: 1);
    final equal = TargetClashQuestion.tryCreate(
        expression: expression, targetValue: 0.3)!;
    expect(equal.correctAnswer, PresentationAnswer.equalTo);
    expect(equal.zone, TargetZone.bullseye);
    expect(
        TargetClashQuestion.tryCreate(
            expression: expression, targetValue: 0.3000001),
        isNull);
    final tiny = TargetClashQuestion.tryCreate(
      expression: fact(0.00000002, numberType: NumberType.rationals, dp: 8),
      targetValue: 0.00000001,
    )!;
    expect(tiny.correctAnswer, PresentationAnswer.greaterThan);
    expect(tiny.zone, TargetZone.danger);
  });

  test('off-grid rational values cannot normalize to zero or a nearby tick',
      () {
    for (final sample in [
      (normalized: 0.0, offGrid: 1e-11),
      (normalized: 0.0, offGrid: -1e-11),
      (normalized: 0.3, offGrid: 0.3 + 1e-11),
      (normalized: 0.3, offGrid: 0.3 - 1e-11),
    ]) {
      expect(
        TargetClashQuestion.tryCreate(
          expression:
              fact(sample.normalized, numberType: NumberType.rationals, dp: 1),
          targetValue: sample.offGrid,
        ),
        isNull,
        reason: 'Off-grid target ${sample.offGrid}',
      );
      expect(
        TargetClashQuestion.tryCreate(
          expression:
              fact(sample.offGrid, numberType: NumberType.rationals, dp: 1),
          targetValue: sample.normalized,
        ),
        isNull,
        reason: 'Off-grid expression ${sample.offGrid}',
      );
    }
  });

  test('invalid rational precision and nonfinite values fail closed', () {
    for (final dp in [-1, 400]) {
      expect(
          TargetClashQuestion.tryCreate(
            expression: fact(1, numberType: NumberType.rationals, dp: dp),
            targetValue: 1,
          ),
          isNull);
    }
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity
    ]) {
      expect(
          TargetClashQuestion.tryCreate(
              expression: fact(1), targetValue: value),
          isNull);
      expect(
          TargetClashQuestion.tryCreate(
              expression: fact(value), targetValue: 1),
          isNull);
    }
    expect(
        TargetClashQuestion.tryCreate(
          expression: fact(1.25, numberType: NumberType.rationals, dp: 1),
          targetValue: 1.2,
        ),
        isNull);
  });

  for (final representation in [
    FactRepresentation.missingLeft,
    FactRepresentation.missingRight
  ]) {
    test('$representation is rejected', () {
      expect(
          TargetClashQuestion.tryCreate(
            expression: fact(12).copyWith(representation: representation),
            targetValue: 12,
          ),
          isNull);
    });
  }

  test('invalid math and division by zero are rejected', () {
    expect(
        TargetClashQuestion.tryCreate(
            expression: fact(12).copyWith(result: 13), targetValue: 13),
        isNull);
    expect(
        TargetClashQuestion.tryCreate(
            expression: fact(12).copyWith(operation: Operation.division),
            targetValue: 12),
        isNull);
  });

  for (final operation in [
    Operation.mixed,
    Operation.master,
    Operation.dailyBoss,
    Operation.survival
  ]) {
    test('$operation is rejected', () {
      expect(
          TargetClashQuestion.tryCreate(
              expression: fact(12).copyWith(operation: operation),
              targetValue: 12),
          isNull);
    });
  }
  for (final difficulty in [Difficulty.expert, Difficulty.insane]) {
    test('$difficulty is rejected', () {
      expect(
          TargetClashQuestion.tryCreate(
              expression: fact(12).copyWith(difficulty: difficulty),
              targetValue: 12),
          isNull);
    });
  }
  test('mixed number type is rejected', () {
    expect(
        TargetClashQuestion.tryCreate(
            expression: fact(12, numberType: NumberType.mixed),
            targetValue: 12),
        isNull);
  });
}
