import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';

import 'visual_parity_test.dart'
    show MockAudioService, TestAppWrapper, loadAppFonts, setTestDevice;

import 'support/setup_preview.dart';

import 'support/expect_whole_words.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  for (final size in <Size>[const Size(320, 568), const Size(390, 844)]) {
    for (final scale in <double>[1, 1.5, 2]) {
      testWidgets('config options at $size and $scale', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
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
        final state = GameState(settings: settings, audio: MockAudioService());
        await state.load();
        addTearDown(state.dispose);
        state.goToConfig('addition');
        await state.selectNumType('natural');
        await setTestDevice(tester, logicalSize: size);
        await tester.pumpWidget(
          TestAppWrapper(
            state: state,
            child: Scaffold(
              body: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const ConfigScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await captureSetupPreview(tester, screen: 'config', size: size,
            scale: scale, position: 'top');
        for (final label in <String>[
          '1 Player',
          '2 Players',
          'Blitz',
          'Death',
          'Survival',
          'Combo',
          'Easy',
          'Medium',
          'Hard',
          'Per Question',
          'Deep Thinking',
          'Time Bank',
          'Adaptive Difficulty',
          'Continue to Player Setup →',
        ]) {
          final finder = find.text(label);
          expect(finder, findsOneWidget);
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getRect(finder).overlaps(Offset.zero & size), isTrue);
          if (label == 'Time Bank' || label == 'Continue to Player Setup →') {
            await captureSetupPreview(tester, screen: 'config', size: size,
                scale: scale, position: label == 'Time Bank' ? 'timing' : 'bottom');
          }
        }

        for (final text in [
          'Game Setup',
          'PERSONALIZATION',
          'Adaptive Difficulty',
          'Automatically adjusts the challenge to your skill level',
        ]) {
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          expectWholeWords(tester, text);
        }

        final countOptions = ['10', '15', '20', '25'].map(find.text).toList();
        await tester.ensureVisible(countOptions.first);
        await tester.pumpAndSettle();
        for (final finder in countOptions) {
          expect(finder, findsOneWidget);
          expect(tester.getCenter(finder).dy,
              closeTo(tester.getCenter(countOptions.first).dy, 1));
        }
        await tester.tap(countOptions[1]);
        await tester.pumpAndSettle();
        expect(state.questionCount, 15);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
