import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';

void main() {
  test('empty library is legal', () {
    final library = ScenarioKnowledgeLibrary(const []);

    expect(library.entries, isEmpty);
    expect(library.acceptedDefinitions, isEmpty);
  });

  test('preserves entry order and makes entries immutable', () {
    final source = [_entry('first'), _entry('second')];
    final library = ScenarioKnowledgeLibrary(source);
    source.clear();

    expect(library.entries.map((entry) => entry.definition.id), [
      'first',
      'second',
    ]);
    expect(() => library.entries.clear(), throwsUnsupportedError);
  });

  test('duplicate IDs fail closed', () {
    expect(
      () => ScenarioKnowledgeLibrary([_entry('same'), _entry('same')]),
      throwsArgumentError,
    );
  });

  test('accepted definitions include accepted entries only in source order',
      () {
    final acceptedFirst =
        _entry('accepted-first', ScenarioAcceptanceState.accepted);
    final proposed = _entry('proposed', ScenarioAcceptanceState.proposed);
    final rejected = _entry('rejected', ScenarioAcceptanceState.rejected);
    final acceptedLast =
        _entry('accepted-last', ScenarioAcceptanceState.accepted);
    final library = ScenarioKnowledgeLibrary([
      acceptedFirst,
      proposed,
      rejected,
      acceptedLast,
    ]);

    expect(library.acceptedDefinitions, [
      acceptedFirst.definition,
      acceptedLast.definition,
    ]);
    expect(() => library.acceptedDefinitions.clear(), throwsUnsupportedError);
    expect(library.acceptedById('accepted-first'), acceptedFirst.definition);
    expect(library.acceptedById('proposed'), isNull);
    expect(library.acceptedById('rejected'), isNull);
    expect(library.acceptedById('Accepted-first'), isNull);
    expect(library.acceptedById('missing'), isNull);
  });

  test('governed definitions are authority-free without ranking semantics', () {
    final entry = _entry('only');

    expect(entry.authority, ScenarioKnowledgeAuthority.none);
    expect(entry.mayAffectGameplay, isFalse);
    expect(ScenarioKnowledgeLibrary([entry]).entries, hasLength(1));
  });
}

GovernedScenarioDefinition _entry(
  String id, [
  ScenarioAcceptanceState acceptanceState = ScenarioAcceptanceState.proposed,
]) =>
    GovernedScenarioDefinition(
      definition: ScenarioDefinition(
        id: id,
        version: 1,
        name: id,
        questionBeingTested: 'Question',
        requiredObservations: const [],
        comparableConditions: const [],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        alternativeExplanations: const [],
        missingEvidence: const [],
        epistemicRequirements: const [],
        attributionLimitations: const [],
      ),
      acceptanceState: acceptanceState,
    );
