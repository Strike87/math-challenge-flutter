import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/common.dart';
import 'package:math_challenge/widgets/modals.dart';

import 'support/expect_whole_words.dart';
import 'support/setup_preview.dart';
import 'visual_parity_test.dart'
    show MockAudioService, TestAppWrapper, loadAppFonts, setTestDevice;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        for (final players in [1, 2]) {
          testWidgets('result $size scale $scale dark $dark players $players',
              (tester) async {
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
            final state =
                GameState(settings: settings, audio: MockAudioService());
            await state.load();
            addTearDown(state.dispose);
            state
              ..players = players
              ..mode = GameMode.standard
              ..currentModal = GameModal.win
              ..resultTitle = 'Round Complete!'
              ..resultDescription = 'Great work! Keep practicing.';
            state.p[1]
              ..name = 'Alex'
              ..score = 12345
              ..total = 10
              ..correct = 8
              ..skipped = 1
              ..timeMs = 31000
              ..maxStreak = 4;
            state.p[2]
              ..name = 'Sam'
              ..score = 67890
              ..total = 10
              ..correct = 7
              ..timeMs = 42000;
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
                      child: const ModalRouter(),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final screen = 'results-${dark ? 'dark' : 'light'}-${players}p';
            await captureSetupPreview(tester, screen: screen, size: size,
                scale: scale, position: 'top');
            expect(tester.takeException(), isNull);
            for (final action in ['Replay', 'Main Menu']) {
              expect(find.text(action).hitTestable(), findsOneWidget);
            }
            final compact = size.height <= 600 ||
                (size.width <= 400 && scale > 1.3);
            if (compact) {
              final replay = find.ancestor(
                of: find.text('Replay'),
                matching: find.byType(NeoButton),
              );
              final menu = find.ancestor(
                of: find.text('Main Menu'),
                matching: find.byType(NeoButton),
              );
              expect(tester.getCenter(replay).dy,
                  closeTo(tester.getCenter(menu).dy, 1));
              for (final action in [replay, menu]) {
                final actionSize = tester.getSize(action);
                expect(actionSize.width, greaterThanOrEqualTo(48));
                expect(actionSize.height, greaterThanOrEqualTo(48));
              }
              final viewport = tester.getRect(
                find.byType(SingleChildScrollView),
              );
              final score = tester.getRect(find.text('12345'));
              expect(score.top, greaterThanOrEqualTo(viewport.top - 1));
              expect(score.bottom, lessThanOrEqualTo(viewport.bottom + 1),
                  reason: 'Score should be visible before scrolling');
            }
            for (final value in [
              players == 1 ? "Alex's Report" : 'Head-to-Head Report',
              '12345',
              '80%',
              if (players == 2) ...['67890', '70%'],
              'Avg Time',
              '3.1s',
            ]) {
              final finder = find.text(value);
              expect(finder, findsOneWidget);
              await tester.ensureVisible(finder);
              await tester.pumpAndSettle();
              expectWholeWords(tester, value);
              expect(tester.takeException(), isNull);
            }
            await captureSetupPreview(tester, screen: screen, size: size,
                scale: scale, position: 'bottom');
            expect(find.text('Replay').hitTestable(), findsOneWidget);
            expect(find.text('Main Menu').hitTestable(), findsOneWidget);
            expect(state.p[1].score, 12345);
            expect(state.p[1].correct, 8);
          });
        }
      }
    }
  }
}
