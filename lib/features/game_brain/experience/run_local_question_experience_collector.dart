import 'question_experience_observation.dart';

/// In-memory observations for the active run only.
final class RunLocalQuestionExperienceCollector {
  final List<QuestionExperienceObservation> _observations = [];

  int get count => _observations.length;

  List<QuestionExperienceObservation> get snapshot =>
      List.unmodifiable(_observations);

  void add(QuestionExperienceObservation observation) {
    _observations.add(observation);
  }

  void clear() => _observations.clear();
}
