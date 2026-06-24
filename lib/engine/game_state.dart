import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/game_data.dart';
import '../services/storage.dart';
import '../services/settings.dart';
import '../services/audio.dart';
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
  dailyChallenges,
}

/// Runtime game state (the `rt` object in the original JS).
class RuntimeState {
  Operation challenge;
  int activePlayer;
  Question? q;
  String state; // 'idle' | 'playing' | 'paused' | 'ended'
  bool accepting;
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
  bool dailyBossWon;
  bool frozen;
  bool isFollowUp;
  _FollowUpData? followUpData;
  int lastDailyBossClaimDay;

  RuntimeState()
      : challenge = Operation.mixed,
        activePlayer = 1,
        q = null,
        state = 'idle',
        accepting = false,
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
        dailyBossWon = false,
        frozen = false,
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
  GameState({required this.settings, required this.audio});

  final SettingsService settings;
  final AudioService audio;
  final QuestionGenerator _qgen = QuestionGenerator();
  final Random _rng = Random();

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
  late List<PlayerState> p = [PlayerState(), PlayerState(name: 'Player 1', avatar: '🐶'),
                                                 PlayerState(name: 'Player 2', avatar: '🐱')];

  // ─── Persistent ─────────────────────────────────────────────
  int coins = 0;
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
  DailyBoss? dailyBoss;
  int lastDailyBossClaimDay = -1;
  List<String> shopOwned = [];
  List<String> unlockedAvatars = [];
  List<String> unlockedHats = [];
  bool adsRemoved = false;

  // ─── UI routing ─────────────────────────────────────────────
  GameScreen currentScreen = GameScreen.menu;
  GameModal currentModal = GameModal.none;
  String toastMessage = '';
  bool toastVisible = false;
  Timer? _toastTimer;
  int builderPid = 1;
  AvatarCustom builderAvatar = AvatarCustom();
  bool isDailyBossClaimedToday = false;
  String reactionPill = '';
  String bigEmoji = '';
  bool bigEmojiVisible = false;
  int lastUnlockedAchievementCount = 0;
  List<Achievement> newlyUnlocked = [];

  // ─── Load / save ────────────────────────────────────────────
  Future<void> load() async {
    coins = Storage.getInt('mc_coins', 0);
    gamesPlayed = Storage.getInt('mc_gamesPlayed', 0);
    adaptLvlRaw = Storage.getDouble('mc_adaptLvl', 0);
    adaptLvl = adaptLvlRaw.round();
    achievements = _loadAchs();
    highScores = Storage.getObjectList<HighScore>('mc_scores',
        (j) => HighScore.fromJson(j));
    coins = Storage.getInt('mc_coins', 0);
    skillMap = _loadSkillMap();
    numTypeUnlocked = {
      'integers': Storage.getInt('mc_numTypeUnlocked_integers', 0),
      'rationals': Storage.getInt('mc_numTypeUnlocked_rationals', 0),
    };
    loginStreak = Storage.getInt('mc_loginStreak', 0);
    avatarCustom['1'] = Storage.getObject<AvatarCustom>('mc_avatarCustom1',
        (j) => AvatarCustom.fromJson(j), AvatarCustom(base: '🐶'))!;
    avatarCustom['2'] = Storage.getObject<AvatarCustom>('mc_avatarCustom2',
        (j) => AvatarCustom.fromJson(j), AvatarCustom(base: '🐸'))!;
    dailyProgress = _loadDailyProgress();
    dailyBoss = _generateDailyBoss(DateTime.now());
    shopOwned = Storage.getStringList('mc_shopOwned', []);
    unlockedAvatars = Storage.getStringList('mc_unlockedAvatars', []);
    unlockedHats = Storage.getStringList('mc_unlockedHats', []);
    adsRemoved = Storage.getBool('mc_adsRemoved', false);
    p[1].name = Storage.getString('mc_p1_name', 'Player 1');
    p[1].avatar = Storage.getString('mc_p1_avatar', '🐶');
    p[2].name = Storage.getString('mc_p2_name', 'Player 2');
    p[2].avatar = Storage.getString('mc_p2_avatar', '🐱');
    _updateLoginStreak();
    _updateDailyBossClaimStatus();
    notifyListeners();
  }

