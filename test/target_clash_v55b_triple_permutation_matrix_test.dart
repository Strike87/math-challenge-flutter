import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';

/// V5.5-B: 24 supported Triple configurations x 6 canonical permutations.
///
/// Domain materialization only. DOES_NOT_PROVE_REAL_GAMESTATE_RNG_SEQUENCE_EQUIVALENCE.
/// Each permutation uses a fresh seeded generator, not production's shared
/// GameState._qgen / _rng timeline. Failures are UNKNOWN_CAUSE / TEST_FINDING
/// until deterministically reproduced; never retry with replacement targets.
void main() {
  test('144 deterministic Triple permutation domain materializations', () {
    const operations = [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ];
    const difficulties = [Difficulty.medium, Difficulty.hard];
    const numberTypes = [
      NumberType.natural,
      NumberType.integers,
      NumberType.rationals,
    ];
    final failures = <String>[];
    final observations = <Map<String, Object?>>[];
    final totalTimer = Stopwatch()..start();
    var configurationCount = 0;
    var materializationAttempts = 0;
    var successfulMaterializations = 0;

    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          final configIndex = ++configurationCount;
          final key = '${operation.name}/${difficulty.name}/${numberType.name}';
          final preflightQSeed = 5500 + configIndex;
          final preflightSelectionSeed = 6500 + configIndex;
          final stage2Requests = TargetClashRuntimeState.resolveRequests(
            operation: operation,
            difficulty: difficulty,
            numberType: numberType,
            phase: TargetClashRequestProfilePhase.ordinaryStage2,
          );
          final preflight = TargetClashQuestionGenerator(
            questionGenerator: QuestionGenerator(rng: Random(preflightQSeed)),
            selectionRandom: Random(preflightSelectionSeed),
          ).prepareStage(
            operation: operation,
            difficulty: difficulty,
            numberType: numberType,
            requests: stage2Requests,
            futureRequests: TargetClashRuntimeState.tripleRequests(0)!,
          );
          final preflightStage = preflight.stage;
          if (preflightStage == null) {
            failures.add(
              'UNKNOWN_CAUSE / TEST_FINDING $key index=$configIndex '
              'stage2 failure=${preflight.failure} '
              'qSeed=$preflightQSeed selectionSeed=$preflightSelectionSeed',
            );
            // The target must never be replaced or silently regenerated.
            continue;
          }
          final target = preflightStage.targetValue;
          if (preflightStage.questions.length != stage2Requests.length) {
            failures.add('$key stage2 unexpected question count '
                '${preflightStage.questions.length} target=$target');
          }

          for (var permutationIndex = 0;
              permutationIndex < 6;
              permutationIndex++) {
            materializationAttempts++;
            final qSeed = 7500 + (configIndex - 1) * 6 + permutationIndex;
            final selectionSeed =
                8500 + (configIndex - 1) * 6 + permutationIndex;
            final context = '$key configIndex=$configIndex '
                'permutation=$permutationIndex target=$target '
                'stage2QSeed=$preflightQSeed '
                'stage2SelectionSeed=$preflightSelectionSeed '
                'qSeed=$qSeed selectionSeed=$selectionSeed';
            final requests =
                TargetClashRuntimeState.tripleRequests(permutationIndex);
            if (requests == null || requests.length != 3) {
              failures.add('UNKNOWN_CAUSE / TEST_FINDING $context '
                  'invalid Triple requests: $requests');
              continue;
            }
            final watch = Stopwatch()..start();
            final result = TargetClashQuestionGenerator(
              questionGenerator: QuestionGenerator(rng: Random(qSeed)),
              selectionRandom: Random(selectionSeed),
            ).prepareStageForTarget(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              targetValue: target,
              requests: requests,
            );
            watch.stop();
            final stage = result.stage;
            observations.add({
              'configuration': key,
              'configIndex': configIndex,
              'permutationIndex': permutationIndex,
              'target': target,
              'stage2QSeed': preflightQSeed,
              'stage2SelectionSeed': preflightSelectionSeed,
              'qSeed': qSeed,
              'selectionSeed': selectionSeed,
              'elapsedMicroseconds': watch.elapsedMicroseconds,
              'failure': result.failure?.name,
            });
            if (stage == null) {
              failures.add('UNKNOWN_CAUSE / TEST_FINDING $context '
                  'materialization failure=${result.failure}');
              continue;
            }
            successfulMaterializations++;
            if (stage.targetValue != target || stage.questions.length != 3) {
              failures.add('$context stage target=${stage.targetValue} '
                  'questionCount=${stage.questions.length}');
            }
            for (var slot = 0; slot < stage.questions.length; slot++) {
              if (slot >= requests.length) {
                failures.add('$context unexpected extra slot=$slot');
                continue;
              }
              final question = stage.questions[slot];
              final request = requests[slot];
              final fact = question.expression;
              final relation = fact.result < target
                  ? PresentationAnswer.lessThan
                  : fact.result > target
                      ? PresentationAnswer.greaterThan
                      : PresentationAnswer.equalTo;
              final scale = numberType == NumberType.rationals
                  ? (difficulty == Difficulty.hard ? 100 : 10)
                  : 1;
              final distanceInTicks = (fact.result - target).abs() * scale;
              final tickDistance = distanceInTicks.round();
              final expectedZone = TargetZone.classifyDistance(tickDistance);
              final lawful = fact.isMathematicallyValid &&
                  fact.representation == FactRepresentation.direct &&
                  fact.operation == operation &&
                  fact.difficulty == difficulty &&
                  fact.numberType == numberType &&
                  question.expressionValue == fact.result &&
                  question.targetValue == target &&
                  question.correctAnswer == request.answer &&
                  question.zone == request.zone &&
                  relation == request.answer &&
                  expectedZone == request.zone &&
                  (distanceInTicks - tickDistance).abs() < 0.000001 &&
                  TargetClashQuestion.tryCreate(
                        expression: fact,
                        targetValue: target,
                      ) !=
                      null;
              if (!lawful) {
                failures.add('UNKNOWN_CAUSE / TEST_FINDING $context '
                    'slot=$slot fact=${fact.left} ${operation.name} '
                    '${fact.right}=${fact.result} '
                    'answer=${question.correctAnswer}/${request.answer} '
                    'zone=${question.zone}/${request.zone}');
              }
            }
          }
        }
      }
    }
    totalTimer.stop();
    stdout.writeln('TARGET_CLASH_V55B_TRIPLE_MATRIX=${jsonEncode({
      'schema': 1,
      'scope': 'DOMAIN_ONLY',
      'rngDisclaimer': 'DOES_NOT_PROVE_REAL_GAMESTATE_RNG_SEQUENCE_EQUIVALENCE',
      'configurations': configurationCount,
      'attemptedMaterializations': materializationAttempts,
      'successfulMaterializations': successfulMaterializations,
      'elapsedMilliseconds': totalTimer.elapsedMilliseconds,
      'failures': failures,
      'rows': observations,
    })}');
    expect(configurationCount, 24);
    expect(materializationAttempts, 144);
    expect(successfulMaterializations, 144);
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 8)));
}
