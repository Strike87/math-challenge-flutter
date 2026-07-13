import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

import '../features/economy/domain/coin_ledger.dart';
import '../features/economy/domain/daily_bonus_policy.dart';
import '../features/modals/presentation/toast_controller.dart';
import '../game_config.dart';
import '../models/celebration.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/game_data.dart';
import '../services/storage.dart';
import '../services/settings.dart';
import '../services/audio.dart';
import '../services/iap.dart';
import '../services/admob.dart';
import 'question_generator.dart';

/// Screen identifier — mirrors the original HTML section IDs.
enum GameScreen { menu, numType, config, player, game }

/// Modal identifier — mirrors the original HTML modal IDs.
enum GameModal {
  none,
  settings,
  masterIntro,
  dailyBoss,
  stageCleared,
  win,
  quitConfirm,
  highScore,
  achievements,
  tutorial,
  avatarBuilder,
  skillDashboard,
  coinShop,
  adultGate,
  dailyChallenges,
}

/// Runtime game state (the `rt` object in the original JS).
class RuntimeState {
  Operation challenge;
  int activePlayer;
  Question? q;
  String state; // 'idle' | 'playing' | 'paused' | 'ended'
  bool accepting;
  num? selectedAnswer;
  bool lastAnswerCorrect;
  bool gameActive;
  int totalTurns;
  int maxTurns;
  List<String> newAchs;
  int puUsed;
  int fastAnswers;
  int qStartTs;
  final Set<String> usedFacts;
  Timer? timer;
  int timerStart;
  int timerDurationMs;
  int timerElapsedAtPause;
  int qTimerLimit;
  int blitzTotalMs;
  int blitzElapsedMs;
  int combo;
  double comboMultiplier;
  int comboStreak;
  int comboMaxMultiplier;
  int warmUpCount;
  bool isWarmUp;
  int survivalLives;
  int survivalPhase;
  int survivalCorrect;
  DailyBoss? dailyBoss;
  int dailyBossLives;
  int dailyBossProgress;
  int dailyBossRewardEarned;
  bool dailyBossWon;
  bool frozen;
  String bossMood;
  bool isFollowUp;
  _FollowUpData? followUpData;
  int lastDailyBossClaimDay;

  RuntimeState()
      : challenge = Operation.mixed,
        activePlayer = 1,
        q = null,
        state = 'idle',
        accepting = false,
        selectedAnswer = null,
        lastAnswerCorrect = false,
        gameActive = false,
        totalTurns = 0,
        maxTurns = 0,
        newAchs = [],
        puUsed = 0,
        fastAnswers = 0,
        qStartTs = 0,
        usedFacts = {},
        timer = null,
        timerStart = 0,
        timerDurationMs = 0,
        timerElapsedAtPause = 0,
        qTimerLimit = 0,
        blitzTotalMs = GameConfig.blitzTimerDefault,
        blitzElapsedMs = 0,
        combo = 0,
        comboMultiplier = 1.0,
        comboStreak = 0,
        comboMaxMultiplier = 1,
        warmUpCount = 0,
        isWarmUp = false,
        survivalLives = 3,
        survivalPhase = 0,
        survivalCorrect = 0,
        dailyBoss = null,
        dailyBossLives = 3,
        dailyBossProgress = 0,
        dailyBossRewardEarned = 0,
        dailyBossWon = false,
        frozen = false,
        bossMood = 'normal',
        isFollowUp = false,
        followUpData = null,
        lastDailyBossClaimDay = -1;
}

class _FollowUpData {
  final Operation type;
  final Difficulty diff;
  _FollowUpData(this.type, this.diff);
}

/// The central game state controller.
///
/// Holds:
/// - persistent data (coins, achievements, high scores, skills, etc.)
/// - runtime state (current question, timer, scores)
/// - options (mode, difficulty, etc.)
/// - screen + modal routing
class GameState extends ChangeNotifier {
  GameState({
    required this.settings,
    required this.audio,
    IapPurchaseAdapter? iapAdapter,
    Stream<List<IapPurchase>>? iapPurchaseStream,
    AdMobService? adService,
    AdultGateChallenge Function()? adultGateFactory,
    int Function()? nowMillisProvider,
  })  : iapAdapter = iapAdapter ?? const UnavailableIapPurchaseAdapter(),
        adService = adService ?? const UnavailableAdMobService(),
        _nowMillis =
            nowMillisProvider ?? (() => DateTime.now().millisecondsSinceEpoch),
        _adultGateFactory =
            adultGateFactory ?? (() => AdultGateChallenge.random()) {
    _toastController = ToastController(onChanged: notifyListeners);
    _iapPurchaseSub = iapPurchaseStream?.listen((purchases) {
      for (final purchase in purchases) {
        unawaited(handleIapPurchase(purchase));
      }
    });
  }

  static const int _masteryFastMs = 1500;
  static const int _masteryNormalMs = 3000;
  static const double _masteryGainFast = 7;
  static const double _masteryGainNormal = 5;
  static const double _masteryGainSlow = 3;
  static const double _masteryPenalty = -4;
  static const double _masteryPenaltyTimeout = -2;
  static const double _masteryMax = 100;
  static const double _masteryDefault = 20;
  static const double _confidenceSpeedDivisor = 120;
  static const double _confidenceEmaAlpha = 0.25;
  static const double _confidenceDefault = 50;
  static const int _confidenceDefaultMs = 5000;
  static const double _adaptThresholdEasy = 45;
  static const double _adaptThresholdMedium = 65;
  static const double _adaptThresholdHard = 82;
  static const double _adaptThresholdExpert = 93;
  static const int dailyBonusCoins = 20;
  static const int rewardedAdCoins = 10;
  static const int rewardedCooldownMs = 300000;
  static const int interstitialCadenceGames = 3;

  static const Map<PowerUp, String> _powerUpBonusStorageKeys = {
    PowerUp.time: 'time',
    PowerUp.fifty: 'fifty',
    PowerUp.double: 'double',
    PowerUp.shield: 'shield',
    PowerUp.freeze: 'freeze',
    PowerUp.switchOp: 'switch',
  };

  static const List<String> _resetStorageKeys = [
    'mc_coins',
    'mc_scores',
    'mc_gamesPlayed',
    'mc_adaptLvl',
    'mc_achs',
    'mc_achievements',
    'mc_achievements_raw',
    'mc_skills',
    'mc_skillMap',
    'mc_skillMap_raw',
    'mc_numTypeUnlocked',
    'mc_numTypeUnlocked_integers',
    'mc_numTypeUnlocked_rationals',
    'mc_unlocked_integers',
    'mc_unlocked_rationals',
    'mc_loginStreak',
    'mc_streakLastDay',
    'mc_lastLoginDay',
    'mc_avatarCustom',
    'mc_avatarCustom1',
    'mc_avatarCustom2',
    'mc_p1Data',
    'mc_p1_name',
    'mc_p1_avatar',
    'mc_p2Data',
    'mc_p2_name',
    'mc_p2_avatar',
    'mc_dailyProgress',
    'mc_dailyProgress_raw',
    'mc_dailyChallenges',
    'mc_dailyCoinsDate',
    'mc_dailyBossClaimed',
    'mc_lastDailyBossClaimDay',
    'mc_puBonus',
    'mc_livesBonus',
    'mc_shopOwned',
    'mc_unlockedAvatars',
    'mc_unlockedHats',
    'mc_adsRemoved',
    'mc_iapDeliveredTxs',
    'mc_lastRewardedAt',
    'mc_adGameCount',
    'mc_sound',
    'mc_dark',
    'mc_vibration',
    'mc_dyslexia',
    'mc_colorblind',
    'mc_animSpeed',
    'mc_reduceMotion',
    'mc_lowPerf',
  ];

  @visibleForTesting
  static List<String> get debugResetStorageKeys =>
      List.unmodifiable(_resetStorageKeys);

  final SettingsService settings;
  final AudioService audio;
  final IapPurchaseAdapter iapAdapter;
  final AdMobService adService;
  final AdultGateChallenge Function() _adultGateFactory;
  final int Function() _nowMillis;
  final QuestionGenerator _qgen = QuestionGenerator();
  final Random _rng = Random();
  StreamSubscription<List<IapPurchase>>? _iapPurchaseSub;

  // Master-mode progression state (kept outside `rt` because it survives
  // stage-clear modal round-trips but is reset on quit).
  int _masterLevel = 0;
  int _masterLives = 3;
  int _masterProgress = 0;

  // ─── Options ────────────────────────────────────────────────
  int players = 2;
  GameMode mode = GameMode.standard;
  Difficulty diff = Difficulty.easy;
  int questionCount = 10;
  bool adaptive = true;
  NumberType numType = NumberType.natural;

  // ─── Runtime ────────────────────────────────────────────────
  late RuntimeState rt = RuntimeState();
  late List<PlayerState> p = [
    PlayerState(),
    PlayerState(name: 'Player 1', avatar: const AvatarData.emoji('🐶')),
    PlayerState(name: 'Player 2', avatar: const AvatarData.emoji('🐱'))
  ];

  // ─── Persistent ─────────────────────────────────────────────
  final CoinLedger _coinLedger = CoinLedger();
  final DailyBonusPolicy _dailyBonusPolicy = DailyBonusPolicy();
  int get coins => _coinLedger.balance;
  set coins(int value) => _coinLedger.balance = value;
  int gamesPlayed = 0;
  double adaptLvlRaw = 0;
  int adaptLvl = 0;
  Map<String, bool> achievements = {};
  List<HighScore> highScores = [];
  Map<String, SkillData> skillMap = {};
  Map<String, int> numTypeUnlocked = {'integers': 0, 'rationals': 0};
  int loginStreak = 0;
  Map<String, AvatarCustom> avatarCustom = {
    '1': AvatarCustom(base: '🐶'),
    '2': AvatarCustom(base: '🐸'),
  };
  Map<String, int> dailyProgress = {};
  Map<String, bool> dailyCompleted = {};
  List<String> dailyChallengeIds = [];
  DailyBoss? dailyBoss;
  String dailyBossDateKey = '';
  List<String> shopOwned = [];
  List<String> unlockedAvatars = [];
  List<String> unlockedHats = [];
  bool adsRemoved = false;
  List<String> iapDeliveredTxs = [];
  int adGameCount = 0;
  int lastRewardedAt = 0;
  bool _pendingInterstitialAd = false;

  // ─── UI routing ─────────────────────────────────────────────
  GameScreen currentScreen = GameScreen.menu;
  GameModal currentModal = GameModal.none;
  late final ToastController _toastController;
  String get toastMessage => _toastController.message;
  set toastMessage(String value) => _toastController.message = value;
  bool get toastVisible => _toastController.visible;
  set toastVisible(bool value) => _toastController.visible = value;
  String numTypeUnlockFeedback = '';
  Timer? _bigEmojiHideTimer;
  Timer? _postFeedbackTimer;
  Timer? _delayedResultModalTimer;
  Timer? _delayedLossTimer;
  int builderPid = 1;
  AvatarCustom builderAvatar = AvatarCustom();
  bool isDailyBossClaimedToday = false;
  String reactionPill = '';
  String bigEmoji = '';
  bool bigEmojiVisible = false;
  int screenShakeTick = 0;
  CelebrationEvent celebration = const CelebrationEvent.none();
  int _celebrationSeq = 0;
  int lastUnlockedAchievementCount = 0;
  List<Achievement> newlyUnlocked = [];
  String resultIcon = '🏆';
  String resultTitle = 'Player Report';
  String resultDescription = '';
  AdultGateChallenge? adultGateChallenge;
  IapProduct? pendingIapProduct;
  String adultGateError = '';
  bool adultGateBusy = false;
  GameModal _adultGateReturnModal = GameModal.none;
  int _turnSeq = 0;
  bool _disposed = false;

