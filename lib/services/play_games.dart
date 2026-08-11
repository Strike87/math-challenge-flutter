import 'package:flutter/services.dart';

enum PlayGamesConnectionState {
  checking,
  connected,
  disconnected,
  unavailable,
}

const playGamesAchievementIds = <String, String>{
  'first_win': 'CgkI5OSTrucWEAIQEA',
  'speed_demon': 'CgkI5OSTrucWEAIQBg',
  'perfect_score': 'CgkI5OSTrucWEAIQDg',
  'streak_master': 'CgkI5OSTrucWEAIQCQ',
  'power_upper': 'CgkI5OSTrucWEAIQDw',
  'math_wizard': 'CgkI5OSTrucWEAIQCg',
  'persistent': 'CgkI5OSTrucWEAIQCA',
  'quick_learner': 'CgkI5OSTrucWEAIQBw',
  'survivor': 'CgkI5OSTrucWEAIQBQ',
  'avatar_artist': 'CgkI5OSTrucWEAIQDQ',
  'skill_master': 'CgkI5OSTrucWEAIQCw',
  'daily_grind': 'CgkI5OSTrucWEAIQBA',
  'daily_boss': 'CgkI5OSTrucWEAIQAw',
  'math_legend': 'CgkI5OSTrucWEAIQDA',
};

abstract class PlayGamesService {
  Future<void> initializePgs();

  Future<bool> isAuthenticated();

  Future<bool> connect();

  Future<void> unlockAchievement(String localAchievementId);

  Future<void> reconcileUnlockedAchievements(
    Map<String, bool> achievements,
  ) async {
    for (final achievement in achievements.entries) {
      if (!achievement.value) continue;
      try {
        await unlockAchievement(achievement.key);
      } catch (_) {
        // Best effort: one remote failure must not block the remaining IDs.
      }
    }
  }
}

class NativePlayGamesService extends PlayGamesService {
  NativePlayGamesService();

  static const _channel = MethodChannel('math_challenge/play_games');

  @override
  Future<void> initializePgs() => _channel.invokeMethod<void>('initializePgs');

  @override
  Future<bool> isAuthenticated() async =>
      await _channel.invokeMethod<bool>('isAuthenticated') ?? false;

  @override
  Future<bool> connect() async =>
      await _channel.invokeMethod<bool>('connect') ?? false;

  @override
  Future<void> unlockAchievement(String localAchievementId) async {
    final googleId = playGamesAchievementIds[localAchievementId];
    if (googleId == null) {
      throw ArgumentError.value(
        localAchievementId,
        'localAchievementId',
        'Unknown Play Games achievement',
      );
    }
    await _channel.invokeMethod<void>(
      'unlockAchievement',
      {'achievementId': googleId},
    );
  }
}
