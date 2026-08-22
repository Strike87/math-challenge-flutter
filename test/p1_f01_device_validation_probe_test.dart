import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_device_validation_probe.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/features/gameplay/domain/question_difficulty_legality.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _validationEnabled = bool.fromEnvironment('P1_F01_DEVICE_VALIDATION');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const globalAudioChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  setUpAll(() {
    sqfliteFfiInit();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalAudioChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (_) async => null);
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalAudioChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
  });

  group('P1F01DeviceValidationProbe', () {
    test('availability requires both debug and the validation define', () {
      expect(
        P1F01DeviceValidationProbe.availableFor(
          isDebugBuild: false,
          validationFlag: false,
        ),
        isFalse,
      );
      expect(
        P1F01DeviceValidationProbe.availableFor(
          isDebugBuild: false,
          validationFlag: true,
        ),
        isFalse,
      );
      expect(
        P1F01DeviceValidationProbe.availableFor(
          isDebugBuild: true,
          validationFlag: false,
        ),
        isFalse,
      );
      expect(
        P1F01DeviceValidationProbe.availableFor(
          isDebugBuild: true,
          validationFlag: true,
        ),
        isTrue,
      );
      expect(
        P1F01DeviceValidationServiceExtension.shouldRegisterFor(
          isDebugBuild: false,
          validationFlag: true,
        ),
        isFalse,
      );
      expect(
        P1F01DeviceValidationServiceExtension.shouldRegisterFor(
          isDebugBuild: true,
          validationFlag: true,
        ),
        isTrue,
      );
      expect(
        P1F01TransactionBoundaryController.availableFor(
          isDebugBuild: false,
          validationFlag: true,
        ),
        isFalse,
      );
      expect(
        P1F01TransactionBoundaryController.availableFor(
          isDebugBuild: true,
          validationFlag: true,
        ),
        isTrue,
      );
    });

    test('default build cannot access or mutate integrity state', () async {
      final store = await _newStore();
      addTearDown(store.close);
      await store.admitWindow();
      final probe = P1F01DeviceValidationProbe(store);

      expect(probe.isAvailable, isFalse);
      expect(await probe.currentSnapshot(), isNull);
      expect(await probe.retainedSnapshots(), isEmpty);
      await probe.drain();
      expect(await probe.retryLastAdmission(), isNull);
      expect(await probe.retryConflictingLastAdmission(), isNull);
      expect(await probe.admitGappedOrdinal(), isNull);
      expect(await probe.armBeforeCommit(), isNull);
      expect(await probe.armAfterCommitBeforeAck(), isNull);
      expect(await probe.readBoundaryState(), isNull);
      expect(await probe.releaseBoundary(), isNull);
      expect(await probe.handleCommand('readBoundaryState'),
          const {'status': 'unavailable'});
      expect((await store.latestSnapshot())?.status,
          P1F01IntegrityWindowStatus.open);
    },
        skip: _validationEnabled
            ? 'requires the default validation flag'
            : false);

    test('sanitizes to the approved integrity metadata only', () async {
      final store = await _newStore();
      addTearDown(store.close);
      final source = await store.admitWindow();
      final snapshot = P1F01DeviceValidationSnapshot.fromStore(source!);

      expect(snapshot.integrityVersion, P1F01IntegrityStore.integrityVersion);
      expect(snapshot.localWindowSequence, 1);
      expect(snapshot.status, P1F01IntegrityWindowStatus.open);
      expect(snapshot.admittedORawCount, 0);
      expect(snapshot.lastAdmittedOpportunityOrdinal, isNull);
      expect(snapshot.lastLegalSetCode, isNull);
      expect(snapshot.lastReconciledOrdinal, isNull);
      expect(snapshot.hasIntegrityDefect, isFalse);
      expect(snapshot.hasCleanClosureSignal, isFalse);
      expect(snapshot.legalSetCounters, isEmpty);
      expect(() => snapshot.legalSetCounters['x'] = 1, throwsUnsupportedError);
      expect(snapshot.toJson().keys, {
        'integrityVersion',
        'localWindowSequence',
        'status',
        'admittedORawCount',
        'lastAdmittedOrdinal',
        'lastLegalSetCode',
        'lastReconciledOrdinal',
        'hasIntegrityDefect',
        'hasCleanClosureSignal',
        'legalSetCounters',
      });
    });

    test('disabled boundary controller is a total bypass with no await',
        () async {
      final controller = P1F01TransactionBoundaryController();
      final store = await _newStore(boundaryController: controller);
      expect(controller.isAvailable, isFalse);
      expect(controller.armBeforeCommit(), isFalse);
      expect(controller.armAfterCommitBeforeAck(), isFalse);
      expect(controller.readBoundaryState()['state'],
          P1F01TransactionBoundaryState.disarmed.value);
      expect(controller.readBoundaryState()['phase'], isNull);

      // The disabled path must not INVOKE either hook at all — no validation
      // Future is created, awaited, or even constructed.
      expect(controller.beforeCommitInvocations, 0);
      expect(controller.afterCommitBeforeAckInvocations, 0);

      await store.admitWindow();
      expect(
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.admitted,
      );
      expect(
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 2,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.admitted,
      );
      expect(
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 2,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.alreadyAdmitted,
      );

      // Zero invocations of either hook across admitted, idempotent, and
      // failed-closed admission paths.
      expect(controller.beforeCommitInvocations, 0);
      expect(controller.afterCommitBeforeAckInvocations, 0);
    });

    if (_validationEnabled) {

      test('available validation extension leaves eligible gameplay unchanged',
          () async {
        final baseline = await _newGameState(
          QuestionGenerator(rng: Random(1408)),
          await _newStore(),
        );
        final validated = await _newGameState(
          QuestionGenerator(rng: Random(1408)),
          await _newStore(),
        );
        expect(
            P1F01DeviceValidationProbe(await _newStore()).isAvailable, isTrue);

        for (final state in [baseline, validated]) {
          await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
          await state.setGameBrainPreference(true);
          state
            ..rt.challenge = Operation.addition
            ..mode = GameMode.standard
            ..diff = Difficulty.easy
            ..numType = NumberType.natural
            ..questionCount = 10
            ..adaptive = false
            ..selectedAnswerStyle = AnswerStyle.choice4
            ..startGame();
          state.rt.timer?.cancel();
        }

        expect(_questionSignature(validated.rt.q!),
            _questionSignature(baseline.rt.q!));
        baseline.onAnswer(baseline.rt.q!.ans);
        validated.onAnswer(validated.rt.q!.ans);
        expect(validated.p[1].score, baseline.p[1].score);
        expect(validated.rt.totalTurns, baseline.rt.totalTurns);
        final baselineIntegrity = await _latestIntegrity(baseline);
        final validatedIntegrity = await _latestIntegrity(validated);
        expect(validatedIntegrity?.status, baselineIntegrity?.status);
        expect(validatedIntegrity?.admittedORawCount,
            baselineIntegrity?.admittedORawCount);
        expect(validatedIntegrity?.lastAdmittedOpportunityOrdinal,
            baselineIntegrity?.lastAdmittedOpportunityOrdinal);
      });

      test('reads without mutation and drains only queued work', () async {
        final store = await _newStore();
        addTearDown(store.close);
        await store.admitWindow();
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        );
        final probe = P1F01DeviceValidationProbe(store);

        expect(probe.isAvailable, isTrue);
        final before = await probe.currentSnapshot();
        await probe.drain();
        final after = await probe.currentSnapshot();
        expect(after?.admittedORawCount, before?.admittedORawCount);
        expect(after?.lastAdmittedOpportunityOrdinal,
            before?.lastAdmittedOpportunityOrdinal);
        expect((await probe.retainedSnapshots()).single.localWindowSequence, 1);
        expect(
          await probe.handleCommand('readCurrent'),
          {'snapshot': after?.toJson()},
        );
      });

      test('bounded commands delegate to store retry and fail-closed semantics',
          () async {
        final store = await _newStore();
        addTearDown(store.close);
        await store.admitWindow();
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        );
        final probe = P1F01DeviceValidationProbe(store);

        expect(
          await probe.retryLastAdmission(),
          P1F01OpportunityAdmissionResult.alreadyAdmitted,
        );
        expect(
          await probe.retryConflictingLastAdmission(),
          P1F01OpportunityAdmissionResult.failedClosed,
        );
        expect(
          (await store.latestSnapshot())?.status,
          P1F01IntegrityWindowStatus.leftUnclean,
        );

        await store.admitWindow();
        expect(
          await probe.admitGappedOrdinal(),
          P1F01OpportunityAdmissionResult.failedClosed,
        );
        expect(
          await probe.handleCommand('anything-else'),
          const {'status': 'unsupported_command'},
        );
      });

      test('one-shot boundaries preserve durable admission semantics',
          () async {
        final dir = await Directory.systemTemp.createTemp('p1_f01_boundary_');
        final path = '${dir.path}${Platform.pathSeparator}integrity.db';
        final store = P1F01IntegrityStore(
          databaseFactory: databaseFactoryFfi,
          databasePath: path,
        );
        final mirror = P1F01IntegrityStore(
          databaseFactory: databaseFactoryFfi,
          databasePath: path,
        );
        late final Database durableReader;
        addTearDown(() async {
          await store.close();
          await mirror.close();
          await durableReader.close();
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        final probe = P1F01DeviceValidationProbe(store);
        await store.admitWindow();
        durableReader = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            readOnly: true,
            singleInstance: false,
          ),
        );

        expect(await probe.armBeforeCommit(), isTrue);
        var beforeCommitCompleted = false;
        final beforeCommit = store
            .admitOpportunity(
              opportunityOrdinalWithinRun: 1,
              legalSetCode: _emhCode,
            )
            .whenComplete(() => beforeCommitCompleted = true);
        await _waitForBoundary(
          probe,
          P1F01TransactionBoundaryState.reachedBeforeCommit.value,
        );
        expect(beforeCommitCompleted, isFalse);
        var durableReadCompleted = false;
        final durableWindowRead =
            durableReader.query('p1_f01_integrity_window').then((rows) {
          durableReadCompleted = true;
          return rows;
        });
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(durableReadCompleted, isTrue);
        final preCommitWindow = (await durableWindowRead).single;
        expect(preCommitWindow['admitted_o_raw_count'], 0);
        expect(preCommitWindow['last_admitted_opportunity_ordinal'], isNull);
        expect(
          await durableReader.query('p1_f01_integrity_legal_set_count'),
          isEmpty,
        );
        expect(await probe.releaseBoundary(), isTrue);
        expect(await beforeCommit, P1F01OpportunityAdmissionResult.admitted);
        expect(
          (await durableReader.query('p1_f01_integrity_window'))
              .single['admitted_o_raw_count'],
          1,
        );
        expect(
          (await durableReader.query('p1_f01_integrity_legal_set_count'))
              .single['count'],
          1,
        );
        expect((await mirror.latestSnapshot())?.admittedORawCount, 1);

        // BEFORE_COMMIT reports exact window + ordinal identity.
        expect(await probe.armBeforeCommit(), isTrue);
        final identityBeforeCommit = store
            .admitOpportunity(
              opportunityOrdinalWithinRun: 3,
              legalSetCode: _emhCode,
            )
            .then((_) => fail('must block at BEFORE_COMMIT'));
        await _waitForBoundaryState(probe, (boundary) {
          if (boundary == null) return false;
          expect(boundary['state'],
              P1F01TransactionBoundaryState.reachedBeforeCommit.value);
          expect(boundary['reached'], isTrue);
          expect(boundary['armed'], isFalse);
          expect(boundary['phase'], 'BEFORE_COMMIT');
          expect(boundary['windowSequence'], 1);
          expect(boundary['opportunityOrdinal'], 3);
          return true;
        });
        // Identity remains immutable while paused.
        final identitySnapshot = await probe.readBoundaryState();
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(await probe.readBoundaryState(), identitySnapshot);
        expect(await probe.releaseBoundary(), isTrue);
        // AFTER_COMMIT_BEFORE_ACK reports exact window + ordinal identity.
        await _waitForBoundaryState(probe, (boundary) {
          if (boundary == null) return false;
          expect(boundary['phase'], 'AFTER_COMMIT_BEFORE_ACK');
          expect(boundary['windowSequence'], 1);
          expect(boundary['opportunityOrdinal'], 3);
          return true;
        });
        await probe.releaseBoundary();
        // Admission already verified; swallow any late error from the
        // intentionally abandoned future.
        unawaited(identityBeforeCommit.then<void>(
          (_) {},
          onError: (Object _) {},
        ));

        expect(await probe.armAfterCommitBeforeAck(), isTrue);
        final afterCommit = store.admitOpportunity(
          opportunityOrdinalWithinRun: 2,
          legalSetCode: _emhCode,
        );
        await _waitForBoundary(
          probe,
          P1F01TransactionBoundaryState.reachedAfterCommitBeforeAck.value,
        );
        final durable = await mirror.latestSnapshot();
        expect(durable?.admittedORawCount, 2);
        expect(durable?.legalSetCounters, {_emhCode.value: 2});
        expect(await probe.releaseBoundary(), isTrue);
        expect(await afterCommit, P1F01OpportunityAdmissionResult.admitted);
        // AFTER_COMMIT_BEFORE_ACK identity for ordinal 2 was exact.
        // (Verified via the dedicated identity test below.)

        expect(
          await store.admitOpportunity(
            opportunityOrdinalWithinRun: 2,
            legalSetCode: _emhCode,
          ),
          P1F01OpportunityAdmissionResult.alreadyAdmitted,
        );
        expect(
          await store
              .admitOpportunity(
                opportunityOrdinalWithinRun: 4,
                legalSetCode: _emhCode,
              )
              .timeout(const Duration(seconds: 1)),
          P1F01OpportunityAdmissionResult.admitted,
        );
        final disarmedBoundary = await probe.readBoundaryState();
        expect(disarmedBoundary?['state'],
            P1F01TransactionBoundaryState.disarmed.value);
        expect(disarmedBoundary?['phase'], isNull);
        expect(disarmedBoundary?['windowSequence'], isNull);
        expect(disarmedBoundary?['opportunityOrdinal'], isNull);
        expect(await probe.releaseBoundary(), isFalse);
        expect(
          await probe.handleCommand('readBoundaryState'),
          {'boundary': disarmedBoundary},
        );
      });

      test('boundary identity is exact, immutable, and not replaced by '
          'queued reconciliation', () async {
        final store = await _newStore();
        final probe = P1F01DeviceValidationProbe(store);
        await store.admitWindow();

        // BEFORE_COMMIT phase with exact window + ordinal.
        expect(await probe.armBeforeCommit(), isTrue);
        final blocked = store.admitOpportunity(
          opportunityOrdinalWithinRun: 7,
          legalSetCode: _emhCode,
        );
        await _waitForBoundaryState(probe, (b) =>
            b?['phase'] == 'BEFORE_COMMIT' &&
            b?['windowSequence'] == 1 &&
            b?['opportunityOrdinal'] == 7);
        final captured = await probe.readBoundaryState();
        expect(captured?['phase'], 'BEFORE_COMMIT');
        expect(captured?['windowSequence'], 1);
        expect(captured?['opportunityOrdinal'], 7);

        // Queued reconciliation must not overwrite the paused identity.
        unawaited(store.reconcileTerminal(
          opportunityOrdinalWithinRun: 7,
          terminalLinkAccepted: true,
        ).then<bool>(
          (_) => false,
          onError: (Object _) => false,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(await probe.readBoundaryState(), captured);

        expect(await probe.releaseBoundary(), isTrue);
        await blocked.timeout(const Duration(seconds: 1));
      });

      test('AFTER_COMMIT_BEFORE_ACK reports exact window + ordinal',
          () async {
        final store = await _newStore();
        final probe = P1F01DeviceValidationProbe(store);
        await store.admitWindow();
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        );

        expect(await probe.armAfterCommitBeforeAck(), isTrue);
        final second = store.admitOpportunity(
          opportunityOrdinalWithinRun: 2,
          legalSetCode: _emhCode,
        );
        await _waitForBoundaryState(probe, (b) =>
            b?['phase'] == 'AFTER_COMMIT_BEFORE_ACK' &&
            b?['windowSequence'] == 1 &&
            b?['opportunityOrdinal'] == 2);
        final captured = await probe.readBoundaryState();
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(await probe.readBoundaryState(), captured);
        expect(await probe.releaseBoundary(), isTrue);
        expect(await second, P1F01OpportunityAdmissionResult.admitted);
      });
    }
  });
}

