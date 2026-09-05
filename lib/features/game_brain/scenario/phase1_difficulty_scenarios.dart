import 'scenario_definition.dart';
import 'scenario_knowledge_library.dart';

final ScenarioKnowledgeLibrary phase1DifficultyScenarioLibrary =
    ScenarioKnowledgeLibrary([
  _proposed('StableAtCurrentDifficulty'),
  _proposed('ProductiveChallengeCandidate'),
  _proposed('OverchallengeCandidate'),
  _proposed('UnderchallengeCandidate'),
  _proposed('SparseHigherDifficultyEvidence'),
  _proposed('RecentImprovementCandidate'),
  _proposed('RecentDeclineCandidate'),
  _proposed('RecoveryCandidate'),
  _proposed('TimeoutConcentrationAtDifficulty'),
  _proposed('AssistanceConditionedDifficulty'),
]);

GovernedScenarioDefinition _proposed(String id) => GovernedScenarioDefinition(
      definition: ScenarioDefinition(
        id: id,
        version: 1,
        name: id,
        questionBeingTested: 'Is bounded evidence consistent with $id?',
        requiredObservations: const [],
        comparableConditions: const [],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        alternativeExplanations: const [],
        missingEvidence: const [],
        epistemicRequirements: const [],
        attributionLimitations: const [],
      ),
      acceptanceState: ScenarioAcceptanceState.proposed,
    );
