import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';

const eq = TargetClashQuestionRequest(
    answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye);
const gd = TargetClashQuestionRequest(
    answer: PresentationAnswer.greaterThan, zone: TargetZone.danger);
const ld = TargetClashQuestionRequest(
    answer: PresentationAnswer.lessThan, zone: TargetZone.danger);
const gc = TargetClashQuestionRequest(
    answer: PresentationAnswer.greaterThan, zone: TargetZone.closeCall);
const lc = TargetClashQuestionRequest(
    answer: PresentationAnswer.lessThan, zone: TargetZone.closeCall);
const gn = TargetClashQuestionRequest(
    answer: PresentationAnswer.greaterThan, zone: TargetZone.normal);
const ln = TargetClashQuestionRequest(
    answer: PresentationAnswer.lessThan, zone: TargetZone.normal);

MathFact f(num result,
        {Difficulty d = Difficulty.easy,
        NumberType n = NumberType.natural,
        Operation o = Operation.addition,
        int? dp}) =>
    MathFact(
        operation: o,
        left: result,
        right: o == Operation.multiplication || o == Operation.division ? 1 : 0,
        result: result,
        representation: FactRepresentation.direct,
        difficulty: d,
        numberType: n,
        rationalDecimalPlaces: dp);
Question q(MathFact? fact) => Question(
    type: Operation.master,
    key: 'opaque',
    text: 'not parsed',
    ans: -999,
    choices: const [],
    fact: fact);

class ScriptedGenerator extends QuestionGenerator {
  ScriptedGenerator(this.questions, {Map<num, List<Question?>>? direct})
      : direct = direct ?? {};
  final List<Question> questions;
  final Map<num, List<Question?>> direct;
  final calls = <(Operation, Difficulty, NumberType)>[];
  final directCalls = <(Operation, Difficulty, NumberType, num)>[];
  @override
  Question build(
      {required Operation type,
      required Difficulty diff,
      required NumberType numType,
      bool integerQuest = false,
      bool decimalQuest = false}) {
    calls.add((type, diff, numType));
    if (calls.length > questions.length) throw StateError('Unexpected build');
    return questions[calls.length - 1];
  }

  @override
  Question? buildDirectForResult(
      {required Operation type,
      required Difficulty diff,
      required NumberType numType,
      required num result}) {
    directCalls.add((type, diff, numType, result));
    final answers = direct[result];
    return answers == null || answers.isEmpty ? null : answers.removeAt(0);
  }
}

TargetClashStageResult prepare(
        ScriptedGenerator source, List<TargetClashQuestionRequest> requests,
        {Difficulty d = Difficulty.easy,
        NumberType n = NumberType.natural,
        Operation o = Operation.addition}) =>
    TargetClashQuestionGenerator(questionGenerator: source).prepareStage(
        operation: o, difficulty: d, numberType: n, requests: requests);
List<num> results(ScriptedGenerator source) =>
    source.directCalls.map((call) => call.$4).toList();

