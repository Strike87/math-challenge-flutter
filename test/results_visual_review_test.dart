import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
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

  _registerIqSparkResults();

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

enum _IqResultFixture { freePractice, trainingArena, daily }

const _freePracticeSummary = MentalMathResultSummary(
  avatarEmoji: '🐶',
  terminalTitle: 'MASTERY REACHED',
  message: 'Strong run. You reached full momentum.',
  peakMomentum: 10,
  bestStreak: 5,
  accuracyPercent: 82,
  averageResponseMs: 4300,
  fastestAnswerMs: 2100,
  factsRecovered: 0,
);

const _trainingArenaSummary = MentalMathResultSummary(
  avatarEmoji: '🐶',
  terminalTitle: 'MASTERY REACHED',
  message: 'Strong run. You reached full momentum.',
  peakMomentum: 10,
  bestStreak: 5,
  accuracyPercent: 82,
  averageResponseMs: 4300,
  fastestAnswerMs: 2100,
  factsRecovered: 1,
  trainingArenaPracticeAreas: [Operation.addition, Operation.subtraction],
);

// Reuse the established first-clear and Perfect Day fixture contracts.
// Both daily substates are asserted at every size/scale/theme; only the
// richer already-claimed Perfect Day state contributes the two captures.
const _dailyFirstClearSummary = MentalMathResultSummary(
  avatarEmoji: '🐶',
  terminalTitle: 'MASTERY REACHED',
  message: 'Strong run. You reached full momentum.',
  peakMomentum: 10,
  bestStreak: 6,
  accuracyPercent: 82,
  averageResponseMs: 4300,
  fastestAnswerMs: 2100,
  factsRecovered: 1,
  dailyFocus: DailyMentalMathFocus.streakMaster,
  currentRunFocusMet: true,
  officialFocusCompleted: true,
  focusGrade: DailyMentalMathGrade.a,
  todaysBestGrade: DailyMentalMathGrade.a,
  isNewDailyBest: true,
  dailyRewardAmountGranted: 50,
);

const _dailyPerfectDaySummary = MentalMathResultSummary(
  avatarEmoji: '🐶',
  terminalTitle: 'MASTERY REACHED',
  message: 'Strong run. You reached full momentum.',
  peakMomentum: 10,
  bestStreak: 8,
  accuracyPercent: 95,
  averageResponseMs: 3200,
  fastestAnswerMs: 1600,
  factsRecovered: 2,
  dailyFocus: DailyMentalMathFocus.precision,
  currentRunFocusMet: true,
  officialFocusCompleted: true,
  focusGrade: DailyMentalMathGrade.s,
  todaysBestGrade: DailyMentalMathGrade.s,
  dailyRewardAlreadyClaimed: true,
  perfectDay: true,
);

