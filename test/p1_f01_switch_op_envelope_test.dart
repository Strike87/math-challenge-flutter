import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/experience/p1_f01_integrity_store.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  // Plain async tests run on the real Dart event loop, so filesystem,
  // SQLite FFI, store serialization, and GameState admissions all execute
  // normally without FakeAsync.
  Future<GameState> makeState({P1F01IntegrityStore? integrityStore}) async {
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
      questionGenerator: QuestionGenerator(rng: Random(1408)),
      p1F01IntegrityStore: integrityStore ?? await _newStore(),
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  Future<void> startSupported(GameState state) async {
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

  void startUnsupported(GameState state) {
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();
  }

  test('switchOp in a supported run disables admission before the '
      'replacement question opens and gameplay proceeds unchanged',
      () async {
    final state = await makeState();
    await startSupported(state);

    // Supported run admitted a window and its first opportunity.
    var snapshot = await _drainedSnapshot(state);
    expect(snapshot?.status, P1F01IntegrityWindowStatus.open);
    expect(snapshot?.admittedORawCount, 1);
    expect(snapshot?.lastAdmittedOpportunityOrdinal, 1);
    final preSwitchQuestion = state.rt.q!;
    final preSwitchTurns = state.rt.totalTurns;

    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);

    // The local firewall is synchronous: eligibility is already gone before
    // any replacement generation timer can fire.
    expect(state.debugP1F01IntegrityRunEligible, isFalse);

    // Real wait matching the production 500 ms switchOp replacement timer.
    await Future<void>.delayed(_switchOpReplacementDelay + _transitionSlack);
    expect(state.rt.q, isNot(same(preSwitchQuestion)));
    expect(state.rt.accepting, isTrue);
    expect(state.rt.totalTurns, preSwitchTurns);
    state.rt.timer?.cancel();

    // Durable bookkeeping is queued asynchronously; it must be LEFT_UNCLEAN.
    snapshot = await _drainedSnapshot(state);
    expect(snapshot?.status, P1F01IntegrityWindowStatus.leftUnclean);
    // Accounting is frozen at the pre-switch admissions.
    expect(snapshot?.admittedORawCount, 1);
    expect(snapshot?.lastAdmittedOpportunityOrdinal, 1);
  });

  test('the replacement-generated question records no P1-F01 admission',
      () async {
    final state = await makeState();
    await startSupported(state);
    final beforeCount =
        state.debugQuestionDifficultyMeasurementOpportunities.length;

    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);
    await Future<void>.delayed(_switchOpReplacementDelay + _transitionSlack);
    state.rt.timer?.cancel();

    // A new canonical question opened...
    expect(state.debugQuestionDifficultyMeasurementOpportunities.length,
        beforeCount + 1);
    // ...but durable accounting did not move.
    final snapshot = await _drainedSnapshot(state);
    expect(snapshot?.admittedORawCount, 1);
    expect(snapshot?.lastAdmittedOpportunityOrdinal, 1);
    expect(snapshot?.legalSetCounters.values.single, 1);
  });

  test('later questions in the same run stay admission-disabled', () async {
    final state = await makeState();
    await startSupported(state);

    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);
    await Future<void>.delayed(_switchOpReplacementDelay + _transitionSlack);
    state.rt.timer?.cancel();

    // Answering schedules the next turn via the production 1300 ms
    // _scheduleNextTurn feedback delay.
    state.onAnswer(state.rt.q!.ans);
    await Future<void>.delayed(_nextTurnDelay + _transitionSlack);
    state.rt.timer?.cancel();

    // The next canonical question also produced no admission.
    final snapshot = await _drainedSnapshot(state);
    expect(snapshot?.status, P1F01IntegrityWindowStatus.leftUnclean);
    expect(snapshot?.admittedORawCount, 1);
    expect(snapshot?.lastAdmittedOpportunityOrdinal, 1);
  });

  test('gameplay does not await the durable bookkeeping', () async {
    final state = await makeState();
    await startSupported(state);

    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);

    // Zero drain before this point: the replacement still proceeds on its
    // normal production timer with no SQLite dependency in the gameplay path.
    await Future<void>.delayed(_switchOpReplacementDelay + _transitionSlack);
    state.rt.timer?.cancel();
    expect(state.rt.accepting, isTrue);
    expect(state.rt.q, isNotNull);
  });

  test('normal non-switchOp supported runs are unchanged', () async {
    final state = await makeState();
    await startSupported(state);

    state.onAnswer(state.rt.q!.ans);
    // Production 1300 ms _scheduleNextTurn feedback delay.
    await Future<void>.delayed(_nextTurnDelay + _transitionSlack);
    state.rt.timer?.cancel();

    final snapshot = await _drainedSnapshot(state);
    expect(snapshot?.status, P1F01IntegrityWindowStatus.open);
    expect(snapshot?.admittedORawCount, 2);
    expect(snapshot?.lastAdmittedOpportunityOrdinal, 2);
  });

  test('non-P1-F01 runs are unchanged by switchOp', () async {
    final state = await makeState();
    startUnsupported(state);
    // GameBrain preference off -> run never eligible; no window exists.
    expect(await state.debugP1F01IntegritySnapshot(), isNull);

    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);
    await Future<void>.delayed(_switchOpReplacementDelay + _transitionSlack);
    state.rt.timer?.cancel();

    expect(state.rt.q, isNotNull);
    expect(state.rt.accepting, isTrue);
    expect(await state.debugP1F01IntegritySnapshot(), isNull);
  });

  test('mayAffectGameplay remains false: switchOp consumption and turn '
      'accounting are untouched by the integrity firewall', () async {
    final state = await makeState();
    await startSupported(state);
    final turnsBefore = state.rt.totalTurns;
    final scoreBefore = state.p[1].score;

    // Add the power-up first, THEN capture the pre-use state.
    state.p[1].pups.add(PowerUp.switchOp);
    final switchOpCountBefore =
        state.p[1].pups.where((p) => p == PowerUp.switchOp).length;
    final pupsCountBefore = state.p[1].pups.length;

    expect(switchOpCountBefore, greaterThan(0));

    state.usePowerUp(PowerUp.switchOp);

    // Exactly one switchOp unit consumed; no turn consumed; score untouched
    // by the firewall itself.
    final switchOpCountAfter =
        state.p[1].pups.where((p) => p == PowerUp.switchOp).length;
    expect(switchOpCountAfter, switchOpCountBefore - 1);
    expect(state.p[1].pups.length, pupsCountBefore - 1);
    expect(state.rt.totalTurns, turnsBefore);
    expect(state.p[1].score, scoreBefore);

    // Let the scheduled replacement transition complete on its production
    // 500 ms timer, then stop the newly generated question's periodic timer
    // so no pending gameplay timer outlives the test.
    await Future<void>.delayed(_switchOpReplacementDelay + _transitionSlack);
    state.rt.timer?.cancel();
  });
}

/// Reads the latest durable snapshot via the integrity store's queue
/// barrier. `latestSnapshot()` already awaits the store's explicit
/// `debugDrain()`, so a single barrier-backed read suffices.
Future<P1F01IntegritySnapshot?> _drainedSnapshot(GameState state) {
  return state.debugP1F01IntegritySnapshot();
}

Future<P1F01IntegrityStore> _newStore() async {
  final dir = await Directory.systemTemp.createTemp('p1_f01_switch_op_');
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

class _NoOpAudioService implements AudioService {
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

/// Production transition delays (verified in lib/engine/game_state.dart):
/// - switchOp replacement: `Timer(const Duration(milliseconds: 500), ...)`
///   scheduled synchronously by usePowerUp(switchOp).
/// - normal answer progression: `_scheduleNextTurn()` uses `const delay = 1300`.
const _switchOpReplacementDelay = Duration(milliseconds: 500);
const _nextTurnDelay = Duration(milliseconds: 1300);

/// Small slack so a real-event-loop Timer scheduled at exactly the production
/// delay reliably fires before the wait ends.
const _transitionSlack = Duration(milliseconds: 20);
