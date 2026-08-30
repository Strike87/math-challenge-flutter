import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/storage.dart';
import '../experience/p1_f01_integrity_store.dart';
import 'p1_f01_study_store.dart';

enum P1StudyCoordinatorState {
  uninitialized,
  recovering,
  readyIdle,
  windowOpening,
  windowActive,
  windowFinalizing,
  resetting,
  disabled,
}

enum P1IntegrityOwnershipRegime {
  integrityOnly,
  studyActivating,
  studyActive,
}

enum P1StudyResetJournal { clear, resetPending }

final class P1StudyResetJournalStore {
  P1StudyResetJournalStore({
    String Function()? read,
    Future<void> Function(String value)? write,
  })  : _read = read ??
            (() => Storage.getString(
                  storageKey,
                  P1StudyResetJournal.clear.name,
                )),
        _write = write ?? ((value) => Storage.setString(storageKey, value));

  static const storageKey = 'mc_p1StudyResetJournal';

  final String Function() _read;
  final Future<void> Function(String value) _write;

  P1StudyResetJournal read() {
    final value = _read();
    return P1StudyResetJournal.values.firstWhere(
      (entry) => entry.name == value,
      orElse: () => P1StudyResetJournal.resetPending,
    );
  }

  Future<void> write(P1StudyResetJournal value) => _write(value.name);
}

/// Single-writer owner of all cross-store P1 Study ordering.
///
/// Production construction is permanently dark. Only the explicitly named
/// test constructor can open the gate.
final class P1F01StudyCoordinator {
  P1F01StudyCoordinator.production({
    required P1F01IntegrityStore integrityStore,
    P1F01StudyStore? studyStore,
    P1StudyResetJournalStore? resetJournal,
  }) : this._(
          integrityStore: integrityStore,
          studyStore: studyStore ?? P1F01StudyStore(),
          resetJournal: resetJournal ?? P1StudyResetJournalStore(),
          confirmatoryWindowExplicitlyOpen: false,
          ownsStudyStore: studyStore == null,
        );

  @visibleForTesting
  P1F01StudyCoordinator.test({
    required P1F01IntegrityStore integrityStore,
    required P1F01StudyStore studyStore,
    required P1StudyResetJournalStore resetJournal,
    bool confirmatoryWindowExplicitlyOpen = true,
  }) : this._(
          integrityStore: integrityStore,
          studyStore: studyStore,
          resetJournal: resetJournal,
          confirmatoryWindowExplicitlyOpen: confirmatoryWindowExplicitlyOpen,
          ownsStudyStore: false,
        );

  P1F01StudyCoordinator._({
    required this.integrityStore,
    required this.studyStore,
    required this.resetJournal,
    required this.confirmatoryWindowExplicitlyOpen,
    required bool ownsStudyStore,
  }) : _ownsStudyStore = ownsStudyStore;

  final P1F01IntegrityStore integrityStore;
  final P1F01StudyStore studyStore;
  final P1StudyResetJournalStore resetJournal;
  final bool confirmatoryWindowExplicitlyOpen;
  final bool _ownsStudyStore;

  Future<void> _queue = Future<void>.value();
  P1StudyCoordinatorState _state = P1StudyCoordinatorState.uninitialized;
  P1IntegrityOwnershipRegime _ownership =
      P1IntegrityOwnershipRegime.integrityOnly;
  int _generation = 0;
  int? _runId;
  int? _failedPreOpenRunId;
  int? _integrityWindowSequence;
  int? _epochSequence;
  bool _futureOpportunityAdmissionEnabled = false;
  bool _terminalFinalizationAllowed = false;
  P1StudyNonCleanCause _cause = P1StudyNonCleanCause.none;
  P1StudyMeasurementDefect _defect = P1StudyMeasurementDefect.none;
  Completer<bool>? _activationCompleter;

  P1StudyCoordinatorState get state => _state;
  P1IntegrityOwnershipRegime get ownershipRegime => _ownership;
  int? get activeIntegrityWindowSequence => _integrityWindowSequence;
  bool get futureOpportunityAdmissionEnabled =>
      _futureOpportunityAdmissionEnabled;
  bool get terminalFinalizationAllowedForCurrentAcceptedOpening =>
      _terminalFinalizationAllowed;

