import '../domain/context_evidence.dart';
import 'bounded_outcome_descriptive_summary.dart';

enum BoundedOutcomeComparisonState {
  incompletePair,
  contextMismatch,
  descriptive,
}

enum BoundedOutcomeComparisonAuthority { none }

final class BoundedOutcomeComparison {
  const BoundedOutcomeComparison._({
    required this.first,
    required this.second,
    required this.state,
    required this.evidenceCountDifference,
    required this.answeredRateDifference,
    required this.correctRateDifference,
    required this.incorrectRateDifference,
    required this.timeoutRateDifference,
  });

  final BoundedOutcomeDescriptiveSummary first;
  final BoundedOutcomeDescriptiveSummary second;
  final BoundedOutcomeComparisonState state;
  final int? evidenceCountDifference;
  final double? answeredRateDifference;
  final double? correctRateDifference;
  final double? incorrectRateDifference;
  final double? timeoutRateDifference;

  BoundedOutcomeComparisonAuthority get authority =>
      BoundedOutcomeComparisonAuthority.none;
  bool get mayAffectGameplay => false;
}

final class BoundedOutcomeComparator {
  const BoundedOutcomeComparator();

  BoundedOutcomeComparison compare({
    required List<ContextEvidenceObservation> firstObservations,
    required List<ContextEvidenceObservation> secondObservations,
  }) {
    const summarizer = BoundedOutcomeDescriptiveSummarizer();
    final first = summarizer.summarize(firstObservations);
    final second = summarizer.summarize(secondObservations);

    if (first.evidenceCount == 0 || second.evidenceCount == 0) {
      return BoundedOutcomeComparison._(
        first: first,
        second: second,
        state: BoundedOutcomeComparisonState.incompletePair,
        evidenceCountDifference: null,
        answeredRateDifference: null,
        correctRateDifference: null,
        incorrectRateDifference: null,
        timeoutRateDifference: null,
      );
    }
    if (first.context != second.context) {
      return BoundedOutcomeComparison._(
        first: first,
        second: second,
        state: BoundedOutcomeComparisonState.contextMismatch,
        evidenceCountDifference: null,
        answeredRateDifference: null,
        correctRateDifference: null,
        incorrectRateDifference: null,
        timeoutRateDifference: null,
      );
    }
    return BoundedOutcomeComparison._(
      first: first,
      second: second,
      state: BoundedOutcomeComparisonState.descriptive,
      evidenceCountDifference: second.evidenceCount - first.evidenceCount,
      answeredRateDifference: second.answeredRate! - first.answeredRate!,
      correctRateDifference: second.correctRate! - first.correctRate!,
      incorrectRateDifference: second.incorrectRate! - first.incorrectRate!,
      timeoutRateDifference: second.timeoutRate! - first.timeoutRate!,
    );
  }
}
