import 'preview_observation_evidence_v2.dart';

enum AccuracyOnlyBaselineOutcome {
  highPerformancePossiblyHarder,
  keepCurrent,
  lowPerformancePossiblyEasierOrReview,
}

class AccuracyOnlyBaselineResult {
  const AccuracyOnlyBaselineResult(this.outcome);

  final AccuracyOnlyBaselineOutcome outcome;
  PreviewAuthority get authority => PreviewAuthority.none;
  bool get mayAffectGameplay => false;
}

class AccuracyOnlyBaseline {
  const AccuracyOnlyBaseline();

  AccuracyOnlyBaselineResult evaluate(double accuracy) {
    if (accuracy < 0 || accuracy > 1) {
      throw ArgumentError.value(
          accuracy, 'accuracy', 'must be between 0 and 1');
    }
    if (accuracy >= .80) {
      return const AccuracyOnlyBaselineResult(
        AccuracyOnlyBaselineOutcome.highPerformancePossiblyHarder,
      );
    }
    if (accuracy >= .60) {
      return const AccuracyOnlyBaselineResult(
        AccuracyOnlyBaselineOutcome.keepCurrent,
      );
    }
    return const AccuracyOnlyBaselineResult(
      AccuracyOnlyBaselineOutcome.lowPerformancePossiblyEasierOrReview,
    );
  }
}
