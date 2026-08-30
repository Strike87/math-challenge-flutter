import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_coordinator.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_store.dart';
import 'package:math_challenge/features/gameplay/domain/question_difficulty_legality.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  group('P1 Study Evidence foundation', () {
    test('the production coordinator is dark while Integrity stays available',
        () async {
      final harness = await _newHarness(production: true);
      addTearDown(harness.dispose);

      await harness.coordinator.initialize();
      expect(harness.coordinator.confirmatoryWindowExplicitlyOpen, isFalse);
      expect(harness.coordinator.state, P1StudyCoordinatorState.disabled);
      expect(harness.begin(1), isTrue);
      await harness.coordinator.drain();

      expect(await harness.study.debugRowCount(P1F01StudyStore.epochTable), 0);
      expect((await harness.integrity.latestSnapshot())?.status,
          P1F01IntegrityWindowStatus.open);
    });

    test('serializes opening, terminal, and exact finalization', () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.finishWindow(1);
      await harness.coordinator.drain();

      expect(await harness.study.debugRowCount(P1F01StudyStore.windowOpenTable),
          1);
      expect(
        await harness.study.debugRowCount(P1F01StudyStore.opportunityOpenTable),
        1,
      );
      expect(
        await harness.study
            .debugRowCount(P1F01StudyStore.opportunityTerminalTable),
        1,
      );
      expect(
        await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable),
        1,
      );
      expect((await harness.integrity.snapshotBySequence(1))?.status,
          P1F01IntegrityWindowStatus.cleanlyClosed);
    });

    test('late and overlapping runs cannot mutate the active Study window',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.finishWindow(1);
      expect(harness.begin(2), isFalse);
      await harness.coordinator.drain();

      expect(harness.begin(2), isTrue);
      harness.opening(2);
      harness.terminal(1); // stale callback from run 1
      harness.terminal(2);
      harness.coordinator.finishWindow(2);
      await harness.coordinator.drain();

      expect(
        await harness.study
            .debugRowCount(P1F01StudyStore.opportunityTerminalTable),
        2,
      );
      expect(
        await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable),
        2,
      );
    });

    test('mismatched Integrity sequence fails closed without closing another',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      final first = await harness.integrity.admitWindow();
      final second = await harness.integrity.admitWindow();

      expect(first?.localWindowSequence, 1);
      expect(second?.localWindowSequence, 2);
      expect((await harness.integrity.snapshotBySequence(1))?.status,
          P1F01IntegrityWindowStatus.leftUnclean);
      expect((await harness.integrity.closeCleanAndSnapshot(1))?.status,
          P1F01IntegrityWindowStatus.leftUnclean);
      expect((await harness.integrity.snapshotBySequence(2))?.status,
          P1F01IntegrityWindowStatus.open);
    });

    test('the 49th admitted window freezes the epoch and a 50th is rejected',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      for (var runId = 1; runId <= P1F01StudyStore.capacityWindows; runId++) {
        expect(harness.begin(runId), isTrue);
        harness.opening(runId);
        harness.terminal(runId);
        harness.coordinator.finishWindow(runId);
        await harness.coordinator.drain();
      }

      final epoch = await harness.study.activeEpoch();
      expect(epoch?.status, P1StudyEpochStatus.frozenForAdjudication);
      expect(epoch?.admittedStudyWindowCount, P1F01StudyStore.capacityWindows);
      expect(epoch?.epochTerminalTimestampUtc, isNull);
      expect(harness.begin(50), isFalse);
      expect(
          await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable),
          P1F01StudyStore.capacityWindows);
    });

    test('D — reset invalidates queued Study writes without resurrection',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      expect(await harness.coordinator.reset(), isTrue);
      await harness.coordinator.drain();

      expect(await harness.study.debugRowCount(P1F01StudyStore.epochTable), 0);
      expect(
        await harness.study.debugRowCount(P1F01StudyStore.windowOpenTable),
        0,
      );
      expect(await harness.integrity.latestSnapshot(), isNull);
    });

    test('E — startup recovery blocks Study admission until recovery completes',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);

      final recovery = harness.coordinator.initialize();
      expect(harness.begin(1), isFalse);
      await recovery;
      expect(harness.begin(1), isTrue);
    });

    test('G and O — failed pre-open fails closed without same-run retry',
        () async {
      var failOpen = true;
      final harness = await _newHarness(
        studyFailureHook: (operation) {
          if (failOpen && operation == P1StudyStoreOperation.openWindow) {
            throw StateError('injected StudyWindowOpen failure');
          }
        },
      );
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      await harness.coordinator.drain();

      expect((await harness.study.activeEpoch())?.admittedStudyWindowCount, 0);
      expect(harness.coordinator.futureOpportunityAdmissionEnabled, isFalse);
      expect(harness.begin(1), isFalse);
      expect(
        (await harness.integrity.snapshotBySequence(1))?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );
      failOpen = false;
      expect(harness.begin(2), isTrue);
    });

    test('G1 — missing exact Integrity recovery aborts X without using Y',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();
      expect(harness.begin(1), isTrue);
      harness.opening(1);
      await harness.coordinator.drain();
      expect((await harness.integrity.admitWindow())?.localWindowSequence, 2);

      await harness.coordinator.close();
      await harness.study.close();
      await harness.integrity.close();
      await _deleteIntegrityWindow(harness._directory, 1);

      final recovered = await _reopenHarness(harness._directory);
      addTearDown(recovered.dispose);
      await recovered.coordinator.initialize();

      expect(recovered.coordinator.state, P1StudyCoordinatorState.disabled);
      expect(recovered.begin(2), isTrue);
      recovered.opening(2);
      recovered.terminal(2);
      recovered.coordinator.finishWindow(2);
      await recovered.coordinator.drain();
      expect(
        await recovered.study.debugRowCount(P1F01StudyStore.windowFinalTable),
        0,
      );
      expect(
        (await recovered.integrity.snapshotBySequence(2))?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );
      final aborted = (await recovered.study.terminalEpochs()).single;
      expect(aborted.status, P1StudyEpochStatus.aborted);
      expect(aborted.stopReason, P1StudyEpochStopReason.measurementUnavailable);

      await recovered.coordinator.close();
      await recovered.study.close();
      await recovered.integrity.close();
      final restarted = await _reopenHarness(harness._directory);
      addTearDown(restarted.dispose);
      await restarted.coordinator.initialize();

      expect(
        (await restarted.study.terminalEpochs()).single.epochSequence,
        aborted.epochSequence,
      );
      expect((await restarted.study.activeEpoch())?.epochSequence,
          isNot(aborted.epochSequence));
      expect(
        await restarted.study.debugRowCount(P1F01StudyStore.windowFinalTable),
        0,
      );
    });

    test('I and N — non-clean follow-up exits preserve the terminal and count',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.markNonClean(
        1,
        P1StudyNonCleanCause.followUpEnvelopeExit,
      );
      expect(harness.coordinator.futureOpportunityAdmissionEnabled, isFalse);
      harness.opening(1);
      harness.coordinator.finishWindow(1);
      await harness.coordinator.drain();

      expect(
        await harness.study
            .debugRowCount(P1F01StudyStore.opportunityTerminalTable),
        1,
      );
      expect((await harness.study.activeEpoch())?.admittedStudyWindowCount, 1);
    });

    test('H — a clean final terminal has no follow-up exit', () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.finishWindow(1);
      await harness.coordinator.drain();

      expect(
        (await harness.integrity.snapshotBySequence(1))?.status,
        P1F01IntegrityWindowStatus.cleanlyClosed,
      );
      expect(
        harness.coordinator.futureOpportunityAdmissionEnabled,
        isFalse,
      );
    });

    test('StudyWindowFinal failure disables capture until recovery', () async {
      final harness = await _newHarness(
        studyFailureHook: (operation) {
          if (operation == P1StudyStoreOperation.finalizeWindow) {
            throw StateError('injected StudyWindowFinal failure');
          }
        },
      );
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.finishWindow(1);
      await harness.coordinator.drain();

      expect(harness.coordinator.state, P1StudyCoordinatorState.disabled);
      expect(harness.begin(2), isFalse);
      expect(
        (await harness.integrity.snapshotBySequence(1))?.status,
        P1F01IntegrityWindowStatus.cleanlyClosed,
      );
      expect(
        await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable),
        0,
      );
      await harness.coordinator.close();
      await harness.study.close();
      await harness.integrity.close();
      final restarted = await _reopenHarness(harness._directory);
      addTearDown(restarted.dispose);
      await restarted.coordinator.initialize();
      final recovered = await _studyFinalRow(restarted._directory, 1);
      expect(recovered?['study_disposition'],
          P1StudyWindowDisposition.nonCleanCensored.storageValue);
      expect(recovered?['non_clean_cause'],
          P1StudyNonCleanCause.unknownNonCleanCause.storageValue);
      expect(recovered?['measurement_defect'],
          P1StudyMeasurementDefect.none.storageValue);
      expect(recovered?['recovered_after_restart'], 1);
    });

    test('injected opportunity/terminal/reconciliation failures fail closed',
        () async {
      Future<void> expectNonCleanFinal(
        void Function(P1StudyStoreOperation operation)? studyFailureHook,
        void Function(P1F01IntegrityOperation operation)? integrityFailureHook,
        P1StudyMeasurementDefect expectedDefect,
      ) async {
        final harness = await _newHarness(
          studyFailureHook: studyFailureHook,
          integrityFailureHook: integrityFailureHook,
        );
        addTearDown(harness.dispose);
        await harness.coordinator.initialize();
        expect(harness.begin(1), isTrue);
        harness.opening(1);
        harness.terminal(1);
        harness.coordinator.finishWindow(1);
        await harness.coordinator.drain();

        expect(harness.coordinator.futureOpportunityAdmissionEnabled, isFalse);
        expect(
          (await harness.integrity.snapshotBySequence(1))?.status,
          P1F01IntegrityWindowStatus.leftUnclean,
        );
        expect(
          await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable),
          1,
        );
        final finalRow = await _studyFinalRow(harness._directory, 1);
        expect(finalRow?['study_disposition'],
            P1StudyWindowDisposition.nonCleanMeasurementFailure.storageValue);
        expect(finalRow?['measurement_defect'], expectedDefect.storageValue);
      }

      var failOpportunity = true;
      await expectNonCleanFinal((operation) {
        if (failOpportunity && operation == P1StudyStoreOperation.openOpportunity) {
          failOpportunity = false;
          throw StateError('injected opportunity-open write failure');
        }
      }, null, P1StudyMeasurementDefect.studyPersistenceFailure);

      var failTerminal = true;
      await expectNonCleanFinal((operation) {
        if (failTerminal && operation == P1StudyStoreOperation.recordTerminal) {
          failTerminal = false;
          throw StateError('injected terminal-receipt write failure');
        }
      }, null, P1StudyMeasurementDefect.studyPersistenceFailure);

      var failReconciliation = true;
      await expectNonCleanFinal(null, (operation) {
        if (failReconciliation &&
            operation == P1F01IntegrityOperation.reconcileTerminal) {
          failReconciliation = false;
          throw StateError('injected exact Integrity reconciliation failure');
        }
      }, P1StudyMeasurementDefect.integrityReconciliationFailure);
    });

    test('injected exact Integrity finalization becomes a non-clean final',
        () async {
      var failClose = true;
      final harness = await _newHarness(
        integrityFailureHook: (operation) {
          if (failClose && operation == P1F01IntegrityOperation.closeClean) {
            failClose = false;
            throw StateError('injected exact Integrity finalization failure');
          }
        },
      );
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();
      expect(harness.begin(1), isTrue);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.finishWindow(1);
      await harness.coordinator.drain();

      expect(
        (await harness.integrity.snapshotBySequence(1))?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );
      expect(
        await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable),
        1,
      );
      final finalRow = await _studyFinalRow(harness._directory, 1);
      expect(finalRow?['study_disposition'],
          P1StudyWindowDisposition.nonCleanMeasurementFailure.storageValue);
      expect(finalRow?['measurement_defect'],
          P1StudyMeasurementDefect.integrityClosureFailure.storageValue);
    });

    test('OPEN Integrity and partially-final Study windows recover censored',
        () async {
      Future<void> expectRecoveredFinal({required bool closeIntegrity}) async {
        final harness = await _newHarness();
        addTearDown(harness.dispose);
        await harness.coordinator.initialize();
        expect(harness.begin(1), isTrue);
        harness.opening(1);
        if (closeIntegrity) {
          harness.terminal(1);
          await harness.coordinator.drain();
          expect(
            (await harness.integrity.closeCleanAndSnapshot(1))?.status,
            P1F01IntegrityWindowStatus.cleanlyClosed,
          );
        } else {
          await harness.coordinator.drain();
        }
        await harness.coordinator.close();
        await harness.study.close();
        await harness.integrity.close();
        final restarted = await _reopenHarness(harness._directory);
        addTearDown(restarted.dispose);
        await restarted.coordinator.initialize();

        expect(
          (await restarted.integrity.snapshotBySequence(1))?.status,
          closeIntegrity
              ? P1F01IntegrityWindowStatus.cleanlyClosed
              : P1F01IntegrityWindowStatus.leftUnclean,
        );
        expect(
          await restarted.study.debugRowCount(P1F01StudyStore.windowFinalTable),
          1,
        );
        final finalRow = await _studyFinalRow(restarted._directory, 1);
        expect(finalRow?['study_disposition'],
            P1StudyWindowDisposition.nonCleanCensored.storageValue);
        expect(finalRow?['non_clean_cause'],
            P1StudyNonCleanCause.unknownNonCleanCause.storageValue);
        expect(finalRow?['measurement_defect'],
            P1StudyMeasurementDefect.none.storageValue);
        expect(finalRow?['recovered_after_restart'], 1);
        expect(restarted.coordinator.state, P1StudyCoordinatorState.readyIdle);
      }

      await expectRecoveredFinal(closeIntegrity: false);
      await expectRecoveredFinal(closeIntegrity: true);
    });

    test('J and K — activation drains grandfathered Integrity before Study Y',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();
      expect(await harness.coordinator.releaseStudyOwnership(), isTrue);

      expect(harness.begin(1), isTrue);
      final activation = harness.coordinator.requestStudyActivation();
      expect(harness.begin(2), isFalse);
      harness.coordinator.finishWindow(1);
      expect(await activation, isTrue);
      expect(harness.coordinator.ownershipRegime,
          P1IntegrityOwnershipRegime.studyActive);
      expect(await harness.integrity.openWindowCount(), 0);
      expect(harness.begin(2), isTrue);
    });

    test('L — Study release requires an idle, drained coordinator', () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();

      expect(harness.begin(1), isTrue);
      expect(await harness.coordinator.releaseStudyOwnership(), isFalse);
      harness.opening(1);
      harness.terminal(1);
      harness.coordinator.finishWindow(1);
      await harness.coordinator.drain();
      expect(await harness.coordinator.releaseStudyOwnership(), isTrue);
      expect(harness.begin(2), isTrue);
    });

    test('P — RESET_PENDING recovery is idempotent and leaves no rows',
        () async {
      final harness = await _newHarness(
        production: true,
        initialJournal: P1StudyResetJournal.resetPending.name,
      );
      addTearDown(harness.dispose);
      await harness.study.createOrLoadActiveEpoch();
      await harness.integrity.admitWindow();

      await harness.coordinator.initialize();
      await harness.coordinator.initialize();
      expect(await harness.study.debugRowCount(P1F01StudyStore.epochTable), 0);
      expect(await harness.integrity.latestSnapshot(), isNull);
    });

    test('P — each destructive reset boundary recovers idempotently',
        () async {
      Future<void> verifyRecovery({
        void Function(P1StudyStoreOperation operation)? studyFailureHook,
        void Function(P1F01IntegrityOperation operation)? integrityFailureHook,
        Future<void> Function(String value)? journalWrite,
      }) async {
        final harness = await _newHarness(
          studyFailureHook: studyFailureHook,
          integrityFailureHook: integrityFailureHook,
          journalWrite: journalWrite,
        );
        addTearDown(harness.dispose);
        await harness.coordinator.initialize();
        expect(harness.begin(1), isTrue);
        harness.opening(1);
        await harness.coordinator.drain();

        expect(await harness.coordinator.reset(), isFalse);
        expect(harness._journal.value, P1StudyResetJournal.resetPending.name);

        await harness.coordinator.close();
        await harness.study.close();
        await harness.integrity.close();
        final restarted = await _reopenHarness(
          harness._directory,
          journal: harness._journal,
        );
        addTearDown(restarted.dispose);
        await restarted.coordinator.initialize();
        await restarted.coordinator.initialize();

        expect(restarted._journal.value, P1StudyResetJournal.clear.name);
        // Recovery is allowed to create its fresh empty epoch, but none of the
        // pre-reset window evidence may resurrect into it.
        expect(
          await restarted.study.debugRowCount(P1F01StudyStore.windowOpenTable),
          0,
        );
        expect(
          await restarted.study
              .debugRowCount(P1F01StudyStore.opportunityOpenTable),
          0,
        );
        expect(await restarted.integrity.latestSnapshot(), isNull);
        expect(restarted.begin(2), isTrue);
        restarted.opening(2);
        restarted.terminal(2);
        restarted.coordinator.finishWindow(2);
        await restarted.coordinator.drain();
        expect(
          (await restarted.integrity.snapshotBySequence(1))?.status,
          isNull,
        );
      }

      var failStudyDelete = true;
      await verifyRecovery(
        studyFailureHook: (operation) {
          if (failStudyDelete && operation == P1StudyStoreOperation.deleteAll) {
            failStudyDelete = false;
            throw StateError('crash before Study deletion');
          }
        },
      );

      var failIntegrityDelete = true;
      await verifyRecovery(
        integrityFailureHook: (operation) {
          if (failIntegrityDelete && operation == P1F01IntegrityOperation.deleteAll) {
            failIntegrityDelete = false;
            throw StateError('crash before Integrity deletion');
          }
        },
      );

      var failClear = true;
      await verifyRecovery(
        journalWrite: (value) async {
          if (failClear && value == P1StudyResetJournal.clear.name) {
            failClear = false;
            throw StateError('crash before RESET_PENDING clear');
          }
        },
      );
    });

    test('R and S — taxonomy and terminal epoch timestamp are schema-frozen',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      final active = await harness.study.createOrLoadActiveEpoch();
      expect(active?.epochTerminalTimestampUtc, isNull);
      await expectLater(
        harness.study.debugExecute(
          'INSERT INTO ${P1F01StudyStore.epochTable} '
          '(study_schema_version,p1_f00_protocol_version,sample_protocol_id,'
          'sample_protocol_version,c_windows,semantic_taxonomy_version,'
          'epoch_status,epoch_stop_reason,admitted_study_window_count) '
          "VALUES (1,'1.2','P1-SE-SAMPLE-00',1,49,2,'ACTIVE','none',0)",
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await harness.study.abortActiveEpoch(
          reason: P1StudyEpochStopReason.userReset,
          epochTerminalTimestampUtc: DateTime.utc(2026, 8, 30),
        ),
        isTrue,
      );
      expect(
          (await harness.study.terminalEpochs())
              .single
              .epochTerminalTimestampUtc,
          isNotNull);
    });

    test('G2 — only semantic taxonomy v1 recovers', () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.coordinator.initialize();
      expect((await harness.study.activeEpoch())?.epochSequence, 1);

      await harness.coordinator.close();
      await harness.study.close();
      await harness.integrity.close();
      final validRecovery = await _reopenHarness(harness._directory);
      addTearDown(validRecovery.dispose);
      await validRecovery.coordinator.initialize();
      expect(
          validRecovery.coordinator.state, P1StudyCoordinatorState.readyIdle);
      expect((await validRecovery.study.activeEpoch())?.epochSequence, 1);
      await validRecovery.coordinator.close();
      await validRecovery.study.close();
      await validRecovery.integrity.close();

      Future<void> expectInvalidRecovery(
        Object? version, {
        bool omitVersion = false,
      }) async {
        final directory =
            await Directory.systemTemp.createTemp('p1_f01_bad_taxonomy_');
        addTearDown(() => directory.delete(recursive: true));
        await _createCorruptStudyEpoch(
          directory,
          version: version,
          omitVersion: omitVersion,
        );
        final recovered = await _reopenHarness(directory);
        await recovered.coordinator.initialize();

        expect(recovered.coordinator.state, P1StudyCoordinatorState.disabled);
        expect(recovered.begin(1), isFalse);
        expect(await recovered.study.activeEpoch(), isNull);
        expect(await recovered.study.createOrLoadActiveEpoch(), isNull);
        expect(await recovered.integrity.admitWindow(), isNotNull);

        await recovered.coordinator.close();
        await recovered.study.close();
        await recovered.integrity.close();
      }

      for (final invalid in <Object?>[0, 2, null, 'malformed']) {
        await expectInvalidRecovery(invalid);
      }
      await expectInvalidRecovery(1, omitVersion: true);
    });

    test('T, U, and V — administrative abort accepts only typed roles',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      for (final role in P1AdministrativeAbortActingRole.values) {
        expect(P1AdministrativeAbortActingRole.parse(role.storageValue), role);
      }
      for (final invalid in ['', 'UNKNOWN', 'OTHER', 'person@example.com']) {
        expect(
          () => P1AdministrativeAbortActingRole.parse(invalid),
          throwsStateError,
        );
      }
      await harness.study.createOrLoadActiveEpoch();
      expect(
        await harness.study.abortActiveEpoch(
          reason: P1StudyEpochStopReason.administrativeAbortIndependentOfResult,
          epochTerminalTimestampUtc: DateTime.utc(2026, 8, 30),
        ),
        isFalse,
      );
      expect(
        await harness.study.abortActiveEpoch(
          reason: P1StudyEpochStopReason.administrativeAbortIndependentOfResult,
          epochTerminalTimestampUtc: DateTime.utc(2026, 8, 30),
          administrativeAbortActingRole:
              P1AdministrativeAbortActingRole.dataGovernance,
          administrativeAbortMetricsNotAccessed: true,
        ),
        isTrue,
      );
    });

    test('an administrative abort stores only the frozen governance role code',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      final active = await harness.study.createOrLoadActiveEpoch();
      expect(active, isNotNull);

      expect(
        await harness.study.abortActiveEpoch(
          reason: P1StudyEpochStopReason.administrativeAbortIndependentOfResult,
          epochTerminalTimestampUtc: DateTime.utc(2026, 8, 30),
          administrativeAbortActingRole:
              P1AdministrativeAbortActingRole.productGovernance,
          administrativeAbortMetricsNotAccessed: true,
        ),
        isTrue,
      );
      final terminal = (await harness.study.terminalEpochs()).single;
      expect(terminal.administrativeAbortActingRole,
          P1AdministrativeAbortActingRole.productGovernance);
      expect(terminal.administrativeAbortMetricsNotAccessed, isTrue);
      expect(P1F01StudyStore.semanticTaxonomyVersion, 1);
      expect(
        P1AdministrativeAbortActingRole.values
            .map((role) => role.storageValue)
            .toList(),
        [
          'PRODUCT_GOVERNANCE',
          'RELEASE_GOVERNANCE',
          'DATA_GOVERNANCE',
          'PROTOCOL_GOVERNANCE',
        ],
      );
      for (final invalid in ['', 'UNKNOWN', 'OTHER', 'person@example.com']) {
        expect(
          () => P1AdministrativeAbortActingRole.parse(invalid),
          throwsStateError,
        );
      }

      await harness.study.createOrLoadActiveEpoch();
      await harness.study.abortActiveEpoch(
        reason: P1StudyEpochStopReason.userReset,
        epochTerminalTimestampUtc: DateTime.utc(2026, 8, 30),
      );
      expect(
        (await harness.study.terminalEpochs())
            .last
            .administrativeAbortActingRole,
        isNull,
      );
    });

    test('S and T — terminal epoch governance persists exactly across restart',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      final active = await harness.study.createOrLoadActiveEpoch();
      expect(active?.status, P1StudyEpochStatus.active);
      expect(active?.epochTerminalTimestampUtc, isNull);

      final timestamp = DateTime.utc(2026, 8, 30, 12, 34, 56, 789);
      expect(
        await harness.study.abortActiveEpoch(
          reason: P1StudyEpochStopReason
              .administrativeAbortIndependentOfResult,
          epochTerminalTimestampUtc: timestamp,
          administrativeAbortActingRole:
              P1AdministrativeAbortActingRole.releaseGovernance,
          administrativeAbortMetricsNotAccessed: true,
        ),
        isTrue,
      );
      await harness.coordinator.close();
      await harness.study.close();
      await harness.integrity.close();
      final restarted = await _reopenHarness(harness._directory);
      addTearDown(restarted.dispose);
      await restarted.coordinator.initialize();

      final terminal = (await restarted.study.terminalEpochs()).single;
      expect(
        terminal.epochTerminalTimestampUtc,
        timestamp.toIso8601String(),
      );
      expect(terminal.administrativeAbortActingRole,
          P1AdministrativeAbortActingRole.releaseGovernance);
      expect(terminal.administrativeAbortMetricsNotAccessed, isTrue);

      final epochColumns =
          await restarted.study.debugColumnNames(P1F01StudyStore.epochTable);
      expect(
        epochColumns.where((name) => name == 'epoch_terminal_timestamp_utc'),
        hasLength(1),
      );
      expect(epochColumns, isNot(contains('administrative_abort_timestamp_utc')));
      for (final table in [
        P1F01StudyStore.windowOpenTable,
        P1F01StudyStore.opportunityOpenTable,
        P1F01StudyStore.opportunityTerminalTable,
        P1F01StudyStore.windowFinalTable,
      ]) {
        final columns = await restarted.study.debugColumnNames(table);
        expect(columns, isNot(contains('epoch_terminal_timestamp_utc')));
        expect(
          columns,
          isNot(contains('administrative_abort_timestamp_utc')),
        );
      }
    });

    test('U — malformed persisted administrative roles fail closed', () async {
      for (final invalid in ['', 'UNKNOWN', 'OTHER', 'arbitrary']) {
        final directory =
            await Directory.systemTemp.createTemp('p1_f01_bad_abort_role_');
        await _createCorruptStudyEpoch(
          directory,
          version: P1F01StudyStore.semanticTaxonomyVersion,
          omitVersion: false,
          status: P1StudyEpochStatus.aborted,
          reason: P1StudyEpochStopReason
              .administrativeAbortIndependentOfResult,
          terminalTimestampUtc: DateTime.utc(2026, 8, 30).toIso8601String(),
          administrativeRole: invalid,
          administrativeMetricsNotAccessed: 1,
        );
        final recovered = await _reopenHarness(directory);
        addTearDown(recovered.dispose);
        await recovered.coordinator.initialize();

        expect(recovered.coordinator.state, P1StudyCoordinatorState.disabled);
        expect(recovered.begin(1), isFalse);
        expect(await recovered.study.activeEpoch(), isNull);
      }
    });

    test('the Study schema has no identity or free-text acting-role field',
        () async {
      final harness = await _newHarness();
      addTearDown(harness.dispose);
      await harness.study.createOrLoadActiveEpoch();
      final columns =
          await harness.study.debugColumnNames(P1F01StudyStore.epochTable);
      final serialized = columns.join('|').toLowerCase();
      for (final prohibited in [
        'name',
        'email',
        'account',
        'identity',
        'actor'
      ]) {
        expect(serialized, isNot(contains(prohibited)));
      }
      expect(columns, contains('administrative_abort_acting_role'));
    });
  });
}

