import '../../../../models/enums.dart';
import '../../domain/brain_observation.dart';
import '../../domain/misconception_evidence.dart';
import 'detector_math.dart';
import 'misconception_detector.dart';

/// Detects one unambiguous 2..12 adjacent-factor multiplication confusion.
///
/// Both original factors and the one changed factor must remain in 2..12. The
/// submitted product must match exactly one ordered candidate; matching two
/// candidates, including duplicate products from equal factors, is rejected.
final class MultiplicationFactDetector implements MisconceptionDetector {
  const MultiplicationFactDetector();

  @override
  MisconceptionEvidence? detect(BrainObservation observation) {
    if (!isWrongSubmittedAnswer(observation) ||
        observation.operation != Operation.multiplication ||
        observation.numberType != NumberType.natural ||
        !hasVerifiedDirectCorrectAnswer(observation)) {
      return null;
    }
    final leftOperand = observation.leftOperand!;
    final rightOperand = observation.rightOperand!;
    final submittedAnswer = numericalAnswer(observation.submittedAnswer);
    if (submittedAnswer == null ||
        leftOperand is! int && leftOperand % 1 != 0 ||
        rightOperand is! int && rightOperand % 1 != 0 ||
        leftOperand < 2 ||
        leftOperand > 12 ||
        rightOperand < 2 ||
        rightOperand > 12) {
      return null;
    }

    final matches = <num>[];
    for (final adjustedRight in [rightOperand - 1, rightOperand + 1]) {
      if (adjustedRight >= 2 &&
          adjustedRight <= 12 &&
          nearlyEqual(leftOperand * adjustedRight, submittedAnswer)) {
        matches.add(leftOperand * adjustedRight);
      }
    }
    for (final adjustedLeft in [leftOperand - 1, leftOperand + 1]) {
      if (adjustedLeft >= 2 &&
          adjustedLeft <= 12 &&
          nearlyEqual(rightOperand * adjustedLeft, submittedAnswer)) {
        matches.add(rightOperand * adjustedLeft);
      }
    }
    if (matches.length != 1) {
      return null;
    }
    return MisconceptionEvidence(
      tag: 'multiplication-fact:adjacent-factor',
      type: MisconceptionType.multiplicationFact,
      reason: MisconceptionReason.adjacentMultiplicationFactor,
      confidence: 0.75,
    );
  }
}
