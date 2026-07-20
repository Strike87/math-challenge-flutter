import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/gameplay/domain/question_mechanic.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('pending plan survives setup navigation and clears on exit flows',
      () async {
    final state = await _makeState();
    addTearDown(state.dispose);
    _setFocusedSkills(state);

    state.goToConfig('weakSkills');
    final plan = state.setupWeakSkillsPlan;
    expect(plan, isNotNull);
    expect(state.currentModal, GameModal.weakSkillsPractice);
    expect(state.currentScreen, GameScreen.menu);

    state.continueWeakSkillsSetup();
    expect(state.currentScreen, GameScreen.numType);
    expect(state.currentModal, GameModal.none);
    expect(state.rt.challenge, Operation.mixed);

    await state.selectNumType(NumberType.integers.name);
    expect(state.setupWeakSkillsPlan, same(plan));
    state.showScreen(GameScreen.numType);
    expect(state.setupWeakSkillsPlan, same(plan));
    state.showScreen(GameScreen.config);
    state.goToPlayerSetup();
    state.backFromPlayers();
    expect(state.setupWeakSkillsPlan, same(plan));

    state.showScreen(GameScreen.menu);
    expect(state.setupWeakSkillsPlan, isNull);

    state.goToConfig('weakSkills');
    state.cancelWeakSkillsSetup();
    expect(state.setupWeakSkillsPlan, isNull);
    expect(state.currentModal, GameModal.none);
    expect(state.currentScreen, GameScreen.menu);
  });

  test('ordinary Quick Practice paths never open the Weak Skills popup',
      () async {
    final state = await _makeState();
    addTearDown(state.dispose);

    for (final operationName in [
      'addition',
      'subtraction',
      'multiplication',
      'division',
      'missingOperation',
      'mixed',
    ]) {
      state.goToConfig(operationName);
      expect(
        state.currentModal,
        GameModal.none,
        reason: operationName,
      );
      expect(
        state.setupWeakSkillsPlan,
        isNull,
        reason: operationName,
      );
    }
  });

  testWidgets(
      'snapshot locks focus, replay preserves it, and fresh entry recalculates',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.players = 2;
    _setFocusedSkills(state);
    state.goToConfig('weakSkills');
    final plan = state.setupWeakSkillsPlan!;
    state.continueWeakSkillsSetup();
    state
      ..numType = NumberType.rationals
      ..diff = Difficulty.hard
      ..mode = GameMode.standard
      ..selectedAnswerStyle = AnswerStyle.trueFalse
      ..questionCount = 15;

    state.startGame();
    state.rt.timer?.cancel();
    final snapshot = state.activeRunSnapshot!;
    expect(snapshot.weakSkillsPlan, same(plan));
    expect(snapshot.runType, GameRunType.normal);
    expect(snapshot.operation, Operation.mixed);
    expect(snapshot.questionMechanic, QuestionMechanic.standard);
    expect(snapshot.operationQuestStageId, isNull);
    expect(snapshot.players, 1);
    expect(state.players, 2);
    expect(snapshot.numberType, NumberType.rationals);
    expect(snapshot.difficulty, Difficulty.hard);
    expect(snapshot.answerStyle, AnswerStyle.trueFalse);
    expect(snapshot.questionTarget, 15);
    expect(state.setupWeakSkillsPlan, isNull);

    state.skillMap[Operation.addition.name]!
      ..mastery = 100
      ..count = 100;
    expect(state.activeRunSnapshot!.weakSkillsPlan, same(plan));

    await state.replayGame();
    state.rt.timer?.cancel();
    expect(state.activeRunSnapshot!.weakSkillsPlan, same(plan));
    expect(state.rt.q!.type, plan.operationAt(0));

    await state.quitToMenu();
    state.goToConfig('weakSkills');
    expect(state.setupWeakSkillsPlan, isNot(same(plan)));
  });

  testWidgets('follow-up preserves a slot and Switch Operation consumes one',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    _setTiedWeakestSkills(state);
    state
      ..players = 2
      ..mode = GameMode.standard
      ..adaptive = false;
    state.goToConfig('weakSkills');
    state.continueWeakSkillsSetup();
    state.startGame();
    state.rt.timer?.cancel();

    expect(state.rt.q!.type, Operation.addition);
    expect(state.rt.weakSkillsScheduleIndex, 1);
    final wrong = state.rt.q!.choices.firstWhere(
      (choice) => (choice - state.rt.q!.ans).abs() >= 1e-9,
    );
    state.onAnswer(wrong);
    await tester.pump(const Duration(milliseconds: 1300));
    state.rt.timer?.cancel();
    expect(state.rt.q!.type, Operation.addition);
    expect(state.rt.weakSkillsScheduleIndex, 1);

    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1300));
    state.rt.timer?.cancel();
    expect(state.rt.q!.type, Operation.subtraction);
    expect(state.rt.weakSkillsScheduleIndex, 2);

    state.p[1].pups.add(PowerUp.switchOp);
    state.usePowerUp(PowerUp.switchOp);
    await tester.pump(const Duration(milliseconds: 500));
    state.rt.timer?.cancel();
    expect(state.rt.q!.type, Operation.addition);
    expect(state.rt.weakSkillsScheduleIndex, 3);
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('canonical answer side effects and Quest isolation are preserved',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    _setFocusedSkills(state);
    final progressBefore = state.operationQuestProgress.encode();
    state
      ..players = 2
      ..mode = GameMode.standard
      ..adaptive = true;
    state.goToConfig('weakSkills');
    state.continueWeakSkillsSetup();
    state.startGame();
    state.rt.timer?.cancel();
    final question = state.rt.q!;
    final skill = state.skillMap[question.type.name]!;
    final countBefore = skill.count;
    final masteryBefore = skill.mastery;

    state.onAnswer(question.ans);
    state.rt.timer?.cancel();

    expect(state.p[1].history.single.type, question.type);
    expect(skill.count, countBefore + 1);
    expect(skill.mastery, isNot(masteryBefore));
    expect(state.operationQuestProgress.encode(), progressBefore);
    expect(state.isOperationQuest, isFalse);
    await state.quitToMenu();
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('menu row and focused configuration are responsive',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    _setFocusedSkills(state);
// Preserve an existing ordinary 2-player preference.
    state.players = 2;

    await _pumpScreen(
        tester,
        state,
        const Stack(children: [
          MenuScreen(),
          ModalRouter(),
        ]),
        size: const Size(390, 844));
    expect(find.text('Weak Skills Practice'), findsOneWidget);
    expect(find.text('🚀'), findsOneWidget);
    for (final label in [
      'Addition',
      'Subtraction',
      'Multiplication',
      'Division',
      'Missing Operation',
      'Mixed Operations',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    final rowSize = tester.getSize(
      find.byKey(const Key('weak-skills-practice-row')),
    );
    expect(rowSize.width, 358);
    expect(rowSize.height, greaterThanOrEqualTo(86));
    await tester.ensureVisible(find.text('Weak Skills Practice'));
    await tester.tap(find.text('Weak Skills Practice'));
    await tester.pumpAndSettle();
    final plan = state.setupWeakSkillsPlan;
    expect(plan, isNotNull);
    expect(state.currentModal, GameModal.weakSkillsPractice);
    expect(state.currentScreen, GameScreen.menu);
    expect(find.text('Recommended Practice'), findsOneWidget);
    expect(find.text('Practice areas'), findsOneWidget);
    final modal = find.byType(ModalRouter);

    expect(
      find.descendant(
        of: modal,
        matching: find.text('Addition'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: modal,
        matching: find.text('Subtraction'),
      ),
      findsOneWidget,
    );
    expect(find.text('Based on your practice history.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpScreen(
      tester,
      state,
      const ModalRouter(),
      textScale: 2,
    );
    expect(find.text('Recommended Practice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    _setTiedWeakestSkills(state);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(state.currentScreen, GameScreen.numType);
    expect(state.currentModal, GameModal.none);
    expect(state.setupWeakSkillsPlan, same(plan));

    await state.selectNumType(NumberType.natural.name);
    await _pumpScreen(tester, state, const ConfigScreen(), textScale: 2);
    expect(find.text('Recommended Practice'), findsNothing);
    expect(find.text('Practice areas'), findsNothing);
    expect(find.text('Based on your practice history.'), findsNothing);
    expect(find.text('1 Player'), findsOneWidget);
    expect(find.text('2 Players'), findsOneWidget);
    await tester.tap(find.text('2 Players'));
    await tester.pump();
    expect(state.setupPlayers, 1);
    expect(state.players, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fallback popup cancels cleanly and fresh entry recalculates',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.players = 2;
    state.goToConfig('weakSkills');
    final fallbackPlan = state.setupWeakSkillsPlan;

    await _pumpScreen(
        tester,
        state,
        const Stack(children: [
          MenuScreen(),
          ModalRouter(),
        ]));
    expect(find.text('Building Your Practice Profile'), findsOneWidget);
    expect(
      find.text('This round will include all four operations.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.setupWeakSkillsPlan, isNull);
    expect(state.currentModal, GameModal.none);
    expect(state.currentScreen, GameScreen.menu);

    _setFocusedSkills(state);
    await tester.ensureVisible(find.text('Weak Skills Practice'));
    await tester.tap(find.text('Weak Skills Practice'));
    await tester.pumpAndSettle();
    expect(state.setupWeakSkillsPlan, isNot(same(fallbackPlan)));
    expect(state.setupWeakSkillsPlan!.isFallback, isFalse);
  });

  testWidgets('Weak Skills uses the ordinary Players row geometry',
      (tester) async {
    final state = await _makeState();
    addTearDown(state.dispose);
    state.players = 2;

    await _pumpScreen(tester, state, const ConfigScreen());
    final normalOnePlayer = tester.getRect(find.text('1 Player'));
    final normalTwoPlayers = tester.getRect(find.text('2 Players'));

    state.showScreen(GameScreen.menu);
    state.goToConfig('weakSkills');
    state.continueWeakSkillsSetup();
    await state.selectNumType(NumberType.natural.name);
    await _pumpScreen(tester, state, const ConfigScreen());
    final weakOnePlayer = tester.getRect(find.text('1 Player'));
    final weakTwoPlayers = tester.getRect(find.text('2 Players'));

    expect(weakOnePlayer.size, normalOnePlayer.size);
    expect(weakTwoPlayers.size, normalTwoPlayers.size);
    expect(weakOnePlayer.topLeft, normalOnePlayer.topLeft);
    expect(weakTwoPlayers.topLeft, normalTwoPlayers.topLeft);
    expect(find.text('Building Your Practice Profile'), findsNothing);
    expect(state.setupPlayers, 1);
    expect(state.players, 2);

    final disabledOpacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('2 Players'), matching: find.byType(Opacity))
          .first,
    );
    expect(disabledOpacity.opacity, 0.4);
    await tester.tap(find.text('2 Players'));
    expect(state.setupPlayers, 1);
    expect(state.players, 2);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  GameState state,
  Widget screen, {
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
        ChangeNotifierProvider<GameState>.value(value: state),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: screen),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<GameState> _makeState() async {
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
  return state;
}

void _setFocusedSkills(GameState state) {
  state.skillMap = {
    Operation.addition.name: SkillData(mastery: 5, count: 3),
    Operation.subtraction.name: SkillData(mastery: 20, count: 3),
    Operation.multiplication.name: SkillData(mastery: 30, count: 3),
    Operation.division.name: SkillData(mastery: 40, count: 3),
  };
}

void _setTiedWeakestSkills(GameState state) {
  state.skillMap = {
    Operation.addition.name: SkillData(mastery: 5, count: 3),
    Operation.subtraction.name: SkillData(mastery: 5, count: 3),
    Operation.multiplication.name: SkillData(mastery: 30, count: 3),
    Operation.division.name: SkillData(mastery: 40, count: 3),
  };
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
