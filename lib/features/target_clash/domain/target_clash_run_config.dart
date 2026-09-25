import '../../../models/enums.dart';

enum TargetClashProfile { v1 }

final class TargetClashRunConfig {
  const TargetClashRunConfig._({
    required this.operation,
    required this.difficulty,
    required this.numberType,
  });

  static TargetClashRunConfig? tryCreate({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
  }) {
    if (!const {
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    }.contains(operation)) {
      return null;
    }
    if (!const {Difficulty.easy, Difficulty.medium, Difficulty.hard}
        .contains(difficulty)) {
      return null;
    }
    if (!const {NumberType.natural, NumberType.integers, NumberType.rationals}
        .contains(numberType)) {
      return null;
    }
    return TargetClashRunConfig._(
      operation: operation,
      difficulty: difficulty,
      numberType: numberType,
    );
  }

  final Operation operation;
  final Difficulty difficulty;
  final NumberType numberType;
  TargetClashProfile get profile => TargetClashProfile.v1;

  int get questionTarget => switch (difficulty) {
        Difficulty.easy => 12,
        Difficulty.medium => 16,
        Difficulty.hard => 17,
        _ => throw StateError('Unsupported Target Clash difficulty.'),
      };
}
