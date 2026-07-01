import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/celebration.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/celebration_overlay.dart';
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

  group('RT-020 feedback, emoji, audio, and haptics', () {
    testWidgets('correct and wrong answers set source-style feedback state',
        (tester) async {
      final correct = await _makeState();
      try {
        _startStandard(correct);

        correct.onAnswer(correct.rt.q!.ans);

        expect(correct.bigEmojiVisible, isTrue);
        expect(_correctEmojiSet, contains(correct.bigEmoji));
        expect(correct.reactionPill, contains('+'));
        expect(correct.rt.selectedAnswer, correct.rt.q!.ans);
        expect(correct.rt.lastAnswerCorrect, isTrue);
        await tester.pump(const Duration(milliseconds: 899));
        expect(correct.bigEmojiVisible, isTrue);
        await tester.pump(const Duration(milliseconds: 1));
        expect(correct.bigEmojiVisible, isFalse);
        expect(correct.reactionPill, isNotEmpty);
        await tester.pump(const Duration(milliseconds: 400));
        expect(correct.reactionPill, isEmpty);
      } finally {
        correct.dispose();
      }

      final wrong = await _makeState();
      try {
        _startStandard(wrong);

        final wrongChoice = wrong.rt.q!.choices.firstWhere(
          (choice) => (choice - wrong.rt.q!.ans).abs() > 1e-9,
        );
        wrong.onAnswer(wrongChoice);

        expect(wrong.bigEmojiVisible, isTrue);
        expect(_wrongEmojiSet, contains(wrong.bigEmoji));
        expect(wrong.reactionPill, contains('Ans:'));
        expect(wrong.rt.selectedAnswer, wrongChoice);
        expect(wrong.rt.lastAnswerCorrect, isFalse);
        await tester.pump(const Duration(milliseconds: 900));
        expect(wrong.bigEmojiVisible, isFalse);
        await tester.pump(const Duration(milliseconds: 400));
      } finally {
        wrong.dispose();
      }
    });

    testWidgets(
        'new games clear cached reaction emoji and stale turn callbacks',
        (tester) async {
      final state = await _makeState();
      try {
        _startStandard(state);
        final wrongChoice = state.rt.q!.choices.firstWhere(
          (choice) => (choice - state.rt.q!.ans).abs() > 1e-9,
        );
        state.onAnswer(wrongChoice);

        expect(state.bigEmojiVisible, isTrue);
        expect(state.reactionPill, isNotEmpty);

        _startStandard(state);
        expect(state.bigEmojiVisible, isFalse);
        expect(state.bigEmoji, isEmpty);
        expect(state.reactionPill, isEmpty);

        await tester.pump(const Duration(milliseconds: 1400));
        expect(state.rt.gameActive, isTrue);
      } finally {
        state.dispose();
      }
    });

    test('master and daily boss wrong answers switch boss mood', () async {
      final master = await _makeState();
      try {
        master.debugSetMasterStage(0);
        master.startGame();
        final wrongChoice = master.rt.q!.choices.firstWhere(
          (choice) => (choice - master.rt.q!.ans).abs() > 1e-9,
        );

        master.onAnswer(wrongChoice);

        expect(master.rt.bossMood, 'wrong');
      } finally {
        master.dispose();
      }

      final daily = await _makeState();
      try {
        daily.dailyBoss = GameConfig.dailyBosses.first;
        daily.startDailyBoss();
        daily.startGame();
        final wrongChoice = daily.rt.q!.choices.firstWhere(
          (choice) => (choice - daily.rt.q!.ans).abs() > 1e-9,
        );

        daily.onAnswer(wrongChoice);

        expect(daily.rt.bossMood, 'wrong');
      } finally {
        daily.dispose();
      }
    });

    testWidgets('wrong answer shake is gated by reduce motion', (tester) async {
      final normal = await _makeState(reduceMotion: false);
      try {
        _startStandard(normal);
        final wrongChoice = normal.rt.q!.choices.firstWhere(
          (choice) => (choice - normal.rt.q!.ans).abs() > 1e-9,
        );
        normal.onAnswer(wrongChoice);
        expect(normal.screenShakeTick, greaterThan(0));
        await tester.pump(const Duration(milliseconds: 1300));
      } finally {
        normal.dispose();
      }

      final reduced = await _makeState(reduceMotion: true);
      try {
        _startStandard(reduced);
        final wrongChoice = reduced.rt.q!.choices.firstWhere(
          (choice) => (choice - reduced.rt.q!.ans).abs() > 1e-9,
        );
        reduced.onAnswer(wrongChoice);
        expect(reduced.screenShakeTick, 0);
        await tester.pump(const Duration(milliseconds: 1300));
      } finally {
        reduced.dispose();
      }
    });

    testWidgets('win, stage, daily-boss, and survival-boss celebrations fire',
        (tester) async {
      final win = await _makeState();
      try {
        _startStandard(win, questionCount: 1);
        win.onAnswer(win.rt.q!.ans);

        expect(win.celebration.kind, CelebrationKind.perfect);
        expect(win.celebration.message, 'Perfect score!');
      } finally {
        win.dispose();
      }

      final master = await _makeState();
      try {
        final stage = GameConfig.masterLevels.first;
        master.debugSetMasterStage(0);
        master.startGame();

        for (var i = 0; i < stage.goal; i++) {
          master.onAnswer(master.rt.q!.ans);
          if (i < stage.goal - 1) {
            await tester.pump(const Duration(milliseconds: 1300));
          }
        }

        expect(master.currentModal, GameModal.stageCleared);
        expect(master.celebration.kind, CelebrationKind.stageClear);
        expect(master.celebration.message, 'Stage cleared!');
      } finally {
        master.dispose();
      }

      final dailyBoss = await _makeState();
      try {
        final boss = GameConfig.dailyBosses.first;
        dailyBoss.dailyBoss = boss;
        dailyBoss.startDailyBoss();
        dailyBoss.startGame();

        for (var i = 0; i < boss.goal; i++) {
          dailyBoss.onAnswer(dailyBoss.rt.q!.ans);
          if (i < boss.goal - 1) {
            await tester.pump(const Duration(milliseconds: 1300));
          }
        }

        expect(dailyBoss.rt.dailyBossWon, isTrue);
        expect(dailyBoss.celebration.kind, CelebrationKind.bossClear);
        expect(dailyBoss.celebration.message, 'Daily Boss defeated!');
      } finally {
        dailyBoss.dispose();
      }

      final survival = await _makeState();
      try {
        survival.players = 1;
        survival.mode = GameMode.survival;
        survival.rt.challenge = Operation.addition;
        survival.startGame();

        for (var i = 0; i < 10; i++) {
          survival.onAnswer(survival.rt.q!.ans);
          if (i < 9) {
            await tester.pump(const Duration(milliseconds: 1300));
          }
        }

        expect(survival.rt.survivalCorrect, 10);
        expect(survival.celebration.kind, CelebrationKind.bossClear);
        expect(survival.celebration.message, 'BOSS DOWN! +5🪙');
        await tester.pump(const Duration(milliseconds: 1300));
      } finally {
        survival.dispose();
      }
    });

    test('big emoji overlay is owned by answers grid, not question card', () {
      final source = File('lib/screens/game_screen.dart').readAsStringSync();
      final answersGrid = _classBlock(source, '_AnswersGrid');
      final questionCard = _classBlock(source, '_QuestionCard');

      expect(answersGrid, contains('BigEmojiOverlay'));
      expect(questionCard, isNot(contains('BigEmojiOverlay')));
    });

    testWidgets('reduce motion and low performance skip confetti paths',
        (tester) async {
      final normal = await _makeState(lowPerf: false, reduceMotion: false);
      try {
        await tester.pumpWidget(_overlayHost(normal));
        normal.unlockAch('first_win');
        await tester.pumpWidget(_overlayHost(normal));
        await tester.pump();

        expect(find.text('First Victory unlocked!'), findsOneWidget);
        expect(find.byType(ConfettiWidget), findsOneWidget);
      } finally {
        normal.dispose();
      }

      final reduceMotion = await _makeState(lowPerf: false, reduceMotion: true);
      try {
        await tester.pumpWidget(_overlayHost(reduceMotion));
        reduceMotion.unlockAch('first_win');
        await tester.pumpWidget(_overlayHost(reduceMotion));
        await tester.pump();

        expect(find.text('First Victory unlocked!'), findsOneWidget);
        expect(find.byType(ConfettiWidget), findsNothing);
      } finally {
        reduceMotion.dispose();
      }

      final lowPerf = await _makeState(lowPerf: true, reduceMotion: false);
      try {
        await tester.pumpWidget(_overlayHost(lowPerf));
        lowPerf.unlockAch('first_win');
        await tester.pumpWidget(_overlayHost(lowPerf));
        await tester.pump();

        expect(find.text('First Victory unlocked!'), findsOneWidget);
        expect(find.byType(ConfettiWidget), findsNothing);
      } finally {
        lowPerf.dispose();
      }
    });

    test('sound and vibration toggles gate service calls', () async {
      var audioCalls = 0;
      var hapticCalls = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMethodCallHandler(audioGlobalChannel, (_) async {
        audioCalls++;
        return null;
      });
      messenger.setMockMethodCallHandler(audioPlayerChannel, (_) async {
        audioCalls++;
        return null;
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') hapticCalls++;
        return null;
      });

      final state = await _makeState(sound: false, vibration: false);
      try {
        audioCalls = 0;
        hapticCalls = 0;

        await state.audio.playCorrect();
        await state.audio.playWrong();
        state.audio.vibrateCorrect();
        state.audio.vibrateWrong();
        state.audio.vibratePattern([50, 30, 50]);
        state.audio.vibratePowerUp();

        expect(audioCalls, 0);
        expect(state.audio.debugVibrationCount, 0);
        expect(hapticCalls, 0);
      } finally {
        state.dispose();
        messenger.setMockMethodCallHandler(
            audioGlobalChannel, (_) async => null);
        messenger.setMockMethodCallHandler(
            audioPlayerChannel, (_) async => null);
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      }
    });

    test('correct and wrong sounds plus haptics fire when toggles are on',
        () async {
      final state = await _makeState(sound: true, vibration: true);
      try {
        await state.audio.playCorrect();
        await state.audio.playWrong();
        state.audio.vibrateCorrect();
        state.audio.vibrateWrong();

        expect(state.audio.debugTonePlayCount, 2);
        expect(state.audio.debugVibrationCount, 2);
      } finally {
        state.dispose();
      }
    });

    testWidgets('achievement and reward feedback queue instead of stacking',
        (tester) async {
      final state = await _makeState();
      void listener() {}
      try {
        state.addListener(listener);
        state.showToast('First message');
        state.showToast('Second message');
        state.showToast('Third message');

        expect(state.toastVisible, isTrue);
        expect(state.toastMessage, 'First message');

        await tester.pump(const Duration(milliseconds: 2400));
        expect(state.toastVisible, isTrue);
        expect(state.toastMessage, 'Second message');

        await tester.pump(const Duration(milliseconds: 2400));
        expect(state.toastVisible, isTrue);
        expect(state.toastMessage, 'Third message');

        await tester.pump(const Duration(milliseconds: 2400));
        expect(state.toastVisible, isFalse);
      } finally {
        state.removeListener(listener);
        state.dispose();
      }
    });
  });
}

