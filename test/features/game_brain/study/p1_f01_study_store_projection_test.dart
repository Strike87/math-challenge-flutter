import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_evaluator.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_store.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  test('SQLite receipt families project into immutable scientific evidence',
      () async {
    final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
    final store = P1F01StudyStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}/study.db',
    );
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });

    final epoch = await store.createOrLoadActiveEpoch();
    expect(epoch, isNotNull);
    final activeSnapshot = await store.scientificSnapshot(epoch!.epochSequence);
    expect(activeSnapshot?.epochStatus, 'ACTIVE');
    expect(activeSnapshot?.epochStopReason, 'none');
    expect(activeSnapshot?.admittedStudyWindowCount, 0);
    expect(activeSnapshot?.capacityWindows, P1F01StudyStore.capacityWindows);
    const sequence = 7;
    expect(
      await store.openWindow(P1StudyWindowOpen(
        epochSequence: epoch.epochSequence,
        integrityWindowSequence: sequence,
        activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
        agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
        runType: GameRunType.normal,
        playerCount: 1,
        gameMode: GameMode.standard,
        questionMechanic: QuestionMechanic.standard,
        answerStyle: AnswerStyle.choice4,
      )),
      isTrue,
    );
    expect(
      await store.openOpportunity(P1StudyOpportunityOpen(
        integrityWindowSequence: sequence,
        opportunityOrdinalWithinRun: 1,
        exactLegalCandidateSetCode: P1F01LegalSetCode.allPhase1,
        executedDifficulty: Difficulty.medium,
        effectiveQuestionOperation: Operation.addition,
        numberType: NumberType.natural,
      )),
      isTrue,
    );
    expect(
      await store.recordTerminal(const P1StudyOpportunityTerminal(
        integrityWindowSequence: sequence,
        opportunityOrdinalWithinRun: 1,
        canonicalTerminalOutcome:
            P1StudyCanonicalTerminalOutcome.answeredCorrect,
      )),
      isTrue,
    );
    expect(
      await store.finalizeWindow(P1StudyWindowFinal(
        integrityWindowSequence: sequence,
        studyDisposition: P1StudyWindowDisposition.cleanEligible,
        nonCleanCause: P1StudyNonCleanCause.none,
        measurementDefect: P1StudyMeasurementDefect.none,
        recoveredAfterRestart: false,
        integritySnapshot: _cleanIntegrity(sequence),
        studyOpeningReceiptCount: 1,
        studyTerminalReceiptCount: 1,
      )),
      isTrue,
    );

    final snapshot = await store.scientificSnapshot(epoch.epochSequence);
    final window = snapshot!.windows.single;
    final opportunity = window.opportunities.single;
    expect(snapshot.measurementAvailable, isTrue);
    expect(window.runSegmentId, sequence);
    expect(window.activityRunContext, 'quickPracticeTimingPractice');
    expect(window.agencyRoute, 'freshSetupAcceptedConfiguration');
    expect(window.runType, 'normal');
    expect(window.playerCount, 1);
    expect(window.gameMode, 'standard');
    expect(window.questionMechanic, 'standard');
    expect(window.answerStyle, 'choice4');
    expect(window.cleanEligible, isTrue);
    expect(opportunity.opportunityOrdinalWithinRun, 1);
    expect(opportunity.decisionContext, 'chooseDifficulty');
    expect(opportunity.decisionLocus, 'questionOpeningDifficultyResolution');
    expect(opportunity.decisionLocusReason,
        'difficultyRequiredForQuestionOpening');
    expect(opportunity.legalCandidates, {
      P1StudyCandidate.easy,
      P1StudyCandidate.medium,
      P1StudyCandidate.hard
    });
    expect(opportunity.executedCandidate, P1StudyCandidate.medium);
    expect(opportunity.canonicalSelectionMechanism, 'playerConfigured');
    expect(opportunity.operation, 'addition');
    expect(opportunity.numberType, 'natural');
    expect(opportunity.terminal, P1StudyTerminal.answeredCorrect);
    expect(opportunity.acceptedQeoLink, isTrue);
  });

  test(
      'real 49-window lifecycle projects frozen-complete readiness without mutation',
      () async {
    final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
    final store = P1F01StudyStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}/study.db',
    );
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });

    final epoch = await store.createOrLoadActiveEpoch();
    expect(epoch, isNotNull);
    final epochSequence = epoch!.epochSequence;
    for (var sequence = 1; sequence <= 48; sequence++) {
      await _admitCleanWindow(store, epochSequence, sequence);
    }

    final snapshot48 = await store.scientificSnapshot(epochSequence);
    expect(snapshot48, isNotNull);
    expect(snapshot48!.epochStatus, P1StudyEpochStatus.active.storageValue);
    expect(
        snapshot48.epochStopReason, P1StudyEpochStopReason.none.storageValue);
    expect(snapshot48.admittedStudyWindowCount, 48);
    expect(snapshot48.capacityWindows, P1F01StudyStore.capacityWindows);
    final attempt48 = attemptP1Study(snapshot48);
    expect(attempt48.readiness, isNot(P1StudyAdjudicationReadiness.ready));
    expect(attempt48.evaluation, isNull);
    expect(await _receiptCounts(store), _allReceiptCounts(48));

    await _admitCleanWindow(store, epochSequence, 49);
    final beforeSnapshot = await store.scientificSnapshot(epochSequence);
    expect(beforeSnapshot, isNotNull);
    expect(
      beforeSnapshot!.epochStatus,
      P1StudyEpochStatus.frozenForAdjudication.storageValue,
    );
    expect(
      beforeSnapshot.epochStopReason,
      P1StudyEpochStopReason.capacityReached.storageValue,
    );
    expect(beforeSnapshot.admittedStudyWindowCount, 49);
    expect(beforeSnapshot.capacityWindows, P1F01StudyStore.capacityWindows);
    final beforeCounts = await _receiptCounts(store);
    expect(beforeCounts, _allReceiptCounts(49));

    final attempt49 = attemptP1Study(beforeSnapshot);
    expect(attempt49.readiness, P1StudyAdjudicationReadiness.ready);
    expect(attempt49.evaluation, isNotNull);

    final afterSnapshot = await store.scientificSnapshot(epochSequence);
    final afterCounts = await _receiptCounts(store);
    expect(afterSnapshot?.epochStatus, beforeSnapshot.epochStatus);
    expect(afterSnapshot?.epochStopReason, beforeSnapshot.epochStopReason);
    expect(
      afterSnapshot?.admittedStudyWindowCount,
      beforeSnapshot.admittedStudyWindowCount,
    );
    expect(afterCounts, beforeCounts);
    await store.debugExecute(
      'DELETE FROM ${P1F01StudyStore.windowFinalTable} '
      'WHERE integrity_window_sequence = 49',
    );
    final missingFinal = await store.scientificSnapshot(epochSequence);
    expect(missingFinal?.measurementAvailable, isFalse);
    expect(missingFinal?.windows.last.cleanEligible, isFalse);
  });

  test(
      'frozen 49-window lifecycle retains one known missing non-clean opening without mutation',
      () async {
    final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
    final store = P1F01StudyStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}/study.db',
    );
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });

    final epoch = await store.createOrLoadActiveEpoch();
    final epochSequence = epoch!.epochSequence;
    for (var sequence = 1; sequence <= 48; sequence++) {
      await _admitCleanWindow(store, epochSequence, sequence);
    }
    expect(
      await store.openWindow(P1StudyWindowOpen(
        epochSequence: epochSequence,
        integrityWindowSequence: 49,
        activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
        agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
        runType: GameRunType.normal,
        playerCount: 1,
        gameMode: GameMode.standard,
        questionMechanic: QuestionMechanic.standard,
        answerStyle: AnswerStyle.choice4,
      )),
      isTrue,
    );
    expect(
      await store.finalizeWindow(P1StudyWindowFinal(
        integrityWindowSequence: 49,
        studyDisposition: P1StudyWindowDisposition.nonCleanMeasurementFailure,
        nonCleanCause: P1StudyNonCleanCause.none,
        measurementDefect: P1StudyMeasurementDefect.studyPersistenceFailure,
        recoveredAfterRestart: false,
        integritySnapshot: P1F01IntegritySnapshot(
          integrityVersion: P1F01IntegrityStore.integrityVersion,
          localWindowSequence: 49,
          status: P1F01IntegrityWindowStatus.leftUnclean,
          admittedORawCount: 1,
          lastAdmittedOpportunityOrdinal: 1,
          lastLegalSetCode: 'V1_EMH_MASK_7',
          lastReconciledOrdinal: null,
          hasIntegrityDefect: true,
          hasCleanClosureSignal: false,
          legalSetCounters: const {'V1_EMH_MASK_7': 1},
        ),
        studyOpeningReceiptCount: 0,
        studyTerminalReceiptCount: 0,
      )),
      isTrue,
    );

    final beforeSnapshot = await store.scientificSnapshot(epochSequence);
    final beforeCounts = await _receiptCounts(store);
    expect(beforeSnapshot?.measurementAvailable, isTrue);
    expect(beforeSnapshot?.epochStatus,
        P1StudyEpochStatus.frozenForAdjudication.storageValue);
    expect(beforeSnapshot?.epochStopReason,
        P1StudyEpochStopReason.capacityReached.storageValue);
    expect(beforeSnapshot?.admittedStudyWindowCount, 49);
    final attempt = attemptP1Study(beforeSnapshot!);
    expect(attempt.readiness, P1StudyAdjudicationReadiness.ready);
    final metrics = attempt.evaluation!.metrics;
    expect(metrics.rawOpportunityCount, 49);
    expect(metrics.validOpportunityCount, 48);
    expect(metrics.missingOpportunityCount, 1);

    final afterSnapshot = await store.scientificSnapshot(epochSequence);
    expect(await _receiptCounts(store), beforeCounts);
    expect(afterSnapshot?.measurementAvailable, isTrue);
  });

  test('claimed-clean final corruption fails closed without rewriting receipts',
      () async {
    const corruptions = <(String, String)>[
      ('integrity version', 'integrity_version = 2'),
      ('admitted count', 'final_admitted_o_raw_count = 2'),
      ('last admitted ordinal', 'last_admitted_opportunity_ordinal = 2'),
      ('last reconciled ordinal', 'last_reconciled_ordinal = 2'),
      ('last legal-set code', "last_legal_set_code = 'V1_EMH_MASK_3'"),
      ('malformed legal counters', "legal_set_counters = 'not-json'"),
      (
        'duplicate legal counter key',
        "legal_set_counters = '{\"V1_EMH_MASK_7\":1,\"V1_EMH_MASK_7\":1}'",
      ),
      ('unknown legal counter', "legal_set_counters = '{\"BAD\":1}'"),
      (
        'negative legal counter',
        "legal_set_counters = '{\"V1_EMH_MASK_7\":-1}'"
      ),
      ('legal counter sum', "legal_set_counters = '{\"V1_EMH_MASK_7\":2}'"),
      (
        'legal counter equal-sum wrong code',
        "legal_set_counters = '{\"V1_EMH_MASK_3\":1}'",
      ),
      ('Study opening count', 'study_opening_receipt_count = 2'),
      ('Study terminal count', 'study_terminal_receipt_count = 2'),
      ('non-clean cause', "non_clean_cause = 'lifecycleInterruption'"),
      (
        'measurement defect',
        "measurement_defect = 'explicitUnlinkedTerminal'",
      ),
      ('integrity defect', 'has_integrity_defect = 1'),
      ('clean-closure signal', 'has_clean_closure_signal = 0'),
      ('integrity status', "final_integrity_status = 'LEFT_UNCLEAN'"),
    ];
    for (final corruption in corruptions) {
      await _withCleanFixture((store, epochSequence) async {
        final baseline = await store.scientificSnapshot(epochSequence);
        expect(baseline?.measurementAvailable, isTrue, reason: corruption.$1);
        final beforeCounts = await _receiptCounts(store);
        await store.debugExecute(
          'UPDATE ${P1F01StudyStore.windowFinalTable} '
          'SET ${corruption.$2} WHERE integrity_window_sequence = 1',
        );
        final corrupted = await store.scientificSnapshot(epochSequence);
        expect(corrupted?.measurementAvailable, isFalse, reason: corruption.$1);
        expect(corrupted?.windows.single.cleanEligible, isFalse,
            reason: corruption.$1);
        expect(await _receiptCounts(store), beforeCounts,
            reason: corruption.$1);
      });
    }
  });

  test(
      'missing clean terminal is structural, while valid non-clean remains available',
      () async {
    await _withCleanFixture((store, epochSequence) async {
      await store.debugExecute(
        'DELETE FROM ${P1F01StudyStore.opportunityTerminalTable} '
        'WHERE integrity_window_sequence = 1',
      );
      final corrupted = await store.scientificSnapshot(epochSequence);
      expect(corrupted?.measurementAvailable, isFalse);
      expect(corrupted?.windows.single.cleanEligible, isFalse);
    });
    await _withCleanFixture((store, epochSequence) async {
      await store.debugExecute(
        'UPDATE ${P1F01StudyStore.windowFinalTable} SET '
        "study_disposition = 'nonCleanCensored', "
        "non_clean_cause = 'followUpEnvelopeExit' "
        'WHERE integrity_window_sequence = 1',
      );
      final nonClean = await store.scientificSnapshot(epochSequence);
      expect(nonClean?.measurementAvailable, isTrue);
      expect(nonClean?.windows.single.cleanEligible, isFalse);
    });
  });

  test('R1D projection preserves known missing opening in raw accounting',
      () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(1, const {'V1_EMH_MASK_7': 1}),
      openingCount: 0,
      terminalCount: 0,
      action: (store, epochSequence) async {
        final before = await _receiptCounts(store);
        final snapshot = await store.scientificSnapshot(epochSequence);
        final afterSnapshot = await _receiptCounts(store);
        expect(snapshot?.measurementAvailable, isTrue);
        expect(snapshot?.windows.single.cleanEligible, isFalse);
        final opportunity = snapshot!.windows.single.opportunities.single;
        expect(opportunity.opportunityOrdinalWithinRun, isNull);
        expect(opportunity.decisionContext, isNull);
        expect(opportunity.decisionLocus, isNull);
        expect(opportunity.decisionLocusReason, isNull);
        expect(opportunity.canonicalSelectionMechanism, isNull);
        expect(opportunity.legalCandidates, P1StudyCandidate.values.toSet());
        expect(opportunity.executedCandidate, isNull);
        expect(opportunity.operation, isNull);
        expect(opportunity.numberType, isNull);
        expect(opportunity.terminal, isNull);
        expect(opportunity.acceptedQeoLink, isNull);

        final attempt = attemptP1Study(P1StudyScientificSnapshot(
          epochSequence: epochSequence,
          measurementAvailable: snapshot.measurementAvailable,
          epochStatus: 'FROZEN_FOR_ADJUDICATION',
          epochStopReason: 'capacityReached',
          admittedStudyWindowCount: 49,
          capacityWindows: 49,
          windows: snapshot.windows,
        ));
        final metrics = attempt.evaluation!.metrics;
        expect(metrics.rawOpportunityCount, 1);
        expect(metrics.validOpportunityCount, 0);
        expect(metrics.missingOpportunityCount, 1);
        for (final candidate in P1StudyCandidate.values) {
          expect(metrics.candidateMetrics[candidate]?.missingness, 1);
          expect(metrics.candidateMetrics[candidate]?.executedExposure, 0);
          expect(metrics.candidateMetrics[candidate]?.comparableExposure, 0);
          expect(metrics.candidateMetrics[candidate]?.wilson.trials, isNull);
        }
        expect(metrics.playerSelectionConfounding.totalOtherwiseEligible, 0);
        expect(
            metrics
                .adaptiveCanonicalSelectionConfounding.totalOtherwiseEligible,
            0);
        expect(metrics.modeContextConfounding.totalOtherwiseEligible, 0);
        expect(await _receiptCounts(store), afterSnapshot);
        expect(afterSnapshot, before);
      },
    );
  });

  test(
      'non-clean counter differences preserve only the known missing legal set',
      () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(
        3,
        const {'V1_EMH_MASK_7': 2, 'V1_EMH_MASK_3': 1},
      ),
      openingCount: 2,
      terminalCount: 2,
      action: (store, epochSequence) async {
        final snapshot = await store.scientificSnapshot(epochSequence);
        expect(snapshot?.measurementAvailable, isTrue);
        final missing = snapshot!.windows.single.opportunities
            .where((opportunity) => opportunity.executedCandidate == null)
            .toList();
        expect(missing, hasLength(1));
        expect(missing.single.legalCandidates, {
          P1StudyCandidate.easy,
          P1StudyCandidate.medium,
        });
        final metrics = _readyMetrics(snapshot, epochSequence);
        expect(metrics.rawOpportunityCount, 3);
        expect(metrics.validOpportunityCount, 0);
        expect(metrics.missingOpportunityCount, 3);
        expect(metrics.candidateMetrics[P1StudyCandidate.easy]!.missingness, 1);
        expect(
            metrics.candidateMetrics[P1StudyCandidate.medium]!.missingness, 1);
        expect(metrics.candidateMetrics[P1StudyCandidate.hard]!.missingness, 1);
      },
    );
  });

  test('MASK_3 missing receipt contributes only Easy and Medium denominators',
      () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(1, const {'V1_EMH_MASK_3': 1}),
      openingCount: 0,
      terminalCount: 0,
      action: (store, epochSequence) async {
        final snapshot = await store.scientificSnapshot(epochSequence);
        final opportunity = snapshot!.windows.single.opportunities.single;
        expect(opportunity.legalCandidates,
            {P1StudyCandidate.easy, P1StudyCandidate.medium});
        final metrics = _readyMetrics(snapshot, epochSequence);
        expect(metrics.rawOpportunityCount, 1);
        expect(metrics.validOpportunityCount, 0);
        expect(metrics.missingOpportunityCount, 1);
        expect(metrics.candidateMetrics[P1StudyCandidate.easy]!.missingness, 1);
        expect(
            metrics.candidateMetrics[P1StudyCandidate.medium]!.missingness, 1);
        expect(metrics.candidateMetrics[P1StudyCandidate.hard]!.missingness,
            isNull);
      },
    );
  });

  test('active missing final remains available but terminal epochs fail closed',
      () async {
    final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
    final store = P1F01StudyStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}/study.db',
    );
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    final epoch = (await store.createOrLoadActiveEpoch())!;
    expect(
      await store.openWindow(P1StudyWindowOpen(
        epochSequence: epoch.epochSequence,
        integrityWindowSequence: 1,
        activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
        agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
        runType: GameRunType.normal,
        playerCount: 1,
        gameMode: GameMode.standard,
        questionMechanic: QuestionMechanic.standard,
        answerStyle: AnswerStyle.choice4,
      )),
      isTrue,
    );
    expect(
        (await store.scientificSnapshot(epoch.epochSequence))!
            .measurementAvailable,
        isTrue);
    await store.debugExecute(
      'UPDATE ${P1F01StudyStore.epochTable} SET '
      "epoch_status = 'FROZEN_FOR_ADJUDICATION', "
      "epoch_stop_reason = 'capacityReached' WHERE epoch_sequence = 1",
    );
    expect(
        (await store.scientificSnapshot(epoch.epochSequence))!
            .measurementAvailable,
        isFalse);
    await store.debugExecute(
      'UPDATE ${P1F01StudyStore.epochTable} SET '
      "epoch_status = 'ADJUDICATED', "
      "epoch_terminal_timestamp_utc = '2026-09-01T00:00:00.000Z' "
      'WHERE epoch_sequence = 1',
    );
    expect(
        (await store.scientificSnapshot(epoch.epochSequence))!
            .measurementAvailable,
        isFalse);
  });

  test(
    'R1D counter-derived Store receipts isolate 50/1000 and 51/1000',
    () async {
      for (final missing in [50, 51]) {
        final valid = 1000 - missing;
        final directory =
            await Directory.systemTemp.createTemp('p1-eval-store-');
        final store = P1F01StudyStore(
          databaseFactory: databaseFactoryFfi,
          databasePath: '${directory.path}/study.db',
        );
        try {
          final epoch = (await store.createOrLoadActiveEpoch())!;
          for (var sequence = 1; sequence <= 46; sequence++) {
            await _admitCleanWindowWithCount(
              store,
              epoch.epochSequence,
              sequence,
              sequence <= 5
                  ? 25
                  : sequence == 6
                      ? valid - 925
                      : 20,
            );
          }
          final missingByWindow =
              missing == 50 ? const [25, 24, 1] : const [25, 25, 1];
          for (var index = 0; index < missingByWindow.length; index++) {
            final sequence = 47 + index;
            final count = missingByWindow[index];
            expect(
              await store.openWindow(P1StudyWindowOpen(
                epochSequence: epoch.epochSequence,
                integrityWindowSequence: sequence,
                activityRunContext:
                    P1ActivityRunContext.quickPracticeTimingPractice,
                agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
                runType: GameRunType.normal,
                playerCount: 1,
                gameMode: GameMode.standard,
                questionMechanic: QuestionMechanic.standard,
                answerStyle: AnswerStyle.choice4,
              )),
              isTrue,
            );
            expect(
              await store.finalizeWindow(P1StudyWindowFinal(
                integrityWindowSequence: sequence,
                studyDisposition:
                    P1StudyWindowDisposition.nonCleanMeasurementFailure,
                nonCleanCause: P1StudyNonCleanCause.none,
                measurementDefect:
                    P1StudyMeasurementDefect.studyPersistenceFailure,
                recoveredAfterRestart: false,
                integritySnapshot: _nonCleanIntegrity(
                    count, {'V1_EMH_MASK_7': count}, sequence),
                studyOpeningReceiptCount: 0,
                studyTerminalReceiptCount: 0,
              )),
              isTrue,
            );
          }
          final snapshot = await store.scientificSnapshot(epoch.epochSequence);
          final evaluation = attemptP1Study(snapshot!);
          expect(evaluation.readiness, P1StudyAdjudicationReadiness.ready);
          final metrics = evaluation.evaluation!.metrics;
          expect(metrics.rawOpportunityCount, 1000);
          expect(metrics.validOpportunityCount, valid);
          expect(metrics.missingOpportunityCount, missing);
          expect(metrics.globalMissingness, missing / 1000);
          if (missing == 50) {
            expect(evaluation.evaluation!.status,
                P1StudyEvaluationStatus.feasible);
          } else {
            expect(evaluation.evaluation!.inconclusiveReason,
                P1StudyInconclusiveReason.missingnessAboveThreshold);
          }
        } finally {
          await store.close();
          await directory.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('non-clean receipt-family contradictions fail closed', () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(1, const {'V1_EMH_MASK_7': 1}),
      openingCount: 1,
      terminalCount: 1,
      action: (store, epochSequence) async {
        await store.debugExecute(
          'UPDATE ${P1F01StudyStore.windowFinalTable} '
          "SET legal_set_counters = '{\"V1_EMH_MASK_3\":1}' "
          'WHERE integrity_window_sequence = 1',
        );
        final snapshot = await store.scientificSnapshot(epochSequence);
        expect(snapshot?.measurementAvailable, isFalse);
        expect(snapshot?.windows.single.cleanEligible, isFalse);
      },
    );
  });

  test('non-clean counter and receipt-count corruption fails closed', () async {
    const corruptions = <String>[
      "legal_set_counters = 'not-json'",
      "legal_set_counters = '{\"BAD\":1}'",
      "legal_set_counters = '{\"V1_EMH_MASK_7\":-1}'",
      "legal_set_counters = '{\"V1_EMH_MASK_7\":1,\"V1_EMH_MASK_7\":0}'",
      "legal_set_counters = '{\"V1_EMH_MASK_7\":2}'",
      'study_opening_receipt_count = 1',
      'study_terminal_receipt_count = 1',
      "study_disposition = 'nonCleanCensored', non_clean_cause = 'none', measurement_defect = 'none'",
      "study_disposition = 'nonCleanCensored', non_clean_cause = 'followUpEnvelopeExit', measurement_defect = 'studyPersistenceFailure'",
    ];
    for (final corruption in corruptions) {
      await _withNonCleanWindow(
        integrity: _nonCleanIntegrity(1, const {'V1_EMH_MASK_7': 1}),
        openingCount: 0,
        terminalCount: 0,
        action: (store, epochSequence) async {
          await store.debugExecute(
            'UPDATE ${P1F01StudyStore.windowFinalTable} SET $corruption '
            'WHERE integrity_window_sequence = 1',
          );
          final snapshot = await store.scientificSnapshot(epochSequence);
          expect(snapshot?.measurementAvailable, isFalse, reason: corruption);
          expect(snapshot?.windows.single.cleanEligible, isFalse);
        },
      );
    }
  });

  test('non-clean admitted count accepts 25 missing receipts and rejects 26',
      () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(25, const {'V1_EMH_MASK_7': 25}),
      openingCount: 0,
      terminalCount: 0,
      action: (store, epochSequence) async {
        final baseline = await store.scientificSnapshot(epochSequence);
        final finalCount =
            await store.debugRowCount(P1F01StudyStore.windowFinalTable);
        expect(baseline?.measurementAvailable, isTrue);
        expect(baseline?.windows.single.cleanEligible, isFalse);

        await store.debugExecute(
          'UPDATE ${P1F01StudyStore.windowFinalTable} SET '
          'final_admitted_o_raw_count = 26, '
          "legal_set_counters = '{\"V1_EMH_MASK_7\":26}' "
          'WHERE integrity_window_sequence = 1',
        );

        final corrupted = await store.scientificSnapshot(epochSequence);
        final repeated = await store.scientificSnapshot(epochSequence);
        expect(corrupted?.measurementAvailable, isFalse);
        expect(corrupted?.windows.single.cleanEligible, isFalse);
        expect(repeated?.measurementAvailable, isFalse);
        expect(await store.debugRowCount(P1F01StudyStore.windowFinalTable),
            finalCount);
      },
      afterAction: (databasePath) async {
        final db = await databaseFactoryFfi.openDatabase(databasePath);
        try {
          final row = (await db.rawQuery(
            'SELECT final_admitted_o_raw_count, legal_set_counters '
            'FROM ${P1F01StudyStore.windowFinalTable} '
            'WHERE integrity_window_sequence = 1',
          ))
              .single;
          expect(row['final_admitted_o_raw_count'], 26);
          expect(row['legal_set_counters'], '{"V1_EMH_MASK_7":26}');
        } finally {
          await db.close();
        }
      },
    );
  });

  test('unknown non-clean vocabulary fails closed after direct corruption',
      () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(1, const {'V1_EMH_MASK_7': 1}),
      openingCount: 0,
      terminalCount: 0,
      action: (store, epochSequence) async {
        await store.debugExecute('PRAGMA ignore_check_constraints = ON');
        await store.debugExecute(
          'UPDATE ${P1F01StudyStore.windowFinalTable} SET '
          "non_clean_cause = 'BOGUS', measurement_defect = 'BOGUS' "
          'WHERE integrity_window_sequence = 1',
        );
        final snapshot = await store.scientificSnapshot(epochSequence);
        expect(snapshot?.measurementAvailable, isFalse);
        expect(snapshot?.windows.single.cleanEligible, isFalse);
      },
    );
  });

  test('non-clean complete and terminal-only receipt loss do not double count',
      () async {
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(3, const {'V1_EMH_MASK_7': 3}),
      openingCount: 3,
      terminalCount: 3,
      action: (store, epochSequence) async {
        final snapshot = await store.scientificSnapshot(epochSequence);
        final metrics = _readyMetrics(snapshot!, epochSequence);
        expect(metrics.rawOpportunityCount, 3);
        expect(metrics.validOpportunityCount, 0);
        expect(metrics.missingOpportunityCount, 3);
      },
    );
    await _withNonCleanWindow(
      integrity: _nonCleanIntegrity(1, const {'V1_EMH_MASK_7': 1}),
      openingCount: 1,
      terminalCount: 0,
      action: (store, epochSequence) async {
        final snapshot = await store.scientificSnapshot(epochSequence);
        final metrics = _readyMetrics(snapshot!, epochSequence);
        expect(metrics.rawOpportunityCount, 1);
        expect(metrics.validOpportunityCount, 0);
        expect(metrics.missingOpportunityCount, 1);
        expect(snapshot.windows.single.opportunities, hasLength(1));
      },
    );
  });

  test('foreign-key schema rejects a final/window identity mismatch', () async {
    await _withCleanFixture((store, _) async {
      expect(
        () => store.debugExecute(
          'UPDATE ${P1F01StudyStore.windowFinalTable} '
          'SET integrity_window_sequence = 2 WHERE integrity_window_sequence = 1',
        ),
        throwsA(anything),
      );
    });
  });

  test(
      'equal-sum swapped legal counters and orphan terminals cannot pass clean',
      () async {
    await _withThreeOpportunityFixture((store, epochSequence) async {
      final baseline = await store.scientificSnapshot(epochSequence);
      expect(baseline?.measurementAvailable, isTrue);
      await store.debugExecute(
        'UPDATE ${P1F01StudyStore.windowFinalTable} SET '
        "legal_set_counters = '{\"V1_EMH_MASK_7\":1,\"V1_EMH_MASK_3\":2}' "
        'WHERE integrity_window_sequence = 1',
      );
      final corrupted = await store.scientificSnapshot(epochSequence);
      expect(corrupted?.measurementAvailable, isFalse);
      expect(corrupted?.windows.single.cleanEligible, isFalse);
    });
    await _withCleanFixture((store, _) async {
      expect(
        () => store.debugExecute(
          'INSERT INTO ${P1F01StudyStore.opportunityTerminalTable} '
          '(integrity_window_sequence, opportunity_ordinal_within_run, '
          'canonical_terminal_outcome, accepted_qeo_link) '
          "VALUES (1, 2, 'AnsweredCorrect', 1)",
        ),
        throwsA(anything),
      );
    });
  });

  test(
      'post-baseline opening ordinal gap is structurally unavailable, not null',
      () async {
    await _withThreeOpportunityFixture((store, epochSequence) async {
      await store.debugExecute(
        'DELETE FROM ${P1F01StudyStore.opportunityTerminalTable} '
        'WHERE integrity_window_sequence = 1 '
        'AND opportunity_ordinal_within_run = 2',
      );
      await store.debugExecute(
        'UPDATE ${P1F01StudyStore.opportunityOpenTable} '
        'SET opportunity_ordinal_within_run = 4 '
        'WHERE integrity_window_sequence = 1 '
        'AND opportunity_ordinal_within_run = 2',
      );
      await store.debugExecute(
        'INSERT INTO ${P1F01StudyStore.opportunityTerminalTable} '
        '(integrity_window_sequence, opportunity_ordinal_within_run, '
        'canonical_terminal_outcome, accepted_qeo_link) '
        "VALUES (1, 4, 'AnsweredCorrect', 1)",
      );
      final corrupted = await store.scientificSnapshot(epochSequence);
      expect(corrupted, isNotNull);
      expect(corrupted?.measurementAvailable, isFalse);
      expect(corrupted?.windows.single.cleanEligible, isFalse);
    });
  });

  test('frozen ready epoch remains ready when a corrupt final is unavailable',
      () async {
    final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
    final store = P1F01StudyStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: '${directory.path}/study.db',
    );
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    final epoch = await store.createOrLoadActiveEpoch();
    final epochSequence = epoch!.epochSequence;
    for (var sequence = 1; sequence <= 49; sequence++) {
      await _admitCleanWindow(store, epochSequence, sequence);
    }
    final before = await store.scientificSnapshot(epochSequence);
    final beforeCounts = await _receiptCounts(store);
    expect(before?.measurementAvailable, isTrue);
    expect(
      attemptP1Study(before!).readiness,
      P1StudyAdjudicationReadiness.ready,
    );

    await store.debugExecute(
      'UPDATE ${P1F01StudyStore.windowFinalTable} SET '
      "legal_set_counters = '{\"V1_EMH_MASK_3\":1}' "
      'WHERE integrity_window_sequence = 1',
    );

    final after = await store.scientificSnapshot(epochSequence);
    final attempt = attemptP1Study(after!);
    expect(after.epochStatus, before.epochStatus);
    expect(after.epochStopReason, before.epochStopReason);
    expect(after.admittedStudyWindowCount, before.admittedStudyWindowCount);
    expect(after.measurementAvailable, isFalse);
    expect(attempt.readiness, P1StudyAdjudicationReadiness.ready);
    expect(attempt.evaluation?.status, P1StudyEvaluationStatus.inconclusive);
    expect(
      attempt.evaluation?.inconclusiveReason,
      P1StudyInconclusiveReason.measurementUnavailable,
    );
    expect(await _receiptCounts(store), beforeCounts);
  });
}

