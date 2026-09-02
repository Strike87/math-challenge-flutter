import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../models/enums.dart';
import '../../gameplay/domain/question_mechanic.dart';
import '../experience/p1_f01_integrity_store.dart';
import 'p1_f01_study_evaluator.dart';

enum _ScientificWindowFinalState {
  clean,
  nonClean,
  structurallyUnavailable,
}

final class _ScientificWindowFinalValidation {
  const _ScientificWindowFinalValidation(this.state, this.missingLegalSets);

  final _ScientificWindowFinalState state;
  final Map<String, int> missingLegalSets;
}

enum P1StudyEpochStatus {
  active('ACTIVE'),
  frozenForAdjudication('FROZEN_FOR_ADJUDICATION'),
  adjudicated('ADJUDICATED'),
  aborted('ABORTED');

  const P1StudyEpochStatus(this.storageValue);
  final String storageValue;

  static P1StudyEpochStatus parse(String value) => values.singleWhere(
        (entry) => entry.storageValue == value,
      );
}

enum P1StudyEpochStopReason {
  none('none'),
  capacityReached('capacityReached'),
  userReset('userReset'),
  measurementUnavailable('measurementUnavailable'),
  administrativeAbortIndependentOfResult(
    'administrativeAbortIndependentOfResult',
  );

  const P1StudyEpochStopReason(this.storageValue);
  final String storageValue;

  static P1StudyEpochStopReason parse(String value) => values.singleWhere(
        (entry) => entry.storageValue == value,
      );
}

enum P1AdministrativeAbortActingRole {
  productGovernance('PRODUCT_GOVERNANCE'),
  releaseGovernance('RELEASE_GOVERNANCE'),
  dataGovernance('DATA_GOVERNANCE'),
  protocolGovernance('PROTOCOL_GOVERNANCE');

  const P1AdministrativeAbortActingRole(this.storageValue);
  final String storageValue;

  static P1AdministrativeAbortActingRole parse(String value) =>
      values.singleWhere((entry) => entry.storageValue == value);
}

enum P1ActivityRunContext {
  quickPracticeTimingPractice('quickPracticeTimingPractice'),
  unknown('unknown');

  const P1ActivityRunContext(this.storageValue);
  final String storageValue;
}

enum P1AgencyRoute {
  freshSetupAcceptedConfiguration('freshSetupAcceptedConfiguration'),
  replayCarriedConfiguration('replayCarriedConfiguration'),
  unknown('unknown');

  const P1AgencyRoute(this.storageValue);
  final String storageValue;
}

enum P1StudyWindowDisposition {
  cleanEligible('cleanEligible'),
  nonCleanCensored('nonCleanCensored'),
  nonCleanMeasurementFailure('nonCleanMeasurementFailure'),
  aborted('aborted');

  const P1StudyWindowDisposition(this.storageValue);
  final String storageValue;
}

enum P1StudyNonCleanCause {
  none('none'),
  lifecycleInterruption('lifecycleInterruption'),
  switchOpEnvelopeExit('switchOpEnvelopeExit'),
  followUpEnvelopeExit('followUpEnvelopeExit'),
  userReset('userReset'),
  administrativeAbortIndependentOfResult(
    'administrativeAbortIndependentOfResult',
  ),
  unknownNonCleanCause('unknownNonCleanCause');

  const P1StudyNonCleanCause(this.storageValue);
  final String storageValue;
}

enum P1StudyMeasurementDefect {
  none('none'),
  explicitUnlinkedTerminal('explicitUnlinkedTerminal'),
  studyPersistenceFailure('studyPersistenceFailure'),
  integrityAdmissionFailure('integrityAdmissionFailure'),
  integrityReconciliationFailure('integrityReconciliationFailure'),
  integrityClosureFailure('integrityClosureFailure'),
  recoverySequenceMismatch('recoverySequenceMismatch'),
  integritySnapshotUnavailable('integritySnapshotUnavailable'),
  unknownMeasurementFailure('unknownMeasurementFailure');

  const P1StudyMeasurementDefect(this.storageValue);
  final String storageValue;
}

enum P1StudyCanonicalTerminalOutcome {
  answeredCorrect('AnsweredCorrect'),
  answeredIncorrect('AnsweredIncorrect'),
  questionTimedOut('QuestionTimedOut'),
  questionSkipped('QuestionSkipped'),
  questionReplaced('QuestionReplaced');

  const P1StudyCanonicalTerminalOutcome(this.storageValue);
  final String storageValue;
}

enum P1StudyStoreOperation {
  createEpoch,
  openWindow,
  openOpportunity,
  recordTerminal,
  finalizeWindow,
  recover,
  abortEpoch,
  deleteAll,
}

@immutable
final class P1StudyEpoch {
  const P1StudyEpoch({
    required this.epochSequence,
    required this.status,
    required this.stopReason,
    required this.admittedStudyWindowCount,
    required this.epochTerminalTimestampUtc,
    required this.administrativeAbortActingRole,
    required this.administrativeAbortMetricsNotAccessed,
  });

  final int epochSequence;
  final P1StudyEpochStatus status;
  final P1StudyEpochStopReason stopReason;
  final int admittedStudyWindowCount;
  final String? epochTerminalTimestampUtc;
  final P1AdministrativeAbortActingRole? administrativeAbortActingRole;
  final bool? administrativeAbortMetricsNotAccessed;
}

@immutable
final class P1StudyWindowOpen {
  const P1StudyWindowOpen({
    required this.epochSequence,
    required this.integrityWindowSequence,
    required this.activityRunContext,
    required this.agencyRoute,
    required this.runType,
    required this.playerCount,
    required this.gameMode,
    required this.questionMechanic,
    required this.answerStyle,
  });

  final int epochSequence;
  final int integrityWindowSequence;
  final P1ActivityRunContext activityRunContext;
  final P1AgencyRoute agencyRoute;
  final GameRunType runType;
  final int playerCount;
  final GameMode gameMode;
  final QuestionMechanic questionMechanic;
  final AnswerStyle answerStyle;
}

@immutable
final class P1StudyOpportunityOpen {
  const P1StudyOpportunityOpen({
    required this.integrityWindowSequence,
    required this.opportunityOrdinalWithinRun,
    required this.exactLegalCandidateSetCode,
    required this.executedDifficulty,
    required this.effectiveQuestionOperation,
    required this.numberType,
  });

  final int integrityWindowSequence;
  final int opportunityOrdinalWithinRun;
  final P1F01LegalSetCode exactLegalCandidateSetCode;
  final Difficulty executedDifficulty;
  final Operation effectiveQuestionOperation;
  final NumberType numberType;
}

@immutable
final class P1StudyOpportunityTerminal {
  const P1StudyOpportunityTerminal({
    required this.integrityWindowSequence,
    required this.opportunityOrdinalWithinRun,
    required this.canonicalTerminalOutcome,
  });