  Future<void> save() async {
    await Storage.setInt('mc_coins', coins);
    await Storage.setInt('mc_gamesPlayed', gamesPlayed);
    await Storage.setDouble('mc_adaptLvl', adaptLvlRaw);
    await Storage.setString('mc_achievements', _encodeAchs());
    await Storage.setObjectList('mc_scores', highScores);
    await Storage.setString('mc_skillMap', _encodeSkillMap());
    await Storage.setInt('mc_numTypeUnlocked_integers', numTypeUnlocked['integers']!);
    await Storage.setInt('mc_numTypeUnlocked_rationals', numTypeUnlocked['rationals']!);
    await Storage.setInt('mc_loginStreak', loginStreak);
    await Storage.setObject('mc_avatarCustom1', avatarCustom['1']!.toJson());
    await Storage.setObject('mc_avatarCustom2', avatarCustom['2']!.toJson());
    await Storage.setString('mc_dailyProgress', _encodeDailyProgress());
    await Storage.setStringList('mc_shopOwned', shopOwned);
    await Storage.setStringList('mc_unlockedAvatars', unlockedAvatars);
    await Storage.setStringList('mc_unlockedHats', unlockedHats);
    await Storage.setBool('mc_adsRemoved', adsRemoved);
    await Storage.setString('mc_p1_name', p[1].name);
    await Storage.setString('mc_p1_avatar', p[1].avatar is String ? p[1].avatar as String : '🐶');
    await Storage.setString('mc_p2_name', p[2].name);
    await Storage.setString('mc_p2_avatar', p[2].avatar is String ? p[2].avatar as String : '🐱');
  }

  // ─── Helpers ────────────────────────────────────────────────
  Map<String, bool> _loadAchs() {
    final raw = Storage.getString('mc_achievements_raw', '');
    final m = <String, bool>{};
    for (final a in GameConfig.achievementsDef) {
      m[a.id] = false;
    }
    if (raw.isEmpty) return m;
    for (final part in raw.split(',')) {
      if (part.isEmpty) continue;
      final kv = part.split('=');
      if (kv.length == 2) m[kv[0]] = kv[1] == '1';
    }
    return m;
  }

  String _encodeAchs() {
    return achievements.entries.map((e) => '${e.key}=${e.value ? 1 : 0}').join(',');
  }

  Map<String, SkillData> _loadSkillMap() {
    final raw = Storage.getString('mc_skillMap_raw', '');
    final def = <String, SkillData>{};
    for (final op in [Operation.addition, Operation.subtraction,
                      Operation.multiplication, Operation.division]) {
      def[op.name] = SkillData();
    }
    if (raw.isEmpty) return def;
    return def;
  }

  String _encodeSkillMap() {
    return skillMap.entries
        .map((e) => '${e.key}:${e.value.toJson()}')
        .join(';');
  }

  Map<String, int> _loadDailyProgress() {
    final raw = Storage.getString('mc_dailyProgress_raw', '');
    final m = <String, int>{};
    if (raw.isEmpty) return m;
    for (final part in raw.split(',')) {
      final kv = part.split('=');
      if (kv.length == 2) m[kv[0]] = int.tryParse(kv[1]) ?? 0;
    }
    return m;
  }

  String _encodeDailyProgress() {
    return dailyProgress.entries.map((e) => '${e.key}=${e.value}').join(',');
  }

  void _updateLoginStreak() {
    final today = DateTime.now().millisecondsSinceEpoch ~/ GameConfig.msPerDay;
    final lastDay = Storage.getInt('mc_lastLoginDay', -1);
    if (lastDay == today) return;
    if (lastDay == today - 1) {
      loginStreak++;
    } else {
      loginStreak = 1;
    }
    Storage.setInt('mc_lastLoginDay', today);
    notifyListeners();
  }

  DailyBoss _generateDailyBoss(DateTime date) {
    final day = date.millisecondsSinceEpoch ~/ GameConfig.msPerDay;
    final idx = day % GameConfig.dailyBosses.length;
    return GameConfig.dailyBosses[idx];
  }