Set<String> get _correctEmojiSet =>
    GameConfig.correctRx.map((rx) => rx.split(' ').first).toSet();

Set<String> get _wrongEmojiSet =>
    GameConfig.wrongRx.map((rx) => rx.split(' ').first).toSet();

Future<GameState> _makeState({
  bool sound = false,
  bool vibration = false,
  bool lowPerf = true,
  bool reduceMotion = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();

  final settings = SettingsService()
    ..load(
      dark: false,
      sound: sound,
      vibration: vibration,
      dyslexia: false,
      colorblind: false,
      lowPerf: lowPerf,
      reduceMotion: reduceMotion,
      animSpeed: 1.0,
    );
  final state = GameState(settings: settings, audio: AudioService(settings));
  await state.load();
  state.dailyChallengeIds = ['blitz_15', 'streak_7', 'division_10'];
  return state;
}

void _startStandard(GameState state, {int questionCount = 10}) {
  state.players = 1;
  state.mode = GameMode.standard;
  state.adaptive = false;
  state.questionCount = questionCount;
  state.rt.challenge = Operation.addition;
  state.startGame();
}

Widget _overlayHost(GameState state) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          CelebrationOverlay(state: state, settings: state.settings),
        ],
      ),
    ),
  );
}

String _classBlock(String source, String className) {
  final start = source.indexOf('class $className');
  expect(start, isNonNegative, reason: 'Expected to find $className');
  final next = source.indexOf('\nclass ', start + 1);
  return source.substring(start, next == -1 ? source.length : next);
}