Future<void> _withCleanFixture(
  Future<void> Function(P1F01StudyStore store, int epochSequence) action,
) async {
  final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
  final store = P1F01StudyStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}/study.db',
  );
  try {
    final epoch = await store.createOrLoadActiveEpoch();
    await _admitCleanWindow(store, epoch!.epochSequence, 1);
    await action(store, epoch.epochSequence);
  } finally {
    await store.close();
    await directory.delete(recursive: true);
  }
}

P1StudyEvaluationMetrics _readyMetrics(
  P1StudyScientificSnapshot snapshot,
  int epochSequence,
) =>
    attemptP1Study(P1StudyScientificSnapshot(
      epochSequence: epochSequence,
      measurementAvailable: snapshot.measurementAvailable,
      epochStatus: 'FROZEN_FOR_ADJUDICATION',
      epochStopReason: 'capacityReached',
      admittedStudyWindowCount: 49,
      capacityWindows: 49,
      windows: snapshot.windows,
    )).evaluation!.metrics;

Future<void> _withNonCleanWindow({
  required P1F01IntegritySnapshot integrity,
  required int openingCount,
  required int terminalCount,
  required Future<void> Function(P1F01StudyStore store, int epochSequence)
      action,
  Future<void> Function(String databasePath)? afterAction,
}) async {
  final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
  final databasePath = '${directory.path}/study.db';
  final store = P1F01StudyStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: databasePath,
  );
  try {
    final epoch = await store.createOrLoadActiveEpoch();
    final epochSequence = epoch!.epochSequence;
    expect(
      await store.openWindow(P1StudyWindowOpen(
        epochSequence: epochSequence,
        integrityWindowSequence: 1,
        activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
        agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
        runType: GameRunType.normal,
        playerCount: 1,
        gameMode: GameMode.standard,
        questionMechanic: QuestionMechanic.standard,
        answerStyle: AnswerStyle.choice4,
      )),
      isTrue,
    );
    for (var ordinal = 1; ordinal <= openingCount; ordinal++) {
      expect(
        await store.openOpportunity(P1StudyOpportunityOpen(
          integrityWindowSequence: 1,
          opportunityOrdinalWithinRun: ordinal,
          exactLegalCandidateSetCode: P1F01LegalSetCode.allPhase1,
          executedDifficulty: Difficulty.easy,
          effectiveQuestionOperation: Operation.addition,
          numberType: NumberType.natural,
        )),
        isTrue,
      );
    }
    for (var ordinal = 1; ordinal <= terminalCount; ordinal++) {
      expect(
        await store.recordTerminal(P1StudyOpportunityTerminal(
          integrityWindowSequence: 1,
          opportunityOrdinalWithinRun: ordinal,
          canonicalTerminalOutcome:
              P1StudyCanonicalTerminalOutcome.answeredIncorrect,
        )),
        isTrue,
      );
    }
    expect(
      await store.finalizeWindow(P1StudyWindowFinal(
        integrityWindowSequence: 1,
        studyDisposition: P1StudyWindowDisposition.nonCleanMeasurementFailure,
        nonCleanCause: P1StudyNonCleanCause.none,
        measurementDefect: P1StudyMeasurementDefect.studyPersistenceFailure,
        recoveredAfterRestart: false,
        integritySnapshot: integrity,
        studyOpeningReceiptCount: openingCount,
        studyTerminalReceiptCount: terminalCount,
      )),
      isTrue,
    );
    await action(store, epochSequence);
    await afterAction?.call(databasePath);
  } finally {
    await store.close();
    await directory.delete(recursive: true);
  }
}

