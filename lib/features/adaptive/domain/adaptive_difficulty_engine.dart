import 'dart:math';

enum MasteryOutcome { correct, wrong, timeout }

class AdaptiveDifficultyEngine {
  const AdaptiveDifficultyEngine();

  static const double defaultMastery = 20;
  static const double maxMastery = 100;
  static const int _fastResponseMilliseconds = 1500;
  static const int _normalResponseMilliseconds = 3000;
  static const double _fastMasteryGain = 7;
  static const double _normalMasteryGain = 5;
  static const double _slowMasteryGain = 3;
  static const double _wrongMasteryPenalty = -4;
  static const double _timeoutMasteryPenalty = -2;
  static const double _defaultConfidence = 50;
  static const int _defaultConfidenceMilliseconds = 5000;
  static const double _confidenceSpeedDivisor = 120;
  static const double _confidenceEmaAlpha = 0.25;

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

  ({double mastery, double confidence}) calculateMasteryUpdate({
    required double currentMastery,
    required double currentConfidence,
    required MasteryOutcome outcome,
    required int responseMilliseconds,
  }) {
    final masteryDelta = switch (outcome) {
      MasteryOutcome.correct
          when responseMilliseconds < _fastResponseMilliseconds =>
        _fastMasteryGain,
      MasteryOutcome.correct
          when responseMilliseconds < _normalResponseMilliseconds =>
        _normalMasteryGain,
      MasteryOutcome.correct => _slowMasteryGain,
      MasteryOutcome.wrong => _wrongMasteryPenalty,
      MasteryOutcome.timeout => _timeoutMasteryPenalty,
    };
    final baseMastery = currentMastery == 0 ? defaultMastery : currentMastery;
    final mastery = max(0.0, min(maxMastery, baseMastery + masteryDelta));

    final effectiveMilliseconds = responseMilliseconds == 0
        ? _defaultConfidenceMilliseconds
        : responseMilliseconds;
    final speedScore =
        max(0.0, 100 - (effectiveMilliseconds / _confidenceSpeedDivisor));
    final baseConfidence =
        currentConfidence == 0 ? _defaultConfidence : currentConfidence;
    final confidence = (baseConfidence * (1 - _confidenceEmaAlpha) +
            speedScore * _confidenceEmaAlpha)
        .roundToDouble();

    return (mastery: mastery, confidence: confidence);
  }
}
