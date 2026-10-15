import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';

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
  const phases = [
    TargetClashRequestProfilePhase.ordinaryStage1,
    TargetClashRequestProfilePhase.ordinaryStage2,
    TargetClashRequestProfilePhase.boss,
    TargetClashRequestProfilePhase.finalTarget,
  ];

  test('R3D04A applies exactly the approved eight typed overrides', () {
    final changed = <String>[];
    var resolvedRows = 0;
    for (final operation in operations) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          for (final phase in phases) {
            final resolved = TargetClashRuntimeState.resolveRequests(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
              phase: phase,
            );
            final base = _base(difficulty, phase);
            if (!_sameRequests(resolved, base)) {
              changed.add(_rowKey(operation, difficulty, numberType, phase));
            }
            resolvedRows++;
          }
          if (difficulty != Difficulty.easy) {
            final resolved = _stage2PlusTriple(
              operation: operation,
              difficulty: difficulty,
              numberType: numberType,
            );
            final baseline = [
              ..._base(
                difficulty,
                TargetClashRequestProfilePhase.ordinaryStage2,
              ),
              ...TargetClashRuntimeState.tripleRequests(0)!,
            ];
            if (!_sameRequests(resolved, baseline)) {
              changed.add(
                '${operation.name}/${difficulty.name}/${numberType.name}/'
                'stage2_plus_triple',
              );
            }
            resolvedRows++;
          }
        }
      }
    }

    expect(TargetClashRuntimeState.profileOverrides, hasLength(8));
    expect(resolvedRows, 168);
    expect(changed, unorderedEquals(_approvedChangedRows));
    expect(changed, hasLength(8));
  });

  test('R3D04A override sequences exactly match the design freeze', () {
    for (final entry in _approvedOverrides.entries) {
      expect(
        TargetClashRuntimeState.resolveRequests(
          operation: entry.key.operation,
          difficulty: entry.key.difficulty,
          numberType: entry.key.numberType,
          phase: entry.key.phase,
        ),
        _requestMatcher(entry.value),
        reason: _rowKey(
          entry.key.operation,
          entry.key.difficulty,
          entry.key.numberType,
          entry.key.phase,
        ),
      );
    }
  });

  test('R3D04A leaves required non-overridden rows and Triple unchanged', () {
    expect(
      TargetClashRuntimeState.resolveRequests(
        operation: Operation.multiplication,
        difficulty: Difficulty.hard,
        numberType: NumberType.rationals,
        phase: TargetClashRequestProfilePhase.boss,
      ),
      _requestMatcher(TargetClashRuntimeState.bossRequests(Difficulty.hard)),
    );
    for (final phase in phases) {
      expect(
        TargetClashRuntimeState.resolveRequests(
          operation: Operation.division,
          difficulty: Difficulty.easy,
          numberType: NumberType.rationals,
          phase: phase,
        ),
        _requestMatcher(_base(Difficulty.easy, phase)),
      );
    }
    for (final operation in [Operation.addition, Operation.subtraction]) {
      for (final difficulty in difficulties) {
        for (final numberType in numberTypes) {
          for (final phase in phases) {
            expect(
              TargetClashRuntimeState.resolveRequests(
                operation: operation,
                difficulty: difficulty,
                numberType: numberType,
                phase: phase,
              ),
              _requestMatcher(_base(difficulty, phase)),
            );
          }
        }
      }
    }
    for (var index = 0; index < _triplePermutations.length; index++) {
      expect(
        TargetClashRuntimeState.tripleRequests(index)!
            .map(_requestLabel)
            .toList(),
        _triplePermutations[index],
        reason: 'Triple permutation $index remains canonical',
      );
    }
  });
}

List<TargetClashQuestionRequest> _base(
  Difficulty difficulty,
  TargetClashRequestProfilePhase phase,
) => switch (phase) {
      TargetClashRequestProfilePhase.ordinaryStage1 =>
        TargetClashRuntimeState.ordinaryRequests(difficulty, 1),
      TargetClashRequestProfilePhase.ordinaryStage2 =>
        TargetClashRuntimeState.ordinaryRequests(difficulty, 2),
      TargetClashRequestProfilePhase.boss =>
        TargetClashRuntimeState.bossRequests(difficulty),
      TargetClashRequestProfilePhase.finalTarget =>
        TargetClashRuntimeState.finalRequests(difficulty),
    };

bool _sameRequests(
  List<TargetClashQuestionRequest> left,
  List<TargetClashQuestionRequest> right,
) =>
    left.length == right.length &&
    List.generate(
      left.length,
      (index) =>
          left[index].answer == right[index].answer &&
          left[index].zone == right[index].zone,
    )
        .every((same) => same);

