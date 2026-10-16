import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';

/// Explicit R3-17 capability. It is intentionally opt-in because 36,000 full
/// preparations are not a focused-test budget. Remove `skip` only in the
/// dedicated stress-validation checkpoint.
void main() {
  test('R3 36 configurations x 1000 deterministic selection seeds', () {
    const operations = [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ];
    const difficulties = [Difficulty.easy, Difficulty.medium, Difficulty.hard];
    const types = [
      NumberType.natural,
      NumberType.integers,
      NumberType.rationals,
    ];
    final reachedOverrides = <TargetClashProfileOverrideKey>{};
    var configurationSeedEvaluations = 0;
    var profilePreparations = 0;

    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final type in types) {
          for (var seed = 0; seed < 1000; seed++) {
            configurationSeedEvaluations++;
            final context = '$operation/$difficulty/$type seed=$seed';
            final planner = TargetClashQuestionGenerator(
              questionGenerator: QuestionGenerator(rng: Random(7000 + seed)),
              selectionRandom: Random(seed),
            );
            final stage1Requests = _resolveRequests(
              operation,
              difficulty,
              type,
              TargetClashRequestProfilePhase.ordinaryStage1,
              reachedOverrides,
            );
            final stage1 = _expectPrepared(
              planner.prepareStage(
                operation: operation,
                difficulty: difficulty,
                numberType: type,
                requests: stage1Requests,
              ),
              operation: operation,
              difficulty: difficulty,
              numberType: type,
              requests: stage1Requests,
              context: '$context stage1',
            );
            profilePreparations++;

            final stage2Requests = _resolveRequests(
              operation,
              difficulty,
              type,
              TargetClashRequestProfilePhase.ordinaryStage2,
              reachedOverrides,
            );
            final tripleRequests = TargetClashRuntimeState.tripleRequests(0)!;
            final stage2 = _expectPrepared(
              planner.prepareStage(
                operation: operation,
                difficulty: difficulty,
                numberType: type,
                requests: stage2Requests,
                futureRequests:
                    difficulty == Difficulty.easy ? const [] : tripleRequests,
              ),
              operation: operation,
              difficulty: difficulty,
              numberType: type,
              requests: stage2Requests,
              context: '$context stage2',
            );
            profilePreparations++;

            if (difficulty != Difficulty.easy) {
              _expectPrepared(
                planner.prepareStageForTarget(
                  operation: operation,
                  difficulty: difficulty,
                  numberType: type,
                  targetValue: stage2.targetValue,
                  requests: tripleRequests,
                ),
                operation: operation,
                difficulty: difficulty,
                numberType: type,
                requests: tripleRequests,
                expectedTarget: stage2.targetValue,
                context: '$context triple retainedStage2Target',
              );
              profilePreparations++;
            }

            for (final phase in [
              TargetClashRequestProfilePhase.boss,
              TargetClashRequestProfilePhase.finalTarget,
            ]) {
              final requests = _resolveRequests(
                operation,
                difficulty,
                type,
                phase,
                reachedOverrides,
              );
              _expectPrepared(
                planner.prepareStage(
                  operation: operation,
                  difficulty: difficulty,
                  numberType: type,
                  requests: requests,
                ),
                operation: operation,
                difficulty: difficulty,
                numberType: type,
                requests: requests,
                context: '$context $phase',
              );
              profilePreparations++;
            }

            // Deterministic replay capability: the same pair of seeds
            // reproduces Stage 1 through the same target-first path.
            final replay = _expectPrepared(
              TargetClashQuestionGenerator(
                questionGenerator: QuestionGenerator(rng: Random(7000 + seed)),
                selectionRandom: Random(seed),
              ).prepareStage(
                operation: operation,
                difficulty: difficulty,
                numberType: type,
                requests: stage1Requests,
              ),
              operation: operation,
              difficulty: difficulty,
              numberType: type,
              requests: stage1Requests,
              context: '$context replay',
            );
            profilePreparations++;
            expect(
              replay.targetValue,
              stage1.targetValue,
              reason: '$context replay',
            );
          }
        }
      }
    }

    expect(operations.length * difficulties.length * types.length, 36);
    expect(configurationSeedEvaluations, 36000);
    expect(reachedOverrides, TargetClashRuntimeState.profileOverrides.keys.toSet());
    expect(reachedOverrides, hasLength(8));
    expect(profilePreparations, 204000);
  }, skip: 'Run only in the explicit R3 stress-validation checkpoint.');
}

List<TargetClashQuestionRequest> _resolveRequests(
  Operation operation,
  Difficulty difficulty,
  NumberType numberType,
  TargetClashRequestProfilePhase phase,
  Set<TargetClashProfileOverrideKey> reachedOverrides,
) {
  final key = TargetClashProfileOverrideKey(
    operation: operation,
    difficulty: difficulty,
    numberType: numberType,
    phase: phase,
  );
  if (TargetClashRuntimeState.profileOverrides.containsKey(key)) {
    reachedOverrides.add(key);
  }
  return TargetClashRuntimeState.resolveRequests(
    operation: operation,
    difficulty: difficulty,
    numberType: numberType,
    phase: phase,
  );
}

TargetClashStage _expectPrepared(
  TargetClashStageResult result, {
  required Operation operation,
  required Difficulty difficulty,
  required NumberType numberType,
  required List<TargetClashQuestionRequest> requests,
  required String context,
  num? expectedTarget,
}) {
  expect(
    result.failure,
    isNull,
    reason: '$context generationFailure=${result.failure}',
  );
  final stage = result.stage;
  expect(stage, isNotNull, reason: '$context stage was null');
  final prepared = stage!;
  expect(
    prepared.questions,
    hasLength(requests.length),
    reason: '$context partial stage',
  );
  if (expectedTarget != null) {
    expect(prepared.targetValue, expectedTarget, reason: '$context retained target');
  }
  for (var index = 0; index < requests.length; index++) {
    final request = requests[index];
    final question = prepared.questions[index];
    final expression = question.expression;
    final questionContext = '$context request=$index '
        'target=${prepared.targetValue} relation=${request.answer} '
        'zone=${request.zone} value=${question.expressionValue}';
    expect(question.targetValue, prepared.targetValue, reason: questionContext);
    expect(
      PresentationAnswer.classify(question.expressionValue, prepared.targetValue),
      request.answer,
      reason: questionContext,
    );
    expect(question.zone, request.zone, reason: questionContext);
    expect(
      TargetClashQuestion.tryCreate(
        expression: expression,
        targetValue: prepared.targetValue,
      )?.zone,
      request.zone,
      reason: questionContext,
    );
    expect(expression.isMathematicallyValid, isTrue, reason: questionContext);
    expect(
      expression.representation,
      FactRepresentation.direct,
      reason: questionContext,
    );
    expect(expression.operation, operation, reason: questionContext);
    expect(expression.difficulty, difficulty, reason: questionContext);
    expect(expression.numberType, numberType, reason: questionContext);
  }
  return prepared;
}