  final int integrityWindowSequence;
  final int opportunityOrdinalWithinRun;
  final P1StudyCanonicalTerminalOutcome canonicalTerminalOutcome;
}

@immutable
final class P1StudyWindowFinal {
  const P1StudyWindowFinal({
    required this.integrityWindowSequence,
    required this.studyDisposition,
    required this.nonCleanCause,
    required this.measurementDefect,
    required this.recoveredAfterRestart,
    required this.integritySnapshot,
    required this.studyOpeningReceiptCount,
    required this.studyTerminalReceiptCount,
  });

  final int integrityWindowSequence;
  final P1StudyWindowDisposition studyDisposition;
  final P1StudyNonCleanCause nonCleanCause;
  final P1StudyMeasurementDefect measurementDefect;
  final bool recoveredAfterRestart;
  final P1F01IntegritySnapshot integritySnapshot;
  final int studyOpeningReceiptCount;
  final int studyTerminalReceiptCount;
}

final class P1F01StudyStore {
  P1F01StudyStore({
    DatabaseFactory? databaseFactory,
    String? databasePath,
    this.failureHook,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  static const int studySchemaVersion = 1;
  static const int semanticTaxonomyVersion = 1;
  static const String p1F00ProtocolVersion = '1.2';
  static const String sampleProtocolId = 'P1-SE-SAMPLE-00';
  static const int sampleProtocolVersion = 1;
  static const int capacityWindows = 49;
  // Frozen P1-F00 v1.2 per-window Phase-1 opening ceiling.
  static const int _maxOpeningsPerWindow = 25;
  static const int maxOpportunityRows = 1225;
  static const int maxPriorTerminalEpochs = 16;

  static const epochTable = 'study_epoch';
  static const windowOpenTable = 'study_window_open';
  static const opportunityOpenTable = 'study_opportunity_open';
  static const opportunityTerminalTable = 'study_opportunity_terminal';
  static const windowFinalTable = 'study_window_final';

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  final void Function(P1StudyStoreOperation operation)? failureHook;
  Future<void> _queue = Future<void>.value();
  Database? _database;

  bool get isOpen => _database != null;

  Future<P1StudyEpoch?> createOrLoadActiveEpoch() => _guarded<P1StudyEpoch?>(
        P1StudyStoreOperation.createEpoch,
        () => _serialize(() async {
          final db = await _db();
          return db.transaction((txn) async {
            _fail(P1StudyStoreOperation.createEpoch);
            await _validateAllPersistedEpochs(txn);
            final active = await txn.query(
              epochTable,
              where: 'epoch_status IN (?, ?)',
              whereArgs: [
                P1StudyEpochStatus.active.storageValue,
                P1StudyEpochStatus.frozenForAdjudication.storageValue,
              ],
              orderBy: 'epoch_sequence DESC',
              limit: 1,
            );
            if (active.isNotEmpty) return _epochFromRow(active.single);
            final terminalRows = await txn.query(
              epochTable,
              where: 'epoch_status IN (?, ?)',
              whereArgs: [
                P1StudyEpochStatus.adjudicated.storageValue,
                P1StudyEpochStatus.aborted.storageValue,
              ],
            );
            for (final row in terminalRows) {
              _epochFromRow(row);
            }
            final adjudicated = terminalRows
                .where((row) =>
                    row['epoch_status'] ==
                    P1StudyEpochStatus.adjudicated.storageValue)
                .length;
            final terminal = terminalRows.length;
            if (adjudicated > 0 || terminal >= maxPriorTerminalEpochs) {
              return null;
            }
            final sequence = await txn.insert(epochTable, {
              'study_schema_version': studySchemaVersion,
              'p1_f00_protocol_version': p1F00ProtocolVersion,
              'sample_protocol_id': sampleProtocolId,
              'sample_protocol_version': sampleProtocolVersion,
              'c_windows': capacityWindows,
              'semantic_taxonomy_version': semanticTaxonomyVersion,
              'epoch_status': P1StudyEpochStatus.active.storageValue,
              'epoch_stop_reason': P1StudyEpochStopReason.none.storageValue,
              'admitted_study_window_count': 0,
            });
            return _epochFromRow((await txn.query(
              epochTable,
              where: 'epoch_sequence = ?',
              whereArgs: [sequence],
            ))
                .single);
          });
        }),
      );

  Future<P1StudyEpoch?> activeEpoch() => _guarded<P1StudyEpoch?>(
        P1StudyStoreOperation.recover,
        () => _serialize(() async {
          final db = await _db();
          await _validateAllPersistedEpochs(db);
          final rows = await db.query(
            epochTable,
            where: 'epoch_status IN (?, ?)',
            whereArgs: [
              P1StudyEpochStatus.active.storageValue,
              P1StudyEpochStatus.frozenForAdjudication.storageValue,
            ],
            orderBy: 'epoch_sequence DESC',
            limit: 1,
          );
          return rows.isEmpty ? null : _epochFromRow(rows.single);
        }),
      );

  Future<List<P1StudyEpoch>> terminalEpochs() async {
    final epochs = await _guarded<List<P1StudyEpoch>>(
      P1StudyStoreOperation.recover,
      () => _serialize(() async {
        final db = await _db();
        await _validateAllPersistedEpochs(db);
        final rows = await db.query(
          epochTable,
          where: 'epoch_status IN (?, ?)',
          whereArgs: [
            P1StudyEpochStatus.adjudicated.storageValue,
            P1StudyEpochStatus.aborted.storageValue,
          ],
          orderBy: 'epoch_sequence ASC',
        );
        return List.unmodifiable(rows.map(_epochFromRow));
      }),
    );
    return epochs ?? const <P1StudyEpoch>[];
  }

  /// Read-only projection over existing receipts; it neither writes nor adds
  /// retained data. Unknown durable values become unavailable evaluator input.
  Future<P1StudyScientificSnapshot?> scientificSnapshot(int epochSequence) =>
      _guarded<P1StudyScientificSnapshot?>(
        P1StudyStoreOperation.recover,
        () => _serialize(() async {
          final db = await _db();
          await _validateAllPersistedEpochs(db);
          final epoch = await db.query(epochTable,
              where: 'epoch_sequence = ?',
              whereArgs: [epochSequence],
              limit: 1);
          if (epoch.isEmpty) return null;
          _epochFromRow(epoch.single);
          final epochRow = epoch.single;
          final terminalEpoch = {
            P1StudyEpochStatus.frozenForAdjudication.storageValue,
            P1StudyEpochStatus.adjudicated.storageValue,
          }.contains(epochRow['epoch_status']);
          final windows = await db.query(windowOpenTable,
              where: 'epoch_sequence = ?',
              whereArgs: [epochSequence],
              orderBy: 'integrity_window_sequence ASC');
          var available = true;
          final admittedWindows = epochRow['admitted_study_window_count'];
          if (terminalEpoch &&
              (admittedWindows != capacityWindows ||
                  windows.length != admittedWindows)) {
            available = false;
          }
          final projected = <P1StudyScientificWindow>[];
          for (final window in windows) {
            final sequence = window['integrity_window_sequence'] as int?;
            if (sequence == null || sequence < 1) available = false;
            final finals = sequence == null
                ? const <Map<String, Object?>>[]
                : await db.query(windowFinalTable,
                    where: 'integrity_window_sequence = ?',
                    whereArgs: [sequence],
                    limit: 2);
            if (finals.length > 1) available = false;
            final openings = sequence == null
                ? const <Map<String, Object?>>[]
                : await db.query(opportunityOpenTable,
                    where: 'integrity_window_sequence = ?',
                    whereArgs: [sequence],
                    orderBy: 'opportunity_ordinal_within_run ASC');
            final terminals = sequence == null
                ? const <Map<String, Object?>>[]
                : await db.query(opportunityTerminalTable,
                    where: 'integrity_window_sequence = ?',
                    whereArgs: [sequence]);
            final terminalByOrdinal = <int, Map<String, Object?>>{};
            for (final terminal in terminals) {
              final ordinal =
                  terminal['opportunity_ordinal_within_run'] as int?;
              if (ordinal == null || terminalByOrdinal.containsKey(ordinal)) {
                available = false;
              } else {
                terminalByOrdinal[ordinal] = terminal;
              }
            }
            final opportunities = <P1StudyScientificOpportunity>[];
            for (final opening in openings) {
              final ordinal = opening['opportunity_ordinal_within_run'] as int?;
              final terminal =
                  ordinal == null ? null : terminalByOrdinal[ordinal];
              opportunities.add(P1StudyScientificOpportunity(
                opportunityOrdinalWithinRun: ordinal,
                decisionContext: _knownString(
                    opening['decision_context'], const {'chooseDifficulty'}),
                decisionLocus: _knownString(opening['decision_locus'],
                    const {'questionOpeningDifficultyResolution'}),
                decisionLocusReason: _knownString(
                    opening['decision_locus_reason'],
                    const {'difficultyRequiredForQuestionOpening'}),
                legalCandidates: _legalCandidates(
                    opening['exact_legal_candidate_set_code'] as String?),
                executedCandidate:
                    _candidate(opening['executed_difficulty'] as String?),
                canonicalSelectionMechanism: _knownString(
                    opening['canonical_selection_mechanism'],
                    const {'playerConfigured'}),
                operation: _knownString(opening['effective_question_operation'],
                    Operation.values.map((value) => value.name).toSet()),
                numberType: _knownString(opening['number_type'],
                    NumberType.values.map((value) => value.name).toSet()),
                terminal: _terminal(
                    terminal?['canonical_terminal_outcome'] as String?),
                acceptedQeoLink: terminal == null
                    ? null
                    : terminal['accepted_qeo_link'] == 1,
              ));
            }
            final finalRow = finals.isEmpty ? null : finals.single;
            final finalValidation = _scientificWindowFinalValidation(
              finalRow,
              window,
              openings,
              terminals,
              terminalEpoch: terminalEpoch,
            );
            if (finalValidation.state ==
                _ScientificWindowFinalState.structurallyUnavailable) {
              available = false;
            }
            for (final entry in finalValidation.missingLegalSets.entries) {
              final candidates = _legalCandidates(entry.key);
              if (candidates == null) {
                available = false;
                continue;
              }
              for (var index = 0; index < entry.value; index++) {
                opportunities.add(P1StudyScientificOpportunity(
                  opportunityOrdinalWithinRun: null,
                  decisionContext: null,
                  decisionLocus: null,
                  decisionLocusReason: null,
                  legalCandidates: candidates,
                  executedCandidate: null,
                  canonicalSelectionMechanism: null,
                  operation: null,
                  numberType: null,
                  terminal: null,
                  acceptedQeoLink: null,
                ));
              }
            }
            projected.add(P1StudyScientificWindow(
              runSegmentId: sequence,
              activityRunContext: _knownString(window['activity_run_context'],
                  const {'quickPracticeTimingPractice'}),
              agencyRoute: _knownString(window['agency_route'], const {
                'freshSetupAcceptedConfiguration',
                'replayCarriedConfiguration'
              }),
              runType: _knownString(window['run_type'],
                  GameRunType.values.map((value) => value.name).toSet()),
              playerCount: window['player_count'] as int?,
              gameMode: _knownString(window['game_mode'],
                  GameMode.values.map((value) => value.name).toSet()),
              questionMechanic: _knownString(window['question_mechanic'],
                  QuestionMechanic.values.map((value) => value.name).toSet()),
              answerStyle: _knownString(window['answer_style'],
                  AnswerStyle.values.map((value) => value.name).toSet()),
              cleanEligible:
                  finalValidation.state == _ScientificWindowFinalState.clean,
              opportunities: List.unmodifiable(opportunities),
            ));
          }
          return P1StudyScientificSnapshot(
              epochSequence: epochSequence,
              measurementAvailable: available,
              epochStatus: epochRow['epoch_status'] as String?,
              epochStopReason: epochRow['epoch_stop_reason'] as String?,
              admittedStudyWindowCount:
                  epochRow['admitted_study_window_count'] as int?,
              capacityWindows: epochRow['c_windows'] as int?,
              windows: List.unmodifiable(projected));
        }),
      );

  Future<bool> openWindow(P1StudyWindowOpen record) async =>
      (await _guarded(
        P1StudyStoreOperation.openWindow,
        () => _serialize(() async {
          final db = await _db();
          return db.transaction((txn) async {
            _fail(P1StudyStoreOperation.openWindow);
            final epochRows = await txn.query(
              epochTable,
              where: 'epoch_sequence = ? AND epoch_status = ?',
              whereArgs: [
                record.epochSequence,
                P1StudyEpochStatus.active.storageValue,
              ],
              limit: 1,
            );
            if (epochRows.isEmpty ||
                epochRows.single['admitted_study_window_count'] as int >=
                    capacityWindows) {
              return false;
            }
            final inserted = await txn.insert(
              windowOpenTable,
              {
                'epoch_sequence': record.epochSequence,
                'integrity_window_sequence': record.integrityWindowSequence,
                'activity_run_context': record.activityRunContext.storageValue,
                'agency_route': record.agencyRoute.storageValue,
                'run_type': record.runType.name,
                'player_count': record.playerCount,
                'game_mode': record.gameMode.name,
                'question_mechanic': record.questionMechanic.name,
                'answer_style': record.answerStyle.name,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            if (inserted == 0) return false;
            await txn.rawUpdate(
              'UPDATE $epochTable SET admitted_study_window_count = admitted_study_window_count + 1 WHERE epoch_sequence = ?',
              [record.epochSequence],
            );
            return true;
          });
        }),
      )) ??
      false;

  Future<bool> openOpportunity(P1StudyOpportunityOpen record) async =>
      (await _guarded(
        P1StudyStoreOperation.openOpportunity,
        () => _serialize(() async {
          final db = await _db();
          return db.transaction((txn) async {
            _fail(P1StudyStoreOperation.openOpportunity);
            if (record.opportunityOrdinalWithinRun < 1 ||
                record.opportunityOrdinalWithinRun > _maxOpeningsPerWindow) {
              return false;
            }
            final count = Sqflite.firstIntValue(await txn.rawQuery(
                  'SELECT COUNT(*) FROM $opportunityOpenTable',
                )) ??
                0;
            if (count >= maxOpportunityRows) return false;
            final window = await txn.query(
              windowOpenTable,
              where: 'integrity_window_sequence = ?',
              whereArgs: [record.integrityWindowSequence],
              limit: 1,
            );
            if (window.isEmpty) return false;
            await txn.insert(opportunityOpenTable, {
              'integrity_window_sequence': record.integrityWindowSequence,
              'opportunity_ordinal_within_run':
                  record.opportunityOrdinalWithinRun,
              'decision_context': 'chooseDifficulty',
              'decision_locus': 'questionOpeningDifficultyResolution',
              'decision_locus_reason': 'difficultyRequiredForQuestionOpening',
              'exact_legal_candidate_set_code':
                  record.exactLegalCandidateSetCode.value,
              'executed_difficulty': record.executedDifficulty.name,
              'canonical_selection_mechanism': 'playerConfigured',
              'effective_question_operation':
                  record.effectiveQuestionOperation.name,
              'number_type': record.numberType.name,
            });
            return true;
          });
        }),
      )) ??
      false;

  Future<bool> recordTerminal(P1StudyOpportunityTerminal record) async =>
      (await _guarded(
        P1StudyStoreOperation.recordTerminal,
        () => _serialize(() async {
          final db = await _db();
          return db.transaction((txn) async {
            _fail(P1StudyStoreOperation.recordTerminal);
            final opening = await txn.query(
              opportunityOpenTable,
              where:
                  'integrity_window_sequence = ? AND opportunity_ordinal_within_run = ?',
              whereArgs: [
                record.integrityWindowSequence,
                record.opportunityOrdinalWithinRun,
              ],
              limit: 1,
            );
            if (opening.isEmpty) return false;
            await txn.insert(opportunityTerminalTable, {
              'integrity_window_sequence': record.integrityWindowSequence,
              'opportunity_ordinal_within_run':
                  record.opportunityOrdinalWithinRun,
              'canonical_terminal_outcome':
                  record.canonicalTerminalOutcome.storageValue,
              'accepted_qeo_link': 1,
            });
            return true;
          });
        }),
      )) ??
      false;

  Future<bool> finalizeWindow(P1StudyWindowFinal record) async =>
      (await _guarded(
        P1StudyStoreOperation.finalizeWindow,
        () => _serialize(() async {
          final db = await _db();
          return db.transaction((txn) async {
            _fail(P1StudyStoreOperation.finalizeWindow);
            final window = await txn.query(
              windowOpenTable,
              columns: ['epoch_sequence'],
              where: 'integrity_window_sequence = ?',
              whereArgs: [record.integrityWindowSequence],
              limit: 1,
            );
            if (window.isEmpty ||
                record.integritySnapshot.localWindowSequence !=
                    record.integrityWindowSequence) {
              return false;
            }
            await txn.insert(windowFinalTable, {
              'integrity_window_sequence': record.integrityWindowSequence,
              'study_disposition': record.studyDisposition.storageValue,
              'non_clean_cause': record.nonCleanCause.storageValue,
              'measurement_defect': record.measurementDefect.storageValue,
              'recovered_after_restart': record.recoveredAfterRestart ? 1 : 0,
              'integrity_version': record.integritySnapshot.integrityVersion,
              'final_integrity_status':
                  record.integritySnapshot.status.storageValue,
              'final_admitted_o_raw_count':
                  record.integritySnapshot.admittedORawCount,
              'last_admitted_opportunity_ordinal':
                  record.integritySnapshot.lastAdmittedOpportunityOrdinal,
              'last_legal_set_code': record.integritySnapshot.lastLegalSetCode,
              'last_reconciled_ordinal':
                  record.integritySnapshot.lastReconciledOrdinal,
              'has_integrity_defect':
                  record.integritySnapshot.hasIntegrityDefect ? 1 : 0,
              'has_clean_closure_signal':
                  record.integritySnapshot.hasCleanClosureSignal ? 1 : 0,
              'legal_set_counters':
                  jsonEncode(record.integritySnapshot.legalSetCounters),
              'study_opening_receipt_count': record.studyOpeningReceiptCount,
              'study_terminal_receipt_count': record.studyTerminalReceiptCount,
            });
            final epochSequence = window.single['epoch_sequence'] as int;
            final epoch = (await txn.query(
              epochTable,
              where: 'epoch_sequence = ?',
              whereArgs: [epochSequence],
              limit: 1,
            ))
                .single;
            if (epoch['admitted_study_window_count'] as int ==
                capacityWindows) {
              await txn.update(
                epochTable,
                {
                  'epoch_status':
                      P1StudyEpochStatus.frozenForAdjudication.storageValue,
                  'epoch_stop_reason':
                      P1StudyEpochStopReason.capacityReached.storageValue,
                },
                where: 'epoch_sequence = ? AND epoch_status = ?',
                whereArgs: [
                  epochSequence,
                  P1StudyEpochStatus.active.storageValue,
                ],
              );
            }
            return true;
          });
        }),
      )) ??
      false;

  Future<bool> abortActiveEpoch({
    required P1StudyEpochStopReason reason,
    required DateTime epochTerminalTimestampUtc,
    P1AdministrativeAbortActingRole? administrativeAbortActingRole,
    bool? administrativeAbortMetricsNotAccessed,
  }) async =>
      (await _guarded(
        P1StudyStoreOperation.abortEpoch,
        () => _serialize(() async {
          if (!{
            P1StudyEpochStopReason.userReset,
            P1StudyEpochStopReason.measurementUnavailable,
            P1StudyEpochStopReason.administrativeAbortIndependentOfResult,
          }.contains(reason)) {
            return false;
          }
          final administrative = reason ==
              P1StudyEpochStopReason.administrativeAbortIndependentOfResult;
          if (administrative != (administrativeAbortActingRole != null) ||
              administrative !=
                  (administrativeAbortMetricsNotAccessed == true)) {
            return false;
          }
          final db = await _db();
          return db.transaction((txn) async {
            _fail(P1StudyStoreOperation.abortEpoch);
            final active = await txn.query(
              epochTable,
              columns: ['epoch_sequence'],
              where: 'epoch_status IN (?, ?)',
              whereArgs: [
                P1StudyEpochStatus.active.storageValue,
                P1StudyEpochStatus.frozenForAdjudication.storageValue,
              ],
              limit: 1,
            );
            if (active.isEmpty) return true;
            final sequence = active.single['epoch_sequence'] as int;
            await txn.update(
              epochTable,
              {
                'epoch_status': P1StudyEpochStatus.aborted.storageValue,
                'epoch_stop_reason': reason.storageValue,
                'epoch_terminal_timestamp_utc':
                    epochTerminalTimestampUtc.toUtc().toIso8601String(),
                'administrative_abort_acting_role':
                    administrativeAbortActingRole?.storageValue,
                'administrative_abort_metrics_not_accessed':
                    administrative ? 1 : null,
              },
              where: 'epoch_sequence = ?',
              whereArgs: [sequence],
            );
            final windows = await txn.query(
              windowOpenTable,
              columns: ['integrity_window_sequence'],
              where: 'epoch_sequence = ?',
              whereArgs: [sequence],
            );
            final ids = windows
                .map((row) => row['integrity_window_sequence'] as int)
                .toList();
            if (ids.isNotEmpty) {
              final marks = List.filled(ids.length, '?').join(',');
              await txn.delete(opportunityTerminalTable,
                  where: 'integrity_window_sequence IN ($marks)',
                  whereArgs: ids);
              await txn.delete(opportunityOpenTable,
                  where: 'integrity_window_sequence IN ($marks)',
                  whereArgs: ids);
              await txn.delete(windowFinalTable,
                  where: 'integrity_window_sequence IN ($marks)',
                  whereArgs: ids);
            }
            await txn.delete(windowOpenTable,
                where: 'epoch_sequence = ?', whereArgs: [sequence]);
            return true;
          });
        }),
      )) ??
      false;

  Future<int> openingReceiptCount(int integrityWindowSequence) =>
      _count(opportunityOpenTable, integrityWindowSequence);

  Future<int> terminalReceiptCount(int integrityWindowSequence) =>
      _count(opportunityTerminalTable, integrityWindowSequence);

  Future<List<int>> unfinishedWindowSequences() => _serialize(() async {
        final db = await _db();
        final rows = await db.rawQuery('''
          SELECT w.integrity_window_sequence
          FROM $windowOpenTable w
          LEFT JOIN $windowFinalTable f
            ON f.integrity_window_sequence = w.integrity_window_sequence
          WHERE f.integrity_window_sequence IS NULL
          ORDER BY w.integrity_window_sequence ASC
        ''');
        return rows
            .map((row) => row['integrity_window_sequence'] as int)
            .toList(growable: false);
      });

  Future<bool> deleteAll() async =>
      (await _guarded(
        P1StudyStoreOperation.deleteAll,
        () => _serialize(() async {
          final db = await _db();
          await db.transaction((txn) async {
            _fail(P1StudyStoreOperation.deleteAll);
            await txn.delete(opportunityTerminalTable);
            await txn.delete(opportunityOpenTable);
            await txn.delete(windowFinalTable);
            await txn.delete(windowOpenTable);
            await txn.delete(epochTable);
          });
          return true;
        }),
      )) ??
      false;

  Future<void> drain() => _queue;

  @visibleForTesting
  Future<int> debugRowCount(String table) async {
    await drain();
    final db = await _db();
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table'),
        ) ??
        0;
  }

  @visibleForTesting
  Future<List<String>> debugColumnNames(String table) async {
    await drain();
    final db = await _db();
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((row) => row['name'] as String).toList();
  }

  @visibleForTesting
  Future<void> debugExecute(String sql, [List<Object?>? arguments]) async {
    await drain();
    final db = await _db();
    await db.rawInsert(sql, arguments);
  }

  Future<void> close() async {
    await drain();
    final db = _database;
    _database = null;
    await db?.close();
  }

  Future<int> _count(String table, int integrityWindowSequence) =>
      _serialize(() async {
        final db = await _db();
        return Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM $table WHERE integrity_window_sequence = ?',
              [integrityWindowSequence],
            )) ??
            0;
      });

  static String? _knownString(Object? value, Set<String> allowed) =>
      value is String && allowed.contains(value) ? value : null;

  static P1StudyCandidate? _candidate(String? value) => switch (value) {
        'easy' => P1StudyCandidate.easy,
        'medium' => P1StudyCandidate.medium,
        'hard' => P1StudyCandidate.hard,
        _ => null,
      };

  static Set<P1StudyCandidate>? _legalCandidates(String? value) {
    final mask = switch (value) {
      'V1_EMH_MASK_1' => 1,
      'V1_EMH_MASK_2' => 2,
      'V1_EMH_MASK_3' => 3,
      'V1_EMH_MASK_4' => 4,
      'V1_EMH_MASK_5' => 5,
      'V1_EMH_MASK_6' => 6,
      'V1_EMH_MASK_7' => 7,
      _ => null,
    };
    if (mask == null) return null;
    return {
      if (mask & 1 != 0) P1StudyCandidate.easy,
      if (mask & 2 != 0) P1StudyCandidate.medium,
      if (mask & 4 != 0) P1StudyCandidate.hard,
    };
  }

  static P1StudyTerminal? _terminal(String? value) => switch (value) {
        'AnsweredCorrect' => P1StudyTerminal.answeredCorrect,
        'AnsweredIncorrect' => P1StudyTerminal.answeredIncorrect,
        'QuestionTimedOut' => P1StudyTerminal.questionTimedOut,
        'QuestionSkipped' => P1StudyTerminal.questionSkipped,
        'QuestionReplaced' => P1StudyTerminal.questionReplaced,
        _ => null,
      };

  static _ScientificWindowFinalValidation _scientificWindowFinalValidation(
    Map<String, Object?>? finalRow,
    Map<String, Object?> window,
    List<Map<String, Object?>> openings,
    List<Map<String, Object?>> terminals, {
    required bool terminalEpoch,
  }) {
    if (finalRow == null) {
      return _ScientificWindowFinalValidation(
        terminalEpoch
            ? _ScientificWindowFinalState.structurallyUnavailable
            : _ScientificWindowFinalState.nonClean,
        const {},
      );
    }
    final disposition = finalRow['study_disposition'];
    if (disposition != P1StudyWindowDisposition.cleanEligible.storageValue) {
      return _validateNonCleanScientificFinal(
        finalRow,
        window,
        openings,
        terminals,
      );
    }
    if (finalRow['non_clean_cause'] != P1StudyNonCleanCause.none.storageValue ||
        finalRow['measurement_defect'] !=
            P1StudyMeasurementDefect.none.storageValue ||
        finalRow['final_integrity_status'] !=
            P1F01IntegrityWindowStatus.cleanlyClosed.storageValue ||
        finalRow['has_integrity_defect'] != 0 ||
        finalRow['has_clean_closure_signal'] != 1 ||
        finalRow['integrity_version'] != P1F01IntegrityStore.integrityVersion ||
        finalRow['integrity_window_sequence'] !=
            window['integrity_window_sequence']) {
      return const _ScientificWindowFinalValidation(
          _ScientificWindowFinalState.structurallyUnavailable, {});
    }
    if (openings.length > _maxOpeningsPerWindow) {
      return const _ScientificWindowFinalValidation(
          _ScientificWindowFinalState.structurallyUnavailable, {});
    }

    final openingOrdinals = <int>{};
    final legalSetCounters = <String, int>{};
    for (final opening in openings) {
      final ordinal = opening['opportunity_ordinal_within_run'];
      final legalSetCode = opening['exact_legal_candidate_set_code'];
      if (ordinal is! int ||
          !openingOrdinals.add(ordinal) ||
          legalSetCode == P1F01LegalSetCode.unknown.value ||
          P1F01LegalSetCode.fromStoredValue(legalSetCode as String? ?? '') ==
              null) {
        return const _ScientificWindowFinalValidation(
            _ScientificWindowFinalState.structurallyUnavailable, {});
      }
      legalSetCounters.update(legalSetCode as String, (count) => count + 1,
          ifAbsent: () => 1);
    }
    final expectedOrdinals = {
      for (var ordinal = 1; ordinal <= openings.length; ordinal++) ordinal,
    };
    final terminalOrdinals = <int>{};
    for (final terminal in terminals) {
      final ordinal = terminal['opportunity_ordinal_within_run'];
      if (ordinal is! int || !terminalOrdinals.add(ordinal)) {
        return const _ScientificWindowFinalValidation(
            _ScientificWindowFinalState.structurallyUnavailable, {});
      }
    }
    if (openingOrdinals.length != openings.length ||
        openingOrdinals.length != expectedOrdinals.length ||
        !openingOrdinals.containsAll(expectedOrdinals) ||
        terminalOrdinals.length != terminals.length ||
        terminalOrdinals.length != openingOrdinals.length ||
        !terminalOrdinals.containsAll(openingOrdinals)) {
      return const _ScientificWindowFinalValidation(
          _ScientificWindowFinalState.structurallyUnavailable, {});
    }
    final expectedLastOrdinal = openings.isEmpty ? null : openings.length;
    final expectedLastLegalSet = openings.isEmpty
        ? null
        : openings.singleWhere(
            (opening) =>
                opening['opportunity_ordinal_within_run'] ==
                expectedLastOrdinal,
          )['exact_legal_candidate_set_code'];
    final counters = _decodeLegalSetCounters(finalRow['legal_set_counters']);
    if (finalRow['final_admitted_o_raw_count'] != openings.length ||
        finalRow['study_opening_receipt_count'] != openings.length ||
        finalRow['study_terminal_receipt_count'] != terminals.length ||
        finalRow['last_admitted_opportunity_ordinal'] != expectedLastOrdinal ||
        finalRow['last_reconciled_ordinal'] != expectedLastOrdinal ||
        finalRow['last_legal_set_code'] != expectedLastLegalSet ||
        counters == null ||
        !_sameCounters(counters, legalSetCounters)) {
      return const _ScientificWindowFinalValidation(
          _ScientificWindowFinalState.structurallyUnavailable, {});
    }
    return const _ScientificWindowFinalValidation(
        _ScientificWindowFinalState.clean, {});
  }

  static _ScientificWindowFinalValidation _validateNonCleanScientificFinal(
    Map<String, Object?> finalRow,
    Map<String, Object?> window,
    List<Map<String, Object?>> openings,
    List<Map<String, Object?>> terminals,
  ) {
    const unavailable = _ScientificWindowFinalValidation(
        _ScientificWindowFinalState.structurallyUnavailable, {});
    final disposition = finalRow['study_disposition'];
    final cause = finalRow['non_clean_cause'];
    final defect = finalRow['measurement_defect'];
    final knownCause = cause is String &&
        P1StudyNonCleanCause.values.any((value) => value.storageValue == cause);
    final knownDefect = defect is String &&
        P1StudyMeasurementDefect.values
            .any((value) => value.storageValue == defect);
    final nonCleanCoherent = (disposition ==
                P1StudyWindowDisposition
                    .nonCleanMeasurementFailure.storageValue &&
            knownCause &&
            knownDefect &&
            defect != P1StudyMeasurementDefect.none.storageValue) ||
        (disposition ==
                P1StudyWindowDisposition.nonCleanCensored.storageValue &&
            knownCause &&
            knownDefect &&
            cause != P1StudyNonCleanCause.none.storageValue &&
            defect == P1StudyMeasurementDefect.none.storageValue);
    if (!nonCleanCoherent ||
        finalRow['integrity_version'] != P1F01IntegrityStore.integrityVersion ||
        finalRow['integrity_window_sequence'] !=
            window['integrity_window_sequence']) {
      return unavailable;
    }
    final admitted = finalRow['final_admitted_o_raw_count'];
    final storedOpenings = finalRow['study_opening_receipt_count'];
    final storedTerminals = finalRow['study_terminal_receipt_count'];
    final counters = _decodeLegalSetCounters(finalRow['legal_set_counters']);
    if (admitted is! int ||
        admitted < 0 ||
        admitted > _maxOpeningsPerWindow ||
        storedOpenings != openings.length ||
        storedTerminals != terminals.length ||
        counters == null ||
        counters.values.fold(0, (sum, value) => sum + value) != admitted ||
        admitted < openings.length) {
      return unavailable;
    }
    final lastAdmitted = finalRow['last_admitted_opportunity_ordinal'];
    final lastLegal = finalRow['last_legal_set_code'];
    final lastReconciled = finalRow['last_reconciled_ordinal'];
    final integrityStatus = finalRow['final_integrity_status'];
    final integrityDefect = finalRow['has_integrity_defect'];
    final cleanClosure = finalRow['has_clean_closure_signal'];
    final zeroAdmitted = admitted == 0 &&
        lastAdmitted == null &&
        lastLegal == null &&
        lastReconciled == null &&
        counters.isEmpty;
    final positiveAdmitted = admitted > 0 &&
        lastAdmitted == admitted &&
        lastLegal is String &&
        lastLegal != P1F01LegalSetCode.unknown.value &&
        P1F01LegalSetCode.fromStoredValue(lastLegal) != null &&
        counters.values.every((count) => count > 0) &&
        (lastReconciled == null ||
            (lastReconciled is int &&
                lastReconciled >= 1 &&
                lastReconciled <= admitted));
    final integrityCoherent = switch (integrityStatus) {
      'CLEANLY_CLOSED' => integrityDefect == 0 &&
          cleanClosure == 1 &&
          lastReconciled == lastAdmitted &&
          openings.length == admitted &&
          terminals.length == admitted,
      'LEFT_UNCLEAN' =>
        cleanClosure == 0 && (integrityDefect == 0 || integrityDefect == 1),
      _ => false,
    };
    if ((!zeroAdmitted && !positiveAdmitted) || !integrityCoherent) {
      return unavailable;
    }
    final observed = <String, int>{};
    final openingOrdinals = <int>{};
    for (final opening in openings) {
      final ordinal = opening['opportunity_ordinal_within_run'];
      final code = opening['exact_legal_candidate_set_code'];
      if (ordinal is! int ||
          ordinal < 1 ||
          ordinal > admitted ||
          !openingOrdinals.add(ordinal) ||
          code is! String ||
          code == P1F01LegalSetCode.unknown.value ||
          P1F01LegalSetCode.fromStoredValue(code) == null) {
        return unavailable;
      }
      observed.update(code, (value) => value + 1, ifAbsent: () => 1);
    }
    final terminalOrdinals = <int>{};
    for (final terminal in terminals) {
      final ordinal = terminal['opportunity_ordinal_within_run'];
      if (ordinal is! int ||
          !terminalOrdinals.add(ordinal) ||
          !openingOrdinals.contains(ordinal)) {
        return unavailable;
      }
    }
    final missing = <String, int>{};
    if (observed.entries.any(
          (entry) => entry.value > (counters[entry.key] ?? 0),
        ) ||
        counters.containsKey(P1F01LegalSetCode.unknown.value)) {
      return unavailable;
    }
    final finalOpening = openings.where(
        (opening) => opening['opportunity_ordinal_within_run'] == admitted);
    if (finalOpening.isNotEmpty &&
        finalOpening.single['exact_legal_candidate_set_code'] != lastLegal) {
      return unavailable;
    }
    for (final entry in counters.entries) {
      final count = entry.value - (observed[entry.key] ?? 0);
      if (count < 0) return unavailable;
      if (count > 0) missing[entry.key] = count;
    }
    if (missing.values.fold(0, (sum, value) => sum + value) !=
        admitted - openings.length) {
      return unavailable;
    }
    if (finalOpening.isEmpty &&
        admitted > 0 &&
        (missing[lastLegal] ?? 0) <= 0) {
      return unavailable;
    }
    return _ScientificWindowFinalValidation(
      _ScientificWindowFinalState.nonClean,
      Map.unmodifiable(missing),
    );
  }

  static Map<String, int>? _decodeLegalSetCounters(Object? value) {
    if (value is! String) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final encodedKeys = RegExp(r'"([^"\\]*)"\s*:')
          .allMatches(value)
          .map((match) => match.group(1))
          .toList();
      if (encodedKeys.length != decoded.length ||
          encodedKeys.toSet().length != encodedKeys.length) {
        return null;
      }
      final counters = <String, int>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String ||
            entry.value is! int ||
            entry.value < 0 ||
            P1F01LegalSetCode.fromStoredValue(entry.key as String) == null) {
          return null;
        }
        counters[entry.key as String] = entry.value as int;
      }
      return counters;
    } on FormatException {
      return null;
    }
  }

  static bool _sameCounters(Map<String, int> left, Map<String, int> right) =>
      left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);

  P1StudyEpoch _epochFromRow(Map<String, Object?> row) {
    if (row['study_schema_version'] != studySchemaVersion ||
        row['p1_f00_protocol_version'] != p1F00ProtocolVersion ||
        row['sample_protocol_id'] != sampleProtocolId ||
        row['sample_protocol_version'] != sampleProtocolVersion ||
        row['c_windows'] != capacityWindows ||
        row['semantic_taxonomy_version'] != semanticTaxonomyVersion) {
      throw const FormatException('Unsupported Study epoch binding.');
    }
    final status = P1StudyEpochStatus.parse(row['epoch_status'] as String);
    final reason =
        P1StudyEpochStopReason.parse(row['epoch_stop_reason'] as String);
    final roleValue = row['administrative_abort_acting_role'] as String?;
    final role = roleValue == null
        ? null
        : P1AdministrativeAbortActingRole.parse(roleValue);
    final metrics = row['administrative_abort_metrics_not_accessed'] as int?;
    final timestamp = row['epoch_terminal_timestamp_utc'] as String?;
    final statusReasonTimestampValid = switch (status) {
      P1StudyEpochStatus.active =>
        reason == P1StudyEpochStopReason.none && timestamp == null,
      P1StudyEpochStatus.frozenForAdjudication =>
        reason == P1StudyEpochStopReason.capacityReached && timestamp == null,
      P1StudyEpochStatus.aborted =>
        {
          P1StudyEpochStopReason.userReset,
          P1StudyEpochStopReason.measurementUnavailable,
          P1StudyEpochStopReason.administrativeAbortIndependentOfResult,
        }.contains(reason) && timestamp != null,
      P1StudyEpochStatus.adjudicated =>
        reason == P1StudyEpochStopReason.capacityReached && timestamp != null,
    };
    final administrative =
        reason == P1StudyEpochStopReason.administrativeAbortIndependentOfResult;
    if (!statusReasonTimestampValid ||
        administrative != (role != null) ||
        administrative != (metrics == 1)) {
      throw const FormatException('Invalid Study epoch governance fields.');
    }
    return P1StudyEpoch(
      epochSequence: row['epoch_sequence'] as int,
      status: status,
      stopReason: reason,
      admittedStudyWindowCount: row['admitted_study_window_count'] as int,
      epochTerminalTimestampUtc: timestamp,
      administrativeAbortActingRole: role,
      administrativeAbortMetricsNotAccessed:
          metrics == null ? null : metrics == 1,
    );
  }

  Future<void> _validateAllPersistedEpochs(DatabaseExecutor database) async {
    final rows = await database.query(epochTable);
    for (final row in rows) {
      _epochFromRow(row);
    }
  }

  Future<Database> _db() async {
    final existing = _database;
    if (existing != null) return existing;
    final factory = _databaseFactory ?? databaseFactory;
    final path = _databasePath ?? await _defaultDatabasePath(factory);
    return _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: studySchemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $epochTable (
              epoch_sequence INTEGER PRIMARY KEY AUTOINCREMENT,
              study_schema_version INTEGER NOT NULL CHECK(study_schema_version = 1),
              p1_f00_protocol_version TEXT NOT NULL CHECK(p1_f00_protocol_version = '1.2'),
              sample_protocol_id TEXT NOT NULL CHECK(sample_protocol_id = 'P1-SE-SAMPLE-00'),
              sample_protocol_version INTEGER NOT NULL CHECK(sample_protocol_version = 1),
              c_windows INTEGER NOT NULL CHECK(c_windows = 49),
              semantic_taxonomy_version INTEGER NOT NULL CHECK(semantic_taxonomy_version = 1),
              epoch_status TEXT NOT NULL CHECK(epoch_status IN ('ACTIVE','FROZEN_FOR_ADJUDICATION','ADJUDICATED','ABORTED')),
              epoch_stop_reason TEXT NOT NULL CHECK(epoch_stop_reason IN ('none','capacityReached','userReset','measurementUnavailable','administrativeAbortIndependentOfResult')),
              admitted_study_window_count INTEGER NOT NULL CHECK(admitted_study_window_count BETWEEN 0 AND 49),
              epoch_terminal_timestamp_utc TEXT,
              administrative_abort_acting_role TEXT CHECK(administrative_abort_acting_role IN ('PRODUCT_GOVERNANCE','RELEASE_GOVERNANCE','DATA_GOVERNANCE','PROTOCOL_GOVERNANCE')),
              administrative_abort_metrics_not_accessed INTEGER CHECK(administrative_abort_metrics_not_accessed = 1),
              CHECK(
                (epoch_status = 'ACTIVE'
                  AND epoch_stop_reason = 'none'
                  AND epoch_terminal_timestamp_utc IS NULL)
                OR
                (epoch_status = 'FROZEN_FOR_ADJUDICATION'
                  AND epoch_stop_reason = 'capacityReached'
                  AND epoch_terminal_timestamp_utc IS NULL)
                OR
                (epoch_status = 'ABORTED'
                  AND epoch_stop_reason IN ('userReset','measurementUnavailable','administrativeAbortIndependentOfResult')
                  AND epoch_terminal_timestamp_utc IS NOT NULL)
                OR
                (epoch_status = 'ADJUDICATED'
                  AND epoch_stop_reason = 'capacityReached'
                  AND epoch_terminal_timestamp_utc IS NOT NULL)
              ),
              CHECK(
                (epoch_stop_reason = 'administrativeAbortIndependentOfResult'
                  AND epoch_status = 'ABORTED'
                  AND administrative_abort_acting_role IS NOT NULL
                  AND administrative_abort_metrics_not_accessed = 1)
                OR
                (epoch_stop_reason != 'administrativeAbortIndependentOfResult'
                  AND administrative_abort_acting_role IS NULL
                  AND administrative_abort_metrics_not_accessed IS NULL)
              )
            )
          ''');
          await db.execute('''
            CREATE TABLE $windowOpenTable (
              epoch_sequence INTEGER NOT NULL,
              integrity_window_sequence INTEGER PRIMARY KEY,
              activity_run_context TEXT NOT NULL CHECK(activity_run_context IN ('quickPracticeTimingPractice','unknown')),
              agency_route TEXT NOT NULL CHECK(agency_route IN ('freshSetupAcceptedConfiguration','replayCarriedConfiguration','unknown')),
              run_type TEXT NOT NULL,
              player_count INTEGER NOT NULL,
              game_mode TEXT NOT NULL,
              question_mechanic TEXT NOT NULL,
              answer_style TEXT NOT NULL,
              FOREIGN KEY(epoch_sequence) REFERENCES $epochTable(epoch_sequence) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE $opportunityOpenTable (
              integrity_window_sequence INTEGER NOT NULL,
              opportunity_ordinal_within_run INTEGER NOT NULL CHECK(opportunity_ordinal_within_run BETWEEN 1 AND 25),
              decision_context TEXT NOT NULL CHECK(decision_context = 'chooseDifficulty'),
              decision_locus TEXT NOT NULL CHECK(decision_locus = 'questionOpeningDifficultyResolution'),
              decision_locus_reason TEXT NOT NULL CHECK(decision_locus_reason = 'difficultyRequiredForQuestionOpening'),
              exact_legal_candidate_set_code TEXT NOT NULL,
              executed_difficulty TEXT NOT NULL CHECK(executed_difficulty IN ('easy','medium','hard')),
              canonical_selection_mechanism TEXT NOT NULL CHECK(canonical_selection_mechanism = 'playerConfigured'),
              effective_question_operation TEXT NOT NULL,
              number_type TEXT NOT NULL,
              PRIMARY KEY(integrity_window_sequence, opportunity_ordinal_within_run),
              FOREIGN KEY(integrity_window_sequence) REFERENCES $windowOpenTable(integrity_window_sequence) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE $opportunityTerminalTable (
              integrity_window_sequence INTEGER NOT NULL,
              opportunity_ordinal_within_run INTEGER NOT NULL,
              canonical_terminal_outcome TEXT NOT NULL CHECK(canonical_terminal_outcome IN ('AnsweredCorrect','AnsweredIncorrect','QuestionTimedOut','QuestionSkipped','QuestionReplaced')),
              accepted_qeo_link INTEGER NOT NULL CHECK(accepted_qeo_link = 1),
              PRIMARY KEY(integrity_window_sequence, opportunity_ordinal_within_run),
              FOREIGN KEY(integrity_window_sequence, opportunity_ordinal_within_run) REFERENCES $opportunityOpenTable(integrity_window_sequence, opportunity_ordinal_within_run) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE $windowFinalTable (
              integrity_window_sequence INTEGER PRIMARY KEY,
              study_disposition TEXT NOT NULL CHECK(study_disposition IN ('cleanEligible','nonCleanCensored','nonCleanMeasurementFailure','aborted')),
              non_clean_cause TEXT NOT NULL CHECK(non_clean_cause IN ('none','lifecycleInterruption','switchOpEnvelopeExit','followUpEnvelopeExit','userReset','administrativeAbortIndependentOfResult','unknownNonCleanCause')),
              measurement_defect TEXT NOT NULL CHECK(measurement_defect IN ('none','explicitUnlinkedTerminal','studyPersistenceFailure','integrityAdmissionFailure','integrityReconciliationFailure','integrityClosureFailure','recoverySequenceMismatch','integritySnapshotUnavailable','unknownMeasurementFailure')),
              recovered_after_restart INTEGER NOT NULL CHECK(recovered_after_restart IN (0,1)),
              integrity_version INTEGER NOT NULL,
              final_integrity_status TEXT NOT NULL,
              final_admitted_o_raw_count INTEGER NOT NULL,
              last_admitted_opportunity_ordinal INTEGER,
              last_legal_set_code TEXT,
              last_reconciled_ordinal INTEGER,
              has_integrity_defect INTEGER NOT NULL CHECK(has_integrity_defect IN (0,1)),
              has_clean_closure_signal INTEGER NOT NULL CHECK(has_clean_closure_signal IN (0,1)),
              legal_set_counters TEXT NOT NULL,
              study_opening_receipt_count INTEGER NOT NULL,
              study_terminal_receipt_count INTEGER NOT NULL,
              FOREIGN KEY(integrity_window_sequence) REFERENCES $windowOpenTable(integrity_window_sequence) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
  }

  Future<String> _defaultDatabasePath(DatabaseFactory factory) async {
    final base = await factory.getDatabasesPath();
    final separator = base.endsWith('/') || base.endsWith('\\') ? '' : '/';
    return '$base${separator}p1_f01_study.db';
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  Future<T?> _guarded<T>(
    P1StudyStoreOperation operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on Exception {
      return null;
    } on StateError {
      return null;
    }
  }

  void _fail(P1StudyStoreOperation operation) => failureHook?.call(operation);
}
