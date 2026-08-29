/// Pure-domain Wilson precision evaluation for the frozen Phase-1 P1-F01
/// study-evidence criterion.
///
/// Frozen semantics (P1-F00 v1, "Decision-relevant precision"):
/// two-sided 95% Wilson score interval for a candidate-specific binomial
/// proportion over comparable evidence; the criterion passes when the
/// interval half-width is at most 0.15 (boundary equality passes).
///
/// This file is mathematical foundation only. It captures nothing, persists
/// nothing, reads no gameplay state, and feeds no gameplay decision.
/// `mayAffectGameplay = false`.
library;

import 'dart:math' as math;

/// Two-sided 95% standard normal quantile used by the frozen criterion.
const double wilsonZ95 = 1.959963984540054;

/// Frozen Phase-1 precision threshold for the Wilson interval half-width.
const double wilsonPrecisionThreshold = 0.15;

/// Candidate-specific binomial summary handed to the evaluator.
///
/// This is a plain value input: it carries no question content, player
/// identity, timestamps, or outcome history beyond the aggregate counts.
final class WilsonBinomialSummary {
  const WilsonBinomialSummary({required this.successes, required this.trials});

  final int successes;
  final int trials;
}

/// Explicit result states for Wilson evaluation.
enum WilsonEvaluationStatus {
  /// Inputs were mathematically invalid (negative counts or k > n).
  invalidInput,

  /// n == 0: no accepted-terminal denominator exists, so no interval is
  /// fabricated.
  unevaluable,

  /// n > 0: a finite Wilson interval was computed.
  evaluable,
}

/// Immutable result of one Wilson precision evaluation.
///
/// For [WilsonEvaluationStatus.evaluable], all numeric fields are finite and
/// mathematically coherent: `0 <= lower <= estimate <= upper <= 1` and
/// `halfWidth = upper - lower` up to floating-point symmetry of the formula.
/// For every other status the numeric fields are absent and must not be
/// fabricated by callers.
final class WilsonPrecisionResult {
  const WilsonPrecisionResult._({
    required this.status,
    this.successes,
    this.trials,
    this.estimatedProportion,
    this.lowerBound,
    this.upperBound,
    this.halfWidth,
    this.meetsPrecision,
  });

  const WilsonPrecisionResult.invalidInput()
      : this._(status: WilsonEvaluationStatus.invalidInput);

  const WilsonPrecisionResult.unevaluable()
      : this._(status: WilsonEvaluationStatus.unevaluable);

  const WilsonPrecisionResult.evaluable({
    required int successes,
    required int trials,
    required double estimatedProportion,
    required double lowerBound,
    required double upperBound,
    required double halfWidth,
    required bool meetsPrecision,
  }) : this._(
          status: WilsonEvaluationStatus.evaluable,
          successes: successes,
          trials: trials,
          estimatedProportion: estimatedProportion,
          lowerBound: lowerBound,
          upperBound: upperBound,
          halfWidth: halfWidth,
          meetsPrecision: meetsPrecision,
        );

  final WilsonEvaluationStatus status;

  /// Present only when [status] is evaluable.
  final int? successes;

  /// Present only when [status] is evaluable.
  final int? trials;

  /// Point estimate k/n; present only when [status] is evaluable.
  final double? estimatedProportion;

  /// Lower Wilson bound; present only when [status] is evaluable.
  final double? lowerBound;

  /// Upper Wilson bound; present only when [status] is evaluable.
  final double? upperBound;

  /// Two-sided interval half-width; present only when [status] is evaluable.
  final double? halfWidth;

  /// Whether `halfWidth <= 0.15` with boundary equality passing; present only
  /// when [status] is evaluable.
  final bool? meetsPrecision;

  bool get isEvaluable => status == WilsonEvaluationStatus.evaluable;
}

/// Pure threshold predicate for the frozen precision rule.
///
/// Isolated so boundary semantics (`<=`, equality passes) are testable
/// directly without depending on whether some integer (k, n) pair lands on
/// exactly 0.15 after floating-point evaluation.
///
/// A half-width is a non-negative real quantity, so nonsensical inputs are
/// rejected explicitly rather than silently producing a misleading boolean:
/// NaN, either infinity, or any negative value throws [ArgumentError].
bool meetsWilsonPrecision(double halfWidth) {
  if (halfWidth.isNaN || halfWidth.isInfinite || halfWidth < 0) {
    throw ArgumentError.value(
      halfWidth,
      'halfWidth',
      'must be a finite, non-negative interval half-width',
    );
  }
  return halfWidth <= wilsonPrecisionThreshold;
}

/// Evaluates the frozen two-sided 95% Wilson precision criterion for one
/// candidate's binomial summary.
///
/// Validation:
/// - negative successes or trials, or successes > trials, produce an explicit
///   invalid-input result rather than an exception, matching the pure-domain
///   explicit-result style used by adjacent evaluators;
/// - n == 0 produces [WilsonEvaluationStatus.unevaluable] with no fabricated
///   interval values;
/// - every n > 0 is mathematically evaluable — no artificial small-n cutoff
///   exists; small samples simply widen the interval and fail the threshold
///   naturally.
WilsonPrecisionResult evaluateWilsonPrecision(WilsonBinomialSummary summary) {
  final k = summary.successes;
  final n = summary.trials;
  if (k < 0 || n < 0 || k > n) {
    return const WilsonPrecisionResult.invalidInput();
  }
  if (n == 0) {
    return const WilsonPrecisionResult.unevaluable();
  }

  final pHat = k / n;
  final z2 = wilsonZ95 * wilsonZ95;
  final denominator = 1 + z2 / n;

  final center = (pHat + z2 / (2 * n)) / denominator;
  final halfWidth = wilsonZ95 *
      math.sqrt((pHat * (1 - pHat) / n) + (z2 / (4 * n * n))) /
      denominator;
  final lower = center - halfWidth;
  final upper = center + halfWidth;

  return WilsonPrecisionResult.evaluable(
    successes: k,
    trials: n,
    estimatedProportion: pHat,
    lowerBound: lower,
    upperBound: upper,
    halfWidth: halfWidth,
    meetsPrecision: meetsWilsonPrecision(halfWidth),
  );
}
