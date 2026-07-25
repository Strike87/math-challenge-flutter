import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RT-020 shield animation parity', () {
    testWidgets(
        'shield activation shows pulsing HUD overlay and static player indicator',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);
      await _pumpGame(tester, state);

      expect(find.byKey(const Key('powerup-shield-button')), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      final armedState = await _makeState();
      _startStandard(armedState);
      armedState.p[1].pups = [PowerUp.shield];
      await _pumpGame(tester, armedState);
      expect(find.byKey(const Key('powerup-shield-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('powerup-shield-button')));
      await tester.pump();

      expect(armedState.p[1].shieldActive, isTrue);
      expect(armedState.p[1].pups.where((p) => p == PowerUp.shield), isEmpty);
      expect(find.byKey(const Key('player-card-shield-active-p1')),
          findsOneWidget);
      expect(
          find.byKey(const Key('player-card-shield-active-p2')), findsNothing);
      expect(find.byKey(const Key('shield-hud-armed-overlay')), findsOneWidget);
      expect(find.text('🛡️ Shield activated!'), findsNothing);
      final initial = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      expect(initial.opacity, 0);
      await tester.pump(const Duration(milliseconds: 700));
      final peak = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      expect(peak.opacity, closeTo(1.0, 0.01));
      await tester.pump(const Duration(milliseconds: 700));
      final end = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      expect(end.opacity, closeTo(0, 0.01));
      armedState.rt.timer?.cancel();
      state.rt.timer?.cancel();
    });

    testWidgets('wrong answer consumes shield and shows absorb overlay',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);

      await _pumpGame(tester, state);
      expect(find.byKey(const Key('player-card-shield-active-p1')),
          findsOneWidget);

      final livesBefore = state.rt.survivalLives;
      state.onAnswer(_wrongChoices(state).first);
      await tester.pump();

      expect(state.p[1].shieldActive, isFalse);
      expect(state.rt.survivalLives, livesBefore);
      expect(state.reactionPill, '🛡️ Shield absorbed it!');
      expect(state.bigEmoji, '🛡️');
      expect(state.bigEmojiVisible, isTrue);
      expect(
          find.byKey(const Key('player-card-shield-active-p1')), findsNothing);
      expect(find.byKey(const Key('shield-hud-armed-overlay')), findsNothing);
      expect(find.text('🛡️ Shield absorbed it!'), findsOneWidget);
      final pill = tester.widget<Text>(find.text('🛡️ Shield absorbed it!'));
      expect(pill.style?.color, const Color(GameConfig.mint));
      await tester.pump(const Duration(milliseconds: 1400));
      state.rt.timer?.cancel();
    });

    testWidgets('question counter waits for the next question', (tester) async {
      final state = await _makeState();
      _startStandard(state);
      await _pumpGame(tester, state);

      expect(find.text('Q 1 / 10'), findsOneWidget);

      state.onAnswer(_wrongChoices(state).first);
      await tester.pump();
      expect(find.text('Q 1 / 10'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('Q 2 / 10'), findsOneWidget);
      state.rt.timer?.cancel();
    });

    testWidgets('two player question counter uses per-player progress',
        (tester) async {
      final state = await _makeState();
      _startTwoPlayerStandard(state);
      await _pumpGame(tester, state);

      expect(state.rt.maxTurns, 20);
      expect(state.rt.activePlayer, 1);
      expect(find.text('Q 1 / 10'), findsOneWidget);

      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(state.rt.activePlayer, 2);
      expect(find.text('Q 1 / 10'), findsOneWidget);

      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(state.rt.activePlayer, 1);
      expect(find.text('Q 2 / 10'), findsOneWidget);

      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(state.rt.activePlayer, 2);
      expect(find.text('Q 2 / 10'), findsOneWidget);
      expect(state.rt.gameActive, isTrue);

      for (var turn = 3; turn < 20; turn++) {
        state.onAnswer(state.rt.q!.ans);
        if (turn < 19) {
          await tester.pump(const Duration(milliseconds: 1300));
        }
      }
      expect(state.rt.totalTurns, 20);
      expect(state.rt.state, 'ending');
      state.dispose();
    });

    testWidgets('two player cards use shared motion durations', (tester) async {
      final cases = [
        (
          name: 'normal',
          animSpeed: 1.0,
          reduceMotion: false,
          platform: false,
          expected: const Duration(milliseconds: 200)
        ),
        (
          name: 'low performance',
          animSpeed: 0.3,
          reduceMotion: false,
          platform: false,
          expected: const Duration(milliseconds: 60)
        ),
        (
          name: 'manual reduce motion',
          animSpeed: 1.0,
          reduceMotion: true,
          platform: false,
          expected: Duration.zero
        ),
        (
          name: 'platform reduce motion',
          animSpeed: 1.0,
          reduceMotion: false,
          platform: true,
          expected: Duration.zero
        ),
      ];

      for (final testCase in cases) {
        final state = await _makeState(
          animSpeed: testCase.animSpeed,
          lowPerf: testCase.animSpeed == 0.3,
          reduceMotion: testCase.reduceMotion,
          platformReduceMotion: testCase.platform,
        );
        _startTwoPlayerStandard(state);
        await _pumpGame(tester, state);

        final scales = tester
            .widgetList<AnimatedScale>(find.byType(AnimatedScale))
            .where((widget) => widget.child is AnimatedOpacity)
            .toList();
        expect(scales, hasLength(2), reason: testCase.name);
        for (final scale in scales) {
          final opacity = scale.child as AnimatedOpacity;
          final container = opacity.child as AnimatedContainer;
          expect(scale.duration, testCase.expected, reason: testCase.name);
          expect(opacity.duration, testCase.expected, reason: testCase.name);
          expect(container.duration, testCase.expected, reason: testCase.name);
        }
        state.rt.timer?.cancel();
      }
    });

    testWidgets('boss and shield floating honor motion speed and static modes',
        (tester) async {
      final animatedCases = [
        (name: 'normal', animSpeed: 1.0, quarter: 750),
        (name: 'fast', animSpeed: 0.3, quarter: 225),
        (name: 'slow', animSpeed: 2.0, quarter: 1500),
      ];

      for (final testCase in animatedCases) {
        final state = await _makeState(animSpeed: testCase.animSpeed);
        _startDailyBossWithShield(state);
        await _pumpGame(tester, state);

        await tester.pump(Duration(milliseconds: testCase.quarter));
        final offsets = _nonZeroVerticalTranslations(tester);
        expect(offsets, hasLength(2), reason: testCase.name);
        for (final offset in offsets) {
          expect(offset, closeTo(-4.5, 0.01), reason: testCase.name);
        }
        state.rt.timer?.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final staticCases = [
        (
          name: 'manual reduce motion',
          reduceMotion: true,
          lowPerf: false,
          platform: false
        ),
        (
          name: 'platform reduce motion',
          reduceMotion: false,
          lowPerf: false,
          platform: true
        ),
        (
          name: 'low performance',
          reduceMotion: false,
          lowPerf: true,
          platform: false
        ),
      ];

      for (final testCase in staticCases) {
        final state = await _makeState(
          animSpeed: 0.3,
          lowPerf: testCase.lowPerf,
          reduceMotion: testCase.reduceMotion,
          platformReduceMotion: testCase.platform,
        );
        _startDailyBossWithShield(state);
        await _pumpGame(tester, state);

        await tester.pump(const Duration(milliseconds: 750));
        expect(_nonZeroVerticalTranslations(tester), isEmpty,
            reason: testCase.name);
        state.rt.timer?.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('skip and timeout do not consume an armed shield',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);

      state.skip();
      expect(state.p[1].shieldActive, isTrue);

      await tester.pump(const Duration(milliseconds: 1400));
      state.rt.timer?.cancel();
      state.rt.accepting = true;
      state.debugTimeoutForTest();

      expect(state.p[1].shieldActive, isTrue);
      await tester.pump(const Duration(milliseconds: 1400));
      state.rt.timer?.cancel();
    });

    testWidgets('reduce motion keeps a static armed indicator and absorb pill',
        (tester) async {
      final state = await _makeState(reduceMotion: true);
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);

      await _pumpGame(tester, state);
      expect(find.byKey(const Key('shield-hud-armed-overlay')), findsOneWidget);
      final before = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final after = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      expect(after.opacity, before.opacity);
      state.onAnswer(_wrongChoices(state).first);
      await tester.pump();

      expect(state.p[1].shieldActive, isFalse);
      expect(find.byKey(const Key('shield-hud-armed-overlay')), findsNothing);
      expect(find.text('🛡️ Shield absorbed it!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1400));
      state.rt.timer?.cancel();
    });

    testWidgets('performance mode keeps the armed shield highlight static',
        (tester) async {
      final state = await _makeState(lowPerf: true);
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);

      await _pumpGame(tester, state);
      final before = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      await tester.pump(const Duration(milliseconds: 700));
      final after = tester.widget<Opacity>(
        find.byKey(const Key('shield-hud-armed-overlay')),
      );
      expect(after.opacity, before.opacity);
      state.rt.timer?.cancel();
    });
  });
}

