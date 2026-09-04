import 'preview_observation_evidence_v2.dart';

class MinimalPreviewInterpreter {
  const MinimalPreviewInterpreter();

  PreviewInterpretationResult interpret(
    PreviewObservationEvidenceV2 evidence,
    PreviewInterpretationRequest request,
  ) {
    switch (request) {
      case PreviewInterpretationRequest.reliableImprovement:
        return _notEvaluable(
          'A validated reliable-change receipt is unavailable.',
          'ValidatedChangeReceipt unavailable',
        );
      case PreviewInterpretationRequest.productiveChallenge:
      case PreviewInterpretationRequest.overchallenge:
      case PreviewInterpretationRequest.underchallenge:
        return _notEvaluable(
          'The requested construct is not evaluable under the current evidence contract.',
          'Required construct evidence/validation unavailable under the current contract',
        );
      case PreviewInterpretationRequest.boundedObservationSummary:
        return _summarize(evidence);
      case PreviewInterpretationRequest.observedTemporalDifference:
        return _compareTemporal(evidence);
    }
  }

  PreviewInterpretationResult _summarize(
      PreviewObservationEvidenceV2 evidence) {
    final conflict = evidence.conflictingEvidence;
    if (conflict.isPresent) {
      return PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.conflicting,
        observationsUsed: const ['explicit conflicting evidence'],
        supportingEvidence: const [],
        contradictingEvidence: [_slotText('Conflicting evidence', conflict)],
        missingEvidence: const [],
        abstentionReason:
            'Explicit conflicting evidence was supplied; no winner is forced.',
        explanation:
            'Conflicting evidence was supplied and is preserved without a forced winner.',
      );
    }
    final sparse = evidence.sparseEvidence;
    if (sparse.isPresent) {
      return PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.insufficient,
        observationsUsed: const ['explicit sparse evidence'],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        missingEvidence: [_slotText('Sparse evidence', sparse)],
        abstentionReason: 'Sparse evidence was explicitly supplied.',
        explanation:
            'A bounded summary is insufficient because sparse evidence was explicitly supplied.',
      );
    }
    final aggregate = evidence.aggregate;
    if (!aggregate.isPresent) {
      final description = _slotText('Aggregate observation', aggregate);
      return PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.insufficient,
        observationsUsed: const [],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        missingEvidence: [description],
        abstentionReason: 'The aggregate observation is not present.',
        explanation: 'A bounded summary is insufficient because $description.',
      );
    }

    final observation = aggregate.value!;
    final context = _slotText('Factual context', evidence.factualContext);
    return PreviewInterpretationResult(
      interpretationState: PreviewInterpretationState.observational,
      observationsUsed: const [
        'bounded aggregate observation',
        'factual context state'
      ],
      supportingEvidence: [
        'Counts: ${observation.evidenceCount} total, ${observation.correctCount} correct, ${observation.incorrectCount} incorrect, ${observation.timeoutCount} timeout.',
        'Derived accuracy: ${observation.accuracy.toStringAsFixed(2)}.',
        context,
      ],
      contradictingEvidence: const [],
      missingEvidence: const [],
      abstentionReason: null,
      explanation:
          'Observed counts are ${observation.correctCount} correct, ${observation.incorrectCount} incorrect, and ${observation.timeoutCount} timeout; derived accuracy is ${observation.accuracy.toStringAsFixed(2)}. $context.',
    );
  }

  PreviewInterpretationResult _compareTemporal(
      PreviewObservationEvidenceV2 evidence) {
    final conflict = evidence.conflictingEvidence;
    if (conflict.isPresent) {
      return PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.conflicting,
        observationsUsed: const ['explicit conflicting evidence'],
        supportingEvidence: const [],
        contradictingEvidence: [_slotText('Conflicting evidence', conflict)],
        missingEvidence: const [],
        abstentionReason:
            'Explicit conflicting evidence was supplied; no winner is forced.',
        explanation:
            'Conflicting evidence was supplied and is preserved without a forced winner.',
      );
    }
    final sparse = evidence.sparseEvidence;
    if (sparse.isPresent) {
      return PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.insufficient,
        observationsUsed: const ['explicit sparse evidence'],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        missingEvidence: [_slotText('Sparse evidence', sparse)],
        abstentionReason: 'Sparse evidence was explicitly supplied.',
        explanation:
            'A temporal comparison is insufficient because sparse evidence was explicitly supplied.',
      );
    }
    final temporal = evidence.temporalComparison;
    if (!temporal.isPresent) {
      final description = _slotText('Temporal comparison', temporal);
      return PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.insufficient,
        observationsUsed: const [],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        missingEvidence: [description],
        abstentionReason: 'The temporal comparison is not present.',
        explanation:
            'A temporal comparison is insufficient because $description.',
      );
    }

    final comparison = temporal.value!;
    final difference = switch (
        comparison.recent.accuracy.compareTo(comparison.earlier.accuracy)) {
      1 => ObservedTemporalDifference.recentHigher,
      0 => ObservedTemporalDifference.recentEqual,
      _ => ObservedTemporalDifference.recentLower,
    };
    final label = switch (difference) {
      ObservedTemporalDifference.recentHigher => 'RECENT_HIGHER',
      ObservedTemporalDifference.recentEqual => 'RECENT_EQUAL',
      ObservedTemporalDifference.recentLower => 'RECENT_LOWER',
    };
    return PreviewInterpretationResult(
      interpretationState: PreviewInterpretationState.observational,
      observationsUsed: const [
        'explicit earlier and recent aggregate observations'
      ],
      supportingEvidence: [label],
      contradictingEvidence: const [],
      missingEvidence: const [],
      abstentionReason: null,
      explanation: 'The supplied temporal comparison is $label.',
      temporalDifference: difference,
    );
  }

  PreviewInterpretationResult _notEvaluable(
          String reason, String missingEvidence) =>
      PreviewInterpretationResult(
        interpretationState: PreviewInterpretationState.notEvaluable,
        observationsUsed: const [],
        supportingEvidence: const [],
        contradictingEvidence: const [],
        missingEvidence: [missingEvidence],
        abstentionReason: reason,
        explanation: reason,
      );

  String _slotText<T>(String label, EvidenceSlot<T> slot) =>
      switch (slot.state) {
        EvidenceSlotState.present => '$label: ${slot.value}',
        EvidenceSlotState.absent => '$label: explicitly absent',
        EvidenceSlotState.missing => '$label: missing',
      };
}