final class _Harness {
  _Harness(
    this.coordinator,
    this.integrity,
    this.study,
    this._directory,
    this._journal,
  );

  final P1F01StudyCoordinator coordinator;
  final P1F01IntegrityStore integrity;
  final P1F01StudyStore study;
  final Directory _directory;
  final _JournalBox _journal;

  bool begin(int runId) => coordinator.beginWindow(
        runId: runId,
        eligible: true,
        studyRecord: (epoch, sequence) => P1StudyWindowOpen(
          epochSequence: epoch,
          integrityWindowSequence: sequence,
          activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
          agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
          runType: GameRunType.normal,
          playerCount: 1,
          gameMode: GameMode.standard,
          questionMechanic: QuestionMechanic.standard,
          answerStyle: AnswerStyle.choice4,
        ),
      );

  void opening(int runId) => coordinator.admitOpportunity(
        runId: runId,
        studyRecord: (sequence) => P1StudyOpportunityOpen(
          integrityWindowSequence: sequence,
          opportunityOrdinalWithinRun: 1,
          exactLegalCandidateSetCode: _legalSetCode,
          executedDifficulty: Difficulty.easy,
          effectiveQuestionOperation: Operation.addition,
          numberType: NumberType.natural,
        ),
      );

  void terminal(int runId) => coordinator.recordTerminal(
        runId: runId,
        terminalLinkAccepted: true,
        studyRecord: (sequence) => P1StudyOpportunityTerminal(
          integrityWindowSequence: sequence,
          opportunityOrdinalWithinRun: 1,
          canonicalTerminalOutcome:
              P1StudyCanonicalTerminalOutcome.answeredCorrect,
        ),
      );

