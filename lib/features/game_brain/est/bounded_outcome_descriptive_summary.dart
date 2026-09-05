import '../../../models/enums.dart';
import '../domain/context_evidence.dart';

enum BoundedOutcomeDescriptiveAuthority { none }

final class BoundedOutcomeDescriptiveSummary {
  const BoundedOutcomeDescriptiveSummary({
    required this.context,
    required this.difficulty,
    required this.evidenceCount,
    required this.answeredCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.timeoutCount,
    required this.answeredRate,
    required this.correctRate,
    required this.incorrectRate,
    required this.timeoutRate,
  });

  final ContextEvidenceKey? context;
  final Difficulty? difficulty;
  final int evidenceCount;
  final int answeredCount;
  final int correctCount;
  final int incorrectCount;
  final int timeoutCount;
  final double? answeredRate;
  final double? correctRate;
  final double? incorrectRate;
  final double? timeoutRate;

  BoundedOutcomeDescriptiveAuthority get authority =>
      BoundedOutcomeDescriptiveAuthority.none;
  bool get mayAffectGameplay => false;
}

final class BoundedOutcomeDescriptiveSummarizer {
  const BoundedOutcomeDescriptiveSummarizer();

  BoundedOutcomeDescriptiveSummary summarize(
    List<ContextEvidenceObservation> observations,
  ) {
    if (observations.isEmpty) {
      return const BoundedOutcomeDescriptiveSummary(
        context: null,
        difficulty: null,
        evidenceCount: 0,
        answeredCount: 0,
        correctCount: 0,
        incorrectCount: 0,
        timeoutCount: 0,
        answeredRate: null,
        correctRate: null,
        incorrectRate: null,
        timeoutRate: null,
      );
    }

    final context = observations.first.context;
    if (context == null) {
      throw ArgumentError('Each observation must have a context.');
    }
    final difficulty = observations.first.difficulty;
    var correctCount = 0;
    var incorrectCount = 0;
    var timeoutCount = 0;
    for (final observation in observations) {
      if (observation.context == null) {
        throw ArgumentError('Each observation must have a context.');
      }
      if (observation.context != context) {
        throw ArgumentError('Observations must have the same context.');
      }
      if (observation.difficulty != difficulty) {
        throw ArgumentError('Observations must have the same difficulty.');
      }
      if (observation.timedOut) {
        timeoutCount++;
      } else if (observation.correct) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    final evidenceCount = observations.length;
    final answeredCount = correctCount + incorrectCount;
    return BoundedOutcomeDescriptiveSummary(
      context: context,
      difficulty: difficulty,
      evidenceCount: evidenceCount,
      answeredCount: answeredCount,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      timeoutCount: timeoutCount,
      answeredRate: answeredCount / evidenceCount,
      correctRate: correctCount / evidenceCount,
      incorrectRate: incorrectCount / evidenceCount,
      timeoutRate: timeoutCount / evidenceCount,
    );
  }
}
