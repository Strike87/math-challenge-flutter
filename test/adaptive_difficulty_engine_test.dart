import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/adaptive/domain/adaptive_difficulty_engine.dart';

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
}
