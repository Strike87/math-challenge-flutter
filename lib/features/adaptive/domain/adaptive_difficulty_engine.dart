import 'dart:math';

class AdaptiveDifficultyEngine {
  const AdaptiveDifficultyEngine();

  static const double defaultMastery = 20;

  ({double raw, int level}) levelFromMasteries(
    Iterable<double> masteries,
  ) {
    var total = 0.0;
    var count = 0;
    for (final mastery in masteries) {
      total += mastery == 0 ? defaultMastery : mastery;
      count++;
    }
    if (count == 0) return (raw: 0, level: 0);

    final raw = (total / count / 100) * 10;
    return (raw: raw, level: min(10, raw.round()));
  }
}
