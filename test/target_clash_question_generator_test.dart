import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
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
  ScriptedGenerator(this.questions,
      {Map<num, List<Question?>>? direct,
      Map<num, Question?> reusableDirect = const {},
      List<num> domain = const []})
      : direct = direct ?? {},
        reusableDirect = reusableDirect,
        domain = domain.isNotEmpty
            ? domain
            : _domainForDirect([
                ...?direct?.keys,
                ...reusableDirect.keys,
              ]);
  final List<Question> questions;
  final Map<num, List<Question?>> direct;
  final Map<num, Question?> reusableDirect;
  final List<num> domain;
  final calls = <(Operation, Difficulty, NumberType)>[];
  final directCalls = <(Operation, Difficulty, NumberType, num)>[];
  @override
  List<num> canonicalDirectResultDomain({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
  }) => List.unmodifiable(domain);

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
    if (answers != null && answers.isNotEmpty) return answers.removeAt(0);
    return reusableDirect[result];
  }
}

List<num> _domainForDirect(Iterable<num> materializableResults) {
  // A fake declares every queried canonical value explicitly. The small halo
  // lets a supplied materializable result express its legal Target Clash
  // target without delegating to production randomness.
  final values = <num>{...materializableResults};
  for (final result in materializableResults) {
    for (var distance = 1; distance <= 6; distance++) {
      values.add(result - distance);
      values.add(result + distance);
    }
    // Rational Target Clash zones use decimal ticks rather than integer gaps.
    if (result is double && result != result.roundToDouble()) {
      for (var tick = 1; tick <= 6; tick++) {
        values.add((result * 100 - tick).round() / 100);
        values.add((result * 100 + tick).round() / 100);
      }
    }
  }
  return values.toList()..sort();
}

TargetClashStageResult prepare(
        ScriptedGenerator source, List<TargetClashQuestionRequest> requests,
        {Difficulty d = Difficulty.easy,
        NumberType n = NumberType.natural,
        Operation o = Operation.addition,
        Random? selectionRandom}) =>
    TargetClashQuestionGenerator(
            questionGenerator: source, selectionRandom: selectionRandom)
        .prepareStage(
        operation: o, difficulty: d, numberType: n, requests: requests);
List<num> results(ScriptedGenerator source) =>
    source.directCalls.map((call) => call.$4).toList();

final class _SelectionRandom implements Random {
  _SelectionRandom(this.value);
  final int value;
  final maxima = <int>[];
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
  @override int nextInt(int max) {
    maxima.add(max);
    return value;
  }
}

