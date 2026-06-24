import 'models/game_data.dart';

/// All static game content and tunable constants in one place.
class GameConfig {
  GameConfig._();

  // ─── Avatar parts ────────────────────────────────────────────
  static const List<String> avatarBases = [
    '🐶','🐱','🦁','🐸','🐼','🦊','🐯','🦋','🐙','🦉','🐧',
  ];
  static const List<String> avatarHats = [
    '','🎓','🧢','🪖','👒','🎀','🌸',
  ];
  static const List<String> avatarAccessories = [
    '','👓','🕶️','🧣','🧤','👑','💍','📿','🎀','🪭','⌚','🧸','💎','🏅','🪆',
  ];
  static const List<String?> avatarColors = [
    null, '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FECA57', '#FF9FF3', '#A29BFE', '#54A0FF',
  ];

  // ─── Difficulty / phase ──────────────────────────────────────
  static const List<String> phaseKeys = ['easy','medium','hard','expert','insane'];
  static const List<String> phaseNames = ['Easy','Medium','Hard','Expert','INSANE'];
  static const List<String> phaseNamesBanner = ['Easy','Medium','Hard','Expert','💀 INSANE'];
  static const List<int> phaseColors = [0xFF4CAF50, 0xFFFF9800, 0xFFF44336, 0xFF9C27B0, 0xFFFF0080];
  static const List<int> phaseTimesMs = [15000, 12000, 10000, 8000, 6000];
  static const List<int> phaseBonus = [0, 2, 4, 7, 10];

  // ─── Streak / combo ──────────────────────────────────────────
  static const List<int> streakThresholds = [5, 10, 20];
  static const List<int> streakCoins = [2, 5, 10];
  static const List<int> comboThresholds = [3, 5, 10];
  static const List<int> comboMultipliers = [2, 3, 5];

  // ─── Timer tunables ──────────────────────────────────────────
  static const int msPerDay = 86400000;
  static const int blitzTimerDefault = 60000;       // 60 s
  static const int comboTimerDefault = 90000;       // 90 s
  static const int timerMinMs = 3000;
  static const int timerPenaltyStep = 3;
  static const Map<String, int> timerBaseMs = {
    'easy': 10000, 'medium': 8000, 'hard': 6000, 'expert': 5000, 'insane': 4000,
  };

  // ─── Scoring ─────────────────────────────────────────────────
  static const int scoreBase = 10;
  static const int scoreFastBonus = 2;
  static const int scoreStreakBonus = 1;
  static const int puRewardInterval = 3;

  // ─── Reaction copy ───────────────────────────────────────────
  static const List<String> correctRx = [
    '🎉 Excellent!','🥳 Well done!','🤩 Wow!','👍 Great!','💯 Perfect!','⭐ Super!','🔥 On Fire!',
  ];
  static const List<String> wrongRx = [
    '🙈 Oops!','😥 Oh no!','🤔 Close!','😕 Next time!','😬 Almost!',
  ];

  // ─── Master Mode levels ──────────────────────────────────────
  static const List<MasterLevel> masterLevels = [
    MasterLevel(
      name: 'The Jungle',
      type: 'addition', diff: 'easy', goal: 5, time: 10,
      boss: '🦍', numType: 'natural',
      story: "You defeated the Gorilla! The path is clear — but a wide river blocks your way.",
    ),
    MasterLevel(
      name: 'River Crossing',
      type: 'subtraction', diff: 'medium', goal: 10, time: 9,
      boss: '🐊', numType: 'natural',
      story: "You crossed safely! Ahead, ancient stone ruins rise from the mist.",
    ),
    MasterLevel(
      name: 'Ancient Ruins',
      type: 'multiplication', diff: 'medium', goal: 15, time: 8,
      boss: '🗿', numType: 'integers',
      story: "The Stone Guardian crumbles! You enter a dark tunnel. It's getting warmer...",
    ),
    MasterLevel(
      name: "Dragon's Cave",
      type: 'mixed', diff: 'hard', goal: 20, time: 7,
      boss: '🐲', numType: 'rationals',
      story: 'The Dragon bows in defeat! The Treasure Vault stands before you.',
    ),
    MasterLevel(
      name: 'Treasure Vault',
      type: 'mixed', diff: 'hard', goal: 25, time: 6,
      boss: '🧞', numType: 'mixed',
      story: '',
    ),
  ];

