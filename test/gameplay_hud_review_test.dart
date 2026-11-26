import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';

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
        for (final players in [1, 2]) {
          testWidgets('HUD $size scale $scale dark $dark players $players',
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
              ..currentScreen = GameScreen.game;
            state.p[1]
              ..name = 'Alex'
              ..score = 12345;
            state.p[2]
              ..name = 'Sam'
              ..score = 67890;
            final timer = Timer(const Duration(hours: 1), () {});
            addTearDown(timer.cancel);
            state.rt = RuntimeState()
              ..challenge = Operation.addition
              ..gameActive = true
              ..state = 'playing'
              ..isWarmUp = false
              ..maxTurns = 10
              ..accepting = true
              ..timer = timer
              ..timerDurationMs = 10000
              ..q = const Question(
                type: Operation.addition,
                key: 'hud-review',
                text: '1234 + 5678',
                ans: 6912,
                choices: [6912, 6812, 6910, 6810],
                diff: Difficulty.hard,
                numType: NumberType.natural,
              );
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
            await captureSetupPreview(
              tester,
              screen: 'gameplay-${dark ? 'dark' : 'light'}-${players}p',
              size: size,
              scale: scale,
              position: 'hud',
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Alex'), findsOneWidget);
            expect(find.text('12345'), findsOneWidget);
            if (players == 2) {
              expect(find.text('Sam'), findsOneWidget);
              expect(find.text('67890'), findsOneWidget);
            }
            expect(find.text('1234 + 5678', findRichText: true), findsOneWidget);
            final content = find.byKey(const Key('gameplay-content'));
            expect(content, findsOneWidget);
            expect(tester.getRect(content).overlaps(Offset.zero & size), isTrue);
            final answers = [
              for (var i = 0; i < 4; i++)
                find.byKey(ValueKey('gameplay-answer-$i')),
            ];
            for (final answer in answers) {
              expect(answer, findsOneWidget);
              final size = tester.getSize(answer);
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
              expect(tester.widget<InkWell>(answer).onTap, isNotNull);
            }
            expect(tester.getCenter(answers[0]).dy,
                closeTo(tester.getCenter(answers[1]).dy, 1));
            expect(tester.getCenter(answers[2]).dy,
                closeTo(tester.getCenter(answers[3]).dy, 1));
            expect(tester.getCenter(answers[0]).dx,
                closeTo(tester.getCenter(answers[2]).dx, 1));
            expect(tester.getCenter(answers[1]).dx,
                closeTo(tester.getCenter(answers[3]).dx, 1));
            // Check the initial viewport, before ensureVisible scrolls it.
            final scroll = find.ancestor(
              of: content,
              matching: find.byType(Scrollable),
            );
            expect(scroll, findsOneWidget);
            final viewport = tester.getRect(scroll);
            final expression = find.byKey(
              const Key('gameplay-question-expression'),
            );
            for (final element in [expression, ...answers]) {
              final rect = tester.getRect(element);
              expect(rect.top, greaterThanOrEqualTo(viewport.top - 1),
                  reason: 'Question and answers must remain visible together');
              expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 1),
                  reason: 'Question and answers must remain visible together');
            }
            for (final answer in answers) {
              expect(answer.hitTestable(), findsOneWidget);
            }
            for (var i = 0; i < answers.length; i++) {
              final answer = answers[i];
              await tester.ensureVisible(answer);
              await tester.pumpAndSettle();
              expect(answer.hitTestable(), findsOneWidget);
              final label = find.descendant(
                of: answer,
                matching: find.text(['6912', '6812', '6910', '6810'][i]),
              );
              expect(label, findsOneWidget);
              final tile = tester.getRect(answer);
              final text = tester.getRect(label);
              expect(text.left, greaterThanOrEqualTo(tile.left - 1));
              expect(text.right, lessThanOrEqualTo(tile.right + 1));
              expect(text.top, greaterThanOrEqualTo(tile.top - 1));
              expect(text.bottom, lessThanOrEqualTo(tile.bottom + 1));
            }
            await captureSetupPreview(
              tester,
              screen: 'gameplay-${dark ? 'dark' : 'light'}-${players}p',
              size: size,
              scale: scale,
              position: 'answers',
            );
            expect(tester.takeException(), isNull);
            timer.cancel();
          });
        }
      }
    }
  }
}
