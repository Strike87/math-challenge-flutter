import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_policy.dart';
import 'package:math_challenge/features/operation_quest/domain/operation_quest.dart';
import 'package:math_challenge/models/enums.dart';
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

  Future<GameState> state([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
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
          animSpeed: 1);
    final result = GameState(settings: settings, audio: AudioService(settings));
    await result.load();
    addTearDown(result.dispose);
    return result;
  }

  Future<GameState> reload() async {
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
          animSpeed: 1);
    final result = GameState(settings: settings, audio: AudioService(settings));
    await result.load();
    addTearDown(result.dispose);
    return result;
  }

  CloudProgress populatedProgress() {
    final base = CloudProgress.empty();
    return CloudProgress(
      coins: 99,
      gamesPlayed: 7,
      achievements: {...base.achievements, 'first_win': true},
      operationQuestStars: const {'addition_easy': 3},
      highScores: const [
        HighScore(
            name: 'Cloud',
            score: 12,
            mode: GameMode.standard,
            date: '2026-01-01')
      ],
      skillMap: {
        for (final key in base.skillMap.keys)
          key: SkillData(mastery: 90, count: 5)
      },
      profile: CloudProfile(
        player1: CloudPlayerProfile(
            name: 'One',
            selectedAvatar: '🐱',
            customAvatar: AvatarCustom(
                base: '🐱', hat: '🎓', accessory: '👓', color: '#FF6B6B')),
        player2: CloudPlayerProfile(
            name: 'Two',
            selectedAvatar: '🦁',
            customAvatar: AvatarCustom(
                base: '🦁', hat: '🧢', accessory: '🕶️', color: '#4ECDC4')),
      ),
      economy: CloudEconomy(
        numberTypeUnlocks: const {'integers': 1, 'rationals': 1},
        shopOwned: const ['av_cat'],
        unlockedAvatars: const ['🐱'],
        unlockedHats: const ['🎓'],
        powerUpBonus: {for (final powerUp in PowerUp.values) powerUp.name: 2},
        livesBonus: 3,
      ),
    );
  }

  test('exports canonical empty CloudProgress and no metadata', () async {
    final game = await state();
    final exported = game.exportCloudProgress();
    expect(exported, CloudProgress.empty());
    expect(exported.toJson().toString(), isNot(contains('cloudDirty')));
  });

  test('typed import replaces approved progress and keeps import clean',
      () async {
    final game = await state();
    final progress = populatedProgress();
    game.coins = 1;
    game.numTypeUnlocked = const {'integers': 0, 'rationals': 0};
    game.shopOwned = ['local'];
    game.skillMap = {
      for (final key in progress.skillMap.keys) key: SkillData(mastery: 1)
    };
    await Storage.setString('mc_puBonus',
        jsonEncode({for (final powerUp in PowerUp.values) powerUp.name: 9}));
    await Storage.setInt('mc_livesBonus', 9);
    expect(await game.importCloudProgress(progress), isTrue);
    expect(game.exportCloudProgress(), progress);
    expect(game.cloudDirty, isFalse);
    expect(game.adaptLvlRaw, 9);
    expect(game.adaptLvl, 9);
  });

  test('populated export, excluded state, and round trip are canonical',
      () async {
    final first = await state();
    final progress = populatedProgress();
    first.coins = progress.coins;
    first.gamesPlayed = progress.gamesPlayed;
    first.achievements = Map.of(progress.achievements);
    first.operationQuestProgress = OperationQuestProgress({
      OperationQuestStageId.fromStorageId('addition_easy')!: 3,
    });
    first.highScores = List.of(progress.highScores);
    first.skillMap = Map.of(progress.skillMap);
    first.p[1].name = progress.profile.player1.name;
    first.p[1].avatar =
        AvatarData.emoji(progress.profile.player1.selectedAvatar);
    first.p[2].name = progress.profile.player2.name;
    first.p[2].avatar =
        AvatarData.emoji(progress.profile.player2.selectedAvatar);
    first.avatarCustom = {
      '1': progress.profile.player1.customAvatar,
      '2': progress.profile.player2.customAvatar
    };
    first.numTypeUnlocked = Map.of(progress.economy.numberTypeUnlocks);
    first.shopOwned = List.of(progress.economy.shopOwned);
    first.unlockedAvatars = List.of(progress.economy.unlockedAvatars);
    first.unlockedHats = List.of(progress.economy.unlockedHats);
    await Storage.setString(
        'mc_puBonus', jsonEncode(progress.economy.powerUpBonus));
    await Storage.setInt('mc_livesBonus', progress.economy.livesBonus);
    first.adaptLvlRaw = 999;
    first.dailyProgress = {'daily': 1};
    first.adsRemoved = true;
    first.setAnswerStyle(AnswerStyle.trueFalse);
    first.showScreen(GameScreen.config);
    first.showModal(GameModal.settings);
    expect(first.exportCloudProgress(), progress);
    expect(first.exportCloudProgress().toJson().containsKey('adaptLvlRaw'),
        isFalse);
    for (final key in [
      'dailyProgress',
      'settings',
      'selectedAnswerStyle',
      'adsRemoved',
      'iapDeliveredTxs',
      'adGameCount',
      'lastRewardedAt',
      'runtime',
      'currentScreen',
      'currentModal',
    ]) {
      expect(first.exportCloudProgress().toJson().containsKey(key), isFalse);
    }

    final second = await state();
    second.dailyProgress = {'keep': 2};
    second.adsRemoved = true;
    second.settings.toggleSound();
    second.setAnswerStyle(AnswerStyle.trueFalse);
    second.showScreen(GameScreen.config);
    second.showModal(GameModal.settings);
    expect(await second.importCloudProgress(progress), isTrue);
    expect(second.exportCloudProgress(), progress);
    expect(second.dailyProgress, {'keep': 2});
    expect(second.settings.sound, isTrue);
    expect(second.adsRemoved, isTrue);
    expect(second.selectedAnswerStyle, AnswerStyle.trueFalse);
    expect(second.currentScreen, GameScreen.config);
    expect(second.currentModal, GameModal.settings);
  });

  test('metadata defaults and reset generation persist', () async {
    final game = await state();
    expect(game.cloudResetGeneration, 0);
    expect(game.cloudRevisionId, isNull);
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudLastSyncedRevisionId, isNull);
    expect(game.cloudDirty, isFalse);
    game.cloudRevisionId = 'revision';
    game.cloudParentRevisionId = 'parent';
    game.cloudLastSyncedRevisionId = 'synced';
    game.cloudDirty = true;
    await game.save();
    final persisted = await reload();
    expect(persisted.cloudRevisionId, 'revision');
    expect(persisted.cloudParentRevisionId, 'parent');
    expect(persisted.cloudLastSyncedRevisionId, 'synced');
    expect(persisted.cloudDirty, isTrue);
    for (final key in [
      'cloudResetGeneration',
      'cloudRevisionId',
      'cloudParentRevisionId',
      'cloudLastSyncedRevisionId',
      'cloudDirty',
    ]) {
      expect(
          persisted.exportCloudProgress().toJson().containsKey(key), isFalse);
    }
    await persisted.resetAllData();
    expect(persisted.cloudResetGeneration, 1);
    expect(persisted.cloudDirty, isTrue);
    expect(persisted.cloudRevisionId, isNull);
    expect(persisted.cloudParentRevisionId, isNull);
    expect(persisted.cloudLastSyncedRevisionId, isNull);
    expect(persisted.exportCloudProgress(), CloudProgress.empty());
    final reset = await reload();
    expect(reset.cloudResetGeneration, 1);
    expect(reset.cloudDirty, isTrue);
    final decision = const CloudProgressPolicy().decide(
      CloudProgressDocument(
        revision: 0,
        revisionId: 'old',
        parentRevisionId: null,
        resetGeneration: 0,
        updatedAtUtcMs: 0,
        progress: CloudProgress.empty(),
      ),
      CloudProgressDocument(
        revision: 0,
        revisionId: 'new',
        parentRevisionId: null,
        resetGeneration: reset.cloudResetGeneration,
        updatedAtUtcMs: 0,
        progress: reset.exportCloudProgress(),
      ),
    );
    expect(decision.kind, CloudProgressDecisionKind.useCloud);
  });

  test('cloud-owned and excluded mutation checkpoints dirty correctly',
      () async {
    final game = await state();
    game.addCoins(1);
    await Future<void>.delayed(Duration.zero);
    expect(game.cloudDirty, isTrue);

    final zero = await state();
    zero.addCoins(0);
    expect(zero.cloudDirty, isFalse);

    final achievement = await state();
    achievement.unlockAch('first_win');
    await Future<void>.delayed(Duration.zero);
    expect(achievement.cloudDirty, isTrue);
    achievement.cloudDirty = false;
    achievement.unlockAch('first_win');
    expect(achievement.cloudDirty, isFalse);

    final clean = await state();
    clean.setAnswerStyle(AnswerStyle.trueFalse);
    clean.settings.toggleSound();
    clean.debugUpdateDailyProgress('blitz_15');
    expect(clean.cloudDirty, isFalse);
    clean.setPlayerName(1, 'Player 1');
    expect(clean.cloudDirty, isFalse);
    clean.setPlayerName(1, 'Renamed');
    await Future<void>.delayed(Duration.zero);
    expect(clean.cloudDirty, isTrue);

    final mastery = await state();
    mastery.debugUpdateSkillMap(
        Operation.addition, Difficulty.easy, true, 1000);
    await Future<void>.delayed(Duration.zero);
    expect(mastery.cloudDirty, isTrue);

    final purchase = await state();
    purchase.coins = 500;
    await purchase.selectNumType(NumberType.integers.name);
    expect(purchase.numTypeUnlocked['integers'], 1);
    expect(purchase.cloudDirty, isTrue);

    purchase.cloudDirty = false;
    await purchase.selectNumType(NumberType.integers.name);
    expect(purchase.cloudDirty, isFalse);

    final failed = await state();
    await failed.selectNumType(NumberType.integers.name);
    expect(failed.cloudDirty, isFalse);

    final avatar = await state();
    avatar.pickAvatar(1, '🐱');
    await Future<void>.delayed(Duration.zero);
    expect(avatar.cloudDirty, isTrue);
    avatar.cloudDirty = false;
    avatar.pickAvatar(1, '🐱');
    expect(avatar.cloudDirty, isFalse);

    final custom = await state();
    custom.showAvatarBuilder(1);
    custom.setBuilderBase('🐱');
    custom.saveCustomAvatar();
    await Future<void>.delayed(Duration.zero);
    expect(custom.cloudDirty, isTrue);

    final shop = await state();
    await shop.buyShopItem(
        const ShopItem(id: 'av_cat', emoji: '🐱', name: 'Cat', price: 1));
    expect(shop.cloudDirty, isFalse);
  });

  testWidgets('real completed game dirties once and import replays no flow',
      (tester) async {
    final game = await state();
    game.players = 1;
    game.mode = GameMode.standard;
    game.adaptive = false;
    game.questionCount = 1;
    game.rt.challenge = Operation.addition;
    game.startGame();
    game.onAnswer(game.rt.q!.ans);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(game.gamesPlayed, 1);
    expect(game.cloudDirty, isTrue);

    game.cloudDirty = false;
    game.debugTimeoutForTest();
    expect(game.cloudDirty, isFalse);

    final imported = await state();
    imported.showScreen(GameScreen.config);
    imported.showModal(GameModal.settings);
    expect(await imported.importCloudProgress(populatedProgress()), isTrue);
    expect(imported.coins, populatedProgress().coins);
    expect(imported.currentScreen, GameScreen.config);
    expect(imported.currentModal, GameModal.settings);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Quest best stars dirty while equal results stay clean',
      (tester) async {
    final game = await state();
    const stage = OperationQuestStageId.additionEasy;

    Future<void> complete({bool correct = true}) async {
      game.startOperationQuestStage(stage);
      game.startGame();
      for (var i = 0; i < 10 && game.rt.gameActive; i++) {
        final question = game.rt.q!;
        game.onAnswer(correct
            ? question.ans
            : question.choices.firstWhere((choice) => choice != question.ans));
        await tester.pump(const Duration(milliseconds: 1300));
      }
    }

    await complete();
    final best = game.operationQuestProgress.bestStars(stage);
    expect(best, greaterThan(0));
    expect(game.gamesPlayed, 1);
    expect(game.cloudDirty, isTrue);

    game.cloudDirty = false;
    await complete();
    expect(game.operationQuestProgress.bestStars(stage), best);
    expect(game.gamesPlayed, 2);
    expect(game.cloudDirty, isTrue);

    game.cloudDirty = false;
    await complete(correct: false);
    expect(game.operationQuestResultStars, lessThan(best));
    expect(game.operationQuestProgress.bestStars(stage), best);
    expect(game.gamesPlayed, 3);
    expect(game.cloudDirty, isTrue);
    await tester.pump(const Duration(seconds: 3));
  });
}
