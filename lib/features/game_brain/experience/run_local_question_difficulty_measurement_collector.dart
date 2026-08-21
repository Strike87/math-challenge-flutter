import '../../gameplay/domain/question_difficulty_legality.dart';
import 'question_experience_observation.dart';

/// In-process canonical difficulty legality measurements for the active run.
final class RunLocalQuestionDifficultyMeasurementCollector {
  final List<QuestionDifficultyMeasurementOpportunity> _opportunities = [];

  int get count => _opportunities.length;

  List<QuestionDifficultyLegality?> get snapshot => List.unmodifiable(
        _opportunities.map((opportunity) => opportunity.legality),
      );

  List<QuestionDifficultyMeasurementOpportunity> get opportunities =>
      List.unmodifiable(_opportunities);

  void add(
    QuestionDifficultyLegality? legality,
    ({int runId, int questionId}) questionToken,
  ) {
    _opportunities.add(QuestionDifficultyMeasurementOpportunity(
      legality: legality,
      runId: questionToken.runId,
      questionId: questionToken.questionId,
      opportunityOrdinalWithinRun: _opportunities.length + 1,
    ));
  }

  bool link(
    ({int runId, int questionId}) questionToken,
    QuestionExperienceObservation observation,
  ) {
    final index = _opportunities.indexWhere(
      (opportunity) =>
          opportunity.runId == questionToken.runId &&
          opportunity.questionId == questionToken.questionId,
    );
    if (index < 0 || _opportunities[index].terminalObservation != null) {
      return false;
    }
    _opportunities[index] = _opportunities[index].withTerminalObservation(
      observation,
    );
    return true;
  }

  void clear() => _opportunities.clear();
}

/// One generated question's run-local difficulty measurement opportunity.
final class QuestionDifficultyMeasurementOpportunity {
  const QuestionDifficultyMeasurementOpportunity({
    required this.legality,
    required this.runId,
    required this.questionId,
    required this.opportunityOrdinalWithinRun,
    this.terminalObservation,
  });

  final QuestionDifficultyLegality? legality;
  final int runId;
  final int questionId;
  final int opportunityOrdinalWithinRun;
  final QuestionExperienceObservation? terminalObservation;

  QuestionDifficultyMeasurementOpportunity withTerminalObservation(
    QuestionExperienceObservation observation,
  ) =>
      QuestionDifficultyMeasurementOpportunity(
        legality: legality,
        runId: runId,
        questionId: questionId,
        opportunityOrdinalWithinRun: opportunityOrdinalWithinRun,
        terminalObservation: observation,
      );
}