  Future<void> dispose() async {
    await coordinator.close();
    await study.close();
    await integrity.close();
    if (await _directory.exists()) await _directory.delete(recursive: true);
  }
}

Future<_Harness> _newHarness({
  bool production = false,
  String initialJournal = 'clear',
  void Function(P1StudyStoreOperation operation)? studyFailureHook,
  void Function(P1F01IntegrityOperation operation)? integrityFailureHook,
  Future<void> Function(String value)? journalWrite,
  _JournalBox? journal,
}) async {
  final directory = await Directory.systemTemp.createTemp('p1_f01_study_');
  final integrity = P1F01IntegrityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}${Platform.pathSeparator}integrity.db',
    failureHook: integrityFailureHook,
  );
  final study = P1F01StudyStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}${Platform.pathSeparator}study.db',
    failureHook: studyFailureHook,
  );
  final journalBox = journal ?? _JournalBox(initialJournal);
  final resetJournal = P1StudyResetJournalStore(
    read: () => journalBox.value,
    write: (value) async {
      await journalWrite?.call(value);
      journalBox.value = value;
    },
  );
  final coordinator = production
      ? P1F01StudyCoordinator.production(
          integrityStore: integrity,
          studyStore: study,
          resetJournal: resetJournal,
        )
      : P1F01StudyCoordinator.test(
          integrityStore: integrity,
          studyStore: study,
          resetJournal: resetJournal,
        );
  return _Harness(coordinator, integrity, study, directory, journalBox);
}

