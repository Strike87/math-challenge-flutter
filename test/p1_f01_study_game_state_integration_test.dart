import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_coordinator.dart';
import 'package:math_challenge/features/game_brain/study/p1_f01_study_store.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => null,
    );
  });

  test('G1-C - missing Integrity history leaves canonical gameplay available',
      () async {
    final initial = await _GameHarness.create();
    addTearDown(initial.dispose);
    initial.start(questionCount: 2);
    await initial.coordinator.drain();

    initial.state.dispose();
    await initial.coordinator.close();
    await initial.study.close();
    await initial.integrity.close();
    await _deleteIntegrityWindow(initial.studyPath, 1);

    final recovered = await _GameHarness.create(directory: initial.directory);
    addTearDown(recovered.dispose);
    recovered.start(questionCount: 2);

    expect(recovered.state.rt.gameActive, isTrue);
    expect(recovered.state.debugP1F01IntegrityRunEligible, isTrue);
    expect(
      await recovered.study.debugRowCount(P1F01StudyStore.windowOpenTable),
      0,
    );
  });

  test('A - a newer canonical run cannot cross-mutate a finalizing window',
      () async {
    final harness = await _GameHarness.create();
    addTearDown(harness.dispose);
    harness.start(questionCount: 1);

    var newerRunStarted = false;
    harness.state.addListener(() {
      if (newerRunStarted || harness.state.rt.state != 'ended') return;
      newerRunStarted = true;
      harness.start(questionCount: 10);
    });
    harness.answerWrong();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await harness.coordinator.drain();

    expect(newerRunStarted, isTrue);
    expect(harness.state.rt.gameActive, isTrue);
    expect(harness.state.debugP1F01IntegrityRunEligible, isFalse);
    expect(
        await harness.study.debugRowCount(P1F01StudyStore.windowOpenTable), 1);
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
        await harness.study.debugRowCount(P1F01StudyStore.windowFinalTable), 1);
    expect(
      (await harness.integrity.snapshotBySequence(1))?.status,
      P1F01IntegrityWindowStatus.cleanlyClosed,
    );
  });

  test('H - a final canonical wrong answer reconciles and closes cleanly',
      () async {
    final harness = await _GameHarness.create();
    addTearDown(harness.dispose);
    harness.start(questionCount: 1);

    harness.answerWrong();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await harness.coordinator.drain();

    expect(harness.state.rt.state, 'ended');
    expect(
      await harness.study
          .debugRowCount(P1F01StudyStore.opportunityTerminalTable),
      1,
    );
    final finalRow = await harness.singleRow(P1F01StudyStore.windowFinalTable);
    expect(finalRow['non_clean_cause'], P1StudyNonCleanCause.none.storageValue);
    expect(
      finalRow['study_disposition'],
      P1StudyWindowDisposition.cleanEligible.storageValue,
    );
    expect(
      finalRow['measurement_defect'],
      P1StudyMeasurementDefect.none.storageValue,
    );
  });

  test('I - a non-final wrong answer reconciles but excludes its follow-up',
      () async {
    final harness = await _GameHarness.create();
    addTearDown(harness.dispose);
    harness.start(questionCount: 2);

    harness.answerWrong();
    expect(harness.coordinator.futureOpportunityAdmissionEnabled, isFalse);
    await harness.coordinator.drain();
    expect(
      await harness.study
          .debugRowCount(P1F01StudyStore.opportunityTerminalTable),
      1,
    );

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    expect(harness.state.rt.isFollowUp, isFalse);
    expect(
      await harness.study.debugRowCount(P1F01StudyStore.opportunityOpenTable),
      1,
    );
    harness.state.onAnswer(harness.state.rt.q!.ans);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await harness.coordinator.drain();

    expect(
      await harness.study
          .debugRowCount(P1F01StudyStore.opportunityTerminalTable),
      1,
    );
    final finalRow = await harness.singleRow(P1F01StudyStore.windowFinalTable);
    expect(
      finalRow['non_clean_cause'],
      P1StudyNonCleanCause.followUpEnvelopeExit.storageValue,
    );
    expect(
      finalRow['study_disposition'],
      P1StudyWindowDisposition.nonCleanCensored.storageValue,
    );
    expect(
      finalRow['measurement_defect'],
      P1StudyMeasurementDefect.none.storageValue,
    );
    expect(finalRow['last_reconciled_ordinal'], 1);
    expect(
      finalRow['final_integrity_status'],
      P1F01IntegrityWindowStatus.leftUnclean.storageValue,
    );
  });
}

final class _GameHarness {
  _GameHarness({
    required this.state,
    required this.coordinator,
    required this.integrity,
    required this.study,
    required this.directory,
    required this.studyPath,
  });

  final GameState state;
  final P1F01StudyCoordinator coordinator;
  final P1F01IntegrityStore integrity;
  final P1F01StudyStore study;
  final Directory directory;
  final String studyPath;

  static Future<_GameHarness> create({Directory? directory}) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final gameDirectory =
        directory ?? await Directory.systemTemp.createTemp('p1_game_state_');
    final integrity = P1F01IntegrityStore(
      databaseFactory: databaseFactoryFfi,
      databasePath:
          '${gameDirectory.path}${Platform.pathSeparator}integrity.db',
    );
    final studyPath = '${gameDirectory.path}${Platform.pathSeparator}study.db';
    final study = P1F01StudyStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: studyPath,
    );
    var journal = P1StudyResetJournal.clear.name;
    final coordinator = P1F01StudyCoordinator.test(
      integrityStore: integrity,
      studyStore: study,
      resetJournal: P1StudyResetJournalStore(
        read: () => journal,
        write: (value) async => journal = value,
      ),
    );
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
      p1F01IntegrityStore: integrity,
      p1F01StudyCoordinator: coordinator,
    );
    await state.load();
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    return _GameHarness(
      state: state,
      coordinator: coordinator,
      integrity: integrity,
      study: study,
      directory: gameDirectory,
      studyPath: studyPath,
    );
  }

  void start({required int questionCount}) {
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..players = 1
      ..questionCount = questionCount
      ..adaptive = false
      ..selectedAnswerStyle = AnswerStyle.choice4
      ..startGame();
    state.rt.timer?.cancel();
  }

  void answerWrong() => state.onAnswer(
        state.rt.q!.choices.firstWhere((choice) => choice != state.rt.q!.ans),
      );

  Future<Map<String, Object?>> singleRow(String table) async {
    final db = await databaseFactoryFfi.openDatabase(studyPath);
    try {
      return (await db.query(table)).single;
    } finally {
      await db.close();
    }
  }

  Future<void> dispose() async {
    state.dispose();
    await coordinator.drain();
    await study.close();
    await integrity.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

Future<void> _deleteIntegrityWindow(String studyPath, int sequence) async {
  final database = await databaseFactoryFfi.openDatabase(
    '${File(studyPath).parent.path}${Platform.pathSeparator}integrity.db',
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