Matcher _requestMatcher(List<TargetClashQuestionRequest> requests) =>
    predicate<List<TargetClashQuestionRequest>>(
      (actual) => _sameRequests(actual, requests),
      'matches the approved request sequence',
    );

List<TargetClashQuestionRequest> _stage2PlusTriple({
  required Operation operation,
  required Difficulty difficulty,
  required NumberType numberType,
}) => [
      ...TargetClashRuntimeState.resolveRequests(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        phase: TargetClashRequestProfilePhase.ordinaryStage2,
      ),
      ...TargetClashRuntimeState.tripleRequests(0)!,
    ];

String _requestLabel(TargetClashQuestionRequest request) =>
    '${request.answer.name}/${request.zone.name}';

String _rowKey(
  Operation operation,
  Difficulty difficulty,
  NumberType numberType,
  TargetClashRequestProfilePhase phase,
) => '${operation.name}/${difficulty.name}/${numberType.name}/${phase.name}';

const _approvedChangedRows = [
  'multiplication/hard/natural/boss',
  'multiplication/hard/integers/boss',
  'division/easy/natural/ordinaryStage1',
  'division/easy/natural/ordinaryStage2',
  'division/easy/natural/boss',
  'division/easy/natural/finalTarget',
  'division/easy/integers/ordinaryStage1',
  'division/easy/integers/ordinaryStage2',
];

const _triplePermutations = [
  ['lessThan/normal', 'equalTo/bullseye', 'greaterThan/normal'],
  ['lessThan/normal', 'greaterThan/normal', 'equalTo/bullseye'],
  ['equalTo/bullseye', 'lessThan/normal', 'greaterThan/normal'],
  ['equalTo/bullseye', 'greaterThan/normal', 'lessThan/normal'],
  ['greaterThan/normal', 'lessThan/normal', 'equalTo/bullseye'],
  ['greaterThan/normal', 'equalTo/bullseye', 'lessThan/normal'],
];

final _approvedOverrides = Map<TargetClashProfileOverrideKey,
    List<TargetClashQuestionRequest>>.unmodifiable({
  const TargetClashProfileOverrideKey(
    operation: Operation.multiplication,
    difficulty: Difficulty.hard,
    numberType: NumberType.natural,
    phase: TargetClashRequestProfilePhase.boss,
  ): const [_ln, _gc, _ld, _gc, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.multiplication,
    difficulty: Difficulty.hard,
    numberType: NumberType.integers,
    phase: TargetClashRequestProfilePhase.boss,
  ): const [_ln, _gc, _ld, _gc, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.division,
    difficulty: Difficulty.easy,
    numberType: NumberType.natural,
    phase: TargetClashRequestProfilePhase.ordinaryStage1,
  ): const [_ld, _gd, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.division,
    difficulty: Difficulty.easy,
    numberType: NumberType.natural,
    phase: TargetClashRequestProfilePhase.ordinaryStage2,
  ): const [_gd, _ld, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.division,
    difficulty: Difficulty.easy,
    numberType: NumberType.natural,
    phase: TargetClashRequestProfilePhase.boss,
  ): const [_ld, _gd, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.division,
    difficulty: Difficulty.easy,
    numberType: NumberType.natural,
    phase: TargetClashRequestProfilePhase.finalTarget,
  ): const [_ld, _gc, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.division,
    difficulty: Difficulty.easy,
    numberType: NumberType.integers,
    phase: TargetClashRequestProfilePhase.ordinaryStage1,
  ): const [_ln, _gd, _eq],
  const TargetClashProfileOverrideKey(
    operation: Operation.division,
    difficulty: Difficulty.easy,
    numberType: NumberType.integers,
    phase: TargetClashRequestProfilePhase.ordinaryStage2,
  ): const [_gn, _ld, _eq],
});

const _eq = TargetClashQuestionRequest(
  answer: PresentationAnswer.equalTo,
  zone: TargetZone.bullseye,
);
const _gd = TargetClashQuestionRequest(
  answer: PresentationAnswer.greaterThan,
  zone: TargetZone.danger,
);
const _ld = TargetClashQuestionRequest(
  answer: PresentationAnswer.lessThan,
  zone: TargetZone.danger,
);
const _gc = TargetClashQuestionRequest(
  answer: PresentationAnswer.greaterThan,
  zone: TargetZone.closeCall,
);
const _ln = TargetClashQuestionRequest(
  answer: PresentationAnswer.lessThan,
  zone: TargetZone.normal,
);
const _gn = TargetClashQuestionRequest(
  answer: PresentationAnswer.greaterThan,
  zone: TargetZone.normal,
);
