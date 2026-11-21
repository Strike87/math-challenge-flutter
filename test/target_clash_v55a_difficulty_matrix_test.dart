import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';

/// V5.5-A: read-only baseline of every currently supported Target Clash setup.
///
/// No scoring, RNG, difficulty, gameplay or GameBrain implementation is changed.
/// The six Triple request permutations are deterministic; one representative
/// permutation is used here, while existing tests cover their mapping.
void main() {
  test('all 36 supported configurations prepare canonical phase profiles', () {
    const operations = [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ];
    const difficulties = [
      Difficulty.easy,
      Difficulty.medium,
      Difficulty.hard,
    ];
    const numberTypes = [
      NumberType.natural,
      NumberType.integers,
      NumberType.rationals,
    ];
    final failures = <String>[];
    final rows = <Map<String, Object?>>[];
    var combinations = 0;
    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          combinations++;
          final key = '${operation.name}/${difficulty.name}/${numberType.name}';
          final config = TargetClashRunConfig.tryCreate(
            operation: operation,
            difficulty: difficulty,
            numberType: numberType,
          );
          expect(config, isNotNull, reason: key);
          final generator = TargetClashQuestionGenerator(
            questionGenerator: QuestionGenerator(rng: Random(5500 + combinations)),
            selectionRandom: Random(6500 + combinations),
          );
          final profiles = <String, List<TargetClashQuestionRequest>>{
            'ordinaryStage1': TargetClashRuntimeState.resolveRequests(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              phase: TargetClashRequestProfilePhase.ordinaryStage1,
            ),
            'ordinaryStage2': TargetClashRuntimeState.resolveRequests(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              phase: TargetClashRequestProfilePhase.ordinaryStage2,
            ),
            'boss': TargetClashRuntimeState.resolveRequests(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              phase: TargetClashRequestProfilePhase.boss,
            ),
            'finalTarget': TargetClashRuntimeState.resolveRequests(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              phase: TargetClashRequestProfilePhase.finalTarget,
            ),
          };
          final futureTriple = difficulty == Difficulty.easy
              ? <TargetClashQuestionRequest>[]
              : TargetClashRuntimeState.tripleRequests(0)!;
          num? retainedTarget;
          final stages = <String, int>{};
          final zones = <String, int>{};
          for (final entry in profiles.entries) {
            final result = generator.prepareStage(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              requests: entry.value,
              futureRequests: entry.key == 'ordinaryStage2'
                  ? futureTriple
                  : const [],
            );
            final stage = result.stage;
            if (stage == null) {
              failures.add('$key/${entry.key}: ${result.failure}');
              continue;
            }
            if (entry.key == 'ordinaryStage2') retainedTarget = stage.targetValue;
            stages[entry.key] = stage.questions.length;
            if (stage.questions.length != entry.value.length) {
              failures.add('$key/${entry.key}: incorrect question count');
            }
            for (var i = 0; i < stage.questions.length; i++) {
              final question = stage.questions[i];
              if (question.targetValue != stage.targetValue ||
                  question.correctAnswer != entry.value[i].answer ||
                  question.zone != entry.value[i].zone ||
                  !question.expression.isMathematicallyValid) {
                failures.add('$key/${entry.key}/question-${i + 1}: invalid canonical fact or request');
              }
              zones.update(question.zone.name, (n) => n + 1,
                  ifAbsent: () => 1);
            }
          }
          if (difficulty != Difficulty.easy && retainedTarget != null) {
            final triple = generator.prepareStageForTarget(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              targetValue: retainedTarget,
              requests: futureTriple,
            );
            if (triple.stage == null) {
              failures.add('$key/triple: ${triple.failure}');
            } else {
              stages['triple'] = triple.stage!.questions.length;
              if (triple.stage!.targetValue != retainedTarget) {
                failures.add('$key/triple: target was not retained');
              }
            }
          }
          final expected = config!.questionTarget;
          final planned = stages.values.fold<int>(0, (a, b) => a + b);
          if (stages.length == (difficulty == Difficulty.easy ? 4 : 5) &&
              planned != expected) {
            failures.add('$key: planned=$planned expected=$expected');
          }
          rows.add({
            'configuration': key,
            'expectedQuestions': expected,
            'preparedQuestions': planned,
            'stages': stages,
            'zones': zones,
          });
        }
      }
    }
    expect(combinations, 36);
    // Machine-readable observations are available in the CI test log.
    final matrixJson = jsonEncode({
      'schema': 1,
      'configurations': combinations,
      'failures': failures,
      'rows': rows,
    });
    stdout.writeln('TARGET_CLASH_V55A_MATRIX=$matrixJson');
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 8)));

  test('unsupported Expert/Insane stay outside Target Clash', () {
    for (final difficulty in [Difficulty.expert, Difficulty.insane]) {
      expect(
        TargetClashRunConfig.tryCreate(
          operation: Operation.addition,
          difficulty: difficulty,
          numberType: NumberType.natural,
        ),
        isNull,
      );
    }
  });

  test('the approved exact-match profile overrides stay unchanged', () {
    // This is a baseline guard for the immutable correction table.
    final overrides = TargetClashRuntimeState.profileOverrides;
    expect(overrides, hasLength(8));
    expect(
      overrides.keys.every((key) =>
          [Difficulty.easy, Difficulty.medium, Difficulty.hard]
              .contains(key.difficulty)),
      isTrue,
    );
  });
}
