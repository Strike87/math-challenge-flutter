import 'enums.dart';

/// A single generated math question.
class Question {
  final Operation type;
  final String key;
  final String text;
  final num ans;
  final List<num> choices;
  final String? boss;
  final Difficulty? diff;
  final NumberType? numType;
  final int? ratDP;

  const Question({
    required this.type,
    required this.key,
    required this.text,
    required this.ans,
    required this.choices,
    this.boss,
    this.diff,
    this.numType,
    this.ratDP,
  });

  @override
  String toString() => 'Question($text → $ans)';
}

/// Player runtime data for one game session.
class PlayerState {
  String name;
  Object avatar; // String emoji or AvatarCustom
  int score;
  int correct;
  int total;
  int timeMs;
  int skipped;
  int fastest;
  int bonus;
  int streak;
  int maxStreak;
  List<HistoryEntry> history;
  List<PowerUp> pups;
  bool doubleActive;
  bool shieldActive;

  PlayerState({
    this.name = 'Player',
    this.avatar = '🐶',
    this.score = 0,
    this.correct = 0,
    this.total = 0,
    this.timeMs = 0,
    this.skipped = 0,
    this.fastest = 999999999,
    this.bonus = 0,
    this.streak = 0,
    this.maxStreak = 0,
    List<HistoryEntry>? history,
    List<PowerUp>? pups,
    this.doubleActive = false,
    this.shieldActive = false,
  })  : history = history ?? [],
        pups = pups ?? [];

  /// Reset to fresh game session values while keeping name + avatar.
  void resetForGame(
      {required bool isSinglePlayer, required bool isMasterOrBoss}) {
    score = 0;
    correct = 0;
    total = 0;
    timeMs = 0;
    skipped = 0;
    fastest = 999999999;
    bonus = 0;
    streak = 0;
    maxStreak = 0;
    history = [];
    // Only single-player non-boss Standard mode awards all 6 starting power-ups.
    pups =
        (isSinglePlayer && !isMasterOrBoss) ? [...PowerUp.values] : <PowerUp>[];
    doubleActive = false;
    shieldActive = false;
  }

  /// Average answer time in milliseconds (0 if no answers yet).
  double get avgMs => total == 0 ? 0 : timeMs / total;

  /// Accuracy as a percentage (0–100).
  double get accuracy => total == 0 ? 0 : (correct / total) * 100;
}

class HistoryEntry {
  final Operation type;
  final bool correct;
  final int ms;

  const HistoryEntry({
    required this.type,
    required this.correct,
    required this.ms,
  });
}

/// Custom avatar data (built via the avatar builder).
class AvatarCustom {
  final String base;
  final String hat;
  final String accessory;
  final String? color;

  const AvatarCustom({
    this.base = '🐶',
    this.hat = '',
    this.accessory = '',
    this.color,
  });

  Map<String, dynamic> toJson() => {
        'base': base,
        'hat': hat,
        'accessory': accessory,
        'color': color,
      };

  static AvatarCustom fromJson(Map<String, dynamic> j) => AvatarCustom(
        base: (j['base'] as String?) ?? '🐶',
        hat: (j['hat'] as String?) ?? '',
        accessory: (j['accessory'] as String?) ?? '',
        color: j['color'] as String?,
      );
}
