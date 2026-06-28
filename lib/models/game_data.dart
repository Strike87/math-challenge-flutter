/// Master Mode level definition — 5 story stages with bosses.
class MasterLevel {
  final String name;
  final String type; // operation or 'mixed'
  final String diff; // difficulty key
  final int goal; // correct answers needed
  final int time; // seconds per question
  final String boss; // boss emoji
  final String numType; // 'natural' | 'integers' | 'rationals' | 'mixed'
  final String story; // shown after stage cleared

  const MasterLevel({
    required this.name,
    required this.type,
    required this.diff,
    required this.goal,
    required this.time,
    required this.boss,
    required this.numType,
    required this.story,
  });
}

/// Daily Boss definition — one per day, deterministic.
class DailyBoss {
  final String name;
  final String icon;
  final String type;
  final String diff;
  final int goal;
  final int time;
  final String numType;
  final int reward;
  final String theme;
  final String desc;

  const DailyBoss({
    required this.name,
    required this.icon,
    required this.type,
    required this.diff,
    required this.goal,
    required this.time,
    required this.numType,
    required this.reward,
    required this.theme,
    required this.desc,
  });
}

/// Achievement definition — 14 unlockables.
class Achievement {
  final String id;
  final String name;
  final String desc;
  final String icon;

  const Achievement({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
  });
}

/// Daily challenge definition — 6 rotating challenges.
class DailyChallenge {
  final String id;
  final String title;
  final String desc;
  final int reward;
  final String type;
  final int target;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.desc,
    required this.reward,
    required this.type,
    required this.target,
  });
}

/// Shop item (avatar / hat / pack).
class ShopItem {
  final String id;
  final String emoji;
  final String name;
  final int price;
  final bool consumable;
  final String? special;

  const ShopItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
    this.consumable = false,
    this.special,
  });
}

/// Hall of Fame entry.
class HighScore {
  final String name;
  final int score;
  final String mode;
  final String date;

  const HighScore({
    required this.name,
    required this.score,
    required this.mode,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'mode': mode,
        'date': date,
      };

  static HighScore fromJson(Map<String, dynamic> j) => HighScore(
        name: j['name'] as String? ?? 'Player',
        score: (j['score'] as num?)?.toInt() ?? 0,
        mode: j['mode'] as String? ?? 'standard',
        date: j['date'] as String? ?? '',
      );
}

/// Per-skill mastery tracking.
class SkillData {
  int easy;
  int medium;
  int hard;
  int expert;
  int insane;
  int correct;
  int count;
  double mastery;
  double confidence;

  SkillData({
    this.easy = 0,
    this.medium = 0,
    this.hard = 0,
    this.expert = 0,
    this.insane = 0,
    this.correct = 0,
    this.count = 0,
    this.mastery = 20,
    this.confidence = 0,
  });

  Map<String, dynamic> toJson() => {
        'easy': easy,
        'medium': medium,
        'hard': hard,
        'expert': expert,
        'insane': insane,
        'correct': correct,
        'count': count,
        'mastery': mastery,
        'confidence': confidence,
      };

  static SkillData fromJson(Map<String, dynamic> j) => SkillData(
        easy: (j['easy'] as num?)?.toInt() ?? 0,
        medium: (j['medium'] as num?)?.toInt() ?? 0,
        hard: (j['hard'] as num?)?.toInt() ?? 0,
        expert: (j['expert'] as num?)?.toInt() ?? 0,
        insane: (j['insane'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
        mastery: (j['mastery'] as num?)?.toDouble() ?? 20,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      );
}
