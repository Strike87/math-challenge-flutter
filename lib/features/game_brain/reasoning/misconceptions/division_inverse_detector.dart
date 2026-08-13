import '../../../../models/enums.dart';
import '../../domain/brain_observation.dart';
import '../../domain/misconception_evidence.dart';
import 'detector_math.dart';
import 'misconception_detector.dart';

/// Detects division answers produced by reversing two nonzero operands.
final class DivisionInverseDetector implements MisconceptionDetector {
  const DivisionInverseDetector();

  @override
  MisconceptionEvidence? detect(BrainObservation observation) {
    if (!isWrongSubmittedAnswer(observation) ||
        observation.operation != Operation.division ||
        !hasVerifiedDirectCorrectAnswer(observation)) {
      return null;
    }
    final leftOperand = observation.leftOperand!;
    final rightOperand = observation.rightOperand!;
    final correctAnswer = numericalAnswer(observation.correctAnswer);
    final submittedAnswer = numericalAnswer(observation.submittedAnswer);
    if (leftOperand == 0 ||
        rightOperand == 0 ||
        correctAnswer == null ||
        submittedAnswer == null) {
      return null;
    }
    final reversedAnswer = rightOperand / leftOperand;
    if (nearlyEqual(reversedAnswer, correctAnswer) ||
        !nearlyEqual(reversedAnswer, submittedAnswer)) {
      return null;
    }
    return MisconceptionEvidence(
      tag: 'division-inverse:reversed-operands',
      type: MisconceptionType.divisionInverse,
      reason: MisconceptionReason.reversedDivisionOperands,
      confidence: 0.9,
    );
  }
}