  // ─── Daily Bosses ────────────────────────────────────────────
  static const List<DailyBoss> dailyBosses = [
    DailyBoss(name: 'Lava Dragon', icon: '🐲', type: 'mixed',
      diff: 'medium', goal: 12, time: 9, numType: 'integers',
      reward: 50, theme: 'atm-cave', desc: 'Hot integer problems with no mercy.'),
    DailyBoss(name: 'Clockwork Sphinx', icon: '🦁', type: 'multiplication',
      diff: 'hard', goal: 10, time: 8, numType: 'natural',
      reward: 45, theme: 'atm-ruins', desc: 'Fast multiplication in ancient gears.'),
    DailyBoss(name: 'Frost Kraken', icon: '🐙', type: 'division',
      diff: 'medium', goal: 10, time: 9, numType: 'rationals',
      reward: 55, theme: 'atm-ocean', desc: 'Decimal division from the deep.'),
    DailyBoss(name: 'Storm Golem', icon: '🗿', type: 'subtraction',
      diff: 'hard', goal: 12, time: 8, numType: 'integers',
      reward: 50, theme: 'atm-mountain', desc: 'Negative numbers under pressure.'),
    DailyBoss(name: 'Solar Phoenix', icon: '🔥', type: 'addition',
      diff: 'hard', goal: 14, time: 7, numType: 'rationals',
      reward: 60, theme: 'atm-vault', desc: 'Decimal addition at sunrise.'),
    DailyBoss(name: 'Nebula Hydra', icon: '🐉', type: 'mixed',
      diff: 'hard', goal: 15, time: 7, numType: 'mixed',
      reward: 65, theme: 'atm-space', desc: 'A mixed-operation boss from the stars.'),
  ];

  // ─── Achievements ────────────────────────────────────────────
  static const List<Achievement> achievementsDef = [
    Achievement(id: 'first_win', name: 'First Victory', desc: 'Win your first game', icon: '🏆'),
    Achievement(id: 'speed_demon', name: 'Speed Demon', desc: 'Answer 5 questions under 2s each', icon: '⚡'),
    Achievement(id: 'perfect_score', name: 'Perfect Score', desc: '100% accuracy in a game', icon: '💯'),
    Achievement(id: 'streak_master', name: 'Streak Master', desc: 'Get a 10-question streak', icon: '🔥'),
    Achievement(id: 'power_upper', name: 'Power Upper', desc: 'Use 5 power-ups in one game', icon: '✨'),
    Achievement(id: 'math_wizard', name: 'Math Wizard', desc: 'Complete Master Stage 3', icon: '🧙'),
    Achievement(id: 'persistent', name: 'Persistent', desc: 'Play 10 games total', icon: '🔄'),
    Achievement(id: 'quick_learner', name: 'Quick Learner', desc: 'Reach adaptive difficulty level 8', icon: '🚀'),
    Achievement(id: 'survivor', name: 'Survivor', desc: 'Score 250+ in Sudden Death mode', icon: '💀'),
    Achievement(id: 'avatar_artist', name: 'Avatar Artist', desc: 'Create a custom avatar', icon: '🎨'),
    Achievement(id: 'skill_master', name: 'Skill Master', desc: 'Reach 90% in any skill category', icon: '📈'),
    Achievement(id: 'daily_grind', name: 'Daily Grind', desc: 'Complete 3 daily challenges', icon: '🎁'),
    Achievement(id: 'daily_boss', name: 'Boss Breaker', desc: 'Defeat a Daily Boss', icon: '🐲'),
    Achievement(id: 'math_legend', name: 'Math Legend', desc: 'Beat all 5 Master mode stages', icon: '👑'),
  ];