P1F01IntegritySnapshot _nonCleanIntegrity(
        int admitted, Map<String, int> legalSetCounters,
        [int sequence = 1]) =>
    P1F01IntegritySnapshot(
      integrityVersion: P1F01IntegrityStore.integrityVersion,
      localWindowSequence: sequence,
      status: P1F01IntegrityWindowStatus.leftUnclean,
      admittedORawCount: admitted,
      lastAdmittedOpportunityOrdinal: admitted == 0 ? null : admitted,
      lastLegalSetCode:
          legalSetCounters.isEmpty ? null : legalSetCounters.keys.last,
      lastReconciledOrdinal: null,
      hasIntegrityDefect: true,
      hasCleanClosureSignal: false,
      legalSetCounters: legalSetCounters,
    );

Future<void> _withThreeOpportunityFixture(
  Future<void> Function(P1F01StudyStore store, int epochSequence) action,
) async {
  final directory = await Directory.systemTemp.createTemp('p1-eval-store-');
  final store = P1F01StudyStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}/study.db',
  );
  try {
    final epoch = await store.createOrLoadActiveEpoch();
    final epochSequence = epoch!.epochSequence;
    expect(
      await store.openWindow(P1StudyWindowOpen(
        epochSequence: epochSequence,
        integrityWindowSequence: 1,
        activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
        agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
        runType: GameRunType.normal,
        playerCount: 1,
        gameMode: GameMode.standard,
        questionMechanic: QuestionMechanic.standard,
        answerStyle: AnswerStyle.choice4,
      )),
      isTrue,
    );
    final codes = [
      P1F01LegalSetCode.allPhase1,
      P1F01LegalSetCode.allPhase1,
      P1F01LegalSetCode.fromStoredValue('V1_EMH_MASK_3')!,
    ];
    for (var index = 0; index < codes.length; index++) {
      final ordinal = index + 1;
      expect(
        await store.openOpportunity(P1StudyOpportunityOpen(
          integrityWindowSequence: 1,
          opportunityOrdinalWithinRun: ordinal,
          exactLegalCandidateSetCode: codes[index],
          executedDifficulty: Difficulty.easy,
          effectiveQuestionOperation: Operation.addition,
          numberType: NumberType.natural,
        )),
        isTrue,
      );
      expect(
        await store.recordTerminal(P1StudyOpportunityTerminal(
          integrityWindowSequence: 1,
          opportunityOrdinalWithinRun: ordinal,
          canonicalTerminalOutcome:
              P1StudyCanonicalTerminalOutcome.answeredCorrect,
        )),
        isTrue,
      );
    }
    expect(
      await store.finalizeWindow(P1StudyWindowFinal(
        integrityWindowSequence: 1,
        studyDisposition: P1StudyWindowDisposition.cleanEligible,
        nonCleanCause: P1StudyNonCleanCause.none,
        measurementDefect: P1StudyMeasurementDefect.none,
        recoveredAfterRestart: false,
        integritySnapshot: P1F01IntegritySnapshot(
          integrityVersion: P1F01IntegrityStore.integrityVersion,
          localWindowSequence: 1,
          status: P1F01IntegrityWindowStatus.cleanlyClosed,
          admittedORawCount: 3,
          lastAdmittedOpportunityOrdinal: 3,
          lastLegalSetCode: 'V1_EMH_MASK_3',
          lastReconciledOrdinal: 3,
          hasIntegrityDefect: false,
          hasCleanClosureSignal: true,
          legalSetCounters: const {'V1_EMH_MASK_7': 2, 'V1_EMH_MASK_3': 1},
        ),
        studyOpeningReceiptCount: 3,
        studyTerminalReceiptCount: 3,
      )),
      isTrue,
    );
    await action(store, epochSequence);
  } finally {
    await store.close();
    await directory.delete(recursive: true);
  }
}

