import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/game_brain/integration/adaptive_shadow_integration.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/screens/practice_style_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> makeState({
    AdaptiveShadowEvaluator? adaptiveShadowEvaluator,
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
      questionGenerator: QuestionGenerator(rng: Random(1001)),
      adaptiveShadowEvaluator: adaptiveShadowEvaluator,
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  Future<void> startFreePractice(
    GameState state, {
    Operation operation = Operation.mixed,
    bool missingOperation = false,
    Difficulty difficulty = Difficulty.easy,
    int questions = 10,
    AnswerStyle answerStyle = AnswerStyle.choice4,
    bool mentalMath = true,
  }) async {
    state.goToPracticeStyle(
      missingOperation ? 'missingOperation' : operation.name,
    );
    if (mentalMath) {
      state.startMentalMathFreePractice();
    } else {
      state.startTimingPractice();
    }
    await state.selectNumType(NumberType.natural.name);
    state
      ..diff = difficulty
      ..questionCount = questions
      ..selectedAnswerStyle = answerStyle;
    state.startGame();
    state.rt.timer?.cancel();
  }

  Future<void> pump(
    WidgetTester tester,
    GameState state,
    Widget child,
  ) =>
      tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameState>.value(value: state),
            ChangeNotifierProvider<SettingsService>.value(
                value: state.settings),
          ],
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );

  bool enabled(WidgetTester tester, String label) {
    final finder = find.ancestor(
      of: find.text(label, skipOffstage: false),
      matching: find.byType(InkWell),
    );
    expect(finder, findsOneWidget);
    return tester.widget<InkWell>(finder).onTap != null;
  }

  testWidgets('existing operation cards lead through Practice Style',
      (tester) async {
    final state = await makeState();
    await pump(tester, state, const MenuScreen());

    expect(find.text('Mental Math'), findsNothing);
    await tester.ensureVisible(find.text('Addition'));
    await tester.tap(find.text('Addition'));
    await tester.pump();
    expect(state.currentScreen, GameScreen.practiceStyle);
    expect(state.setupMentalMathEntry, isNull);
    await pump(tester, state, const PracticeStyleScreen());
    expect(find.byKey(const Key('mental-math-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mental-math-button')));
    await tester.pump();
    expect(state.currentScreen, GameScreen.numType);
    expect(state.setupMentalMathEntry, MentalMathEntry.freePractice);

    await state.selectNumType(NumberType.natural.name);
    state.goToPlayerSetup();
    expect(state.currentScreen, GameScreen.player);
    state.startGame();
    state.rt.timer?.cancel();

    final snapshot = state.activeRunSnapshot!;
    expect(snapshot.mentalMathEntry, MentalMathEntry.freePractice);
    expect(snapshot.runType, GameRunType.normal);
    expect(snapshot.mode, GameMode.standard);
    expect(snapshot.questionMechanic.name, 'standard');
    expect(snapshot.timingStyle, TimingStyle.perQuestion);
  });

  test('all canonical operations and both styles preserve their context',
      () async {
    for (final option in const [
      (operation: Operation.addition, missingOperation: false),
      (operation: Operation.subtraction, missingOperation: false),
      (operation: Operation.multiplication, missingOperation: false),
      (operation: Operation.division, missingOperation: false),
      (operation: Operation.mixed, missingOperation: false),
      (operation: Operation.mixed, missingOperation: true),
    ]) {
      for (final mentalMath in [false, true]) {
        final state = await makeState();
        await startFreePractice(
          state,
          operation: option.operation,
          missingOperation: option.missingOperation,
          difficulty: Difficulty.hard,
          questions: 25,
          answerStyle: option.missingOperation
              ? AnswerStyle.trueFalse
              : AnswerStyle.choice4,
          mentalMath: mentalMath,
        );
        final snapshot = state.activeRunSnapshot!;
        expect(snapshot.operation, option.operation);
        expect(snapshot.questionMechanic.name,
            option.missingOperation ? 'missingOperation' : 'standard');
        expect(snapshot.difficulty, Difficulty.hard);
        expect(snapshot.questionTarget, 25);
        expect(snapshot.mentalMathEntry,
            mentalMath ? MentalMathEntry.freePractice : isNull);
        expect(
            snapshot.answerStyle,
            option.missingOperation
                ? AnswerStyle.choice4
                : AnswerStyle.choice4);

        await state.replayGame();
        state.rt.timer?.cancel();
        expect(state.activeRunSnapshot?.mentalMathEntry,
            mentalMath ? MentalMathEntry.freePractice : isNull);
        expect(state.activeRunSnapshot?.questionMechanic.name,
            option.missingOperation ? 'missingOperation' : 'standard');
      }
    }
  });

  test('Mental Math supports all fixed difficulties, counts, and answer styles',
      () async {
    for (final difficulty in const [
      Difficulty.easy,
      Difficulty.medium,
      Difficulty.hard,
    ]) {
      for (final questions in const [10, 15, 20, 25]) {
        for (final answerStyle in AnswerStyle.values) {
          final state = await makeState();
          await startFreePractice(
            state,
            operation: Operation.addition,
            difficulty: difficulty,
            questions: questions,
            answerStyle: answerStyle,
          );
          expect(state.activeRunSnapshot?.difficulty, difficulty);
          expect(state.activeRunSnapshot?.questionTarget, questions);
          expect(state.activeRunSnapshot?.answerStyle, answerStyle);
        }
      }
    }
  });

  test('unsupported manipulated Mental Math setup fails closed', () async {
    for (final configure in <void Function(GameState)>[
      (state) => state.players = 2,
      (state) => state.adaptive = true,
      (state) => state.timingStyle = TimingStyle.untimed,
      (state) => state.timingStyle = TimingStyle.timeBank,
    ]) {
      final state = await makeState();
      state.goToPracticeStyle('addition');
      state.startMentalMathFreePractice();
      await state.selectNumType(NumberType.natural.name);
      configure(state);
      state.startGame();
      expect(state.currentScreen, isNot(GameScreen.game));
      expect(state.activeRunSnapshot, isNull);
    }
  });

  testWidgets('unsupported Config choices remain visible but disabled',
      (tester) async {
    final state = await makeState();
    state.goToPracticeStyle('addition');
    state.startMentalMathFreePractice();
    await state.selectNumType(NumberType.natural.name);
    await pump(tester, state, const ConfigScreen());

    expect(enabled(tester, '1 Player'), isTrue);
    expect(enabled(tester, '2 Players'), isFalse);
    expect(enabled(tester, 'Deep Thinking'), isFalse);
    expect(enabled(tester, 'Time Bank'), isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  test(
      'Mental Math is evidence-excluded while a normal control remains eligible',
      () async {
    var evaluations = 0;
    final state = await makeState(
      adaptiveShadowEvaluator: (_, __) {
        evaluations++;
        return const AdaptiveIntegrationDecision.noAdaptation();
      },
    );
    await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus);
    await state.setGameBrainPreference(true);
    await startFreePractice(state, operation: Operation.addition);
    state.onAnswer(state.rt.q!.ans);

    expect(state.debugP1F01IntegrityRunEligible, isFalse);
    expect(state.debugQuestionExperienceObservationCount, 0);
    expect(state.debugContextEvidenceObservationCount, 0);
    expect(evaluations, 0);

    await state.quitToMenu();
    state
      ..rt.challenge = Operation.addition
      ..players = 1
      ..mode = GameMode.standard
      ..adaptive = false
      ..diff = Difficulty.easy
      ..questionCount = 10;
    state.startGame();
    state.rt.timer?.cancel();
    state.onAnswer(state.rt.q!.ans);
    expect(state.debugQuestionExperienceObservationCount, 1);
    expect(state.debugContextEvidenceObservationCount, 1);
    expect(evaluations, 1);
  });

  test('cancelled Free Practice cannot leak into ordinary Quick Practice',
      () async {
    final state = await makeState();
    state.goToPracticeStyle('addition');
    state.startMentalMathFreePractice();
    state.backFromNumType();
    state.startTimingPractice();
    await state.selectNumType(NumberType.natural.name);
    state.startGame();
    state.rt.timer?.cancel();

    expect(state.activeRunSnapshot?.mentalMathEntry, isNull);
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
