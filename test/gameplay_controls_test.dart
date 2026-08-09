import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/gameplay/presentation/widgets/gameplay_controls.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('QuitPill follows the dyslexia setting and remains tappable',
      (tester) async {
    final settings = SettingsService();
    var taps = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: QuitPill(onPressed: () => taps++),
          ),
        ),
      ),
    );

    Text quitText() => tester.widget<Text>(find.text('Quit'));

    expect(quitText().style?.fontFamily, AppFonts.head);

    settings.load(
      dark: false,
      sound: true,
      vibration: true,
      dyslexia: true,
      colorblind: false,
      lowPerf: false,
      reduceMotion: false,
      animSpeed: 1,
    );
    await tester.pump();

    expect(quitText().style?.fontFamily, AppFonts.dyslexia);

    await tester.tap(find.text('Quit'));
    expect(taps, 1);
  });

  testWidgets('gameplay content is bounded on wide viewports', (tester) async {
    for (final size in [const Size(1194, 834), const Size(1440, 900)]) {
      final state = await _gameState();
      await _pumpGame(tester, state, size);

      expect(tester.takeException(), isNull);
      final content = tester.getRect(find.byKey(const Key('gameplay-content')));
      expect(content.width, 720);
      expect((content.center.dx - size.width / 2).abs(), lessThanOrEqualTo(1));
      final hud = tester.getRect(
        find
            .ancestor(
              of: find.text('STANDARD'),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(hud.width, greaterThan(content.width));

      final answerFinder = find.descendant(
        of: find.byType(GridView).first,
        matching: find.byType(InkWell),
      );
      final answers = tester
          .widgetList<InkWell>(answerFinder)
          .where((answer) => answer.onTap != null)
          .toList();
      expect(answers, hasLength(4));
      final answerRects = answers
          .map((answer) => tester.getRect(find.byWidget(answer)))
          .toList();
      expect(answerRects[0].left, answerRects[2].left);
      expect(answerRects[1].left, answerRects[3].left);
      expect(answerRects[0].width, answerRects[1].width);
      expect(answerRects[0].width, answerRects[2].width);
      state.dispose();
    }
  });

  testWidgets('landscape gameplay answer remains actionable', (tester) async {
    final state = await _gameState();
    await _pumpGame(tester, state, const Size(844, 390));

    final answer = find
        .descendant(
          of: find.byType(GridView).first,
          matching: find.byType(InkWell),
        )
        .first;
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pump(const Duration(milliseconds: 1300));

    expect(tester.takeException(), isNull);
    expect(state.rt.totalTurns, 1);
    state.dispose();
  });

  testWidgets('True/False keyboard answer respects the gameplay lock',
      (tester) async {
    final state = await _gameState();
    state.rt.answerStyle = AnswerStyle.trueFalse;
    state.rt.proposedAnswer = state.rt.q!.ans;
    state.rt.proposedTruth = true;
    await _pumpGame(tester, state, const Size(390, 844));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Quit'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Skip ⏩'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('True'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(state.rt.totalTurns, 1);
    expect(state.rt.accepting, isFalse);
    expect(state.rt.lastAnswerCorrect, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.rt.totalTurns, 1);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('power-up controls traverse and Enter activates once',
      (tester) async {
    final state = await _gameState();
    addTearDown(state.dispose);
    state.p[1].pups.addAll([
      PowerUp.double,
      PowerUp.double,
      PowerUp.shield,
      PowerUp.shield,
    ]);
    await _pumpGame(tester, state, const Size(390, 844));

    final doubleControl = _powerUpControl('×2');
    expect(
      tester.widget<InkWell>(doubleControl).borderRadius,
      BorderRadius.circular(18),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Quit'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('×2'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('🛡'))).hasFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(Focus.of(tester.element(find.text('×2'))).hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(state.p[1].doubleActive, isTrue);
    expect(_powerUpCount(state, PowerUp.double), 1);
    expect(state.rt.puUsed, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_powerUpCount(state, PowerUp.double), 1);
    expect(state.rt.puUsed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('power-up control activates once from Space', (tester) async {
    final state = await _gameState();
    addTearDown(state.dispose);
    state.p[1].pups.addAll([PowerUp.shield, PowerUp.shield]);
    await _pumpGame(tester, state, const Size(390, 844));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('🛡'))).hasFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(state.p[1].shieldActive, isTrue);
    expect(_powerUpCount(state, PowerUp.shield), 1);
    expect(state.rt.puUsed, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_powerUpCount(state, PowerUp.shield), 1);
    expect(state.rt.puUsed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('True/False keeps 50/50 visible and natively disabled',
      (tester) async {
    final state = await _gameState();
    addTearDown(state.dispose);
    state.p[1].pups.addAll([PowerUp.fifty, PowerUp.fifty]);
    state.rt.answerStyle = AnswerStyle.trueFalse;
    state.rt.proposedAnswer = state.rt.q!.ans;
    state.rt.proposedTruth = true;
    await _pumpGame(tester, state, const Size(390, 844));

    final fiftyControl = _powerUpControl('50/50');
    expect(fiftyControl, findsOneWidget);
    expect(tester.widget<InkWell>(fiftyControl).onTap, isNull);
    expect(find.byKey(const Key('powerup-fifty-count')), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(_powerUpCount(state, PowerUp.fifty), 2);
    expect(state.rt.puUsed, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Quit'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Skip ⏩'))).hasFocus, isTrue);
    expect(Focus.of(tester.element(find.text('50/50'))).hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('power-up pointer activation mutates inventory exactly once',
      (tester) async {
    final state = await _gameState();
    addTearDown(state.dispose);
    state.p[1].pups.addAll([PowerUp.double, PowerUp.double]);
    await _pumpGame(tester, state, const Size(390, 844));

    final doubleControl = _powerUpControl('×2');
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    final center = tester.getCenter(doubleControl);
    await tester.sendEventToBinding(mouse.hover(center));
    await tester.sendEventToBinding(mouse.down(center));
    await tester.sendEventToBinding(mouse.up());
    await tester.pump();

    expect(state.p[1].doubleActive, isTrue);
    expect(_powerUpCount(state, PowerUp.double), 1);
    expect(state.rt.puUsed, 1);
    await tester.sendEventToBinding(mouse.removePointer());
    expect(tester.takeException(), isNull);
  });

  testWidgets('answer lock disables a focused power-up before activation',
      (tester) async {
    final state = await _gameState();
    addTearDown(state.dispose);
    state.p[1].pups.add(PowerUp.shield);
    await _pumpGame(tester, state, const Size(390, 844));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('🛡'))).hasFocus, isTrue);

    state.rt.accepting = false;
    state.notifyListeners();
    await tester.pump();
    final shieldControl = _powerUpControl('🛡');
    expect(tester.widget<InkWell>(shieldControl).onTap, isNull);
    expect(Focus.of(tester.element(find.text('🛡'))).hasFocus, isFalse);

    await tester.tap(shieldControl);
    await tester.pump();
    expect(state.p[1].shieldActive, isFalse);
    expect(_powerUpCount(state, PowerUp.shield), 1);
    expect(state.rt.puUsed, 0);
    expect(tester.takeException(), isNull);
  });
}

Finder _powerUpControl(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(InkWell),
    );

int _powerUpCount(GameState state, PowerUp powerUp) =>
    state.p[1].pups.where((candidate) => candidate == powerUp).length;

Future<GameState> _gameState() async {
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
  state.startGame();
  state.rt.timer?.cancel();
  return state;
}

Future<void> _pumpGame(
  WidgetTester tester,
  GameState state,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
        ChangeNotifierProvider<GameState>.value(value: state),
      ],
      child: const MaterialApp(
        home: Scaffold(body: game_screen.GameScreen()),
      ),
    ),
  );
  await tester.pump();
}
