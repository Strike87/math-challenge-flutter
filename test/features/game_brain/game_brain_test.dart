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

  test('evaluate returns the injected policy decision and records once', () {
    final memory = BrainSessionMemory();
    final expected = BrainDecision(isNeutral: false, confidence: 0.75);
    final brain = GameBrain(policy: _FakePolicy(expected), memory: memory);

    final decision = brain.evaluate(observation, learner);

    expect(decision, same(expected));
    expect(decision.isShadow, isTrue);
    expect(memory.observations, [same(observation)]);
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