  Future<void> initialize() {
    if (_state != P1StudyCoordinatorState.uninitialized) return _queue;
    _state = P1StudyCoordinatorState.recovering;
    return _enqueue(() async {
      if (resetJournal.read() == P1StudyResetJournal.resetPending) {
        await _completeResetDeletion();
      }
      await integrityStore.recoverOpenWindows();
      if (!confirmatoryWindowExplicitlyOpen) {
        _ownership = P1IntegrityOwnershipRegime.integrityOnly;
        _state = P1StudyCoordinatorState.disabled;
        return;
      }
      final epoch = await studyStore.createOrLoadActiveEpoch();
      if (epoch == null ||
          epoch.status == P1StudyEpochStatus.frozenForAdjudication) {
        _ownership = P1IntegrityOwnershipRegime.studyActive;
        _state = P1StudyCoordinatorState.disabled;
        return;
      }
      _epochSequence = epoch.epochSequence;
      var recoveredAllFinals = true;
      for (final sequence in await studyStore.unfinishedWindowSequences()) {
        final snapshot = await integrityStore.snapshotBySequence(sequence);
        if (snapshot == null) {
          await studyStore.abortActiveEpoch(
            reason: P1StudyEpochStopReason.measurementUnavailable,
            epochTerminalTimestampUtc: DateTime.now().toUtc(),
          );
          _state = P1StudyCoordinatorState.disabled;
          return;
        }
        final finalSnapshot = snapshot.status == P1F01IntegrityWindowStatus.open
            ? await integrityStore.markLeftUncleanAndSnapshot(sequence)
            : snapshot;
        if (finalSnapshot != null) {
          recoveredAllFinals = await _persistFinal(
                sequence,
                finalSnapshot,
                recovered: true,
                cause: P1StudyNonCleanCause.unknownNonCleanCause,
                defect: P1StudyMeasurementDefect.none,
              ) &&
              recoveredAllFinals;
        }
      }
      if (!recoveredAllFinals || await integrityStore.openWindowCount() != 0) {
        _state = P1StudyCoordinatorState.disabled;
        return;
      }
      _ownership = P1IntegrityOwnershipRegime.studyActive;
      _state = P1StudyCoordinatorState.readyIdle;
    });
  }

  /// Reserves synchronously; canonical gameplay never waits on persistence.
  bool beginWindow({
    required int runId,
    required bool eligible,
    required P1StudyWindowOpen Function(
      int epochSequence,
      int integrityWindowSequence,
    ) studyRecord,
  }) {
    if (!eligible ||
        runId <= 0 ||
        _failedPreOpenRunId == runId ||
        _state == P1StudyCoordinatorState.uninitialized ||
        (confirmatoryWindowExplicitlyOpen &&
            _state == P1StudyCoordinatorState.recovering) ||
        _state == P1StudyCoordinatorState.resetting) {
      return false;
    }
    if (_ownership == P1IntegrityOwnershipRegime.integrityOnly) {
      if (_runId != null) return false;
      _runId = runId;
      _futureOpportunityAdmissionEnabled = true;
      _terminalFinalizationAllowed = true;
      final generation = _generation;
      // Integrity-only remains the established gameplay-adjacent path. Start
      // its write now, while retaining it in the coordinator drain boundary.
      final admission = integrityStore.admitWindow();
      _enqueue(() async {
        final snapshot = await admission;
        if (!_matches(runId, generation)) return;
        if (snapshot == null) {
          _defect = P1StudyMeasurementDefect.integrityAdmissionFailure;
          _futureOpportunityAdmissionEnabled = false;
          return;
        }
        _integrityWindowSequence = snapshot.localWindowSequence;
      });
      return true;
    }
    if (_ownership != P1IntegrityOwnershipRegime.studyActive ||
        _state != P1StudyCoordinatorState.readyIdle ||
        !confirmatoryWindowExplicitlyOpen ||
        _epochSequence == null) {
      return false;
    }
    _runId = runId;
    _state = P1StudyCoordinatorState.windowOpening;
    _futureOpportunityAdmissionEnabled = true;
    _terminalFinalizationAllowed = true;
    _cause = P1StudyNonCleanCause.none;
    _defect = P1StudyMeasurementDefect.none;
    final generation = _generation;
    _enqueue(() async {
      if (!_matches(runId, generation)) return;
      final snapshot = await integrityStore.admitWindow();
      if (!_matches(runId, generation)) return;
      if (snapshot == null) {
        _failOpening(runId, P1StudyMeasurementDefect.integrityAdmissionFailure);
        return;
      }
      final sequence = snapshot.localWindowSequence;
      _integrityWindowSequence = sequence;
      final record = studyRecord(_epochSequence!, sequence);
      if (!await studyStore.openWindow(record)) {
        await integrityStore.markLeftUncleanAndSnapshot(sequence);
        _failOpening(
          runId,
          P1StudyMeasurementDefect.studyPersistenceFailure,
        );
        return;
      }
      if (_matches(runId, generation)) {
        _state = P1StudyCoordinatorState.windowActive;
      }
    });
    return true;
  }

