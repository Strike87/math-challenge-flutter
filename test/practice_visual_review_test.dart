import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';

import 'support/expect_whole_words.dart';
import 'support/setup_preview.dart';
import 'visual_parity_test.dart'
    show MockAudioService, TestAppWrapper, TestAppShell, loadAppFonts, setTestDevice;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('practice $size scale $scale dark $dark', (tester) async {
          SharedPreferences.setMockInitialValues({'mc_dark': dark});
          await Storage.init();
          final settings = SettingsService()
            ..load(
              dark: dark,
              sound: false,
              vibration: false,
              dyslexia: false,
              colorblind: false,
              lowPerf: true,
              reduceMotion: true,
              animSpeed: 1,
            );
          final state = GameState(settings: settings, audio: MockAudioService());
          await state.load();
          addTearDown(state.dispose);
          state.showPracticeMenu();
          await setTestDevice(tester, logicalSize: size);
          await tester.pumpWidget(
            TestAppWrapper(
              state: state,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const TestAppShell(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final screen = 'practice-${dark ? 'dark' : 'light'}';
          await captureSetupPreview(tester, screen: screen, size: size,
              scale: scale, position: 'menu-top');
          for (final label in [
            'Operation Quest', '10 TRAILS • 30 STAGES', 'QUICK PRACTICE',
            'Addition', 'Subtraction', 'Multiplication', 'Division',
            'Missing Operation', 'Mixed Operations',
          ]) {
            final finder = find.text(label);
            expect(finder, findsOneWidget);
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            expectWholeWords(tester, label);
            expect(tester.takeException(), isNull);
          }
          await captureSetupPreview(tester, screen: screen, size: size,
              scale: scale, position: 'menu-bottom');
          final addition = find.text('Addition');
          await tester.ensureVisible(addition);
          await tester.pumpAndSettle();
          await tester.tap(addition);
          await tester.pumpAndSettle();
          expect(state.currentScreen, GameScreen.practiceStyle);
          expectWholeWords(tester, 'Choose Practice Style');
          final back = find.byKey(const Key('practice-style-back'));
          expect(tester.getSize(back).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
          await captureSetupPreview(tester, screen: screen, size: size,
              scale: scale, position: 'style-top');
          for (final label in ['Timing Practice', 'IQ Spark']) {
            await tester.ensureVisible(find.text(label));
            await tester.pumpAndSettle();
            expectWholeWords(tester, label);
          }
          final iq = find.byKey(const Key('mental-math-button'));
          await tester.ensureVisible(iq);
          await tester.pumpAndSettle();
          expect(iq.hitTestable(), findsOneWidget);
          await captureSetupPreview(tester, screen: screen, size: size,
              scale: scale, position: 'style-bottom');
          await tester.tap(iq);
          await tester.pumpAndSettle();
          expect(state.currentScreen, GameScreen.numType);
          expect(state.isMentalMathSetup, isTrue);
          state.goToPracticeStyle('addition');
          await tester.pumpAndSettle();
          final timing = find.byKey(const Key('timing-practice-button'));
          await tester.ensureVisible(timing);
          await tester.pumpAndSettle();
          await tester.tap(timing);
          await tester.pumpAndSettle();
          expect(state.currentScreen, GameScreen.numType);
          expect(state.isMentalMathSetup, isFalse);
          state.goToPracticeStyle('addition');
          await tester.pumpAndSettle();
          await tester.ensureVisible(back);
          await tester.pumpAndSettle();
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(state.currentScreen, GameScreen.menu);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
