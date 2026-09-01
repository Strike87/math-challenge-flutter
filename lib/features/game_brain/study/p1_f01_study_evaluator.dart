/// Deterministic, read-only scientific evaluation of the frozen P1-F01 Study
/// record families. This library has no storage, Flutter, gameplay, clock, or
/// identity dependency.
library;

import 'wilson_precision_evaluator.dart';

enum P1StudyCandidate { easy, medium, hard }

enum P1StudyTerminal {
  answeredCorrect,
  answeredIncorrect,
  questionTimedOut,
  questionSkipped,
  questionReplaced,
}

enum P1StudyEvaluationStatus { feasible, inconclusive, notFeasible }

/// Durable governance readiness is deliberately outside the locked scientific
/// terminal taxonomy. A non-ready epoch has no evaluation result.
enum P1StudyAdjudicationReadiness {
  ready,
  samplingIncomplete,
  aborted,
  governanceIncoherent,
}

final class P1StudyEvaluationAttempt {
  const P1StudyEvaluationAttempt({required this.readiness, this.evaluation});
  final P1StudyAdjudicationReadiness readiness;
  final P1StudyEvaluationResult? evaluation;
}

enum P1StudyInconclusiveReason {
  measurementUnavailable,
  missingnessAboveThreshold,
  thresholdUnevaluable,
  precisionInsufficient,
  commonSupportInsufficient,
  legalCoverageInsufficient,
  runOrTemporalDiversityInsufficient,
  unresolvedMajorConfounding,
}

enum P1StudyNotFeasibleReason {
  exposureStarvation,
  comparabilityFailure,
  playerSelectionConfounding,
  adaptiveCanonicalSelectionConfounding,
  modeContextConfounding,
  insufficientRepeatedEvidence,
  legalOptionCoverageFailure,
}

/// The protocol distinguishes a known, exactly stratified selection route from
/// an unresolved route value.  This is deliberately a typed evaluator decision
/// rather than a string-to-terminal shortcut: known routes remain separate
/// common-support strata, while a major unresolved population is only critical
/// when exclusion would remove the minimum scientific measurement.
enum P1StudyConfoundingAssessment {
  none,
  stratified,
  unavailableOrUnknown,
  unresolvedMajor,
  critical,
}

/// One immutable window supplied by the store's read-only projection.
final class P1StudyScientificWindow {
  const P1StudyScientificWindow({
    required this.runSegmentId,
    required this.activityRunContext,
    required this.agencyRoute,
    required this.runType,
    required this.playerCount,
    required this.gameMode,
    required this.questionMechanic,
    required this.answerStyle,
    required this.cleanEligible,
    required this.opportunities,
  });

  final int? runSegmentId;
  final String? activityRunContext;
  final String? agencyRoute;
  final String? runType;
  final int? playerCount;
  final String? gameMode;
  final String? questionMechanic;
  final String? answerStyle;
  final bool cleanEligible;
  final List<P1StudyScientificOpportunity> opportunities;
}

/// One governed opportunity. Nullable values represent durable malformed or
/// unavailable measurements and are deliberately never coerced into evidence.
final class P1StudyScientificOpportunity {
  const P1StudyScientificOpportunity({
    required this.opportunityOrdinalWithinRun,
    required this.decisionContext,
    required this.decisionLocus,
    required this.decisionLocusReason,
    required this.legalCandidates,
    required this.executedCandidate,
    required this.canonicalSelectionMechanism,
    required this.operation,
    required this.numberType,
    required this.terminal,
    required this.acceptedQeoLink,
  });

  final int? opportunityOrdinalWithinRun;
  final String? decisionContext;
  final String? decisionLocus;
  final String? decisionLocusReason;
  final Set<P1StudyCandidate>? legalCandidates;
  final P1StudyCandidate? executedCandidate;
  final String? canonicalSelectionMechanism;
  final String? operation;
  final String? numberType;
  final P1StudyTerminal? terminal;
  final bool? acceptedQeoLink;
}

/// Validated, in-memory Study projection for one epoch. [measurementAvailable]
/// is false when the store cannot truthfully decode its durable rows.
final class P1StudyScientificSnapshot {
  const P1StudyScientificSnapshot({
    required this.epochSequence,
    required this.measurementAvailable,
    required this.windows,
    this.epochStatus,
    this.epochStopReason,
    this.admittedStudyWindowCount,
    this.capacityWindows,
  });