  void admitOpportunity({
    required int runId,
    required P1StudyOpportunityOpen Function(int sequence) studyRecord,
  }) {
    if (_runId != runId || !_futureOpportunityAdmissionEnabled) return;
    final generation = _generation;
    _enqueue(() async {
      if (!_matches(runId, generation)) return;
      final sequence = _integrityWindowSequence;
      if (sequence == null) {
        _defect = P1StudyMeasurementDefect.integrityAdmissionFailure;
        _futureOpportunityAdmissionEnabled = false;
        return;
      }
      final record = studyRecord(sequence);
      final admission = await integrityStore.admitOpportunityForSequence(
        localWindowSequence: sequence,
        opportunityOrdinalWithinRun: record.opportunityOrdinalWithinRun,
        legalSetCode: record.exactLegalCandidateSetCode,
      );
      if (admission == P1F01OpportunityAdmissionResult.failedClosed) {
        _defect = P1StudyMeasurementDefect.integrityAdmissionFailure;
        _futureOpportunityAdmissionEnabled = false;
        return;
      }
      if (_ownership == P1IntegrityOwnershipRegime.studyActive &&
          !await studyStore.openOpportunity(record)) {
        _defect = P1StudyMeasurementDefect.studyPersistenceFailure;
        _futureOpportunityAdmissionEnabled = false;
        await integrityStore.markLeftUncleanAndSnapshot(sequence);
      }
    });
  }

  void recordTerminal({
    required int runId,
    required P1StudyOpportunityTerminal Function(int sequence) studyRecord,
    required bool terminalLinkAccepted,
  }) {
    if (_runId != runId || !_terminalFinalizationAllowed) return;
    final generation = _generation;
    _enqueue(() async {
      if (!_matches(runId, generation)) return;
      final sequence = _integrityWindowSequence;
      if (sequence == null) return;
      final record = studyRecord(sequence);
      if (!terminalLinkAccepted) {
        _defect = P1StudyMeasurementDefect.explicitUnlinkedTerminal;
        _futureOpportunityAdmissionEnabled = false;
        await integrityStore.markLeftUncleanAndSnapshot(sequence);
        return;
      }
      if (_ownership == P1IntegrityOwnershipRegime.studyActive &&
          !await studyStore.recordTerminal(record)) {
        _defect = P1StudyMeasurementDefect.studyPersistenceFailure;
        _futureOpportunityAdmissionEnabled = false;
        await integrityStore.markLeftUncleanAndSnapshot(sequence);
        return;
      }
      if (!await integrityStore.reconcileTerminalForSequence(
        localWindowSequence: sequence,
        opportunityOrdinalWithinRun: record.opportunityOrdinalWithinRun,
        terminalLinkAccepted: true,
      )) {
        _defect = P1StudyMeasurementDefect.integrityReconciliationFailure;
        _futureOpportunityAdmissionEnabled = false;
      }
    });
  }

  void markNonClean(int runId, P1StudyNonCleanCause cause) {
    if (_runId != runId) return;
    _futureOpportunityAdmissionEnabled = false;
    if (_cause == P1StudyNonCleanCause.none) _cause = cause;
    final generation = _generation;
    _enqueue(() async {
      if (!_matches(runId, generation)) return;
      final sequence = _integrityWindowSequence;
      if (sequence != null) {
        await integrityStore.markLeftUncleanAndSnapshot(sequence);
      }
    });
  }

