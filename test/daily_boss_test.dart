import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/models/player.dart';
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

  Future<GameState> makeState([Map<String, Object> prefs = const {}]) async {
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
    state.dailyChallengeIds = ['blitz_15', 'streak_7', 'division_10'];
    addTearDown(state.dispose);
    return state;
  }

  String questionSignature(Question q) =>
      '${q.type.name}|${q.diff?.name}|${q.numType?.name}|${q.key}|${q.text}|'
      '${q.ans}|${q.choices.join(',')}';

  Future<void> answerCorrect(GameState state, WidgetTester tester) async {
    state.onAnswer(state.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1300));
  }

  Future<void> beatDailyBoss(GameState state, WidgetTester tester) async {
    final boss = state.rt.dailyBoss!;
    for (var i = 0; i < boss.goal; i++) {
      await answerCorrect(state, tester);
    }
  }

  void expectBoss(DailyBoss boss, Map<String, Object> expected) {
    expect(boss.name, expected['name']);
    expect(boss.icon, expected['icon']);
    expect(boss.type, expected['type']);
    expect(boss.diff, expected['diff']);
    expect(boss.goal, expected['goal']);
    expect(boss.time, expected['time']);
    expect(boss.numType, expected['numType']);
    expect(boss.reward, expected['reward']);
    expect(boss.theme, expected['theme']);
    expect(boss.desc, expected['desc']);
  }

  group('RT-008 Daily Boss deterministic identity with fresh questions', () {
    test('boss roster matches original six-boss source list', () async {
      expect(GameConfig.dailyBosses.length, 6);

      final expected = [
        {
          'name': 'Lava Dragon',
          'icon': '🐲',
          'type': 'mixed',
          'diff': 'medium',
          'goal': 12,
          'time': 9,
          'numType': 'integers',
          'reward': 50,
          'theme': 'atm-cave',
          'desc': 'Hot integer problems with no mercy.',
        },
        {
          'name': 'Clockwork Sphinx',
          'icon': '🦁',
          'type': 'multiplication',
          'diff': 'hard',
          'goal': 10,
          'time': 8,
          'numType': 'natural',
          'reward': 45,
          'theme': 'atm-ruins',
          'desc': 'Fast multiplication in ancient gears.',
        },
        {
          'name': 'Frost Kraken',
          'icon': '🐙',
          'type': 'division',
          'diff': 'medium',
          'goal': 10,
          'time': 9,
          'numType': 'rationals',
          'reward': 55,
          'theme': 'atm-ocean',
          'desc': 'Decimal division from the deep.',
        },
        {
          'name': 'Storm Golem',
          'icon': '🗿',
          'type': 'subtraction',
          'diff': 'hard',
          'goal': 12,
          'time': 8,
          'numType': 'integers',
          'reward': 50,
          'theme': 'atm-mountain',
          'desc': 'Negative numbers under pressure.',
        },
        {
          'name': 'Solar Phoenix',
          'icon': '🔥',
          'type': 'addition',
          'diff': 'hard',
          'goal': 14,
          'time': 7,
          'numType': 'rationals',
          'reward': 60,
          'theme': 'atm-vault',
          'desc': 'Decimal addition at sunrise.',
        },
        {
          'name': 'Nebula Hydra',
          'icon': '🐉',
          'type': 'mixed',
          'diff': 'hard',
          'goal': 15,
          'time': 7,
          'numType': 'mixed',
          'reward': 65,
          'theme': 'atm-space',
          'desc': 'A mixed-operation boss from the stars.',
        },
      ];

      for (var i = 0; i < expected.length; i++) {
        expectBoss(GameConfig.dailyBosses[i], expected[i]);
      }
    });

    test('same date always produces the same boss', () async {
      final state = await makeState();
      final date = DateTime(2026, 7, 3);

      final first = state.debugGenerateDailyBoss(date);
      final second = state.debugGenerateDailyBoss(date);

      expect(first.name, 'Frost Kraken');
      expect(second.name, first.name);
      expect(second.icon, first.icon);
      expect(second.type, first.type);
      expect(second.diff, first.diff);
      expect(second.goal, first.goal);
      expect(second.time, first.time);
      expect(second.numType, first.numType);
      expect(second.reward, first.reward);
    });

    test('known source-hash dates produce expected boss rotation', () async {
      final state = await makeState();

      final expectedByDate = {
        DateTime(2026, 6, 27): 'Clockwork Sphinx',
        DateTime(2026, 6, 28): 'Lava Dragon',
        DateTime(2026, 6, 29): 'Nebula Hydra',
        DateTime(2026, 7, 3): 'Frost Kraken',
        DateTime(2026, 7, 4): 'Storm Golem',
        DateTime(2026, 7, 5): 'Solar Phoenix',
      };

      for (final entry in expectedByDate.entries) {
        expect(state.debugGenerateDailyBoss(entry.key).name, entry.value);
      }
    });

    test('boss identity stays fixed during retries while questions change',
        () async {
      final state = await makeState();
      final boss = state.debugGenerateDailyBoss(DateTime(2026, 7, 3));
      state.dailyBoss = boss;

      state.startDailyBoss();
      state.startGame();
      final firstBoss = state.rt.dailyBoss!;
      final firstQuestions = <String>[questionSignature(state.rt.q!)];
      for (var i = 0; i < 3; i++) {
        state.rt.timer?.cancel();
        state.startDailyBoss();
        state.startGame();
        firstQuestions.add(questionSignature(state.rt.q!));
      }

      expect(firstBoss.name, boss.name);
      expect(firstBoss.icon, boss.icon);
      expect(firstBoss.type, boss.type);
      expect(firstBoss.diff, boss.diff);
      expect(firstBoss.goal, boss.goal);
      expect(firstBoss.numType, boss.numType);
      expect(firstQuestions.toSet().length, greaterThan(1));
    });

    test('Daily Boss starts with 3 hearts', () async {
      final state = await makeState();
      state.dailyBoss = GameConfig.dailyBosses.first;

      state.startDailyBoss();
      state.startGame();

      expect(state.rt.dailyBossLives, 3);
    });

    testWidgets('reward can be claimed only once per local day',
        (tester) async {
      final state = await makeState();
      const boss = DailyBoss(
        name: 'Test Boss',
        icon: '🐲',
        type: 'addition',
        diff: 'easy',
        goal: 1,
        time: 10,
        numType: 'natural',
        reward: 50,
        theme: 'test',
        desc: 'Fast deterministic reward test.',
      );
      state.dailyBoss = boss;

      state.startDailyBoss();
      state.startGame();
      await beatDailyBoss(state, tester);

      expect(state.rt.dailyBossWon, isTrue);
      expect(state.coins, boss.reward);
      expect(state.isDailyBossClaimedToday, isTrue);
      expect(Storage.getString('mc_dailyBossClaimed', ''), isNotEmpty);

      state.startDailyBoss();
      state.startGame();
      await beatDailyBoss(state, tester);

      expect(state.rt.dailyBossWon, isTrue);
      expect(state.coins, boss.reward);
    });
  });
}
