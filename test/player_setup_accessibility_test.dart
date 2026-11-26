import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/screens/player_screen.dart';
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
      testWidgets('two-player setup at $size and $scale', (tester) async {
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
        state.setOption('players', 2);
        expect(state.setupPlayers, 2);
        state.goToPlayerSetup();

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
                  child: const PlayerSetupScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await captureSetupPreview(tester, screen: 'player', size: size,
            scale: scale, position: 'player1');
        final progress = find.byKey(const Key('player-setup-progress'));
        for (final label in ['Player 1', 'Player 2']) {
          final finder = find.descendant(
            of: progress,
            matching: find.text(label),
          );
          expect(finder, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(paragraph.didExceedMaxLines, isFalse);
          final rect = tester.getRect(finder);
          final bounds = tester.getRect(progress);
          expect(rect.top, greaterThanOrEqualTo(bounds.top));
          expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
        }

        expect(find.text('Player 1 Setup'), findsOneWidget);
        final firstName = find.byKey(const Key('player-setup-name-p1'));
        await tester.ensureVisible(firstName);
        await tester.enterText(firstName, 'Alex');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        final primary = find.byKey(const Key('player-setup-primary'));
        await tester.ensureVisible(primary);
        await tester.pumpAndSettle();
        await captureSetupPreview(tester, screen: 'player', size: size,
            scale: scale, position: 'player1-bottom');
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(find.text('Player 2 Setup'), findsOneWidget);
        expect(find.byKey(const Key('player-setup-name-p2')), findsOneWidget);

        final back = find.byKey(const Key('player-setup-back'));
        await tester.ensureVisible(back);
        await tester.pumpAndSettle();
        await captureSetupPreview(tester, screen: 'player', size: size,
            scale: scale, position: 'player2');
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(find.text('Player 1 Setup'), findsOneWidget);
        expect(state.p[1].name, 'Alex');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
