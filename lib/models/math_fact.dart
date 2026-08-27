import 'enums.dart';

/// The canonical mathematical relationship behind a generated question.
enum FactRepresentation {
  direct,
  missingLeft,
  missingRight,
}

/// Immutable generator-owned projection of `left operation right = result`.
class MathFact {
  const MathFact({
    required this.operation,
    required this.left,
    required this.right,
    required this.result,
    required this.representation,
    required this.difficulty,
    required this.numberType,
    this.rationalDecimalPlaces,
    this.allowsRelatedMissingRepresentations = true,
  });

  final Operation operation;
  final num left;
  final num right;
  final num result;
  final FactRepresentation representation;
  final Difficulty difficulty;
  final NumberType numberType;
  final int? rationalDecimalPlaces;
  final bool allowsRelatedMissingRepresentations;

  bool get isBasicOperation => switch (operation) {
        Operation.addition ||
        Operation.subtraction ||
        Operation.multiplication ||
        Operation.division =>
          true,
        _ => false,
      };

  bool get isMathematicallyValid {
    if (!isBasicOperation || (operation == Operation.division && right == 0)) {
      return false;
    }
    final expected = switch (operation) {
      Operation.addition => left + right,
      Operation.subtraction => left - right,
      Operation.multiplication => left * right,
      Operation.division => left / right,
      _ => result,
    };
    return (expected - result).abs() < 0.000001;
  }

  MathFact copyWith({
    Operation? operation,
    num? left,
    num? right,
    num? result,
    FactRepresentation? representation,
    Difficulty? difficulty,
    NumberType? numberType,
    int? rationalDecimalPlaces,
    bool? allowsRelatedMissingRepresentations,
  }) =>
      MathFact(
        operation: operation ?? this.operation,
        left: left ?? this.left,
        right: right ?? this.right,
        result: result ?? this.result,
        representation: representation ?? this.representation,
        difficulty: difficulty ?? this.difficulty,
        numberType: numberType ?? this.numberType,
        rationalDecimalPlaces:
            rationalDecimalPlaces ?? this.rationalDecimalPlaces,
        allowsRelatedMissingRepresentations:
            allowsRelatedMissingRepresentations ??
                this.allowsRelatedMissingRepresentations,
      );
}
