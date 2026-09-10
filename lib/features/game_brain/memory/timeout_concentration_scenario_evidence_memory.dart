import '../scenario/scenario_knowledge_library.dart';
import '../scenario/timeout_concentration_evaluator.dart';
import '../scenario/timeout_concentration_scenario_matcher.dart';

enum TimeoutConcentrationScenarioEvidenceMemoryAuthority { none }

final class TimeoutConcentrationScenarioEvidenceEntry {
  const TimeoutConcentrationScenarioEvidenceEntry._({
    required this.sequence,
    required this.match,
  });

  final int sequence;
  final TimeoutConcentrationScenarioMatch match;

  TimeoutConcentrationScenarioEvidenceMemoryAuthority get authority =>
      TimeoutConcentrationScenarioEvidenceMemoryAuthority.none;

  bool get mayAffectGameplay => false;
}

final class TimeoutConcentrationScenarioEvidenceMemory {
  TimeoutConcentrationScenarioEvidenceMemory({required this.capacity}) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
  }

  final int capacity;
  final List<TimeoutConcentrationScenarioEvidenceEntry> _entries = [];
  int _nextSequence = 1;

  List<TimeoutConcentrationScenarioEvidenceEntry> get entries =>
      List.unmodifiable(_entries);

  TimeoutConcentrationScenarioEvidenceEntry record({
    required ScenarioKnowledgeLibrary scenarioLibrary,
    required TimeoutConcentrationScenarioMatch match,
  }) {
    final accepted = scenarioLibrary.acceptedById(
      'TimeoutConcentrationAtDifficulty',
    );
    final evaluation = match.evaluation;
    final expectedEvaluationState = switch (match.state) {
      TimeoutConcentrationScenarioMatchState.matched =>
        TimeoutConcentrationEvaluationState.descriptivelyCompatible,
      TimeoutConcentrationScenarioMatchState.notMatched =>
        TimeoutConcentrationEvaluationState.noDirectionalConcentration,
      TimeoutConcentrationScenarioMatchState.contradicted =>
        TimeoutConcentrationEvaluationState.descriptivelyIncompatible,
      TimeoutConcentrationScenarioMatchState.notEvaluable => null,
    };
    if (accepted == null ||
        !identical(match.definition, accepted) ||
        accepted.version != 1 ||
        expectedEvaluationState == null ||
        evaluation.state != expectedEvaluationState ||
        match.notEvaluableReason != null ||
        evaluation.notEvaluableReason != null ||
        evaluation.context == null ||
        evaluation.observedTimeoutRateDifference == null ||
        !evaluation.observedTimeoutRateDifference!.isFinite) {
      throw ArgumentError('Match is not recordable.');
    }

    final entry = TimeoutConcentrationScenarioEvidenceEntry._(
      sequence: _nextSequence,
      match: match,
    );
    if (_entries.length == capacity) _entries.removeAt(0);
    _entries.add(entry);
    _nextSequence++;
    return entry;
  }

  TimeoutConcentrationScenarioEvidenceMemoryAuthority get authority =>
      TimeoutConcentrationScenarioEvidenceMemoryAuthority.none;

  bool get mayAffectGameplay => false;
}
