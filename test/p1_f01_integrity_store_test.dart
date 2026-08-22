import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/features/gameplay/domain/question_difficulty_legality.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(sqfliteFfiInit);

  group('P1F01IntegrityStore', () {
    test('initializes only the authorized local integrity schema', () async {
      final store = await _newStore();
      addTearDown(store.close);

      final window = await store.admitWindow();
      expect(window?.localWindowSequence, 1);
      expect(window?.status, P1F01IntegrityWindowStatus.open);

      final windowColumns = await store.debugColumnNames(
        'p1_f01_integrity_window',
      );
      final counterColumns = await store.debugColumnNames(
        'p1_f01_integrity_legal_set_count',
      );
      expect(windowColumns, contains('integrity_version'));
      expect(windowColumns, contains('local_window_sequence'));
      expect(windowColumns, contains('admitted_o_raw_count'));
      expect(windowColumns, contains('last_admitted_opportunity_ordinal'));
      expect(windowColumns, contains('last_legal_set_code'));
      expect(
          counterColumns, ['local_window_sequence', 'legal_set_code', 'count']);
      final serializedColumns =
          [...windowColumns, ...counterColumns].join('|').toLowerCase();
      for (final prohibited in [
        'qeo',
        'question_id',
        'answer',
        'timestamp',
        'player',
        'age',
        'score',
        'telemetry',
        'identity',
      ]) {
        expect(serializedColumns, isNot(contains(prohibited)));
      }
    });

    test('detects an OPEN window after reopen and preserves LEFT_UNCLEAN',
        () async {
      final path = await _tempDbPath();
      final first = _store(path);
      final admitted = await first.admitWindow();
      expect(admitted?.status, P1F01IntegrityWindowStatus.open);
      await first.close();

      final reopened = _store(path);
      addTearDown(reopened.close);
      expect(
        (await reopened.latestSnapshot())?.status,
        P1F01IntegrityWindowStatus.open,
      );
      await reopened.recoverOpenWindows();
      expect(
        (await reopened.latestSnapshot())?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );
      await reopened.recoverOpenWindows();
      expect(
        (await reopened.latestSnapshot())?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );

      final next = await reopened.admitWindow();
      expect(next?.localWindowSequence, 2);
      final all = await reopened.debugSnapshots();
      expect(all.first.status, P1F01IntegrityWindowStatus.leftUnclean);
      expect(all.last.status, P1F01IntegrityWindowStatus.open);
    });

    test('clean close remains clean across reopen', () async {
      final path = await _tempDbPath();
      final first = _store(path);
      await first.admitWindow();
      expect(await first.closeCleanIfConsistent(), isTrue);
      await first.close();

      final reopened = _store(path);
      addTearDown(reopened.close);
      await reopened.recoverOpenWindows();
      final snapshot = await reopened.latestSnapshot();
      expect(snapshot?.status, P1F01IntegrityWindowStatus.cleanlyClosed);
      expect(snapshot?.hasCleanClosureSignal, isTrue);
    });

    test('O_raw is monotonic and terminal reconciliation does not decrement it',
        () async {
      final store = await _newStore();
      addTearDown(store.close);
      await store.admitWindow();

      expect(
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.admitted,
      );
      expect((await store.latestSnapshot())?.admittedORawCount, 1);
      expect(
        await store.reconcileTerminal(
          opportunityOrdinalWithinRun: 1,
          terminalLinkAccepted: true,
        ),
        isTrue,
      );
      expect((await store.latestSnapshot())?.admittedORawCount, 1);

      await store.admitOpportunity(
        opportunityOrdinalWithinRun: 2,
        legalSetCode: _emhCode,
      );
      final snapshot = await store.latestSnapshot();
      expect(snapshot?.admittedORawCount, 2);
      expect(snapshot?.legalSetCounters, {_emhCode.value: 2});
    });

    test('duplicate ordinal retry is exact after committed write and reopen',
        () async {
      final path = await _tempDbPath();
      final first = _store(path);
      await first.admitWindow();
      await first.admitOpportunity(
        opportunityOrdinalWithinRun: 1,
        legalSetCode: _emhCode,
      );
      await first.close();

      final reopened = _store(path);
      addTearDown(reopened.close);
      expect(
        await reopened.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.alreadyAdmitted,
      );
      final snapshot = await reopened.latestSnapshot();
      expect(snapshot?.admittedORawCount, 1);
      expect(snapshot?.legalSetCounters, {_emhCode.value: 1});
    });

    test('contradictory duplicate and gap fail closed without amplification',
        () async {
      final store = await _newStore();
      addTearDown(store.close);
      await store.admitWindow();
      await store.admitOpportunity(
        opportunityOrdinalWithinRun: 1,
        legalSetCode: _emhCode,
      );

      expect(
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: P1F01LegalSetCode.unknown,
        ),
        P1F01OpportunityAdmissionResult.failedClosed,
      );
      final conflict = await store.latestSnapshot();
      expect(conflict?.status, P1F01IntegrityWindowStatus.leftUnclean);
      expect(conflict?.admittedORawCount, 1);
      expect(conflict?.legalSetCounters, {_emhCode.value: 1});

      await store.admitWindow();
      expect(
        await store.admitOpportunity(
          opportunityOrdinalWithinRun: 2,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.failedClosed,
      );
      expect(
        (await store.latestSnapshot())?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );
    });

    test('failed opportunity and close transactions cannot fake clean history',
        () async {
      final path = await _tempDbPath();
      var failOpportunity = true;
      final first = _store(
        path,
        failureHook: (operation) {
          if (failOpportunity &&
              operation == P1F01IntegrityOperation.admitOpportunity) {
            throw Exception('injected opportunity failure');
          }
        },
      );
      await first.admitWindow();
      expect(
        await first.admitOpportunity(
          opportunityOrdinalWithinRun: 1,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.failedClosed,
      );
      failOpportunity = false;
      expect(
        await first.admitOpportunity(
          opportunityOrdinalWithinRun: 2,
          legalSetCode: _emhCode,
        ),
        P1F01OpportunityAdmissionResult.failedClosed,
      );
      await first.close();

      final reopened = _store(path);
      addTearDown(reopened.close);
      await reopened.recoverOpenWindows();
      expect(
        (await reopened.latestSnapshot())?.status,
        P1F01IntegrityWindowStatus.leftUnclean,
      );

      final closeFailure = await _newStore(
        failureHook: (operation) {
          if (operation == P1F01IntegrityOperation.closeClean) {
            throw Exception('injected close failure');
          }
        },
      );
      addTearDown(closeFailure.close);
      await closeFailure.admitWindow();
      expect(await closeFailure.closeCleanIfConsistent(), isFalse);
      expect(
        (await closeFailure.latestSnapshot())?.status,
        P1F01IntegrityWindowStatus.open,
      );

      final admissionFailure = await _newStore(
        failureHook: (operation) {
          if (operation == P1F01IntegrityOperation.admitWindow) {
            throw Exception('injected window admission failure');
          }
        },
      );
      addTearDown(admissionFailure.close);
      expect(await admissionFailure.admitWindow(), isNull);
      expect(await admissionFailure.latestSnapshot(), isNull);
    });

    test('deleteAll removes resettable local integrity state', () async {
      final store = await _newStore();
      addTearDown(store.close);
      await store.admitWindow();
      await store.admitOpportunity(
        opportunityOrdinalWithinRun: 1,
        legalSetCode: _emhCode,
      );
      expect(await store.deleteAll(), isTrue);
      expect(await store.latestSnapshot(), isNull);
      expect(await store.debugSnapshots(), isEmpty);
    });

    test('legal-set encoding preserves exact Phase-1 membership or UNKNOWN',
        () {
      expect(
        P1F01LegalSetCode.fromLegality(QuestionDifficultyLegality(
          route: QuestionDifficultyRoute.playerConfigured,
          resolvedDifficulty: Difficulty.medium,
          legalDifficulties: playerConfigurableDifficultySet,
        )),
        _emhCode,
      );
      expect(
        P1F01LegalSetCode.fromLegality(QuestionDifficultyLegality(
          route: QuestionDifficultyRoute.adaptive,
          resolvedDifficulty: Difficulty.insane,
          legalDifficulties: adaptiveDifficultySet,
        )),
        P1F01LegalSetCode.unknown,
      );
    });
  });

  group('GameState P1-F01 integration', () {
    test('load recovers previous OPEN before any later admission', () async {
      final path = await _tempDbPath();
      final original = _store(path);
      await original.admitWindow();
      await original.close();

      final reopenedStore = _store(path);
      await _makeState(integrityStore: reopenedStore);

      final snapshot = await _latestMatching(
        reopenedStore,
        P1F01IntegrityWindowStatus.leftUnclean,
      );
      expect(snapshot?.status, P1F01IntegrityWindowStatus.leftUnclean);
      expect(snapshot?.localWindowSequence, 1);
    });

    test('new admission recovers previous OPEN before admitting another window',
        () async {
      final path = await _tempDbPath();
      final original = _store(path);
      await original.admitWindow();
      await original.close();

      final reopenedStore = _store(path);
      final recoveredState = await _makeState(
        integrityStore: reopenedStore,
      );
      await recoveredState.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
      await recoveredState.setGameBrainPreference(true);
      _startSupported(recoveredState);

      final snapshots = await reopenedStore.debugSnapshots();
      expect(snapshots.first.status, P1F01IntegrityWindowStatus.leftUnclean);
      expect(snapshots.first.localWindowSequence, 1);
      expect(snapshots.last.status, P1F01IntegrityWindowStatus.open);
      expect(snapshots.last.localWindowSequence, 2);
    });

    test('storage failure leaves canonical gameplay, BRAIN-07, and QEO intact',
        () async {
      final off = await _makeState(
        questionGenerator: QuestionGenerator(rng: Random(1408)),
      );
      final on = await _makeState(
        questionGenerator: QuestionGenerator(rng: Random(1408)),
        integrityStore: await _newStore(
          failureHook: (_) => throw Exception('injected storage failure'),
        ),
      );
      await on.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
      await on.setGameBrainPreference(true);

      _startSupported(off);
      _startSupported(on);
      expect(_questionSignature(on.rt.q!), _questionSignature(off.rt.q!));
      expect(
        on.debugQuestionTimerDurationMs(),
        off.debugQuestionTimerDurationMs(),
      );

      off.onAnswer(off.rt.q!.ans);
      on.onAnswer(on.rt.q!.ans);
      expect(on.p[1].score, off.p[1].score);
      expect(on.rt.totalTurns, off.rt.totalTurns);
      expect(on.adaptLvl, off.adaptLvl);
      expect(on.debugContextEvidenceObservationCount, 1);
      expect(off.debugContextEvidenceObservationCount, 1);
      expect(on.debugQuestionExperienceObservationCount, 1);
      expect(await on.debugP1F01IntegritySnapshot(), isNull);
    });

    test('Clear GameBrain Data and reset delete local integrity rows',
        () async {
      final clearState = await _makeState(
        integrityStore: await _newStore(),
      );
      await clearState.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
      await clearState.setGameBrainPreference(true);
      _startSupported(clearState);
      clearState.onAnswer(clearState.rt.q!.ans);
      expect(await clearState.debugP1F01IntegritySnapshot(), isNotNull);
      expect(await clearState.clearGameBrainData(), isTrue);
      expect(await clearState.debugP1F01IntegritySnapshot(), isNull);

      final resetState = await _makeState(
        integrityStore: await _newStore(),
      );
      await resetState.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
      await resetState.setGameBrainPreference(true);
      _startSupported(resetState);
      resetState.onAnswer(resetState.rt.q!.ans);
      expect(await resetState.debugP1F01IntegritySnapshot(), isNotNull);
      await resetState.resetAllData();
      expect(await resetState.debugP1F01IntegritySnapshot(), isNull);
    });
  });
}

