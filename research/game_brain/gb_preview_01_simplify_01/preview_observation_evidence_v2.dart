enum EvidenceSlotState { present, absent, missing }

/// Distinguishes a supplied fact from an explicit absence and unavailable data.
class EvidenceSlot<T> {
  const EvidenceSlot.present(T value)
      : this._(EvidenceSlotState.present, value);

  const EvidenceSlot.absent() : this._(EvidenceSlotState.absent, null);

  const EvidenceSlot.missing() : this._(EvidenceSlotState.missing, null);

  const EvidenceSlot._(this.state, this.value);

  final EvidenceSlotState state;
  final T? value;

  bool get isPresent => state == EvidenceSlotState.present;

  @override
  bool operator ==(Object other) =>
      other is EvidenceSlot<T> && other.state == state && other.value == value;

  @override
  int get hashCode => Object.hash(state, value);
}

class BoundedAggregateObservation {
  BoundedAggregateObservation({
    required this.evidenceCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.timeoutCount,
  }) {
    if (evidenceCount < 0 ||
        correctCount < 0 ||
        incorrectCount < 0 ||
        timeoutCount < 0) {
      throw ArgumentError('Observation counts must not be negative.');
    }
    if (evidenceCount != correctCount + incorrectCount + timeoutCount) {
      throw ArgumentError('evidenceCount must equal the outcome counts.');
    }
  }

  final int evidenceCount;
  final int correctCount;
  final int incorrectCount;
  final int timeoutCount;

  double get accuracy => evidenceCount == 0 ? 0 : correctCount / evidenceCount;

  @override
  bool operator ==(Object other) =>
      other is BoundedAggregateObservation &&
      other.evidenceCount == evidenceCount &&
      other.correctCount == correctCount &&
      other.incorrectCount == incorrectCount &&
      other.timeoutCount == timeoutCount;

  @override
  int get hashCode =>
      Object.hash(evidenceCount, correctCount, incorrectCount, timeoutCount);
}

class TemporalComparisonObservation {
  const TemporalComparisonObservation({
    required this.earlier,
    required this.recent,
  });

  final BoundedAggregateObservation earlier;
  final BoundedAggregateObservation recent;

  @override
  bool operator ==(Object other) =>
      other is TemporalComparisonObservation &&
      other.earlier == earlier &&
      other.recent == recent;

  @override
  int get hashCode => Object.hash(earlier, recent);
}

class PreviewObservationEvidenceV2 {
  const PreviewObservationEvidenceV2({
    required this.aggregate,
    this.factualContext = const EvidenceSlot<String>.missing(),
    this.temporalComparison =
        const EvidenceSlot<TemporalComparisonObservation>.missing(),
    this.sparseEvidence = const EvidenceSlot<String>.missing(),
    this.conflictingEvidence = const EvidenceSlot<String>.missing(),
  });

  final EvidenceSlot<BoundedAggregateObservation> aggregate;
  final EvidenceSlot<String> factualContext;
  final EvidenceSlot<TemporalComparisonObservation> temporalComparison;
  final EvidenceSlot<String> sparseEvidence;
  final EvidenceSlot<String> conflictingEvidence;
}

enum PreviewInterpretationRequest {
  boundedObservationSummary,
  observedTemporalDifference,
  reliableImprovement,
  productiveChallenge,
  overchallenge,
  underchallenge,
}

enum PreviewInterpretationState {
  observational,
  insufficient,
  conflicting,
  notEvaluable,
}

enum PreviewAuthority { none }

enum ObservedTemporalDifference { recentHigher, recentEqual, recentLower }

class PreviewInterpretationResult {
  PreviewInterpretationResult({
    required this.interpretationState,
    required List<String> observationsUsed,
    required List<String> supportingEvidence,
    required List<String> contradictingEvidence,
    required List<String> missingEvidence,
    required this.abstentionReason,
    required this.explanation,
    this.temporalDifference,
  })  : observationsUsed = List.unmodifiable(observationsUsed),
        supportingEvidence = List.unmodifiable(supportingEvidence),
        contradictingEvidence = List.unmodifiable(contradictingEvidence),
        missingEvidence = List.unmodifiable(missingEvidence);

  final PreviewInterpretationState interpretationState;
  final List<String> observationsUsed;
  final List<String> supportingEvidence;
  final List<String> contradictingEvidence;
  final List<String> missingEvidence;
  final String? abstentionReason;
  final String explanation;
  final ObservedTemporalDifference? temporalDifference;
  PreviewAuthority get authority => PreviewAuthority.none;
  bool get mayAffectGameplay => false;

  @override
  bool operator ==(Object other) =>
      other is PreviewInterpretationResult &&
      other.interpretationState == interpretationState &&
      _sameList(other.observationsUsed, observationsUsed) &&
      _sameList(other.supportingEvidence, supportingEvidence) &&
      _sameList(other.contradictingEvidence, contradictingEvidence) &&
      _sameList(other.missingEvidence, missingEvidence) &&
      other.abstentionReason == abstentionReason &&
      other.explanation == explanation &&
      other.temporalDifference == temporalDifference;

  @override
  int get hashCode => Object.hash(
        interpretationState,
        Object.hashAll(observationsUsed),
        Object.hashAll(supportingEvidence),
        Object.hashAll(contradictingEvidence),
        Object.hashAll(missingEvidence),
        abstentionReason,
        explanation,
        temporalDifference,
      );
}

bool _sameList<T>(List<T> first, List<T> second) =>
    first.length == second.length &&
    Iterable.generate(first.length)
        .every((index) => first[index] == second[index]);
