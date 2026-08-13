import '../../../models/enums.dart';

/// Immutable canonical mastery values available to GameBrain for one learner.
final class LearnerSnapshot {
  LearnerSnapshot({required Map<Operation, double> masteryByOperation})
      : masteryByOperation = Map.unmodifiable(masteryByOperation) {
    for (final entry in this.masteryByOperation.entries) {
      final mastery = entry.value;
      if (!mastery.isFinite || mastery < 0 || mastery > 100) {
        throw ArgumentError.value(
          mastery,
          'masteryByOperation[${entry.key.name}]',
          'must be a finite value from 0 to 100',
        );
      }
    }
  }

  final Map<Operation, double> masteryByOperation;
}
