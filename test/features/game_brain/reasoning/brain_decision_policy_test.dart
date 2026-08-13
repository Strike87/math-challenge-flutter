import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  final observation = BrainObservation(
    operation: Operation.multiplication,
    difficulty: Difficulty.easy,
    numberType: NumberType.natural,
    correctAnswer: '28',
    submittedAnswer: '11',
    correct: false,
    timedOut: false,
    responseTimeMs: 800,
    masteryBefore: 20,
    masteryAfter: 20,
    leftOperand: 7,
    rightOperand: 4,
  );
  final learner = LearnerSnapshot(
    masteryByOperation: const {Operation.multiplication: 20},
  );

  test('default policy exposes deterministic evidence while remaining neutral',
      () {
    final decision = ConservativeBrainDecisionPolicy().decide(
      observation,
      learner,
    );

    expect(decision.isNeutral, isTrue);
    expect(decision.isShadow, isTrue);
    expect(
        decision.misconceptionEvidence?.tag, 'operation-substitution:addition');
    expect(decision.confidence, 0.9);
  });

  test('GameBrain records the supplied observation once without mutation', () {
    final memory = BrainSessionMemory();
    final brain = GameBrain(memory: memory);

    final first = brain.evaluate(observation, learner);
    final second = brain.evaluate(observation, learner);

    expect(first.misconceptionEvidence?.tag, 'operation-substitution:addition');
    expect(second.misconceptionEvidence?.tag, first.misconceptionEvidence?.tag);
    expect(memory.observations, [same(observation), same(observation)]);
  });
}
