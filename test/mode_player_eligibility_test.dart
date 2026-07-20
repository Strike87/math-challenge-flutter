import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:provider/provider.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  group('RT-041 mode/player eligibility', () {
    test('fresh loaded state uses the Game Setup defaults', () async {
      final state = await _makeState();

      expect(state.players, 1);
      expect(state.setupPlayers, 1);
      expect(state.adaptive, isFalse);
      expect(state.mode, GameMode.standard);
      expect(state.selectedAnswerStyle, AnswerStyle.choice4);
      expect(state.diff, Difficulty.easy);
      expect(state.questionCount, 10);
    });

    // 1. 1P allows Standard, Blitz, Death, Survival, Combo.
    test('1P allows all five modes', () async {
      final state = await _makeState();
      state.setOption('players', 1);

      for (final mode in GameMode.values) {
        state.setOption('mode', mode.name);
        expect(state.mode, mode,
            reason: '1P should allow ${mode.name}');
      }
    });

    // 2. 2P allows Standard only. Restricted modes stay visible but disabled.
    test('2P allows Standard only', () async {
      final state = await _makeState();
      state.setOption('players', 2);

      state.setOption('mode', GameMode.standard.name);
      expect(state.mode, GameMode.standard,
          reason: '2P should allow Standard');

      for (final restricted in GameMode.singlePlayerOnly) {
        state.setOption('mode', restricted.name);
        expect(state.mode, GameMode.standard,
            reason: '2P should reject ${restricted.name}');
      }
    });

    // 3. Switching from 1P restricted mode to 2P resets mode to Standard.
    test('switching 1P restricted mode to 2P resets to Standard', () async {
      final state = await _makeState();
      state.setOption('players', 1);

      for (final restricted in GameMode.singlePlayerOnly) {
        state.setOption('mode', restricted.name);
        expect(state.mode, restricted,
            reason: '1P should keep ${restricted.name}');

        state.setOption('players', 2);
        expect(state.mode, GameMode.standard,
            reason: 'switching to 2P should reset ${restricted.name} to Standard');

        // Reset for next iteration.
        state.setOption('players', 1);
      }
    });

    // 4. setOption('mode', restrictedMode) while players == 2 does not keep
    //    restricted mode — it falls back to Standard.
    test('setOption rejects restricted mode when players == 2', () async {
      final state = await _makeState();
      state.setOption('players', 2);
      state.setOption('mode', GameMode.standard.name);

      for (final restricted in GameMode.singlePlayerOnly) {
        state.setOption('mode', restricted.name);
        expect(state.mode, GameMode.standard,
            reason:
                'setOption should not set ${restricted.name} when players == 2');
      }
    });

    // 5. startGame() blocks corrupted 2P + restricted mode state.
    test('startGame blocks corrupted 2P + restricted mode', () async {
      final state = await _makeState();
      state.rt.challenge = Operation.addition;
      state.questionCount = 10;
      state.adaptive = false;

      for (final restricted in GameMode.singlePlayerOnly) {
        // Directly corrupt state, bypassing setOption.
        state.players = 2;
        state.mode = restricted;

        state.startGame();

        expect(state.mode, GameMode.standard,
            reason:
                'startGame should reset corrupted ${restricted.name} to Standard');
        // startGame should have returned early without entering the game screen.
        expect(state.currentScreen, isNot(GameScreen.game),
            reason:
                'startGame should not proceed to game with corrupted 2P + ${restricted.name}');
      }
    });

    // 6. Standard remains valid for both 1P and 2P.
    test('Standard is valid for 1P and 2P', () async {
      final state = await _makeState();

      state.setOption('players', 1);
      state.setOption('mode', GameMode.standard.name);
      expect(state.mode, GameMode.standard, reason: '1P Standard');

      state.setOption('players', 2);
      expect(state.mode, GameMode.standard,
          reason: '2P should preserve Standard');
      state.setOption('mode', GameMode.standard.name);
      expect(state.mode, GameMode.standard,
          reason: '2P Standard via setOption');
    });

    // Bonus: GameMode.isAvailableForPlayers static helper correctness.
    test('isAvailableForPlayers helper is correct', () {
      expect(GameMode.isAvailableForPlayers(GameMode.standard, 1), isTrue);
      expect(GameMode.isAvailableForPlayers(GameMode.standard, 2), isTrue);

      for (final restricted in GameMode.singlePlayerOnly) {
        expect(GameMode.isAvailableForPlayers(restricted, 1), isTrue,
            reason: '${restricted.name} should be available for 1P');
        expect(GameMode.isAvailableForPlayers(restricted, 2), isFalse,
            reason: '${restricted.name} should not be available for 2P');
      }
    });

    // 7. UI validation for 2P mode tabs.
    testWidgets(
        '2P mode tabs render restricted modes visible, greyed, and disabled',
        (tester) async {
      final state = await _makeState();
      state.setOption('players', 2);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(value: state.settings),
            ChangeNotifierProvider<GameState>.value(value: state),
          ],
          child: MaterialApp(
            home: const Scaffold(
              body: ConfigScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All modes should be visible; restricted modes are greyed/disabled, not hidden.
      expect(find.text('Standard', skipOffstage: false), findsWidgets);
      expect(find.text('Blitz', skipOffstage: false), findsWidgets);
      expect(find.text('Death', skipOffstage: false), findsWidgets);
      expect(find.text('Survival', skipOffstage: false), findsWidgets);
      expect(find.text('Combo', skipOffstage: false), findsWidgets);

      expect(state.mode, GameMode.standard);

      expect(_hasDisabledOpacity('Standard'), isFalse);
      for (final label in ['Blitz', 'Death', 'Survival', 'Combo']) {
        expect(_hasDisabledOpacity(label), isTrue,
            reason: '$label should be visibly greyed in 2P mode');

        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(state.mode, GameMode.standard,
            reason: 'Tapping disabled $label should not change selection');
      }
    });
  });
}

bool _hasDisabledOpacity(String label) {
  return find
      .ancestor(
        of: find.text(label, skipOffstage: false),
        matching: find.byWidgetPredicate(
          (widget) => widget is Opacity && widget.opacity == 0.4,
        ),
      )
      .evaluate()
      .isNotEmpty;
}

Future<GameState> _makeState([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
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
  final state = GameState(settings: settings, audio: AudioService(settings));
  await state.load();
  addTearDown(state.dispose);
  return state;
}
