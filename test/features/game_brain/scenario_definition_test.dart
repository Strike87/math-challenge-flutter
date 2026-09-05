import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';

void main() {
  test('valid definition retains exact values', () {
    final definition = _definition();

    expect(definition.id, ' scenario-id ');
    expect(definition.version, 1);
    expect(definition.name, ' Scenario name ');
    expect(definition.questionBeingTested, ' Question? ');
    expect(definition.requiredObservations, ['observation']);
  });

  test('list fields are immutable defensive copies', () {
    final source = <String>['value'];
    final definition = _definition(
      requiredObservations: source,
      comparableConditions: source,
      supportingEvidence: source,
      contradictingEvidence: source,
      alternativeExplanations: source,
      missingEvidence: source,
      epistemicRequirements: source,
      attributionLimitations: source,
    );
    source.clear();

    for (final values in [
      definition.requiredObservations,
      definition.comparableConditions,
      definition.supportingEvidence,
      definition.contradictingEvidence,
      definition.alternativeExplanations,
      definition.missingEvidence,
      definition.epistemicRequirements,
      definition.attributionLimitations,
    ]) {
      expect(values, ['value']);
      expect(() => values.clear(), throwsUnsupportedError);
    }
  });

  test('blank required strings and invalid version throw ArgumentError', () {
    expect(() => _definition(id: '  '), throwsArgumentError);
    expect(() => _definition(version: 0), throwsArgumentError);
    expect(() => _definition(name: '  '), throwsArgumentError);
    expect(
      () => _definition(questionBeingTested: '  '),
      throwsArgumentError,
    );
  });
}

ScenarioDefinition _definition({
  String id = ' scenario-id ',
  int version = 1,
  String name = ' Scenario name ',
  String questionBeingTested = ' Question? ',
  List<String>? requiredObservations,
  List<String>? comparableConditions,
  List<String>? supportingEvidence,
  List<String>? contradictingEvidence,
  List<String>? alternativeExplanations,
  List<String>? missingEvidence,
  List<String>? epistemicRequirements,
  List<String>? attributionLimitations,
}) =>
    ScenarioDefinition(
      id: id,
      version: version,
      name: name,
      questionBeingTested: questionBeingTested,
      requiredObservations: requiredObservations ?? ['observation'],
      comparableConditions: comparableConditions ?? ['condition'],
      supportingEvidence: supportingEvidence ?? ['support'],
      contradictingEvidence: contradictingEvidence ?? ['contradiction'],
      alternativeExplanations: alternativeExplanations ?? ['alternative'],
      missingEvidence: missingEvidence ?? ['missing'],
      epistemicRequirements: epistemicRequirements ?? ['requirement'],
      attributionLimitations: attributionLimitations ?? ['limitation'],
    );
