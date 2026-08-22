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
    }
  });
}

final _emhCode = P1F01LegalSetCode.fromLegality(QuestionDifficultyLegality(
  route: QuestionDifficultyRoute.playerConfigured,
  resolvedDifficulty: Difficulty.medium,
  legalDifficulties: playerConfigurableDifficultySet,
));

Future<P1F01IntegrityStore> _newStore() async {
  final dir = await Directory.systemTemp.createTemp('p1_f01_probe_');
  final store = P1F01IntegrityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${dir.path}${Platform.pathSeparator}integrity.db',
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
