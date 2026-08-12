export 'domain/brain_decision.dart';
export 'domain/brain_memory_entry.dart';
export 'domain/brain_observation.dart';
export 'domain/learner_hypothesis.dart';
export 'domain/learner_snapshot.dart';
export 'domain/misconception_evidence.dart';
export 'domain/session_evidence.dart';
export 'domain/tentative_misconception_hypothesis.dart';
export 'memory/brain_session_memory.dart';
export 'reasoning/brain_decision_policy.dart';
export 'reasoning/session/default_learner_reasoner.dart';
export 'reasoning/session/learner_reasoner.dart';

import 'domain/brain_decision.dart';
import 'domain/brain_observation.dart';
import 'domain/learner_snapshot.dart';
import 'memory/brain_session_memory.dart';
import 'reasoning/brain_decision_policy.dart';
import 'reasoning/session/default_learner_reasoner.dart';
import 'reasoning/session/learner_reasoner.dart';

/// Thin facade that evaluates an observation and retains it in session memory.
final class GameBrain {
  GameBrain({
    BrainDecisionPolicy? policy,
    BrainSessionMemory? memory,
    LearnerReasoner? learnerReasoner,
  })  : _policy = policy ?? const ConservativeBrainDecisionPolicy(),
        _memory = memory ?? BrainSessionMemory(),
        _learnerReasoner = learnerReasoner ?? const DefaultLearnerReasoner();

  final BrainDecisionPolicy _policy;
  final BrainSessionMemory _memory;
  final LearnerReasoner _learnerReasoner;

  BrainSessionMemory get memory => _memory;

  BrainDecision evaluate(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  ) {
    final decision = _policy.decide(observation, learnerSnapshot);
    _memory.record(
      observation,
      misconceptionEvidence: decision.misconceptionEvidence,
    );
    final sessionEvidence = _learnerReasoner.reason(
      _memory.entries,
      observation.operation,
    );
    return BrainDecision(
      isNeutral: decision.isNeutral,
      confidence: decision.confidence,
      misconceptionEvidence: decision.misconceptionEvidence,
      sessionEvidence: sessionEvidence,
    );
  }
}
