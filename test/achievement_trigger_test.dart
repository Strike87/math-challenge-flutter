import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';
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

  Future<GameState> makeState({bool resetPrefs = true}) async {
    if (resetPrefs) {
      SharedPreferences.setMockInitialValues({});
    }
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
    return state;
  }

  Future<void> answerCorrect(GameState state, WidgetTester tester) async {
    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1300));
  }

  Future<void> finishOneQuestionGame(
    GameState state,
    WidgetTester tester,
  ) async {
    state.players = 1;
    state.mode = GameMode.standard;
    state.adaptive = false;
    state.questionCount = 1;
    state.rt.challenge = Operation.addition;
    state.startGame();
    await answerCorrect(state, tester);
  }

  group('RT-004 achievement triggers', () {
    testWidgets('skill_master uses source count and mastery condition',
        (tester) async {
      final confidenceOnly = await makeState();
      try {
        confidenceOnly.skillMap[Operation.subtraction.name] = SkillData(
          count: 4,
          mastery: 100,
          confidence: 100,
        );
        await finishOneQuestionGame(confidenceOnly, tester);
        expect(confidenceOnly.achievements['skill_master'], isFalse);
      } finally {
        confidenceOnly.dispose();
      }

      final sourceMatch = await makeState();
      try {
        sourceMatch.skillMap[Operation.subtraction.name] = SkillData(
          count: 5,
          mastery: 90,
          confidence: 0,
        );
        await finishOneQuestionGame(sourceMatch, tester);
        expect(sourceMatch.achievements['skill_master'], isTrue);
      } finally {
        sourceMatch.dispose();
      }
    });

    testWidgets('speed_demon unlocks after 5 fast answers', (tester) async {
      final state = await makeState();
      try {
        state.players = 1;
        state.mode = GameMode.standard;
        state.adaptive = false;
        state.questionCount = 5;
        state.rt.challenge = Operation.addition;
        state.startGame();

        for (var i = 0; i < 5; i++) {
          await answerCorrect(state, tester);
        }

        expect(state.rt.fastAnswers, 5);
        expect(state.achievements['speed_demon'], isTrue);
      } finally {
        state.dispose();
      }
    });

    testWidgets('perfect_score unlocks for 100 percent game accuracy',
        (tester) async {
      final state = await makeState();
      try {
        await finishOneQuestionGame(state, tester);

        expect(state.p[1].total, 1);
        expect(state.p[1].correct, 1);
        expect(state.achievements['perfect_score'], isTrue);
      } finally {
        state.dispose();
      }
    });

    test('daily_grind unlocks after 3 completed daily challenges', () async {
      final state = await makeState();
      try {
        state.dailyChallengeIds = ['blitz_15', 'streak_7', 'division_10'];

        state.debugUpdateDailyProgressAbsolute('blitz_15', 15);
        state.debugUpdateDailyProgressAbsolute('streak_7', 7);
        state.debugUpdateDailyProgressAbsolute('division_10', 10);

        expect(state.achievements['daily_grind'], isTrue);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Math Wizard unlocks after clearing Master Stage 3',
        (tester) async {
      final state = await makeState();
      try {
        final stageIndex = 2;
        final stage = GameConfig.masterLevels[stageIndex];
        state.debugSetMasterStage(stageIndex);
        state.startGame();

        for (var i = 0; i < stage.goal; i++) {
          await answerCorrect(state, tester);
        }

        expect(state.achievements['math_wizard'], isTrue);
        expect(state.achievements['math_legend'], isFalse);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Math Legend unlocks after final Master stage', (tester) async {
      final state = await makeState();
      try {
        final stageIndex = GameConfig.masterLevels.length - 1;
        final stage = GameConfig.masterLevels[stageIndex];
        state.debugSetMasterStage(stageIndex);
        state.startGame();

        for (var i = 0; i < stage.goal; i++) {
          await answerCorrect(state, tester);
        }

        expect(state.achievements['math_legend'], isTrue);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Daily Boss unlocks after defeating a daily boss',
        (tester) async {
      final state = await makeState();
      try {
        final boss = GameConfig.dailyBosses.first;
        state.dailyBoss = boss;
        state.startDailyBoss();
        state.startGame();

        for (var i = 0; i < boss.goal; i++) {
          await answerCorrect(state, tester);
        }

        expect(state.rt.dailyBossWon, isTrue);
        expect(state.achievements['daily_boss'], isTrue);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Survivor unlocks at 250+ points in Death mode',
        (tester) async {
      final state = await makeState();
      try {
        state.players = 1;
        state.mode = GameMode.death;
        state.rt.challenge = Operation.addition;
        state.startGame();
        state.p[1].score = 250;

        final q = state.rt.q!;
        final wrong = q.choices.firstWhere((choice) => choice != q.ans);
        state.onAnswer(wrong);
        await tester.pump(const Duration(milliseconds: 1300));

        expect(state.achievements['survivor'], isTrue);
      } finally {
        state.dispose();
      }
    });

    testWidgets('high scores stay mutable, sorted, trimmed, and persisted',
        (tester) async {
      final state = await makeState();
      try {
        expect(state.highScores, isEmpty);

        await finishOneQuestionGame(state, tester);

        expect(state.highScores.length, 1);
        expect(state.highScores.single.score, greaterThan(0));

        state.highScores = List.generate(
          10,
          (i) => HighScore(
            name: 'P$i',
            score: i + 1,
            mode: 'standard',
            date: '2026-06-27',
          ),
        );

        await finishOneQuestionGame(state, tester);
        await state.save();

        expect(state.highScores.length, 10);
        expect(state.highScores.first.score,
            greaterThan(state.highScores.last.score));
        expect(state.highScores.any((score) => score.score == 1), isFalse);

        final persistedScores = state.highScores.map((s) => s.score).toList();
        final reloaded = await makeState(resetPrefs: false);
        try {
          expect(reloaded.highScores.map((s) => s.score), persistedScores);
        } finally {
          reloaded.dispose();
        }
      } finally {
        state.dispose();
      }
    });
  });
}