  MasterLevel? get clearedMasterLevel {
    final idx = _masterLevel - 1;
    if (currentModal != GameModal.stageCleared ||
        idx < 0 ||
        idx >= GameConfig.masterLevels.length) {
      return null;
    }
    return GameConfig.masterLevels[idx];
  }

  MasterLevel? get nextMasterLevel {
    if (_masterLevel < 0 || _masterLevel >= GameConfig.masterLevels.length) {
      return null;
    }
    return GameConfig.masterLevels[_masterLevel];
  }

  MasterLevel? get currentMasterLevel {
    if (_masterLevel < 0 || _masterLevel >= GameConfig.masterLevels.length) {
      return null;
    }
    return GameConfig.masterLevels[_masterLevel];
  }

  int get masterLevel => _masterLevel;

  int get masterProgress => _masterProgress;

  int get masterLives => _masterLives;

  List<String> get availableAvatarBases =>
      _mergeUnlocked(GameConfig.avatarBases, unlockedAvatars);

  List<String> get availableAvatarHats =>
      _mergeUnlocked(GameConfig.avatarHats, unlockedHats);

  bool get isDailyCoinsClaimedToday {
    _hydrateDailyBonusPolicy();
    return _dailyBonusPolicy.isClaimedOn(_dailyDateKey());
  }

  List<DailyChallenge> get activeDailyChallenges {
    final byId = {for (final c in GameConfig.dailyChallenges) c.id: c};
    final ids = dailyChallengeIds.isEmpty
        ? GameConfig.dailyChallenges.take(3).map((c) => c.id)
        : dailyChallengeIds;
    return ids.map((id) => byId[id]).whereType<DailyChallenge>().toList();
  }

  List<String> _mergeUnlocked(List<String> base, List<String> unlocked) {
    final seen = <String>{};
    final out = <String>[];
    for (final emoji in [...base, ...unlocked]) {
      if (emoji.isEmpty || seen.contains(emoji)) continue;
      seen.add(emoji);
      out.add(emoji);
    }
    return out;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _turnSeq++;
    rt.gameActive = false;
    _iapPurchaseSub?.cancel();
    _toastController.dispose();
    _bigEmojiHideTimer?.cancel();
    _postFeedbackTimer?.cancel();
    _delayedResultModalTimer?.cancel();
    _cancelDelayedLossEnd();
    rt.timer?.cancel();
    super.dispose();
  }

  // ─── Load / save ────────────────────────────────────────────
  Future<void> load() async {
    coins = Storage.getInt('mc_coins', 0);
    gamesPlayed = Storage.getInt('mc_gamesPlayed', 0);
    adaptLvlRaw = Storage.getDouble('mc_adaptLvl', 0);
    adaptLvl = adaptLvlRaw.round();
    achievements = _loadAchs();
    highScores = List<HighScore>.from(Storage.getObjectList<HighScore>(
        'mc_scores', (j) => HighScore.fromJson(j)));
    coins = Storage.getInt('mc_coins', 0);
    skillMap = _loadSkillMap();
    _recomputeAdaptiveLevel();
    numTypeUnlocked = _loadNumTypeUnlocked();
    loginStreak = Storage.getInt('mc_loginStreak', 0);
    avatarCustom['1'] = _loadAvatarCustom(1);
    avatarCustom['2'] = _loadAvatarCustom(2);
    dailyProgress = _loadDailyProgress();
    dailyChallengeIds = _loadDailyChallengeIds();
    final today = DateTime.now();
    dailyBossDateKey = _dailyDateKey(today);
    dailyBoss = _generateDailyBoss(today);
    shopOwned = _loadOwnedList('mc_shopOwned');
    unlockedAvatars = _loadStringListCompat('mc_unlockedAvatars');
    unlockedHats = _loadStringListCompat('mc_unlockedHats');
    adsRemoved = Storage.getBool('mc_adsRemoved', false);
    iapDeliveredTxs = Storage.getStringList('mc_iapDeliveredTxs', []);
    adGameCount = Storage.getInt('mc_adGameCount', 0);
    lastRewardedAt = Storage.getInt('mc_lastRewardedAt', 0);
    await restorePurchases(silent: true);
    _loadPlayerData(1);
    _loadPlayerData(2);
    await _updateLoginStreak();
    _updateDailyBossClaimStatus();
    await _persistLoadedMigrationState();
    _hydrateDailyBonusPolicy();
    notifyListeners();
  }

  Future<void> save() async {
    await Storage.setInt('mc_coins', coins);
    await Storage.setInt('mc_gamesPlayed', gamesPlayed);
    await Storage.setDouble('mc_adaptLvl', adaptLvlRaw);
    await Storage.setString('mc_achievements', _encodeAchs());
    await Storage.setObjectList('mc_scores', highScores);
    await Storage.setString('mc_skillMap', _encodeSkillMap());
    await Storage.setInt(
        'mc_numTypeUnlocked_integers', numTypeUnlocked['integers'] ?? 0);
    await Storage.setInt(
        'mc_numTypeUnlocked_rationals', numTypeUnlocked['rationals'] ?? 0);
    await Storage.setInt('mc_loginStreak', loginStreak);
    await Storage.setObject('mc_avatarCustom1', avatarCustom['1']!.toJson());
    await Storage.setObject('mc_avatarCustom2', avatarCustom['2']!.toJson());
    await Storage.setString('mc_dailyProgress', _encodeDailyProgress());
    await Storage.setStringList('mc_shopOwned', shopOwned);
    await Storage.setStringList('mc_unlockedAvatars', unlockedAvatars);
    await Storage.setStringList('mc_unlockedHats', unlockedHats);
    await Storage.setBool('mc_adsRemoved', adsRemoved);
    await Storage.setStringList('mc_iapDeliveredTxs', iapDeliveredTxs);
    await Storage.setInt('mc_adGameCount', adGameCount);
    await Storage.setInt('mc_lastRewardedAt', lastRewardedAt);
    await Storage.setString('mc_p1_name', p[1].name);
    await Storage.setString('mc_p1_avatar', p[1].avatar.storageEmoji);
    await Storage.setString('mc_p2_name', p[2].name);
    await Storage.setString('mc_p2_avatar', p[2].avatar.storageEmoji);
  }

  Future<void> _persistLoadedMigrationState() async {
    await save();
    await Storage.setString(
      'mc_dailyChallenges',
      jsonEncode({'date': _dailyDateKey(), 'challenges': dailyChallengeIds}),
    );
    await _normalizeStoredDateKey('mc_dailyCoinsDate');
    await _migrateDailyBossClaimDate();
  }

  Future<void> _normalizeStoredDateKey(String key) async {
    final raw = Storage.getString(key, '');
    if (raw.isEmpty) return;
    final normalized = _normalizeDateKey(raw);
    if (_isDateKey(normalized)) {
      await Storage.setString(key, normalized);
    }
  }

  void _hydrateDailyBonusPolicy() {
    _dailyBonusPolicy.lastClaimDate =
        _normalizeDateKey(Storage.getString('mc_dailyCoinsDate', ''));
  }

  Future<void> _migrateDailyBossClaimDate() async {
    final raw = Storage.getString('mc_dailyBossClaimed', '');
    final normalized = _normalizeDateKey(raw);
    if (_isDateKey(normalized)) {
      await Storage.setString('mc_dailyBossClaimed', normalized);
      return;
    }

    final legacyDay = Storage.getInt('mc_lastDailyBossClaimDay', -1);
    if (legacyDay >= 0) {
      await Storage.setString(
          'mc_dailyBossClaimed', _dateKeyFromDayNumber(legacyDay));
    }
  }

  // ─── Helpers ────────────────────────────────────────────────
  Map<String, bool> _loadAchs() {
    final raw = Storage.getString(
        'mc_achievements', Storage.getString('mc_achievements_raw', ''));
    final m = <String, bool>{};
    for (final a in GameConfig.achievementsDef) {
      m[a.id] = false;
    }
    if (raw.isEmpty) return _loadLegacyAchs(m);
    for (final part in raw.split(',')) {
      if (part.isEmpty) continue;
      final kv = part.split('=');
      if (kv.length == 2) m[kv[0]] = kv[1] == '1';
    }
    return m;
  }