Future<GameState> _makeState({
  bool reduceMotion = false,
  bool lowPerf = false,
  double animSpeed = 1,
  bool platformReduceMotion = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: lowPerf,
      reduceMotion: reduceMotion,
      animSpeed: animSpeed,
    );
  settings.setPlatformReduceMotion(platformReduceMotion);
  final state = GameState(settings: settings, audio: AudioService(settings));
  await state.load();
  addTearDown(state.dispose);
  return state;
}

void _startStandard(GameState state) {
  state.players = 1;
  state.mode = GameMode.standard;
  state.rt.challenge = Operation.addition;
  state.questionCount = 10;
  state.adaptive = false;
  state.startGame();
}

void _startTwoPlayerStandard(GameState state) {
  state.players = 2;
  state.mode = GameMode.standard;
  state.rt.challenge = Operation.addition;
  state.questionCount = 10;
  state.adaptive = false;
  state.startGame();
}

void _startDailyBossWithShield(GameState state) {
  state.dailyBoss = GameConfig.dailyBosses.first;
  state.startDailyBoss();
  state.startGame();
  state.p[1].shieldActive = true;
}

Future<void> _pumpGame(WidgetTester tester, GameState state) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
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

List<double> _nonZeroVerticalTranslations(WidgetTester tester) {
  return tester
      .widgetList<Transform>(find.byType(Transform))
      .map((transform) => transform.transform.getTranslation().y)
      .where((offset) => offset.abs() > 0.01)
      .toList();
}

List<num> _wrongChoices(GameState state) {
  final q = state.rt.q!;
  return q.choices.where((choice) => (choice - q.ans).abs() >= 1e-9).toList();
}
