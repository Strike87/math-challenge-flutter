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
    return '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
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
    return '${weekdays[date.weekday - 1]} ${months[date.month - 1]} '
        '${date.day.toString().padLeft(2, '0')} ${date.year}';
  }

  group('RT-007 storage migration from original app', () {
    test('A legacy achievements migrate from mc_achs to mc_achievements',
        () async {
      final legacyAchs = jsonEncode([
        {'id': 'first_win', 'unlocked': true},
        {'id': 'skill_master', 'unlocked': true},
      ]);
      final state = await makeState({'mc_achs': legacyAchs});

      expect(state.achievements['first_win'], isTrue);
      expect(state.achievements['skill_master'], isTrue);
      expect(Storage.getString('mc_achievements', ''), contains('first_win=1'));
      expect(
          Storage.getString('mc_achievements', ''), contains('skill_master=1'));
      expect(Storage.getString('mc_achs', ''), legacyAchs);

      final migrated = Storage.getString('mc_achievements', '');
      await state.load();
      expect(Storage.getString('mc_achievements', ''), migrated);
    });

    test('B legacy skills migrate from mc_skills to mc_skillMap', () async {
      final legacySkills = jsonEncode({
        'addition': {
          'easy': 2,
          'medium': 3,
          'hard': 4,
          'correct': 8,
          'count': 10,
          'mastery': 91.5,
          'confidence': 77.25,
        },
      });
      final state = await makeState({'mc_skills': legacySkills});

      final addition = state.skillMap[Operation.addition.name]!;
      expect(addition.correct, 8);
      expect(addition.count, 10);
      expect(addition.mastery, 91.5);

      final migrated = jsonDecode(Storage.getString('mc_skillMap', ''));
      expect(migrated['addition']['easy'], 2);
      expect(migrated['addition']['expert'], 0);
      expect(migrated['addition']['insane'], 0);
      expect(Storage.getString('mc_skills', ''), legacySkills);

      await state.load();
      final reloaded = state.skillMap[Operation.addition.name]!;
      expect(reloaded.correct, 8);
      expect(reloaded.count, 10);
    });

    test('C legacy number type unlocks migrate to split Flutter flags',
        () async {
      final legacyUnlocks = jsonEncode({
        'integers': true,
        'rationals': false,
      });
      final state = await makeState({'mc_numTypeUnlocked': legacyUnlocks});

      expect(state.numTypeUnlocked['integers'], 1);
      expect(state.numTypeUnlocked['rationals'], 0);
      expect(Storage.getInt('mc_numTypeUnlocked_integers', 0), 1);
      expect(Storage.getInt('mc_numTypeUnlocked_rationals', 0), 0);
      expect(Storage.getString('mc_numTypeUnlocked', ''), legacyUnlocks);

      await state.load();
      expect(Storage.getInt('mc_numTypeUnlocked_integers', 0), 1);
      expect(Storage.getInt('mc_numTypeUnlocked_rationals', 0), 0);
    });

    test('D legacy player data migrates to split player fields', () async {
      final p1 = jsonEncode({'name': 'Ada', 'avatar': '🦊'});
      final p2 = jsonEncode({'name': 'Turing', 'avatar': '🐸'});
      final state = await makeState({'mc_p1Data': p1, 'mc_p2Data': p2});

      expect(state.p[1].name, 'Ada');
      expect(state.p[1].avatar, '🦊');
      expect(state.p[2].name, 'Turing');
      expect(state.p[2].avatar, '🐸');
      expect(Storage.getString('mc_p1_name', ''), 'Ada');
      expect(Storage.getString('mc_p1_avatar', ''), '🦊');
      expect(Storage.getString('mc_p2_name', ''), 'Turing');
      expect(Storage.getString('mc_p2_avatar', ''), '🐸');
      expect(Storage.getString('mc_p1Data', ''), p1);
      expect(Storage.getString('mc_p2Data', ''), p2);
    });

    test('E legacy shop ownership migrates to Flutter ownership lists',
        () async {
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
      expect(Storage.getStringList('mc_shopOwned', []),
          containsAll(['av_dragon', 'hat_top']));
      expect(Storage.getStringList('mc_shopOwned', []),
          isNot(contains('pack_powerups')));
      expect(Storage.getStringList('mc_unlockedAvatars', []),
          containsAll(['🐲', '👽']));
      expect(Storage.getStringList('mc_unlockedHats', []), contains('🎩'));

      await state.load();
      expect(Storage.getStringList('mc_shopOwned', []).toSet().length,
          Storage.getStringList('mc_shopOwned', []).length);
    });

    test('F legacy daily and login dates normalize to Flutter keys', () async {
      final now = DateTime.now();
      final legacyToday = jsDateString(now);
      final state = await makeState({
        'mc_dailyCoinsDate': legacyToday,
        'mc_dailyBossClaimed': legacyToday,
        'mc_dailyChallenges': jsonEncode({
          'date': legacyToday,
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
        'mc_loginStreak': jsonEncode(4),
        'mc_streakLastDay': todayKey(),
      });

      expect(state.isDailyCoinsClaimedToday, isTrue);
      expect(state.isDailyBossClaimedToday, isTrue);
      expect(state.dailyChallengeIds, ['blitz_15', 'streak_7', 'division_10']);
      expect(Storage.getString('mc_dailyCoinsDate', ''), todayKey());
      expect(Storage.getString('mc_dailyBossClaimed', ''), todayKey());
      expect(Storage.getInt('mc_loginStreak', 0), 4);
      expect(Storage.containsKey('mc_lastLoginDay'), isTrue);

      final dailyChallenges =
          jsonDecode(Storage.getString('mc_dailyChallenges', ''));
      expect(dailyChallenges['date'], todayKey());
      expect(dailyChallenges['challenges'],
          ['blitz_15', 'streak_7', 'division_10']);

      final dailyProgress =
          jsonDecode(Storage.getString('mc_dailyProgress', ''));
      expect(dailyProgress['blitz_15']['current'], 15);
      expect(dailyProgress['blitz_15']['completed'], isTrue);

      await state.load();
      expect(Storage.getInt('mc_loginStreak', 0), 4);
      expect(Storage.getString('mc_dailyCoinsDate', ''), todayKey());
    });

    test('G migration is idempotent and does not delete separate legacy keys',
        () async {
      final legacyAchs = jsonEncode([
        {'id': 'first_win', 'unlocked': true},
      ]);
      final legacySkills = jsonEncode({
        'addition': {'correct': 3, 'count': 4, 'mastery': 55},
      });
      final legacyPlayer = jsonEncode({'name': 'Legacy', 'avatar': '🐼'});
      final state = await makeState({
        'mc_coins': jsonEncode(25),
        'mc_achs': legacyAchs,
        'mc_skills': legacySkills,
        'mc_numTypeUnlocked': jsonEncode({'integers': true}),
        'mc_p1Data': legacyPlayer,
      });

      final achievementOnce = Storage.getString('mc_achievements', '');
      final skillOnce = Storage.getString('mc_skillMap', '');
      final coinsOnce = Storage.getInt('mc_coins', 0);

      await state.load();

      expect(Storage.getString('mc_achievements', ''), achievementOnce);
      expect(Storage.getString('mc_skillMap', ''), skillOnce);
      expect(Storage.getInt('mc_coins', 0), coinsOnce);
      expect(Storage.getString('mc_achs', ''), legacyAchs);
      expect(Storage.getString('mc_skills', ''), legacySkills);
      expect(Storage.getString('mc_p1Data', ''), legacyPlayer);
      expect(Storage.getString('mc_numTypeUnlocked', ''), isNotEmpty);
    });
  });
}
