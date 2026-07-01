import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
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
        'shield activation shows HUD key, player indicator, and feedback',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];

      await _pumpGame(tester, state);
      expect(find.byKey(const Key('powerup-shield-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('powerup-shield-button')));
      await tester.pump();

      expect(state.p[1].shieldActive, isTrue);
      expect(state.p[1].pups.where((p) => p == PowerUp.shield), isEmpty);
      expect(
          find.byKey(const Key('player-card-shield-active')), findsOneWidget);
      expect(find.text('🛡️ Shield activated!'), findsOneWidget);
      state.rt.timer?.cancel();
    });

    testWidgets('wrong answer consumes shield and shows absorb overlay',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);

      await _pumpGame(tester, state);
      expect(
          find.byKey(const Key('player-card-shield-active')), findsOneWidget);

      final livesBefore = state.rt.survivalLives;
      state.onAnswer(_wrongChoices(state).first);
      await tester.pump();

      expect(state.p[1].shieldActive, isFalse);
      expect(state.rt.survivalLives, livesBefore);
      expect(state.reactionPill, '🛡️ Shield absorbed it!');
      expect(find.byKey(const Key('player-card-shield-active')), findsNothing);
      expect(find.byKey(const Key('shield-absorb-overlay')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 720));
      expect(find.byKey(const Key('shield-absorb-overlay')), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      state.rt.timer?.cancel();
    });

    testWidgets('reduce motion still shows a clear absorb indicator',
        (tester) async {
      final state = await _makeState(reduceMotion: true);
      _startStandard(state);
      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);

      await _pumpGame(tester, state);
      state.onAnswer(_wrongChoices(state).first);
      await tester.pump();

      expect(state.p[1].shieldActive, isFalse);
      expect(find.byKey(const Key('shield-absorb-overlay')), findsOneWidget);
      expect(find.text('🛡️ Shield absorbed it!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1400));
      state.rt.timer?.cancel();
    });
  });
}

Future<GameState> _makeState({bool reduceMotion = false}) async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: false,
      reduceMotion: reduceMotion,
      animSpeed: 1,
    );
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

List<num> _wrongChoices(GameState state) {
  final q = state.rt.q!;
  return q.choices.where((choice) => (choice - q.ans).abs() >= 1e-9).toList();
}
