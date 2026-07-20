import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/weak_skills/domain/weak_skills_policy.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';

void main() {
  group('Weak Skills policy', () {
    test('uses evidence thresholds at the exact boundaries', () {
      expect(
        selectWeakSkillsPlan(_skills([10, 20, 30, 40], [3, 3, 2, 1]))
            .isFallback,
        isTrue,
        reason: 'nine total attempts must fall back',
      );
      expect(
        selectWeakSkillsPlan(_skills([10, 20, 30, 40], [3, 3, 2, 2]))
            .isFallback,
        isFalse,
        reason: 'ten total attempts can focus',
      );
      expect(
        selectWeakSkillsPlan(_skills([0, 20, 40, 50], [2, 5, 3, 0]))
            .focusedOperations,
        [Operation.subtraction, Operation.multiplication],
        reason: 'count two is ineligible and count three is eligible',
      );
      expect(
        selectWeakSkillsPlan(_skills([10, 19.9, 30, 40], [3, 3, 2, 2]))
            .isFallback,
        isTrue,
      );
      expect(
        selectWeakSkillsPlan(_skills([10, 20, 30, 40], [3, 3, 2, 2]))
            .isFallback,
        isFalse,
      );
    });

    test('implements tie policies A through F deterministically', () {
      expect(
        selectWeakSkillsPlan(_skills([20, 20, 20, 20], [3, 3, 3, 3]))
            .isFallback,
        isTrue,
      );

      final tiedWeakest =
          selectWeakSkillsPlan(_skills([10, 10, 25, 30], [3, 3, 3, 3]));
      expect(tiedWeakest.isFallback, isFalse);
      expect(
        tiedWeakest.operationCycle,
        [
          for (var i = 0; i < 10; i++) ...[
            Operation.addition,
            Operation.subtraction
          ],
        ],
      );

      expect(
        selectWeakSkillsPlan(_skills([10, 10, 10, 30], [3, 3, 3, 3]))
            .isFallback,
        isTrue,
      );

      expect(
        selectWeakSkillsPlan(_skills([5, 20, 20, 40], [3, 3, 3, 3]))
            .focusedOperations,
        [Operation.addition, Operation.subtraction],
      );

      expect(
        selectWeakSkillsPlan(_skills([5, 20, 30, 40], [10, 0, 0, 0]))
            .isFallback,
        isTrue,
      );
      expect(
        selectWeakSkillsPlan(_skills([5, 15, 30, 40], [5, 5, 0, 0])).isFallback,
        isFalse,
      );
      expect(
        selectWeakSkillsPlan(_skills([5, 14.9, 30, 40], [5, 5, 0, 0]))
            .isFallback,
        isTrue,
      );
    });

    test('builds deterministic focused, tied, and fallback cycles', () {
      final focused =
          selectWeakSkillsPlan(_skills([5, 20, 30, 40], [3, 3, 3, 3]));
      expect(focused.operationCycle, hasLength(20));
      expect(
        focused.operationCycle.where((op) => op == Operation.addition),
        hasLength(13),
      );
      expect(
        focused.operationCycle.where((op) => op == Operation.subtraction),
        hasLength(7),
      );
      expect(
        selectWeakSkillsPlan(_skills([5, 20, 30, 40], [3, 3, 3, 3]))
            .operationCycle,
        focused.operationCycle,
      );

      final tied = selectWeakSkillsPlan(_skills([5, 5, 30, 40], [3, 3, 3, 3]));
      expect(tied.operationCycle, hasLength(20));
      expect(tied.operationCycle.toSet(), {
        Operation.addition,
        Operation.subtraction,
      });
      expect(
        tied.operationCycle.where((op) => op == Operation.addition),
        hasLength(10),
      );

      final fallback =
          selectWeakSkillsPlan(_skills([20, 20, 20, 20], [0, 0, 0, 0]));
      expect(fallback.operationCycle, [
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
      ]);
      expect(fallback.operationAt(5), Operation.subtraction);
    });

    test('does not mutate the input map and exposes immutable cycles', () {
      final input = _skills([5, 20, 30, 40], [3, 3, 3, 3]);
      final before = {
        for (final entry in input.entries) entry.key: entry.value.toJson(),
      };
      final plan = selectWeakSkillsPlan(input);

      expect(
        {for (final entry in input.entries) entry.key: entry.value.toJson()},
        before,
      );
      expect(() => plan.operationCycle.add(Operation.division),
          throwsUnsupportedError);
      expect(plan.focusedOperations, [
        Operation.addition,
        Operation.subtraction,
      ]);
    });
  });
}

Map<String, SkillData> _skills(List<double> mastery, List<int> counts) => {
      for (var i = 0; i < _operations.length; i++)
        _operations[i].name: SkillData(
          mastery: mastery[i],
          count: counts[i],
        ),
    };

const _operations = [
  Operation.addition,
  Operation.subtraction,
  Operation.multiplication,
  Operation.division,
];
