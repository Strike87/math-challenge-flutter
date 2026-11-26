import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/screens/numtype_screen.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';

import 'visual_parity_test.dart'
    show MockAudioService, TestAppWrapper, loadAppFonts, setTestDevice;

import 'support/setup_preview.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  for (final size in <Size>[const Size(320, 568), const Size(390, 844)]) {
    for (final scale in <double>[1, 1.5, 2]) {
      testWidgets('number type cards at $size and $scale', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'mc_numTypeUnlocked_integers': 1,
          'mc_numTypeUnlocked_rationals': 0,
        });
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
                  child: const NumTypeScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await captureSetupPreview(tester, screen: 'number-type', size: size,
            scale: scale, position: 'top');
        expect(find.text('READY'), findsNWidgets(2));
        expect(find.text('1200 🪙'), findsOneWidget);
        for (final label in <String>[
          'Natural Numbers',
          'Integers',
          'Rationals / Decimals',
        ]) {
          final title = find.text(label);
          expect(title, findsOneWidget);
          final card = find.ancestor(of: title, matching: find.byType(InkWell));
          expect(card, findsOneWidget);
          await tester.ensureVisible(title);
          await tester.pumpAndSettle();
          final cardRect = tester.getRect(card);
          final labels = find.descendant(
            of: card,
            matching: find.byType(RichText),
          );
          for (final element in labels.evaluate()) {
            final paragraph = element.renderObject;
            if (paragraph is! RenderParagraph) continue;
            expect(paragraph.didExceedMaxLines, isFalse);
            final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
            expect(rect.left, greaterThanOrEqualTo(cardRect.left - 1));
            expect(rect.right, lessThanOrEqualTo(cardRect.right + 1));
          }
          expect(tester.takeException(), isNull);
          if (label == 'Rationals / Decimals') {
            await captureSetupPreview(tester, screen: 'number-type', size: size,
                scale: scale, position: 'rationals');
          }
        }
      });
    }
  }
}