Future<void> _waitForBoundary(
  P1F01DeviceValidationProbe probe,
  String expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if ((await probe.readBoundaryState())?['state'] == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Boundary state did not reach $expected.');
}

Future<void> _waitForBoundaryState(
  P1F01DeviceValidationProbe probe,
  bool Function(Map<String, Object?>? boundary) predicate,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final boundary = await probe.readBoundaryState();
    if (predicate(boundary)) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Boundary state never satisfied the expected identity.');
}

final _emhCode = P1F01LegalSetCode.fromLegality(QuestionDifficultyLegality(
  route: QuestionDifficultyRoute.playerConfigured,
  resolvedDifficulty: Difficulty.medium,
  legalDifficulties: playerConfigurableDifficultySet,
));

Future<P1F01IntegrityStore> _newStore({
  P1F01TransactionBoundaryController? boundaryController,
}) async {
  final dir = await Directory.systemTemp.createTemp('p1_f01_probe_');
  final store = P1F01IntegrityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${dir.path}${Platform.pathSeparator}integrity.db',
    boundaryController: boundaryController,
  );
  addTearDown(() async {
    await store.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return store;
}

Future<GameState> _newGameState(
  QuestionGenerator questionGenerator,
  P1F01IntegrityStore integrityStore,
) async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: true,
      reduceMotion: true,
      animSpeed: 1,
    );
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    questionGenerator: questionGenerator,
    p1F01IntegrityStore: integrityStore,
  );
  await state.load();
  addTearDown(state.dispose);
  return state;
}

Future<P1F01IntegritySnapshot?> _latestIntegrity(GameState state) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final snapshot = await state.debugP1F01IntegritySnapshot();
    if (snapshot != null) return snapshot;
    await Future<void>.delayed(Duration.zero);
  }
  return state.debugP1F01IntegritySnapshot();
}

String _questionSignature(Question question) =>
    '${question.type.name}|${question.diff?.name}|${question.numType?.name}|'
    '${question.key}|${question.text}|${question.ans}|'
    '${question.choices.join(',')}';
