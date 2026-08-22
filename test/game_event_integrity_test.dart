import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/models/enums.dart';
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

  testWidgets('a question accepts exactly one terminal answer', (tester) async {
    final state = await _makeState();
    _startGame(state);
    final answer = state.rt.q!.ans;

    state.onAnswer(answer);
    state.onAnswer(answer);
    state.debugTimeoutForTest();

    expect(state.p[1].total, 1);
    expect(state.p[1].correct, 1);
    expect(state.rt.totalTurns, 1);
    await _disposeAndDrain(state, tester);
  });

  testWidgets('Switch claims before its delayed replacement', (tester) async {
    final state = await _makeState();
    _startGame(state);
    final oldQuestion = state.rt.q;
    state.p[1].pups = [PowerUp.switchOp];

    state.usePowerUp(PowerUp.switchOp);
    state.onAnswer(oldQuestion!.ans);
    state.debugTimeoutForTest();

    expect(state.rt.accepting, isFalse);
    expect(state.p[1].total, 0);
    expect(state.rt.totalTurns, 0);
    await tester.pump(const Duration(milliseconds: 501));
    expect(state.rt.q, isNot(same(oldQuestion)));
    expect(state.rt.accepting, isTrue);
    await _disposeAndDrain(state, tester);
  });

  testWidgets('a stale Switch callback cannot replace a replay question',
      (tester) async {
    final state = await _makeState();
    _startGame(state);
    state.p[1].pups = [PowerUp.switchOp];
    state.usePowerUp(PowerUp.switchOp);

    await state.replayGame();
    final replayQuestion = state.rt.q;
    await tester.pump(const Duration(milliseconds: 501));

    expect(state.rt.q, same(replayQuestion));
    expect(state.rt.accepting, isTrue);
    expect(state.p[1].total, 0);
    await _disposeAndDrain(state, tester);
  });

  testWidgets('a stale Switch callback cannot replace a new-run question',
      (tester) async {
    final state = await _makeState();
    _startGame(state);
    state.p[1].pups = [PowerUp.switchOp];
    state.usePowerUp(PowerUp.switchOp);

    state.startGame();
    final newRunQuestion = state.rt.q;
    await tester.pump(const Duration(milliseconds: 501));

    expect(state.rt.q, same(newRunQuestion));
    expect(state.rt.accepting, isTrue);
    expect(state.p[1].total, 0);
    await _disposeAndDrain(state, tester);
  });

  testWidgets('a stale Switch callback cannot survive quit', (tester) async {
    final state = await _makeState();
    _startGame(state);
    final oldQuestion = state.rt.q;
    state.p[1].pups = [PowerUp.switchOp];
    state.usePowerUp(PowerUp.switchOp);

    await state.quitToMenu();
    await tester.pump(const Duration(milliseconds: 501));

    expect(state.currentScreen, GameScreen.menu);
    expect(state.rt.q, same(oldQuestion));
    expect(state.rt.accepting, isFalse);
    expect(state.p[1].total, 0);
  });

  testWidgets('a stale Switch callback cannot survive Quest-map return',
      (tester) async {
    final state = await _makeState();
    _startGame(state);
    final oldQuestion = state.rt.q;
    state.p[1].pups = [PowerUp.switchOp];
    state.usePowerUp(PowerUp.switchOp);

    await state.returnToOperationQuestMap();
    await tester.pump(const Duration(milliseconds: 501));

    expect(state.currentScreen, GameScreen.menu);
    expect(state.currentModal, GameModal.operationQuest);
    expect(state.rt.q, same(oldQuestion));
    expect(state.rt.accepting, isFalse);
    expect(state.p[1].total, 0);
  });

  for (final mode in [GameMode.blitz, GameMode.combo]) {
    testWidgets('${mode.name} expiry rejects a late answer', (tester) async {
      final state = await _makeState();
      _startGame(state, mode: mode);
      final expiredQuestion = state.rt.q;
      state.rt.timerStart = DateTime.now().millisecondsSinceEpoch -
          state.rt.timerDurationMs;

      await tester.pump(const Duration(milliseconds: 101));
      expect(state.rt.gameActive, isFalse);
      expect(state.rt.state, 'ended');

      state.onAnswer(expiredQuestion!.ans);
      state.debugTimeoutForTest();
      expect(state.p[1].total, 0);
      expect(state.rt.totalTurns, 0);
      expect(state.gamesPlayed, 1);
    });
  }
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
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
  );
  await state.load();
  addTearDown(state.dispose);
  return state;
}

void _startGame(GameState state, {GameMode mode = GameMode.standard}) {
  state.players = 1;
  state.mode = mode;
  state.adaptive = false;
  state.diff = Difficulty.easy;
  state.rt.challenge = Operation.addition;
  state.startGame();
}

Future<void> _disposeAndDrain(GameState state, WidgetTester tester) async {
  state.dispose();
  await tester.pump(const Duration(seconds: 3));
}