final _emhCode = P1F01LegalSetCode.fromLegality(QuestionDifficultyLegality(
  route: QuestionDifficultyRoute.playerConfigured,
  resolvedDifficulty: Difficulty.medium,
  legalDifficulties: playerConfigurableDifficultySet,
));

Future<P1F01IntegrityStore> _newStore({
  void Function(P1F01IntegrityOperation operation)? failureHook,
}) async =>
    _store(await _tempDbPath(), failureHook: failureHook);

P1F01IntegrityStore _store(
  String path, {
  void Function(P1F01IntegrityOperation operation)? failureHook,
}) {
  final store = P1F01IntegrityStore(
    databaseFactory: databaseFactoryFfi,
    databasePath: path,
    failureHook: failureHook,
  );
  addTearDown(() async {
    await store.close();
    final dir = File(path).parent;
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return store;
}

Future<P1F01IntegritySnapshot?> _latestMatching(
  P1F01IntegrityStore store,
  P1F01IntegrityWindowStatus status,
) async {
  for (var i = 0; i < 10; i++) {
    final snapshot = await store.latestSnapshot();
    if (snapshot?.status == status) return snapshot;
    await Future<void>.delayed(Duration.zero);
  }
  return store.latestSnapshot();
}

Future<String> _tempDbPath() async {
  final dir = await Directory.systemTemp.createTemp('p1_f01_integrity_');
  return '${dir.path}${Platform.pathSeparator}integrity.db';
}

Future<GameState> _makeState({
  QuestionGenerator? questionGenerator,
  P1F01IntegrityStore? integrityStore,
}) async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  final state = GameState(
    settings: SettingsService()
      ..load(
        dark: false,
        sound: false,
        vibration: false,
        dyslexia: false,
        colorblind: false,
        lowPerf: true,
        reduceMotion: true,
        animSpeed: 1,
      ),
    audio: _NoOpAudioService(),
    questionGenerator: questionGenerator,
    p1F01IntegrityStore: integrityStore,
  );
  await state.load();
  addTearDown(state.dispose);
  return state;
}

void _startSupported(GameState state) {
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

String _questionSignature(Question question) =>
    '${question.type.name}|${question.diff?.name}|${question.numType?.name}|'
    '${question.key}|${question.text}|${question.ans}|'
    '${question.choices.join(',')}';

final class _NoOpAudioService implements AudioService {
  @override
  int get debugTonePlayCount => 0;

  @override
  int get debugVibrationCount => 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> playCorrect() async {}

  @override
  Future<void> playPowerUp() async {}

  @override
  Future<void> playStart() async {}

  @override
  Future<void> playTones(List<List<double>> tones) async {}

  @override
  Future<void> playWrong() async {}

  @override
  void vibrate(int ms) {}

  @override
  void vibrateCorrect() {}

  @override
  void vibratePattern(List<int> pattern) {}

  @override
  void vibratePowerUp() {}

  @override
  void vibrateWrong() {}
}
