import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';

void main() {
  const expectedIds = [
    'StableAtCurrentDifficulty',
    'ProductiveChallengeCandidate',
    'OverchallengeCandidate',
    'UnderchallengeCandidate',
    'SparseHigherDifficultyEvidence',
    'RecentImprovementCandidate',
    'RecentDeclineCandidate',
    'RecoveryCandidate',
    'TimeoutConcentrationAtDifficulty',
    'AssistanceConditionedDifficulty',
  ];

  final entries = phase1DifficultyScenarioLibrary.entries;

  test('freezes the ten canonical identities in reference order', () {
    expect(entries, hasLength(10));
    expect(entries.map((entry) => entry.definition.id), expectedIds);
    expect(entries.map((entry) => entry.definition.name), expectedIds);
    expect(entries.map((entry) => entry.definition.id).toSet(), hasLength(10));
  });

  test('keeps definitions proposed, versioned, and question-only', () {
    for (final entry in entries) {
      final definition = entry.definition;
      expect(definition.version, 1);
      expect(entry.acceptanceState, ScenarioAcceptanceState.proposed);
      expect(
        definition.questionBeingTested,
        'Is bounded evidence consistent with ${definition.name}?',
      );
      expect(definition.requiredObservations, isEmpty);
      expect(definition.comparableConditions, isEmpty);
      expect(definition.supportingEvidence, isEmpty);
      expect(definition.contradictingEvidence, isEmpty);
      expect(definition.alternativeExplanations, isEmpty);
      expect(definition.missingEvidence, isEmpty);
      expect(definition.epistemicRequirements, isEmpty);
      expect(definition.attributionLimitations, isEmpty);
    }
  });

  test('exposes no accepted or gameplay-authoritative scenario', () {
    expect(phase1DifficultyScenarioLibrary.acceptedDefinitions, isEmpty);
    for (final id in expectedIds) {
      expect(phase1DifficultyScenarioLibrary.acceptedById(id), isNull);
      expect(phase1DifficultyScenarioLibrary.acceptedById(id.toLowerCase()),
          isNull);
    }
    for (final entry in entries) {
      expect(entry.authority, ScenarioKnowledgeAuthority.none);
      expect(entry.mayAffectGameplay, isFalse);
    }
  });

  test('keeps the preloaded entry list immutable', () {
    expect(() => entries.clear(), throwsUnsupportedError);
  });

  test('catalog source introduces no ranking, precedence, or action semantics',
      () {
    final source = File(
      'lib/features/game_brain/scenario/phase1_difficulty_scenarios.dart',
    ).readAsStringSync();

    for (final forbiddenTerm in [
      'rank',
      'priority',
      'precedence',
      'recommend',
      'policy',
      'action',
      'match',
      'evaluate',
      'score',
    ]) {
      expect(source.toLowerCase(), isNot(contains(forbiddenTerm)));
    }
  });
}