  final int epochSequence;
  final bool measurementAvailable;
  final List<P1StudyScientificWindow> windows;
  final String? epochStatus;
  final String? epochStopReason;
  final int? admittedStudyWindowCount;
  final int? capacityWindows;
}

/// Reviewable aggregate metrics; none contains question, answer, identity, or
/// timestamp payload.
final class P1StudyEvaluationMetrics {
  const P1StudyEvaluationMetrics({
    required this.rawOpportunityCount,
    required this.validOpportunityCount,
    required this.missingOpportunityCount,
    required this.unsupportedOpportunityCount,
    required this.qualifyingStratumCount,
    required this.comparableRunDiversity,
    required this.globalMissingness,
    required this.candidateMetrics,
    required this.starvation,
    required this.playerSelectionConfounding,
    required this.adaptiveCanonicalSelectionConfounding,
    required this.modeContextConfounding,
  });

  final int rawOpportunityCount;
  final int validOpportunityCount;
  final int missingOpportunityCount;
  final int unsupportedOpportunityCount;
  final int qualifyingStratumCount;
  final int comparableRunDiversity;
  final double? globalMissingness;
  final Map<P1StudyCandidate, P1StudyCandidateMetrics> candidateMetrics;
  final double? starvation;
  final P1StudyConfoundingDiagnostics playerSelectionConfounding;
  final P1StudyConfoundingDiagnostics adaptiveCanonicalSelectionConfounding;
  final P1StudyConfoundingDiagnostics modeContextConfounding;
}

final class P1StudyConfoundingDiagnostics {
  const P1StudyConfoundingDiagnostics({
    required this.affected,
    required this.totalOtherwiseEligible,
  });

  final int affected;
  final int totalOtherwiseEligible;
  double? get affectedRate =>
      totalOtherwiseEligible == 0 ? null : affected / totalOtherwiseEligible;
}

final class P1StudyCandidateMetrics {
  const P1StudyCandidateMetrics({
    required this.executedExposure,
    required this.comparableExposure,
    required this.legalCoverage,
    required this.missingness,
    required this.runConcentration,
    required this.temporalConcentration,
    required this.qualifyingStrataRepresented,
    required this.wilson,
  });

  final int executedExposure;
  final int comparableExposure;
  final double? legalCoverage;
  final double? missingness;
  final double? runConcentration;
  final double? temporalConcentration;
  final int qualifyingStrataRepresented;
  final WilsonPrecisionResult wilson;
}

final class P1StudyEvaluationResult {
  const P1StudyEvaluationResult({
    required this.status,
    required this.metrics,
    this.inconclusiveReason,
    this.notFeasibleReason,
  });

  final P1StudyEvaluationStatus status;
  final P1StudyInconclusiveReason? inconclusiveReason;
  final P1StudyNotFeasibleReason? notFeasibleReason;
  final P1StudyEvaluationMetrics metrics;
}