  Map<String, bool> _loadLegacyAchs(Map<String, bool> defaults) {
    final raw = Storage.getString('mc_achs', '');
    if (raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final entry in decoded) {
          if (entry is! Map) continue;
          final id = entry['id'];
          if (id is String && defaults.containsKey(id)) {
            defaults[id] = entry['unlocked'] == true;
          }
        }
      }
    } catch (_) {
      // Ignore malformed legacy achievement data.
    }
    return defaults;
  }

  String _encodeAchs() {
    return achievements.entries
        .map((e) => '${e.key}=${e.value ? 1 : 0}')
        .join(',');
  }

  Map<String, SkillData> _loadSkillMap() {
    final raw = Storage.getString(
        'mc_skillMap', Storage.getString('mc_skillMap_raw', ''));
    final def = <String, SkillData>{};
    for (final op in [
      Operation.addition,
      Operation.subtraction,
      Operation.multiplication,
      Operation.division
    ]) {
      def[op.name] = SkillData();
    }
    if (raw.isEmpty) return _loadLegacySkillMap(def);
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          def[entry.key] = SkillData.fromJson(value);
        } else if (value is Map) {
          def[entry.key] = SkillData.fromJson(Map<String, dynamic>.from(value));
        }
      }
    } catch (_) {
      // Legacy builds wrote a non-JSON debug string here. Ignore it safely.
    }
    return def;
  }

  Map<String, SkillData> _loadLegacySkillMap(Map<String, SkillData> defaults) {
    final raw = Storage.getString('mc_skills', '');
    if (raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key is! String || value is! Map) continue;
          defaults[key] = SkillData.fromJson(Map<String, dynamic>.from(value));
        }
      }
    } catch (_) {
      // Ignore malformed legacy skill data.
    }
    return defaults;
  }

  Map<String, int> _loadNumTypeUnlocked() {
    final split = {
      'integers': Storage.getInt('mc_numTypeUnlocked_integers', 0),
      'rationals': Storage.getInt('mc_numTypeUnlocked_rationals', 0),
    };
    if (split.values.any((value) => value != 0)) return split;

    final raw = Storage.getString('mc_numTypeUnlocked', '');
    if (raw.isEmpty) return split;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        split['integers'] = _legacyUnlockFlag(decoded['integers']);
        split['rationals'] = _legacyUnlockFlag(decoded['rationals']);
      }
    } catch (_) {
      // Ignore malformed legacy number type unlock data.
    }
    return split;
  }

  int _legacyUnlockFlag(Object? value) {
    if (value == true) return 1;
    if (value is num && value > 0) return 1;
    return 0;
  }

  AvatarCustom _loadAvatarCustom(int pid) {
    final key = 'mc_avatarCustom$pid';
    if (Storage.containsKey(key)) {
      final current = Storage.getObject<AvatarCustom>(
        key,
        (j) => AvatarCustom.fromJson(j),
      );
      if (current != null) return current;
    }

    if (pid == 1) {
      final legacy = _decodeJsonMap(Storage.getString('mc_avatarCustom', ''));
      if (legacy != null) return AvatarCustom.fromJson(legacy);
    }

    return AvatarCustom(base: pid == 1 ? '🐶' : '🐸');
  }

  void _loadPlayerData(int pid) {
    final defaultName = 'Player $pid';
    final defaultAvatar = pid == 1 ? '🐶' : '🐱';
    final nameKey = 'mc_p${pid}_name';
    final avatarKey = 'mc_p${pid}_avatar';

    if (Storage.containsKey(nameKey) || Storage.containsKey(avatarKey)) {
      p[pid].name = Storage.getString(nameKey, defaultName);
      p[pid].avatar = Storage.getString(avatarKey, defaultAvatar);
      return;
    }

    final legacy = _decodeJsonMap(Storage.getString('mc_p${pid}Data', ''));
    if (legacy == null) {
      p[pid].name = defaultName;
      p[pid].avatar = defaultAvatar;
      return;
    }

    p[pid].name = legacy['name'] as String? ?? defaultName;
    final avatar = legacy['avatar'];
    if (avatar is String) {
      p[pid].avatar = avatar;
    } else if (avatar is Map) {
      final custom = AvatarCustom.fromJson(Map<String, dynamic>.from(avatar));
      avatarCustom['$pid'] = custom;
      p[pid].avatar = custom.base;
    } else {
      p[pid].avatar = defaultAvatar;
    }
  }

  List<String> _loadOwnedList(String key) {
    final list = Storage.getStringList(key, []);
    if (list.isNotEmpty) return list;

    final raw = Storage.getString(key, '');
    if (raw.isEmpty) return list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.entries
            .where((entry) => entry.key is String && entry.value == true)
            .map((entry) => entry.key as String)
            .toList();
      }
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {
      // Ignore malformed legacy ownership data.
    }
    return list;
  }

  List<String> _loadStringListCompat(String key) {
    final list = Storage.getStringList(key, []);
    if (list.isNotEmpty) return list;

    final raw = Storage.getString(key, '');
    if (raw.isEmpty) return list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {
      // Ignore malformed legacy list data.
    }
    return list;
  }

  Map<String, dynamic>? _decodeJsonMap(String raw) {
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Ignore malformed legacy object data.
    }
    return null;
  }

  String _encodeSkillMap() {
    return jsonEncode(
        skillMap.map((key, value) => MapEntry(key, value.toJson())));
  }

  Map<String, int> _loadDailyProgress() {
    final raw = Storage.getString(
        'mc_dailyProgress', Storage.getString('mc_dailyProgress_raw', ''));
    final m = <String, int>{};
    dailyCompleted = {};
    if (raw.isEmpty) return m;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final current = (value['current'] as num?)?.toInt() ?? 0;
          m[entry.key] = current;
          dailyCompleted[entry.key] = value['completed'] == true ||
              current >= _dailyChallengeTarget(entry.key);
        } else if (value is Map) {
          final mapped = Map<String, dynamic>.from(value);
          final current = (mapped['current'] as num?)?.toInt() ?? 0;
          m[entry.key] = current;
          dailyCompleted[entry.key] = mapped['completed'] == true ||
              current >= _dailyChallengeTarget(entry.key);
        } else {
          final current = (value as num?)?.toInt() ?? 0;
          m[entry.key] = current;
          dailyCompleted[entry.key] =
              current >= _dailyChallengeTarget(entry.key);
        }
      }
      return m;
    } catch (_) {
      for (final part in raw.split(',')) {
        final kv = part.split('=');
        if (kv.length == 2) {
          final current = int.tryParse(kv[1]) ?? 0;
          m[kv[0]] = current;
          dailyCompleted[kv[0]] = current >= _dailyChallengeTarget(kv[0]);
        }
      }
    }
    return m;
  }

  String _encodeDailyProgress() {
    final ids = {...dailyProgress.keys, ...dailyCompleted.keys};
    return jsonEncode({
      for (final id in ids)
        id: {
          'current': dailyProgress[id] ?? 0,
          'completed': dailyCompleted[id] ?? false,
        }
    });
  }

  int _dailyChallengeTarget(String id) {
    return GameConfig.dailyChallenges
        .firstWhere(
          (c) => c.id == id,
          orElse: () => const DailyChallenge(
            id: '',
            title: '',
            desc: '',
            reward: 0,
            type: '',
            target: 1,
          ),
        )
        .target;
  }

  List<String> _loadDailyChallengeIds() {
    final today = _dailyDateKey();
    final raw = Storage.getString('mc_dailyChallenges', '');
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ids = (decoded['challenges'] as List?)
              ?.map(_dailyChallengeIdFromSavedValue)
              .whereType<String>()
              .where((id) => GameConfig.dailyChallenges.any((c) => c.id == id))
              .toList() ??
          [];
      if (_normalizeDateKey(decoded['date'] as String? ?? '') == today &&
          ids.isNotEmpty) {
        return ids.take(3).toList();
      }
    } catch (_) {
      // Regenerate below when stored data is missing or malformed.
    }

    dailyProgress = {};
    dailyCompleted = {};
    final challenges = [...GameConfig.dailyChallenges];
    challenges.shuffle(Random(_hashString('daily-challenges:$today')));
    final ids = challenges.take(3).map((c) => c.id).toList();
    Storage.setString(
      'mc_dailyChallenges',
      jsonEncode({'date': today, 'challenges': ids}),
    );
    Storage.setString('mc_dailyProgress', _encodeDailyProgress());
    return ids;
  }

  String _dailyDateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String? _dailyChallengeIdFromSavedValue(Object? value) {
    if (value is String) return value;
    if (value is Map) {
      final id = value['id'];
      if (id is String) return id;
    }
    return null;
  }

  String _normalizeDateKey(String raw) {
    if (raw.isEmpty) return '';
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return raw;

    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length == 4) {
      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final month = months[parts[1]];
      final day = int.tryParse(parts[2]);
      final year = int.tryParse(parts[3]);
      if (month != null && day != null && year != null) {
        return _dailyDateKey(DateTime(year, month, day));
      }
    }

    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : _dailyDateKey(parsed);
  }

  bool _isDateKey(String value) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

  String _dateKeyFromDayNumber(int dayNumber) {
    return _dailyDateKey(
      DateTime.fromMillisecondsSinceEpoch(dayNumber * GameConfig.msPerDay),
    );
  }

  int _hashString(String value) {
    var hash = 2166136261;
    for (var i = 0; i < value.length; i++) {
      hash ^= value.codeUnitAt(i);
      hash = (hash * 16777619) & 0xffffffff;
    }
    return hash;
  }

  Map<PowerUp, int> _loadPowerUpBonus() {
    final bonus = {for (final pu in PowerUp.values) pu: 0};
    final raw = Storage.getString('mc_puBonus', '');
    if (raw.isEmpty) return bonus;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final pu in PowerUp.values) {
        final key = _powerUpBonusStorageKeys[pu]!;
        final value = decoded[key] ?? decoded[pu.name];
        bonus[pu] = (value as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      // Corrupt or legacy values should not break game start.
    }

    return bonus;
  }

  void _savePowerUpBonus(Map<PowerUp, int> bonus) {
    Storage.setString(
      'mc_puBonus',
      jsonEncode({
        for (final pu in PowerUp.values)
          _powerUpBonusStorageKeys[pu]!: bonus[pu] ?? 0,
      }),
    );
  }

  void _clearPowerUpBonus() {
    _savePowerUpBonus({for (final pu in PowerUp.values) pu: 0});
  }

  void _applyPowerUpBonusIfEligible({
    required bool isMaster,
    required bool isBoss,
  }) {
    if (players != 1 || isMaster || isBoss) return;

    final bonus = _loadPowerUpBonus();
    if (!bonus.values.any((count) => count > 0)) return;

    for (final entry in bonus.entries) {
      final count = entry.value;
      if (count <= 0) continue;
      p[1].pups.addAll(List.filled(count, entry.key));
    }
    _clearPowerUpBonus();
  }

  Future<void> _updateLoginStreak() async {
    final today = _dayNumberFromDateKey(_dailyDateKey());
    final hasCurrentLastDay = Storage.containsKey('mc_lastLoginDay');
    final lastDay = hasCurrentLastDay
        ? Storage.getInt('mc_lastLoginDay', -1)
        : _dayNumberFromDateKey(
            _normalizeDateKey(Storage.getString('mc_streakLastDay', '')));
    if (lastDay == today) {
      if (!hasCurrentLastDay) {
        await Storage.setInt('mc_lastLoginDay', today);
      }
      await Storage.setInt('mc_loginStreak', loginStreak);
      return;
    }
    if (lastDay == today - 1) {
      loginStreak++;
    } else {
      loginStreak = 1;
    }
    await Storage.setInt('mc_lastLoginDay', today);
    await Storage.setInt('mc_loginStreak', loginStreak);
    notifyListeners();
  }

  int _dayNumberFromDateKey(String key) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) return -1;
    return parsed.millisecondsSinceEpoch ~/ GameConfig.msPerDay;
  }

  DailyBoss _generateDailyBoss(DateTime date) {
    final key = _dailyDateKey(date);
    final seed = _hashString('daily-boss:$key');
    final idx = seed % GameConfig.dailyBosses.length;
    return GameConfig.dailyBosses[idx];
  }

  @visibleForTesting
  DailyBoss debugGenerateDailyBoss(DateTime date) => _generateDailyBoss(date);

  void _updateDailyBossClaimStatus() {
    final today = _dailyDateKey();
    final legacyDay =
        DateTime.now().millisecondsSinceEpoch ~/ GameConfig.msPerDay;
    isDailyBossClaimedToday =
        _normalizeDateKey(Storage.getString('mc_dailyBossClaimed', '')) ==
                today ||
            Storage.getInt('mc_lastDailyBossClaimDay', -1) == legacyDay;
  }

  // ─── Coin operations ────────────────────────────────────────
  void addCoins(int amount, [bool silent = false]) {
    _coinLedger.adjust(amount);
    if (!silent) {
      showToast(amount >= 0 ? '+$amount 🪙' : '$amount 🪙');
    }
    notifyListeners();
  }

  // ─── Ad operations ─────────────────────────────────────────
  @visibleForTesting
  AdMobRequestPolicy get debugAdRequestPolicy => adService.requestPolicy;

  String iapPriceFor(IapProduct product) =>
      iapAdapter.priceFor(product.productId) ?? 'Price unavailable';

  bool isBannerEligibleFor(GameScreen screen) =>
      !adsRemoved &&
      currentModal == GameModal.none &&
      (screen == GameScreen.numType || screen == GameScreen.player);

  Widget? bannerWidget() => adsRemoved
      ? null
      : adService.bannerWidget(
          forceHidden: !isBannerEligibleFor(currentScreen),
        );

  int rewardedCooldownRemainingMs({int? nowMillis}) {
    if (lastRewardedAt <= 0) return 0;
    final elapsed = (nowMillis ?? _nowMillis()) - lastRewardedAt;
    return max(0, rewardedCooldownMs - elapsed);
  }

  bool get isRewardedAdOnCooldown => rewardedCooldownRemainingMs() > 0;

  Future<void> syncBannerForCurrentScreen() async {
    try {
      if (isBannerEligibleFor(currentScreen)) {
        await adService.showBanner();
      } else {
        await adService.hideBanner();
      }
    } catch (_) {
      // Ad service failures should never crash normal game navigation.
    }
  }

  Future<void> _recordCompletedGameForAds() async {
    if (adsRemoved) {
      _pendingInterstitialAd = false;
      await _hideAdsSafely();
      return;
    }
    adGameCount++;
    if (adGameCount % interstitialCadenceGames == 0) {
      _pendingInterstitialAd = true;
    }
    await Storage.setInt('mc_adGameCount', adGameCount);
  }

  @visibleForTesting
  Future<void> debugRecordCompletedGameForAds() => _recordCompletedGameForAds();

  @visibleForTesting
  bool get debugPendingInterstitialAd => _pendingInterstitialAd;

  Future<void> _showPendingInterstitialAd() async {
    if (!_pendingInterstitialAd) return;
    _pendingInterstitialAd = false;
    if (adsRemoved || rt.gameActive || rt.state == 'playing') return;
    try {
      await adService.showInterstitial();
    } on AdMobException {
      // Ad no-fill/service errors should not interrupt result dismissal.
    }
  }

  Future<bool> claimRewardedAdCoins({int? nowMillis}) async {
    if (adsRemoved) {
      showToast('Ads are removed');
      return false;
    }
    final now = nowMillis ?? _nowMillis();
    if (rewardedCooldownRemainingMs(nowMillis: now) > 0) {
      showToast('Rewarded ad is cooling down');
      return false;
    }

    var rewarded = false;
    try {
      if (isBannerEligibleFor(currentScreen)) {
        await adService.hideBanner();
      }
      rewarded = await adService.showRewarded();
    } on AdMobException catch (e) {
      if (e.code == AdMobErrorCode.rewardNotEarned) {
        showToast('Watch the full ad to earn coins.');
        return false;
      }
      rewarded = false;
    } catch (_) {
      rewarded = false;
    } finally {
      await syncBannerForCurrentScreen();
    }
    if (!rewarded) {
      showToast('Rewarded ad unavailable. Please try again later.');
      return false;
    }

    lastRewardedAt = now;
    await Storage.setInt('mc_lastRewardedAt', lastRewardedAt);
    addCoins(rewardedAdCoins, true);
    await save();
    showToast('🎬 +$rewardedAdCoins🪙');
    return true;
  }

  Future<bool> claimDailyCoinBonus() async {
    if (isDailyCoinsClaimedToday) {
      showToast('Daily bonus already claimed');
      return false;
    }

    final today = _dailyDateKey();
    await Storage.setString('mc_dailyCoinsDate', today);
    _dailyBonusPolicy.recordClaim(today);
    addCoins(dailyBonusCoins, true);
    await save();
    showToast('💎 +$dailyBonusCoins🪙 daily bonus');
    return true;
  }

  Future<void> _hideAdsSafely() async {
    try {
      await adService.hideBanner();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  // ─── Toast ──────────────────────────────────────────────────
  void showToast(String msg) =>
      _toastController.show(msg, canQueue: hasListeners);

  void _celebrate(
    CelebrationKind kind, {
    required String emoji,
    required String message,
  }) {
    _celebrationSeq++;
    celebration = CelebrationEvent(
      id: _celebrationSeq,
      kind: kind,
      emoji: emoji,
      message: message,
    );
  }

  // ─── Screen / modal routing ─────────────────────────────────
  void showScreen(GameScreen s) {
    currentScreen = s;
    unawaited(syncBannerForCurrentScreen());
    notifyListeners();
  }

  void showModal(GameModal m) {
    currentModal = m;
    unawaited(syncBannerForCurrentScreen());
    if (rt.state == 'playing' && _isPausingModal(m)) {
      rt.state = 'paused';
    }
    notifyListeners();
  }

  void closeModal() {
    if (currentModal == GameModal.adultGate) {
      cancelAdultGate();
      return;
    }
    currentModal = GameModal.none;
    if (rt.state == 'paused' && rt.gameActive) {
      rt.state = 'playing';
    }
    unawaited(syncBannerForCurrentScreen());
    notifyListeners();
  }

  bool _isPausingModal(GameModal m) {
    return [
      GameModal.quitConfirm,
      GameModal.settings,
      GameModal.highScore,
      GameModal.achievements,
      GameModal.skillDashboard,
      GameModal.coinShop,
      GameModal.adultGate,
    ].contains(m);
  }

  // ─── Configuration actions ──────────────────────────────────
  void goToConfig(String operationName) {
    final op = Operation.fromString(operationName);
    if (op == Operation.master) {
      rt.challenge = Operation.master;
      showModal(GameModal.masterIntro);
      return;
    }
    rt.challenge = op;
    showScreen(GameScreen.numType);
  }

  Future<void> selectNumType(String numTypeName) async {
    final nt = NumberType.fromString(numTypeName);
    if (nt == NumberType.integers && (numTypeUnlocked['integers'] ?? 0) < 1) {
      // Match the original HTML economy.
      if (coins < 500) {
        numTypeUnlockFeedback = 'integers';
        notifyListeners();
        return;
      }
      addCoins(-500);
      numTypeUnlocked['integers'] = 1;
    } else if (nt == NumberType.rationals &&
        (numTypeUnlocked['rationals'] ?? 0) < 1) {
      if (coins < 1200) {
        numTypeUnlockFeedback = 'rationals';
        notifyListeners();
        return;
      }
      addCoins(-1200);
      numTypeUnlocked['rationals'] = 1;
    }
    numTypeUnlockFeedback = '';
    numType = nt;
    await save();
    showScreen(GameScreen.config);
  }

  void setOption(String key, dynamic value) {
    switch (key) {
      case 'players':
        players = value as int;
        if (!GameMode.isAvailableForPlayers(mode, players)) {
          mode = GameMode.standard;
        }
        break;
      case 'mode':
        final nextMode = GameMode.fromString(value as String);
        if (GameMode.isAvailableForPlayers(nextMode, players)) {
          mode = nextMode;
        } else {
          mode = GameMode.standard;
        }
        break;
      case 'diff':
        diff = Difficulty.fromString(value as String);
        break;
      case 'q':
        questionCount = value as int;
        break;
    }
    notifyListeners();
  }

  void setAdaptive(bool v) {
    adaptive = v;
    notifyListeners();
  }

  void goToPlayerSetup() {
    showScreen(GameScreen.player);
  }

  void backFromPlayers() {
    if (rt.challenge == Operation.master ||
        rt.challenge == Operation.dailyBoss) {
      showScreen(GameScreen.menu);
      return;
    }
    showScreen(GameScreen.config);
  }

  void startMasterMode() {
    closeModal();
    _turnSeq++;
    players = 1;
    mode = GameMode.standard;
    adaptive = false;
    rt.challenge = Operation.master;
    _masterLevel = 0;
    _masterLives = 3 + Storage.getInt('mc_livesBonus', 0);
    Storage.setInt('mc_livesBonus', 0);
    _masterProgress = 0;
    showScreen(GameScreen.player);
  }

  void showDailyBoss() {
    showModal(GameModal.dailyBoss);
  }

  void startDailyBoss() {
    closeModal();
    rt.challenge = Operation.dailyBoss;
    rt.dailyBoss = dailyBoss;
    players = 1;
    mode = GameMode.standard;
    adaptive = false;
    showScreen(GameScreen.player);
  }

  void pickAvatar(int pid, String av) {
    p[pid].avatar = av;
    notifyListeners();
  }

  // ─── Game lifecycle ─────────────────────────────────────────
  void startGame() {
    _postFeedbackTimer?.cancel();
    _delayedResultModalTimer?.cancel();

    // Safety: block 2P games in single-player-only modes.
    if (!GameMode.isAvailableForPlayers(mode, players)) {
      mode = GameMode.standard;
      notifyListeners();
      return;
    }

    _cancelDelayedLossEnd();
    _turnSeq++;
    closeModal();

    // Reset player data
    final isMaster = rt.challenge == Operation.master;
    final isBoss = rt.challenge == Operation.dailyBoss;
    for (var i = 1; i <= 2; i++) {
      p[i].resetForGame(
        isSinglePlayer: players == 1,
        isMasterOrBoss: isMaster || isBoss,
      );
    }
    _applyPowerUpBonusIfEligible(isMaster: isMaster, isBoss: isBoss);
    _clearAnswerFeedback();
    celebration = const CelebrationEvent.none();
    screenShakeTick = 0;

    // Reset runtime
    rt = RuntimeState()
      ..challenge = isMaster
          ? Operation.master
          : (isBoss ? Operation.dailyBoss : rt.challenge)
      ..dailyBoss = isBoss ? dailyBoss : null
      ..dailyBossLives = 3
      ..gameActive = true
      ..state = 'playing'
      ..isWarmUp = (mode == GameMode.standard && !isMaster && !isBoss);

    rt.maxTurns = isMaster
        ? (currentMasterLevel?.goal ?? GameConfig.endlessTurns)
        : isBoss
            ? (rt.dailyBoss?.goal ?? dailyBoss?.goal ?? GameConfig.endlessTurns)
            : ([
                GameMode.blitz,
                GameMode.death,
                GameMode.survival,
                GameMode.combo
              ].contains(mode)
                ? GameConfig.endlessTurns
                : players * questionCount);

    if (isMaster) {
      // Master reset: 3 lives
    }

    audio.playStart();

    showScreen(GameScreen.game);

    if (mode == GameMode.blitz) {
      rt.blitzTotalMs = GameConfig.blitzTimerDefault;
      rt.blitzElapsedMs = 0;
      _startGlobalTimer(GameConfig.blitzTimerDefault);
    } else if (mode == GameMode.combo) {
      rt.blitzTotalMs = GameConfig.comboTimerDefault;
      rt.blitzElapsedMs = 0;
      _startGlobalTimer(GameConfig.comboTimerDefault);
    }

    _nextTurn();
  }

  void _nextTurn() {
    if (!rt.gameActive) return;
    if (players == 2 && mode == GameMode.standard && rt.totalTurns > 0) {
      rt.activePlayer = rt.activePlayer == 1 ? 2 : 1;
    }

    // Warm-up: first 3 questions in standard mode
    if (rt.isWarmUp && rt.warmUpCount < 3) {
      rt.warmUpCount++;
      _generateQ();
      rt.qStartTs = DateTime.now().millisecondsSinceEpoch;
      rt.accepting = true;
      notifyListeners();
      return;
    } else if (rt.isWarmUp && rt.warmUpCount == 3) {
      rt.isWarmUp = false;
    }

    _generateQ();
    notifyListeners();
  }

  void _generateQ() {
    var type = rt.challenge;
    var d = diff;

    // Follow-up reinforcement
    if (rt.isFollowUp && rt.followUpData != null) {
      type = rt.followUpData!.type;
      d = rt.followUpData!.diff;
      rt.isFollowUp = false;
      rt.followUpData = null;
    }

    // Resolve via rt.challenge and level info
    String? boss;
    if (rt.challenge == Operation.master) {
      final stageIdx = _masterLevel;
      final lvl = GameConfig.masterLevels[stageIdx];
      d = Difficulty.fromString(lvl.diff);
      type = Operation.fromString(lvl.type);
      boss = lvl.boss;
      final masterNt = lvl.numType;
      numType = masterNt == 'mixed'
          ? [
              NumberType.natural,
              NumberType.integers,
              NumberType.rationals
            ][_rng.nextInt(3)]
          : NumberType.fromString(masterNt);
    } else if (rt.challenge == Operation.dailyBoss) {
      final lvl = rt.dailyBoss ?? dailyBoss!;
      d = Difficulty.fromString(lvl.diff);
      type = Operation.fromString(lvl.type);
      boss = lvl.icon;
      numType = lvl.numType == 'mixed'
          ? [
              NumberType.natural,
              NumberType.integers,
              NumberType.rationals
            ][_rng.nextInt(3)]
          : NumberType.fromString(lvl.numType);
    }

    if (mode == GameMode.survival) {
      d = Difficulty.fromString(
          GameConfig.phaseKeys[rt.survivalPhase.clamp(0, 4)]);
    }

    if (type == Operation.mixed || type == Operation.survival) {
      type = [
        Operation.multiplication,
        Operation.division,
        Operation.addition,
        Operation.subtraction
      ][_rng.nextInt(4)];
    }

    // Adaptive difficulty
    if (adaptive &&
        rt.challenge != Operation.master &&
        rt.challenge != Operation.dailyBoss &&
        mode != GameMode.survival) {
      d = _getAdaptDiff(type);
    }

    // Build question with uniqueness guarantee
    Question q = _qgen.build(type: type, diff: d, numType: numType);
    bool foundUnique = false;
    for (var attempt = 0; attempt < 500; attempt++) {
      final candidate = _qgen.build(type: type, diff: d, numType: numType);
      if (!rt.usedFacts.contains(candidate.key)) {
        rt.usedFacts.add(candidate.key);
        q = candidate;
        foundUnique = true;
        break;
      }
    }
    if (!foundUnique) {
      rt.usedFacts.clear();
      q = _qgen.build(type: type, diff: d, numType: numType);
      rt.usedFacts.add(q.key);
    }

    q = Question(
      type: q.type,
      key: q.key,
      text: q.text,
      ans: q.ans,
      choices: q.choices,
      boss: boss,
      diff: d,
      numType: numType,
      ratDP: q.ratDP,
    );

    rt.q = q;
    rt.selectedAnswer = null;
    rt.lastAnswerCorrect = false;
    rt.bossMood = 'normal';
    rt.qStartTs = DateTime.now().millisecondsSinceEpoch;
    rt.accepting = true;

    // Start per-question timer
    if (mode != GameMode.blitz && mode != GameMode.combo) {
      rt.qTimerLimit = 0;
      _startQuestionTimer();
    }
  }

  Difficulty _getAdaptDiff(Operation type) {
    final m = skillMap[type.name]?.mastery ?? _masteryDefault;
    if (m < _adaptThresholdEasy) return Difficulty.easy;
    if (m < _adaptThresholdMedium) return Difficulty.medium;
    if (m < _adaptThresholdHard) return Difficulty.hard;
    if (m < _adaptThresholdExpert) return Difficulty.expert;
    return Difficulty.insane;
  }

  int _getTimerLimitMs() {
    if (mode == GameMode.blitz || mode == GameMode.combo) {
      return rt.blitzTotalMs;
    }
    if (rt.challenge == Operation.master) {
      return (currentMasterLevel?.time ?? 10) * 1000;
    }
    if (rt.challenge == Operation.dailyBoss) {
      return (rt.dailyBoss?.time ?? dailyBoss?.time ?? 9) * 1000;
    }
    if (mode == GameMode.survival) {
      return GameConfig.phaseTimesMs[rt.survivalPhase.clamp(0, 4)];
    }

    final timerDiff = adaptive && rt.q?.diff != null ? rt.q!.diff! : diff;
    final baseMs = GameConfig.timerBaseMs[timerDiff.name] ??
        GameConfig.timerBaseMs['hard']!;
    final penalty =
        adaptive ? (adaptLvl ~/ GameConfig.timerPenaltyStep) * 1000 : 0;
    return max(GameConfig.timerMinMs, baseMs - penalty);
  }

  void _startQuestionTimer({int resumeElapsedMs = 0}) {
    final limitMs =
        rt.qTimerLimit > 0 ? rt.qTimerLimit * 1000 : _getTimerLimitMs();
    final duration = max(0, limitMs - resumeElapsedMs);
    rt.qTimerLimit = limitMs ~/ 1000;
    rt.timerDurationMs = duration;
    rt.timerStart = DateTime.now().millisecondsSinceEpoch;
    rt.timer?.cancel();
    rt.timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
      if (elapsed >= duration) {
        t.cancel();
        _onTimeout();
      } else {
        notifyListeners();
      }
    });
  }

  void _startGlobalTimer(int totalMs) {
    rt.timerStart = DateTime.now().millisecondsSinceEpoch;
    rt.timerDurationMs = totalMs;
    rt.qTimerLimit = totalMs ~/ 1000;
    rt.timer?.cancel();
    rt.timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
      rt.blitzElapsedMs = elapsed;
      if (elapsed >= totalMs) {
        t.cancel();
        _endGame(false, false);
      } else {
        notifyListeners();
      }
    });
  }

  void _onTimeout() {
    if (!rt.accepting) return;
    _onAnswer(null, false, true);
  }

  @visibleForTesting
  void debugTimeoutForTest() => _onTimeout();

  // ─── Answer handler ─────────────────────────────────────────
  void onAnswer(num val) {
    _onAnswer(val, false, false);
  }

  void skip() {
    if (!rt.accepting) return;
    _onAnswer(null, true, false);
  }

  void _onAnswer(num? val, bool isSkip, bool isTimeout) {
    if (!rt.accepting || rt.state == 'paused') return;
    rt.accepting = false;
    if (mode != GameMode.blitz && mode != GameMode.combo) {
      _freezeQuestionTimer();
      rt.timer?.cancel();
    }

    final q = rt.q!;
    final isCorrect = val != null && (val - q.ans).abs() < 1e-9;
    rt.selectedAnswer = val;
    rt.lastAnswerCorrect = isCorrect;
    final pid = rt.activePlayer;
    final pl = p[pid];
    final timeTaken = DateTime.now().millisecondsSinceEpoch - rt.qStartTs;

    pl.total++;
    pl.timeMs += timeTaken;
    pl.history.add(HistoryEntry(
      type: q.type,
      correct: isCorrect,
      ms: timeTaken,
    ));
    if (pl.history.length > 75) {
      pl.history = pl.history.sublist(pl.history.length - 50);
    }

    _updateSkillMap(q.type, q.diff ?? diff, isCorrect, timeTaken);
    _updateAdapt(isCorrect, timeTaken, q.type);

    if (isCorrect) {
      _onCorrect(pl, pid, timeTaken);
    } else {
      _onWrong(pl, pid, isSkip, isTimeout, val);
    }

    rt.totalTurns++;
    _checkStandardTurnLimit();
    if (_delayedLossTimer == null) _scheduleNextTurn();
  }

  void _freezeQuestionTimer() {
    if (rt.timerDurationMs <= 0 || rt.timerStart <= 0) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
    rt.timerDurationMs =
        (rt.timerDurationMs - elapsed).clamp(0, rt.timerDurationMs).toInt();
    rt.timerStart = 0;
  }

  void _onCorrect(PlayerState pl, int pid, int timeTaken) {
    pl.correct++;
    pl.streak++;
    pl.maxStreak = max(pl.maxStreak, pl.streak);
    if (timeTaken < pl.fastest) pl.fastest = timeTaken;
    if (timeTaken < 2000) rt.fastAnswers++;

    // Survival: phase + coin per correct
    if (mode == GameMode.survival) {
      rt.survivalCorrect++;
      addCoins(1, true);
      if (rt.survivalCorrect % 10 == 0) {
        final boss = GameConfig
            .survivalBosses[_rng.nextInt(GameConfig.survivalBosses.length)];
        addCoins(GameConfig.survivalBossReward, true);
        bigEmoji = boss;
        rt.bossMood = 'defeated';
        reactionPill = '👹 BOSS DOWN! +${GameConfig.survivalBossReward}🪙';
        bigEmojiVisible = true;
        audio.vibratePattern([80, 30, 80, 30, 120]);
        _shakeScreen(vibrate: false);
        _celebrate(
          CelebrationKind.bossClear,
          emoji: boss,
          message: 'BOSS DOWN! +${GameConfig.survivalBossReward}🪙',
        );
      }
      final newPhase = min(rt.survivalCorrect ~/ 5, 4);
      if (newPhase > rt.survivalPhase) {
        rt.survivalPhase = newPhase;
        audio.vibratePattern([60, 30, 60]);
        _shakeScreen(vibrate: false);
      }
    }

    // Combo mode
    if (mode == GameMode.combo) {
      rt.comboStreak++;
      final streak = rt.comboStreak;
      int mult = 1;
      if (streak >= GameConfig.comboThresholds[2]) {
        mult = GameConfig.comboMultipliers[2];
      } else if (streak >= GameConfig.comboThresholds[1])
        mult = GameConfig.comboMultipliers[1];
      else if (streak >= GameConfig.comboThresholds[0])
        mult = GameConfig.comboMultipliers[0];
      rt.comboMultiplier = mult.toDouble();
      rt.comboMaxMultiplier = max(rt.comboMaxMultiplier, mult);
    } else {
      rt.combo++;
      if (rt.combo >= 10) {
        rt.comboMultiplier = 2.0;
      } else if (rt.combo >= 5)
        rt.comboMultiplier = 1.5;
      else if (rt.combo >= 3) rt.comboMultiplier = 1.2;
    }

    // Power-up reward (single-player non-boss non-combo non-survival)
    final eligibleForPU = players == 1 &&
        rt.challenge != Operation.master &&
        rt.challenge != Operation.dailyBoss &&
        ![GameMode.combo, GameMode.survival].contains(mode);
    if (eligibleForPU && pl.correct == 1) {
      pl.pups.addAll(PowerUp.values);
      showToast('🎁 Got one of each power-up!');
    } else if (eligibleForPU &&
        pl.correct > 1 &&
        pl.correct % GameConfig.puRewardInterval == 0) {
      final pu = PowerUp.values[_rng.nextInt(PowerUp.values.length)];
      pl.pups.add(pu);
      showToast('🎁 Got: ${pu.label}!');
    }

    // Scoring
    int pts = GameConfig.scoreBase;
    int bonus = 0;
    final isBlitz = mode == GameMode.blitz;
    final isMaster = rt.challenge == Operation.master;
    final isBoss = rt.challenge == Operation.dailyBoss;

    if (!isBlitz && !isMaster && mode != GameMode.combo) {
      final remaining = max(0, (rt.qTimerLimit * 1000 - timeTaken) / 1000);
      bonus = remaining.ceil();
      if (timeTaken < 2000) {
        bonus += 2;
      } else if (timeTaken < 4000) bonus += 1;
    } else if (mode == GameMode.combo) {
      if (timeTaken < 1500) {
        bonus = 5;
      } else if (timeTaken < 2500)
        bonus = 3;
      else if (timeTaken < 4000) bonus = 1;
    } else if (isBlitz) {
      if (timeTaken < 1500) {
        bonus = 8;
      } else if (timeTaken < 2500)
        bonus = 5;
      else if (timeTaken < 4000) bonus = 2;
    } else if (mode == GameMode.survival) {
      bonus = GameConfig.phaseBonus[min(rt.survivalPhase, 4)];
      if (timeTaken < 2000) bonus += 3;
    }

    if (pl.doubleActive) {
      pts = (pts + bonus) * 2;
      bonus = 0;
      pl.doubleActive = false;
    } else {
      pts += bonus;
    }

    pts = (pts * rt.comboMultiplier).round();
    pl.score += pts;
    pl.bonus += bonus;

    // Coins
    if (pl.correct % 5 == 0) addCoins(1, true);
    for (var i = 0; i < GameConfig.streakThresholds.length; i++) {
      if (pl.streak == GameConfig.streakThresholds[i]) {
        addCoins(GameConfig.streakCoins[i], true);
        audio.vibratePattern([50, 30, 50]);
        _shakeScreen(vibrate: false);
        showToast(
            '🔥 Streak ×${[5, 10, 20][i]}! +${GameConfig.streakCoins[i]}🪙');
      }
    }
    if (pl.streak == 1 &&
        pl.total > 1 &&
        pl.history.length >= 2 &&
        !pl.history[pl.history.length - 2].correct) {
      addCoins(3, true);
      showToast('🎁 Comeback! +3🪙');
    }

    final bossDown = mode == GameMode.survival && rt.survivalCorrect % 10 == 0;
    final rx = GameConfig.correctRx[_rng.nextInt(GameConfig.correctRx.length)];
    if (!bossDown) {
      reactionPill = '$rx +$pts';
      bigEmoji = rx.split(' ').first;
    }
    if (rt.challenge == Operation.master ||
        rt.challenge == Operation.dailyBoss) {
      rt.bossMood = 'hit';
      _shakeScreen();
    }
    bigEmojiVisible = true;
    audio.playCorrect();
    audio.vibrateCorrect();

    // Master / Daily Boss progress
    if (rt.challenge == Operation.master) _masterProgress++;
    if (isBoss) rt.dailyBossProgress++;

    // Check stage / boss cleared
    _checkProgressMilestones();

    // Daily challenges
    if (mode == GameMode.blitz) _updateDailyProgress('blitz_15');
    if (rt.q?.type == Operation.division) _updateDailyProgress('division_10');
    _updateDailyProgressAbsolute('streak_7', pl.streak);
    _updateDailyProgressAbsolute('perfect_5', pl.streak);

    notifyListeners();
  }

  void _checkProgressMilestones() {
    final isMaster = rt.challenge == Operation.master;
    final isBoss = rt.challenge == Operation.dailyBoss;

    if (isMaster) {
      final lvl = GameConfig.masterLevels[_masterLevel];
      if (_masterProgress >= lvl.goal) {
        _masterLevel++;
        if (_masterLevel >= GameConfig.masterLevels.length) {
          // Beat the game!
          unlockAch('math_legend');
          _endGameAfterFeedback(true, false);
        } else {
          if (_masterLevel >= 3) unlockAch('math_wizard');
          _updateDailyProgress('master_stage');
          _showStageClearedAfterFeedback(lvl);
        }
      }
    } else if (isBoss) {
      final lvl = rt.dailyBoss!;
      if (rt.dailyBossProgress >= lvl.goal) {
        rt.dailyBossWon = true;
        unlockAch('daily_boss');
        final today = _dailyDateKey();
        final alreadyClaimed = isDailyBossClaimedToday ||
            _normalizeDateKey(Storage.getString('mc_dailyBossClaimed', '')) ==
                today;
        if (!alreadyClaimed) {
          addCoins(lvl.reward);
          rt.dailyBossRewardEarned = lvl.reward;
          unawaited(Storage.setString('mc_dailyBossClaimed', today));
          _updateDailyProgress('daily_boss');
        } else {
          rt.dailyBossRewardEarned = 0;
        }
        isDailyBossClaimedToday = true;
        _endGameAfterFeedback(true, false);
      }
    }
  }

  void _checkStandardTurnLimit() {
    if (rt.challenge == Operation.master ||
        rt.challenge == Operation.dailyBoss ||
        rt.maxTurns == GameConfig.endlessTurns) {
      return;
    }
    if (rt.totalTurns >= rt.maxTurns) {
      _endGameAfterFeedback(true, false);
    }
  }

  void _onWrong(
      PlayerState pl, int pid, bool isSkip, bool isTimeout, num? val) {
    rt.combo = 0;
    rt.comboMultiplier = 1.0;

    if (mode == GameMode.combo) {
      rt.comboStreak = 0;
      rt.comboMultiplier = 1.0;
    }

    if (pl.shieldActive && !isSkip && !isTimeout) {
      pl.shieldActive = false;
      reactionPill = '🛡️ Shield absorbed it!';
      bigEmoji = '🛡️';
      bigEmojiVisible = true;
      notifyListeners();
      return;
    }

    if (mode == GameMode.death && !isSkip) {
      bigEmoji = '💀';
      reactionPill = '💀 Game Over!';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      _shakeScreen(vibrate: false);
      _scheduleDelayedLossEnd(const Duration(milliseconds: 600));
      notifyListeners();
      return;
    }

    pl.streak = 0;
    final wrongLabel = isTimeout
        ? "⏰ Time's Up!"
        : GameConfig.wrongRx[_rng.nextInt(GameConfig.wrongRx.length)];

    if (mode == GameMode.survival && !isSkip) {
      rt.survivalLives--;
      bigEmoji = '💔';
      reactionPill = '💔 Ans: ${rt.q?.ans}';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      _shakeScreen(vibrate: false);
      if (rt.survivalLives <= 0) {
        _scheduleDelayedLossEnd(const Duration(milliseconds: 900));
        notifyListeners();
        return;
      }
    } else if (rt.challenge == Operation.dailyBoss && !isSkip) {
      rt.dailyBossLives--;
      bigEmoji = '💔';
      rt.bossMood = 'wrong';
      reactionPill = '💔 Boss hit! Ans: ${rt.q?.ans}';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      _shakeScreen(vibrate: false);
      if (rt.dailyBossLives <= 0) {
        _scheduleDelayedLossEnd(const Duration(milliseconds: 900));
        notifyListeners();
        return;
      }
    } else if (rt.challenge == Operation.master && !isSkip) {
      // Master: lose a life
      _masterLives--;
      bigEmoji = '💔';
      rt.bossMood = 'wrong';
      reactionPill = '$wrongLabel 💔 Ans: ${rt.q?.ans}';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      _shakeScreen(vibrate: false);
      if (_masterLives <= 0) {
        _scheduleDelayedLossEnd(const Duration(milliseconds: 900));
        notifyListeners();
        return;
      }
    } else {
      if (isSkip) {
        pl.skipped++;
        bigEmoji = '⏩';
        reactionPill = 'Skipped! Ans: ${rt.q?.ans}';
      } else {
        bigEmoji = isTimeout ? '⏰' : wrongLabel.split(' ').first;
        reactionPill = '$wrongLabel Ans: ${rt.q?.ans}';
      }
      bigEmojiVisible = true;
      if (!isTimeout) {
        audio.playWrong();
        audio.vibrateWrong();
        _shakeScreen(vibrate: false);
      } else {
        audio.playWrong();
      }
      // Follow-up
      if (!isSkip &&
          !isTimeout &&
          mode == GameMode.standard &&
          rt.challenge != Operation.dailyBoss) {
        rt.isFollowUp = true;
        rt.followUpData = _FollowUpData(rt.q!.type, rt.q!.diff ?? diff);
      }
    }

    notifyListeners();
  }

  void _shakeScreen({bool vibrate = true}) {
    if (vibrate) audio.vibratePattern([100, 50, 100]);
    if (!settings.reduceMotion) screenShakeTick++;
  }

  void _cancelDelayedLossEnd() {
    _delayedLossTimer?.cancel();
    _delayedLossTimer = null;
  }

  void _scheduleDelayedLossEnd(Duration delay) {
    _cancelDelayedLossEnd();
    final seq = _turnSeq;
    _delayedLossTimer = Timer(delay, () {
      _delayedLossTimer = null;
      if (_disposed ||
          seq != _turnSeq ||
          !rt.gameActive ||
          rt.state == 'ended' ||
          currentScreen != GameScreen.game) {
        return;
      }
      _endGame(false, true);
    });
  }

  void _scheduleNextTurn() {
    if (!rt.gameActive) return;
    if (rt.state != 'playing') return;
    const delay = 1300;
    final seq = ++_turnSeq;
    _bigEmojiHideTimer?.cancel();
    if (bigEmojiVisible) {
      _bigEmojiHideTimer = Timer(const Duration(milliseconds: 900), () {
        if (seq != _turnSeq || !rt.gameActive) return;
        bigEmojiVisible = false;
        notifyListeners();
      });
    }
    Timer(Duration(milliseconds: delay), () {
      if (seq != _turnSeq || !rt.gameActive) return;
      _bigEmojiHideTimer?.cancel();
      bigEmojiVisible = false;
      bigEmoji = '';
      reactionPill = '';
      _nextTurn();
    });
  }

  // ─── End game ───────────────────────────────────────────────
  void _endGameAfterFeedback(bool win, bool loss) {
    if (!rt.gameActive) return;
    rt.state = 'ending';
    rt.timer?.cancel();
    const delay = 1300;
    final seq = ++_turnSeq;
    _bigEmojiHideTimer?.cancel();
    if (bigEmojiVisible) {
      _bigEmojiHideTimer = Timer(const Duration(milliseconds: 900), () {
        if (seq != _turnSeq || !rt.gameActive || rt.state != 'ending') return;
        bigEmojiVisible = false;
        notifyListeners();
      });
    }
    _postFeedbackTimer?.cancel();
    _postFeedbackTimer = Timer(const Duration(milliseconds: delay), () {
      if (seq != _turnSeq || !rt.gameActive || rt.state != 'ending') return;
      _bigEmojiHideTimer?.cancel();
      bigEmojiVisible = false;
      bigEmoji = '';
      reactionPill = '';
      _endGame(win, loss);
    });
  }

  void _showStageClearedAfterFeedback(MasterLevel lvl) {
    if (!rt.gameActive) return;
    rt.state = 'ending';
    rt.timer?.cancel();
    const delay = 1300;
    final seq = ++_turnSeq;
    _bigEmojiHideTimer?.cancel();
    if (bigEmojiVisible) {
      _bigEmojiHideTimer = Timer(const Duration(milliseconds: 900), () {
        if (seq != _turnSeq || !rt.gameActive || rt.state != 'ending') return;
        bigEmojiVisible = false;
        notifyListeners();
      });
    }
    _postFeedbackTimer?.cancel();
    _postFeedbackTimer = Timer(const Duration(milliseconds: delay), () {
      if (seq != _turnSeq || !rt.gameActive || rt.state != 'ending') return;
      _bigEmojiHideTimer?.cancel();
      bigEmojiVisible = false;
      bigEmoji = '';
      reactionPill = '';
      _celebrate(
        CelebrationKind.stageClear,
        emoji: lvl.boss,
        message: 'Stage cleared!',
      );
      _delayedResultModalTimer?.cancel();
      _delayedResultModalTimer = Timer(const Duration(milliseconds: 1250), () {
        if (seq != _turnSeq || !rt.gameActive || rt.state != 'ending') return;
        rt.state = 'paused';
        showModal(GameModal.stageCleared);
      });
    });
  }

  void _endGame(bool win, bool loss) {
    _cancelDelayedLossEnd();
    if (!rt.gameActive || rt.state == 'ended') return;
    rt.gameActive = false;
    rt.state = 'ended';
    rt.timer?.cancel();
    gamesPlayed++;
    unawaited(_recordCompletedGameForAds());
    if (gamesPlayed >= 10) unlockAch('persistent');

    // Save high score
    if (p[1].score > 0) {
      highScores.add(HighScore(
        name: p[1].name,
        score: p[1].score,
        mode: mode.name,
        date: DateTime.now().toIso8601String().substring(0, 10),
      ));
      highScores.sort((a, b) => b.score.compareTo(a.score));
      if (highScores.length > 10) highScores = highScores.sublist(0, 10);
    }

    if (win && p[1].correct > 0) unlockAch('first_win');
    // Perfect score
    final perfect = p[1].total > 0 && p[1].correct == p[1].total;
    if (perfect) {
      unlockAch('perfect_score');
    }
    // Streak master
    if (p[1].maxStreak >= 10) unlockAch('streak_master');
    // Speed demon
    if (rt.fastAnswers >= 5) unlockAch('speed_demon');
    // Survivor
    if (mode == GameMode.death && p[1].score >= 250) unlockAch('survivor');
    // Skill master
    for (final e in skillMap.entries) {
      if (e.value.count >= 5 && e.value.mastery >= 90) {
        unlockAch('skill_master');
        break;
      }
    }
    // Quick learner
    if (adaptLvl >= 8) unlockAch('quick_learner');

    _prepareResultSummary(win: win, loss: loss);

    final isBossWin = win && rt.dailyBossWon;
    if (win) {
      final isMasterWin = rt.challenge == Operation.master;
      if (isBossWin || isMasterWin || perfect) {
        _celebrate(
          isBossWin
              ? CelebrationKind.bossClear
              : perfect
                  ? CelebrationKind.perfect
                  : CelebrationKind.win,
          emoji: isBossWin
              ? (rt.dailyBoss?.icon ?? '🐲')
              : isMasterWin
                  ? '👑'
                  : '💯',
          message: isBossWin
              ? 'Daily Boss defeated!'
              : isMasterWin
                  ? 'Master Challenge complete!'
                  : 'Perfect score!',
        );
      }
    }

    save();
    if (isBossWin) {
      _delayedResultModalTimer?.cancel();
      _delayedResultModalTimer = Timer(const Duration(milliseconds: 1250), () {
        if (rt.state == 'ended' && currentModal == GameModal.none) {
          showModal(GameModal.win);
        }
      });
    } else {
      showModal(GameModal.win);
    }
  }

  void _prepareResultSummary({required bool win, required bool loss}) {
    final p1 = p[1];
    final p2 = p[2];

    if (loss) {
      resultIcon = '💀';
      resultTitle = 'Game Over!';
      if (rt.challenge == Operation.master) {
        final stage = min(_masterLevel + 1, GameConfig.masterLevels.length);
        resultDescription = 'You reached Stage $stage';
      } else if (rt.challenge == Operation.dailyBoss) {
        final boss = rt.dailyBoss?.name ?? 'Daily Boss';
        resultDescription =
            '$boss survived with ${rt.dailyBossProgress} hits landed.';
      } else {
        resultDescription = 'Final Score: ${p1.score}';
      }
      return;
    }

    if (win && rt.challenge == Operation.master) {
      resultIcon = '👑';
      resultTitle = 'Legendary!';
      resultDescription = 'You found the Treasure! 🎊';
      return;
    }

    if (win && rt.dailyBossWon) {
      final boss = rt.dailyBoss;
      resultIcon = boss?.icon ?? '🐲';
      resultTitle = '${boss?.name ?? 'Daily Boss'} Defeated!';
      resultDescription = rt.dailyBossRewardEarned > 0
          ? 'Daily reward claimed: +${rt.dailyBossRewardEarned} coins'
          : "Cleared again for practice. Today's reward was already claimed.";
      return;
    }

    if (players == 2 && mode == GameMode.standard) {
      if (p1.score > p2.score) {
        resultIcon = p1.avatar.storageEmoji;
        resultTitle = '${p1.name} Wins! 🏆';
      } else if (p2.score > p1.score) {
        resultIcon = p2.avatar.storageEmoji;
        resultTitle = '${p2.name} Wins! 🏆';
      } else {
        resultIcon = '🤝';
        resultTitle = "It's a Tie!";
      }
      resultDescription = '${p1.score} – ${p2.score}';
      return;
    }

    resultIcon = mode == GameMode.blitz || mode == GameMode.combo ? '⏱️' : '🌟';
    resultTitle = mode == GameMode.blitz || mode == GameMode.combo
        ? "Time's Up!"
        : 'Player Report';
    resultDescription = 'Final Score: ${p1.score}';
  }

  void advanceStage() {
    closeModal();
    _clearAnswerFeedback();
    rt.state = 'playing';
    _masterProgress = 0;
    _nextTurn();
  }

  void _clearAnswerFeedback() {
    _bigEmojiHideTimer?.cancel();
    reactionPill = '';
    bigEmoji = '';
    bigEmojiVisible = false;
  }

  Future<void> replayGame() async {
    final dismissedResult = currentModal == GameModal.win;
    closeModal();
    if (dismissedResult) await _showPendingInterstitialAd();
    if (rt.challenge == Operation.master) {
      _masterLevel = 0;
      _masterProgress = 0;
      _masterLives = 3 + Storage.getInt('mc_livesBonus', 0);
      Storage.setInt('mc_livesBonus', 0);
    }
    startGame();
  }

  Future<void> quitToMenu() async {
    _cancelDelayedLossEnd();
    _turnSeq++;
    final dismissedResult = currentModal == GameModal.win;
    closeModal();
    if (dismissedResult) await _showPendingInterstitialAd();
    rt.gameActive = false;
    rt.state = 'idle';
    rt.timer?.cancel();
    _masterLevel = 0;
    _masterLives = 3;
    _masterProgress = 0;
    showScreen(GameScreen.menu);
  }

  void showQuitConfirm() {
    showModal(GameModal.quitConfirm);
  }

  // ─── Adaptive + skill tracking ──────────────────────────────
  void _updateAdapt(bool correct, int timeMs, Operation type) {
    final sd = skillMap[type.name];
    if (sd == null) return;

    final prevMastery = sd.mastery == 0 ? _masteryDefault : sd.mastery;
    if (correct) {
      final boost = timeMs < 2000 ? 0.6 : 0.2;
      sd.mastery = min(_masteryMax, prevMastery + boost);
    } else {
      sd.mastery = max(0, prevMastery - 0.5);
    }
    _recomputeAdaptiveLevel();
  }

  void _updateSkillMap(Operation type, Difficulty d, bool correct, int timeMs) {
    final sd = skillMap[type.name] ?? SkillData();
    if (correct) {
      switch (d) {
        case Difficulty.easy:
          sd.easy++;
          break;
        case Difficulty.medium:
          sd.medium++;
          break;
        case Difficulty.hard:
          sd.hard++;
          break;
        case Difficulty.expert:
          sd.expert++;
          break;
        case Difficulty.insane:
          sd.insane++;
          break;
      }
      sd.correct++;
    }
    sd.count++;
    _updateMastery(sd, correct, timeMs);
    skillMap[type.name] = sd;
  }

  void _updateMastery(SkillData sd, bool correct, int timeMs) {
    double change;
    if (correct) {
      if (timeMs < _masteryFastMs) {
        change = _masteryGainFast;
      } else if (timeMs < _masteryNormalMs) {
        change = _masteryGainNormal;
      } else {
        change = _masteryGainSlow;
      }
    } else {
      final timeoutLimitMs = rt.qTimerLimit > 0 ? rt.qTimerLimit * 1000 : 10000;
      change = (timeMs == 0 || timeMs >= timeoutLimitMs)
          ? _masteryPenaltyTimeout
          : _masteryPenalty;
    }

    final baseMastery = sd.mastery == 0 ? _masteryDefault : sd.mastery;
    sd.mastery = max(0, min(_masteryMax, baseMastery + change));

    final ms = timeMs == 0 ? _confidenceDefaultMs : timeMs;
    final speedScore = max(0, 100 - (ms / _confidenceSpeedDivisor));
    final baseConfidence =
        sd.confidence == 0 ? _confidenceDefault : sd.confidence;
    sd.confidence = (baseConfidence * (1 - _confidenceEmaAlpha) +
            speedScore * _confidenceEmaAlpha)
        .roundToDouble();
    _recomputeAdaptiveLevel();
  }

  void _recomputeAdaptiveLevel() {
    final values = skillMap.values;
    if (values.isEmpty) {
      adaptLvlRaw = 0;
      adaptLvl = 0;
      return;
    }
    final sum = values.fold<double>(
      0,
      (total, skill) =>
          total + (skill.mastery == 0 ? _masteryDefault : skill.mastery),
    );
    final mean = sum / values.length;
    adaptLvlRaw = (mean / 100) * 10;
    adaptLvl = min(10, adaptLvlRaw.round());
  }

  @visibleForTesting
  Difficulty debugGetAdaptDiff(Operation type) => _getAdaptDiff(type);

  @visibleForTesting
  int debugQuestionTimerDurationMs() => rt.timerDurationMs;

  @visibleForTesting
  void debugRestartQuestionTimer({int resumeElapsedMs = 0}) =>
      _startQuestionTimer(resumeElapsedMs: resumeElapsedMs);

  @visibleForTesting
  void debugSetMasterStage(int level) {
    _masterLevel = level.clamp(0, GameConfig.masterLevels.length - 1).toInt();
    _masterLives = 3;
    _masterProgress = 0;
    players = 1;
    mode = GameMode.standard;
    adaptive = false;
    rt.challenge = Operation.master;
  }

  @visibleForTesting
  void debugUpdateSkillMap(
          Operation type, Difficulty difficulty, bool correct, int timeMs) =>
      _updateSkillMap(type, difficulty, correct, timeMs);

  @visibleForTesting
  void debugUpdateAdapt(bool correct, int timeMs, Operation type) =>
      _updateAdapt(correct, timeMs, type);

  @visibleForTesting
  void debugRecordAdaptiveAnswer(
      Operation type, Difficulty difficulty, bool correct, int timeMs) {
    _updateSkillMap(type, difficulty, correct, timeMs);
    _updateAdapt(correct, timeMs, type);
  }

  // ─── Achievements ───────────────────────────────────────────
  void unlockAch(String id) {
    if (achievements[id] == true) return;
    achievements[id] = true;
    final a = GameConfig.achievementsDef.firstWhere((e) => e.id == id);
    newlyUnlocked.add(a);
    _celebrate(
      CelebrationKind.achievement,
      emoji: a.icon,
      message: '${a.name} unlocked!',
    );
    showToast('${a.icon} ${a.name} unlocked!');
  }

  // ─── Daily challenges ───────────────────────────────────────
  void _updateDailyProgress(String id) {
    final ch = _activeDailyChallenge(id);
    if (ch == null || dailyCompleted[id] == true) return;
    final cur = dailyProgress[id] ?? 0;
    final next = cur + 1;
    dailyProgress[id] = next;
    if (next >= ch.target) _completeDailyChallenge(ch);
  }

  void _updateDailyProgressAbsolute(String id, int value) {
    final ch = _activeDailyChallenge(id);
    if (ch == null || dailyCompleted[id] == true) return;
    final cur = dailyProgress[id] ?? 0;
    if (value > cur) {
      dailyProgress[id] = value;
      if (value >= ch.target) _completeDailyChallenge(ch);
    }
  }

  DailyChallenge? _activeDailyChallenge(String id) {
    for (final c in activeDailyChallenges) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _completeDailyChallenge(DailyChallenge ch) {
    if (dailyCompleted[ch.id] == true) return;
    dailyProgress[ch.id] = max(dailyProgress[ch.id] ?? 0, ch.target);
    dailyCompleted[ch.id] = true;
    addCoins(ch.reward);
    _celebrate(
      CelebrationKind.reward,
      emoji: '🎁',
      message: '${ch.title} complete!',
    );
    showToast('🎁 ${ch.title} complete! +${ch.reward}🪙');

    final completedToday =
        activeDailyChallenges.where((c) => dailyCompleted[c.id] == true).length;
    if (completedToday >= 3) unlockAch('daily_grind');
  }

  @visibleForTesting
  void debugUpdateDailyProgress(String id) => _updateDailyProgress(id);

  @visibleForTesting
  void debugUpdateDailyProgressAbsolute(String id, int value) =>
      _updateDailyProgressAbsolute(id, value);

  // ─── Power-up usage ─────────────────────────────────────────
  void usePowerUp(PowerUp pu) {
    if (!rt.accepting) return;
    if (_isPowerUpBlocked(pu)) return;

    final pl = p[rt.activePlayer];
    if (!pl.pups.contains(pu)) return;
    pl.pups.remove(pu);
    rt.puUsed++;
    if (rt.puUsed >= 5) unlockAch('power_upper');

    switch (pu) {
      case PowerUp.time:
        rt.timer?.cancel();
        rt.timerDurationMs += 5000;
        if (rt.qTimerLimit > 0) rt.qTimerLimit += 5;
        rt.timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
          if (elapsed >= rt.timerDurationMs) {
            t.cancel();
            _onTimeout();
          } else {
            notifyListeners();
          }
        });
        break;
      case PowerUp.fifty:
        // Remove 2 wrong answers
        if (rt.q != null) {
          final wrong = rt.q!.choices
              .where((c) => (c - rt.q!.ans).abs() >= 1e-9)
              .toList();
          wrong.shuffle(_rng);
          for (final w in wrong.take(2)) {
            rt.q!.choices.remove(w);
          }
        }
        break;
      case PowerUp.double:
        pl.doubleActive = true;
        break;
      case PowerUp.shield:
        pl.shieldActive = true;
        break;
      case PowerUp.freeze:
        rt.timer?.cancel();
        rt.frozen = true;
        break;
      case PowerUp.switchOp:
        Timer(const Duration(milliseconds: 500), () {
          if (!rt.gameActive || rt.state != 'playing') return;
          _generateQ();
          notifyListeners();
        });
        break;
    }
    audio.playPowerUp();
    notifyListeners();
  }

  bool _isPowerUpBlocked(PowerUp pu) {
    if (pu == PowerUp.time || pu == PowerUp.freeze) {
      if (mode == GameMode.blitz || mode == GameMode.combo) return true;
    }
    if (pu == PowerUp.freeze && (mode == GameMode.survival || rt.frozen)) {
      return true;
    }
    return false;
  }

  bool isPowerUpBlocked(PowerUp pu) => _isPowerUpBlocked(pu);

  // ─── Avatar builder ─────────────────────────────────────────
  void showAvatarBuilder(int pid) {
    builderPid = pid;
    final selected = p[pid].avatar;
    final saved = avatarCustom['$pid'];
    if (selected.isCustom) {
      builderAvatar = selected.custom!;
    } else {
      builderAvatar = AvatarCustom(
        base: selected.base,
        hat: saved?.hat ?? '',
        accessory: saved?.accessory ?? '',
        color: saved?.color,
      );
    }
    showModal(GameModal.avatarBuilder);
  }

  void setBuilderBase(String s) {
    builderAvatar = AvatarCustom(
      base: s,
      hat: builderAvatar.hat,
      accessory: builderAvatar.accessory,
      color: builderAvatar.color,
    );
    notifyListeners();
  }

  void setBuilderHat(String s) {
    builderAvatar = AvatarCustom(
      base: builderAvatar.base,
      hat: s,
      accessory: builderAvatar.accessory,
      color: builderAvatar.color,
    );
    notifyListeners();
  }

  void setBuilderAccessory(String s) {
    builderAvatar = AvatarCustom(
      base: builderAvatar.base,
      hat: builderAvatar.hat,
      accessory: s,
      color: builderAvatar.color,
    );
    notifyListeners();
  }

  void setBuilderColor(String? s) {
    builderAvatar = AvatarCustom(
      base: builderAvatar.base,
      hat: builderAvatar.hat,
      accessory: builderAvatar.accessory,
      color: s,
    );
    notifyListeners();
  }

  void saveCustomAvatar() {
    avatarCustom['$builderPid'] = builderAvatar;
    p[builderPid].avatar = AvatarData.custom(builderAvatar);
    unlockAch('avatar_artist');
    closeModal();
    save();
  }

  // ─── Coin shop ──────────────────────────────────────────────
  Future<void> buyShopItem(ShopItem item) async {
    if (item.special == 'watch') {
      await claimDailyCoinBonus();
      return;
    }
    if (!item.consumable && shopOwned.contains(item.id)) {
      showToast('Already owned');
      return;
    }
    if (coins < item.price) {
      showToast('Not enough 🪙');
      return;
    }
    addCoins(-item.price, true);
    if (!item.consumable) shopOwned.add(item.id);

    if (item.id.startsWith('av_')) {
      if (!unlockedAvatars.contains(item.emoji))
        unlockedAvatars.add(item.emoji);
    } else if (item.id.startsWith('hat_')) {
      if (!unlockedHats.contains(item.emoji)) unlockedHats.add(item.emoji);
    } else if (item.id == 'pack_powerups') {
      final bonus = _loadPowerUpBonus();
      for (final pu in PowerUp.values) {
        bonus[pu] = (bonus[pu] ?? 0) + 5;
      }
      _savePowerUpBonus(bonus);
      showToast('⚡ Power Pack activated! Bonus power-ups next game');
    } else if (item.id == 'pack_lives') {
      Storage.setInt('mc_livesBonus', Storage.getInt('mc_livesBonus', 0) + 1);
      showToast('❤️ Extra life added to next Master run');
    }
    await save();
    notifyListeners();
  }

  void beginIapPurchase(IapProduct product) {
    if (product.removesAds && adsRemoved) {
      showToast('Ads already removed');
      return;
    }
    pendingIapProduct = product;
    adultGateChallenge = _adultGateFactory();
    adultGateError = '';
    adultGateBusy = false;
    _adultGateReturnModal =
        currentModal == GameModal.adultGate ? GameModal.none : currentModal;
    currentModal = GameModal.adultGate;
    notifyListeners();
  }

  Future<void> submitAdultGateAnswer(String answer) async {
    final product = pendingIapProduct;
    final challenge = adultGateChallenge;
    if (product == null || challenge == null || adultGateBusy) return;
    if (!challenge.accepts(answer)) {
      adultGateError = 'Not quite. Please try again.';
      notifyListeners();
      return;
    }

    adultGateBusy = true;
    adultGateError = '';
    notifyListeners();

    try {
      await iapAdapter.buyProduct(product);
      _closeAdultGateToReturnModal();
      showToast('Opening Google Play...');
    } on IapException catch (e) {
      _closeAdultGateToReturnModal();
      await _handleIapError(e, product: product);
    } catch (_) {
      _closeAdultGateToReturnModal();
      showToast('Purchase could not start');
    }
  }

  void cancelAdultGate() {
    _closeAdultGateToReturnModal();
  }

  void _closeAdultGateToReturnModal() {
    pendingIapProduct = null;
    adultGateChallenge = null;
    adultGateError = '';
    adultGateBusy = false;
    currentModal = _adultGateReturnModal;
    _adultGateReturnModal = GameModal.none;
    if (rt.state == 'paused' &&
        rt.gameActive &&
        currentModal == GameModal.none) {
      rt.state = 'playing';
    }
    notifyListeners();
  }

  @visibleForTesting
  List<String> get debugIapDeliveredTxs => List.unmodifiable(iapDeliveredTxs);

  Future<bool> handleIapPurchase(IapPurchase purchase) async {
    if (!purchase.isApproved) return false;

    final product = IapProducts.byProductId(purchase.productId);
    var delivered = false;

    if (product != null) {
      final txKey = purchase.transactionKey;
      if (!iapDeliveredTxs.contains(txKey)) {
        await _rememberIapTransaction(txKey);
        if (product.kind == IapProductKind.consumable) {
          addCoins(product.deliveredCoins, true);
        } else if (product.removesAds) {
          adsRemoved = true;
          unawaited(_hideAdsSafely());
          await Storage.setBool('mc_adsRemoved', true);
          notifyListeners();
        }
        await save();
        delivered = true;
      }
    }

    try {
      await iapAdapter.completePurchase(purchase);
    } catch (_) {
      showToast('Purchase delivered. Google Play confirmation will retry.');
    }

    if (delivered && product != null) {
      showToast(product.removesAds
          ? '✅ ${product.label} — ads removed forever!'
          : '✅ ${product.label} added! +${product.deliveredCoins}🪙');
    }
    return delivered;
  }

  Future<bool> restorePurchases({bool silent = false}) async {
    try {
      final purchases = await iapAdapter.restorePurchases();
      final restored = await _applyRestoredPurchases(purchases);
      if (!silent) {
        showToast(restored
            ? 'Purchases restored. Ads are removed.'
            : 'No purchases to restore.');
      }
      return restored;
    } on IapException catch (e) {
      if (!silent) await _handleIapError(e);
      return false;
    } catch (_) {
      if (!silent) showToast('Purchase service failed. Please try again.');
      return false;
    }
  }

  Future<bool> _applyRestoredPurchases(List<IapPurchase> purchases) async {
    var restoredAds = false;
    for (final purchase in purchases) {
      if (!purchase.isApproved) continue;
      if (purchase.productId != IapProducts.removeAdsId) continue;
      restoredAds = true;
      unawaited(iapAdapter.completePurchase(purchase).catchError((_) {}));
    }

    if (restoredAds) {
      adsRemoved = true;
      unawaited(_hideAdsSafely());
      await Storage.setBool('mc_adsRemoved', true);
      await save();
      notifyListeners();
    }
    return restoredAds;
  }

  Future<void> _handleIapError(IapException e, {IapProduct? product}) async {
    switch (e.code) {
      case IapErrorCode.userCancelled:
        return;
      case IapErrorCode.alreadyOwned:
        if (product?.removesAds == true) {
          adsRemoved = true;
          unawaited(_hideAdsSafely());
          await Storage.setBool('mc_adsRemoved', true);
          await save();
          notifyListeners();
          showToast('Purchases restored. Ads are removed.');
          return;
        }
        showToast('You already own this purchase.');
        return;
      case IapErrorCode.billingUnavailable:
        showToast('Google Play billing is not available on this device.');
        return;
      case IapErrorCode.network:
        showToast('Connection lost. Please try again when online.');
        return;
      case IapErrorCode.developer:
      case IapErrorCode.unknown:
        showToast('Purchase failed. Please try again.');
        return;
    }
  }

  Future<void> _rememberIapTransaction(String key) async {
    if (!iapDeliveredTxs.contains(key)) {
      iapDeliveredTxs.add(key);
    }
    if (iapDeliveredTxs.length > 50) {
      iapDeliveredTxs = iapDeliveredTxs.sublist(iapDeliveredTxs.length - 50);
    }
    await Storage.setStringList('mc_iapDeliveredTxs', iapDeliveredTxs);
  }

  Future<void> resetAllData() async {
    rt.timer?.cancel();
    _cancelDelayedLossEnd();
    _turnSeq++;
    for (final key in _resetStorageKeys) {
      await Storage.remove(key);
    }
    _resetInMemoryData();
    showToast('All data reset');
  }

  void _resetInMemoryData() {
    _coinLedger.reset();
    _dailyBonusPolicy.reset();
    gamesPlayed = 0;
    adaptLvlRaw = 0;
    adaptLvl = 0;
    achievements = {
      for (final achievement in GameConfig.achievementsDef)
        achievement.id: false,
    };
    highScores = [];
    skillMap = {
      for (final op in [
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
      ])
        op.name: SkillData(),
    };
    numTypeUnlocked = {'integers': 0, 'rationals': 0};
    loginStreak = 0;
    avatarCustom = {
      '1': AvatarCustom(base: '🐶'),
      '2': AvatarCustom(base: '🐸'),
    };
    dailyProgress = {};
    dailyCompleted = {};
    dailyChallengeIds = [];
    final today = DateTime.now();
    dailyBossDateKey = _dailyDateKey(today);
    dailyBoss = _generateDailyBoss(today);
    shopOwned = [];
    unlockedAvatars = [];
    unlockedHats = [];
    adsRemoved = false;
    iapDeliveredTxs = [];
    adGameCount = 0;
    _pendingInterstitialAd = false;
    lastRewardedAt = 0;
    p = [
      PlayerState(),
      PlayerState(name: 'Player 1', avatar: const AvatarData.emoji('🐶')),
      PlayerState(name: 'Player 2', avatar: const AvatarData.emoji('🐱')),
    ];
    rt = RuntimeState();
    _masterLevel = 0;
    _masterLives = 3;
    _masterProgress = 0;
    currentScreen = GameScreen.menu;
    currentModal = GameModal.none;
    _toastController.reset();
    builderPid = 1;
    builderAvatar = AvatarCustom();
    isDailyBossClaimedToday = false;
    reactionPill = '';
    bigEmoji = '';
    bigEmojiVisible = false;
    celebration = const CelebrationEvent.none();
    lastUnlockedAchievementCount = 0;
    newlyUnlocked = [];
    resultIcon = '🏆';
    resultTitle = 'Player Report';
    resultDescription = '';
    adultGateChallenge = null;
    pendingIapProduct = null;
    adultGateError = '';
    adultGateBusy = false;
    _adultGateReturnModal = GameModal.none;
    settings.load(
      dark: false,
      sound: true,
      vibration: true,
      dyslexia: false,
      colorblind: false,
      lowPerf: false,
      reduceMotion: false,
      animSpeed: 1.0,
    );
  }

  // ─── Reaction pill clearing ─────────────────────────────────
  void clearReaction() {
    reactionPill = '';
    notifyListeners();
  }

  void setPlayerName(int pid, String name) {
    p[pid].name = name;
    notifyListeners();
  }
}
