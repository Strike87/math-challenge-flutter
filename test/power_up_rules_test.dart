import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
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

  group('RT-010 power-up rules', () {
    testWidgets('power-ups are granted every 3 correct answers',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);

      expect(state.p[1].pups.length, PowerUp.values.length);

      await _answerCorrect(state, tester);
      await _answerCorrect(state, tester);

      expect(state.p[1].pups.length, PowerUp.values.length);

      await _answerCorrect(state, tester);
      await tester.pump(const Duration(milliseconds: 2600));

      expect(state.p[1].correct, 3);
      expect(state.p[1].pups.length, PowerUp.values.length + 1);
      state.rt.timer?.cancel();
    });

    test(
        'power-ups are limited to single-player non-Master non-Daily-Boss games',
        () async {
      final standard = await _makeState();
      _startStandard(standard);
      expect(standard.p[1].pups, containsAll(PowerUp.values));

      final twoPlayer = await _makeState();
      twoPlayer.players = 2;
      twoPlayer.mode = GameMode.standard;
      twoPlayer.rt.challenge = Operation.addition;
      twoPlayer.startGame();
      expect(twoPlayer.p[1].pups, isEmpty);
      expect(twoPlayer.p[2].pups, isEmpty);

      final master = await _makeState();
      master.players = 1;
      master.mode = GameMode.standard;
      master.rt.challenge = Operation.master;
      master.startGame();
      expect(master.p[1].pups, isEmpty);

      final dailyBoss = await _makeState();
      dailyBoss.players = 1;
      dailyBoss.mode = GameMode.standard;
      dailyBoss.rt.challenge = Operation.dailyBoss;
      dailyBoss.startGame();
      expect(dailyBoss.p[1].pups, isEmpty);
    });

    test('time and freeze are rejected in Blitz and Combo before consuming',
        () async {
      final blitz = await _makeState();
      blitz.players = 1;
      blitz.mode = GameMode.blitz;
      blitz.rt.challenge = Operation.addition;
      blitz.startGame();

      final blitzCount = _count(blitz, PowerUp.time);
      final blitzDuration = blitz.rt.timerDurationMs;
      expect(blitz.isPowerUpBlocked(PowerUp.time), isTrue);
      expect(blitz.isPowerUpBlocked(PowerUp.freeze), isTrue);
      blitz.usePowerUp(PowerUp.time);

      expect(_count(blitz, PowerUp.time), blitzCount);
      expect(blitz.rt.puUsed, 0);
      expect(blitz.rt.timerDurationMs, blitzDuration);

      final combo = await _makeState();
      combo.players = 1;
      combo.mode = GameMode.combo;
      combo.rt.challenge = Operation.addition;
      combo.startGame();

      final comboCount = _count(combo, PowerUp.freeze);
      expect(combo.isPowerUpBlocked(PowerUp.time), isTrue);
      expect(combo.isPowerUpBlocked(PowerUp.freeze), isTrue);
      combo.usePowerUp(PowerUp.freeze);

      expect(_count(combo, PowerUp.freeze), comboCount);
      expect(combo.rt.puUsed, 0);
      expect(combo.rt.frozen, isFalse);
    });

    test('time adds 5000ms to active timer and 5s to qTimerLimit', () async {
      final state = await _makeState();
      _startStandard(state);

      final beforeDuration = state.rt.timerDurationMs;
      final beforeLimit = state.rt.qTimerLimit;
      final beforeCount = _count(state, PowerUp.time);

      state.usePowerUp(PowerUp.time);

      expect(_count(state, PowerUp.time), beforeCount - 1);
      expect(state.rt.timerDurationMs, beforeDuration + 5000);
      expect(state.rt.qTimerLimit, beforeLimit + 5);
      expect(state.rt.puUsed, 1);
    });

    test('fifty removes exactly 2 wrong answers', () async {
      final state = await _makeState();
      _startStandard(state);

      expect(state.rt.q!.choices.length, 4);
      expect(_wrongChoices(state).length, 3);

      state.usePowerUp(PowerUp.fifty);

      expect(state.rt.q!.choices.length, 2);
      expect(_wrongChoices(state).length, 1);
      expect(
        state.rt.q!.choices
            .where((choice) => (choice - state.rt.q!.ans).abs() < 1e-9)
            .length,
        1,
      );
    });

    testWidgets('double doubles this question total points once',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);

      state.p[1].pups = [PowerUp.double];
      state.rt.qTimerLimit = 10;
      state.rt.qStartTs = DateTime.now().millisecondsSinceEpoch;

      state.usePowerUp(PowerUp.double);
      expect(state.p[1].doubleActive, isTrue);

      state.onAnswer(state.rt.q!.ans);
      await tester.pump(const Duration(milliseconds: 1400));

      expect(state.p[1].score, 44);
      expect(state.p[1].bonus, 0);
      expect(state.p[1].doubleActive, isFalse);
      state.rt.timer?.cancel();
    });

    testWidgets(
        'shield absorbs the next non-timeout wrong answer before lives change',
        (tester) async {
      final state = await _makeState();
      state.players = 1;
      state.mode = GameMode.survival;
      state.rt.challenge = Operation.addition;
      state.startGame();

      state.p[1].pups = [PowerUp.shield];
      state.usePowerUp(PowerUp.shield);
      expect(state.p[1].shieldActive, isTrue);

      final wrong = _wrongChoices(state).first;
      state.onAnswer(wrong);

      expect(state.p[1].shieldActive, isFalse);
      expect(state.rt.survivalLives, 3);
      expect(state.reactionPill, '🛡️ Shield absorbed it!');
      expect(state.bigEmoji, '🛡️');
      await tester.pump(const Duration(milliseconds: 1400));
      state.rt.timer?.cancel();
    });

    test('freeze stops the timer and marks frozen state', () async {
      final state = await _makeState();
      _startStandard(state);

      final beforeCount = _count(state, PowerUp.freeze);
      expect(state.rt.timer?.isActive, isTrue);

      state.usePowerUp(PowerUp.freeze);

      expect(_count(state, PowerUp.freeze), beforeCount - 1);
      expect(state.rt.timer?.isActive, isFalse);
      expect(state.rt.frozen, isTrue);
    });

    testWidgets('switch replaces the current question after 500ms',
        (tester) async {
      final state = await _makeState();
      _startStandard(state);

      state.p[1].pups = [PowerUp.switchOp];
      final oldKey = state.rt.q!.key;

      state.usePowerUp(PowerUp.switchOp);

      expect(state.rt.q!.key, oldKey);
      await tester.pump(const Duration(milliseconds: 499));
      expect(state.rt.q!.key, oldKey);
      await tester.pump(const Duration(milliseconds: 2));

      expect(state.rt.q!.key, isNot(oldKey));
      expect(state.rt.accepting, isTrue);
      state.rt.timer?.cancel();
    });

    test('Power Pack grants +5 of every power-up type per purchase', () async {
      final state = await _makeState({'mc_coins': 1000});
      final pack = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_powerups');

      await state.buyShopItem(pack);
      await state.buyShopItem(pack);

      final bonus = jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
      for (final storageKey in [
        'time',
        'fifty',
        'double',
        'shield',
        'freeze',
        'switch'
      ]) {
        expect(bonus[storageKey], 10, reason: storageKey);
      }
      expect(state.coins, 0);
    });
  });
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

void _startStandard(GameState state) {
  state.players = 1;
  state.mode = GameMode.standard;
  state.rt.challenge = Operation.addition;
  state.questionCount = 20;
  state.adaptive = false;
  state.startGame();
}

Future<void> _answerCorrect(GameState state, WidgetTester tester) async {
  state.onAnswer(state.rt.q!.ans);
  await tester.pump(const Duration(milliseconds: 1400));
}

int _count(GameState state, PowerUp pu) {
  return state.p[1].pups.where((candidate) => candidate == pu).length;
}

List<num> _wrongChoices(GameState state) {
  final q = state.rt.q!;
  return q.choices.where((choice) => (choice - q.ans).abs() >= 1e-9).toList();
}