Future<_Harness> _reopenHarness(
  Directory directory, {
  _JournalBox? journal,
}) async {
  final integrity = P1F01IntegrityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}${Platform.pathSeparator}integrity.db',
  );
  final study = P1F01StudyStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}${Platform.pathSeparator}study.db',
  );
  final journalBox = journal ?? _JournalBox(P1StudyResetJournal.clear.name);
  final coordinator = P1F01StudyCoordinator.test(
    integrityStore: integrity,
    studyStore: study,
    resetJournal: P1StudyResetJournalStore(
      read: () => journalBox.value,
      write: (value) async => journalBox.value = value,
    ),
  );
  return _Harness(coordinator, integrity, study, directory, journalBox);
}

final class _JournalBox {
  _JournalBox(this.value);

  String value;
}

Future<void> _deleteIntegrityWindow(Directory directory, int sequence) async {
  final database = await databaseFactoryFfi.openDatabase(
    '${directory.path}${Platform.pathSeparator}integrity.db',
  );
  try {
    await database.delete(
      'p1_f01_integrity_window',
      where: 'local_window_sequence = ?',
      whereArgs: [sequence],
    );
  } finally {
    await database.close();
  }
}

Future<Map<String, Object?>?> _studyFinalRow(
  Directory directory,
  int sequence,
) async {
  final database = await databaseFactoryFfi.openDatabase(
    '${directory.path}${Platform.pathSeparator}study.db',
  );
  try {
    final rows = await database.query(
      P1F01StudyStore.windowFinalTable,
      where: 'integrity_window_sequence = ?',
      whereArgs: [sequence],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  } finally {
    await database.close();
  }
}

Future<void> _createCorruptStudyEpoch(
  Directory directory, {
  required Object? version,
  required bool omitVersion,
  P1StudyEpochStatus status = P1StudyEpochStatus.active,
  P1StudyEpochStopReason reason = P1StudyEpochStopReason.none,
  String? terminalTimestampUtc,
  Object? administrativeRole,
  Object? administrativeMetricsNotAccessed,
}) async {
  final database = await databaseFactoryFfi.openDatabase(
    '${directory.path}${Platform.pathSeparator}study.db',
  );
  try {
    await database.execute('''
      CREATE TABLE ${P1F01StudyStore.epochTable} (
        epoch_sequence INTEGER PRIMARY KEY,
        study_schema_version INTEGER,
        p1_f00_protocol_version TEXT,
        sample_protocol_id TEXT,
        sample_protocol_version INTEGER,
        c_windows INTEGER,
        ${omitVersion ? '' : 'semantic_taxonomy_version,'}
        epoch_status TEXT,
        epoch_stop_reason TEXT,
        admitted_study_window_count INTEGER,
        epoch_terminal_timestamp_utc TEXT,
        administrative_abort_acting_role TEXT,
        administrative_abort_metrics_not_accessed INTEGER
      )
    ''');
    await database.insert(
      P1F01StudyStore.epochTable,
      {
        'epoch_sequence': 1,
        'study_schema_version': 1,
        'p1_f00_protocol_version': '1.2',
        'sample_protocol_id': 'P1-SE-SAMPLE-00',
        'sample_protocol_version': 1,
        'c_windows': 49,
        if (!omitVersion) 'semantic_taxonomy_version': version,
        'epoch_status': status.storageValue,
        'epoch_stop_reason': reason.storageValue,
        'admitted_study_window_count': 0,
        if (terminalTimestampUtc != null)
          'epoch_terminal_timestamp_utc': terminalTimestampUtc,
        if (administrativeRole != null)
          'administrative_abort_acting_role': administrativeRole,
        if (administrativeMetricsNotAccessed != null)
          'administrative_abort_metrics_not_accessed':
              administrativeMetricsNotAccessed,
      },
    );
    await database.execute('PRAGMA user_version = 1');
  } finally {
    await database.close();
  }
}

final _legalSetCode = P1F01LegalSetCode.fromLegality(
  QuestionDifficultyLegality(
    route: QuestionDifficultyRoute.playerConfigured,
    resolvedDifficulty: Difficulty.easy,
    legalDifficulties: playerConfigurableDifficultySet,
  ),
);
