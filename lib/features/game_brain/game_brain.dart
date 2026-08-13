export 'domain/brain_decision.dart';
export 'domain/brain_observation.dart';
export 'domain/learner_snapshot.dart';
export 'domain/misconception_evidence.dart';
export 'domain/tentative_misconception_hypothesis.dart';
export 'memory/brain_session_memory.dart';
export 'reasoning/brain_decision_policy.dart';

import 'domain/brain_decision.dart';
import 'domain/brain_observation.dart';
import 'domain/learner_snapshot.dart';
import 'memory/brain_session_memory.dart';
import 'reasoning/brain_decision_policy.dart';

/// Thin facade that evaluates an observation and retains it in session memory.
final class GameBrain {
  GameBrain({
    BrainDecisionPolicy? policy,
    BrainSessionMemory? memory,
  })  : _policy = policy ?? const ConservativeBrainDecisionPolicy(),
        _memory = memory ?? BrainSessionMemory();

  final BrainDecisionPolicy _policy;
  final BrainSessionMemory _memory;

  BrainSessionMemory get memory => _memory;

  BrainDecision evaluate(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  ) {
    final decision = _policy.decide(observation, learnerSnapshot);
    _memory.record(observation);
    return decision;
  }
}
