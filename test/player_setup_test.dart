import 'dart:ui';

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

    testWidgets('keeps setup controls reachable with keyboard open',
        (tester) async {
      final state = await _makeState();
      state.setOption('players', 1);

      await tester.pumpWidget(_host(state, keyboardInset: 240));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byKey(const Key('player-setup-name-p1')), findsOneWidget);
      expect(find.byKey(const Key('player-setup-primary')), findsOneWidget);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'avatar controls support native keyboard and mouse for Player 1',
        (tester) async {
      final state = await _makeState();
      state.setOption('players', 1);
      await tester.pumpWidget(_host(state));
      await tester.pump();
      final player2InitialAvatar = state.p[2].avatar.storageEmoji;

      final avatarTile = find.byKey(const Key('player-setup-avatar-tile-p1'));
      final avatarTileInkWell = find.descendant(
        of: avatarTile,
        matching: find.byType(InkWell),
      );
      expect(
        tester.widget<InkWell>(avatarTileInkWell).borderRadius,
        BorderRadius.circular(18),
      );
      final back = find.byKey(const Key('player-setup-back'));
      final backIcon = find.descendant(of: back, matching: find.byType(Icon));
      Focus.of(tester.element(backIcon)).requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(
        Focus.of(tester.element(find.text('Tap to change'))).hasFocus,
        isTrue,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(Focus.of(tester.element(backIcon)).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(state.builderPid, 1);
      expect(find.text('Pick your avatar'), findsOneWidget);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Pick your avatar'), findsOneWidget);

      final close = find.byIcon(Icons.close_rounded);
      Focus.of(tester.element(close)).requestFocus();
      for (var i = 0; i < 7; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      final cat = find.descendant(
        of: find.byType(GridView),
        matching: find.text('🐱'),
      );
      expect(Focus.of(tester.element(cat)).hasPrimaryFocus, isTrue);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(state.p[1].avatar.storageEmoji, '🐱');
      expect(state.p[2].avatar.storageEmoji, player2InitialAvatar);
      expect(find.text('Pick your avatar'), findsNothing);

      final quickPicks = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(InkWell),
      );
      final quickPick = quickPicks.at(1);
      expect(
        tester.widget<InkWell>(quickPick).borderRadius,
        BorderRadius.circular(18),
      );
      Focus.of(tester.element(find.text('Tap to change'))).requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(state.p[1].avatar.storageEmoji, state.availableAvatarBases[0]);
      expect(state.p[2].avatar.storageEmoji, player2InitialAvatar);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(state.p[1].avatar.storageEmoji, state.availableAvatarBases[0]);
      final mouse = TestPointer(2, PointerDeviceKind.mouse);
      final center = tester.getCenter(quickPick);
      await tester.sendEventToBinding(mouse.hover(center));
      await tester.sendEventToBinding(mouse.down(center));
      await tester.sendEventToBinding(mouse.up());
      await tester.pump();
      expect(state.p[1].avatar.storageEmoji, state.availableAvatarBases[1]);
      await tester.sendEventToBinding(mouse.removePointer());
      expect(tester.takeException(), isNull);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Avatar Picker Escape keeps the existing avatar unchanged',
        (tester) async {
      final state = await _makeState();
      state.setOption('players', 1);
      final before = state.p[1].avatar.storageEmoji;
      await tester.pumpWidget(_host(state));
      await tester.pump();

      await tester.tap(find.byKey(const Key('player-setup-avatar-tile-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Pick your avatar'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, isNotNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Pick your avatar'), findsNothing);
      expect(state.p[1].avatar.storageEmoji, before);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
      state.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('LU-1A.3 responsive Player Setup matrix', () {
    for (final testCase in const [
      (
        label: 'small phone portrait',
        size: Size(320, 568),
        textScale: 1.3,
      ),
    ]) {
      testWidgets('1P remains usable on ${testCase.label}', (tester) async {
        final state = await _makeState();
        addTearDown(state.dispose);
        addTearDown(() => state.rt.timer?.cancel());
        state.setOption('players', 1);

        await _pumpPlayerSetup(
          tester,
          state,
          size: testCase.size,
          textScale: testCase.textScale,
        );

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byKey(const Key('player-setup-name-p1')), findsOneWidget);
        expect(
          find.byKey(const Key('player-setup-avatar-tile-p1')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('player-setup-section-p2')), findsNothing);
        final start = find.byKey(const Key('player-setup-primary'));
        await tester.ensureVisible(start);
        expect(tester.takeException(), isNull);
        await tester.tap(start);
        await tester.pump();

        expect(state.rt.gameActive, isTrue);
        state.rt.timer?.cancel();
        expect(tester.takeException(), isNull);
      });
    }

    for (final testCase in const [
      (
        label: 'phone landscape',
        size: Size(844, 390),
        textScale: 1.3,
      ),
      (
        label: 'narrow split-screen',
        size: Size(500, 900),
        textScale: 2.0,
      ),
      (
        label: 'wide split-screen',
        size: Size(900, 700),
        textScale: 1.0,
      ),
    ]) {
      testWidgets('2P remains usable on ${testCase.label}', (tester) async {
        final state = await _makeState();
        addTearDown(state.dispose);
        addTearDown(() => state.rt.timer?.cancel());
        state
          ..setOption('players', 2)
          ..currentScreen = GameScreen.player;

        await _pumpPlayerSetup(
          tester,
          state,
          size: testCase.size,
          textScale: testCase.textScale,
        );

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text('Player 1 Setup'), findsOneWidget);
        final player1Name = find.byKey(const Key('player-setup-name-p1'));
        final player1Avatar =
            find.byKey(const Key('player-setup-avatar-tile-p1'));
        final player1Customize =
            find.byKey(const Key('player-setup-customize-p1'));
        for (final control in [
          player1Name,
          player1Avatar,
          player1Customize,
        ]) {
          await tester.ensureVisible(control);
        }
        await tester.enterText(player1Name, 'Ada');
        final primary = find.byKey(const Key('player-setup-primary'));
        await tester.ensureVisible(primary);
        await tester.tap(primary);
        await tester.pump();

        expect(find.text('Player 2 Setup'), findsOneWidget);
        final player2Name = find.byKey(const Key('player-setup-name-p2'));
        final player2Avatar =
            find.byKey(const Key('player-setup-avatar-tile-p2'));
        final player2Customize =
            find.byKey(const Key('player-setup-customize-p2'));
        for (final control in [
          player2Name,
          player2Avatar,
          player2Customize,
        ]) {
          await tester.ensureVisible(control);
        }
        await tester.enterText(player2Name, 'Ben');
        final back = find.byKey(const Key('player-setup-back'));
        await tester.ensureVisible(back);
        await tester.tap(back);
        await tester.pump();

        expect(find.text('Player 1 Setup'), findsOneWidget);
        expect(state.p[1].name, 'Ada');
        expect(state.p[2].name, 'Ben');
        await tester.ensureVisible(primary);
        await tester.tap(primary);
        await tester.pump();
        expect(find.text('Player 2 Setup'), findsOneWidget);
        await tester.ensureVisible(primary);
        await tester.tap(primary);
        await tester.pump();

        expect(state.p[1].name, 'Ada');
        expect(state.p[2].name, 'Ben');
        expect(state.rt.gameActive, isTrue);
        state.rt.timer?.cancel();
        expect(tester.takeException(), isNull);
      });
    }
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

Future<void> _pumpPlayerSetup(
  WidgetTester tester,
  GameState state, {
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: state),
        ChangeNotifierProvider<SettingsService>.value(value: state.settings),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(
            resizeToAvoidBottomInset: false,
            body: PlayerSetupScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
