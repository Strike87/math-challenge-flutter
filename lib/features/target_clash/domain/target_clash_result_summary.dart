import 'target_clash_runtime_state.dart';

/// Immutable successful Target Clash completion facts.
final class TargetClashResultSummary {
  const TargetClashResultSummary._({
    required this.score,
    required this.correct,
    required this.resolved,
    required this.bestCombo,
    required this.perfectHits,
    required this.bossesDefeated,
    required this.finalTargetCompleted,
    required this.finalTargetCleared,
    required this.tripleClashesCompleted,
  });

  factory TargetClashResultSummary.fromFinishedRuntime(
    TargetClashRuntimeState runtime,
  ) {
    if (!runtime.finished) {
      throw ArgumentError.value(runtime, 'runtime', 'must be finished');
    }
    return TargetClashResultSummary._(
      score: runtime.score,
      correct: runtime.correctCount,
      resolved: runtime.resolvedCount,
      bestCombo: runtime.bestCombo,
      perfectHits: runtime.perfectHits,
      bossesDefeated: runtime.bossesDefeated,
      finalTargetCompleted: runtime.finalTargetCompleted,
      finalTargetCleared: runtime.finalTargetCleared,
      tripleClashesCompleted: runtime.tripleClashesCompleted,
    );
  }

  final int score;
  final int correct;
  final int resolved;
  final int bestCombo;
  final int perfectHits;
  final int bossesDefeated;
  final bool finalTargetCompleted;
  final bool finalTargetCleared;
  final int tripleClashesCompleted;

  double get accuracyPercent => resolved == 0 ? 0.0 : correct * 100 / resolved;
}
