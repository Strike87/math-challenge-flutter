import '../../../models/enums.dart';
import 'misconception_evidence.dart';

/// Immutable, value-only data captured after one question outcome.
final class BrainObservation {
  BrainObservation({
    required this.operation,
    required this.difficulty,
    required this.numberType,
    required this.correctAnswer,
    required this.submittedAnswer,
    required this.correct,
    required this.timedOut,
    required this.responseTimeMs,
    required this.masteryBefore,
    required this.masteryAfter,
    this.misconceptionEvidence,
  }) {
    if (correctAnswer.trim().isEmpty) {
      throw ArgumentError.value(
        correctAnswer,
        'correctAnswer',
        'must not be empty',
      );
    }
    if (submittedAnswer?.trim().isEmpty ?? false) {
      throw ArgumentError.value(
        submittedAnswer,
        'submittedAnswer',
        'must not be empty when supplied',
      );
    }
    if (timedOut && correct) {
      throw ArgumentError('A timed-out observation cannot be correct.');
    }
    if (responseTimeMs < 0) {
      throw ArgumentError.value(
        responseTimeMs,
        'responseTimeMs',
        'must not be negative',
      );
    }
    _validateMastery(masteryBefore, 'masteryBefore');
    _validateMastery(masteryAfter, 'masteryAfter');
  }

  final Operation operation;
  final Difficulty difficulty;
  final NumberType numberType;
  final String correctAnswer;
  final String? submittedAnswer;
  final bool correct;
  final bool timedOut;
  final int responseTimeMs;
  final double masteryBefore;
  final double masteryAfter;
  final MisconceptionEvidence? misconceptionEvidence;

  static void _validateMastery(double value, String name) {
    if (!value.isFinite || value < 0 || value > 100) {
      throw ArgumentError.value(
          value, name, 'must be a finite value from 0 to 100');
    }
  }
}
