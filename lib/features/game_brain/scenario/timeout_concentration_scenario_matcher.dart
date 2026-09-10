import 'scenario_definition.dart';
import 'scenario_knowledge_library.dart';
import 'timeout_concentration_evaluator.dart';

enum TimeoutConcentrationScenarioMatchState {
  notEvaluable,
  matched,
  notMatched,
  contradicted,
}

enum TimeoutConcentrationScenarioMatchNotEvaluableReason {
  scenarioNotAccepted,
  scenarioVersionMismatch,
  evaluationNotEvaluable,
}

enum TimeoutConcentrationScenarioMatchAuthority { none }

final class TimeoutConcentrationScenarioMatch {
  const TimeoutConcentrationScenarioMatch({
    required this.state,
    required this.notEvaluableReason,
    required this.definition,
    required this.evaluation,
  });

  final TimeoutConcentrationScenarioMatchState state;
  final TimeoutConcentrationScenarioMatchNotEvaluableReason? notEvaluableReason;
  final ScenarioDefinition? definition;
  final TimeoutConcentrationEvaluation evaluation;

  TimeoutConcentrationScenarioMatchAuthority get authority =>
      TimeoutConcentrationScenarioMatchAuthority.none;

  bool get mayAffectGameplay => false;
}

final class TimeoutConcentrationScenarioMatcher {
  const TimeoutConcentrationScenarioMatcher();

  TimeoutConcentrationScenarioMatch match({
    required ScenarioKnowledgeLibrary scenarioLibrary,
    required TimeoutConcentrationEvaluation evaluation,
  }) {
    final definition = scenarioLibrary.acceptedById(
      'TimeoutConcentrationAtDifficulty',
    );
    if (definition == null) {
      return _notEvaluable(
        TimeoutConcentrationScenarioMatchNotEvaluableReason.scenarioNotAccepted,
        null,
        evaluation,
      );
    }
    if (definition.version != 1) {
      return _notEvaluable(
        TimeoutConcentrationScenarioMatchNotEvaluableReason
            .scenarioVersionMismatch,
        definition,
        evaluation,
      );
    }
    switch (evaluation.state) {
      case TimeoutConcentrationEvaluationState.descriptivelyCompatible:
        return TimeoutConcentrationScenarioMatch(
          state: TimeoutConcentrationScenarioMatchState.matched,
          notEvaluableReason: null,
          definition: definition,
          evaluation: evaluation,
        );
      case TimeoutConcentrationEvaluationState.noDirectionalConcentration:
        return TimeoutConcentrationScenarioMatch(
          state: TimeoutConcentrationScenarioMatchState.notMatched,
          notEvaluableReason: null,
          definition: definition,
          evaluation: evaluation,
        );
      case TimeoutConcentrationEvaluationState.descriptivelyIncompatible:
        return TimeoutConcentrationScenarioMatch(
          state: TimeoutConcentrationScenarioMatchState.contradicted,
          notEvaluableReason: null,
          definition: definition,
          evaluation: evaluation,
        );
      case TimeoutConcentrationEvaluationState.notEvaluable:
        return _notEvaluable(
          TimeoutConcentrationScenarioMatchNotEvaluableReason
              .evaluationNotEvaluable,
          definition,
          evaluation,
        );
    }
  }

  TimeoutConcentrationScenarioMatch _notEvaluable(
    TimeoutConcentrationScenarioMatchNotEvaluableReason reason,
    ScenarioDefinition? definition,
    TimeoutConcentrationEvaluation evaluation,
  ) =>
      TimeoutConcentrationScenarioMatch(
        state: TimeoutConcentrationScenarioMatchState.notEvaluable,
        notEvaluableReason: reason,
        definition: definition,
        evaluation: evaluation,
      );
}
