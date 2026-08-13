import '../../domain/brain_observation.dart';
import '../../domain/misconception_evidence.dart';
import 'detector_math.dart';
import 'misconception_detector.dart';

/// Detects a nonzero answer with the correct magnitude but the opposite sign.
final class SignRuleDetector implements MisconceptionDetector {
  const SignRuleDetector();

  @override
  MisconceptionEvidence? detect(BrainObservation observation) {
    if (!isWrongSubmittedAnswer(observation)) {
      return null;
    }
    final correctAnswer = numericalAnswer(observation.correctAnswer);
    final submittedAnswer = numericalAnswer(observation.submittedAnswer);
    if (correctAnswer == null ||
        submittedAnswer == null ||
        correctAnswer.abs() <= misconceptionTolerance ||
        submittedAnswer.abs() <= misconceptionTolerance ||
        !nearlyEqual(correctAnswer.abs(), submittedAnswer.abs()) ||
        correctAnswer * submittedAnswer >= 0) {
      return null;
    }
    return MisconceptionEvidence(
      tag: 'sign-rule:opposite-sign-same-magnitude',
      type: MisconceptionType.signRule,
      reason: MisconceptionReason.oppositeSignSameMagnitude,
      confidence: 0.95,
    );
  }
}
