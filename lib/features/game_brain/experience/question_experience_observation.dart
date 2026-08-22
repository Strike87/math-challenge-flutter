import '../../../models/enums.dart';

/// Immutable facts about the canonical context that was presented.
final class QuestionPresentedSnapshot {
  const QuestionPresentedSnapshot({
    required this.operation,
    required this.numberType,
    required this.difficulty,
    required this.answerStyle,
  });

  final Operation operation;
  final NumberType numberType;
  final Difficulty difficulty;
  final AnswerStyle answerStyle;

  @override
  bool operator ==(Object other) =>
      other is QuestionPresentedSnapshot &&
      operation == other.operation &&
      numberType == other.numberType &&
      difficulty == other.difficulty &&
      answerStyle == other.answerStyle;

  @override
  int get hashCode =>
      Object.hash(operation, numberType, difficulty, answerStyle);
}

/// One mutually exclusive way an already-presented question ended.
sealed class QuestionTerminalObservation {
  const QuestionTerminalObservation();

  @override
  bool operator ==(Object other) =>
      runtimeType == other.runtimeType && other is QuestionTerminalObservation;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AnsweredCorrect extends QuestionTerminalObservation {
  const AnsweredCorrect();
}

final class AnsweredIncorrect extends QuestionTerminalObservation {
  const AnsweredIncorrect();
}

final class QuestionTimedOut extends QuestionTerminalObservation {
  const QuestionTimedOut();
}

final class QuestionSkipped extends QuestionTerminalObservation {
  const QuestionSkipped();
}

final class QuestionReplaced extends QuestionTerminalObservation {
  const QuestionReplaced();
}

final class QuestionAbandoned extends QuestionTerminalObservation {
  const QuestionAbandoned();
}

/// Immutable facts about one already-completed question experience.
final class QuestionExperienceObservation {
  const QuestionExperienceObservation({
    required this.presented,
    required this.terminal,
  });

  final QuestionPresentedSnapshot presented;
  final QuestionTerminalObservation terminal;

  @override
  bool operator ==(Object other) =>
      other is QuestionExperienceObservation &&
      presented == other.presented &&
      terminal == other.terminal;

  @override
  int get hashCode => Object.hash(presented, terminal);
}
