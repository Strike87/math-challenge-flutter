import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/gameplay/presentation/widgets/gameplay_controls.dart';
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
}

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
