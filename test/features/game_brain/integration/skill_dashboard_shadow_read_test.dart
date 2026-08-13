import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/features/game_brain/integration/skill_dashboard_shadow_read.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  test(
    'supported insufficient exposure remains intact beside canonical data',
    () {
      final evidence = ContextEvidenceResult.insufficientExposure(
        context: ContextEvidenceKey(
          operation: Operation.addition,
          numberType: NumberType.natural,
        ),
        exposureCount: 2,
        correctCount: 1,
        incorrectCount: 1,
        timeoutCount: 0,
      );

      final readModel = composeSkillDashboardShadowRead(const [
        SkillDashboardCanonicalSnapshot(
          operation: Operation.addition,
          mastery: 42,
          attemptCount: 7,
        ),
      ], contextEvidence: evidence);

      expect(readModel.contextEvidence, same(evidence));
      expect(
        readModel.contextEvidence!.reasonCode,
        ContextEvidenceReason.insufficientExposure,
      );
      expect(readModel.canonicalSkills.single.operation, Operation.addition);
      expect(readModel.canonicalSkills.single.mastery, 42);
      expect(readModel.canonicalSkills.single.attemptCount, 7);
    },
  );

  test('unsupported evidence remains intact beside canonical data', () {
    const evidence = ContextEvidenceResult.unsupported();

    final readModel = composeSkillDashboardShadowRead(const [
      SkillDashboardCanonicalSnapshot(
        operation: Operation.division,
        mastery: 75,
        attemptCount: 12,
      ),
    ], contextEvidence: evidence);

    expect(readModel.contextEvidence, same(evidence));
    expect(
      readModel.contextEvidence!.reasonCode,
      ContextEvidenceReason.unsupportedContext,
    );
    expect(readModel.contextEvidence!.context, isNull);
  });

  test('absent evidence remains absent even for low mastery', () {
    final readModel = composeSkillDashboardShadowRead(const [
      SkillDashboardCanonicalSnapshot(
        operation: Operation.subtraction,
        mastery: 1,
        attemptCount: 100,
      ),
    ]);

    expect(readModel.contextEvidence, isNull);
    expect(readModel.canonicalSkills.single.mastery, 1);
    expect(readModel.canonicalSkills.single.attemptCount, 100);
  });

  test('composition copies source values into an unmodifiable collection', () {
    const sourceSnapshot = SkillDashboardCanonicalSnapshot(
      operation: Operation.multiplication,
      mastery: 64,
      attemptCount: 9,
    );
    final source = <SkillDashboardCanonicalSnapshot>[sourceSnapshot];

    final readModel = composeSkillDashboardShadowRead(source);
    expect(source, hasLength(1));
    expect(source.single, same(sourceSnapshot));

    source
      ..clear()
      ..add(
        const SkillDashboardCanonicalSnapshot(
          operation: Operation.division,
          mastery: 5,
          attemptCount: 1,
        ),
      );

    expect(readModel.canonicalSkills, hasLength(1));
    expect(
      readModel.canonicalSkills.single.operation,
      Operation.multiplication,
    );
    expect(readModel.canonicalSkills.single.mastery, 64);
    expect(readModel.canonicalSkills.single.attemptCount, 9);
    expect(readModel.canonicalSkills.single, isNot(same(sourceSnapshot)));
    expect(
      () => readModel.canonicalSkills.add(sourceSnapshot),
      throwsUnsupportedError,
    );
  });
}
