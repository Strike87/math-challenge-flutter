import '../domain/brain_decision.dart';
import '../domain/brain_observation.dart';
import '../domain/learner_snapshot.dart';
import 'misconceptions/composite_misconception_detector.dart';
import 'misconceptions/misconception_detector.dart';

/// Pure policy seam for shadow-only decisions.
abstract interface class BrainDecisionPolicy {
  BrainDecision decide(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  );
}

/// BRAIN-01's deliberately conservative policy: observe without inferring.
final class ConservativeBrainDecisionPolicy implements BrainDecisionPolicy {
  const ConservativeBrainDecisionPolicy({
    MisconceptionDetector? misconceptionDetector,
  }) : _misconceptionDetector = misconceptionDetector;

  static final MisconceptionDetector _defaultMisconceptionDetector =
      CompositeMisconceptionDetector();

  final MisconceptionDetector? _misconceptionDetector;

  @override
  BrainDecision decide(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  ) {
    final evidence =
        (_misconceptionDetector ?? _defaultMisconceptionDetector).detect(
      observation,
    );
    return BrainDecision(
      isNeutral: true,
      confidence: evidence?.confidence ?? 0,
      misconceptionEvidence: evidence,
    );
  }
}
