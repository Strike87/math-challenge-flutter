import '../domain/brain_decision.dart';
import '../domain/brain_observation.dart';
import '../domain/learner_snapshot.dart';

/// Pure policy seam for shadow-only decisions.
abstract interface class BrainDecisionPolicy {
  BrainDecision decide(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  );
}

/// BRAIN-01's deliberately conservative policy: observe without inferring.
final class ConservativeBrainDecisionPolicy implements BrainDecisionPolicy {
  const ConservativeBrainDecisionPolicy();

  @override
  BrainDecision decide(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  ) =>
      BrainDecision.neutral();
}
