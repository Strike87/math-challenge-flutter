import 'scenario_definition.dart';

final class ScenarioKnowledgeLibrary {
  ScenarioKnowledgeLibrary(List<GovernedScenarioDefinition> entries)
      : entries = List.unmodifiable(entries) {
    final ids = this.entries.map((entry) => entry.definition.id).toSet();
    if (ids.length != this.entries.length) {
      throw ArgumentError('Scenario IDs must be unique.');
    }
  }

  final List<GovernedScenarioDefinition> entries;

  List<ScenarioDefinition> get acceptedDefinitions => List.unmodifiable(
        entries
            .where((entry) =>
                entry.acceptanceState == ScenarioAcceptanceState.accepted)
            .map((entry) => entry.definition),
      );

  ScenarioDefinition? acceptedById(String id) {
    for (final entry in entries) {
      if (entry.definition.id == id &&
          entry.acceptanceState == ScenarioAcceptanceState.accepted) {
        return entry.definition;
      }
    }
    return null;
  }
}
