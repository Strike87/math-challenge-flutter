import '../../../../models/enums.dart';
import '../../domain/brain_observation.dart';

const double misconceptionTolerance = 1e-9;

bool nearlyEqual(num first, num second) =>
    (first - second).abs() <= misconceptionTolerance;

num? numericalAnswer(String? answer) {
  final value = num.tryParse(answer ?? '');
  return value != null && value.isFinite ? value : null;
}

bool isWrongSubmittedAnswer(BrainObservation observation) =>
    !observation.correct &&
    !observation.timedOut &&
    observation.submittedAnswer != null;

bool hasOperands(BrainObservation observation) =>
    observation.leftOperand != null && observation.rightOperand != null;

bool isBasicOperation(Operation operation) =>
    operation == Operation.addition ||
    operation == Operation.subtraction ||
    operation == Operation.multiplication ||
    operation == Operation.division;

num? directResult(Operation operation, num leftOperand, num rightOperand) {
  switch (operation) {
    case Operation.addition:
      return leftOperand + rightOperand;
    case Operation.subtraction:
      return leftOperand - rightOperand;
    case Operation.multiplication:
      return leftOperand * rightOperand;
    case Operation.division:
      return rightOperand == 0 ? null : leftOperand / rightOperand;
    case Operation.mixed:
    case Operation.master:
    case Operation.dailyBoss:
    case Operation.survival:
      return null;
  }
}

bool hasVerifiedDirectCorrectAnswer(BrainObservation observation) {
  if (!hasOperands(observation) || !isBasicOperation(observation.operation)) {
    return false;
  }
  final expected = directResult(
    observation.operation,
    observation.leftOperand!,
    observation.rightOperand!,
  );
  final correctAnswer = numericalAnswer(observation.correctAnswer);
  return expected != null &&
      correctAnswer != null &&
      nearlyEqual(expected, correctAnswer);
}
