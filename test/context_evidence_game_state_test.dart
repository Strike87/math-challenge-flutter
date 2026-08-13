import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/features/operation_quest/domain/operation_quest.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> makeState() async {
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
    final state = GameState(settings: settings, audio: _NoOpAudioService());
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  void startBasicRun(GameState state) {
    state
      ..rt.challenge = Operation.addition
      ..mode = GameMode.standard
      ..diff = Difficulty.easy
      ..numType = NumberType.natural
      ..questionCount = 10
      ..adaptive = false
      ..startGame();
    state.rt.timer?.cancel();
  }

  test('records once after canonical answer effects and turn bookkeeping',
      () async {
    final state = await makeState();
    startBasicRun(state);
    final question = state.rt.q!;

    state.onAnswer(question.ans);

    final evidence = state.debugLastContextEvidenceResult!;
    expect(state.debugContextEvidenceObservationCount, 1);
    expect(evidence.reasonCode, ContextEvidenceReason.insufficientExposure);
    expect(evidence.context?.operation, question.type);
    expect(evidence.context?.numberType, NumberType.natural);
    expect(evidence.correctCount, 1);
    expect(state.p[1].total, 1);
    expect(state.p[1].correct, 1);
    expect(state.p[1].score, greaterThan(0));
    expect(state.skillMap[question.type.name]!.count, 1);
    expect(state.skillMap[question.type.name]!.mastery, greaterThan(20));
    expect(state.rt.totalTurns, 1);
    expect(state.currentScreen, GameScreen.game);
  });

  test('wrong and timeout outcomes remain observable without routing effects',
      () async {
    final state = await makeState();
    startBasicRun(state);
    final firstQuestion = state.rt.q!;
    final wrongAnswer = firstQuestion.choices.firstWhere(
      (choice) => (choice - firstQuestion.ans).abs() >= 1e-9,
    );

    state.onAnswer(wrongAnswer);
    expect(state.debugLastContextEvidenceResult!.incorrectCount, 1);
    expect(state.debugLastContextEvidenceResult!.timeoutCount, 0);
    expect(state.currentScreen, GameScreen.game);

    await Future<void>.delayed(const Duration(milliseconds: 1350));
    state.rt.timer?.cancel();
    state.debugTimeoutForTest();
    expect(state.debugLastContextEvidenceResult!.incorrectCount, 2);
    expect(state.debugLastContextEvidenceResult!.timeoutCount, 1);
    expect(state.currentScreen, GameScreen.game);
  });

  test('replay preserves configuration and starts an empty observer', () async {
    final state = await makeState();
    startBasicRun(state);
    final snapshot = state.activeRunSnapshot!;
    state.onAnswer(state.rt.q!.ans);
    expect(state.debugContextEvidenceObservationCount, 1);

    await state.replayGame();
    state.rt.timer?.cancel();

    expect(state.activeRunSnapshot?.mode, snapshot.mode);
    expect(state.activeRunSnapshot?.difficulty, snapshot.difficulty);
    expect(state.activeRunSnapshot?.numberType, snapshot.numberType);
    expect(state.activeRunSnapshot?.operation, snapshot.operation);
    expect(state.activeRunSnapshot?.answerStyle, snapshot.answerStyle);
    expect(state.activeRunSnapshot?.players, snapshot.players);
    expect(state.activeRunSnapshot?.questionTarget, snapshot.questionTarget);
    expect(
      state.activeRunSnapshot?.questionMechanic,
      snapshot.questionMechanic,
    );
    expect(state.debugHasContextEvidenceObserver, isTrue);
    expect(state.debugContextEvidenceObservationCount, 0);
    expect(state.debugLastContextEvidenceResult, isNull);
  });

  test('quit and reset discard the run-local observer', () async {
    final state = await makeState();
    startBasicRun(state);
    state.onAnswer(state.rt.q!.ans);

    await state.quitToMenu();

    expect(state.debugHasContextEvidenceObserver, isFalse);
    expect(state.debugLastContextEvidenceResult, isNull);
    expect(state.currentScreen, GameScreen.menu);

    startBasicRun(state);
    state.onAnswer(state.rt.q!.ans);
    await state.resetAllData();
    expect(state.debugHasContextEvidenceObserver, isFalse);
    expect(state.debugLastContextEvidenceResult, isNull);
  });

  test('Master questions are unsupported and unrecorded', () async {
    final state = await makeState();
    state.startMasterMode();
    state.startGame();
    state.rt.timer?.cancel();
    state.onAnswer(state.rt.q!.ans);
    expect(
      state.debugLastContextEvidenceResult?.reasonCode,
      ContextEvidenceReason.unsupportedContext,
    );
    expect(state.debugContextEvidenceObservationCount, 0);
  });

  test('Daily Boss questions are unsupported and unrecorded', () async {
    final state = await makeState();
    state.startDailyBoss();
    state.startGame();
    state.rt.timer?.cancel();
    state.onAnswer(state.rt.q!.ans);
    expect(
      state.debugLastContextEvidenceResult?.reasonCode,
      ContextEvidenceReason.unsupportedContext,
    );
    expect(state.debugContextEvidenceObservationCount, 0);
  });

  test('Operation Quest questions are unsupported and discarded on return',
      () async {
    final state = await makeState();
    state.startOperationQuestStage(OperationQuestStageId.additionEasy);
    state.startGame();
    state.rt.timer?.cancel();
    state.onAnswer(state.rt.q!.ans);
    expect(
      state.debugLastContextEvidenceResult?.reasonCode,
      ContextEvidenceReason.unsupportedContext,
    );
    expect(state.debugContextEvidenceObservationCount, 0);

    await state.returnToOperationQuestMap();
    expect(state.debugHasContextEvidenceObserver, isFalse);
    expect(state.debugLastContextEvidenceResult, isNull);
  });

  test('missing-operation mechanics are unsupported and unrecorded', () async {
    final state = await makeState();
    state.goToConfig('missingOperation');
    state
      ..rt.challenge = Operation.multiplication
      ..mode = GameMode.standard
      ..numType = NumberType.natural
      ..diff = Difficulty.easy
      ..questionCount = 10
      ..startGame();
    state.rt.timer?.cancel();

    state.onAnswer(state.rt.q!.ans);

    expect(
      state.debugLastContextEvidenceResult?.reasonCode,
      ContextEvidenceReason.unsupportedContext,
    );
    expect(state.debugContextEvidenceObservationCount, 0);
  });

  test('True/False basic-operation runs are unsupported and unrecorded',
      () async {
    final state = await makeState();
    state.selectedAnswerStyle = AnswerStyle.trueFalse;
    startBasicRun(state);

    expect(state.activeRunSnapshot?.answerStyle, AnswerStyle.trueFalse);
    final proposedTruth = state.rt.proposedTruth!;
    state.onTrueFalseAnswer(proposedTruth);

    expect(
      state.debugLastContextEvidenceResult?.reasonCode,
      ContextEvidenceReason.unsupportedContext,
    );
    expect(state.debugContextEvidenceObservationCount, 0);
    expect(state.p[1].total, 1);
    expect(state.p[1].correct, 1);
    expect(state.rt.totalTurns, 1);
    expect(state.currentScreen, GameScreen.game);
  });

  test('Weak Skills plan and adaptive state remain on canonical paths',
      () async {
    final state = await makeState();
    state.goToConfig('weakSkills');
    state.continueWeakSkillsSetup();
    state
      ..mode = GameMode.standard
      ..numType = NumberType.natural
      ..diff = Difficulty.easy
      ..questionCount = 10
      ..adaptive = true
      ..startGame();
    state.rt.timer?.cancel();
    final plan = state.activeRunSnapshot!.weakSkillsPlan;
    final question = state.rt.q!;

    state.onAnswer(question.ans);

    expect(state.activeRunSnapshot?.weakSkillsPlan, same(plan));
    expect(state.skillMap[question.type.name]!.count, 1);
    expect(state.adaptLvlRaw, greaterThan(0));
    expect(state.debugContextEvidenceObservationCount, 1);
  });
}

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
