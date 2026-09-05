enum ScenarioAcceptanceState { proposed, accepted, rejected }

enum ScenarioKnowledgeAuthority { none }

final class ScenarioDefinition {
  ScenarioDefinition({
    required this.id,
    required this.version,
    required this.name,
    required this.questionBeingTested,
    required List<String> requiredObservations,
    required List<String> comparableConditions,
    required List<String> supportingEvidence,
    required List<String> contradictingEvidence,
    required List<String> alternativeExplanations,
    required List<String> missingEvidence,
    required List<String> epistemicRequirements,
    required List<String> attributionLimitations,
  })  : requiredObservations = List.unmodifiable(requiredObservations),
        comparableConditions = List.unmodifiable(comparableConditions),
        supportingEvidence = List.unmodifiable(supportingEvidence),
        contradictingEvidence = List.unmodifiable(contradictingEvidence),
        alternativeExplanations = List.unmodifiable(alternativeExplanations),
        missingEvidence = List.unmodifiable(missingEvidence),
        epistemicRequirements = List.unmodifiable(epistemicRequirements),
        attributionLimitations = List.unmodifiable(attributionLimitations) {
    if (id.trim().isEmpty)
      throw ArgumentError.value(id, 'id', 'must not be blank');
    if (version < 1)
      throw ArgumentError.value(version, 'version', 'must be at least 1');
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    if (questionBeingTested.trim().isEmpty) {
      throw ArgumentError.value(
        questionBeingTested,
        'questionBeingTested',
        'must not be blank',
      );
    }
  }

  final String id;
  final int version;
  final String name;
  final String questionBeingTested;
  final List<String> requiredObservations;
  final List<String> comparableConditions;
  final List<String> supportingEvidence;
  final List<String> contradictingEvidence;
  final List<String> alternativeExplanations;
  final List<String> missingEvidence;
  final List<String> epistemicRequirements;
  final List<String> attributionLimitations;
}

final class GovernedScenarioDefinition {
  const GovernedScenarioDefinition({
    required this.definition,
    required this.acceptanceState,
  });

  final ScenarioDefinition definition;
  final ScenarioAcceptanceState acceptanceState;

  ScenarioKnowledgeAuthority get authority => ScenarioKnowledgeAuthority.none;
  bool get mayAffectGameplay => false;
}
