import 'package:flutter_test/flutter_test.dart';
import '../../../../research/game_brain/gb_preview_01_simplify_01/accuracy_only_baseline.dart';
import '../../../../research/game_brain/gb_preview_01_simplify_01/minimal_preview_interpreter.dart';
import '../../../../research/game_brain/gb_preview_01_simplify_01/preview_observation_evidence_v2.dart';

void main() {
  const interpreter = MinimalPreviewInterpreter();
  final aggregate = BoundedAggregateObservation(
    evidenceCount: 10,
    correctCount: 8,
    incorrectCount: 2,
    timeoutCount: 0,
  );

  test('1: factual summaries are deterministic', () {
    final evidence = _evidence(aggregate: aggregate);
    final first = interpreter.interpret(
        evidence, PreviewInterpretationRequest.boundedObservationSummary);
    final second = interpreter.interpret(
        evidence, PreviewInterpretationRequest.boundedObservationSummary);

    expect(first, second);
    expect(first.explanation, second.explanation);
  });

  test('2: present, absent, and missing context remain distinct', () {
    final present = _summaryForContext(const EvidenceSlot.present('CTX-A'));
    final absent = _summaryForContext(const EvidenceSlot.absent());
    final missing = _summaryForContext(const EvidenceSlot.missing());

    expect(present.explanation, contains('CTX-A'));
    expect(absent.explanation, contains('explicitly absent'));
    expect(missing.explanation, contains('missing'));
  });

  test('3: temporal increase is observational only', () {
    final result = interpreter.interpret(
      _evidence(
        aggregate: aggregate,
        temporal: TemporalComparisonObservation(
          earlier: BoundedAggregateObservation(
            evidenceCount: 10,
            correctCount: 4,
            incorrectCount: 6,
            timeoutCount: 0,
          ),
          recent: aggregate,
        ),
      ),
      PreviewInterpretationRequest.observedTemporalDifference,
    );

    expect(
        result.interpretationState, PreviewInterpretationState.observational);
    expect(result.temporalDifference, ObservedTemporalDifference.recentHigher);
    expect(result.explanation, contains('RECENT_HIGHER'));
    expect(result.explanation.toLowerCase(), isNot(contains('reliable')));
  });

  test('4: reliable improvement remains not evaluable', () {
    final result = interpreter.interpret(
      _evidence(aggregate: aggregate),
      PreviewInterpretationRequest.reliableImprovement,
    );

    expect(result.interpretationState, PreviewInterpretationState.notEvaluable);
    expect(
        result.abstentionReason, contains('validated reliable-change receipt'));
    expect(result.missingEvidence.single, contains('ValidatedChangeReceipt'));
  });

  test('5: explicit sparse evidence abstains without a numeric threshold', () {
    final result = interpreter.interpret(
      _evidence(
        aggregate: aggregate,
        sparse: const EvidenceSlot.present('Declared sparse evidence'),
      ),
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(result.interpretationState, PreviewInterpretationState.insufficient);
  });

  test('6: explicit conflicting evidence is preserved', () {
    final result = interpreter.interpret(
      _evidence(
        aggregate: aggregate,
        conflict: const EvidenceSlot.present('Incompatible supplied evidence'),
      ),
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(result.interpretationState, PreviewInterpretationState.conflicting);
    expect(result.contradictingEvidence.single,
        contains('Incompatible supplied evidence'));
  });

  test('7: productive challenge is not evaluable', () {
    final result = interpreter.interpret(
      _evidence(aggregate: aggregate),
      PreviewInterpretationRequest.productiveChallenge,
    );
    expect(result.interpretationState, PreviewInterpretationState.notEvaluable);
    expect(result.missingEvidence.single,
        contains('construct evidence/validation'));
    expect(result.missingEvidence.single,
        isNot(contains('ValidatedChangeReceipt')));
  });

  test('8: overchallenge is not evaluable', () {
    final result = interpreter.interpret(
      _evidence(aggregate: aggregate),
      PreviewInterpretationRequest.overchallenge,
    );
    expect(result.interpretationState, PreviewInterpretationState.notEvaluable);
    expect(result.missingEvidence.single,
        contains('construct evidence/validation'));
    expect(result.missingEvidence.single,
        isNot(contains('ValidatedChangeReceipt')));
  });

  test('9: underchallenge is not evaluable', () {
    final result = interpreter.interpret(
      _evidence(aggregate: aggregate),
      PreviewInterpretationRequest.underchallenge,
    );
    expect(result.interpretationState, PreviewInterpretationState.notEvaluable);
    expect(result.missingEvidence.single,
        contains('construct evidence/validation'));
    expect(result.missingEvidence.single,
        isNot(contains('ValidatedChangeReceipt')));
  });

  test('10: identical counts preserve distinct factual contexts', () {
    final contextA = _summaryForContext(const EvidenceSlot.present('CTX-A'));
    final contextB = _summaryForContext(const EvidenceSlot.present('CTX-B'));

    expect(
        contextA.interpretationState, PreviewInterpretationState.observational);
    expect(
        contextB.interpretationState, PreviewInterpretationState.observational);
    expect(contextA.explanation, contains('CTX-A'));
    expect(contextB.explanation, contains('CTX-B'));
  });

  test('11: accuracy-only baseline remains separate from sparse abstention',
      () {
    final baseline = const AccuracyOnlyBaseline().evaluate(aggregate.accuracy);
    final interpreted = interpreter.interpret(
      _evidence(
        aggregate: aggregate,
        sparse: const EvidenceSlot.present('Declared sparse evidence'),
      ),
      PreviewInterpretationRequest.boundedObservationSummary,
    );

    expect(baseline.outcome,
        AccuracyOnlyBaselineOutcome.highPerformancePossiblyHarder);
    expect(interpreted.interpretationState,
        PreviewInterpretationState.insufficient);
  });

  test('12: raw signals do not make unsupported constructs evaluable', () {
    final evidence = _evidence(aggregate: aggregate);
    for (final request in const [
      PreviewInterpretationRequest.reliableImprovement,
      PreviewInterpretationRequest.productiveChallenge,
      PreviewInterpretationRequest.overchallenge,
      PreviewInterpretationRequest.underchallenge,
    ]) {
      expect(
        interpreter.interpret(evidence, request).interpretationState,
        PreviewInterpretationState.notEvaluable,
      );
    }
  });

  test('13: interpreter outputs cannot affect gameplay', () {
    for (final request in PreviewInterpretationRequest.values) {
      final result =
          interpreter.interpret(_evidence(aggregate: aggregate), request);
      expect(result.authority, PreviewAuthority.none);
      expect(result.mayAffectGameplay, isFalse);
    }
  });

  test('14: interpreter explanations exclude forbidden vocabulary', () {
    const forbidden = [
      'mastery',
      'ability',
      'motivation',
      'cognitive load',
      'diagnosis',
      'recommendation'
    ];
    for (final request in PreviewInterpretationRequest.values) {
      final explanation = interpreter
          .interpret(_evidence(aggregate: aggregate), request)
          .explanation
          .toLowerCase();
      for (final word in forbidden) {
        expect(explanation, isNot(contains(word)));
      }
    }
  });

  test('15: invalid aggregate counts are rejected', () {
    expect(
      () => BoundedAggregateObservation(
        evidenceCount: 2,
        correctCount: 1,
        incorrectCount: 0,
        timeoutCount: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => BoundedAggregateObservation(
        evidenceCount: 0,
        correctCount: -1,
        incorrectCount: 1,
        timeoutCount: 0,
      ),
      throwsArgumentError,
    );
  });
}

PreviewInterpretationResult _summaryForContext(EvidenceSlot<String> context) =>
    const MinimalPreviewInterpreter().interpret(
      _evidence(
          aggregate: BoundedAggregateObservation(
            evidenceCount: 10,
            correctCount: 8,
            incorrectCount: 2,
            timeoutCount: 0,
          ),
          factualContext: context),
      PreviewInterpretationRequest.boundedObservationSummary,
    );

PreviewObservationEvidenceV2 _evidence({
  required BoundedAggregateObservation aggregate,
  EvidenceSlot<String> factualContext =
      const EvidenceSlot<String>.present('CTX-A'),
  TemporalComparisonObservation? temporal,
  EvidenceSlot<String> sparse = const EvidenceSlot<String>.missing(),
  EvidenceSlot<String> conflict = const EvidenceSlot<String>.missing(),
}) =>
    PreviewObservationEvidenceV2(
      aggregate: EvidenceSlot.present(aggregate),
      factualContext: factualContext,
      temporalComparison: temporal == null
          ? const EvidenceSlot<TemporalComparisonObservation>.missing()
          : EvidenceSlot.present(temporal),
      sparseEvidence: sparse,
      conflictingEvidence: conflict,
    );
