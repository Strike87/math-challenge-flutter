import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
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

  SettingsService loadSettingsFromStorage() {
    return SettingsService()
      ..load(
        dark: Storage.getBool('mc_dark', false),
        sound: Storage.getBool('mc_sound', true),
        vibration: Storage.getBool('mc_vibration', true),
        dyslexia: Storage.getBool('mc_dyslexia', false),
        colorblind: Storage.getBool('mc_colorblind', false),
        lowPerf: Storage.getBool('mc_lowPerf', false),
        reduceMotion: Storage.getBool('mc_reduceMotion', false),
        animSpeed: Storage.getDouble('mc_animSpeed', 1.0),
      );
  }

  Future<GameState> makeState(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await Storage.init();
    final settings = loadSettingsFromStorage();
    final state = GameState(settings: settings, audio: AudioService(settings));
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  String todayKey() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  String jsDateString(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]} ${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')} ${date.year}';
  }

  group('RT-005 persistence schema parity', () {
    test('A legacy achievements load from mc_achs', () async {
      final state = await makeState({
        'mc_achs': jsonEncode([
          {'id': 'first_win', 'unlocked': true},
          {'id': 'skill_master', 'unlocked': true},
          {'id': 'daily_boss', 'unlocked': false},
        ]),
      });

      expect(state.achievements['first_win'], isTrue);
      expect(state.achievements['skill_master'], isTrue);
      expect(state.achievements['daily_boss'], isFalse);
    });

    test('B legacy skills load from mc_skills and preserve adaptive fields',
        () async {
      final state = await makeState({
        'mc_skills': jsonEncode({
          'addition': {
            'easy': 2,
            'medium': 3,
            'hard': 4,
            'correct': 8,
            'count': 10,
            'mastery': 91.5,
            'confidence': 77.25,
          },
        }),
      });

      final addition = state.skillMap[Operation.addition.name]!;
      expect(addition.easy, 2);
      expect(addition.medium, 3);
      expect(addition.hard, 4);
      expect(addition.expert, 0);
      expect(addition.insane, 0);
      expect(addition.correct, 8);
      expect(addition.count, 10);
      expect(addition.mastery, 91.5);
      expect(addition.confidence, 77.25);
    });

    test('C legacy number type unlocks load from mc_numTypeUnlocked', () async {
      final state = await makeState({
        'mc_numTypeUnlocked': jsonEncode({
          'integers': true,
          'rationals': false,
        }),
      });

      expect(state.numTypeUnlocked['integers'], 1);
      expect(state.numTypeUnlocked['rationals'], 0);
    });

    test('D legacy player data loads from mc_p1Data and mc_p2Data', () async {
      final state = await makeState({
        'mc_p1Data': jsonEncode({'name': 'Ada', 'avatar': '🦊'}),
        'mc_p2Data': jsonEncode({'name': 'Turing', 'avatar': '🐸'}),
      });

      expect(state.p[1].name, 'Ada');
      expect(state.p[1].avatar, '🦊');
      expect(state.p[2].name, 'Turing');
      expect(state.p[2].avatar, '🐸');
    });

    test('E legacy shop ownership maps from object to Flutter lists', () async {
      final state = await makeState({
        'mc_shopOwned': jsonEncode({
          'av_dragon': true,
          'hat_top': true,
          'pack_powerups': false,
        }),
        'mc_unlockedAvatars': jsonEncode(['🐲', '👽']),
        'mc_unlockedHats': jsonEncode(['🎩']),
      });

      expect(state.shopOwned, containsAll(['av_dragon', 'hat_top']));
      expect(state.shopOwned, isNot(contains('pack_powerups')));
      expect(state.unlockedAvatars, containsAll(['🐲', '👽']));
      expect(state.unlockedHats, contains('🎩'));
    });

    test('F settings toggles save and survive reload', () async {
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
      final settings = loadSettingsFromStorage();

      settings.toggleDark();
      settings.toggleSound();
      settings.toggleVibration();
      settings.toggleDyslexia();
      settings.toggleColorblind();
      settings.toggleLowPerf();
      settings.toggleReduceMotion();
      settings.setAnimSpeed(0.3);

      final reloaded = loadSettingsFromStorage();
      expect(reloaded.dark, isTrue);
      expect(reloaded.sound, isFalse);
      expect(reloaded.vibration, isFalse);
      expect(reloaded.dyslexia, isTrue);
      expect(reloaded.colorblind, isTrue);
      expect(reloaded.lowPerf, isTrue);
      expect(reloaded.reduceMotion, isTrue);
      expect(reloaded.animSpeed, 0.3);
    });

    test('G legacy same-key JSON values and avatar custom load', () async {
      final state = await makeState({
        'mc_coins': jsonEncode(42),
        'mc_gamesPlayed': jsonEncode(7),
        'mc_adaptLvl': jsonEncode(6.5),
        'mc_adsRemoved': jsonEncode(true),
        'mc_avatarCustom': jsonEncode({
          'base': '🦁',
          'hat': '🎓',
          'accessory': '👑',
          'color': '#ff0000',
        }),
      });

      expect(state.coins, 42);
      expect(state.gamesPlayed, 7);
      expect(state.adaptLvlRaw, 6.5);
      expect(state.adsRemoved, isTrue);
      expect(state.avatarCustom['1']!.base, '🦁');
      expect(state.avatarCustom['1']!.hat, '🎓');
      expect(state.avatarCustom['1']!.accessory, '👑');
      expect(state.avatarCustom['1']!.color, '#ff0000');
    });

    test('H legacy daily dates and challenge objects normalize on load',
        () async {
      final now = DateTime.now();
      final state = await makeState({
        'mc_dailyCoinsDate': jsDateString(now),
        'mc_dailyBossClaimed': todayKey(),
        'mc_dailyChallenges': jsonEncode({
          'date': jsDateString(now),
          'challenges': [
            {'id': 'blitz_15'},
            {'id': 'streak_7'},
            {'id': 'division_10'},
          ],
        }),
        'mc_dailyProgress': jsonEncode({
          'blitz_15': {'current': 15, 'completed': true},
          'streak_7': {'current': 2, 'completed': false},
        }),
      });

      expect(state.isDailyCoinsClaimedToday, isTrue);
      expect(state.isDailyBossClaimedToday, isTrue);
      expect(state.dailyChallengeIds, ['blitz_15', 'streak_7', 'division_10']);
      expect(state.dailyProgress['blitz_15'], 15);
      expect(state.dailyCompleted['blitz_15'], isTrue);
      expect(state.dailyProgress['streak_7'], 2);
      expect(state.dailyCompleted['streak_7'], isFalse);
    });

    test('I legacy login streak date is respected', () async {
      final state = await makeState({
        'mc_loginStreak': jsonEncode(4),
        'mc_streakLastDay': todayKey(),
      });

      expect(state.loginStreak, 4);
    });

    test('J legacy raw low performance setting parses as bool', () async {
      SharedPreferences.setMockInitialValues({'mc_lowPerf': 'true'});
      await Storage.init();

      final settings = loadSettingsFromStorage();

      expect(settings.lowPerf, isTrue);
    });
  });
}