  void _updateDailyBossClaimStatus() {
    final today = DateTime.now().millisecondsSinceEpoch ~/ GameConfig.msPerDay;
    isDailyBossClaimedToday = Storage.getInt('mc_lastDailyBossClaimDay', -1) == today;
  }

  // ─── Coin operations ────────────────────────────────────────
  void addCoins(int amount, [bool silent = false]) {
    coins += amount;
    if (!silent) {
      showToast(amount >= 0 ? '+$amount 🪙' : '$amount 🪙');
    }
    notifyListeners();
  }

  // ─── Toast ──────────────────────────────────────────────────
  void showToast(String msg) {
    toastMessage = msg;
    toastVisible = true;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      toastVisible = false;
      notifyListeners();
    });
  }

  // ─── Screen / modal routing ─────────────────────────────────
  void showScreen(GameScreen s) {
    currentScreen = s;
    notifyListeners();
  }

  void showModal(GameModal m) {
    currentModal = m;
    if (rt.state == 'playing' && _isPausingModal(m)) {
      rt.state = 'paused';
    }
    notifyListeners();
  }

  void closeModal() {
    currentModal = GameModal.none;
    if (rt.state == 'paused' && rt.gameActive) {
      rt.state = 'playing';
    }
    notifyListeners();
  }

  bool _isPausingModal(GameModal m) {
    return [
      GameModal.quitConfirm, GameModal.settings, GameModal.highScore,
      GameModal.achievements, GameModal.skillDashboard, GameModal.coinShop,
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

  void selectNumType(String numTypeName) {
    final nt = NumberType.fromString(numTypeName);
    if (nt == NumberType.integers && numTypeUnlocked['integers']! < 1) {
      // Unlock cost: 50 coins
      if (coins < 50) {
        showToast('Need 50 🪙 to unlock Integers');
        return;
      }
      addCoins(-50);
      numTypeUnlocked['integers'] = 1;
    } else if (nt == NumberType.rationals && numTypeUnlocked['rationals']! < 1) {
      if (coins < 100) {
        showToast('Need 100 🪙 to unlock Rationals');
        return;
      }
      addCoins(-100);
      numTypeUnlocked['rationals'] = 1;
    }
    numType = nt;
    showScreen(GameScreen.config);
  }

  void setOption(String key, dynamic value) {
    switch (key) {
      case 'players': players = value as int; break;
      case 'mode': mode = GameMode.fromString(value as String); break;
      case 'diff': diff = Difficulty.fromString(value as String); break;
      case 'q': questionCount = value as int; break;
    }
    notifyListeners();
  }

  void setAdaptive(bool v) { adaptive = v; notifyListeners(); }

  void goToPlayerSetup() {
    showScreen(GameScreen.player);
  }

  void backFromPlayers() {
    if (rt.challenge == Operation.master || rt.challenge == Operation.dailyBoss) {
      showScreen(GameScreen.menu);
      return;
    }
    showScreen(GameScreen.config);
  }

  void startMasterMode() {
    closeModal();
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

  void pickAvatar(int pid, dynamic av) {
    p[pid].avatar = av;
    notifyListeners();
  }

  // ─── Game lifecycle ─────────────────────────────────────────
  void startGame() {
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

    // Reset runtime
    rt = RuntimeState()
      ..challenge = isMaster ? Operation.master : (isBoss ? Operation.dailyBoss : rt.challenge)
      ..dailyBoss = isBoss ? dailyBoss : null
      ..dailyBossLives = isBoss ? (dailyBoss?.goal ?? 12) : 3
      ..gameActive = true
      ..state = 'playing'
      ..isWarmUp = (mode == GameMode.standard && !isMaster && !isBoss);

    rt.maxTurns = ([GameMode.blitz, GameMode.death, GameMode.survival, GameMode.combo]
        .contains(mode) || isMaster || isBoss)
        ? 99999
        : players * questionCount;

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
          ? [NumberType.natural, NumberType.integers, NumberType.rationals][_rng.nextInt(3)]
          : NumberType.fromString(masterNt);
    } else if (rt.challenge == Operation.dailyBoss) {
      final lvl = rt.dailyBoss ?? dailyBoss!;
      d = Difficulty.fromString(lvl.diff);
      type = Operation.fromString(lvl.type);
      boss = lvl.icon;
      numType = lvl.numType == 'mixed'
          ? [NumberType.natural, NumberType.integers, NumberType.rationals][_rng.nextInt(3)]
          : NumberType.fromString(lvl.numType);
    }

    if (mode == GameMode.survival) {
      d = Difficulty.fromString(
          GameConfig.phaseKeys[rt.survivalPhase.clamp(0, 4)]);
    }

    if (type == Operation.mixed || type == Operation.survival) {
      type = [Operation.multiplication, Operation.division,
              Operation.addition, Operation.subtraction][_rng.nextInt(4)];
    }

    // Adaptive difficulty
    if (adaptive && rt.challenge != Operation.master &&
        rt.challenge != Operation.dailyBoss && mode != GameMode.survival) {
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
      type: q.type, key: q.key, text: q.text, ans: q.ans,
      choices: q.choices, boss: boss, diff: d, ratDP: q.ratDP,
    );

    rt.q = q;
    rt.qStartTs = DateTime.now().millisecondsSinceEpoch;
    rt.accepting = true;

    // Start per-question timer
    if (mode != GameMode.blitz && mode != GameMode.combo) {
      _startQuestionTimer();
    }
  }

  Difficulty _getAdaptDiff(Operation type) {
    final m = skillMap[type.name]?.mastery ?? 20;
    if (m < 35) return Difficulty.easy;
    if (m < 60) return Difficulty.medium;
    if (m < 80) return Difficulty.hard;
    if (m < 95) return Difficulty.expert;
    return Difficulty.insane;
  }

  void _startQuestionTimer() {
    final baseMs = GameConfig.timerBaseMs[diff.name] ?? 10000;
    final penalty = adaptLvl ~/ GameConfig.timerPenaltyStep;
    final duration = max(GameConfig.timerMinMs, baseMs - penalty * 1000);
    rt.qTimerLimit = duration ~/ 1000;
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
    rt.timer?.cancel();

    final q = rt.q!;
    final isCorrect = val != null && (val - q.ans).abs() < 1e-9;
    final pid = rt.activePlayer;
    final pl = p[pid];
    final timeTaken = DateTime.now().millisecondsSinceEpoch - rt.qStartTs;

    pl.total++;
    pl.timeMs += timeTaken;
    pl.history.add(HistoryEntry(
      type: q.type, correct: isCorrect, ms: timeTaken,
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
    _scheduleNextTurn();
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
      final newPhase = min(rt.survivalCorrect ~/ 5, 4);
      if (newPhase > rt.survivalPhase) {
        rt.survivalPhase = newPhase;
        audio.vibratePattern([60, 30, 60]);
      }
    }

    // Combo mode
    if (mode == GameMode.combo) {
      rt.comboStreak++;
      final streak = rt.comboStreak;
      int mult = 1;
      if (streak >= GameConfig.comboThresholds[2]) {
        mult = GameConfig.comboMultipliers[2];
      } else if (streak >= GameConfig.comboThresholds[1]) mult = GameConfig.comboMultipliers[1];
      else if (streak >= GameConfig.comboThresholds[0]) mult = GameConfig.comboMultipliers[0];
      rt.comboMultiplier = mult.toDouble();
      rt.comboMaxMultiplier = max(rt.comboMaxMultiplier, mult);
    } else {
      rt.combo++;
      if (rt.combo >= 10) {
        rt.comboMultiplier = 2.0;
      } else if (rt.combo >= 5) rt.comboMultiplier = 1.5;
      else if (rt.combo >= 3) rt.comboMultiplier = 1.2;
    }

    // Power-up reward (single-player non-boss non-combo non-survival)
    final eligibleForPU = players == 1 &&
        rt.challenge != Operation.master &&
        rt.challenge != Operation.dailyBoss &&
        ![GameMode.combo, GameMode.survival].contains(mode);
    if (eligibleForPU && pl.correct > 0 && pl.correct % GameConfig.puRewardInterval == 0) {
      final pu = PowerUp.values[_rng.nextInt(PowerUp.values.length)];
      pl.pups.add(pu);
      audio.playPowerUp();
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
      } else if (timeTaken < 2500) bonus = 3;
      else if (timeTaken < 4000) bonus = 1;
    } else if (isBlitz) {
      if (timeTaken < 1500) {
        bonus = 8;
      } else if (timeTaken < 2500) bonus = 5;
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
        showToast('🔥 Streak ×${[5,10,20][i]}! +${GameConfig.streakCoins[i]}🪙');
      }
    }
    if (pl.streak == 1 && pl.total > 1 && pl.history.length >= 2 &&
        !pl.history[pl.history.length - 2].correct) {
      addCoins(3, true);
      showToast('🎁 Comeback! +3🪙');
    }

    final rx = GameConfig.correctRx[_rng.nextInt(GameConfig.correctRx.length)];
    reactionPill = '$rx +$pts';
    bigEmoji = rx.split(' ').first;
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
          _endGame(true, false);
        } else {
          // Show stage cleared modal
          rt.state = 'paused';
          showModal(GameModal.stageCleared);
        }
      }
    } else if (isBoss) {
      final lvl = rt.dailyBoss!;
      if (rt.dailyBossProgress >= lvl.goal) {
        rt.dailyBossWon = true;
        unlockAch('daily_boss');
        addCoins(lvl.reward);
        final today = DateTime.now().millisecondsSinceEpoch ~/ GameConfig.msPerDay;
        Storage.setInt('mc_lastDailyBossClaimDay', today);
        isDailyBossClaimedToday = true;
        _updateDailyProgress('daily_boss');
        _endGame(true, false);
      }
    } else {
      // Standard modes: check max turns
      if (rt.totalTurns + 1 >= rt.maxTurns) {
        _endGame(true, false);
      } else if (players == 2) {
        rt.activePlayer = rt.activePlayer == 1 ? 2 : 1;
      }
    }
  }

  void _onWrong(PlayerState pl, int pid, bool isSkip, bool isTimeout, num? val) {
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
      audio.vibrateWrong();
      notifyListeners();
      return;
    }

    if (mode == GameMode.death && !isSkip) {
      bigEmoji = '💀';
      reactionPill = '💀 Game Over!';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      Timer(const Duration(milliseconds: 600), () => _endGame(false, true));
      notifyListeners();
      return;
    }

    pl.streak = 0;

    if (mode == GameMode.survival && !isSkip) {
      rt.survivalLives--;
      bigEmoji = '💔';
      reactionPill = '💔 Ans: ${rt.q?.ans}';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      if (rt.survivalLives <= 0) {
        Timer(const Duration(milliseconds: 900), () => _endGame(false, true));
        notifyListeners();
        return;
      }
    } else if (rt.challenge == Operation.dailyBoss && !isSkip) {
      rt.dailyBossLives--;
      bigEmoji = '💔';
      reactionPill = '💔 Boss hit! Ans: ${rt.q?.ans}';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      if (rt.dailyBossLives <= 0) {
        Timer(const Duration(milliseconds: 900), () => _endGame(false, true));
        notifyListeners();
        return;
      }
    } else if (rt.challenge == Operation.master && !isSkip) {
      // Master: lose a life
      _masterLives--;
      bigEmoji = '💔';
      reactionPill = '💔 Ans: ${rt.q?.ans}';
      bigEmojiVisible = true;
      audio.playWrong();
      audio.vibrateWrong();
      if (_masterLives <= 0) {
        Timer(const Duration(milliseconds: 900), () => _endGame(false, true));
        notifyListeners();
        return;
      }
    } else {
      if (isSkip) {
        pl.skipped++;
        bigEmoji = '⏩';
        reactionPill = 'Skipped! Ans: ${rt.q?.ans}';
      } else {
        bigEmoji = isTimeout ? '⏰' : '😢';
        reactionPill = isTimeout ? "⏰ Time's Up! Ans: ${rt.q?.ans}"
                                  : '😢 Ans: ${rt.q?.ans}';
      }
      bigEmojiVisible = true;
      if (!isTimeout) {
        audio.playWrong();
        audio.vibrateWrong();
      }
      // Follow-up
      if (!isSkip && !isTimeout && mode == GameMode.standard &&
          rt.challenge != Operation.dailyBoss) {
        rt.isFollowUp = true;
        rt.followUpData = _FollowUpData(rt.q!.type, rt.q!.diff ?? diff);
      }
    }

    notifyListeners();
  }

  void _scheduleNextTurn() {
    if (!rt.gameActive) return;
    if (rt.state == 'paused') return;
    final delay = mode == GameMode.blitz || mode == GameMode.combo ? 400 : 1300;
    Timer(Duration(milliseconds: delay), () {
      bigEmojiVisible = false;
      _nextTurn();
    });
  }

  // ─── End game ───────────────────────────────────────────────
  void _endGame(bool win, bool loss) {
    rt.gameActive = false;
    rt.state = 'ended';
    rt.timer?.cancel();
    gamesPlayed++;
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

    // First win
    if (win) unlockAch('first_win');
    // Perfect score
    if (p[1].total > 0 && p[1].correct == p[1].total) unlockAch('perfect_score');
    // Streak master
    if (p[1].maxStreak >= 10) unlockAch('streak_master');
    // Speed demon
    if (rt.fastAnswers >= 5) unlockAch('speed_demon');
    // Survivor
    if (mode == GameMode.death && p[1].score >= 250) unlockAch('survivor');
    // Skill master
    for (final e in skillMap.entries) {
      if (e.value.confidence >= 90) unlockAch('skill_master');
    }
    // Quick learner
    if (adaptLvl >= 8) unlockAch('quick_learner');

    save();
    showModal(GameModal.win);
  }

  void advanceStage() {
    closeModal();
    rt.state = 'playing';
    _masterProgress = 0;
    _nextTurn();
  }

  void replayGame() {
    closeModal();
    startGame();
  }

  void quitToMenu() {
    closeModal();
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
    final delta = correct
        ? (timeMs < 2000 ? 0.4 : timeMs < 4000 ? 0.2 : 0.1)
        : -0.5;
    adaptLvlRaw = max(0, adaptLvlRaw + delta);
    adaptLvl = adaptLvlRaw.round();
  }

  void _updateSkillMap(Operation type, Difficulty d, bool correct, int timeMs) {
    final sd = skillMap[type.name] ?? SkillData();
    if (correct) {
      switch (d) {
        case Difficulty.easy:    sd.easy++; break;
        case Difficulty.medium:  sd.medium++; break;
        case Difficulty.hard:    sd.hard++; break;
        default: break;
      }
      sd.correct++;
    }
    sd.count++;
    // Mastery: exponential moving average
    final target = correct ? 100.0 : 0.0;
    sd.mastery = sd.mastery * 0.85 + target * 0.15;
    // Confidence: % correct
    sd.confidence = sd.count == 0 ? 0 : (sd.correct / sd.count) * 100;
    skillMap[type.name] = sd;
  }

  // ─── Achievements ───────────────────────────────────────────
  void unlockAch(String id) {
    if (achievements[id] == true) return;
    achievements[id] = true;
    final a = GameConfig.achievementsDef.firstWhere((e) => e.id == id);
    newlyUnlocked.add(a);
    showToast('${a.icon} ${a.name} unlocked!');
  }

  // ─── Daily challenges ───────────────────────────────────────
  void _updateDailyProgress(String id) {
    final cur = dailyProgress[id] ?? 0;
    dailyProgress[id] = cur + 1;
    final ch = GameConfig.dailyChallenges.firstWhere((c) => c.id == id);
    if (cur + 1 >= ch.target) {
      addCoins(ch.reward);
      showToast('🎁 ${ch.title} complete! +${ch.reward}🪙');
    }
  }

  void _updateDailyProgressAbsolute(String id, int value) {
    final cur = dailyProgress[id] ?? 0;
    if (value > cur) {
      dailyProgress[id] = value;
      final ch = GameConfig.dailyChallenges.firstWhere((c) => c.id == id);
      if (value >= ch.target && cur < ch.target) {
        addCoins(ch.reward);
        showToast('🎁 ${ch.title} complete! +${ch.reward}🪙');
      }
    }
  }

  // ─── Power-up usage ─────────────────────────────────────────
  void usePowerUp(PowerUp pu) {
    final pl = p[rt.activePlayer];
    if (!pl.pups.contains(pu)) return;
    pl.pups.remove(pu);
    rt.puUsed++;
    if (rt.puUsed >= 5) unlockAch('power_upper');

    switch (pu) {
      case PowerUp.time:
        rt.timer?.cancel();
        rt.timerDurationMs += 5000;
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
          final wrong = rt.q!.choices.where((c) => (c - rt.q!.ans).abs() >= 1e-9).toList();
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
        break;
      case PowerUp.switchOp:
        _nextTurn();
        break;
    }
    audio.playPowerUp();
    notifyListeners();
  }

  // ─── Avatar builder ─────────────────────────────────────────
  void showAvatarBuilder(int pid) {
    builderPid = pid;
    builderAvatar = avatarCustom['$pid'] ?? AvatarCustom();
    showModal(GameModal.avatarBuilder);
  }

  void setBuilderBase(String s) { builderAvatar = AvatarCustom(
    base: s, hat: builderAvatar.hat, accessory: builderAvatar.accessory, color: builderAvatar.color,
  ); notifyListeners(); }
  void setBuilderHat(String s) { builderAvatar = AvatarCustom(
    base: builderAvatar.base, hat: s, accessory: builderAvatar.accessory, color: builderAvatar.color,
  ); notifyListeners(); }
  void setBuilderAccessory(String s) { builderAvatar = AvatarCustom(
    base: builderAvatar.base, hat: builderAvatar.hat, accessory: s, color: builderAvatar.color,
  ); notifyListeners(); }
  void setBuilderColor(String? s) { builderAvatar = AvatarCustom(
    base: builderAvatar.base, hat: builderAvatar.hat, accessory: builderAvatar.accessory, color: s,
  ); notifyListeners(); }

  void saveCustomAvatar() {
    avatarCustom['$builderPid'] = builderAvatar;
    p[builderPid].avatar = builderAvatar;
    unlockAch('avatar_artist');
    closeModal();
    save();
  }

  // ─── Coin shop ──────────────────────────────────────────────
  void buyShopItem(ShopItem item) {
    if (item.special == 'watch') {
      addCoins(100);
      showToast('+100 🪙 Daily bonus');
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
      unlockedAvatars.add(item.emoji);
    } else if (item.id.startsWith('hat_')) {
      unlockedHats.add(item.emoji);
    } else if (item.id == 'pack_powerups') {
      // Add 5 of each power-up to next game
      showToast('🎒 Power Pack applied to next game');
    } else if (item.id == 'pack_lives') {
      Storage.setInt('mc_livesBonus', Storage.getInt('mc_livesBonus', 0) + 1);
      showToast('❤️ Extra life added to next Master run');
    }
    save();
    notifyListeners();
  }

  void resetAllData() {
    Storage.remove('mc_coins');
    Storage.remove('mc_gamesPlayed');
    Storage.remove('mc_adaptLvl');
    Storage.remove('mc_achievements_raw');
    Storage.remove('mc_scores');
    Storage.remove('mc_skillMap_raw');
    Storage.remove('mc_numTypeUnlocked_integers');
    Storage.remove('mc_numTypeUnlocked_rationals');
    Storage.remove('mc_loginStreak');
    Storage.remove('mc_avatarCustom1');
    Storage.remove('mc_avatarCustom2');
    Storage.remove('mc_dailyProgress_raw');
    Storage.remove('mc_shopOwned');
    Storage.remove('mc_unlockedAvatars');
    Storage.remove('mc_unlockedHats');
    Storage.remove('mc_adsRemoved');
    Storage.remove('mc_p1_name');
    Storage.remove('mc_p1_avatar');
    Storage.remove('mc_p2_name');
    Storage.remove('mc_p2_avatar');
    load();
    showToast('All data reset');
  }

  // ─── Reaction pill clearing ─────────────────────────────────
  void clearReaction() {
    reactionPill = '';
    notifyListeners();
  }

  void setPlayerName(int pid, String name) {
    p[pid].name = name.isEmpty ? 'Player $pid' : name;
    notifyListeners();
  }
}