Future<void> _admitCleanWindow(
  P1F01StudyStore store,
  int epochSequence,
  int sequence,
) async {
  final difficulty = switch ((sequence - 1) % 3) {
    0 => Difficulty.easy,
    1 => Difficulty.medium,
    _ => Difficulty.hard,
  };
  expect(
    await store.openWindow(P1StudyWindowOpen(
      epochSequence: epochSequence,
      integrityWindowSequence: sequence,
      activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
      agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
      runType: GameRunType.normal,
      playerCount: 1,
      gameMode: GameMode.standard,
      questionMechanic: QuestionMechanic.standard,
      answerStyle: AnswerStyle.choice4,
    )),
    isTrue,
  );
  expect(
    await store.openOpportunity(P1StudyOpportunityOpen(
      integrityWindowSequence: sequence,
      opportunityOrdinalWithinRun: 1,
      exactLegalCandidateSetCode: P1F01LegalSetCode.allPhase1,
      executedDifficulty: difficulty,
      effectiveQuestionOperation: Operation.addition,
      numberType: NumberType.natural,
    )),
    isTrue,
  );
  expect(
    await store.recordTerminal(P1StudyOpportunityTerminal(
      integrityWindowSequence: sequence,
      opportunityOrdinalWithinRun: 1,
      canonicalTerminalOutcome: P1StudyCanonicalTerminalOutcome.answeredCorrect,
    )),
    isTrue,
  );
  expect(
    await store.finalizeWindow(P1StudyWindowFinal(
      integrityWindowSequence: sequence,
      studyDisposition: P1StudyWindowDisposition.cleanEligible,
      nonCleanCause: P1StudyNonCleanCause.none,
      measurementDefect: P1StudyMeasurementDefect.none,
      recoveredAfterRestart: false,
      integritySnapshot: _cleanIntegrity(sequence),
      studyOpeningReceiptCount: 1,
      studyTerminalReceiptCount: 1,
    )),
    isTrue,
  );
}