  void markMeasurementDefect(int runId, P1StudyMeasurementDefect defect) {
    if (_runId != runId) return;
    _futureOpportunityAdmissionEnabled = false;
    if (_defect == P1StudyMeasurementDefect.none) _defect = defect;
  }

  void finishWindow(int runId) {
    if (_runId != runId) return;
    _futureOpportunityAdmissionEnabled = false;
    _terminalFinalizationAllowed = false;
    if (_ownership == P1IntegrityOwnershipRegime.studyActive) {
      _state = P1StudyCoordinatorState.windowFinalizing;
    }
    final generation = _generation;
    _enqueue(() async {
      if (!_matches(runId, generation)) return;
      final sequence = _integrityWindowSequence;
      var finalPersisted = true;
      if (sequence != null) {
        final nonClean = _cause != P1StudyNonCleanCause.none ||
            _defect != P1StudyMeasurementDefect.none;
        var snapshot = nonClean
            ? await integrityStore.markLeftUncleanAndSnapshot(sequence)
            : await integrityStore.closeCleanAndSnapshot(sequence);
        if (snapshot == null ||
            snapshot.localWindowSequence != sequence ||
            (!nonClean &&
                snapshot.status != P1F01IntegrityWindowStatus.cleanlyClosed)) {
          _defect = P1StudyMeasurementDefect.integrityClosureFailure;
          snapshot = await integrityStore.markLeftUncleanAndSnapshot(sequence);
        }
        if (_ownership == P1IntegrityOwnershipRegime.studyActive &&
            snapshot != null) {
          finalPersisted = await _persistFinal(
            sequence,
            snapshot,
            recovered: false,
            cause: _cause,
            defect: _defect,
          );
        }
      }
      _clearWindow();
      if (_ownership == P1IntegrityOwnershipRegime.studyActivating) {
        await _activateAfterDrain();
      } else if (_ownership == P1IntegrityOwnershipRegime.studyActive) {
        if (!finalPersisted) {
          _state = P1StudyCoordinatorState.disabled;
          return;
        }
        final epoch = await studyStore.activeEpoch();
        _state = epoch?.status == P1StudyEpochStatus.active
            ? P1StudyCoordinatorState.readyIdle
            : P1StudyCoordinatorState.disabled;
      }
    });
  }

  Future<bool> requestStudyActivation() {
    if (!confirmatoryWindowExplicitlyOpen) return Future.value(false);
    if (_ownership == P1IntegrityOwnershipRegime.studyActive) {
      return Future.value(true);
    }
    final existing = _activationCompleter;
    if (existing != null) return existing.future;
    final completer = _activationCompleter = Completer<bool>();
    _ownership = P1IntegrityOwnershipRegime.studyActivating;
    _state = P1StudyCoordinatorState.recovering;
    if (_runId == null) _enqueue(_activateAfterDrain);
    return completer.future;
  }

  Future<bool> releaseStudyOwnership() async {
    if (_ownership != P1IntegrityOwnershipRegime.studyActive ||
        _runId != null ||
        !{P1StudyCoordinatorState.readyIdle, P1StudyCoordinatorState.disabled}
            .contains(_state)) {
      return false;
    }
    await drain();
    if (await integrityStore.openWindowCount() != 0) return false;
    _ownership = P1IntegrityOwnershipRegime.integrityOnly;
    _state = P1StudyCoordinatorState.disabled;
    return true;
  }

  Future<bool> reset() {
    _generation++;
    _futureOpportunityAdmissionEnabled = false;
    _terminalFinalizationAllowed = false;
    _state = P1StudyCoordinatorState.resetting;
    return _enqueueResult(() async {
      try {
        await resetJournal.write(P1StudyResetJournal.resetPending);
        if (!await studyStore.abortActiveEpoch(
          reason: P1StudyEpochStopReason.userReset,
          epochTerminalTimestampUtc: DateTime.now().toUtc(),
        )) {
          throw StateError('P1 Study reset abort failed.');
        }
        await _completeResetDeletion();
        _clearWindow();
        _ownership = P1IntegrityOwnershipRegime.integrityOnly;
        _state = P1StudyCoordinatorState.disabled;
        return true;
      // Reset must retain RESET_PENDING and fail closed for every durable
      // deletion/journal boundary failure. Store hooks may surface StateError,
      // which is an Error rather than an Exception in Dart.
      } on Object {
        return false;
      }
    });
  }