/// Evaluates the locked P1-F00 v1/v1.1/v1.2 definitions without mutating the
/// snapshot or durable epoch state.
P1StudyEvaluationResult _evaluateP1Study(P1StudyScientificSnapshot snapshot) {
  final all = <_Record>[];
  final outside = <_Record>[];
  var unsupported = 0;
  var malformed = !snapshot.measurementAvailable;
  final identities = <(int, int)>{};
  final duplicateIdentities = <(int, int)>{};
  for (final window in snapshot.windows) {
    final segment = window.runSegmentId;
    for (final opportunity in window.opportunities) {
      final ordinal = opportunity.opportunityOrdinalWithinRun;
      if (segment != null && ordinal != null && ordinal >= 1) {
        final identity = (segment, ordinal);
        if (!identities.add(identity)) duplicateIdentities.add(identity);
      }
      final record = _Record(window, opportunity);
      if (_isClearlyOutsideEnvelope(record)) {
        unsupported++;
        outside.add(record);
      } else {
        all.add(record);
      }
    }
  }

  final valid = all.where((record) {
    final segment = record.w.runSegmentId;
    final ordinal = record.o.opportunityOrdinalWithinRun;
    return _isValid(record) &&
        (segment == null ||
            ordinal == null ||
            !duplicateIdentities.contains((segment, ordinal)));
  }).toList(growable: false);
  final missing = all.length - valid.length;
  final metricsBuilder = _MetricsBuilder(
    raw: all,
    valid: valid,
    missing: missing,
    unsupported: unsupported,
  );

  // Step 1: unavailable records are never made scientific evidence, and this
  // precedence intentionally wins over any apparent measurable failure.
  if (malformed || all.isEmpty) {
    return metricsBuilder.result(
      P1StudyEvaluationStatus.inconclusive,
      inconclusive: P1StudyInconclusiveReason.measurementUnavailable,
    );
  }

  final strata = _strata(valid);
  final triStrata = strata.values
      .where((s) => s.key.legalCandidates.length == 3)
      .toList(growable: false);
  final qualifying = triStrata.where(_qualifies).toList(growable: false);
  final comparable =
      qualifying.expand((s) => s.records).toList(growable: false);
  metricsBuilder.setStrata(qualifying, comparable, triStrata);
  final fullOutcome = _measurementOutcome(
    metricsBuilder,
    valid,
    triStrata,
    qualifying,
  );

  final retainedRaw = all.where(_isRetainedMeasurementRecord).toList(
        growable: false,
      );
  final retainedValid =
      valid.where(_isRetainedMeasurementRecord).toList(growable: false);
  final retainedMetricsBuilder = _MetricsBuilder(
    raw: retainedRaw,
    valid: retainedValid,
    missing: retainedRaw.length - retainedValid.length,
    unsupported: 0,
  );
  final retainedStrata = _strata(retainedValid);
  final retainedTriStrata = retainedStrata.values
      .where((stratum) => stratum.key.legalCandidates.length == 3)
      .toList(growable: false);
  final retainedQualifying =
      retainedTriStrata.where(_qualifies).toList(growable: false);
  retainedMetricsBuilder.setStrata(
    retainedQualifying,
    retainedQualifying.expand((stratum) => stratum.records).toList(),
    retainedTriStrata,
  );
  final retainedOutcome = _measurementOutcome(
    retainedMetricsBuilder,
    retainedValid,
    retainedTriStrata,
    retainedQualifying,
  );
  final measurementSurvives =
      retainedOutcome.status == P1StudyEvaluationStatus.feasible;

  final modePopulation = outside.where((record) =>
      _isOtherwiseEligibleForModeContext(record) &&
      !_hasDuplicateIdentity(record, duplicateIdentities));
  final modeConfounding = _assessConfounding(
    affected: modePopulation.length,
    total: all
            .where((record) =>
                _isOtherwiseEligibleForModeContext(record) &&
                !_hasDuplicateIdentity(record, duplicateIdentities))
            .length +
        modePopulation.length,
    measurementSurvives: measurementSurvives,
  );
  final playerSelectionConfounding = _assessPlayerSelectionConfounding(
    all,
    duplicateIdentities,
    measurementSurvives: measurementSurvives,
  );
  final adaptivePopulation = all.where((record) =>
      _isOtherwiseEligibleForCanonicalSelection(record) &&
      !_hasDuplicateIdentity(record, duplicateIdentities));
  final adaptiveConfounding = _assessConfounding(
    affected: all
        .where((record) =>
            _isOtherwiseEligibleForCanonicalSelection(record) &&
            !_hasDuplicateIdentity(record, duplicateIdentities) &&
            record.o.canonicalSelectionMechanism != 'playerConfigured')
        .length,
    total: adaptivePopulation.length,
    measurementSurvives: measurementSurvives,
  );
  metricsBuilder.setConfoundingDiagnostics(
    playerSelectionConfounding.diagnostics,
    adaptiveConfounding.diagnostics,
    modeConfounding.diagnostics,
  );
  if (modeConfounding.assessment == P1StudyConfoundingAssessment.critical) {
    return metricsBuilder.result(
      P1StudyEvaluationStatus.notFeasible,
      notFeasible: P1StudyNotFeasibleReason.modeContextConfounding,
    );
  }
  if (playerSelectionConfounding.assessment ==
      P1StudyConfoundingAssessment.critical) {
    return metricsBuilder.result(
      P1StudyEvaluationStatus.notFeasible,
      notFeasible: P1StudyNotFeasibleReason.playerSelectionConfounding,
    );
  }
  if (adaptiveConfounding.assessment == P1StudyConfoundingAssessment.critical) {
    return metricsBuilder.result(
      P1StudyEvaluationStatus.notFeasible,
      notFeasible:
          P1StudyNotFeasibleReason.adaptiveCanonicalSelectionConfounding,
    );
  }
  // Below the explicit critical-confounding threshold, the locked scientific
  // adjudication remains the only terminal authority.  The retained
  // comparison is deliberately not an attribution heuristic: today it can
  // share the same valid support population as the full evaluation.
  return metricsBuilder.result(
    fullOutcome.status,
    inconclusive: fullOutcome.inconclusiveReason,
    notFeasible: fullOutcome.notFeasibleReason,
  );
}

