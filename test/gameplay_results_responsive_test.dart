import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/screens/player_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _viewports = [Size(844, 390), Size(1280, 800)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viewport in _viewports) {
    testWidgets('Master responsive flow at $viewport', (tester) async {
      final state = await _makeState();
      await _setViewport(tester, viewport);

      state.goToConfig('master');
      await _pumpShell(tester, state);

      final ready = find.text('I am Ready! 🗡️');
      await _expectReachable(tester, ready, viewport);
      await tester.tap(ready);
      await tester.pump();
      expect(state.currentScreen, GameScreen.player);
      expect(find.byType(PlayerSetupScreen), findsOneWidget);

      state.startGame();
      await tester.pump();
      _expectGameplay(state);
      await _expectHud(tester, find.text('🏆 MASTER'), viewport);
      await _expectHud(tester, find.text('Stage 1'), viewport);
      await _expectHud(tester, find.text('♥♥♥'), viewport);
      await _expectHud(tester, find.text('10').first, viewport);
      await _expectQuestionAndAnswer(tester, viewport);
      _expectWideContent(tester, viewport);

      for (var answer = 0; answer < 5; answer++) {
        state.onAnswer(state.rt.q!.ans);
        if (answer < 4) await tester.pump(const Duration(milliseconds: 1300));
      }
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 1250));

      expect(state.currentModal, GameModal.stageCleared);
      final enterStageTwo = find.text('Enter River Crossing');
      await _expectReachable(tester, enterStageTwo, viewport);
      expect(tester.takeException(), isNull);

      await tester.tap(enterStageTwo);
      await tester.pump();
      expect(state.currentModal, GameModal.none);
      expect(state.masterLevel, 1);
      expect(state.rt.gameActive, isTrue);
      await _expectHud(tester, find.text('Stage 2'), viewport);
      await _expectQuestionAndAnswer(tester, viewport);
      expect(tester.takeException(), isNull);
      await _finish(tester, state);
    });

    testWidgets('Survival responsive flow at $viewport', (tester) async {
      final state = await _makeState();
      await _setViewport(tester, viewport);
      state.players = 1;
      state.mode = GameMode.survival;
      state.rt.challenge = Operation.addition;
      state.startGame();
      await _pumpShell(tester, state);

      _expectGameplay(state);
      await _expectHud(tester, find.text('💪 SURVIVAL'), viewport);
      await _expectHud(tester, find.text('♥♥♥'), viewport);
      await _expectHud(tester, find.text('Easy'), viewport);
      await _expectHud(tester, find.text('15').first, viewport);
      await _expectQuestionAndAnswer(tester, viewport);
      _expectWideContent(tester, viewport);

      for (var answer = 0; answer < 10; answer++) {
        state.onAnswer(state.rt.q!.ans);
        if (answer < 9) await tester.pump(const Duration(milliseconds: 1300));
      }

      expect(state.rt.survivalCorrect, 10);
      expect(state.rt.survivalPhase, 2);
      await tester.pump();
      expect(state.reactionPill, '👹 BOSS DOWN! +5🪙');
      expect(find.textContaining('BOSS DOWN! +5🪙'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));

      state.rt.survivalLives = 1;
      state.notifyListeners();
      await tester.pump();
      final wrongIndex = state.rt.q!.choices.indexWhere(
        (choice) => (choice - state.rt.q!.ans).abs() > 0.000001,
      );
      expect(wrongIndex, greaterThanOrEqualTo(0));
      final wrongAnswer = _enabledAnswers().at(wrongIndex);
      await _expectReachable(tester, wrongAnswer, viewport);
      await tester.tap(wrongAnswer);
      await tester.pump(const Duration(milliseconds: 900));

      expect(state.currentModal, GameModal.win);
      await _expectReachable(tester, find.text('Replay'), viewport);
      await _expectReachable(tester, find.text('Main Menu'), viewport);
      expect(tester.takeException(), isNull);
      await _finish(tester, state);
    });

    testWidgets('Two-player responsive flow at $viewport', (tester) async {
      final state = await _makeState();
      await _setViewport(tester, viewport);
      state.players = 2;
      state.mode = GameMode.standard;
      state.rt.challenge = Operation.addition;
      state.questionCount = 1;
      state.adaptive = false;
      state.startGame();
      state.rt.isWarmUp = false;
      state.notifyListeners();
      await _pumpShell(tester, state);

      _expectGameplay(state);
      await _expectHud(tester, find.text("Player 1's Turn"), viewport);
      expect(find.byType(AnimatedScale), findsAtLeastNWidgets(2));
      await _expectQuestionAndAnswer(tester, viewport);
      _expectWideContent(tester, viewport);

      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));

      expect(state.currentModal, GameModal.none);
      expect(state.rt.activePlayer, 2);
      await _expectHud(tester, find.text("Player 2's Turn"), viewport);
      await _expectQuestionAndAnswer(tester, viewport);

      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));

      expect(state.currentModal, GameModal.win);
      expect(find.text('Head-to-Head Report'), findsOneWidget);
      final replay = find.text('Replay');
      final menu = find.text('Main Menu');
      await _expectReachable(tester, replay, viewport);
      await _expectReachable(tester, menu, viewport);
      expect(tester.takeException(), isNull);

      await tester.tap(replay);
      await tester.pump();
      expect(state.currentModal, GameModal.none);
      expect(state.rt.gameActive, isTrue);
      expect(state.currentScreen, GameScreen.game);

      state.showModal(GameModal.win);
      await tester.pump();
      await _expectReachable(tester, find.text('Main Menu'), viewport);
      await tester.tap(find.text('Main Menu'));
      await tester.pump();
      expect(state.currentScreen, GameScreen.menu);
      expect(state.rt.gameActive, isFalse);
      expect(tester.takeException(), isNull);
      await _finish(tester, state);
    });
  }
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
  final state = GameState(settings: settings, audio: AudioService(settings));
  await state.load();
  return state;
}

