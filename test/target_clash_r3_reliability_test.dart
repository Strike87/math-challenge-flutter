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

/// R3-15/R3-16: focused enumeration evidence. This deliberately separates the
/// pure target-feasibility proof from question materialization and lifecycle
/// tests. It never calls the Target Clash planner or any question builder.
void main() {
  const operations = [
    Operation.addition,
    Operation.subtraction,
    Operation.multiplication,
    Operation.division,
  ];
  const difficulties = [Difficulty.easy, Difficulty.medium, Difficulty.hard];
  const numberTypes = [
    NumberType.natural,
    NumberType.integers,
    NumberType.rationals,
  ];

  test('R3-15 reports the structural Easy Natural Subtraction profile', () {
    final questionGenerator = QuestionGenerator();
    final domain = questionGenerator.canonicalDirectResultDomain(
      type: Operation.subtraction,
      diff: Difficulty.easy,
      numType: NumberType.natural,
    );
    final feasible = _feasibleTargets(
      domain: domain,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      requests: TargetClashRuntimeState.resolveRequests(
        operation: Operation.subtraction,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
        phase: TargetClashRequestProfilePhase.ordinaryStage1,
      ),
    );

    // ignore: avoid_print
    print(
      'R3-15 subtraction/easy/natural/stage1 '
      'canonical_domain=$domain feasible_targets=$feasible '
      'feasible_target_count=${feasible.length}',
    );
    expect(feasible, isNotEmpty);
  });

  test(
      'R3-12 known low-level seed 8 Addition Medium Natural generator regression',
      () {
    const seed = 8;
    const operation = Operation.addition;
    const difficulty = Difficulty.medium;
    const numberType = NumberType.natural;
    const requests = [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.lessThan,
        zone: TargetZone.normal,
      ),
      TargetClashQuestionRequest(
        answer: PresentationAnswer.greaterThan,
        zone: TargetZone.normal,
      ),
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
    ];

    TargetClashStageResult prepareWithHistoricalSeed() =>
        TargetClashQuestionGenerator(
          questionGenerator: QuestionGenerator(rng: Random(seed)),
          selectionRandom: Random(seed),
        ).prepareStage(
          operation: operation,
          difficulty: difficulty,
          numberType: numberType,
          requests: requests,
        );

    expect(seed, 8);
    expect(operation, Operation.addition);
    expect(difficulty, Difficulty.medium);
    expect(numberType, NumberType.natural);
    expect(requests, hasLength(3));
    expect(requests[0].answer, PresentationAnswer.lessThan);
    expect(requests[0].zone, TargetZone.normal);
    expect(requests[1].answer, PresentationAnswer.greaterThan);
    expect(requests[1].zone, TargetZone.normal);
    expect(requests[2].answer, PresentationAnswer.equalTo);
    expect(requests[2].zone, TargetZone.bullseye);

    final domain = QuestionGenerator().canonicalDirectResultDomain(
      type: operation,
      diff: difficulty,
      numType: numberType,
    );
    final feasible = _feasibleTargets(
      domain: domain,
      difficulty: difficulty,
      numberType: numberType,
      requests: requests,
    );
    expect(domain, isNotEmpty);
    expect(feasible, isNotEmpty);

    final result = prepareWithHistoricalSeed();
    final stage = result.stage;
    expect(result.failure, isNull);
    expect(stage, isNotNull);
    expect(stage!.questions, hasLength(requests.length));
    expect(feasible, contains(stage.targetValue));
    for (var index = 0; index < requests.length; index++) {
      final request = requests[index];
      final question = stage.questions[index];
      final expression = question.expression;
      expect(question.targetValue, stage.targetValue);
      expect(
        PresentationAnswer.classify(question.expressionValue, stage.targetValue),
        request.answer,
      );
      expect(question.zone, request.zone);
      expect(
        TargetClashQuestion.tryCreate(
          expression: expression,
          targetValue: stage.targetValue,
        )?.zone,
        request.zone,
      );
      expect(expression.isMathematicallyValid, isTrue);
      expect(expression.representation, FactRepresentation.direct);
      expect(expression.operation, operation);
      expect(expression.difficulty, difficulty);
      expect(expression.numberType, numberType);
    }

    final repeated = prepareWithHistoricalSeed();
    expect(repeated.failure, result.failure);
    expect(repeated.stage, isNotNull);
    expect(repeated.stage!.targetValue, stage.targetValue);
    expect(repeated.stage!.questions, hasLength(stage.questions.length));
  });

  // R3-15 independently establishes this exact explicit low-level request
  // profile has singleton feasibility [5]. This is not a runtime phase claim.
  test(
      'R3-14 known low-level seed 236 Subtraction Easy Natural singleton-target regression',
      () {
    const seed = 236;
    const operation = Operation.subtraction;
    const difficulty = Difficulty.easy;
    const numberType = NumberType.natural;
    const requests = [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.lessThan,
        zone: TargetZone.normal,
      ),
      TargetClashQuestionRequest(
        answer: PresentationAnswer.greaterThan,
        zone: TargetZone.normal,
      ),
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
    ];

    TargetClashStageResult prepareWithHistoricalSeed() =>
        TargetClashQuestionGenerator(
          questionGenerator: QuestionGenerator(rng: Random(seed)),
          selectionRandom: Random(seed),
        ).prepareStage(
          operation: operation,
          difficulty: difficulty,
          numberType: numberType,
          requests: requests,
        );

    expect(seed, 236);
    expect(operation, Operation.subtraction);
    expect(difficulty, Difficulty.easy);
    expect(numberType, NumberType.natural);
    expect(requests, hasLength(3));
    expect(requests[0].answer, PresentationAnswer.lessThan);
    expect(requests[0].zone, TargetZone.normal);
    expect(requests[1].answer, PresentationAnswer.greaterThan);
    expect(requests[1].zone, TargetZone.normal);
    expect(requests[2].answer, PresentationAnswer.equalTo);
    expect(requests[2].zone, TargetZone.bullseye);

    final domain = QuestionGenerator().canonicalDirectResultDomain(
      type: operation,
      diff: difficulty,
      numType: numberType,
    );
    final feasible = _feasibleTargets(
      domain: domain,
      difficulty: difficulty,
      numberType: numberType,
      requests: requests,
    );
    expect(domain, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(feasible, [5]);

    final result = prepareWithHistoricalSeed();
    final stage = result.stage;
    expect(result.failure, isNull);
    expect(stage, isNotNull);
    expect(stage!.questions, hasLength(requests.length));
    expect(stage.targetValue, 5);
    expect(feasible, contains(stage.targetValue));
    for (var index = 0; index < requests.length; index++) {
      final request = requests[index];
      final question = stage.questions[index];
      final expression = question.expression;
      expect(question.targetValue, 5);
      expect(
        PresentationAnswer.classify(question.expressionValue, stage.targetValue),
        request.answer,
      );
      expect(question.zone, request.zone);
      expect(
        TargetClashQuestion.tryCreate(
          expression: expression,
          targetValue: stage.targetValue,
        )?.zone,
        request.zone,
      );
      expect(expression.isMathematicallyValid, isTrue);
      expect(expression.representation, FactRepresentation.direct);
      expect(expression.operation, operation);
      expect(expression.difficulty, difficulty);
      expect(expression.numberType, numberType);
    }

    final repeated = prepareWithHistoricalSeed();
    expect(repeated.failure, result.failure);
    expect(repeated.stage, isNotNull);
    expect(repeated.stage!.targetValue, 5);
    expect(repeated.stage!.questions, hasLength(stage.questions.length));
  });

  test('R3-16 cross-check multiplication hard natural boss', () {
    const operation = Operation.multiplication;
    const difficulty = Difficulty.hard;
    const numberType = NumberType.natural;
    final requests = TargetClashRuntimeState.resolveRequests(
      operation: operation,
      difficulty: difficulty,
      numberType: numberType,
      phase: TargetClashRequestProfilePhase.boss,
    );
    final questionGenerator = QuestionGenerator(rng: Random(17));
    final domain = questionGenerator.canonicalDirectResultDomain(
      type: operation,
      diff: difficulty,
      numType: numberType,
    );
    final sortedDomain = domain.toSet().toList()..sort();
    final domainSet = sortedDomain.toSet();
    final isSorted = List.generate(
      domain.length > 1 ? domain.length - 1 : 0,
      (index) => domain[index] <= domain[index + 1],
    ).every((value) => value);
    final isSparse = List.generate(
      sortedDomain.length > 1 ? sortedDomain.length - 1 : 0,
      (index) => sortedDomain[index + 1] - sortedDomain[index] != 1,
    ).any((value) => value);
    var survivors = List<num>.of(sortedDomain);

    // ignore: avoid_print
    print(
      'R3-16_CROSSCHECK_DOMAIN total=${domain.length} '
      'unique=${sortedDomain.length} sorted=$isSorted sparse=$isSparse '
      'first10=${sortedDomain.take(10).toList()} '
      'last10=${sortedDomain.reversed.take(10).toList().reversed.toList()}',
    );
    for (var index = 0; index < requests.length; index++) {
      final request = requests[index];
      survivors = [
        for (final target in survivors)
          if (_candidateResults(
            target: target,
            difficulty: difficulty,
            numberType: numberType,
            request: request,
          ).any(domainSet.contains))
            target,
      ];
      // ignore: avoid_print
      print(
        'R3-16_CROSSCHECK_SURVIVAL request=$index '
        'answer=${request.answer} zone=${request.zone} '
        'survival_count=${survivors.length} '
        'near_targets=${survivors.take(10).toList()}',
      );
    }

    final pureFeasible = _feasibleTargets(
      domain: sortedDomain,
      difficulty: difficulty,
      numberType: numberType,
      requests: requests,
    );
    final planner = TargetClashQuestionGenerator(
      questionGenerator: questionGenerator,
      selectionRandom: Random(23),
    );
    final result = planner.prepareStage(
      operation: operation,
      difficulty: difficulty,
      numberType: numberType,
      requests: requests,
    );
    final stage = result.stage;
    // ignore: avoid_print
    print(
      'R3-16_CROSSCHECK_PRODUCTION '
      'failure=${result.failure} target=${stage?.targetValue} '
      'stage_size=${stage?.questions.length} '
      'pure_feasible_count=${pureFeasible.length} '
      'pure_feasible_contains_target=${stage == null ? null : pureFeasible.contains(stage.targetValue)}',
    );
  });

  test('R3 enumerates every runtime-derived supported phase profile', () {
    var profileCount = 0;
    var feasibleProfileCount = 0;
    final zeroFeasibleProfiles = <_ProfileFeasibility>[];
    final csvRows = <String>[
      'operation,difficulty,number_type,profile,canonical_domain_size,feasible_target_count,first_eliminating_request_index,first_eliminating_relation,first_eliminating_zone',
    ];
    final expectedProfileRows = operations.length *
        numberTypes.length *
        difficulties.fold<int>(
          0,
          (total, difficulty) =>
              total +
              _runtimeProfiles(
                Operation.addition,
                difficulty,
                NumberType.natural,
              ).length,
        );
    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          final questionGenerator = QuestionGenerator();
          final domain = questionGenerator.canonicalDirectResultDomain(
            type: operation,
            diff: difficulty,
            numType: numberType,
          );
          final profiles = _runtimeProfiles(operation, difficulty, numberType);
          for (final profile in profiles.entries) {
            profileCount++;
            final profileKey = '$operation/$difficulty/$numberType/'
                '${profile.key}';
            // ignore: avoid_print
            print('PROFILE_BEGIN operation=$operation difficulty=$difficulty '
                'number_type=$numberType profile=${profile.key} '
                'domain_size=${domain.length}');
            final feasible = _feasibleTargets(
              domain: domain,
              difficulty: difficulty,
              numberType: numberType,
              requests: profile.value,
            );
            final feasibility = _profileFeasibility(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              profile: profile.key,
              domain: domain,
              requests: profile.value,
            );
            csvRows.add(feasibility.toCsvRow());
            if (feasible.isEmpty) {
              zeroFeasibleProfiles.add(feasibility);
            } else {
              feasibleProfileCount++;
            }
            // ignore: avoid_print
            print('PROFILE_DONE operation=$operation difficulty=$difficulty '
                'number_type=$numberType profile=${profile.key} '
                'domain_size=${domain.length} feasible_target_count=${feasible.length}');
            expect(feasible.length, feasibility.feasibleTargetCount,
                reason: profileKey);
          }
        }
      }
    }

    const outputDirectory =
        r'D:\FlutterProjects\math_challenge_target_clash_fix_01_review';
    final directory = Directory(outputDirectory);
    directory.createSync(recursive: true);
    File('$outputDirectory${Platform.pathSeparator}'
            'R3D01_profile_feasibility_scope.csv')
        .writeAsStringSync('${csvRows.join('\n')}\n');
    File('$outputDirectory${Platform.pathSeparator}'
            'R3D01_zero_feasible_profiles.txt')
        .writeAsStringSync(_zeroFeasibleReport(zeroFeasibleProfiles));

    // ignore: avoid_print
    print('R3D01_SCOPE_SUMMARY supported_profile_count=$profileCount '
        'feasible_profile_count=$feasibleProfileCount '
        'zero_feasible_profile_count=${zeroFeasibleProfiles.length}');

    // The expected row count is derived from the current runtime request
    // profiles rather than a frozen diagnostic constant.
    expect(profileCount, expectedProfileRows);
    expect(feasibleProfileCount + zeroFeasibleProfiles.length, profileCount);
  });
}

