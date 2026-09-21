import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';

void main() {
  test('supplied-target preparation never builds an anchor and is atomic', () {
    final source = _DirectOnlyGenerator();
    final generator = TargetClashQuestionGenerator(questionGenerator: source);
    final result = generator.prepareStageForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      targetValue: 10,
      requests: const [
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
        TargetClashQuestionRequest(
            answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
        TargetClashQuestionRequest(
            answer: PresentationAnswer.greaterThan, zone: TargetZone.danger),
      ],
    );
    expect(result.failure, isNull);
    expect(source.buildCalls, 0);
    expect(result.stage!.questions.map((q) => q.targetValue), [10, 10, 10]);
    expect(source.directResults, [6, 10, 11]);
  });

  test('single materialization and replacement preserve immutable stage', () {
    final generator =
        TargetClashQuestionGenerator(questionGenerator: _DirectOnlyGenerator());
    final stage = generator.prepareStageForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      targetValue: 10,
      requests: const [
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      ],
    ).stage!;
    final replacement = generator
        .materializeForTarget(
          operation: Operation.addition,
          difficulty: Difficulty.easy,
          numberType: NumberType.natural,
          targetValue: 10,
          request: const TargetClashQuestionRequest(
              answer: PresentationAnswer.greaterThan, zone: TargetZone.danger),
        )
        .question!;
    final replaced =
        stage.replacingQuestion(index: 0, replacement: replacement)!;
    expect(stage.questions.single.zone, TargetZone.normal);
    expect(replaced.questions.single.zone, TargetZone.danger);
    expect(stage.replacingQuestion(index: 1, replacement: replacement), isNull);
  });

  test('equality uses supplied result and hard rationals use canonical ticks',
      () {
    final source = _DirectOnlyGenerator();
    final generator = TargetClashQuestionGenerator(questionGenerator: source);
    expect(
      generator
          .materializeForTarget(
            operation: Operation.addition,
            difficulty: Difficulty.easy,
            numberType: NumberType.natural,
            targetValue: 10,
            request: const TargetClashQuestionRequest(
                answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
          )
          .question!
          .expressionValue,
      10,
    );
    final rational = generator.materializeForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.hard,
      numberType: NumberType.rationals,
      targetValue: 2.35,
      request: const TargetClashQuestionRequest(
          answer: PresentationAnswer.greaterThan, zone: TargetZone.closeCall),
    );
    expect(rational.question!.zone, TargetZone.closeCall);
    expect(source.directResults.last, 2.37);
  });

  test('unsupported and later no-candidate slots fail with no partial stage',
      () {
    final generator =
        TargetClashQuestionGenerator(questionGenerator: _NoDirectGenerator());
    expect(
      generator.prepareStageForTarget(
        operation: Operation.master,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        targetValue: 10,
        requests: const [],
      ).failure,
      TargetClashGenerationFailure.unsupportedConfiguration,
    );
    final failed = generator.prepareStageForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      targetValue: 10,
      requests: const [
        TargetClashQuestionRequest(
            answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      ],
    );
    expect(failed.stage, isNull);
    expect(failed.failure, TargetClashGenerationFailure.slotGenerationFailed);
  });

  test('fresh empty requests retain the TC-01 anchor behavior', () {
    final fresh = _FreshGenerator();
    final generator = TargetClashQuestionGenerator(questionGenerator: fresh);
    final result = generator.prepareStage(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      requests: const [],
    );
    expect(result.failure, isNull);
    expect(result.stage!.targetValue, 10);
    expect(result.stage!.questions, isEmpty);
    expect(fresh.buildCalls, 1);
    expect(
      generator.prepareStageForTarget(
        operation: Operation.addition,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        targetValue: 10,
        requests: const [],
      ).failure,
      TargetClashGenerationFailure.invalidRequest,
    );
  });

  test('supplied targets retain canonical metadata for every basic operation',
      () {
    final generator =
        TargetClashQuestionGenerator(questionGenerator: _DirectOnlyGenerator());
    for (final operation in const [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ]) {
      final question = generator
          .materializeForTarget(
            operation: operation,
            difficulty: Difficulty.easy,
            numberType: NumberType.natural,
            targetValue: 10,
            request: const TargetClashQuestionRequest(
              answer: PresentationAnswer.lessThan,
              zone: TargetZone.normal,
            ),
          )
          .question!;
      expect(question.expression.operation, operation);
      expect(question.expression.representation, FactRepresentation.direct);
      expect(question.expression.numberType, NumberType.natural);
    }
  });

  test(
      'candidate distances, precision, invalid request, and target mismatch fail closed',
      () {
    final source = _DirectOnlyGenerator();
    final generator = TargetClashQuestionGenerator(questionGenerator: source);
    for (final request in const [
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.danger),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.greaterThan, zone: TargetZone.closeCall),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
    ]) {
      expect(
          generator
              .materializeForTarget(
                operation: Operation.addition,
                difficulty: Difficulty.easy,
                numberType: NumberType.natural,
                targetValue: 10,
                request: request,
              )
              .question,
          isNotNull);
    }
    expect(source.directResults, [9, 12, 6]);
    expect(
        generator
            .materializeForTarget(
              operation: Operation.addition,
              difficulty: Difficulty.easy,
              numberType: NumberType.rationals,
              targetValue: 1.1,
              request: const TargetClashQuestionRequest(
                  answer: PresentationAnswer.greaterThan,
                  zone: TargetZone.danger),
            )
            .question!
            .expressionValue,
        1.2);
    expect(
        generator
            .materializeForTarget(
              operation: Operation.addition,
              difficulty: Difficulty.hard,
              numberType: NumberType.rationals,
              targetValue: 1.11,
              request: const TargetClashQuestionRequest(
                  answer: PresentationAnswer.greaterThan,
                  zone: TargetZone.danger),
            )
            .question!
            .expressionValue,
        1.12);
    expect(
        generator
            .materializeForTarget(
              operation: Operation.addition,
              difficulty: Difficulty.easy,
              numberType: NumberType.natural,
              targetValue: 10,
              request: const TargetClashQuestionRequest(
                  answer: PresentationAnswer.lessThan,
                  zone: TargetZone.bullseye),
            )
            .failure,
        TargetClashGenerationFailure.invalidRequest);
    final stage = generator.prepareStageForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      targetValue: 10,
      requests: const [
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal)
      ],
    ).stage!;
    final wrongTarget = generator
        .materializeForTarget(
          operation: Operation.addition,
          difficulty: Difficulty.easy,
          numberType: NumberType.natural,
          targetValue: 11,
          request: const TargetClashQuestionRequest(
              answer: PresentationAnswer.greaterThan, zone: TargetZone.danger),
        )
        .question!;
    expect(stage.replacingQuestion(index: 0, replacement: wrongTarget), isNull);
  });
}

