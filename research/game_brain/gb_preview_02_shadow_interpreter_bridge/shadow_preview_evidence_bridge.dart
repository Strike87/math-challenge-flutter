import 'package:math_challenge/features/game_brain/domain/context_evidence.dart';
import 'package:math_challenge/models/enums.dart';

import '../gb_preview_01_simplify_01/preview_observation_evidence_v2.dart';

class ShadowPreviewEvidenceBridge {
  const ShadowPreviewEvidenceBridge();

  PreviewObservationEvidenceV2 fromObservations(
    List<ContextEvidenceObservation> observations,
  ) {
    final facts = _validateHomogeneous(observations);
    if (facts == null) return _missingEvidence();

    return PreviewObservationEvidenceV2(
      aggregate: EvidenceSlot.present(_aggregate(observations)),
      factualContext: EvidenceSlot.present(_contextId(facts)),
    );
  }

  PreviewObservationEvidenceV2 fromTemporalObservations({
    required List<ContextEvidenceObservation> earlier,
    required List<ContextEvidenceObservation> recent,
  }) {
    final earlierFacts = _validateHomogeneous(earlier);
    final recentFacts = _validateHomogeneous(recent);
    if (earlierFacts == null || recentFacts == null) return _missingEvidence();
    if (earlierFacts.context != recentFacts.context) {
      throw ArgumentError('Temporal observations must have the same context.');
    }
    if (earlierFacts.difficulty != recentFacts.difficulty) {
      throw ArgumentError(
          'Temporal observations must have the same difficulty.');
    }

    return PreviewObservationEvidenceV2(
      aggregate: const EvidenceSlot<BoundedAggregateObservation>.missing(),
      factualContext: EvidenceSlot.present(_contextId(earlierFacts)),
      temporalComparison: EvidenceSlot.present(
        TemporalComparisonObservation(
          earlier: _aggregate(earlier),
          recent: _aggregate(recent),
        ),
      ),
    );
  }

  PreviewObservationEvidenceV2 _missingEvidence() =>
      const PreviewObservationEvidenceV2(
        aggregate: EvidenceSlot<BoundedAggregateObservation>.missing(),
      );

  ({ContextEvidenceKey context, Difficulty difficulty})? _validateHomogeneous(
    List<ContextEvidenceObservation> observations,
  ) {
    if (observations.isEmpty) return null;

    final context = observations.first.context;
    if (context == null) {
      throw ArgumentError('Each observation must have a context.');
    }
    final difficulty = observations.first.difficulty;
    for (final observation in observations) {
      if (observation.context == null) {
        throw ArgumentError('Each observation must have a context.');
      }
      if (observation.context != context) {
        throw ArgumentError('Observations must have the same context.');
      }
      if (observation.difficulty != difficulty) {
        throw ArgumentError('Observations must have the same difficulty.');
      }
    }
    return (context: context, difficulty: difficulty);
  }

  BoundedAggregateObservation _aggregate(
    List<ContextEvidenceObservation> observations,
  ) {
    var correctCount = 0;
    var incorrectCount = 0;
    var timeoutCount = 0;
    for (final observation in observations) {
      if (observation.timedOut) {
        timeoutCount++;
      } else if (observation.correct) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }
    return BoundedAggregateObservation(
      evidenceCount: observations.length,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      timeoutCount: timeoutCount,
    );
  }

  String _contextId(
          ({ContextEvidenceKey context, Difficulty difficulty}) facts) =>
      'operation=${facts.context.operation.name};'
      'numberType=${facts.context.numberType.name};'
      'representation=${facts.context.representation.name};'
      'difficulty=${facts.difficulty.name}';
}
