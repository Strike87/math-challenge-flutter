import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/adaptive/domain/adaptive_difficulty_engine.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const engine = AdaptiveDifficultyEngine();

  test('empty mastery collection returns zero levels', () {
    final level = engine.levelFromMasteries(const []);

    expect(level.raw, 0);
    expect(level.level, 0);
  });

  test('zero mastery uses the default mastery value', () {
    final level = engine.levelFromMasteries(const [0]);

    expect(level.raw, 2);
    expect(level.level, 2);
  });

  test('mean mastery preserves raw and rounded levels', () {
    final level = engine.levelFromMasteries(const [95, 20, 20, 20]);

    expect(level.raw, 3.875);
    expect(level.level, 4);
  });

  test('rounded adaptive level retains the upper cap', () {
    final level = engine.levelFromMasteries(const [110]);

    expect(level.raw, 11);
    expect(level.level, 10);
  });

  test('mastery thresholds map directly without conversion or clamping', () {
    for (final testCase in const [
      (mastery: -1.0, difficulty: Difficulty.easy),
      (mastery: 0.0, difficulty: Difficulty.easy),
      (mastery: 44.999, difficulty: Difficulty.easy),
      (mastery: 45.0, difficulty: Difficulty.medium),
      (mastery: 45.001, difficulty: Difficulty.medium),
      (mastery: 64.999, difficulty: Difficulty.medium),
      (mastery: 65.0, difficulty: Difficulty.hard),
      (mastery: 65.001, difficulty: Difficulty.hard),
      (mastery: 81.999, difficulty: Difficulty.hard),
      (mastery: 82.0, difficulty: Difficulty.expert),
      (mastery: 82.001, difficulty: Difficulty.expert),
      (mastery: 92.999, difficulty: Difficulty.expert),
      (mastery: 93.0, difficulty: Difficulty.insane),
      (mastery: 93.001, difficulty: Difficulty.insane),
      (mastery: 101.0, difficulty: Difficulty.insane),
    ]) {
      expect(
        engine.difficultyForMastery(testCase.mastery),
        testCase.difficulty,
        reason: 'mastery ${testCase.mastery}',
      );
    }
  });

  for (final testCase in const [
    (milliseconds: 1499, mastery: 57.0),
    (milliseconds: 1500, mastery: 55.0),
    (milliseconds: 2999, mastery: 55.0),
    (milliseconds: 3000, mastery: 53.0),
  ]) {
    test('correct at ${testCase.milliseconds}ms uses the frozen gain', () {
      final update = engine.calculateMasteryUpdate(
        currentMastery: 50,
        currentConfidence: 50,
        outcome: MasteryOutcome.correct,
        responseMilliseconds: testCase.milliseconds,
      );

      expect(update.mastery, testCase.mastery);
    });
  }

  for (final testCase in const [
    (outcome: MasteryOutcome.wrong, mastery: 46.0),
    (outcome: MasteryOutcome.timeout, mastery: 48.0),
  ]) {
    test('${testCase.outcome.name} uses the frozen penalty', () {
      final update = engine.calculateMasteryUpdate(
        currentMastery: 50,
        currentConfidence: 50,
        outcome: testCase.outcome,
        responseMilliseconds: 4000,
      );

      expect(update.mastery, testCase.mastery);
    });
  }

  test('mastery retains its lower clamp', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 1,
      currentConfidence: 50,
      outcome: MasteryOutcome.wrong,
      responseMilliseconds: 4000,
    );

    expect(update.mastery, 0);
  });

  test('mastery retains its upper clamp', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 98,
      currentConfidence: 50,
      outcome: MasteryOutcome.correct,
      responseMilliseconds: 1000,
    );

    expect(update.mastery, 100);
  });

  test('zero mastery uses 20 before applying the delta', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 0,
      currentConfidence: 50,
      outcome: MasteryOutcome.correct,
      responseMilliseconds: 1000,
    );

    expect(update.mastery, 27);
  });

  test('zero confidence uses 50 before applying the EMA', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 50,
      currentConfidence: 0,
      outcome: MasteryOutcome.correct,
      responseMilliseconds: 1400,
    );

    expect(update.confidence, 60);
  });

  test('zero response uses 5000ms for confidence only', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 50,
      currentConfidence: 50,
      outcome: MasteryOutcome.correct,
      responseMilliseconds: 0,
    );

    expect(update.mastery, 57);
    expect(update.confidence, 52);
  });

  test('speed score retains its zero floor', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 50,
      currentConfidence: 80,
      outcome: MasteryOutcome.wrong,
      responseMilliseconds: 15000,
    );

    expect(update.confidence, 60);
  });

  test('negative response keeps confidence above 100 and rounded', () {
    final update = engine.calculateMasteryUpdate(
      currentMastery: 50,
      currentConfidence: 100,
      outcome: MasteryOutcome.correct,
      responseMilliseconds: -1200,
    );

    expect(update.confidence, 103);
  });
}
