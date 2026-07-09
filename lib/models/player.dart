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
  static const int noFastestTime = 999999999;

  String name;
  AvatarData _avatar;
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
    AvatarData avatar = const AvatarData.emoji('🐶'),
    this.score = 0,
    this.correct = 0,
    this.total = 0,
    this.timeMs = 0,
    this.skipped = 0,
    this.fastest = noFastestTime,
    this.bonus = 0,
    this.streak = 0,
    this.maxStreak = 0,
    List<HistoryEntry>? history,
    List<PowerUp>? pups,
    this.doubleActive = false,
    this.shieldActive = false,
  })  : _avatar = avatar,
        history = history ?? [],
        pups = pups ?? [];

  AvatarData get avatar => _avatar;

  set avatar(Object value) {
    _avatar = AvatarData.from(value);
  }

  /// Reset to fresh game session values while keeping name + avatar.
  void resetForGame(
      {required bool isSinglePlayer, required bool isMasterOrBoss}) {
    score = 0;
    correct = 0;
    total = 0;
    timeMs = 0;
    skipped = 0;
    fastest = noFastestTime;
    bonus = 0;
    streak = 0;
    maxStreak = 0;
    history = [];
    pups = <PowerUp>[];
    doubleActive = false;
    shieldActive = false;
  }

  /// Average answer time in milliseconds (0 if no answers yet).
  double get avgMs => total == 0 ? 0 : timeMs / total;

  /// Accuracy as a percentage (0–100).
  double get accuracy => total == 0 ? 0 : (correct / total) * 100;
}

/// Typed avatar value: either an emoji base or a custom avatar stack.
class AvatarData {
  const AvatarData.emoji(this.emoji) : custom = null;

  const AvatarData.custom(this.custom) : emoji = null;

  factory AvatarData.from(Object value) {
    if (value is AvatarData) return value;
    if (value is AvatarCustom) return AvatarData.custom(value);
    if (value is String && value.trim().isNotEmpty) {
      return AvatarData.emoji(value);
    }
    return const AvatarData.emoji('🐶');
  }

  final String? emoji;
  final AvatarCustom? custom;

  bool get isCustom => custom != null;
  String get base => custom?.base ?? emoji ?? '🐶';
  String get storageEmoji => emoji ?? base;

  @override
  bool operator ==(Object other) {
    if (other is String) return emoji == other;
    if (other is AvatarCustom) return custom == other;
    return other is AvatarData &&
        other.emoji == emoji &&
        other.custom == custom;
  }

  @override
  int get hashCode => Object.hash(emoji, custom);

  @override
  String toString() => custom?.toString() ?? emoji ?? '🐶';
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

  @override
  bool operator ==(Object other) {
    return other is AvatarCustom &&
        other.base == base &&
        other.hat == hat &&
        other.accessory == accessory &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(base, hat, accessory, color);
}
