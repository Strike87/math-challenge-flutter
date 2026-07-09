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
  const linkChannel = MethodChannel('math_challenge/link_launcher');

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(linkChannel, null);
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
        expect(find.text('🪙 65'), findsOneWidget);
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
        expect(find.text('Quest:'), findsOneWidget);
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

    testWidgets('Settings Performance mode subtitle is separated',
        (tester) async {
      final state = await _makeState();
      try {
        state.showModal(GameModal.settings);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Performance mode'), findsOneWidget);
        expect(find.text('faster on all devices'), findsOneWidget);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Settings support links open and report failure',
        (tester) async {
      final state = await _makeState();
      final opened = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(linkChannel, (call) async {
        opened.add((call.arguments as Map)['url'] as String);
        return opened.length == 1;
      });
      try {
        state.showModal(GameModal.settings);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Support / About'), findsOneWidget);
        expect(find.text('support@mathchallenge.me'), findsOneWidget);
        expect(find.text('mathchallenge.me'), findsOneWidget);

        await tester.ensureVisible(find.text('mathchallenge.me'));
        await tester.pump();
        await tester.tap(find.text('mathchallenge.me'));
        await tester.pump();
        expect(opened.single, 'https://mathchallenge.me');

        await tester.ensureVisible(find.text('support@mathchallenge.me'));
        await tester.pump();
        await tester.tap(find.text('support@mathchallenge.me'));
        await tester.pump();
        expect(opened.last, 'mailto:support@mathchallenge.me');
        expect(state.toastMessage, 'Could not open link.');
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(linkChannel, null);
        state.dispose();
      }
    });

    testWidgets('Settings performance toggle preserves modal scroll offset',
        (tester) async {
      final state = await _makeState();
      try {
        state.showModal(GameModal.settings);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        final scrollable = find.byType(Scrollable).first;
        final beforeState = tester.state<ScrollableState>(scrollable);
        await tester.drag(scrollable, const Offset(0, -260));
        await tester.pump();
        final before = beforeState.position.pixels;

        await tester.tap(find.byType(Checkbox).at(2));
        await tester.pump();

        final after = tester.state<ScrollableState>(scrollable).position.pixels;
        expect(after, closeTo(before, 1));
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

        expect(state.currentModal, GameModal.none);
        await tester.pump(const Duration(milliseconds: 1300));
        expect(state.currentModal, GameModal.none);
        await tester.pump(const Duration(milliseconds: 1250));
        expect(state.currentModal, GameModal.stageCleared);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('${stage.name} Cleared! 🌟'), findsOneWidget);
        expect(find.text(stage.story), findsOneWidget);
        expect(find.text('Enter ${next.name}'), findsOneWidget);
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

    testWidgets('Daily Boss report hides replay only after a win',
        (tester) async {
      final state = await _makeState();
      try {
        state.players = 1;
        state.rt.challenge = Operation.dailyBoss;
        state.rt.dailyBossWon = true;
        state.resultTitle = 'Boss Defeated!';
        state.showModal(GameModal.win);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Replay'), findsNothing);
        expect(find.text('Main Menu'), findsOneWidget);

        state.rt.dailyBossWon = false;
        state.showModal(GameModal.win);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Replay'), findsOneWidget);
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
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        expect(find.text('Player 1 Avatar'), findsOneWidget);
        expect(find.text('👤 Player 1'), findsNothing);
        expect(find.text('👤 Player 2'), findsNothing);

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
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        expect(find.text('Player 2 Avatar'), findsOneWidget);
        expect(find.text('👤 Player 1'), findsNothing);
        expect(find.text('👤 Player 2'), findsNothing);

        state.setBuilderBase('🐸');
        state.saveCustomAvatar();

        final p2 = state.p[2].avatar as AvatarCustom;
        expect(p2.base, '🐸');
        expect((state.p[1].avatar as AvatarCustom).base, '🐱');

        state.showAvatarBuilder(1);
        expect(state.builderAvatar.base, '🐱');
        expect(state.builderAvatar.hat, '🎓');
        expect(state.builderAvatar.accessory, '👓');
        expect(state.builderAvatar.color, '#FF6B6B');
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

    testWidgets(
        'Avatar Builder keeps preview and tabs fixed above picker grids',
        (tester) async {
      final state = await _makeState();
      try {
        state.showAvatarBuilder(1);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.byKey(const Key('avatar-builder-preview')), findsOneWidget);
        expect(find.byKey(const Key('avatar-builder-tabs')), findsOneWidget);
        expect(find.byKey(const Key('avatar-builder-picker')), findsOneWidget);
        expect(find.byKey(const Key('avatar-base-grid')), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('None'), findsNothing);
        expect(find.text('🚫'), findsWidgets);

        await tester.tap(find.text('Hat'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('avatar-hat-grid')), findsOneWidget);
        await tester.tap(find.text('🚫').first);
        await tester.pumpAndSettle();
        expect(state.builderAvatar.hat, '');

        await tester.tap(find.text('Accessory'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('avatar-accessory-grid')), findsOneWidget);
        await tester.tap(find.text('🚫').first);
        await tester.pumpAndSettle();
        expect(state.builderAvatar.accessory, '');

        await tester.tap(find.text('Color'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('avatar-color-grid')), findsOneWidget);
        expect(find.text('None'), findsNothing);
        await tester.tap(find.text('🚫').first);
        await tester.pumpAndSettle();
        expect(state.builderAvatar.color, isNull);
        expect(tester.takeException(), isNull);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Coin Shop hub opens focused shop sections', (tester) async {
      final state = await _makeState();
      try {
        state.coins = 0;
        state.showModal(GameModal.coinShop);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        expect(find.text('Coin Shop'), findsOneWidget);
        expect(find.text('0 coins'), findsNothing);
        expect(find.text('Not enough'), findsNothing);
        for (final label in ['Avatars', 'Hats', 'Packs', 'Buy']) {
          expect(find.text(label), findsOneWidget);
        }
        for (final subtitle in [
          'Choose your character',
          'Customize your look',
          'Power-ups and daily rewards',
          'Coins and remove ads',
        ]) {
          expect(find.text(subtitle), findsNothing);
        }

        await tester.tap(find.byKey(const Key('shopHub_avatars')));
        await tester.pumpAndSettle();
        expect(find.text('AVATARS'), findsOneWidget);
        expect(find.text('Dragon'), findsOneWidget);
        expect(find.text('Robot'), findsOneWidget);
        expect(find.text('🪙 300'), findsOneWidget);
        expect(find.text('🪙 200'), findsWidgets);
        expect(find.text('Not enough'), findsNothing);
        await tester.tap(find.text('Dragon'));
        await tester.pumpAndSettle();
        expect(state.shopOwned, isNot(contains('av_dragon')));
        expect(state.toastMessage, isNot('Not enough 🪙'));
        await tester.tap(find.byKey(const Key('shopBackToHub')));
        await tester.pumpAndSettle();
        expect(find.text('Not enough'), findsNothing);

        await tester.tap(find.byKey(const Key('shopHub_hats')));
        await tester.pumpAndSettle();
        expect(find.text('HATS'), findsOneWidget);
        expect(find.text('Top Hat'), findsOneWidget);
        expect(find.text('🪙 100'), findsOneWidget);
        expect(find.text('Not enough'), findsNothing);
        await tester.tap(find.text('Top Hat'));
        await tester.pumpAndSettle();
        expect(state.shopOwned, isNot(contains('hat_cap')));
        expect(state.toastMessage, isNot('Not enough 🪙'));
        await tester.tap(find.byKey(const Key('shopBackToHub')));
        await tester.pumpAndSettle();
        expect(find.text('Not enough'), findsNothing);

        await tester.tap(find.byKey(const Key('shopHub_packs')));
        await tester.pumpAndSettle();
        expect(find.text('PACKS'), findsOneWidget);
        expect(find.text('Power Pack'), findsOneWidget);
        expect(find.text('Extra Life'), findsOneWidget);
        expect(find.text('+20 Coins'), findsOneWidget);
        expect(find.textContaining('x5 of each power-up'), findsOneWidget);
        expect(find.textContaining('For Master mode'), findsOneWidget);
        expect(find.text('🪙 500'), findsOneWidget);
        expect(find.text('🪙 450'), findsOneWidget);
        expect(find.textContaining('Daily bonus'), findsOneWidget);
        expect(find.text('Free Daily'), findsOneWidget);
        expect(find.text('Not enough'), findsNothing);
        expect(state.coins, 0);
        expect(state.toastMessage, isNot('Not enough 🪙'));
        await tester.tap(find.byKey(const Key('shopBackToHub')));
        await tester.pumpAndSettle();
        expect(find.text('Not enough'), findsNothing);

        await tester.ensureVisible(find.byKey(const Key('shopHub_buy')));
        await tester.tap(find.byKey(const Key('shopHub_buy')));
        await tester.pumpAndSettle();
        expect(find.text('BUY'), findsOneWidget);
        expect(find.text('Watch Ad'), findsOneWidget);
        expect(find.text('Watch a Short Ad'), findsNothing);
        expect(find.text('Free coins - no purchase needed'), findsNothing);
        expect(find.text('+10 🪙'), findsOneWidget);
        expect(find.text('100 Coins'), findsOneWidget);
        expect(find.text('500 Coins'), findsOneWidget);
        expect(find.text('1200 Coins'), findsOneWidget);
        expect(find.text('Remove Ads'), findsOneWidget);
        expect(find.text('Price unavailable'), findsWidgets);
        expect(find.text(r'$0.99'), findsNothing);
        expect(find.text(r'$3.99'), findsNothing);
        expect(find.text(r'$7.99'), findsNothing);
        expect(find.text(r'$1.99'), findsNothing);
        expect(find.text('Restore Purchases'), findsNothing);
        expect(find.text('Not enough'), findsNothing);
        expect(
          find.textContaining('Payments processed securely via Google Play.'),
          findsOneWidget,
        );
      } finally {
        state.dispose();
      }
    });

    testWidgets('Coin Shop affordable avatar and hat cards omit buy pills',
        (tester) async {
      final state = await _makeState();
      try {
        state.coins = 1000;
        state.showModal(GameModal.coinShop);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        await tester.tap(find.byKey(const Key('shopHub_avatars')));
        await tester.pumpAndSettle();
        expect(find.text('Dragon'), findsOneWidget);
        expect(find.text('🪙 300'), findsOneWidget);
        expect(find.text('Buy'), findsNothing);
        await tester.tap(find.text('Dragon'));
        await tester.pumpAndSettle();
        expect(state.shopOwned, contains('av_dragon'));

        await tester.tap(find.byKey(const Key('shopBackToHub')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('shopHub_hats')));
        await tester.pumpAndSettle();
        expect(find.text('Crown'), findsOneWidget);
        expect(find.text('🪙 150'), findsOneWidget);
        expect(find.text('Buy'), findsNothing);
        await tester.tap(find.text('Crown'));
        await tester.pumpAndSettle();
        expect(state.shopOwned, contains('hat_crown'));
      } finally {
        state.dispose();
      }
    });

    testWidgets('Coin Shop owned permanent items show owned state, not price',
        (tester) async {
      final state = await _makeState();
      try {
        state.coins = 0;
        state.shopOwned.add('av_dragon');
        state.showModal(GameModal.coinShop);

        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        await tester.tap(find.byKey(const Key('shopHub_avatars')));
        await tester.pumpAndSettle();

        expect(find.text('Dragon'), findsOneWidget);
        expect(find.text('Owned'), findsOneWidget);
        expect(find.text('🪙 300'), findsNothing);
        expect(find.text('Not enough'), findsNothing);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Coin Shop daily bonus is local and once per day',
        (tester) async {
      final state = await _makeState();
      try {
        state.coins = 0;
        state.showModal(GameModal.coinShop);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        await tester.tap(find.byKey(const Key('shopHub_packs')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('+20 Coins'));
        await tester.pumpAndSettle();

        expect(state.coins, GameState.dailyBonusCoins);
        expect(state.pendingIapProduct, isNull);
        expect(state.currentModal, GameModal.coinShop);
        expect(find.text('PACKS'), findsOneWidget);
        expect(find.byKey(const Key('shopBackToHub')), findsOneWidget);

        await tester.tap(find.text('+20 Coins'));
        await tester.pumpAndSettle();

        expect(state.coins, GameState.dailyBonusCoins);
        expect(find.text('Claimed'), findsOneWidget);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Coin Shop reward actions stay in the active section',
        (tester) async {
      final state = await _makeState();
      try {
        state.showModal(GameModal.coinShop);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        await tester.ensureVisible(find.byKey(const Key('shopHub_buy')));
        await tester.tap(find.byKey(const Key('shopHub_buy')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Watch Ad'));
        await tester.pumpAndSettle();

        expect(state.currentModal, GameModal.coinShop);
        expect(find.text('BUY'), findsOneWidget);
        expect(find.byKey(const Key('shopBackToHub')), findsOneWidget);
        expect(find.byKey(const Key('shopHub_buy')), findsNothing);
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
