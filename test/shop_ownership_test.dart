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
    addTearDown(state.dispose);
    return state;
  }

  GameState makeSecondState(SettingsService settings) {
    final state = GameState(settings: settings, audio: AudioService(settings));
    addTearDown(state.dispose);
    return state;
  }

  group('RT-011 shop ownership and unlock rules', () {
    test('permanent avatar unlock deducts coins once and persists', () async {
      final state = await makeState({'mc_coins': 700});
      final dragon = GameConfig.shopItems['avatars']!
          .firstWhere((item) => item.id == 'av_dragon');

      expect(state.availableAvatarBases, isNot(contains(dragon.emoji)));

      await state.buyShopItem(dragon);

      expect(state.coins, 400);
      expect(state.shopOwned, contains(dragon.id));
      expect(state.unlockedAvatars, contains(dragon.emoji));
      expect(state.availableAvatarBases, contains(dragon.emoji));

      await state.buyShopItem(dragon);

      expect(state.coins, 400);
      expect(state.shopOwned.where((id) => id == dragon.id).length, 1);
      expect(state.toastMessage, 'Already owned');

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      expect(reloaded.shopOwned, contains(dragon.id));
      expect(reloaded.availableAvatarBases, contains(dragon.emoji));
    });

    test('permanent hat unlock deducts coins once and persists', () async {
      final state = await makeState({'mc_coins': 300});
      final crown = GameConfig.shopItems['hats']!
          .firstWhere((item) => item.id == 'hat_crown');

      expect(state.availableAvatarHats, isNot(contains(crown.emoji)));

      await state.buyShopItem(crown);

      expect(state.coins, 150);
      expect(state.shopOwned, contains(crown.id));
      expect(state.unlockedHats, contains(crown.emoji));
      expect(state.availableAvatarHats, contains(crown.emoji));

      await state.buyShopItem(crown);

      expect(state.coins, 150);
      expect(state.shopOwned.where((id) => id == crown.id).length, 1);
      expect(state.toastMessage, 'Already owned');

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      expect(reloaded.shopOwned, contains(crown.id));
      expect(reloaded.availableAvatarHats, contains(crown.emoji));
    });

    test('Power Pack is repeatable and grants five of each power-up each time',
        () async {
      final state = await makeState({'mc_coins': 1500});
      final pack = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_powerups');

      await state.buyShopItem(pack);
      await state.buyShopItem(pack);

      expect(state.coins, 500);
      expect(state.shopOwned, isNot(contains(pack.id)));
      final bonus = jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
      expect(bonus['time'], 10);
      expect(bonus['fifty'], 10);
      expect(bonus['double'], 10);
      expect(bonus['shield'], 10);
      expect(bonus['freeze'], 10);
      expect(bonus['switch'], 10);

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      final persisted =
          jsonDecode(Storage.getString('mc_puBonus', '{}')) as Map;
      expect(persisted['time'], 10);
    });

    test('Extra Life is repeatable and increments life bonus each time',
        () async {
      final state = await makeState({'mc_coins': 1000});
      final lives = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_lives');

      await state.buyShopItem(lives);
      await state.buyShopItem(lives);

      expect(state.coins, 100);
      expect(state.shopOwned, isNot(contains(lives.id)));
      expect(Storage.getInt('mc_livesBonus', 0), 2);

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      expect(Storage.getInt('mc_livesBonus', 0), 2);
    });

    test('+20 Coins daily bonus grants once per day', () async {
      final state = await makeState();
      final bonus = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_daily_bonus');

      await state.buyShopItem(bonus);

      expect(state.coins, GameState.dailyBonusCoins);
      expect(state.isDailyCoinsClaimedToday, isTrue);

      await state.buyShopItem(bonus);

      expect(state.coins, GameState.dailyBonusCoins);
      expect(state.toastMessage, 'Daily bonus already claimed');
    });

    test('locked shop avatars stay out of tap-to-change until bought',
        () async {
      final state = await makeState({'mc_coins': 300});
      final robot = GameConfig.shopItems['avatars']!
          .firstWhere((item) => item.id == 'av_robot');

      expect(state.availableAvatarBases, isNot(contains(robot.emoji)));

      await state.buyShopItem(robot);

      expect(state.availableAvatarBases, contains(robot.emoji));
      state.pickAvatar(1, robot.emoji);
      expect(state.p[1].avatar.storageEmoji, robot.emoji);
    });

    test('insufficient coins grant no ownership and do not go negative',
        () async {
      final state = await makeState({'mc_coins': 100});
      final dragon = GameConfig.shopItems['avatars']!
          .firstWhere((item) => item.id == 'av_dragon');

      await state.buyShopItem(dragon);

      expect(state.coins, 100);
      expect(state.shopOwned, isNot(contains(dragon.id)));
      expect(state.unlockedAvatars, isNot(contains(dragon.emoji)));
      expect(state.availableAvatarBases, isNot(contains(dragon.emoji)));
      expect(state.toastMessage, 'Not enough 🪙');
    });

    test('consumable bonus counts affect later gameplay after reload',
        () async {
      final state = await makeState({'mc_coins': 500});
      final pack = GameConfig.shopItems['packs']!
          .firstWhere((item) => item.id == 'pack_powerups');
      await state.buyShopItem(pack);

      final reloaded = makeSecondState(state.settings);
      await reloaded.load();
      reloaded.players = 1;
      reloaded.mode = GameMode.standard;
      reloaded.rt.challenge = Operation.addition;
      reloaded.startGame();

      final counts = <PowerUp, int>{};
      for (final pu in reloaded.p[1].pups) {
        counts[pu] = (counts[pu] ?? 0) + 1;
      }
      for (final pu in PowerUp.values) {
        expect(counts[pu], 5, reason: '${pu.name} should be bonus 5');
      }
    });
  });
}
