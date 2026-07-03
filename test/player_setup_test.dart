import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/screens/player_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
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

  group('UI-POLISH-007 two-step Player Setup', () {
    testWidgets('1P shows Player 1 only and starts directly', (tester) async {
      final state = await _makeState();
      state.setOption('players', 1);

      await tester.pumpWidget(_host(state));
      await tester.pump();

      expect(find.text('Player Setup'), findsOneWidget);
      expect(find.byKey(const Key('player-setup-section-p1')), findsOneWidget);
      expect(find.byKey(const Key('player-setup-section-p2')), findsNothing);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Next'), findsNothing);

      await tester.tap(find.byKey(const Key('player-setup-primary')));
      await tester.pump();

      expect(state.rt.gameActive, isTrue);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('2P config steps through Player 1 then Player 2',
        (tester) async {
      final state = await _makeState();
      state.setOption('players', 2);
      state.currentScreen = GameScreen.player;

      await tester.pumpWidget(_host(state));
      await tester.pump();

      expect(find.text('Player 1 Setup'), findsOneWidget);
      expect(find.byKey(const Key('player-setup-section-p1')), findsOneWidget);
      expect(find.byKey(const Key('player-setup-section-p2')), findsNothing);
      expect(find.text('Next'), findsOneWidget);
      expect(state.isBannerEligibleFor(state.currentScreen), isTrue);

      await tester.enterText(
        find.byKey(const Key('player-setup-name-p1')),
        'Ada',
      );
      await tester.enterText(find.byKey(const Key('player-setup-name-p1')), '');
      expect(state.p[1].name, '');
      await tester.enterText(
        find.byKey(const Key('player-setup-name-p1')),
        'Ada',
      );
      await tester.tap(find.byKey(const Key('player-setup-customize-p1')));
      await tester.pump();
      expect(state.p[1].name, 'Ada');
      expect(state.p[2].name, isNot('Ada'));
      expect(state.builderPid, 1);
      state.closeModal();
      await tester.pump();

      await tester.tap(find.byKey(const Key('player-setup-avatar-tile-p1')));
      await tester.pump();
      expect(state.builderPid, 1);
      expect(find.text('Pick your avatar'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      await tester.tap(find.byKey(const Key('player-setup-primary')));
      await tester.pump();

      expect(find.text('Player 2 Setup'), findsOneWidget);
      expect(find.byKey(const Key('player-setup-section-p1')), findsNothing);
      expect(find.byKey(const Key('player-setup-section-p2')), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
      expect(state.isBannerEligibleFor(state.currentScreen), isTrue);

      await tester.enterText(
        find.byKey(const Key('player-setup-name-p2')),
        'Ben',
      );
      await tester.tap(find.byKey(const Key('player-setup-customize-p2')));
      await tester.pump();
      expect(state.p[1].name, 'Ada');
      expect(state.p[2].name, 'Ben');
      expect(state.builderPid, 2);
      state.closeModal();
      await tester.pump();

      await tester.tap(find.byKey(const Key('player-setup-avatar-tile-p2')));
      await tester.pump();
      expect(state.builderPid, 2);
      expect(find.text('Pick your avatar'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      await tester.tap(find.byKey(const Key('player-setup-back')));
      await tester.pump();
      expect(find.text('Player 1 Setup'), findsOneWidget);
      expect(find.byKey(const Key('player-setup-section-p1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('player-setup-primary')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('player-setup-primary')));
      await tester.pump();

      expect(state.rt.gameActive, isTrue);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('adds keyboard inset to scroll padding', (tester) async {
      final state = await _makeState();
      state.setOption('players', 1);

      await tester.pumpWidget(_host(state, keyboardInset: 240));
      await tester.pump();

      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect((scroll.padding! as EdgeInsets).bottom, 336);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

Future<GameState> _makeState() async {
  SharedPreferences.setMockInitialValues({});
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
  return state;
}

Widget _host(GameState state, {double keyboardInset = 0}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameState>.value(value: state),
      ChangeNotifierProvider<SettingsService>.value(value: state.settings),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: const Scaffold(
          resizeToAvoidBottomInset: false,
          body: PlayerSetupScreen(),
        ),
      ),
    ),
  );
}
