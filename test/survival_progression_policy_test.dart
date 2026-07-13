import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/gameplay/domain/survival_progression_policy.dart';

void main() {
  const policy = SurvivalProgressionPolicy();

  test('correct count maps to the frozen phase and boss cadence', () {
    for (final testCase in const [
      (correctCount: 1, phase: 0, bossDue: false),
      (correctCount: 4, phase: 0, bossDue: false),
      (correctCount: 5, phase: 1, bossDue: false),
      (correctCount: 9, phase: 1, bossDue: false),
      (correctCount: 10, phase: 2, bossDue: true),
      (correctCount: 19, phase: 3, bossDue: false),
      (correctCount: 20, phase: 4, bossDue: true),
      (correctCount: 25, phase: 4, bossDue: false),
      (correctCount: 30, phase: 4, bossDue: true),
    ]) {
      expect(
        policy.afterCorrect(testCase.correctCount),
        (phase: testCase.phase, bossDue: testCase.bossDue),
        reason: 'correctCount ${testCase.correctCount}',
      );
    }
  });
}