void main() {
  test(
      'feasible target selection materializes one complete immutable stage',
      () {
    final source = ScriptedGenerator([
      q(f(10))
    ], direct: {
      10: [q(f(10))], 14: [q(f(14))], 9: [q(f(9))]
    }, domain: const [9, 10, 14]);
    final stage = prepare(source, [gn, ld, eq]).stage!;
    expect(stage.targetValue, 10, reason: 'only 10 supports all requests');
    expect(stage.questions.map((item) => item.expressionValue), [14, 9, 10]);
    expect(stage.questions.map((item) => item.targetValue), [10, 10, 10]);
    expect(source.calls, isEmpty);
    expect(results(source), [14, 9, 10]);
  });

  test('danger requests exactly the one candidate in each direction', () {
    for (final entry in [(gd, 11), (ld, 9)]) {
      final source = ScriptedGenerator([], reusableDirect: {
        9: q(f(9)),
        10: q(f(10)),
        11: q(f(11)),
      }, domain: const [10, 11, 9]);
      expect(prepare(source, [entry.$1], selectionRandom: _SelectionRandom(0))
          .failure, isNull);
      expect(results(source), [entry.$2]);
      expect(source.calls, isEmpty);
    }
  });

  test('close and normal use ordered finite candidate lists', () {
    final close = ScriptedGenerator([], reusableDirect: {
      10: q(f(10)), 12: q(f(12)), 13: q(f(13)),
    }, domain: const [10, 12, 13]);
    expect(prepare(close, [gc]).failure, isNull);
    expect(results(close), [12]);
    final closeLess = ScriptedGenerator([], reusableDirect: {
      7: q(f(7)), 8: q(f(8)), 10: q(f(10)),
    }, domain: const [10, 8, 7]);
    expect(prepare(closeLess, [lc]).failure, isNull);
    expect(results(closeLess), [8]);
    final normal = ScriptedGenerator([], reusableDirect: {
      10: q(f(10)), 14: q(f(14)), 15: q(f(15)), 16: q(f(16)),
    }, domain: const [10, 14, 15, 16]);
    expect(prepare(normal, [gn]).failure, isNull);
    expect(results(normal), [14]);
    final normalLess = ScriptedGenerator([], domain: const [10]);
    expect(prepare(normalLess, [ln]).stage, isNull);
    expect(results(normalLess), isEmpty);
  });

  test('R3-11 synthetic mathematically impossible profile fails closed before selection',
      () {
    const canonicalDomain = [10];
    const requests = [ln];
    const operation = Operation.addition;
    const difficulty = Difficulty.easy;
    const numberType = NumberType.natural;
    final feasibleTargets = canonicalDomain.where((target) {
      // A less-than Normal request for target 10 permits only 6, 5, or 4.
      final candidateResults = [target - 4, target - 5, target - 6];
      return candidateResults.any(canonicalDomain.contains);
    }).toList();
    expect(canonicalDomain, [10]);
    expect(requests, [ln]);
    expect(feasibleTargets, isEmpty);
    expect(feasibleTargets, hasLength(0));

    final source = ScriptedGenerator([], domain: canonicalDomain);
    final selection = _SelectionRandom(0);
    final result = prepare(source, requests,
        o: operation,
        d: difficulty,
        n: numberType,
        selectionRandom: selection);

    expect(result.failure, TargetClashGenerationFailure.anchorGenerationFailed);
    expect(result.stage, isNull);
    expect(selection.maxima, isEmpty);
    expect(source.directCalls, isEmpty);
    expect(results(source), isEmpty);
    expect(source.calls, isEmpty);
  });

  test('singleton feasible target succeeds without selection RNG fallback', () {
    final source = ScriptedGenerator([], reusableDirect: {10: q(f(10))},
        domain: const [10]);
    final stage = prepare(source, [eq, eq]).stage!;
    expect(stage.targetValue, 10);
    expect(results(source), [10, 10]);
  });

  test('Stage-2 future Triple preflight rejects ordinary-only targets', () {
    // 16 satisfies the real Medium Stage-2 ordinary set (20, 14, 16), but
    // lacks its Triple < Normal result (12). 18 and 20 support both sets.
    final values = [14, 16, 18, 20, 24];
    final source = ScriptedGenerator([], domain: values,
        reusableDirect: {
          for (final value in values) value: q(f(value, d: Difficulty.medium)),
        });
    final result = TargetClashQuestionGenerator(questionGenerator: source,
        selectionRandom: Random(1)).prepareStage(
      operation: Operation.addition,
      difficulty: Difficulty.medium,
      numberType: NumberType.natural,
      requests: TargetClashRuntimeState.ordinaryRequests(Difficulty.medium, 2),
      futureRequests: TargetClashRuntimeState.tripleRequests(0)!,
    );
    expect(result.failure, isNull);
    final combined = [
      ...TargetClashRuntimeState.ordinaryRequests(Difficulty.medium, 2),
      ...TargetClashRuntimeState.tripleRequests(0)!,
    ];
    TargetClashStageResult attempt(num target) => TargetClashQuestionGenerator(
      questionGenerator: ScriptedGenerator([], domain: values,
        reusableDirect: {
          for (final value in values) value: q(f(value, d: Difficulty.medium)),
        }),
    ).prepareStageForTarget(operation: Operation.addition,
            difficulty: Difficulty.medium, numberType: NumberType.natural,
            targetValue: target, requests: combined);
    final ordinaryOnly = TargetClashQuestionGenerator(
      questionGenerator: ScriptedGenerator([], domain: values,
          reusableDirect: {
            for (final value in values)
              value: q(f(value, d: Difficulty.medium)),
          }),
    ).prepareStageForTarget(
        operation: Operation.addition,
        difficulty: Difficulty.medium,
        numberType: NumberType.natural,
        targetValue: 16,
        requests: TargetClashRuntimeState.ordinaryRequests(Difficulty.medium, 2));
    expect(ordinaryOnly.stage, isNotNull,
        reason: '16 is ordinary-stage feasible');
    expect(attempt(16).stage, isNull,
        reason: '16 is ordinary-compatible but cannot support Triple');
    for (final feasible in [18, 20]) {
      expect(attempt(feasible).stage, isNotNull);
    }
    expect(result.stage!.targetValue, anyOf(18, 20));
  });

  test('feasible filtering precedes deterministic selection and direct seam', () {
    final source = ScriptedGenerator([], domain: const [10, 14, 20, 24], direct: {
      10: [q(f(10))], 14: [q(f(14))], 20: [q(f(20))], 24: [q(f(24))],
    });
    final selection = _SelectionRandom(2);
    final stage = TargetClashQuestionGenerator(
      questionGenerator: source,
      selectionRandom: selection,
    ).prepareStage(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      requests: const [eq, gn],
    ).stage!;
    // Feasible targets are [10, 14, 20]; 24 is filtered out before the
    // deterministic index is applied to that ordered feasible set.
    expect(selection.maxima, [3]);
    expect(stage.targetValue, 20);
    final anchor = stage.questions.first.expression;
    expect(anchor.representation, FactRepresentation.direct);
    expect(anchor.operation, Operation.addition);
    expect(anchor.difficulty, Difficulty.easy);
    expect(anchor.numberType, NumberType.natural);
    expect(anchor.result, 20);
    expect(anchor.isMathematicallyValid, isTrue);
    expect(source.directCalls.map((call) => call.$4), [20, 24]);
  });

  test('Easy Stage 2 equivalent does not require future Triple requests', () {
    final source = ScriptedGenerator([], domain: const [10],
        direct: {10: [q(f(10))]});
    expect(prepare(source, const [eq]).stage, isNotNull);
  });

  test('domain/materialization mismatch fails closed', () {
    final bad = f(10).copyWith(representation: FactRepresentation.missingLeft);
    final source = ScriptedGenerator([], direct: {10: [q(bad)]}, domain: const [10]);
    final result = prepare(source, [eq]);
    expect(result.failure,
        TargetClashGenerationFailure.canonicalDomainMaterializationMismatch);
    expect(result.stage, isNull);
  });

  test('later failed slot discards a previously prepared slot atomically', () {
    final source = ScriptedGenerator([], direct: {11: [q(f(11))]},
        domain: const [10, 11, 14]);
    final result = prepare(source, [gd, gn]);
    expect(result.failure,
        TargetClashGenerationFailure.canonicalDomainMaterializationMismatch);
    expect(result.stage, isNull);
    expect(results(source), [11, 14]);
    expect(source.calls, isEmpty);
  });

  test('invalid direct metadata is rejected', () {
    final source = ScriptedGenerator([
      q(f(10))
    ], direct: {
      11: [q(f(11).copyWith(difficulty: Difficulty.medium))]
    }, domain: const [10, 11]);
    final result = prepare(source, [gd]);
    expect(result.failure,
        TargetClashGenerationFailure.canonicalDomainMaterializationMismatch);
    expect(result.stage, isNull);
    expect(results(source), [11]);
  });

  test('rational candidates use ticks from dp2 anchor', () {
    ScriptedGenerator source(Map<num, Question?> reusableDirect,
            List<num> domain) =>
        ScriptedGenerator(
            [q(f(2.35, d: Difficulty.hard, n: NumberType.rationals, dp: 2))],
            reusableDirect: reusableDirect, domain: domain);
    final up = source({
      2.35: q(f(2.35, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
      2.36: q(f(2.36, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
    }, const [2.35, 2.36]);
    expect(
        prepare(up, [gd], d: Difficulty.hard, n: NumberType.rationals).failure,
        isNull);
    expect(results(up).map((value) => (value * 100).round()), [236]);
    final down = source({
      2.34: q(f(2.34, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
      2.35: q(f(2.35, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
    }, const [2.34, 2.35]);
    expect(
        prepare(down, [ld], d: Difficulty.hard, n: NumberType.rationals)
            .failure,
        isNull);
    expect(results(down).map((value) => (value * 100).round()), [234]);
    final close = source({
      2.35: q(f(2.35, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
      2.37: q(f(2.37, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
      2.38: q(f(2.38, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
    }, const [2.35, 2.37, 2.38]);
    expect(
        prepare(close, [gc], d: Difficulty.hard, n: NumberType.rationals)
            .failure,
        isNull);
    expect(results(close).map((value) => (value * 100).round()), [237]);
    final normal = source({
      2.35: q(f(2.35, d: Difficulty.hard, n: NumberType.rationals, dp: 2)),
    }, const [2.35]);
    expect(
        prepare(normal, [ln], d: Difficulty.hard, n: NumberType.rationals)
            .stage,
        isNull);
    expect(
        results(normal).map((value) => (value * 100).round()), isEmpty);
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
      final source = ScriptedGenerator([], domain: const [10, 11],
          reusableDirect: {
            10: q(f(10, o: operation)),
            11: q(f(11, o: operation)),
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

  test('R3 regression seeds 8, 23, and 236 prepare complete stages', () {
    final regressions = [
      (Operation.addition, Difficulty.medium, NumberType.natural, 8),
      (Operation.addition, Difficulty.easy, NumberType.natural, 23),
      (Operation.subtraction, Difficulty.easy, NumberType.natural, 236),
    ];
    for (final entry in regressions) {
      final result = TargetClashQuestionGenerator(
        questionGenerator: QuestionGenerator(rng: Random(entry.$4)),
        selectionRandom: Random(entry.$4),
      ).prepareStage(
        operation: entry.$1,
        difficulty: entry.$2,
        numberType: entry.$3,
        requests: const [ln, gn, eq],
      );
      expect(result.failure, isNull, reason: 'seed ${entry.$4}');
      expect(result.stage, isNotNull, reason: 'seed ${entry.$4}');
    }
  });

  test('R3-15 Subtraction/Easy/Natural reports its derived domain and target',
      () {
    final generator = QuestionGenerator(rng: Random(1));
    final domain = generator.canonicalDirectResultDomain(
        type: Operation.subtraction,
        diff: Difficulty.easy,
        numType: NumberType.natural);
    final planner = TargetClashQuestionGenerator(questionGenerator: generator);
    final feasible = domain
        .where((target) => planner
            .prepareStageForTarget(
                operation: Operation.subtraction,
                difficulty: Difficulty.easy,
                numberType: NumberType.natural,
                targetValue: target,
                requests: const [ln, gn, eq])
            .stage != null)
        .toList();
    // ignore: avoid_print
    print('canonical_domain=$domain feasible_targets=$feasible feasible_target_count=${feasible.length}');
    expect(domain, List<num>.generate(9, (index) => index + 1));
    expect(feasible, const [5]);
    expect(feasible.length, 1);
  });
}
