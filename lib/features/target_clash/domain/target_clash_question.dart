import 'dart:math' as math;

import '../../../models/enums.dart';
import '../../../models/math_fact.dart';
import 'presentation_answer.dart';

enum TargetZone {
  normal,
  closeCall,
  danger,
  bullseye;

  static TargetZone? classifyDistance(int distanceUnits) =>
      switch (distanceUnits) {
        0 => bullseye,
        1 => danger,
        2 || 3 => closeCall,
        4 || 5 || 6 => normal,
        _ => null,
      };
}

final class TargetClashQuestion {
  const TargetClashQuestion._({
    required this.expression,
    required this.targetValue,
    required this.correctAnswer,
    required this.zone,
  });

  final MathFact expression;
  num get expressionValue => expression.result;
  final num targetValue;
  final PresentationAnswer correctAnswer;
  final TargetZone zone;

  static bool supportsConfiguration({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
  }) =>
      switch (operation) {
        Operation.addition ||
        Operation.subtraction ||
        Operation.multiplication ||
        Operation.division =>
          true,
        _ => false,
      } &&
      switch (difficulty) {
        Difficulty.easy || Difficulty.medium || Difficulty.hard => true,
        _ => false,
      } &&
      numberType != NumberType.mixed;

  /// Returns null for unsupported facts, unrepresentable values or distances.
  /// Relation and distance are compared only after validating the domain grid.
  static TargetClashQuestion? tryCreate({
    required MathFact expression,
    required num targetValue,
  }) {
    if (!supportsConfiguration(
          operation: expression.operation,
          difficulty: expression.difficulty,
          numberType: expression.numberType,
        ) ||
        expression.representation != FactRepresentation.direct ||
        !expression.isMathematicallyValid) {
      return null;
    }
    final resultUnits = _units(expression.result, expression);
    final targetUnits = _units(targetValue, expression);
    if (resultUnits == null || targetUnits == null) return null;
    final distance =
        (BigInt.from(resultUnits) - BigInt.from(targetUnits)).abs();
    if (distance > BigInt.from(6)) return null;
    final zone = TargetZone.classifyDistance(distance.toInt());
    if (zone == null) return null;
    return TargetClashQuestion._(
      expression: expression,
      targetValue: targetValue,
      correctAnswer: PresentationAnswer.classify(resultUnits, targetUnits),
      zone: zone,
    );
  }

  static int? _units(num value, MathFact expression) {
    if (!value.isFinite) return null;
    switch (expression.numberType) {
      case NumberType.natural:
      case NumberType.integers:
        if (expression.numberType == NumberType.natural && value < 0)
          return null;
        final integer = value.toInt();
        return integer == value ? integer : null;
      case NumberType.rationals:
        final places = expression.rationalDecimalPlaces ?? 1;
        if (places < 0) return null;
        final scale = math.pow(10.0, places);
        final scaled = value * scale;
        // Beyond exact double integers, adjacent decimal ticks are ambiguous.
        if (!scale.isFinite ||
            !scaled.isFinite ||
            scaled.abs() > 9007199254740991) return null;
        final units = scaled.round();
        final normalized = units / scale;
        // Allow only double representation noise in the decimal round trip.
        // At zero the bound is zero, so tiny off-grid values cannot be equal.
        // Relation and zone still use exact integer ticks.
        final roundTripError = normalized.abs() * 2.220446049250313e-16;
        return (value - normalized).abs() <= roundTripError ? units : null;
      case NumberType.mixed:
        return null;
    }
  }
}
