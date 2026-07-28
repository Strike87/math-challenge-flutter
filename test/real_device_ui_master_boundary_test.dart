import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/game_screen.dart' as game_screen;
import 'package:math_challenge/screens/numtype_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
    final headings = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Baloo2-ExtraBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Black.ttf'));
    final body = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'));
    await headings.load();
    await body.load();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  testWidgets('real-device Number Type header stays on one line',
      (tester) async {
    final state = await _makeState();

    await _pumpScreen(
      tester,
      state,
      const NumTypeScreen(),
      size: const Size(360, 800),
    );

    expect(find.text('Number Type'), findsOneWidget);
    expect(find.text('Choose Number Type'), findsNothing);
    expect(find.text('Pick your number world'), findsOneWidget);
    expect(find.text('Natural Numbers'), findsOneWidget);
    expect(find.text('Integers'), findsOneWidget);
    expect(find.text('Rationals / Decimals'), findsOneWidget);
    _expectSingleLine(tester, find.text('Number Type'), 'Number Type');
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('real-device Adaptive Difficulty row keeps title and toggle',
      (tester) async {
    final state = await _makeState();
    final wasAdaptive = state.adaptive;

    await _pumpScreen(
      tester,
      state,
      const ConfigScreen(),
      size: const Size(360, 800),
    );

    final title = find.text('Adaptive Difficulty');
    expect(title, findsOneWidget);
    expect(
      find.text('Automatically adjusts the challenge to your skill level'),
      findsOneWidget,
    );
    expect(find.byType(Switch), findsOneWidget);
    _expectSingleLine(tester, title, 'Adaptive Difficulty');
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(state.adaptive, !wasAdaptive);
    state.dispose();
  });

  testWidgets('Stage 1 final feedback remains Stage 1 at its canonical goal',
      (tester) async {
    final state = await _makeState();
    final stage = GameConfig.masterLevels.first;
    final next = GameConfig.masterLevels[1];

    state.debugSetMasterStage(0);
    state.startGame();
    for (var i = 0; i < stage.goal - 1; i++) {
      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));
    }

    await _pumpScreen(
      tester,
      state,
      const game_screen.GameScreen(),
      size: const Size(390, 844),
    );
    expect(state.masterProgress, stage.goal - 1);
    expect(find.text('Stage 1'), findsOneWidget);
    expect(find.text('${stage.goal - 1}/${stage.goal}'), findsOneWidget);

    state.onAnswer(state.rt.q!.ans);
    await tester.pump();

    expect(state.masterLevel, 0);
    expect(state.currentMasterLevel, same(stage));
    expect(state.masterProgress, stage.goal);
    expect(find.text('Stage 1'), findsOneWidget);
    expect(find.text('${stage.goal}/${stage.goal}'), findsOneWidget);
    expect(find.text('Stage 2'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1250));
    expect(state.currentModal, GameModal.stageCleared);
    expect(state.clearedMasterLevel, same(stage));
    expect(state.nextMasterLevel, same(next));
    expect(state.masterLevel, 0);

    state.advanceStage();
    await tester.pump();
    expect(state.masterLevel, 1);
    expect(state.currentMasterLevel, same(next));
    expect(state.masterProgress, 0);
    expect(state.rt.q!.boss, next.boss);
    expect(find.text('Stage 2'), findsOneWidget);
    expect(find.text('0/${next.goal}'), findsOneWidget);
    state.dispose();
  });

  testWidgets('later Master boundary survives wrong and timeout outcomes',
      (tester) async {
    final state = await _makeState();
    final stageIndex = 1;
    final stage = GameConfig.masterLevels[stageIndex];
    final next = GameConfig.masterLevels[stageIndex + 1];

    state.debugSetMasterStage(stageIndex);
    state.startGame();
    for (var i = 0; i < stage.goal - 1; i++) {
      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1300));
    }

    final wrong = state.rt.q!.choices.firstWhere(
      (choice) => (choice - state.rt.q!.ans).abs() > 1e-9,
    );
    state.onAnswer(wrong);
    expect(state.masterLevel, stageIndex);
    expect(state.masterProgress, stage.goal - 1);
    await tester.pump(const Duration(milliseconds: 1300));

    state.debugTimeoutForTest();
    expect(state.masterLevel, stageIndex);
    expect(state.masterProgress, stage.goal - 1);
    await tester.pump(const Duration(milliseconds: 1300));

    state.onAnswer(state.rt.q!.ans);
    expect(state.masterLevel, stageIndex);
    expect(state.currentMasterLevel, same(stage));
    expect(state.masterProgress, stage.goal);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1250));
    expect(state.clearedMasterLevel, same(stage));
    expect(state.nextMasterLevel, same(next));

    state.advanceStage();
    expect(state.masterLevel, stageIndex + 1);
    expect(state.currentMasterLevel, same(next));
    expect(state.masterProgress, 0);
    expect(state.rt.q!.boss, next.boss);
    state.dispose();
  });
}

void _expectSingleLine(
  WidgetTester tester,
  Finder finder,
  String text,
) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(boxes.map((box) => box.top).toSet(), hasLength(1));
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

Future<void> _pumpScreen(
  WidgetTester tester,
  GameState state,
  Widget screen, {
  required Size size,
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
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pump();
}
