import '../game_brain.dart';

enum AdaptiveDirection { increase, hold, decrease }

/// An integration-owned proposal. A missing direction is unsupported.
final class AdaptiveProposal {
  const AdaptiveProposal(this.direction);
  const AdaptiveProposal.unsupported() : direction = null;

  final AdaptiveDirection? direction;
}

/// The capability and current constraint at the Adaptive integration point.
///
/// GBI-01 is permanently shadow-only, so this type exposes no execution grant.
final class AdaptiveAuthority {
  const AdaptiveAuthority.shadow({
    this.hasCapability = true,
    this.isConstraintLegal = true,
  });

  final bool hasCapability;
  final bool isConstraintLegal;
  bool get canExecute => false;
}

enum AdaptiveIntegrationOutcome { noAdaptation }

/// Immutable result of interpreting an advisory at the Adaptive boundary.
final class AdaptiveIntegrationDecision {
  const AdaptiveIntegrationDecision.noAdaptation()
      : outcome = AdaptiveIntegrationOutcome.noAdaptation,
        direction = null;

  const AdaptiveIntegrationDecision.shadowProposal(
    AdaptiveDirection this.direction,
  ) : outcome = AdaptiveIntegrationOutcome.noAdaptation;

  final AdaptiveIntegrationOutcome outcome;
  final AdaptiveDirection? direction;
  bool get canExecute => false;
}

typedef AdaptiveShadowEvaluator = AdaptiveIntegrationDecision Function(
  ContextEvidenceResult advisory,
  AdaptiveAuthority authority,
);

/// Pure, fail-closed interpretation for the shadow Adaptive integration.
final class AdaptiveShadowIntegration {
  const AdaptiveShadowIntegration();

  AdaptiveIntegrationDecision evaluate(
    ContextEvidenceResult advisory,
    AdaptiveAuthority authority, {
    AdaptiveProposal? shadowProposal,
  }) {
    if (!authority.hasCapability || !authority.isConstraintLegal) {
      return const AdaptiveIntegrationDecision.noAdaptation();
    }

    // The frozen public Core currently exposes no evidence state that can
    // justify an Adaptive proposal.
    if (shadowProposal == null) {
      return switch (advisory.status) {
        ContextEvidenceStatus.insufficientEvidence =>
          const AdaptiveIntegrationDecision.noAdaptation(),
      };
    }

    final direction = shadowProposal.direction;
    if (direction == null) {
      return const AdaptiveIntegrationDecision.noAdaptation();
    }
    return AdaptiveIntegrationDecision.shadowProposal(direction);
  }
}

AdaptiveIntegrationDecision evaluateAdaptiveShadow(
  ContextEvidenceResult advisory,
  AdaptiveAuthority authority,
) =>
    const AdaptiveShadowIntegration().evaluate(advisory, authority);