/// The sole production entry point for a scientific terminal result: only a
/// durably frozen, capacity-complete epoch may produce one.
P1StudyEvaluationAttempt attemptP1Study(P1StudyScientificSnapshot snapshot) {
  final status = snapshot.epochStatus;
  final reason = snapshot.epochStopReason;
  final admitted = snapshot.admittedStudyWindowCount;
  final capacity = snapshot.capacityWindows;
  if (status == 'ABORTED') {
    return const P1StudyEvaluationAttempt(
      readiness: P1StudyAdjudicationReadiness.aborted,
    );
  }
  if (status == 'ACTIVE' && admitted != 49) {
    return const P1StudyEvaluationAttempt(
      readiness: P1StudyAdjudicationReadiness.samplingIncomplete,
    );
  }
  final terminalReady =
      (status == 'FROZEN_FOR_ADJUDICATION' || status == 'ADJUDICATED') &&
          reason == 'capacityReached' &&
          admitted == 49 &&
          capacity == 49;
  if (!terminalReady) {
    return const P1StudyEvaluationAttempt(
      readiness: P1StudyAdjudicationReadiness.governanceIncoherent,
    );
  }
  return P1StudyEvaluationAttempt(
    readiness: P1StudyAdjudicationReadiness.ready,
    evaluation: _evaluateP1Study(snapshot),
  );
}

const _knownAgencyRoutes = {
  'freshSetupAcceptedConfiguration',
  'replayCarriedConfiguration',
};

_ConfoundingAssessment _assessPlayerSelectionConfounding(
  List<_Record> all,
  Set<(int, int)> duplicateIdentities, {
  required bool measurementSurvives,
}) {
  final population = all.where((record) =>
      _isOtherwiseEligibleForPlayerSelection(record) &&
      !_hasDuplicateIdentity(record, duplicateIdentities));
  final unknownRoute = population
      .where((record) => !_knownAgencyRoutes.contains(record.w.agencyRoute))
      .length;
  if (unknownRoute == 0) {
    return _ConfoundingAssessment(
      all.map((r) => r.w.agencyRoute).toSet().length > 1
          ? P1StudyConfoundingAssessment.stratified
          : P1StudyConfoundingAssessment.none,
      affected: 0,
      total: population.length,
    );
  }
  final assessment = _assessConfounding(
    affected: unknownRoute,
    total: population.length,
    measurementSurvives: measurementSurvives,
  );
  return assessment.assessment == P1StudyConfoundingAssessment.none
      ? _ConfoundingAssessment(
          P1StudyConfoundingAssessment.unavailableOrUnknown,
          affected: assessment.diagnostics.affected,
          total: assessment.diagnostics.totalOtherwiseEligible,
        )
      : assessment;
}

final class _ConfoundingAssessment {
  _ConfoundingAssessment(
    this.assessment, {
    required int affected,
    required int total,
  }) : diagnostics = P1StudyConfoundingDiagnostics(
          affected: affected,
          totalOtherwiseEligible: total,
        );

  final P1StudyConfoundingAssessment assessment;
  final P1StudyConfoundingDiagnostics diagnostics;
}