void main() {
  test(
      'anchor fixes every target, preserves request order, and uses direct seam',
      () {
    final anchor = f(10);
    final source = ScriptedGenerator([
      q(anchor)
    ], direct: {
      14: [q(f(14))],
      9: [q(f(9))]
    });
    final stage = prepare(source, [gn, ld, eq]).stage!;
    expect(stage.targetValue, 10);
    expect(stage.questions.map((item) => item.expressionValue), [14, 9, 10]);
    expect(stage.questions.map((item) => item.targetValue), [10, 10, 10]);
    expect(stage.questions.last.expression, same(anchor));
    expect(source.calls, hasLength(1));
    expect(results(source), [14, 9]);
  });

  test('danger requests exactly the one candidate in each direction', () {
    for (final entry in [(gd, 11), (ld, 9)]) {
      final source = ScriptedGenerator([
        q(f(10))
      ], direct: {
        entry.$2: [q(f(entry.$2))]
      });
      expect(prepare(source, [entry.$1]).failure, isNull);
      expect(results(source), [entry.$2]);
      expect(source.calls, hasLength(1));
    }
  });

  test('close and normal use ordered finite candidate lists', () {
    final close = ScriptedGenerator([
      q(f(10))
    ], direct: {
      13: [q(f(13))]
    });
    expect(prepare(close, [gc]).failure, isNull);
    expect(results(close), [12, 13]);
    final closeLess = ScriptedGenerator([
      q(f(10))
    ], direct: {
      7: [q(f(7))]
    });
    expect(prepare(closeLess, [lc]).failure, isNull);
    expect(results(closeLess), [8, 7]);
    final normal = ScriptedGenerator([
      q(f(10))
    ], direct: {
      16: [q(f(16))]
    });
    expect(prepare(normal, [gn]).failure, isNull);
    expect(results(normal), [14, 15, 16]);
    final normalLess = ScriptedGenerator([q(f(10))]);
    expect(prepare(normalLess, [ln]).stage, isNull);
    expect(results(normalLess), [6, 5, 4]);
  });

  test('equal reuses anchor without direct seam call', () {
    final source = ScriptedGenerator([q(f(10))]);
    final stage = prepare(source, [eq, eq]).stage!;
    expect(stage.questions[0].expression, same(stage.questions[1].expression));
    expect(source.directCalls, isEmpty);
  });

  test('anchor is bounded and invalid anchor metadata is rejected', () {
    final bad = f(10).copyWith(representation: FactRepresentation.missingLeft);
    final eighth = ScriptedGenerator([...List.filled(7, q(bad)), q(f(10))]);
    expect(prepare(eighth, [eq]).failure, isNull);
    expect(eighth.calls, hasLength(8));
    final exhausted = ScriptedGenerator(List.filled(9, q(bad)));
    final result = prepare(exhausted, [eq]);
    expect(result.failure, TargetClashGenerationFailure.anchorGenerationFailed);
    expect(result.stage, isNull);
    expect(exhausted.calls, hasLength(8));
  });

  test('later failed slot discards a previously prepared slot atomically', () {
    final source = ScriptedGenerator([
      q(f(10))
    ], direct: {
      11: [q(f(11))]
    });
    final result = prepare(source, [gd, gn]);
    expect(result.failure, TargetClashGenerationFailure.slotGenerationFailed);
    expect(result.stage, isNull);
    expect(results(source), [11, 14, 15, 16]);
    expect(source.calls, hasLength(1));
  });

  test('invalid direct metadata is rejected', () {
    final source = ScriptedGenerator([
      q(f(10))
    ], direct: {
      11: [q(f(11).copyWith(difficulty: Difficulty.medium))]
    });
    final result = prepare(source, [gd]);
    expect(result.failure, TargetClashGenerationFailure.slotGenerationFailed);
    expect(result.stage, isNull);
    expect(results(source), [11]);
  });

  test('rational candidates use ticks from dp2 anchor', () {
    ScriptedGenerator source(
            Map<num, List<Question?>> direct) =>
        ScriptedGenerator(
            [q(f(2.35, d: Difficulty.hard, n: NumberType.rationals, dp: 2))],
            direct: direct);
    final up = source({
      2.36: [q(f(2.36, d: Difficulty.hard, n: NumberType.rationals, dp: 2))]
    });
    expect(
        prepare(up, [gd], d: Difficulty.hard, n: NumberType.rationals).failure,
        isNull);
    expect(results(up).map((value) => (value * 100).round()), [236]);
    final down = source({
      2.34: [q(f(2.34, d: Difficulty.hard, n: NumberType.rationals, dp: 2))]
    });
    expect(
        prepare(down, [ld], d: Difficulty.hard, n: NumberType.rationals)
            .failure,
        isNull);
    expect(results(down).map((value) => (value * 100).round()), [234]);
    final close = source({
      2.38: [q(f(2.38, d: Difficulty.hard, n: NumberType.rationals, dp: 2))]
    });
    expect(
        prepare(close, [gc], d: Difficulty.hard, n: NumberType.rationals)
            .failure,
        isNull);
    expect(results(close).map((value) => (value * 100).round()), [237, 238]);
    final normal = source({});
    expect(
        prepare(normal, [ln], d: Difficulty.hard, n: NumberType.rationals)
            .stage,
        isNull);
    expect(
        results(normal).map((value) => (value * 100).round()), [231, 230, 229]);
  });

  test('configuration and request errors occur before generation', () {
    final unsupported = ScriptedGenerator([]);
    expect(prepare(unsupported, [eq], o: Operation.master).failure,
        TargetClashGenerationFailure.unsupportedConfiguration);
    expect(unsupported.calls, isEmpty);
    final invalid = ScriptedGenerator([]);
    expect(
        prepare(invalid, const [
          TargetClashQuestionRequest(
              answer: PresentationAnswer.equalTo, zone: TargetZone.danger)
        ]).failure,
        TargetClashGenerationFailure.invalidRequest);
    expect(invalid.calls, isEmpty);
  });

  test('all basic operations retain exact direct fact metadata', () {
    for (final operation in [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division,
    ]) {
      final source = ScriptedGenerator([
        q(f(10, o: operation))
      ], direct: {
        11: [q(f(11, o: operation))]
      });
      final result = prepare(source, [gd], o: operation);
      final question = result.stage!.questions.single.expression;
      expect(result.failure, isNull);
      expect(question.operation, operation);
      expect(question.isMathematicallyValid, isTrue);
      expect(source.directCalls.single.$1, operation);
      expect(source.directCalls.single.$4, 11);
    }
  });

  test('unsupported configurations fail before either generator seam', () {
    final unsupported = [
      (Operation.mixed, Difficulty.easy, NumberType.natural),
      (Operation.master, Difficulty.easy, NumberType.natural),
      (Operation.dailyBoss, Difficulty.easy, NumberType.natural),
      (Operation.survival, Difficulty.easy, NumberType.natural),
      (Operation.addition, Difficulty.expert, NumberType.natural),
      (Operation.addition, Difficulty.insane, NumberType.natural),
      (Operation.addition, Difficulty.easy, NumberType.mixed),
    ];
    for (final configuration in unsupported) {
      final source = ScriptedGenerator([]);
      final result = prepare(source, [eq],
          o: configuration.$1, d: configuration.$2, n: configuration.$3);
      expect(result.failure,
          TargetClashGenerationFailure.unsupportedConfiguration);
      expect(result.stage, isNull);
      expect(source.calls, isEmpty);
      expect(source.directCalls, isEmpty);
    }
  });

  test('every invalid answer and zone pairing fails before generation', () {
    for (final answer in PresentationAnswer.values) {
      for (final zone in TargetZone.values) {
        final request = TargetClashQuestionRequest(answer: answer, zone: zone);
        if (request.isValid) continue;
        final source = ScriptedGenerator([]);
        final result = prepare(source, [request]);
        expect(result.failure, TargetClashGenerationFailure.invalidRequest);
        expect(result.stage, isNull);
        expect(source.calls, isEmpty);
        expect(source.directCalls, isEmpty);
      }
    }
  });

  test('seeded real anchors are canonical across eligible number types', () {
    for (final entry in [
      (NumberType.natural, 1),
      (NumberType.integers, 2),
      (NumberType.rationals, 3),
    ]) {
      final result = TargetClashQuestionGenerator(
              questionGenerator: QuestionGenerator(rng: Random(entry.$2)))
          .prepareStage(
              operation: Operation.addition,
              difficulty: Difficulty.easy,
              numberType: entry.$1,
              requests: const [eq]);
      final question = result.stage!.questions.single;
      expect(result.failure, isNull);
      expect(question.expression.isMathematicallyValid, isTrue);
      expect(question.expression.representation, FactRepresentation.direct);
      expect(question.expression.numberType, entry.$1);
      expect(question.targetValue, question.expressionValue);
      expect(question.zone, TargetZone.bullseye);
      expect(question.correctAnswer, PresentationAnswer.equalTo);
    }
  });

  test('seeded real hard rational non-bullseye stage has direct dp2 fact', () {
    final result = TargetClashQuestionGenerator(
            questionGenerator: QuestionGenerator(rng: Random(42)))
        .prepareStage(
            operation: Operation.addition,
            difficulty: Difficulty.hard,
            numberType: NumberType.rationals,
            requests: const [gd]);
    final question = result.stage!.questions.single;
    expect(result.failure, isNull);
    expect(question.targetValue, result.stage!.targetValue);
    expect(question.correctAnswer, PresentationAnswer.greaterThan);
    expect(question.zone, TargetZone.danger);
    expect(question.expression.representation, FactRepresentation.direct);
    expect(question.expression.rationalDecimalPlaces, 2);
  });
}