Future<void> _admitCleanWindowWithCount(
  P1F01StudyStore store,
  int epochSequence,
  int sequence,
  int count,
) async {
  final operation = switch ((sequence - 1) % 3) {
    0 => Operation.addition,
    1 => Operation.subtraction,
    _ => Operation.multiplication,
  };
  expect(
    await store.openWindow(P1StudyWindowOpen(
      epochSequence: epochSequence,
      integrityWindowSequence: sequence,
      activityRunContext: P1ActivityRunContext.quickPracticeTimingPractice,
      agencyRoute: P1AgencyRoute.freshSetupAcceptedConfiguration,
      runType: GameRunType.normal,
      playerCount: 1,
      gameMode: GameMode.standard,
      questionMechanic: QuestionMechanic.standard,
      answerStyle: AnswerStyle.choice4,
    )),
    isTrue,
  );
  for (var ordinal = 1; ordinal <= count; ordinal++) {
    expect(
      await store.openOpportunity(P1StudyOpportunityOpen(
        integrityWindowSequence: sequence,
        opportunityOrdinalWithinRun: ordinal,
        exactLegalCandidateSetCode: P1F01LegalSetCode.allPhase1,
        executedDifficulty: switch ((ordinal - 1) % 3) {
          0 => Difficulty.easy,
          1 => Difficulty.medium,
          _ => Difficulty.hard,
        },
        effectiveQuestionOperation: operation,
        numberType: NumberType.natural,
      )),
      isTrue,
    );
    expect(
      await store.recordTerminal(P1StudyOpportunityTerminal(
        integrityWindowSequence: sequence,
        opportunityOrdinalWithinRun: ordinal,
        canonicalTerminalOutcome:
            P1StudyCanonicalTerminalOutcome.answeredCorrect,
      )),
      isTrue,
    );
  }
  expect(
    await store.finalizeWindow(P1StudyWindowFinal(
      integrityWindowSequence: sequence,
      studyDisposition: P1StudyWindowDisposition.cleanEligible,
      nonCleanCause: P1StudyNonCleanCause.none,
      measurementDefect: P1StudyMeasurementDefect.none,
      recoveredAfterRestart: false,
      integritySnapshot: P1F01IntegritySnapshot(
        integrityVersion: P1F01IntegrityStore.integrityVersion,
        localWindowSequence: sequence,
        status: P1F01IntegrityWindowStatus.cleanlyClosed,
        admittedORawCount: count,
        lastAdmittedOpportunityOrdinal: count,
        lastLegalSetCode: P1F01LegalSetCode.allPhase1.value,
        lastReconciledOrdinal: count,
        hasIntegrityDefect: false,
        hasCleanClosureSignal: true,
        legalSetCounters: {P1F01LegalSetCode.allPhase1.value: count},
      ),
      studyOpeningReceiptCount: count,
      studyTerminalReceiptCount: count,
    )),
    isTrue,
  );
}

