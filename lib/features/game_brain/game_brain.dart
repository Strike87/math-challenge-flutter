export 'domain/brain_decision.dart';
export 'domain/brain_memory_entry.dart';
export 'domain/brain_observation.dart';
export 'domain/brain_recommendation.dart';
export 'domain/context_evidence.dart';
export 'interpretation/bounded_context_shadow_episode_recorder.dart';
export 'interpretation/bounded_context_shadow_interpreter.dart';
export 'domain/learner_hypothesis.dart';
export 'domain/learner_snapshot.dart';
export 'domain/misconception_evidence.dart';
export 'domain/session_evidence.dart';
export 'domain/tentative_misconception_hypothesis.dart';
export 'memory/brain_session_memory.dart';
export 'memory/context_evidence_memory.dart';
export 'reasoning/brain_decision_policy.dart';
export 'reasoning/recommendations/default_recommendation_policy.dart';
export 'reasoning/recommendations/recommendation_policy.dart';
export 'reasoning/session/default_learner_reasoner.dart';
export 'reasoning/session/learner_reasoner.dart';

import 'domain/brain_decision.dart';
import 'domain/brain_observation.dart';
import 'domain/context_evidence.dart';
import 'domain/learner_snapshot.dart';
import 'memory/brain_session_memory.dart';
import 'memory/context_evidence_memory.dart';
import 'reasoning/brain_decision_policy.dart';
import 'reasoning/session/default_learner_reasoner.dart';
import 'reasoning/session/learner_reasoner.dart';
import 'reasoning/recommendations/default_recommendation_policy.dart';
import 'reasoning/recommendations/recommendation_policy.dart';

/// Thin facade that evaluates an observation without changing gameplay.
final class GameBrain {
  GameBrain({
    BrainDecisionPolicy? policy,
    BrainSessionMemory? memory,
    LearnerReasoner? learnerReasoner,
    RecommendationPolicy? recommendationPolicy,
    ContextEvidenceMemory? contextEvidenceMemory,
  })  : _policy = policy ?? const ConservativeBrainDecisionPolicy(),
        _memory = memory ?? BrainSessionMemory(),
        _contextEvidenceMemory =
            contextEvidenceMemory ?? ContextEvidenceMemory(),
        _learnerReasoner = learnerReasoner ?? const DefaultLearnerReasoner(),
        _recommendationPolicy =
            recommendationPolicy ?? const DefaultRecommendationPolicy();

  final BrainDecisionPolicy _policy;
  final BrainSessionMemory _memory;
  final ContextEvidenceMemory _contextEvidenceMemory;
  final LearnerReasoner _learnerReasoner;
  final RecommendationPolicy _recommendationPolicy;

  BrainSessionMemory get memory => _memory;
  ContextEvidenceMemory get contextEvidenceMemory => _contextEvidenceMemory;

  ContextEvidenceResult observeContextEvidence(
    ContextEvidenceObservation observation,
  ) {
    final context = observation.context;
    if (context == null) {
      return const ContextEvidenceResult.unsupported();
    }
    _contextEvidenceMemory.record(observation);
    return _insufficientExposureFor(context);
  }

  ContextEvidenceResult _insufficientExposureFor(ContextEvidenceKey context) {
    var exposureCount = 0;
    var correctCount = 0;
    var timeoutCount = 0;
    for (final observation in _contextEvidenceMemory.observations) {
      if (observation.context != context) continue;
      exposureCount++;
      if (observation.correct) correctCount++;
      if (observation.timedOut) timeoutCount++;
    }
    return ContextEvidenceResult.insufficientExposure(
      context: context,
      exposureCount: exposureCount,
      correctCount: correctCount,
      incorrectCount: exposureCount - correctCount,
      timeoutCount: timeoutCount,
    );
  }

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
    final recommendation = _recommendationPolicy.recommend(
      observation,
      sessionEvidence,
    );
    return BrainDecision(
      isNeutral: decision.isNeutral,
      confidence: decision.confidence,
      misconceptionEvidence: decision.misconceptionEvidence,
      sessionEvidence: sessionEvidence,
      recommendation: recommendation,
    );
  }
}