  // ─── Daily Challenges ────────────────────────────────────────
  static const List<DailyChallenge> dailyChallenges = [
    DailyChallenge(id: 'blitz_15', title: 'Blitz Master',
      desc: 'Answer 15 questions in Blitz mode', reward: 50, type: 'blitz', target: 15),
    DailyChallenge(id: 'streak_7', title: 'Streak Star',
      desc: 'Get a 7-question streak', reward: 30, type: 'streak', target: 7),
    DailyChallenge(id: 'division_10', title: 'Division Pro',
      desc: 'Answer 10 division questions correctly', reward: 40, type: 'division', target: 10),
    DailyChallenge(id: 'master_stage', title: 'Stage Clear',
      desc: 'Clear any Master mode stage', reward: 100, type: 'master', target: 1),
    DailyChallenge(id: 'daily_boss', title: 'Boss Breaker',
      desc: "Defeat today's Daily Boss", reward: 75, type: 'dailyBoss', target: 1),
    DailyChallenge(id: 'perfect_5', title: 'Perfect Round',
      desc: 'Get 5 questions in a row with 100% accuracy', reward: 60, type: 'perfect', target: 5),
  ];

  // ─── Coin shop items ────────────────────────────────────────
  static const Map<String, List<ShopItem>> shopItems = {
    'avatars': [
      ShopItem(id: 'av_dragon', emoji: '🐉', name: 'Dragon', price: 300),
      ShopItem(id: 'av_robot', emoji: '🤖', name: 'Robot', price: 200),
      ShopItem(id: 'av_alien', emoji: '👽', name: 'Alien', price: 200),
      ShopItem(id: 'av_ninja', emoji: '🥷', name: 'Ninja', price: 400),
      ShopItem(id: 'av_wizard', emoji: '🧙', name: 'Wizard', price: 400),
      ShopItem(id: 'av_unicorn', emoji: '🦄', name: 'Unicorn', price: 350),
    ],
    'hats': [
      ShopItem(id: 'hat_crown', emoji: '👑', name: 'Crown', price: 150),
      ShopItem(id: 'hat_wizard', emoji: '🧙', name: 'Wizard', price: 180),
      ShopItem(id: 'hat_cap', emoji: '🎩', name: 'Top Hat', price: 100),
      ShopItem(id: 'hat_halo', emoji: '😇', name: 'Halo', price: 250),
      ShopItem(id: 'hat_fire', emoji: '🔥', name: 'Fire', price: 300),
      ShopItem(id: 'hat_star', emoji: '⭐', name: 'Star', price: 120),
    ],
    'packs': [
      ShopItem(id: 'pack_powerups', emoji: '🎒',
        name: 'Power Pack\n×5 of each power-up', price: 500, consumable: true),
      ShopItem(id: 'pack_coins100', emoji: '💎',
        name: '+100 Coins\nDaily bonus', price: 0, special: 'watch'),
      ShopItem(id: 'pack_lives', emoji: '❤️',
        name: 'Extra Life\nFor Master mode', price: 450, consumable: true),
    ],
  };

  // ─── Theme palette ───────────────────────────────────────────
  static const int coral = 0xFFFF5757;
  static const int mango = 0xFFFF9B21;
  static const int sky = 0xFF00C2FF;
  static const int mint = 0xFF00D68F;
  static const int grape = 0xFF8457E9;
  static const int lemon = 0xFFFFE135;
  static const int punch = 0xFFFF3D71;
  static const int coin = 0xFFFFD700;

  static const int bgLight = 0xFFFDF8F3;
  static const int bgDark = 0xFF13110F;
  static const int textLight = 0xFF1E1B18;
  static const int textDark = 0xFFF5F0E8;
  static const int mutedLight = 0xFF7A6B5E;
  static const int mutedDark = 0xFFA89B8A;
  static const int borderLight = 0xFFFFE4C8;
  static const int borderDark = 0xFF3D3530;
}
