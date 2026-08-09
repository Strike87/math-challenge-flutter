import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_controller.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/game_data.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
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

        final p1 = state.p[1].avatar.custom!;
        expect(p1.base, '🐱');
        expect(p1.hat, '🎓');
        expect(p1.accessory, '👓');
        expect(p1.color, '#FF6B6B');
        expect(state.avatarCustom['1'], isA<AvatarCustom>());
        expect(state.p[2].avatar.isCustom, isFalse);
        expect(state.currentModal, GameModal.none);

        state.showAvatarBuilder(2);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();
        expect(find.text('Player 2 Avatar'), findsOneWidget);
        expect(find.text('👤 Player 1'), findsNothing);
        expect(find.text('👤 Player 2'), findsNothing);

        state.setBuilderBase('🐸');
        state.saveCustomAvatar();

        final p2 = state.p[2].avatar.custom!;
        expect(p2.base, '🐸');
        expect(state.p[1].avatar.custom!.base, '🐱');

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

        expect(state.p[1].avatar.storageEmoji, '🐶');
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

    testWidgets('Avatar Builder native controls stay with the targeted player',
        (tester) async {
      final state = await _makeState();
      try {
        state.players = 2;
        state.showAvatarBuilder(2);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        final base = find.descendant(
          of: find.byKey(const Key('avatar-base-grid')),
          matching: find.text('🐶'),
        );
        final baseInkWell = find.ancestor(
          of: base,
          matching: find.byType(InkWell),
        );
        expect(
          tester.widget<InkWell>(baseInkWell).borderRadius,
          BorderRadius.circular(16),
        );
        Focus.of(tester.element(base)).requestFocus();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        final cat = find.descendant(
          of: find.byKey(const Key('avatar-base-grid')),
          matching: find.text('🐱'),
        );
        expect(Focus.of(tester.element(cat)).hasFocus, isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        expect(Focus.of(tester.element(base)).hasFocus, isTrue);

        var changes = 0;
        state.addListener(() => changes++);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(state.builderPid, 2);
        expect(state.builderAvatar.base, '🐱');
        expect(state.p[1].avatar.storageEmoji, isNot('🐱'));
        expect(changes, 1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(changes, 1);

        await tester.tap(find.text('Color'));
        await tester.pumpAndSettle();
        final colorChoices = find.descendant(
          of: find.byKey(const Key('avatar-color-grid')),
          matching: find.byType(InkWell),
        );
        final firstColor = colorChoices.at(1);
        final secondColor = colorChoices.at(2);
        expect(
          tester.widget<InkWell>(firstColor).customBorder,
          const CircleBorder(),
        );
        final firstColorContent = find.descendant(
          of: firstColor,
          matching: find.byType(AnimatedContainer),
        );
        Focus.of(tester.element(firstColorContent)).requestFocus();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(
          Focus.of(
            tester.element(
              find.descendant(
                of: secondColor,
                matching: find.byType(AnimatedContainer),
              ),
            ),
          ).hasFocus,
          isTrue,
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(
          state.builderAvatar.color,
          GameConfig.avatarColors.whereType<String>().first,
        );
        expect(state.p[1].avatar.isCustom, isFalse);
        await tester.tap(secondColor);
        await tester.pump();
        expect(state.builderAvatar.color, GameConfig.avatarColors[2]);
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

    testWidgets('Coin Shop native controls support keyboard and mouse input',
        (tester) async {
      final state = await _makeState();
      try {
        state.coins = 300;
        state.showModal(GameModal.coinShop);
        await tester.pumpWidget(_modalHost(state));
        await tester.pump();

        final avatars = find.ancestor(
          of: find.text('Avatars'),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(avatars).borderRadius,
            BorderRadius.circular(20));
        for (var i = 0;
            i < 8 &&
                !Focus.of(tester.element(find.text('Avatars'))).hasPrimaryFocus;
            i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        expect(Focus.of(tester.element(find.text('Avatars'))).hasPrimaryFocus,
            isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        expect(Focus.of(tester.element(find.text('Avatars'))).hasPrimaryFocus,
            isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(Focus.of(tester.element(find.text('Avatars'))).hasPrimaryFocus,
            isTrue);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(find.text('AVATARS'), findsOneWidget);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(find.text('AVATARS'), findsOneWidget);

        final dragon = find.ancestor(
          of: find.text('Dragon'),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(dragon).borderRadius,
            BorderRadius.circular(20));
        final mouse = TestPointer(1, PointerDeviceKind.mouse);
        final center = tester.getCenter(dragon);
        await tester.sendEventToBinding(mouse.hover(center));
        await tester.sendEventToBinding(mouse.down(center));
        await tester.sendEventToBinding(mouse.up());
        await tester.pumpAndSettle();
        expect(state.coins, 0);
        expect(state.shopOwned, contains('av_dragon'));
        expect(state.toastMessage, isNot('Already owned'));
        await tester.sendEventToBinding(mouse.removePointer());

        final robot = find.ancestor(
          of: find.text('Robot'),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(robot).onTap, isNull);
        final ownedBefore = Set<String>.from(state.shopOwned);
        await tester.tap(robot);
        await tester.pump();
        expect(state.coins, 0);
        expect(state.shopOwned, ownedBefore);

        await tester.tap(find.byKey(const Key('shopBackToHub')));
        await tester.pumpAndSettle();
        final packs = find.ancestor(
          of: find.text('Packs'),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(packs).borderRadius,
            BorderRadius.circular(20));
        for (var i = 0;
            i < 8 &&
                !Focus.of(tester.element(find.text('Packs'))).hasPrimaryFocus;
            i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        expect(Focus.of(tester.element(find.text('Packs'))).hasPrimaryFocus,
            isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('PACKS'), findsOneWidget);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(find.text('PACKS'), findsOneWidget);
        expect(
          tester
              .widget<InkWell>(
                find.byKey(const Key('shopPack_pack_daily_bonus')),
              )
              .borderRadius,
          BorderRadius.circular(20),
        );
        final dailyBonus = find.byKey(const Key('shopPack_pack_daily_bonus'));
        expect(tester.widget<InkWell>(dailyBonus).onTap, isNotNull);
        for (var i = 0;
            i < 8 &&
                !Focus.of(tester.element(find.text('+20 Coins')))
                    .hasPrimaryFocus;
            i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        expect(Focus.of(tester.element(find.text('+20 Coins'))).hasPrimaryFocus,
            isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(state.coins, GameState.dailyBonusCoins);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(state.coins, GameState.dailyBonusCoins);
        final claimedDailyBonus =
            find.byKey(const Key('shopPack_pack_daily_bonus'));
        expect(tester.widget<InkWell>(claimedDailyBonus).onTap, isNull);
        await tester.tap(claimedDailyBonus);
        await tester.pump();
        expect(state.coins, GameState.dailyBonusCoins);

        state.coins += 500;
        state.notifyListeners();
        await tester.pump();
        final powerPack = find.byKey(const Key('shopPack_pack_powerups'));
        expect(tester.widget<InkWell>(powerPack).onTap, isNotNull);
        for (var i = 0;
            i < 8 &&
                !Focus.of(tester.element(find.text('Power Pack')))
                    .hasPrimaryFocus;
            i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        expect(
            Focus.of(tester.element(find.text('Power Pack'))).hasPrimaryFocus,
            isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(state.coins, GameState.dailyBonusCoins);
        final powerUpBonus =
            jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
        for (final powerUp in [
          'time',
          'fifty',
          'double',
          'shield',
          'freeze',
          'switch'
        ]) {
          expect(powerUpBonus[powerUp], 5);
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(state.coins, GameState.dailyBonusCoins);
        final powerUpBonusAfterKeyUp =
            jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
        for (final powerUp in [
          'time',
          'fifty',
          'double',
          'shield',
          'freeze',
          'switch'
        ]) {
          expect(powerUpBonusAfterKeyUp[powerUp], 5);
        }

        await tester.ensureVisible(find.byKey(const Key('shopBackToHub')));
        await tester.tap(find.byKey(const Key('shopBackToHub')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('shopHub_buy')));
        await tester.tap(find.byKey(const Key('shopHub_buy')));
        await tester.pumpAndSettle();
        final rewardedAd = find.ancestor(
          of: find.text('Watch Ad'),
          matching: find.byType(InkWell),
        );
        final coinOption = find.descendant(
          of: find.byKey(const Key('iapProduct_100_coins')),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(rewardedAd).borderRadius,
            BorderRadius.circular(20));
        expect(tester.widget<InkWell>(coinOption).borderRadius,
            BorderRadius.circular(20));
        await tester.tap(rewardedAd);
        await tester.pumpAndSettle();
        expect(state.currentModal, GameModal.coinShop);
        expect(state.coins, GameState.dailyBonusCoins);

        state.adsRemoved = true;
        state.notifyListeners();
        await tester.pump();
        final disabledRewardedAd = find.ancestor(
          of: find.text('Watch Ad'),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(disabledRewardedAd).onTap, isNull);
        await tester.tap(disabledRewardedAd);
        await tester.pump();
        expect(state.currentModal, GameModal.coinShop);
        expect(state.coins, GameState.dailyBonusCoins);

        await tester.tap(coinOption);
        await tester.pumpAndSettle();
        expect(state.currentModal, GameModal.adultGate);
        expect(state.pendingIapProduct, IapProducts.small);
        expect(tester.takeException(), isNull);
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

    for (final testCase in [
      (const Size(320, 568), 1.3),
      (const Size(844, 390), 1.3),
      (const Size(500, 900), 2.0),
    ]) {
      testWidgets(
        'Settings is bounded and reachable at ${testCase.$1} @ ${testCase.$2}x',
        (tester) async {
          final state = await _makeState();
          final achievementsBefore = Map<String, bool>.from(state.achievements);
          try {
            await _pumpResponsiveModal(
              tester,
              state,
              GameModal.settings,
              testCase.$1,
              testCase.$2,
            );

            expect(find.text('Settings'), findsOneWidget);
            await _expectReachableInsideModal(
              tester,
              find.text('RESTART GAME PROGRESS'),
            );
            await _closeResponsiveModal(tester, state, 'Done');
            expect(state.achievements, achievementsBefore);
          } finally {
            state.dispose();
          }
        },
      );
    }

    for (final testCase in [
      (const Size(844, 390), 1.3),
      (const Size(500, 900), 2.0),
      (const Size(900, 700), 1.3),
    ]) {
      testWidgets(
        'Achievements is bounded and reachable at ${testCase.$1} @ ${testCase.$2}x',
        (tester) async {
          final state = await _makeState();
          final achievementsBefore = Map<String, bool>.from(state.achievements);
          try {
            await _pumpResponsiveModal(
              tester,
              state,
              GameModal.achievements,
              testCase.$1,
              testCase.$2,
            );

            expect(find.text('Achievements'), findsOneWidget);
            await _expectReachableInsideModal(
              tester,
              find.text(GameConfig.achievementsDef.first.name),
            );
            await _closeResponsiveModal(tester, state, 'Close');
            expect(state.achievements, achievementsBefore);
          } finally {
            state.dispose();
          }
        },
      );
    }

    for (final testCase in [
      (const Size(320, 568), 1.3),
      (const Size(844, 390), 1.3),
      (const Size(500, 900), 2.0),
    ]) {
      testWidgets(
        'Coin Shop is bounded and reachable at ${testCase.$1} @ ${testCase.$2}x',
        (tester) async {
          final state = await _makeState();
          final coinsBefore = state.coins;
          final ownedBefore = Set<String>.from(state.shopOwned);
          try {
            await _pumpResponsiveModal(
              tester,
              state,
              GameModal.coinShop,
              testCase.$1,
              testCase.$2,
            );

            expect(find.text('Coin Shop'), findsOneWidget);
            await _expectReachableInsideModal(
              tester,
              find.text('YOUR BALANCE'),
            );
            final avatars = find.byKey(const Key('shopHub_avatars'));
            await _expectReachableInsideModal(tester, avatars);
            await tester.tap(avatars);
            await tester.pump();
            expect(state.currentModal, GameModal.coinShop);
            expect(find.text('AVATARS'), findsOneWidget);
            await _expectReachableInsideModal(tester, find.text('Dragon'));
            await _expectReachableInsideModal(
              tester,
              find.byKey(const Key('shopBackToHub')),
            );
            await tester.tap(find.byKey(const Key('shopBackToHub')));
            await tester.pump();
            expect(find.byKey(const Key('shopHub_avatars')), findsOneWidget);
            await _closeResponsiveModal(tester, state, 'Done');
            expect(state.coins, coinsBefore);
            expect(state.shopOwned, ownedBefore);
          } finally {
            state.dispose();
          }
        },
      );
    }

    for (final testCase in [
      (const Size(320, 568), 1.3),
      (const Size(500, 900), 2.0),
      (const Size(900, 700), 1.3),
    ]) {
      testWidgets(
        'Daily Challenges is bounded and reachable at ${testCase.$1} @ ${testCase.$2}x',
        (tester) async {
          final state = await _makeState();
          final progressBefore = Map<String, int>.from(state.dailyProgress);
          final completedBefore = Map<String, bool>.from(state.dailyCompleted);
          try {
            await _pumpResponsiveModal(
              tester,
              state,
              GameModal.dailyChallenges,
              testCase.$1,
              testCase.$2,
            );

            expect(find.text('Daily Challenges'), findsOneWidget);
            await _expectReachableInsideModal(
              tester,
              find.text(state.activeDailyChallenges.first.title),
            );
            await _closeResponsiveModal(tester, state, 'Close');
            expect(state.dailyProgress, progressBefore);
            expect(state.dailyCompleted, completedBefore);
          } finally {
            state.dispose();
          }
        },
      );
    }

    testWidgets('Adult Gate stays usable above a portrait keyboard',
        (tester) async {
      final state = await _makeState();
      try {
        const size = Size(320, 568);
        const keyboardInset = 200.0;
        await _pumpAdultGateWithKeyboard(tester, state, size, keyboardInset);
      } finally {
        state.dispose();
      }
    });

    testWidgets('Adult Gate stays usable above a landscape keyboard',
        (tester) async {
      final state = await _makeState();
      try {
        const size = Size(844, 390);
        const keyboardInset = 80.0;
        await _pumpAdultGateWithKeyboard(tester, state, size, keyboardInset);
      } finally {
        state.dispose();
      }
    });

    testWidgets('modal shell stays centered and width-bounded without an inset',
        (tester) async {
      final state = await _makeState();
      try {
        const size = Size(480, 700);
        _setTestView(tester, size);
        state.beginIapPurchase(IapProducts.small);
        await tester.pumpWidget(_modalHost(state, size: size));
        await tester.pump();

        final rect = tester.getRect(find.byType(ModalShell));
        expect(rect.width, lessThanOrEqualTo(480));
        expect(rect.center.dx, closeTo(size.width / 2, 0.1));
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

Widget _modalHost(
  GameState state, {
  Size size = const Size(390, 700),
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameState>.value(value: state),
      ChangeNotifierProvider<SettingsService>.value(value: state.settings),
      ChangeNotifierProvider<CloudSaveController>(
        create: (_) => CloudSaveController(
          state: state,
          service: CloudSaveService(state: state, transport: _NoopTransport()),
          localLoad: Future.value(),
        ),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const Scaffold(
          resizeToAvoidBottomInset: false,
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

Future<void> _pumpResponsiveModal(
  WidgetTester tester,
  GameState state,
  GameModal modal,
  Size size,
  double textScale,
) async {
  _setTestView(tester, size);
  state.showModal(modal);
  await tester.pumpWidget(_modalHost(state, size: size, textScale: textScale));
  await tester.pump();

  expect(state.currentModal, modal);
  expect(find.byType(ModalBarrier), findsWidgets);
  expect(
    find.descendant(
      of: find.byType(ModalShell),
      matching: find.byType(SingleChildScrollView),
    ),
    findsOneWidget,
  );
  _expectResponsiveModalBounds(tester, size);
}

void _expectResponsiveModalBounds(WidgetTester tester, Size size) {
  final viewport = Offset.zero & size;
  final modal = tester.getRect(find.byType(ModalShell));
  final barrier = tester.getRect(find.byType(ModalBarrier).first);

  expect(modal.left, greaterThanOrEqualTo(viewport.left));
  expect(modal.top, greaterThanOrEqualTo(viewport.top));
  expect(modal.right, lessThanOrEqualTo(viewport.right));
  expect(modal.bottom, lessThanOrEqualTo(viewport.bottom));
  expect(modal.width, lessThanOrEqualTo(viewport.width));
  expect(modal.height, lessThanOrEqualTo(viewport.height));
  expect(modal.center.dx, closeTo(viewport.center.dx, 1));
  expect(barrier.left, lessThanOrEqualTo(viewport.left));
  expect(barrier.top, lessThanOrEqualTo(viewport.top));
  expect(barrier.right, greaterThanOrEqualTo(viewport.right));
  expect(barrier.bottom, greaterThanOrEqualTo(viewport.bottom));
}

Future<void> _expectReachableInsideModal(
  WidgetTester tester,
  Finder target,
) async {
  await tester.ensureVisible(target);
  await tester.pump();
  final targetRect = tester.getRect(target);
  final modalRect = tester.getRect(find.byType(ModalShell));
  expect(targetRect.left, greaterThanOrEqualTo(modalRect.left));
  expect(targetRect.right, lessThanOrEqualTo(modalRect.right));
  expect(targetRect.top, greaterThanOrEqualTo(modalRect.top));
  expect(targetRect.bottom, lessThanOrEqualTo(modalRect.bottom));
}

Future<void> _closeResponsiveModal(
  WidgetTester tester,
  GameState state,
  String label,
) async {
  final close = find.text(label);
  await tester.ensureVisible(close);
  await tester.tap(close);
  await tester.pump();
  expect(state.currentModal, GameModal.none);
  expect(tester.takeException(), isNull);
}

void _setTestView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpAdultGateWithKeyboard(
  WidgetTester tester,
  GameState state,
  Size size,
  double keyboardInset,
) async {
  _setTestView(tester, size);
  state.beginIapPurchase(IapProducts.small);
  await tester.pumpWidget(
    _modalHost(
      state,
      size: size,
      viewInsets: EdgeInsets.only(bottom: keyboardInset),
    ),
  );
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await _expectAdultGateControlsAboveKeyboard(
    tester,
    size.height - keyboardInset,
  );
}

Future<void> _expectAdultGateControlsAboveKeyboard(
  WidgetTester tester,
  double usableBottom,
) async {
  final field = find.byKey(const Key('adultGateAnswerField'));
  final continueAction = find.text('Continue');
  expect(tester.getRect(field).bottom, lessThanOrEqualTo(usableBottom));
  expect(
      tester.getRect(continueAction).bottom, lessThanOrEqualTo(usableBottom));
  expect(tester.takeException(), isNull);
  await tester.tap(continueAction);
  await tester.pump();
  expect(find.text('Not quite. Please try again.'), findsOneWidget);
}

class _NoopTransport implements SavedGamesTransport {
  @override
  Future<SavedGamesCommitResult> commit(Uint8List bytes) async =>
      SavedGamesCommitted();

  @override
  Future<SavedGamesOpenResult> open() async => SavedGamesOpenedEmpty();

  @override
  Future<SavedGamesResolveResult> resolve(
          String handle, Uint8List bytes) async =>
      SavedGamesResolved();
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