Future<void> _setViewport(WidgetTester tester, Size viewport) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpShell(WidgetTester tester, GameState state) async {
  addTearDown(state.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
        ChangeNotifierProvider<GameState>.value(value: state),
      ],
      child: const MaterialApp(home: _ResponsiveShell()),
    ),
  );
  await tester.pump();
}

Future<void> _finish(WidgetTester tester, GameState state) async {
  state.rt.timer?.cancel();
  await tester.pump(const Duration(seconds: 3));
  state.dispose();
}

void _expectGameplay(GameState state) {
  expect(state.currentScreen, GameScreen.game);
  expect(state.rt.gameActive, isTrue);
}

Future<void> _expectQuestionAndAnswer(
  WidgetTester tester,
  Size viewport,
) async {
  final content = find.byKey(const Key('gameplay-content'));
  expect(content, findsOneWidget);
  await _expectReachable(tester, content, viewport);
  final answer = _enabledAnswers().first;
  await _expectReachable(tester, answer, viewport);
}

Finder _enabledAnswers() => find.descendant(
      of: find.byType(GridView).first,
      matching: find.byType(InkWell),
    );

Future<void> _expectHud(
  WidgetTester tester,
  Finder finder,
  Size viewport,
) async {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThan(0));
  expect(rect.height, greaterThan(0));
  expect(rect.overlaps(Offset.zero & viewport), isTrue);
}

Future<void> _expectReachable(
  WidgetTester tester,
  Finder finder,
  Size viewport,
) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThan(0));
  expect(rect.height, greaterThan(0));
  expect(rect.overlaps(Offset.zero & viewport), isTrue);
  expect(tester.hitTestOnBinding(tester.getCenter(finder)).path, isNotEmpty);
}

void _expectWideContent(WidgetTester tester, Size viewport) {
  if (viewport.width != 1280) return;
  final rect = tester.getRect(find.byKey(const Key('gameplay-content')));
  expect(rect.width, lessThanOrEqualTo(720));
  expect((rect.center.dx - viewport.width / 2).abs(), lessThanOrEqualTo(1));
}

class _ResponsiveShell extends StatelessWidget {
  const _ResponsiveShell();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    return Scaffold(
      body: Stack(
        children: [
          switch (state.currentScreen) {
            GameScreen.player => const PlayerSetupScreen(),
            GameScreen.game => const game_screen.GameScreen(),
            _ => const SizedBox.expand(),
          },
          const ModalRouter(),
        ],
      ),
    );
  }
}