Future<Map<String, int>> _receiptCounts(P1F01StudyStore store) async => {
      P1F01StudyStore.windowOpenTable:
          await store.debugRowCount(P1F01StudyStore.windowOpenTable),
      P1F01StudyStore.opportunityOpenTable:
          await store.debugRowCount(P1F01StudyStore.opportunityOpenTable),
      P1F01StudyStore.opportunityTerminalTable:
          await store.debugRowCount(P1F01StudyStore.opportunityTerminalTable),
      P1F01StudyStore.windowFinalTable:
          await store.debugRowCount(P1F01StudyStore.windowFinalTable),
    };

Map<String, int> _allReceiptCounts(int count) => {
      P1F01StudyStore.windowOpenTable: count,
      P1F01StudyStore.opportunityOpenTable: count,
      P1F01StudyStore.opportunityTerminalTable: count,
      P1F01StudyStore.windowFinalTable: count,
    };

P1F01IntegritySnapshot _cleanIntegrity(int sequence) => P1F01IntegritySnapshot(
      integrityVersion: P1F01IntegrityStore.integrityVersion,
      localWindowSequence: sequence,
      status: P1F01IntegrityWindowStatus.cleanlyClosed,
      admittedORawCount: 1,
      lastAdmittedOpportunityOrdinal: 1,
      lastLegalSetCode: P1F01LegalSetCode.allPhase1.value,
      lastReconciledOrdinal: 1,
      hasIntegrityDefect: false,
      hasCleanClosureSignal: true,
      legalSetCounters: {P1F01LegalSetCode.allPhase1.value: 1},
    );
