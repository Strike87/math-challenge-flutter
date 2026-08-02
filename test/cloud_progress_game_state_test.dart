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
import 'package:math_challenge/services/iap.dart';
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

  CloudProgressDocument document({
    CloudProgress? progress,
    int revision = 1,
    String revisionId = 'revision',
    String? parentRevisionId,
    List<String> mergeParentRevisionIds = const [],
    int resetGeneration = 0,
  }) =>
      CloudProgressDocument(
        revision: revision,
        revisionId: revisionId,
        parentRevisionId: parentRevisionId,
        mergeParentRevisionIds: mergeParentRevisionIds,
        resetGeneration: resetGeneration,
        updatedAtUtcMs: 1,
        progress: progress ?? CloudProgress.empty(),
      );

  Map<String, Object> blockedRecoveryValues(
    String intent, {
    int loginDayOffset = 0,
  }) {
    final today = DateTime.now();
    final date = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return {
      'mc_cloudResetIntent': intent,
      'mc_cloudResetGeneration': 3,
      'mc_cloudRevision': 8,
      'mc_cloudRevisionId': 'old-revision',
      'mc_cloudParentRevisionId': 'old-parent',
      'mc_cloudMergeParentRevisionIds': ['left', 'right'],
      'mc_cloudLastSyncedRevisionId': 'old-synced',
      'mc_cloudDirty': false,
      'mc_coins': 99,
      'mc_gamesPlayed': 7,
      'mc_operationQuestProgress': 'addition_easy=3',
      'mc_skillMap': jsonEncode({
        'addition': {'mastery': 99, 'count': 5},
      }),
      'mc_p1_name': 'Old Player',
      'mc_p1_avatar': '🐱',
      'mc_puBonus': jsonEncode({
        for (final powerUp in PowerUp.values) powerUp.name: 7,
      }),
      'mc_livesBonus': 5,
      'mc_selectedAnswerStyle': AnswerStyle.trueFalse.name,
      'mc_loginStreak': 8,
      'mc_lastLoginDay':
          DateTime(today.year, today.month, today.day).millisecondsSinceEpoch ~/
                  const Duration(days: 1).inMilliseconds +
              loginDayOffset,
      'mc_dailyProgress': jsonEncode({
        'blitz_15': {'current': 4, 'completed': false},
      }),
      'mc_dailyChallenges': jsonEncode({
        'date': date,
        'challenges': ['blitz_15'],
      }),
      'mc_dailyCoinsDate': date,
      'mc_dailyBossClaimed': date,
      'mc_adsRemoved': true,
      'mc_iapDeliveredTxs': ['tx-1'],
      'mc_adGameCount': 11,
      'mc_lastRewardedAt': 123456,
    };
  }

  void expectBlockedRecovery(
    GameState game, {
    required int generation,
    int loginStreak = 8,
  }) {
    expect(game.exportCloudProgress(), CloudProgress.empty());
    expect(game.cloudResetGeneration, generation);
    expect(game.cloudRevision, isNull);
    expect(game.cloudRevisionId, isNull);
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, isEmpty);
    expect(game.cloudLastSyncedRevisionId, isNull);
    expect(game.cloudDirty, isTrue);
    expect(game.cloudResetRecoveryBlocked, isTrue);
    expect(game.p[1].name, 'Player 1');
    expect(game.selectedAnswerStyle, AnswerStyle.trueFalse);
    expect(game.loginStreak, loginStreak);
    expect(game.dailyProgress, {'blitz_15': 4});
    expect(game.adsRemoved, isTrue);
    expect(game.iapDeliveredTxs, ['tx-1']);
    expect(game.adGameCount, 11);
    expect(game.lastRewardedAt, 123456);
    expect(Storage.containsKey('mc_cloudResetIntent'), isTrue);
    game.startGame();
    expect(game.p[1].pups, isEmpty);
    game.startMasterMode();
    expect(game.masterLives, 3);
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
    expect(game.cloudRevision, isNull);
    expect(game.cloudRevisionId, isNull);
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, isEmpty);
    expect(game.cloudLastSyncedRevisionId, isNull);
    expect(game.cloudDirty, isFalse);
    game.cloudRevision = 7;
    game.cloudRevisionId = 'revision';
    game.cloudParentRevisionId = 'parent';
    game.cloudLastSyncedRevisionId = 'synced';
    game.cloudDirty = true;
    await game.save();
    final persisted = await reload();
    expect(persisted.cloudRevision, 7);
    expect(persisted.cloudRevisionId, 'revision');
    expect(persisted.cloudParentRevisionId, 'parent');
    expect(persisted.cloudMergeParentRevisionIds, isEmpty);
    expect(persisted.cloudLastSyncedRevisionId, 'synced');
    expect(persisted.cloudDirty, isTrue);
    for (final key in [
      'cloudResetGeneration',
      'cloudRevision',
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
    expect(persisted.cloudRevision, isNull);
    expect(persisted.cloudRevisionId, isNull);
    expect(persisted.cloudParentRevisionId, isNull);
    expect(persisted.cloudMergeParentRevisionIds, isEmpty);
    expect(persisted.cloudLastSyncedRevisionId, isNull);
    expect(persisted.exportCloudProgress(), CloudProgress.empty());
    final reset = await reload();
    expect(reset.cloudResetGeneration, 1);
    expect(reset.cloudDirty, isTrue);
    expect(reset.cloudRevision, isNull);
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

  test('legacy missing, malformed, and negative cloud revisions load as null',
      () async {
    final game = await state({
      'mc_cloudRevisionId': 'merge',
      'mc_cloudMergeParentRevisionIds': ['parent_a', 'parent_b'],
      'mc_cloudLastSyncedRevisionId': 'merge',
      'mc_cloudDirty': false,
    });
    expect(game.cloudRevision, isNull);
    expect(game.cloudRevisionId, 'merge');
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, ['parent_a', 'parent_b']);
    expect(game.cloudLastSyncedRevisionId, 'merge');
    expect(game.cloudDirty, isFalse);
    expect(() => game.cloudMergeParentRevisionIds.add('parent_c'),
        throwsUnsupportedError);

    final malformed = await state({
      'mc_cloudRevision': 'not-a-revision',
      'mc_cloudRevisionId': 'linear',
      'mc_cloudParentRevisionId': 'root',
      'mc_cloudMergeParentRevisionIds': ['parent_a'],
    });
    expect(malformed.cloudRevision, isNull);
    expect(malformed.cloudRevisionId, 'linear');
    expect(malformed.cloudParentRevisionId, 'root');
    expect(malformed.cloudMergeParentRevisionIds, isEmpty);
    final negative = await state({'mc_cloudRevision': -1});
    expect(negative.cloudRevision, isNull);
    final missing = await state();
    expect(missing.cloudRevision, isNull);
    expect(missing.cloudMergeParentRevisionIds, isEmpty);
  });

  test('acceptance replaces synchronized metadata without importing progress',
      () async {
    final game = await state();
    final local = populatedProgress();
    expect(await game.importCloudProgress(local), isTrue);
    game.cloudDirty = true;
    var notifications = 0;
    game.addListener(() => notifications++);
    final merge = document(
      revision: 0,
      revisionId: 'merge',
      mergeParentRevisionIds: const ['parent_a', 'parent_b'],
      resetGeneration: 3,
    );
    expect(await game.acceptCloudProgressDocument(merge, importProgress: false),
        isTrue);
    expect(game.exportCloudProgress(), local);
    expect(game.cloudResetGeneration, 3);
    expect(game.cloudRevision, 0);
    expect(game.cloudRevisionId, 'merge');
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, ['parent_a', 'parent_b']);
    expect(game.cloudLastSyncedRevisionId, 'merge');
    expect(game.cloudDirty, isFalse);
    expect(notifications, 1);
    final mergedReload = await reload();
    expect(mergedReload.cloudRevision, 0);
    expect(mergedReload.cloudRevisionId, 'merge');
    expect(mergedReload.cloudParentRevisionId, isNull);
    expect(mergedReload.cloudMergeParentRevisionIds, ['parent_a', 'parent_b']);
    expect(mergedReload.cloudLastSyncedRevisionId, 'merge');
    expect(mergedReload.cloudDirty, isFalse);

    final linear = document(
      revision: 8,
      revisionId: 'child',
      parentRevisionId: 'merge',
      resetGeneration: 3,
    );
    expect(
        await game.acceptCloudProgressDocument(linear, importProgress: false),
        isTrue);
    expect(game.cloudParentRevisionId, 'merge');
    expect(game.cloudRevision, 8);
    expect(game.cloudMergeParentRevisionIds, isEmpty);
    final reloaded = await reload();
    expect(reloaded.cloudRevision, 8);
    expect(reloaded.cloudRevisionId, 'child');
    expect(reloaded.cloudParentRevisionId, 'merge');
    expect(reloaded.cloudMergeParentRevisionIds, isEmpty);
    expect(reloaded.cloudLastSyncedRevisionId, 'child');
    expect(reloaded.cloudDirty, isFalse);
  });

  test('acceptance imports cloud progress and replaces scalar lineage',
      () async {
    final game = await state();
    expect(
        await game.acceptCloudProgressDocument(
          document(revisionId: 'linear', parentRevisionId: 'root'),
          importProgress: false,
        ),
        isTrue);
    game.showScreen(GameScreen.config);
    game.showModal(GameModal.settings);
    final merge = document(
      progress: populatedProgress(),
      revision: 12,
      revisionId: 'merge',
      mergeParentRevisionIds: const ['parent_a', 'parent_b'],
      resetGeneration: 4,
    );
    expect(await game.acceptCloudProgressDocument(merge, importProgress: true),
        isTrue);
    expect(game.exportCloudProgress(), populatedProgress());
    expect(game.cloudRevision, 12);
    expect(game.adaptLvlRaw, 9);
    expect(game.adaptLvl, 9);
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, ['parent_a', 'parent_b']);
    expect(game.cloudLastSyncedRevisionId, 'merge');
    expect(game.cloudDirty, isFalse);
    expect(game.currentScreen, GameScreen.config);
    expect(game.currentModal, GameModal.settings);

    final reset =
        document(revision: 9, revisionId: 'reset', resetGeneration: 5);
    expect(await game.acceptCloudProgressDocument(reset, importProgress: true),
        isTrue);
    expect(game.exportCloudProgress(), CloudProgress.empty());
    expect(game.cloudResetGeneration, 5);
    expect(game.cloudRevision, 9);
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, isEmpty);
    expect(game.cloudDirty, isFalse);
  });

  test('reset and schema-v1 acceptance clear merge lineage', () async {
    final game = await state();
    expect(
        await game.acceptCloudProgressDocument(
          document(
            revisionId: 'merge',
            mergeParentRevisionIds: const ['parent_a', 'parent_b'],
          ),
          importProgress: false,
        ),
        isTrue);
    await game.resetAllData();
    expect(game.cloudRevision, isNull);
    expect(game.cloudRevisionId, isNull);
    expect(game.cloudParentRevisionId, isNull);
    expect(game.cloudMergeParentRevisionIds, isEmpty);
    expect(game.cloudLastSyncedRevisionId, isNull);
    expect(game.cloudResetGeneration, 1);
    expect(game.cloudDirty, isTrue);
    final reset = await reload();
    expect(reset.cloudRevision, isNull);
    expect(reset.cloudRevisionId, isNull);
    expect(reset.cloudParentRevisionId, isNull);
    expect(reset.cloudMergeParentRevisionIds, isEmpty);
    expect(reset.cloudLastSyncedRevisionId, isNull);
    expect(reset.cloudResetGeneration, 1);
    expect(reset.cloudDirty, isTrue);

    final v1 = CloudProgressDocument.decode(jsonEncode({
      'schemaVersion': 1,
      'revision': 7,
      'revisionId': 'v1',
      'parentRevisionId': 'root',
      'resetGeneration': 1,
      'updatedAtUtcMs': 1,
      'progress': CloudProgress.empty().toJson(),
    })).document!;
    expect(await reset.acceptCloudProgressDocument(v1, importProgress: false),
        isTrue);
    expect(reset.cloudRevision, 7);
    expect(reset.cloudParentRevisionId, 'root');
    expect(reset.cloudMergeParentRevisionIds, isEmpty);

    expect(await reset.importCloudProgress(populatedProgress()), isTrue);
    expect(reset.cloudRevision, 7);
    expect(reset.cloudParentRevisionId, 'root');
    expect(reset.cloudMergeParentRevisionIds, isEmpty);

    expect(
      await reset.acceptCloudProgressDocument(
        document(revision: 0, revisionId: 'root'),
        importProgress: false,
      ),
      isTrue,
    );
    expect(reset.cloudRevision, 0);
    expect(reset.cloudRevisionId, 'root');
    expect(reset.cloudParentRevisionId, isNull);
    expect(reset.cloudMergeParentRevisionIds, isEmpty);
    expect(reset.cloudLastSyncedRevisionId, 'root');
    expect(reset.cloudDirty, isFalse);
    expect(
      await reset.acceptCloudProgressDocument(
        document(revision: 9, revisionId: 'next', parentRevisionId: 'root'),
        importProgress: false,
      ),
      isTrue,
    );
    expect(reset.cloudRevision, 9);
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

  test(
      'Reset Everywhere writes intent first, clears cloud progress, and preserves excluded state',
      () async {
    final game = await state();
    game
      ..coins = 99
      ..gamesPlayed = 7
      ..cloudRevision = 4
      ..cloudRevisionId = 'revision'
      ..cloudParentRevisionId = 'parent'
      ..cloudDirty = false
      ..dailyProgress = {'daily': 1}
      ..adsRemoved = true;
    game.setAnswerStyle(AnswerStyle.trueFalse);
    await game.save();
    final writes = <String>[];
    Storage.writeFailureHook = (key, _) => writes.add(key);
    addTearDown(() => Storage.writeFailureHook = null);

    expect(await game.resetCloudProgressEverywhere(), isTrue);

    expect(writes.first, 'mc_cloudResetIntent');
    expect(game.exportCloudProgress(), CloudProgress.empty());
    expect(game.cloudResetGeneration, 1);
    expect(game.cloudRevision, isNull);
    expect(game.cloudRevisionId, isNull);
    expect(game.cloudDirty, isTrue);
    expect(game.dailyProgress, {'daily': 1});
    expect(game.adsRemoved, isTrue);
    expect(game.selectedAnswerStyle, AnswerStyle.trueFalse);
    expect(Storage.containsKey('mc_cloudResetIntent'), isFalse);
  });

  test(
      'Reset Everywhere recovery replays a durable intent without another generation',
      () async {
    final game = await state();
    game.coins = 42;
    await game.save();
    Storage.writeFailureHook = (key, _) {
      if (key == 'mc_coins') throw StateError('injected');
    };
    addTearDown(() => Storage.writeFailureHook = null);

    expect(await game.resetCloudProgressEverywhere(), isFalse);
    expect(game.exportCloudProgress(), CloudProgress.empty());
    expect(game.cloudResetGeneration, 1);
    expect(Storage.containsKey('mc_cloudResetIntent'), isTrue);

    Storage.writeFailureHook = null;
    final recovered = await reload();
    expect(recovered.exportCloudProgress(), CloudProgress.empty());
    expect(recovered.cloudResetGeneration, 1);
    expect(recovered.cloudDirty, isTrue);
    expect(Storage.containsKey('mc_cloudResetIntent'), isFalse);
  });

  test('malformed reset intent loads preserved state while failing closed',
      () async {
    final game = await state(blockedRecoveryValues('{bad'));

    expectBlockedRecovery(game, generation: 3);
  });

  test('blocked load restores ads without saving cloud-owned state', () async {
    final values = blockedRecoveryValues('{bad')..['mc_adsRemoved'] = false;
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
    final game = GameState(
      settings: settings,
      audio: AudioService(settings),
      iapAdapter: const DevIapPurchaseAdapter(
        isNativeRelease: false,
        restoredPurchases: [
          IapPurchase(
            productId: IapProducts.removeAdsId,
            status: IapPurchaseStatus.approved,
          ),
        ],
      ),
    );
    addTearDown(game.dispose);
    final writes = <String>[];
    var notifications = 0;
    game.addListener(() => notifications++);
    Storage.writeFailureHook = (key, _) => writes.add(key);
    try {
      await game.load();
      expect(notifications, 1);
      expect(game.adsRemoved, isTrue);
      expect(game.iapDeliveredTxs, ['tx-1']);
      expect(game.exportCloudProgress(), CloudProgress.empty());
      expect(writes, contains('mc_adsRemoved'));
      const cloudKeys = {
        'mc_coins',
        'mc_gamesPlayed',
        'mc_achievements',
        'mc_operationQuestProgress',
        'mc_scores',
        'mc_skillMap',
        'mc_numTypeUnlocked_integers',
        'mc_numTypeUnlocked_rationals',
        'mc_avatarCustom1',
        'mc_avatarCustom2',
        'mc_p1_name',
        'mc_p1_avatar',
        'mc_p2_name',
        'mc_p2_avatar',
        'mc_shopOwned',
        'mc_unlockedAvatars',
        'mc_unlockedHats',
        'mc_cloudResetGeneration',
        'mc_cloudRevision',
        'mc_cloudRevisionId',
        'mc_cloudParentRevisionId',
        'mc_cloudMergeParentRevisionIds',
        'mc_cloudLastSyncedRevisionId',
        'mc_cloudDirty',
      };
      expect(writes.where(cloudKeys.contains), isEmpty);
    } finally {
      Storage.writeFailureHook = null;
    }
  });

  test('future reset intent loads preserved state while failing closed',
      () async {
    final game = await state(
      blockedRecoveryValues(
        jsonEncode({'v': 2, 'targetResetGeneration': 5}),
      ),
    );

    expectBlockedRecovery(game, generation: 3);
  });

  test('failed reset-intent replay loads preserved state while blocked',
      () async {
    final values = blockedRecoveryValues(
      jsonEncode({'v': 1, 'targetResetGeneration': 4}),
      loginDayOffset: -1,
    );
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
    final game = GameState(settings: settings, audio: AudioService(settings));
    addTearDown(game.dispose);
    var notifications = 0;
    game.addListener(() => notifications++);
    Storage.writeFailureHook = (key, _) {
      if (key == 'mc_coins') throw StateError('injected');
    };
    try {
      await game.load();
      expect(notifications, 1);
      expectBlockedRecovery(game, generation: 4, loginStreak: 9);
    } finally {
      Storage.writeFailureHook = null;
    }
  });

  test('reset persistence failure blocks cloud recovery', () async {
    final game = await state();
    Storage.writeFailureHook = (key, _) {
      if (key == 'mc_puBonus') throw StateError('injected');
    };
    addTearDown(() => Storage.writeFailureHook = null);

    expect(await game.resetCloudProgressEverywhere(), isFalse);
    expect(game.cloudResetRecoveryBlocked, isTrue);
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