  Future<void> drain() async {
    await _queue;
    await integrityStore.drain();
    await studyStore.drain();
  }

  Future<void> close() async {
    await drain();
    if (_ownsStudyStore) await studyStore.close();
  }

  void abandonPendingWork() {
    _generation++;
    _futureOpportunityAdmissionEnabled = false;
    _terminalFinalizationAllowed = false;
  }

  Future<void> _activateAfterDrain() async {
    if (_ownership != P1IntegrityOwnershipRegime.studyActivating ||
        _runId != null) {
      return;
    }
    await integrityStore.recoverOpenWindows();
    if (await integrityStore.openWindowCount() != 0) {
      _state = P1StudyCoordinatorState.disabled;
      _activationCompleter?.complete(false);
      _activationCompleter = null;
      return;
    }
    final epoch = await studyStore.createOrLoadActiveEpoch();
    final active = epoch?.status == P1StudyEpochStatus.active;
    if (active) _epochSequence = epoch!.epochSequence;
    _ownership = P1IntegrityOwnershipRegime.studyActive;
    _state = active
        ? P1StudyCoordinatorState.readyIdle
        : P1StudyCoordinatorState.disabled;
    _activationCompleter?.complete(active);
    _activationCompleter = null;
  }

  Future<bool> _persistFinal(
    int sequence,
    P1F01IntegritySnapshot snapshot, {
    required bool recovered,
    required P1StudyNonCleanCause cause,
    required P1StudyMeasurementDefect defect,
  }) async {
    final disposition = defect != P1StudyMeasurementDefect.none
        ? P1StudyWindowDisposition.nonCleanMeasurementFailure
        : cause != P1StudyNonCleanCause.none
            ? P1StudyWindowDisposition.nonCleanCensored
            : snapshot.status == P1F01IntegrityWindowStatus.cleanlyClosed
                ? P1StudyWindowDisposition.cleanEligible
                : P1StudyWindowDisposition.nonCleanMeasurementFailure;
    return studyStore.finalizeWindow(P1StudyWindowFinal(
      integrityWindowSequence: sequence,
      studyDisposition: disposition,
      nonCleanCause: cause,
      measurementDefect:
          disposition == P1StudyWindowDisposition.nonCleanMeasurementFailure &&
                  defect == P1StudyMeasurementDefect.none
              ? P1StudyMeasurementDefect.unknownMeasurementFailure
              : defect,
      recoveredAfterRestart: recovered,
      integritySnapshot: snapshot,
      studyOpeningReceiptCount: await studyStore.openingReceiptCount(sequence),
      studyTerminalReceiptCount:
          await studyStore.terminalReceiptCount(sequence),
    ));
  }

  Future<void> _completeResetDeletion() async {
    // A dark coordinator may hold closed stores with durable rows on disk.
    // Deletion must open and process both stores before CLEAR is written.
    final studyDeleted = await studyStore.deleteAll();
    final integrityDeleted = await integrityStore.deleteAll();
    if (!studyDeleted || !integrityDeleted) {
      throw StateError('P1 Study reset deletion failed.');
    }
    await resetJournal.write(P1StudyResetJournal.clear);
  }

  void _failOpening(int runId, P1StudyMeasurementDefect defect) {
    _failedPreOpenRunId = runId;
    _defect = defect;
    _futureOpportunityAdmissionEnabled = false;
    _terminalFinalizationAllowed = false;
    _clearWindow();
    _state = P1StudyCoordinatorState.readyIdle;
  }

  void _clearWindow() {
    _runId = null;
    _integrityWindowSequence = null;
    _futureOpportunityAdmissionEnabled = false;
    _terminalFinalizationAllowed = false;
    _cause = P1StudyNonCleanCause.none;
    _defect = P1StudyMeasurementDefect.none;
  }

  bool _matches(int runId, int generation) =>
      generation == _generation && _runId == runId;

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  Future<T> _enqueueResult<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }
}
