import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/screens/numtype_screen.dart';
import 'package:math_challenge/screens/player_screen.dart';
import 'package:math_challenge/screens/practice_style_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const viewports = <Size>[Size(844, 390), Size(1280, 800)];

  for (final viewport in viewports) {
    testWidgets(
      'Addition start flow remains reachable at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        final state = await _makeState();
        addTearDown(state.dispose);
        tester.view
          ..physicalSize = viewport
          ..devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1;
        addTearDown(() {
          tester.view
            ..resetPhysicalSize()
            ..resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        await tester.pumpWidget(_TestHost(state: state));
        await tester.pumpAndSettle();

        expect(find.text('MATH'), findsOneWidget);
        expect(find.text('CHALLENGE'), findsOneWidget);
        expect(find.text('Daily'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
        final menuScroll = find.descendant(
          of: find.byType(MenuScreen),
          matching: find.byType(SingleChildScrollView),
        );
        expect(menuScroll, findsOneWidget);
        expect(
          tester
              .state<ScrollableState>(
                find.descendant(
                    of: menuScroll, matching: find.byType(Scrollable)),
              )
              .position
              .maxScrollExtent,
          greaterThan(0),
        );
        if (viewport.width == 1280) {
          final content = find.descendant(
            of: find.byType(MenuScreen),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is ConstrainedBox &&
                  widget.constraints.maxWidth == 720,
            ),
          );
          expect(content, findsOneWidget);
          final rect = tester.getRect(content);
          expect(rect.width, lessThanOrEqualTo(720));
          expect(rect.center.dx, closeTo(viewport.width / 2, 0.1));
        }
        await _expectHitTestable(tester, find.text('Addition'));
        await tester.tap(find.text('Addition'));
        await tester.pumpAndSettle();

        expect(state.currentScreen, GameScreen.practiceStyle);
        expect(find.byType(PracticeStyleScreen), findsOneWidget);
        final timingPracticeButton =
            find.byKey(const Key('timing-practice-button'));
        await _expectHitTestable(tester, timingPracticeButton);
        await tester.tap(timingPracticeButton);
        await tester.pumpAndSettle();

        expect(state.currentScreen, GameScreen.numType);
        expect(find.byType(NumTypeScreen), findsOneWidget);
        expect(find.text('Number Type'), findsOneWidget);
        for (final label in const [
          'Natural Numbers',
          'Integers',
          'Rationals / Decimals',
        ]) {
          await _expectHitTestable(tester, find.text(label));
        }
        await tester.ensureVisible(find.text('Natural Numbers'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Natural Numbers'));
        await tester.pumpAndSettle();

        expect(state.currentScreen, GameScreen.config);
        expect(find.byType(ConfigScreen), findsOneWidget);
        expect(state.mode.name, 'standard');
        expect(state.questionCount, 10);
        expect(state.adaptive, isFalse);
        for (final label in const [
          'Standard',
          '4 Choices',
          'Easy',
          '10',
          'Adaptive Difficulty',
        ]) {
          await _expectHitTestable(tester, find.textContaining(label).first);
        }
        await _expectHitTestable(
          tester,
          find.text('Continue to Player Setup →'),
        );
        await tester.tap(find.text('Continue to Player Setup →'));
        await tester.pumpAndSettle();

        expect(state.currentScreen, GameScreen.player);
        expect(find.byType(PlayerSetupScreen), findsOneWidget);
        expect(find.text('Player Setup'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _expectHitTestable(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final box = tester.renderObject<RenderBox>(target);
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect((Offset.zero & logicalSize).overlaps(rect), isTrue);
  expect(
    tester.hitTestOnBinding(rect.center).path.map((entry) => entry.target),
    contains(box),
  );
  expect(tester.takeException(), isNull);
}

Future<GameState> _makeState() async {
  SharedPreferences.setMockInitialValues(<String, Object>{'mc_dark': false});
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

class _TestHost extends StatelessWidget {
  const _TestHost({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
          ChangeNotifierProvider<GameState>.value(value: state),
        ],
        child: MaterialApp(
          theme: AppTheme.light(state.settings),
          home: Scaffold(
            backgroundColor: state.settings.bg,
            body: Consumer<GameState>(
              builder: (context, state, _) => switch (state.currentScreen) {
                GameScreen.menu => const MenuScreen(),
                GameScreen.practiceStyle => const PracticeStyleScreen(),
                GameScreen.numType => const NumTypeScreen(),
                GameScreen.config => const ConfigScreen(),
                GameScreen.player => const PlayerSetupScreen(),
                GameScreen.game => const SizedBox(),
              },
            ),
          ),
        ),
      );
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