Map<String, List<TargetClashQuestionRequest>> _runtimeProfiles(
  Operation operation,
  Difficulty difficulty,
  NumberType numberType,
) => {
      'stage1': TargetClashRuntimeState.resolveRequests(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        phase: TargetClashRequestProfilePhase.ordinaryStage1,
      ),
      'stage2': TargetClashRuntimeState.resolveRequests(
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
      'final': TargetClashRuntimeState.resolveRequests(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        phase: TargetClashRequestProfilePhase.finalTarget,
      ),
      if (difficulty != Difficulty.easy)
        'stage2_plus_triple': [
          ...TargetClashRuntimeState.resolveRequests(
            operation: operation,
            difficulty: difficulty,
            numberType: numberType,
            phase: TargetClashRequestProfilePhase.ordinaryStage2,
          ),
          ...TargetClashRuntimeState.tripleRequests(0)!,
        ],
    };

/// Mirrors Target Clash's typed zone/relation grid against the canonical result
/// domain only. This is intentionally a test-local oracle: it does not call
/// prepareStageForTarget, materializeForTarget, buildDirectForResult, or RNG.
List<num> _feasibleTargets({
  required List<num> domain,
  required Difficulty difficulty,
  required NumberType numberType,
  required List<TargetClashQuestionRequest> requests,
}) {
  final domainSet = domain.toSet();
  return [
    for (final target in domain)
      if (requests.every(
        (request) => _candidateResults(
          target: target,
          difficulty: difficulty,
          numberType: numberType,
          request: request,
        ).any(domainSet.contains),
      ))
        target,
  ];
}

Iterable<num> _candidateResults({
  required num target,
  required Difficulty difficulty,
  required NumberType numberType,
  required TargetClashQuestionRequest request,
}) sync* {
  final distances = switch (request.zone) {
    TargetZone.danger => const [1],
    TargetZone.closeCall => const [2, 3],
    TargetZone.normal => const [4, 5, 6],
    TargetZone.bullseye => const [0],
  };
  final direction = request.answer == PresentationAnswer.lessThan ? -1 : 1;
  if (numberType == NumberType.rationals) {
    final decimalPlaces = switch (difficulty) {
      Difficulty.easy || Difficulty.medium => 1,
      Difficulty.hard => 2,
      _ => throw ArgumentError.value(difficulty, 'difficulty'),
    };
    final factor = switch (decimalPlaces) {
      1 => 10,
      2 => 100,
      _ => throw StateError('Unsupported decimal precision: $decimalPlaces'),
    };
    final targetTick = (target * factor).round();
    for (final distance in distances) {
      yield (targetTick + direction * distance) / factor;
    }
    return;
  }
  for (final distance in distances) {
    yield target + direction * distance;
  }
}

_ProfileFeasibility _profileFeasibility({
  required Operation operation,
  required Difficulty difficulty,
  required NumberType numberType,
  required String profile,
  required List<num> domain,
  required List<TargetClashQuestionRequest> requests,
}) {
  final domainSet = domain.toSet();
  var survivors = List<num>.of(domain);
  final survivorCounts = <int>[survivors.length];
  int? firstEliminatingRequestIndex;
  TargetClashQuestionRequest? firstEliminatingRequest;
  List<num>? survivorsBeforeElimination;

  for (var index = 0; index < requests.length; index++) {
    final request = requests[index];
    final before = survivors;
    survivors = [
      for (final target in before)
        if (_candidateResults(
          target: target,
          difficulty: difficulty,
          numberType: numberType,
          request: request,
        ).any(domainSet.contains))
          target,
    ];
    survivorCounts.add(survivors.length);
    if (survivors.isEmpty && firstEliminatingRequestIndex == null) {
      firstEliminatingRequestIndex = index;
      firstEliminatingRequest = request;
      survivorsBeforeElimination = before.take(10).toList();
    }
  }

  return _ProfileFeasibility(
    operation: operation,
    difficulty: difficulty,
    numberType: numberType,
    profile: profile,
    domainSize: domain.length,
    feasibleTargetCount: survivors.length,
    requests: requests,
    survivorCounts: survivorCounts,
    firstEliminatingRequestIndex: firstEliminatingRequestIndex,
    firstEliminatingRequest: firstEliminatingRequest,
    survivorsBeforeElimination: survivorsBeforeElimination ?? const [],
  );
}

String _zeroFeasibleReport(List<_ProfileFeasibility> profiles) => profiles
    .map((profile) => profile.toDetailReport())
    .join('\n\n');

class _ProfileFeasibility {
  const _ProfileFeasibility({
    required this.operation,
    required this.difficulty,
    required this.numberType,
    required this.profile,
    required this.domainSize,
    required this.feasibleTargetCount,
    required this.requests,
    required this.survivorCounts,
    required this.firstEliminatingRequestIndex,
    required this.firstEliminatingRequest,
    required this.survivorsBeforeElimination,
  });

  final Operation operation;
  final Difficulty difficulty;
  final NumberType numberType;
  final String profile;
  final int domainSize;
  final int feasibleTargetCount;
  final List<TargetClashQuestionRequest> requests;
  final List<int> survivorCounts;
  final int? firstEliminatingRequestIndex;
  final TargetClashQuestionRequest? firstEliminatingRequest;
  final List<num> survivorsBeforeElimination;

  String toCsvRow() => [
        operation.name,
        difficulty.name,
        numberType.name,
        profile,
        '$domainSize',
        '$feasibleTargetCount',
        '${firstEliminatingRequestIndex ?? ''}',
        firstEliminatingRequest?.answer.name ?? '',
        firstEliminatingRequest?.zone.name ?? '',
      ].map(_csvField).join(',');

  String toDetailReport() => [
        'PROFILE = ${operation.name} / ${difficulty.name} / '
            '${numberType.name} / $profile',
        'DOMAIN_SIZE = $domainSize',
        'REQUEST_SEQUENCE =',
        for (var index = 0; index < requests.length; index++)
          '  $index: relation=${requests[index].answer.name} '
              'zone=${requests[index].zone.name}',
        'SURVIVOR_COUNTS = ${survivorCounts.join(', ')}',
        'FIRST_ELIMINATING_REQUEST_INDEX = $firstEliminatingRequestIndex',
        'FIRST_ELIMINATING_REQUEST_RELATION = '
            '${firstEliminatingRequest?.answer.name}',
        'FIRST_ELIMINATING_REQUEST_ZONE = '
            '${firstEliminatingRequest?.zone.name}',
        'SURVIVORS_BEFORE_ELIMINATION = $survivorsBeforeElimination',
      ].join('\n');
}

String _csvField(String value) => '"${value.replaceAll('"', '""')}"';
