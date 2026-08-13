import '../../../models/enums.dart';
import '../game_brain.dart';

/// Immutable canonical skill values exposed to the dashboard read boundary.
final class SkillDashboardCanonicalSnapshot {
  const SkillDashboardCanonicalSnapshot({
    required this.operation,
    required this.mastery,
    required this.attemptCount,
  });

  final Operation operation;
  final double mastery;
  final int attemptCount;
}

/// Pure read model combining canonical skill values with public evidence.
final class SkillDashboardShadowReadModel {
  SkillDashboardShadowReadModel._({
    required Iterable<SkillDashboardCanonicalSnapshot> canonicalSkills,
    required this.contextEvidence,
  }) : canonicalSkills = List.unmodifiable(
          canonicalSkills.map(
            (skill) => SkillDashboardCanonicalSnapshot(
              operation: skill.operation,
              mastery: skill.mastery,
              attemptCount: skill.attemptCount,
            ),
          ),
        );

  final List<SkillDashboardCanonicalSnapshot> canonicalSkills;
  final ContextEvidenceResult? contextEvidence;
}

/// Composes a side-effect-free snapshot from independent canonical sources.
SkillDashboardShadowReadModel composeSkillDashboardShadowRead(
  Iterable<SkillDashboardCanonicalSnapshot> canonicalSkills, {
  ContextEvidenceResult? contextEvidence,
}) =>
    SkillDashboardShadowReadModel._(
      canonicalSkills: canonicalSkills,
      contextEvidence: contextEvidence,
    );