class _DirectOnlyGenerator extends QuestionGenerator {
  int buildCalls = 0;
  final directResults = <num>[];

  @override
  Question build(
      {required Operation type,
      required Difficulty diff,
      required NumberType numType,
      bool integerQuest = false,
      bool decimalQuest = false}) {
    buildCalls++;
    throw StateError('supplied target must not build an anchor');
  }

  @override
  Question buildDirectForResult(
      {required Operation type,
      required Difficulty diff,
      required NumberType numType,
      required num result}) {
    directResults.add(result);
    final right = switch (type) {
      Operation.multiplication || Operation.division => 1,
      _ => 0,
    };
    final fact = MathFact(
      operation: type,
      left: result,
      right: right,
      result: result,
      representation: FactRepresentation.direct,
      difficulty: diff,
      numberType: numType,
      rationalDecimalPlaces: numType == NumberType.rationals
          ? diff == Difficulty.hard
              ? 2
              : 1
          : null,
    );
    return Question(
        type: type,
        key: '$result',
        text: '$result',
        ans: result,
        choices: const [],
        fact: fact);
  }
}

final class _FreshGenerator extends _DirectOnlyGenerator {
  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) {
    buildCalls++;
    return buildDirectForResult(
      type: type,
      diff: diff,
      numType: numType,
      result: 10,
    );
  }
}

final class _NoDirectGenerator extends QuestionGenerator {
  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) =>
      null;
}
