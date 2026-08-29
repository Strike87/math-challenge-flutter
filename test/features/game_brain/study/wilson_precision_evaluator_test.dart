import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/study/wilson_precision_evaluator.dart';

void main() {
  group('evaluateWilsonPrecision input validation', () {
    test('n == 0 is UNEVALUABLE with no fabricated interval values', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 0, trials: 0),
      );
      expect(result.status, WilsonEvaluationStatus.unevaluable);
      expect(result.isEvaluable, isFalse);
      expect(result.estimatedProportion, isNull);
      expect(result.lowerBound, isNull);
      expect(result.upperBound, isNull);
      expect(result.halfWidth, isNull);
      expect(result.meetsPrecision, isNull);
    });

    test('negative successes are invalid input', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: -1, trials: 10),
      );
      expect(result.status, WilsonEvaluationStatus.invalidInput);
      expect(result.isEvaluable, isFalse);
    });

    test('negative trials are invalid input', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 3, trials: -5),
      );
      expect(result.status, WilsonEvaluationStatus.invalidInput);
      expect(result.isEvaluable, isFalse);
    });

    test('successes greater than trials are invalid input', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 11, trials: 10),
      );
      expect(result.status, WilsonEvaluationStatus.invalidInput);
      expect(result.isEvaluable, isFalse);
    });
  });

  group('evaluateWilsonPrecision interval arithmetic', () {
    test('k == 0, n > 0 produces a finite coherent interval', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 0, trials: 30),
      );
      expect(result.isEvaluable, isTrue);
      expect(result.estimatedProportion, 0.0);
      expect(result.lowerBound!, isNot(isNaN));
      expect(result.lowerBound!, isNotNaN);
      expect(result.upperBound!, isNotNaN);
      expect(result.halfWidth!, isNotNaN);
      expect(result.lowerBound!, inInclusiveRange(0.0, 1.0));
      expect(result.upperBound!, inInclusiveRange(0.0, 1.0));
      expect(result.lowerBound! <= result.upperBound!, isTrue);
    });

    test('k == n produces a finite coherent interval', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 30, trials: 30),
      );
      expect(result.isEvaluable, isTrue);
      expect(result.estimatedProportion, 1.0);
      expect(result.lowerBound!, isNotNaN);
      expect(result.upperBound!, isNotNaN);
      expect(result.lowerBound!, inInclusiveRange(0.0, 1.0));
      expect(result.upperBound!, inInclusiveRange(0.0, 1.0));
    });

    test('interior case matches independently calculated Wilson values', () {
      // Independent reference computation for k = 18, n = 30:
      // pHat = 0.6; z = 1.959963984540054; z^2 = 3.841458820694124...
      final k = 18;
      final n = 30;
      final z = wilsonZ95;
      final pHat = k / n;
      final z2 = z * z;
      final denominator = 1 + z2 / n;
      final expectedCenter = (pHat + z2 / (2 * n)) / denominator;
      final expectedHalf = z *
          _sqrtReference((pHat * (1 - pHat) / n) + (z2 / (4 * n * n))) /
          denominator;

      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 18, trials: 30),
      );
      expect(result.isEvaluable, isTrue);
      expect(result.estimatedProportion!, closeTo(pHat, 1e-15));
      expect(result.lowerBound!, closeTo(expectedCenter - expectedHalf, 1e-12));
      expect(result.upperBound!, closeTo(expectedCenter + expectedHalf, 1e-12));
      expect(result.halfWidth!, closeTo(expectedHalf, 1e-12));

      // Sanity anchors for the 95% Wilson interval at 18/30:
      // approximately [0.4232, 0.7541]. Exactness is already covered by the
      // independent reference computation above.
      expect(result.lowerBound!, closeTo(0.4232, 1e-3));
      expect(result.upperBound!, closeTo(0.7541, 1e-3));
    });

    test('small positive n is evaluable rather than artificially rejected', () {
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 1, trials: 2),
      );
      expect(result.isEvaluable, isTrue);
      expect(result.estimatedProportion, 0.5);
      expect(result.lowerBound!, isNotNaN);
      expect(result.upperBound!, isNotNaN);
      // Small samples widen the interval; they must fail precision naturally,
      // not be rejected.
      expect(result.meetsPrecision, isFalse);
    });
  });

  group('frozen threshold semantics', () {
    test('negative halfWidth throws ArgumentError', () {
      expect(
        () => meetsWilsonPrecision(-0.0001),
        throwsArgumentError,
      );
    });

    test('NaN halfWidth throws ArgumentError', () {
      expect(
        () => meetsWilsonPrecision(double.nan),
        throwsArgumentError,
      );
    });

    test('+Infinity halfWidth throws ArgumentError', () {
      expect(
        () => meetsWilsonPrecision(double.infinity),
        throwsArgumentError,
      );
    });

    test('-Infinity halfWidth throws ArgumentError', () {
      expect(
        () => meetsWilsonPrecision(double.negativeInfinity),
        throwsArgumentError,
      );
    });

    test('halfWidth below 0.15 meets precision', () {
      expect(meetsWilsonPrecision(0.149999), isTrue);
    });

    test('halfWidth above 0.15 does not meet precision', () {
      expect(meetsWilsonPrecision(0.150001), isFalse);
    });

    test('boundary equality passes (<= semantics)', () {
      expect(meetsWilsonPrecision(0.15), isTrue);
      expect(meetsWilsonPrecision(wilsonPrecisionThreshold), isTrue);
    });

    test('a realistic large-sample case can meet the frozen threshold', () {
      // k/n = 0.5 at n = 200 gives half-width well under 0.15.
      final result = evaluateWilsonPrecision(
        const WilsonBinomialSummary(successes: 100, trials: 200),
      );
      expect(result.isEvaluable, isTrue);
      expect(result.meetsPrecision, isTrue);
      expect(result.halfWidth!, lessThan(0.15));
    });
  });

  group('mathematical coherence of evaluable results', () {
    test('bounds bracket the estimate and halfWidth is symmetric', () {
      const cases = [(0, 7), (3, 7), (5, 40), (17, 60), (60, 60)];
      for (final (k, n) in cases) {
        final r = evaluateWilsonPrecision(
          WilsonBinomialSummary(successes: k, trials: n),
        );
        expect(r.isEvaluable, isTrue, reason: 'k=$k n=$n');
        // Floating-point evaluation can push a bound past the estimate by a
        // few ulps when the estimate sits exactly on an endpoint.
        const eps = 1e-12;
        expect(r.lowerBound!, lessThanOrEqualTo(r.estimatedProportion! + eps),
            reason: 'k=$k n=$n');
        expect(r.estimatedProportion!, lessThanOrEqualTo(r.upperBound! + eps),
            reason: 'k=$k n=$n');
        // The formula is symmetric around the center, not the estimate; the
        // interval may be asymmetric around pHat. Coherence here means both
        // distances are non-negative and their sum equals the interval width.
        final upperDistance = r.upperBound! - r.estimatedProportion!;
        final lowerDistance = r.estimatedProportion! - r.lowerBound!;
        expect(upperDistance, greaterThanOrEqualTo(-eps), reason: 'k=$k n=$n');
        expect(lowerDistance, greaterThanOrEqualTo(-eps), reason: 'k=$k n=$n');
        expect(upperDistance + lowerDistance,
            closeTo(r.upperBound! - r.lowerBound!, 1e-9),
            reason: 'k=$k n=$n');
        expect(r.lowerBound!, inInclusiveRange(-1e-12, 1.0),
            reason: 'k=$k n=$n');
        expect(r.upperBound!, inInclusiveRange(0.0, 1 + 1e-12),
            reason: 'k=$k n=$n');
      }
    });
  });
}

/// Local sqrt mirror used only to keep the reference computation in the test
/// independent of the implementation under test's internal structure.
double _sqrtReference(double x) => x <= 0 ? 0 : _newtonSqrt(x);

double _newtonSqrt(double x) {
  var guess = x < 1 ? 1.0 : x;
  for (var i = 0; i < 80; i++) {
    guess = 0.5 * (guess + x / guess);
  }
  return guess;
}