_ConfoundingAssessment _assessConfounding({
  required int affected,
  required int total,
  required bool measurementSurvives,
}) {
  if (affected == 0 || total == 0) {
    return _ConfoundingAssessment(
      P1StudyConfoundingAssessment.none,
      affected: affected,
      total: total,
    );
  }
  return _ConfoundingAssessment(
    measurementSurvives
        ? P1StudyConfoundingAssessment.stratified
        : affected / total > .20
            ? P1StudyConfoundingAssessment.critical
            : P1StudyConfoundingAssessment.unresolvedMajor,
    affected: affected,
    total: total,
  );
}

bool _isRetainedMeasurementRecord(_Record record) =>
    _knownAgencyRoutes.contains(record.w.agencyRoute) &&
    record.o.canonicalSelectionMechanism == 'playerConfigured';

final class _MeasurementOutcome {
  const _MeasurementOutcome(
    this.status, {
    this.inconclusiveReason,
    this.notFeasibleReason,
  });

  final P1StudyEvaluationStatus status;
  final P1StudyInconclusiveReason? inconclusiveReason;
  final P1StudyNotFeasibleReason? notFeasibleReason;
}

_MeasurementOutcome _measurementOutcome(
  _MetricsBuilder metricsBuilder,
  List<_Record> valid,
  List<_Stratum> triStrata,
  List<_Stratum> qualifying,
) {
  if (valid.length >= 300) {
    for (final candidate in P1StudyCandidate.values) {
      if (metricsBuilder.legalCoverage(candidate) == 0) {
        return const _MeasurementOutcome(
          P1StudyEvaluationStatus.notFeasible,
          notFeasibleReason:
              P1StudyNotFeasibleReason.legalOptionCoverageFailure,
        );
      }
      if (metricsBuilder.legalCoverage(candidate)! >= .40 &&
          metricsBuilder.executed(candidate) == 0) {
        return const _MeasurementOutcome(
          P1StudyEvaluationStatus.notFeasible,
          notFeasibleReason: P1StudyNotFeasibleReason.exposureStarvation,
        );
      }
    }
    if (triStrata.isEmpty) {
      return const _MeasurementOutcome(
        P1StudyEvaluationStatus.notFeasible,
        notFeasibleReason: P1StudyNotFeasibleReason.comparabilityFailure,
      );
    }
    if (qualifying.isEmpty) {
      return const _MeasurementOutcome(
        P1StudyEvaluationStatus.notFeasible,
        notFeasibleReason:
            P1StudyNotFeasibleReason.insufficientRepeatedEvidence,
      );
    }
  }
  if (P1StudyCandidate.values.any((candidate) =>
      metricsBuilder.legalCoverage(candidate) == null ||
      metricsBuilder.missingness(candidate) == null)) {
    return const _MeasurementOutcome(
      P1StudyEvaluationStatus.inconclusive,
      inconclusiveReason: P1StudyInconclusiveReason.thresholdUnevaluable,
    );
  }
  if (metricsBuilder.globalMissingness! > .05 ||
      P1StudyCandidate.values.any(
        (candidate) => metricsBuilder.missingness(candidate)! > .10,
      )) {
    return const _MeasurementOutcome(
      P1StudyEvaluationStatus.inconclusive,
      inconclusiveReason: P1StudyInconclusiveReason.missingnessAboveThreshold,
    );
  }
  if (valid.length < 300 ||
      P1StudyCandidate.values
          .any((candidate) => metricsBuilder.executed(candidate) < 60) ||
      metricsBuilder.starvation == null ||
      metricsBuilder.starvation! > .20 ||
      qualifying.length < 3 ||
      P1StudyCandidate.values
          .any((candidate) => metricsBuilder.comparable(candidate) < 30)) {
    return const _MeasurementOutcome(
      P1StudyEvaluationStatus.inconclusive,
      inconclusiveReason: P1StudyInconclusiveReason.commonSupportInsufficient,
    );
  }
  if (P1StudyCandidate.values
      .any((candidate) => metricsBuilder.legalCoverage(candidate)! < .40)) {
    return const _MeasurementOutcome(
      P1StudyEvaluationStatus.inconclusive,
      inconclusiveReason: P1StudyInconclusiveReason.legalCoverageInsufficient,
    );
  }
  if (metricsBuilder.runDiversity < 10 ||
      P1StudyCandidate.values.any(
        (candidate) =>
            metricsBuilder.runConcentration(candidate)! > .25 ||
            metricsBuilder.temporalConcentration(candidate)! > .50,
      )) {
    return const _MeasurementOutcome(
      P1StudyEvaluationStatus.inconclusive,
      inconclusiveReason:
          P1StudyInconclusiveReason.runOrTemporalDiversityInsufficient,
    );
  }
  if (P1StudyCandidate.values.any(
    (candidate) =>
        metricsBuilder.strataRepresented(candidate) < 3 ||
        metricsBuilder.wilson(candidate).status !=
            WilsonEvaluationStatus.evaluable ||
        metricsBuilder.wilson(candidate).meetsPrecision != true,
  )) {
    return const _MeasurementOutcome(
      P1StudyEvaluationStatus.inconclusive,
      inconclusiveReason: P1StudyInconclusiveReason.precisionInsufficient,
    );
  }
  return const _MeasurementOutcome(P1StudyEvaluationStatus.feasible);
}

