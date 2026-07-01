import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
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

  group('RT-030 modal behavioral content parity', () {
    testWidgets(
        'Daily Boss modal mirrors source mission, rules, reward, status',
        (tester) async {
      final state = await _makeState();
      try {
        const boss = DailyBoss(
          name: 'Nebula Hydra',
          icon: '🐉',
          type: 'mixed',
          diff: 'hard',
          goal: 15,
          time: 7,
          numType: 'rationals',
          reward: 65,
          theme: 'atm-space',
          desc: 'A mixed-operation boss from the stars.',
        );
        state.dailyBoss = boss;
        state.showModal(GameModal.dailyBoss);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Nebula Hydra'), findsOneWidget);
        expect(find.text('A mixed-operation boss from the stars.'),
            findsOneWidget);
        expect(find.text('Mixed Operations'), findsOneWidget);
        expect(find.text('Hard'), findsOneWidget);
        expect(find.text('Rationals'), findsOneWidget);
        expect(find.text('15 correct answers'), findsOneWidget);
        expect(find.text('3 hearts'), findsOneWidget);
        expect(find.text('7s each'), findsOneWidget);
        expect(find.text('65 coins'), findsOneWidget);
        expect(find.text('Ready to fight'), findsOneWidget);
        expect(find.text("Fight Today's Boss"), findsOneWidget);

        await Storage.setString('mc_dailyBossClaimed', _todayKey());
        state.isDailyBossClaimedToday = true;
        state.showModal(GameModal.dailyBoss);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Reward claimed today'), findsOneWidget);
        expect(
            find.text('Cleared today. Replay for practice.'), findsOneWidget);
        expect(find.text("Fight Today's Boss"), findsOneWidget);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Master intro feels like an adventure briefing',
        (tester) async {
      final state = await _makeState();
      try {
        state.showModal(GameModal.masterIntro);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Adventure Briefing'), findsOneWidget);
        expect(
          find.text(
            'Cross the map, defeat every boss, and unlock the treasure vault.',
          ),
          findsOneWidget,
        );
        expect(find.text('5 stages'), findsOneWidget);
        expect(find.text('Beat each boss'), findsOneWidget);
        expect(find.text('3 hearts'), findsOneWidget);
        expect(find.text('I am Ready! 🗡️'), findsOneWidget);
        for (var i = 0; i < GameConfig.masterLevels.length; i++) {
          expect(
            find.text('${i + 1} ${GameConfig.masterLevels[i].boss}'),
            findsOneWidget,
          );
        }
      } finally {
        state.dispose();
      }
    });

    testWidgets('Stage Cleared modal uses stage-specific victory story',
        (tester) async {
      final state = await _makeState();
      try {
        final stage = GameConfig.masterLevels.first;
        final next = GameConfig.masterLevels[1];
        state.debugSetMasterStage(0);
        state.startGame();

        for (var i = 0; i < stage.goal; i++) {
          state.onAnswer(state.rt.q!.ans);
          if (i < stage.goal - 1) {
            await tester.pump(const Duration(milliseconds: 1300));
          }
        }

        expect(state.currentModal, GameModal.stageCleared);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('${stage.name} Cleared! 🌟'), findsOneWidget);
        expect(find.text(stage.story), findsOneWidget);
        expect(find.text('Enter ${next.name} →'), findsOneWidget);
        expect(find.textContaining('Next'), findsNothing);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Win modal reports source-style single-player rows',
        (tester) async {
      final state = await _makeState();
      try {
        state.players = 1;
        state.p[1]
          ..name = 'Player 1'
          ..score = 123
          ..correct = 7
          ..total = 10
          ..skipped = 1
          ..bonus = 18
          ..maxStreak = 5
          ..timeMs = 23456;
        state.resultIcon = '🌟';
        state.resultTitle = 'Great Job!';
        state.resultDescription = 'Final Score: 123';
        state.showModal(GameModal.win);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text("Player 1's Report"), findsOneWidget);
        for (final label in [
          'Final Score',
          'Accuracy',
          '✓ Correct',
          '✗ Wrong',
          'Skipped',
          'Time Bonus',
          'Best Streak',
          'Avg Time',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.text('123'), findsOneWidget);
        expect(find.text('70%'), findsOneWidget);
        expect(find.text('18pts'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Win modal reports source-style two-player comparison',
        (tester) async {
      final state = await _makeState();
      try {
        state.players = 2;
        state.p[1]
          ..name = 'Ada'
          ..score = 40
          ..correct = 4
          ..total = 5
          ..skipped = 0
          ..timeMs = 5000;
        state.p[2]
          ..name = 'Ben'
          ..score = 30
          ..correct = 3
          ..total = 5
          ..skipped = 1
          ..timeMs = 7500;
        state.resultIcon = '🏆';
        state.resultTitle = 'Ada Wins! 🏆';
        state.resultDescription = '40 – 30';
        state.showModal(GameModal.win);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        for (final label in [
          'Stat',
          'Ada',
          'Ben',
          'Score',
          'Accuracy',
          '✓ Correct',
          '✗ Wrong',
          'Skipped',
          'Avg Time',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
      } finally {
        state.dispose();
      }
    });

    testWidgets('Daily Boss result copy separates first reward from replay',
        (tester) async {
      final state = await _makeState();
      try {
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
          desc: 'Reward test.',
        );
        state.dailyBoss = boss;

        state.startDailyBoss();
        state.startGame();
        state.onAnswer(state.rt.q!.ans);
        await tester.pump(const Duration(milliseconds: 1300));

        expect(state.resultDescription, 'Daily reward claimed: +50 coins');
        expect(state.coins, 50);

        state.startDailyBoss();
        state.startGame();
        state.onAnswer(state.rt.q!.ans);
        await tester.pump(const Duration(milliseconds: 1300));

        expect(
          state.resultDescription,
          "Cleared again for practice. Today's reward was already claimed.",
        );
        expect(state.coins, 50);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Avatar Builder saves selected parts to the targeted player',
        (tester) async {
      final state = await _makeState();
      try {
        state.players = 2;
        state.showAvatarBuilder(1);
        state.setBuilderBase('🐱');
        state.setBuilderHat('🎓');
        state.setBuilderAccessory('👓');
        state.setBuilderColor('#FF6B6B');
        state.saveCustomAvatar();

        final p1 = state.p[1].avatar as AvatarCustom;
        expect(p1.base, '🐱');
        expect(p1.hat, '🎓');
        expect(p1.accessory, '👓');
        expect(p1.color, '#FF6B6B');
        expect(state.avatarCustom['1'], isA<AvatarCustom>());
        expect(state.p[2].avatar, isNot(isA<AvatarCustom>()));
        expect(state.currentModal, GameModal.none);

        state.showAvatarBuilder(2);
        state.setBuilderBase('🐸');
        state.saveCustomAvatar();

        final p2 = state.p[2].avatar as AvatarCustom;
        expect(p2.base, '🐸');
        expect((state.p[1].avatar as AvatarCustom).base, '🐱');
      } finally {
        state.dispose();
      }
    });

    testWidgets('Avatar Builder cancel does not mutate unrelated state',
        (tester) async {
      final state = await _makeState();
      try {
        state.p[1].avatar = '🐶';
        state.showAvatarBuilder(1);
        state.setBuilderBase('🐱');
        state.closeModal();

        expect(state.p[1].avatar, '🐶');
        expect(state.avatarCustom['1']?.base, isNot('🐱'));
        expect(state.currentModal, GameModal.none);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Coin Shop local tabs and placeholders match modal scope',
        (tester) async {
      final state = await _makeState();
      try {
        state.coins = 0;
        state.showModal(GameModal.coinShop);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Coin Shop'), findsOneWidget);
        expect(find.text('0 coins'), findsOneWidget);
        for (final label in ['Items', 'Boosts', 'Coins']) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.text('AVATARS'), findsOneWidget);
        expect(find.text('HATS'), findsOneWidget);
        expect(find.text('Dragon'), findsOneWidget);
        expect(find.text('Robot'), findsOneWidget);

        await tester.ensureVisible(find.text('Coins'));
        await tester.tap(find.text('Coins'));
        await tester.pumpAndSettle();

        expect(find.text('Watch a Short Ad'), findsOneWidget);
        expect(find.text('100 Coins'), findsOneWidget);
        expect(find.text('500 Coins'), findsOneWidget);
        expect(find.text('1200 Coins'), findsOneWidget);
        expect(find.text('Remove Ads'), findsOneWidget);
        expect(find.text('Restore Purchases'), findsNothing);
        expect(
          find.textContaining('Payments processed securely via Google Play.'),
          findsOneWidget,
        );
      } finally {
        state.dispose();
      }
    });

    testWidgets('closing non-purchase modals does not mutate unrelated state',
        (tester) async {
      final state = await _makeState();
      try {
        state.coins = 123;
        state.shopOwned.add('existing');
        final ownedBefore = Set<String>.from(state.shopOwned);

        state.showModal(GameModal.coinShop);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        await tester.tap(find.text('Done'));
        await tester.pump();

        expect(state.currentModal, GameModal.none);
        expect(state.coins, 123);
        expect(state.shopOwned, ownedBefore);

        const boss = DailyBoss(
          name: 'Safe Boss',
          icon: '🐲',
          type: 'addition',
          diff: 'easy',
          goal: 1,
          time: 10,
          numType: 'natural',
          reward: 50,
          theme: 'test',
          desc: 'Cancel test.',
        );
        state.dailyBoss = boss;
        state.showModal(GameModal.dailyBoss);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        await tester.tap(find.text('Cancel'));
        await tester.pump();

        expect(state.currentModal, GameModal.none);
        expect(state.rt.challenge, isNot(Operation.dailyBoss));
      } finally {
        state.dispose();
      }
    });

    testWidgets('modal shell remains scrollable on compact viewports',
        (tester) async {
      final state = await _makeState();
      try {
        state.showModal(GameModal.coinShop);
        await tester.pumpWidget(
          _modalHost(state, size: const Size(320, 520)),
        );
        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsWidgets);
        expect(tester.takeException(), isNull);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Daily Challenges uses real date badge instead of static emoji',
        (tester) async {
      final state = await _makeState();
      try {
        await tester.pumpWidget(
          _dailyChallengesHost(state, DateTime(2026, 7, 1)),
        );
        await tester.pump();

        expect(find.text('Jul'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('17'), findsNothing);
        expect(find.text('📅'), findsNothing);
      } finally {
        state.dispose();
      }
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
  state.dailyChallengeIds = ['blitz_15', 'streak_7', 'division_10'];
  return state;
}

Widget _modalHost(GameState state, {Size size = const Size(390, 700)}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameState>.value(value: state),
      ChangeNotifierProvider<SettingsService>.value(value: state.settings),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const Scaffold(
          body: Stack(
            children: [
              ModalRouter(),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _dailyChallengesHost(GameState state, DateTime today) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameState>.value(value: state),
      ChangeNotifierProvider<SettingsService>.value(value: state.settings),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: DailyChallengesModal(gs: state, today: today),
      ),
    ),
  );
}

String _todayKey() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}
