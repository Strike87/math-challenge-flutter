import '../../gameplay/domain/question_difficulty_legality.dart';

/// In-process canonical difficulty legality measurements for the active run.
final class RunLocalQuestionDifficultyMeasurementCollector {
  final List<QuestionDifficultyLegality?> _measurements = [];

  int get count => _measurements.length;

  List<QuestionDifficultyLegality?> get snapshot =>
      List.unmodifiable(_measurements);

  void add(QuestionDifficultyLegality? legality) {
    _measurements.add(legality);
  }

  void clear() => _measurements.clear();
}
