import '../../../models/enums.dart';
import '../../../models/game_data.dart';
import '../../game_brain/domain/brain_recommendation.dart';
import '../../game_brain/domain/learner_hypothesis.dart';
import 'weak_skills_advisory_signal.dart';

const _canonicalOperations = [
  Operation.addition,
  Operation.subtraction,
  Operation.multiplication,
  Operation.division,
];

final class WeakSkillsPlan {
  WeakSkillsPlan({
    required this.isFallback,
    required Iterable<Operation> operationCycle,
    this.advisory,
  }) : operationCycle = List.unmodifiable(operationCycle);

  final bool isFallback;
  final List<Operation> operationCycle;
  final WeakSkillsAdvisorySignal? advisory;

  Operation operationAt(int index) =>
      operationCycle[index % operationCycle.length];

  List<Operation> get focusedOperations =>
      List.unmodifiable(operationCycle.toSet());
}

WeakSkillsPlan selectWeakSkillsPlan(
  Map<String, SkillData> skillMap, {
  WeakSkillsAdvisorySignal? advisory,
}) {
  final totalAttempts = _canonicalOperations.fold(
    0,
    (total, operation) => total + (skillMap[operation.name]?.count ?? 0),
  );
  final eligible = _canonicalOperations
      .where((operation) => (skillMap[operation.name]?.count ?? 0) >= 3)
      .toList();

  if (totalAttempts < 10 || eligible.length < 2) return _fallbackPlan();

  final mastery = {
    for (final operation in eligible)
      operation: skillMap[operation.name]!.mastery,
  };
  final lowest = mastery.values.reduce((a, b) => a < b ? a : b);
  final highest = mastery.values.reduce((a, b) => a > b ? a : b);
  final weakest =
      eligible.where((operation) => mastery[operation] == lowest).toList();

  if (highest - lowest < 10 || weakest.length >= 3) return _fallbackPlan();

  if (weakest.length == 2) {
    final applicableAdvisory =
        _isApplicableAdvisory(advisory, weakest) ? advisory : null;
    if (applicableAdvisory != null) {
      final secondary = weakest.firstWhere(
        (operation) => operation != applicableAdvisory.targetOperation,
      );
      return WeakSkillsPlan(
        isFallback: false,
        advisory: applicableAdvisory,
        operationCycle:
            _weightedCycle(applicableAdvisory.targetOperation, secondary),
      );
    }
    return WeakSkillsPlan(
      isFallback: false,
      operationCycle: [
        for (var i = 0; i < 10; i++) ...weakest,
      ],
    );
  }

  final primary = weakest.single;
  final secondMastery = mastery.entries
      .where((entry) => entry.key != primary)
      .map((entry) => entry.value)
      .reduce((a, b) => a < b ? a : b);
  final secondary = eligible.firstWhere(
    (operation) => mastery[operation] == secondMastery,
  );
  return WeakSkillsPlan(
    isFallback: false,
    operationCycle: _weightedCycle(primary, secondary),
  );
}

bool _isApplicableAdvisory(
  WeakSkillsAdvisorySignal? advisory,
  List<Operation> weakest,
) =>
    advisory != null &&
    advisory.recommendationType == BrainRecommendationType.reinforceOperation &&
    advisory.recommendationReason ==
        BrainRecommendationReason.repeatedMisconception &&
    advisory.learnerHypothesis == LearnerHypothesis.repeatedMisconception &&
    weakest.contains(advisory.targetOperation);

List<Operation> _weightedCycle(Operation primary, Operation secondary) => [
      for (var i = 0; i < 20; i++)
        if (((i + 1) * 7 ~/ 20) > (i * 7 ~/ 20)) secondary else primary,
    ];

WeakSkillsPlan _fallbackPlan() => WeakSkillsPlan(
      isFallback: true,
      operationCycle: _canonicalOperations,
    );