bool _isClearlyOutsideEnvelope(_Record r) =>
    (r.w.runType != null && r.w.runType != 'normal') ||
    (r.w.playerCount != null && r.w.playerCount != 1) ||
    (r.w.gameMode != null && r.w.gameMode != 'standard') ||
    (r.w.questionMechanic != null && r.w.questionMechanic != 'standard') ||
    (r.w.answerStyle != null && r.w.answerStyle != 'choice4');

bool _isOtherwiseEligibleForPlayerSelection(_Record record) =>
    _hasScientificValidity(record, allowUnknownRoute: true);

bool _isOtherwiseEligibleForCanonicalSelection(_Record record) =>
    _hasScientificValidity(record, allowNonPlayerConfigured: true);

bool _isOtherwiseEligibleForModeContext(_Record record) =>
    _hasValidNonEnvelopeScientificFields(record) &&
    _hasCompleteModeContextClassification(record);

bool _hasValidNonEnvelopeScientificFields(_Record record) =>
    _hasScientificValidity(record, allowOutsideEnvelope: true);

bool _hasCompleteModeContextClassification(_Record record) =>
    record.w.runType != null &&
    record.w.playerCount != null &&
    record.w.gameMode != null &&
    record.w.questionMechanic != null &&
    record.w.answerStyle != null;

bool _hasDuplicateIdentity(_Record record, Set<(int, int)> duplicates) {
  final segment = record.w.runSegmentId;
  final ordinal = record.o.opportunityOrdinalWithinRun;
  return segment != null &&
      ordinal != null &&
      duplicates.contains((segment, ordinal));
}

bool _isValid(_Record record) => _hasScientificValidity(record);

bool _hasScientificValidity(
  _Record r, {
  bool allowUnknownRoute = false,
  bool allowNonPlayerConfigured = false,
  bool allowOutsideEnvelope = false,
}) {
  final o = r.o;
  return r.w.cleanEligible &&
      r.w.runSegmentId != null &&
      o.opportunityOrdinalWithinRun != null &&
      o.opportunityOrdinalWithinRun! >= 1 &&
      o.opportunityOrdinalWithinRun! <= 25 &&
      o.decisionContext == 'chooseDifficulty' &&
      o.decisionLocus == 'questionOpeningDifficultyResolution' &&
      o.decisionLocusReason == 'difficultyRequiredForQuestionOpening' &&
      o.legalCandidates != null &&
      o.executedCandidate != null &&
      o.legalCandidates!.contains(o.executedCandidate) &&
      (allowNonPlayerConfigured ||
          o.canonicalSelectionMechanism == 'playerConfigured') &&
      _operations.contains(o.operation) &&
      _numberTypes.contains(o.numberType) &&
      r.w.activityRunContext != null &&
      (allowUnknownRoute || _knownAgencyRoutes.contains(r.w.agencyRoute)) &&
      (allowOutsideEnvelope
          ? _hasCompleteModeContextClassification(r)
          : r.w.runType == 'normal' &&
              r.w.playerCount == 1 &&
              r.w.gameMode == 'standard' &&
              r.w.questionMechanic == 'standard' &&
              r.w.answerStyle == 'choice4') &&
      o.acceptedQeoLink == true &&
      o.terminal != null;
}