void _registerIqSparkResults() {
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        for (final fixture in _IqResultFixture.values) {
          testWidgets(
            'IQ Spark result ${fixture.name} $size scale $scale dark $dark',
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
                ..players = 1
                ..mode = GameMode.standard
                ..currentModal = GameModal.win;
              await setTestDevice(tester, logicalSize: size);
              final screen =
                  'results-iq-${fixture.name}-${dark ? 'dark' : 'light'}';
              final summaries = switch (fixture) {
                _IqResultFixture.freePractice => [_freePracticeSummary],
                _IqResultFixture.trainingArena => [_trainingArenaSummary],
                _IqResultFixture.daily => [
                    _dailyFirstClearSummary,
                    _dailyPerfectDaySummary,
                  ],
              };
              for (final summary in summaries) {
                state.mentalMathResultSummary = summary;
                await tester.pumpWidget(
                  TestAppWrapper(
                    state: state,
                    child: Scaffold(
                      body: Builder(
                        builder: (context) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                          ),
                          child: ModalRouter(
                            key: ValueKey(
                              '${fixture.name}-${summaries.indexOf(summary)}',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final modal = find.byType(WinModal);
                expect(modal, findsOneWidget);
                final scroll = find.descendant(
                  of: modal,
                  matching: find.byType(SingleChildScrollView),
                );
                expect(scroll, findsOneWidget);
                final scrollable = find.descendant(
                  of: scroll,
                  matching: find.byType(Scrollable),
                );
                expect(scrollable, findsOneWidget);
                final position =
                    tester.state<ScrollableState>(scrollable).position;
                position.jumpTo(position.minScrollExtent);
                await tester.pumpAndSettle();
                final compact = size.height <= 600 ||
                    (size.width <= 400 && scale > 1.3);
                final viewport = Offset.zero & size;
                final capture = identical(summary, summaries.last);

                expect(tester.takeException(), isNull);
                _expectIqText(
                  tester,
                  summary.dailyFocus == null ? 'IQ SPARK' : 'DAILY IQ SPARK',
                  viewport,
                );
                _expectIqText(tester, summary.terminalTitle, viewport);
                _expectIqActions(tester, modal, viewport, compact);
                if (capture) {
                  await captureSetupPreview(
                    tester,
                    screen: screen,
                    size: size,
                    scale: scale,
                    position: 'top',
                  );
                }

                final texts = [
                  summary.message,
                  if (fixture == _IqResultFixture.trainingArena) ...[
                    'Training Arena',
                    'Practice Areas',
                    'Addition\nSubtraction',
                  ],
                  if (fixture == _IqResultFixture.daily) ...[
                    'Daily Focus',
                    'Focus',
                    summary.dailyFocus!.label,
                    'Status',
                    '✓ COMPLETE',
                    'Focus Grade',
                    summary.focusGrade!.label,
                    "Today's Best",
                    'Grade ${summary.todaysBestGrade!.label}',
                    if (summary.isNewDailyBest) 'NEW DAILY BEST!',
                    if (summary.dailyRewardAmountGranted > 0) '+50 COINS',
                    if (summary.dailyRewardAlreadyClaimed)
                      'DAILY REWARD ALREADY CLAIMED',
                    if (summary.perfectDay) '★ PERFECT DAY ★',
                  ],
                  'Session Metrics',
                  'Peak Momentum',
                  '+${summary.peakMomentum}',
                  'Best Streak',
                  '${summary.bestStreak}',
                  'Accuracy',
                  '${summary.accuracyPercent}%',
                  'Average Response Time',
                  '${(summary.averageResponseMs! / 1000).toStringAsFixed(1)}s',
                  'Fastest Answer',
                  '${(summary.fastestAnswerMs! / 1000).toStringAsFixed(1)}s',
                  'Facts Recovered',
                  '${summary.factsRecovered}',
                ];
                for (final value in texts) {
                  final finder = find.text(value);
                  expect(finder, findsOneWidget, reason: value);
                  await tester.ensureVisible(finder);
                  await tester.pumpAndSettle();
                  _expectIqText(tester, value, tester.getRect(scroll));
                  _expectIqActions(tester, modal, viewport, compact);
                  expect(tester.takeException(), isNull);
                }

                // Verify mutually exclusive daily reward presentations.
                if (fixture == _IqResultFixture.daily) {
                  expect(
                    find.text('+50 COINS'),
                    summary.dailyRewardAmountGranted > 0
                        ? findsOneWidget
                        : findsNothing,
                  );
                  expect(
                    find.text('DAILY REWARD ALREADY CLAIMED'),
                    summary.dailyRewardAlreadyClaimed
                        ? findsOneWidget
                        : findsNothing,
                  );
                  expect(
                    find.text('★ PERFECT DAY ★'),
                    summary.perfectDay ? findsOneWidget : findsNothing,
                  );
                  expect(
                    find.text('NEW DAILY BEST!'),
                    summary.isNewDailyBest ? findsOneWidget : findsNothing,
                  );
                }

                position.jumpTo(position.maxScrollExtent);
                await tester.pumpAndSettle();
                _expectIqText(tester, 'Facts Recovered', tester.getRect(scroll));
                _expectIqText(
                  tester,
                  '${summary.factsRecovered}',
                  tester.getRect(scroll),
                );
                _expectIqActions(tester, modal, viewport, compact);
                expect(tester.takeException(), isNull);
                expect(state.mentalMathResultSummary, same(summary));
                if (capture) {
                  await captureSetupPreview(
                    tester,
                    screen: screen,
                    size: size,
                    scale: scale,
                    position: 'bottom',
                  );
                }
              }
            },
          );
        }
      }
    }
  }
}

void _expectIqText(WidgetTester tester, String text, Rect viewport) {
  expectWholeWords(tester, text);
  final rect = tester.getRect(find.text(text));
  expect(rect.width, greaterThan(0), reason: text);
  expect(rect.height, greaterThan(0), reason: text);
  expect(rect.left, greaterThanOrEqualTo(viewport.left - 1), reason: text);
  expect(rect.right, lessThanOrEqualTo(viewport.right + 1), reason: text);
  expect(rect.top, greaterThanOrEqualTo(viewport.top - 1), reason: text);
  expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 1), reason: text);
}

void _expectIqActions(
  WidgetTester tester,
  Finder modal,
  Rect viewport,
  bool compact,
) {
  for (final label in ['Replay', 'Main Menu']) {
    final text = find.descendant(of: modal, matching: find.text(label));
    expect(text.hitTestable(), findsOneWidget);
    _expectIqText(tester, label, viewport);
    final button = find.ancestor(of: text, matching: find.byType(NeoButton));
    expect(button, findsOneWidget);
    final target = find.descendant(of: button, matching: find.byType(InkWell));
    expect(target.hitTestable(), findsOneWidget);
    if (compact) {
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48), reason: label);
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
    }
  }
}
