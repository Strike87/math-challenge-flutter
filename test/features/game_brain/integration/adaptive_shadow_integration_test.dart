import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/features/game_brain/integration/adaptive_shadow_integration.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const integration = AdaptiveShadowIntegration();
  const authority = AdaptiveAuthority.shadow();

  ContextEvidenceResult insufficientEvidence() =>
      ContextEvidenceResult.insufficientExposure(
        context: ContextEvidenceKey(
          operation: Operation.addition,
          numberType: NumberType.natural,
        ),
        exposureCount: 1,
        correctCount: 1,
        incorrectCount: 0,
        timeoutCount: 0,
      );

  void expectNoAdaptation(AdaptiveIntegrationDecision decision) {
    expect(decision.outcome, AdaptiveIntegrationOutcome.noAdaptation);
    expect(decision.direction, isNull);
    expect(decision.canExecute, isFalse);
  }

  test('insufficient evidence fails closed to no adaptation', () {
    final decision = integration.evaluate(insufficientEvidence(), authority);

    expectNoAdaptation(decision);
  });

  test('unsupported context fails closed to no adaptation', () {
    final decision = integration.evaluate(
      const ContextEvidenceResult.unsupported(),
      authority,
    );

    expectNoAdaptation(decision);
  });

  test('missing capability rejects a shadow proposal', () {
    final decision = integration.evaluate(
      insufficientEvidence(),
      const AdaptiveAuthority.shadow(hasCapability: false),
      shadowProposal: const AdaptiveProposal(AdaptiveDirection.increase),
    );

    expectNoAdaptation(decision);
  });

  test('illegal current constraint rejects a shadow proposal', () {
    final decision = integration.evaluate(
      insufficientEvidence(),
      const AdaptiveAuthority.shadow(isConstraintLegal: false),
      shadowProposal: const AdaptiveProposal(AdaptiveDirection.decrease),
    );

    expectNoAdaptation(decision);
  });

  test('unsupported proposal fails closed', () {
    final decision = integration.evaluate(
      insufficientEvidence(),
      authority,
      shadowProposal: const AdaptiveProposal.unsupported(),
    );

    expectNoAdaptation(decision);
  });

  test('eligible test proposal remains non-executable in shadow mode', () {
    final decision = integration.evaluate(
      insufficientEvidence(),
      authority,
      shadowProposal: const AdaptiveProposal(AdaptiveDirection.increase),
    );

    expect(decision.outcome, AdaptiveIntegrationOutcome.noAdaptation);
    expect(decision.direction, AdaptiveDirection.increase);
    expect(authority.canExecute, isFalse);
    expect(decision.canExecute, isFalse);
  });

  test('shadow interpretation is deterministic', () {
    final first = integration.evaluate(
      insufficientEvidence(),
      authority,
      shadowProposal: const AdaptiveProposal(AdaptiveDirection.hold),
    );
    final second = integration.evaluate(
      insufficientEvidence(),
      authority,
      shadowProposal: const AdaptiveProposal(AdaptiveDirection.hold),
    );

    expect(second.outcome, first.outcome);
    expect(second.direction, first.direction);
    expect(second.canExecute, first.canExecute);
  });
}