const _operations = {
  'addition',
  'subtraction',
  'multiplication',
  'division',
  'mixed',
  'master',
  'dailyBoss',
  'survival',
};
const _numberTypes = {'natural', 'integers', 'rationals', 'mixed'};

Map<_SupportKey, _Stratum> _strata(List<_Record> records) {
  final result = <_SupportKey, _Stratum>{};
  for (final record in records) {
    final key = _SupportKey(record);
    (result[key] ??= _Stratum(key)).records.add(record);
  }
  return result;
}

bool _qualifies(_Stratum stratum) {
  if (stratum.key.legalCandidates.length != 3) return false;
  final counts = P1StudyCandidate.values
      .map(
        (c) => stratum.records.where((r) => r.o.executedCandidate == c).length,
      )
      .toList(growable: false);
  final min = counts.reduce((a, b) => a < b ? a : b);
  final max = counts.reduce((a, b) => a > b ? a : b);
  return min >= 10 && max / min <= 3;
}

final class _Record {
  const _Record(this.w, this.o);
  final P1StudyScientificWindow w;
  final P1StudyScientificOpportunity o;
}

final class _SupportKey {
  _SupportKey(_Record r)
      : legalCandidates = Set.unmodifiable(r.o.legalCandidates!),
        values = (
          r.o.decisionContext!,
          r.o.decisionLocus!,
          r.o.decisionLocusReason!,
          r.w.agencyRoute!,
          r.o.canonicalSelectionMechanism!,
          r.o.operation!,
          r.o.numberType!,
          r.w.answerStyle!,
          r.w.runType!,
          r.w.playerCount!,
          r.w.gameMode!,
          r.w.questionMechanic!,
          r.w.activityRunContext!,
        );
  final Set<P1StudyCandidate> legalCandidates;
  final (
    String,
    String,
    String,
    String,
    String,
    String,
    String,
    String,
    String,
    int,
    String,
    String,
    String,
  ) values;
  @override
  bool operator ==(Object other) =>
      other is _SupportKey &&
      _sameSet(legalCandidates, other.legalCandidates) &&
      values == other.values;
  @override
  int get hashCode =>
      Object.hashAll([Object.hashAllUnordered(legalCandidates), values]);
}

bool _sameSet<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

final class _Stratum {
  _Stratum(this.key);
  final _SupportKey key;
  final List<_Record> records = <_Record>[];
}

final class _MetricsBuilder {
  _MetricsBuilder({
    required this.raw,
    required this.valid,
    required this.missing,
    required this.unsupported,
  });
  final List<_Record> raw;
  final List<_Record> valid;
  final int missing;
  final int unsupported;
  List<_Stratum> _qualifying = const [];
  List<_Record> _comparable = const [];
  List<_Stratum> _tri = const [];
  P1StudyConfoundingDiagnostics _playerSelectionConfounding =
      const P1StudyConfoundingDiagnostics(
          affected: 0, totalOtherwiseEligible: 0);
  P1StudyConfoundingDiagnostics _adaptiveCanonicalSelectionConfounding =
      const P1StudyConfoundingDiagnostics(
          affected: 0, totalOtherwiseEligible: 0);
  P1StudyConfoundingDiagnostics _modeContextConfounding =
      const P1StudyConfoundingDiagnostics(
          affected: 0, totalOtherwiseEligible: 0);

  void setStrata(
    List<_Stratum> qualifying,
    List<_Record> comparable,
    List<_Stratum> tri,
  ) {
    _qualifying = qualifying;
    _comparable = comparable;
    _tri = tri;
  }

  void setConfoundingDiagnostics(
    P1StudyConfoundingDiagnostics playerSelection,
    P1StudyConfoundingDiagnostics adaptiveCanonicalSelection,
    P1StudyConfoundingDiagnostics modeContext,
  ) {
    _playerSelectionConfounding = playerSelection;
    _adaptiveCanonicalSelectionConfounding = adaptiveCanonicalSelection;
    _modeContextConfounding = modeContext;
  }

