import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/domain/brain_decision.dart';
import 'package:math_challenge/features/game_brain/domain/brain_recommendation.dart';
import 'package:math_challenge/features/game_brain/domain/learner_hypothesis.dart';
import 'package:math_challenge/features/game_brain/domain/session_evidence.dart';
import 'package:math_challenge/features/weak_skills/domain/weak_skills_advisory_signal.dart';
import 'package:math_challenge/features/weak_skills/integration/weak_skills_advisory_signal_adapter.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  test('converts only a repeated-misconception reinforcement decision', () {
    final signal = weakSkillsAdvisorySignalFor(_decision());

    expect(signal?.targetOperation, Operation.addition);
    expect(
        signal?.recommendationType, BrainRecommendationType.reinforceOperation);
    expect(signal?.recommendationReason,
        BrainRecommendationReason.repeatedMisconception);
    expect(signal?.learnerHypothesis, LearnerHypothesis.repeatedMisconception);
    expect(signal?.misconceptionType, isNull);
    expect(signal?.supportingObservationCount, 2);
  });

  test('rejects missing or ineligible targets and mismatched BRAIN-04 evidence',
      () {
    expect(
      weakSkillsAdvisorySignalFor(_decision(targetOperation: null)),
      isNull,
    );
    expect(
      weakSkillsAdvisorySignalFor(_decision(targetOperation: Operation.mixed)),
      isNull,
    );
    expect(
      weakSkillsAdvisorySignalFor(
        _decision(reason: BrainRecommendationReason.recovering),
      ),
      isNull,
    );
    expect(
      weakSkillsAdvisorySignalFor(
        _decision(type: BrainRecommendationType.maintain),
      ),
      isNull,
    );
    expect(
      weakSkillsAdvisorySignalFor(
        _decision(hypothesis: LearnerHypothesis.recovering),
      ),
      isNull,
    );
  });

  test('rejects a negative supporting observation count', () {
    expect(
      () => WeakSkillsAdvisorySignal(
        targetOperation: Operation.addition,
        recommendationType: BrainRecommendationType.reinforceOperation,
        recommendationReason: BrainRecommendationReason.repeatedMisconception,
        learnerHypothesis: LearnerHypothesis.repeatedMisconception,
        supportingObservationCount: -1,
      ),
      throwsArgumentError,
    );
  });
}

BrainDecision _decision({
  Operation? targetOperation = Operation.addition,
  BrainRecommendationReason reason =
      BrainRecommendationReason.repeatedMisconception,
  LearnerHypothesis hypothesis = LearnerHypothesis.repeatedMisconception,
  BrainRecommendationType type = BrainRecommendationType.reinforceOperation,
}) =>
    BrainDecision(
      isNeutral: false,
      confidence: .5,
      sessionEvidence: SessionEvidence(
        operation: Operation.addition,
        observationCount: 2,
        correctCount: 0,
        incorrectCount: 2,
        misconceptionCounts: const {},
        latestMisconception: null,
        hypothesis: hypothesis,
        supportingObservationCount: 2,
      ),
      recommendation: BrainRecommendation(
        type: type,
        reason: reason,
        targetOperation: targetOperation,
        currentDifficulty: Difficulty.easy,
        supportingObservationCount: 2,
      ),
    );
