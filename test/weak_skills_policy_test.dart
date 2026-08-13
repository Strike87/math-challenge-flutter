import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/domain/brain_recommendation.dart';
import 'package:math_challenge/features/game_brain/domain/learner_hypothesis.dart';
import 'package:math_challenge/features/weak_skills/domain/weak_skills_policy.dart';
import 'package:math_challenge/features/weak_skills/domain/weak_skills_advisory_signal.dart';
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

    test('advisory reinforces one exact eligible two-way weakest tie', () {
      final advisory = _advisory(
        targetOperation: Operation.subtraction,
      );
      final plan = selectWeakSkillsPlan(
        _skills([5, 5, 30, 40], [3, 3, 3, 3]),
        advisory: advisory,
      );

      expect(plan.advisory, same(advisory));
      expect(plan.advisory?.recommendationType,
          BrainRecommendationType.reinforceOperation);
      expect(plan.advisory?.recommendationReason,
          BrainRecommendationReason.repeatedMisconception);
      expect(plan.advisory?.learnerHypothesis,
          LearnerHypothesis.repeatedMisconception);
      expect(plan.advisory?.supportingObservationCount, 2);
      expect(plan.operationCycle.where((op) => op == Operation.subtraction),
          hasLength(13));
      expect(plan.operationCycle.where((op) => op == Operation.addition),
          hasLength(7));
    });

    test(
        'invalid advisory leaves existing ties, unique focus, and fallback unchanged',
        () {
      final advisory = _advisory(
        targetOperation: Operation.multiplication,
      );
      final tied = selectWeakSkillsPlan(
        _skills([5, 5, 30, 40], [3, 3, 3, 3]),
        advisory: advisory,
      );
      expect(tied.advisory, isNull);
      expect(tied.operationCycle.where((op) => op == Operation.addition),
          hasLength(10));
      expect(tied.operationCycle.where((op) => op == Operation.subtraction),
          hasLength(10));

      final unique = selectWeakSkillsPlan(
        _skills([5, 20, 30, 40], [3, 3, 3, 3]),
        advisory: advisory,
      );
      expect(unique.advisory, isNull);
      expect(unique.operationCycle.where((op) => op == Operation.addition),
          hasLength(13));

      final fallback = selectWeakSkillsPlan(
        _skills([20, 20, 20, 20], [0, 0, 0, 0]),
        advisory: advisory,
      );
      expect(fallback.advisory, isNull);
      expect(fallback.isFallback, isTrue);
    });

    test('mismatched advisory metadata leaves a two-way tie balanced', () {
      final plan = selectWeakSkillsPlan(
        _skills([5, 5, 30, 40], [3, 3, 3, 3]),
        advisory: _advisory(
          targetOperation: Operation.addition,
          recommendationType: BrainRecommendationType.maintain,
        ),
      );

      expect(plan.advisory, isNull);
      expect(plan.operationCycle.where((op) => op == Operation.addition),
          hasLength(10));
      expect(plan.operationCycle.where((op) => op == Operation.subtraction),
          hasLength(10));
    });

    test('targeting an ineligible two-way tie leaves canonical focus unchanged',
        () {
      final plan = selectWeakSkillsPlan(
        _skills([5, 5, 30, 40], [2, 3, 3, 3]),
        advisory: _advisory(targetOperation: Operation.addition),
      );

      expect(plan.isFallback, isFalse);
      expect(plan.advisory, isNull);
      expect(plan.operationCycle.where((op) => op == Operation.subtraction),
          hasLength(13));
      expect(plan.operationCycle.where((op) => op == Operation.multiplication),
          hasLength(7));
    });

    test(
        'an ineligible two-way tie falls back when only one operation qualifies',
        () {
      final plan = selectWeakSkillsPlan(
        _skills([5, 5, 30, 40], [2, 8, 0, 0]),
        advisory: _advisory(targetOperation: Operation.addition),
      );

      expect(plan.isFallback, isTrue);
      expect(plan.advisory, isNull);
      expect(plan.operationCycle, _operations);
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

WeakSkillsAdvisorySignal _advisory({
  required Operation targetOperation,
  BrainRecommendationType recommendationType =
      BrainRecommendationType.reinforceOperation,
}) =>
    WeakSkillsAdvisorySignal(
      targetOperation: targetOperation,
      recommendationType: recommendationType,
      recommendationReason: BrainRecommendationReason.repeatedMisconception,
      learnerHypothesis: LearnerHypothesis.repeatedMisconception,
      supportingObservationCount: 2,
    );
