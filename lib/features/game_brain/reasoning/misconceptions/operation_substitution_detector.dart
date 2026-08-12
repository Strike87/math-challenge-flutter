import '../../../../models/enums.dart';
import '../../domain/brain_observation.dart';
import '../../domain/misconception_evidence.dart';
import 'detector_math.dart';
import 'misconception_detector.dart';

/// Detects exactly one alternative basic operation on the supplied operands.
final class OperationSubstitutionDetector implements MisconceptionDetector {
  const OperationSubstitutionDetector();

  @override
  MisconceptionEvidence? detect(BrainObservation observation) {
    if (!isWrongSubmittedAnswer(observation) ||
        !hasVerifiedDirectCorrectAnswer(observation)) {
      return null;
    }
    final submittedAnswer = numericalAnswer(observation.submittedAnswer);
    final correctAnswer = numericalAnswer(observation.correctAnswer);
    if (submittedAnswer == null || correctAnswer == null) {
      return null;
    }

    final matches = <Operation>[];
    for (final candidateOperation in const [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ]) {
      if (candidateOperation == observation.operation) {
        continue;
      }
      final candidateResult = directResult(
        candidateOperation,
        observation.leftOperand!,
        observation.rightOperand!,
      );
      if (candidateResult != null &&
          !nearlyEqual(candidateResult, correctAnswer) &&
          nearlyEqual(candidateResult, submittedAnswer)) {
        matches.add(candidateOperation);
      }
    }
    if (matches.length != 1) {
      return null;
    }
    return MisconceptionEvidence(
      tag: 'operation-substitution:${matches.single.name}',
      type: MisconceptionType.operationSubstitution,
      reason: MisconceptionReason.alternativeBasicOperation,
      confidence: 0.9,
    );
  }
}
