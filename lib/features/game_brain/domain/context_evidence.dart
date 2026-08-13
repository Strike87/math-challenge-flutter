import '../../../models/enums.dart';

enum ContextRepresentation { directNumeric }

enum ContextEvidenceStatus { insufficientEvidence }

enum ContextEvidenceReason { insufficientExposure, unsupportedContext }

/// A deterministic mathematical context, not a learner classification.
final class ContextEvidenceKey {
  ContextEvidenceKey({
    required this.operation,
    required this.numberType,
    this.representation = ContextRepresentation.directNumeric,
  }) {
    if (!supportsOperation(operation)) {
      throw ArgumentError.value(
        operation,
        'operation',
        'must be a basic operation',
      );
    }
  }

  final Operation operation;
  final NumberType numberType;
  final ContextRepresentation representation;

  static bool supportsOperation(Operation operation) => switch (operation) {
        Operation.addition ||
        Operation.subtraction ||
        Operation.multiplication ||
        Operation.division =>
          true,
        _ => false,
      };

  @override
  bool operator ==(Object other) =>
      other is ContextEvidenceKey &&
      operation == other.operation &&
      numberType == other.numberType &&
      representation == other.representation;

  @override
  int get hashCode => Object.hash(operation, numberType, representation);
}

/// Immutable observables from one already-authoritatively-scored question.
final class ContextEvidenceObservation {
  ContextEvidenceObservation({
    required this.context,
    required this.difficulty,
    required this.correctAnswer,
    required this.submittedAnswer,
    required this.correct,
    required this.timedOut,
    required this.responseTimeMs,
  }) {
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
  }

  final ContextEvidenceKey? context;
  final Difficulty difficulty;
  final num correctAnswer;
  final num? submittedAnswer;
  final bool correct;
  final bool timedOut;
  final int responseTimeMs;
}

/// Internal shadow-only exposure result. It contains no learner claim.
final class ContextEvidenceResult {
  const ContextEvidenceResult._({
    required this.reasonCode,
    required this.context,
    required this.exposureCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.timeoutCount,
  });

  const ContextEvidenceResult.unsupported()
      : this._(
          reasonCode: ContextEvidenceReason.unsupportedContext,
          context: null,
          exposureCount: 0,
          correctCount: 0,
          incorrectCount: 0,
          timeoutCount: 0,
        );

  const ContextEvidenceResult.insufficientExposure({
    required ContextEvidenceKey context,
    required int exposureCount,
    required int correctCount,
    required int incorrectCount,
    required int timeoutCount,
  }) : this._(
          reasonCode: ContextEvidenceReason.insufficientExposure,
          context: context,
          exposureCount: exposureCount,
          correctCount: correctCount,
          incorrectCount: incorrectCount,
          timeoutCount: timeoutCount,
        );

  ContextEvidenceStatus get status =>
      ContextEvidenceStatus.insufficientEvidence;

  final ContextEvidenceReason reasonCode;
  final ContextEvidenceKey? context;
  final int exposureCount;
  final int correctCount;
  final int incorrectCount;
  final int timeoutCount;

  String get explanation {
    final observedContext = context;
    if (observedContext == null) {
      return 'Unsupported context: 0 observations were recorded.';
    }
    return '${observedContext.operation.name}/'
        '${observedContext.numberType.name}/'
        '${observedContext.representation.name}: '
        '$exposureCount observations, $correctCount correct, '
        '$incorrectCount incorrect, $timeoutCount timed out; '
        'insufficient exposure.';
  }
}