  int executed(P1StudyCandidate c) =>
      valid.where((r) => r.o.executedCandidate == c).length;
  int comparable(P1StudyCandidate c) =>
      _comparable.where((r) => r.o.executedCandidate == c).length;
  double? legalCoverage(P1StudyCandidate c) => valid.isEmpty
      ? null
      : valid.where((r) => r.o.legalCandidates!.contains(c)).length /
          valid.length;
  double? missingness(P1StudyCandidate c) {
    final denominator =
        raw.where((r) => r.o.legalCandidates?.contains(c) ?? false).toList();
    return denominator.isEmpty
        ? null
        : denominator.where((r) => !_isValid(r)).length / denominator.length;
  }

  double? get globalMissingness => raw.isEmpty ? null : missing / raw.length;
  double? get starvation {
    if (_tri.isEmpty) return null;
    return _tri
            .where(
              (s) => P1StudyCandidate.values.any(
                (c) =>
                    s.records.where((r) => r.o.executedCandidate == c).length <
                    10,
              ),
            )
            .length /
        _tri.length;
  }

  int get runDiversity =>
      _comparable.map((r) => r.w.runSegmentId!).toSet().length;
  double? runConcentration(P1StudyCandidate c) {
    final records =
        _comparable.where((r) => r.o.executedCandidate == c).toList();
    if (records.isEmpty) return null;
    final counts = <int, int>{};
    for (final r in records) {
      counts.update(r.w.runSegmentId!, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts.values.reduce((a, b) => a > b ? a : b) / records.length;
  }

  double? temporalConcentration(P1StudyCandidate c) {
    if (_comparable.isEmpty) return null;
    final ordered = [..._comparable]..sort((a, b) {
        final run = a.w.runSegmentId!.compareTo(b.w.runSegmentId!);
        return run != 0
            ? run
            : a.o.opportunityOrdinalWithinRun!.compareTo(
                b.o.opportunityOrdinalWithinRun!,
              );
      });
    final total = ordered.where((r) => r.o.executedCandidate == c).length;
    if (total == 0) return null;
    var max = 0;
    for (var bin = 0; bin < 5; bin++) {
      final start = ordered.length * bin ~/ 5;
      final end = ordered.length * (bin + 1) ~/ 5;
      final count = ordered
          .sublist(start, end)
          .where((r) => r.o.executedCandidate == c)
          .length;
      if (count > max) max = count;
    }
    return max / total;
  }

  int strataRepresented(P1StudyCandidate c) => _qualifying
      .where((s) => s.records.any((r) => r.o.executedCandidate == c))
      .length;
  WilsonPrecisionResult wilson(P1StudyCandidate c) {
    final records =
        _comparable.where((r) => r.o.executedCandidate == c).toList();
    return evaluateWilsonPrecision(
      WilsonBinomialSummary(
        successes: records
            .where((r) => r.o.terminal == P1StudyTerminal.answeredCorrect)
            .length,
        trials: records.length,
      ),
    );
  }

  P1StudyEvaluationResult result(
    P1StudyEvaluationStatus status, {
    P1StudyInconclusiveReason? inconclusive,
    P1StudyNotFeasibleReason? notFeasible,
  }) {
    final byCandidate =
        Map<P1StudyCandidate, P1StudyCandidateMetrics>.unmodifiable({
      for (final c in P1StudyCandidate.values)
        c: P1StudyCandidateMetrics(
          executedExposure: executed(c),
          comparableExposure: comparable(c),
          legalCoverage: legalCoverage(c),
          missingness: missingness(c),
          runConcentration: runConcentration(c),
          temporalConcentration: temporalConcentration(c),
          qualifyingStrataRepresented: strataRepresented(c),
          wilson: wilson(c),
        ),
    });
    return P1StudyEvaluationResult(
      status: status,
      inconclusiveReason: inconclusive,
      notFeasibleReason: notFeasible,
      metrics: P1StudyEvaluationMetrics(
        rawOpportunityCount: raw.length,
        validOpportunityCount: valid.length,
        missingOpportunityCount: missing,
        unsupportedOpportunityCount: unsupported,
        qualifyingStratumCount: _qualifying.length,
        comparableRunDiversity: runDiversity,
        globalMissingness: globalMissingness,
        candidateMetrics: byCandidate,
        starvation: starvation,
        playerSelectionConfounding: _playerSelectionConfounding,
        adaptiveCanonicalSelectionConfounding:
            _adaptiveCanonicalSelectionConfounding,
        modeContextConfounding: _modeContextConfounding,
      ),
    );
  }
}
