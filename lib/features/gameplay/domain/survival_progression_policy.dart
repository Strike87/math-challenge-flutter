import 'dart:math';

class SurvivalProgressionPolicy {
  const SurvivalProgressionPolicy();

  ({int phase, bool bossDue}) afterCorrect(int correctCount) => (
        phase: min(correctCount ~/ 5, 4),
        bossDue: correctCount % 10 == 0,
      );
}
