import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  final observation = BrainObservation(
    operation: Operation.addition,
    difficulty: Difficulty.easy,
    numberType: NumberType.natural,
    correctAnswer: '4',
    submittedAnswer: '4',
    correct: true,
    timedOut: false,
    responseTimeMs: 800,
    masteryBefore: 20,
    masteryAfter: 27,
  );
  final learner = LearnerSnapshot(
    masteryByOperation: const {Operation.addition: 27},
  );

  test('default policy produces a conservative neutral shadow decision', () {
    final decision = GameBrain().evaluate(observation, learner);

    expect(decision.isNeutral, isTrue);
    expect(decision.isShadow, isTrue);
    expect(decision.confidence, 0);
  });

  test(
      'evaluate preserves policy fields, returns a new decision, and records once',
      () {
    final memory = BrainSessionMemory();
    final expected = BrainDecision(isNeutral: false, confidence: 0.75);
    final brain = GameBrain(policy: _FakePolicy(expected), memory: memory);

    final decision = brain.evaluate(observation, learner);

    expect(decision, isNot(same(expected)));
    expect(decision.isNeutral, expected.isNeutral);
    expect(decision.confidence, expected.confidence);
    expect(decision.misconceptionEvidence, expected.misconceptionEvidence);
    expect(decision.sessionEvidence, isNotNull);
    expect(decision.isShadow, isTrue);
    expect(memory.observations, [same(observation)]);
    expect(memory.entries.single.observation, same(observation));
  });

  test('current evidence is paired once and informs session reasoning', () {
    final memory = BrainSessionMemory();
    final evidence = MisconceptionEvidence(
      tag: 'sign',
      type: MisconceptionType.signRule,
      reason: MisconceptionReason.oppositeSignSameMagnitude,
    );
    final brain = GameBrain(
      policy: _FakePolicy(
        BrainDecision(
          isNeutral: true,
          confidence: 0.5,
          misconceptionEvidence: evidence,
        ),
      ),
      memory: memory,
    );

    brain.evaluate(observation, learner);
    final decision = brain.evaluate(observation, learner);

    expect(memory.entries, hasLength(2));
    expect(
      memory.entries.every((entry) => entry.misconceptionEvidence == evidence),
      isTrue,
    );
    expect(
      decision.sessionEvidence!.hypothesis,
      LearnerHypothesis.repeatedMisconception,
    );
  });
}

final class _FakePolicy implements BrainDecisionPolicy {
  const _FakePolicy(this.decision);

  final BrainDecision decision;

  @override
  BrainDecision decide(
    BrainObservation observation,
    LearnerSnapshot learnerSnapshot,
  ) =>
      decision;
}
