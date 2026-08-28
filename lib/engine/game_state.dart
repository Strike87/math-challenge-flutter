import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/adaptive/domain/adaptive_difficulty_engine.dart';
import '../features/cloud_save/domain/cloud_progress_document.dart';
import '../features/economy/domain/coin_ledger.dart';
import '../features/economy/domain/daily_bonus_policy.dart';
import '../features/economy/domain/number_type_unlock_policy.dart';
import '../features/family/domain/family_eligibility.dart';
import '../features/game_brain/domain/game_brain_eligibility.dart';
import '../features/game_brain/experience/p1_f01_device_validation_probe.dart';
import '../features/game_brain/experience/p1_f01_integrity_store.dart';
import '../features/game_brain/experience/question_experience_observation.dart';
import '../features/game_brain/experience/run_local_question_difficulty_measurement_collector.dart';
import '../features/game_brain/experience/run_local_question_experience_collector.dart';
import '../features/game_brain/game_brain.dart';
import '../features/game_brain/integration/adaptive_shadow_integration.dart';
import '../features/gameplay/domain/question_difficulty_legality.dart';
import '../features/gameplay/domain/survival_progression_policy.dart';
import '../features/gameplay/domain/question_mechanic.dart';
import '../features/modals/presentation/toast_controller.dart';
import '../features/operation_quest/domain/operation_quest.dart';
import '../features/weak_skills/domain/weak_skills_policy.dart';
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
import '../services/play_games.dart';
import 'question_generator.dart';

/// Screen identifier — mirrors the original HTML section IDs.
enum GameScreen { menu, practiceStyle, numType, config, player, game }

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
  operationQuest,
  weakSkillsPractice,
}

enum _QuestionTerminalClaim {
  answer,
  skip,
  timeout,
  switchReplacement,
  neutral,
}

enum MentalMathTerminalReason {
  masteryReached,
  practiceComplete,
  trainingComplete,
}

@immutable
class MentalMathResultSummary {
  const MentalMathResultSummary({
    required this.avatarEmoji,
    required this.terminalTitle,
    required this.message,
    required this.peakMomentum,
    required this.bestStreak,
    required this.accuracyPercent,
    required this.averageResponseMs,
    required this.fastestAnswerMs,
  });

  final String avatarEmoji;
  final String terminalTitle;
  final String message;
  final int peakMomentum;
  final int bestStreak;
  final int accuracyPercent;
  final int? averageResponseMs;
  final int? fastestAnswerMs;
  static const int factsRecovered = 0;
}

/// Runtime game state (the `rt` object in the original JS).
class RuntimeState {
  Operation challenge;
  AnswerStyle answerStyle;
  num? proposedAnswer;
  bool? proposedTruth;
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
  Timer? timeBankTimer;
  int timeBankTimerStart;
  int timeBankRemainingMs;
  bool timeBankExhausted;
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
  int weakSkillsScheduleIndex;
  int momentum;
  int peakMomentum;
  int currentStreak;
  int bestStreak;
  int completedQuestions;
  int mentalMathAnsweredResponseTotalMs;
  int mentalMathAnsweredResponseCount;
  int nextQuestionTimerBudgetMs;
  MentalMathTerminalReason? terminalReason;
  Timer? mentalMathCountdownTimer;
  int mentalMathCountdownStep;

  RuntimeState()
      : challenge = Operation.mixed,
        answerStyle = AnswerStyle.choice4,
        proposedAnswer = null,
        proposedTruth = null,
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
        timeBankTimer = null,
        timeBankTimerStart = 0,
        timeBankRemainingMs = 0,
        timeBankExhausted = false,
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
        lastDailyBossClaimDay = -1,
        weakSkillsScheduleIndex = 0,
        momentum = 0,
        peakMomentum = 0,
        currentStreak = 0,
        bestStreak = 0,
        completedQuestions = 0,
        mentalMathAnsweredResponseTotalMs = 0,
        mentalMathAnsweredResponseCount = 0,
        nextQuestionTimerBudgetMs = 10000,
        terminalReason = null,
        mentalMathCountdownTimer = null,
        mentalMathCountdownStep = -1;
}

class _FollowUpData {
  final Operation type;
  final Difficulty diff;
  _FollowUpData(this.type, this.diff);
}

@immutable
class GameRunSnapshot {
  const GameRunSnapshot({
    required this.runType,
    required this.mode,
    required this.operation,
    required this.difficulty,
    required this.numberType,
    required this.answerStyle,
    required this.players,
    required this.questionTarget,
    this.operationQuestStageId,
    this.questionMechanic = QuestionMechanic.standard,
    this.timingStyle = TimingStyle.perQuestion,
    this.operationPool,
    this.integerQuest = false,
    this.decimalQuest = false,
    this.weakSkillsPlan,
    this.mentalMathEntry,
  });

  final GameRunType runType;
  final GameMode mode;
  final Operation operation;
  final Difficulty difficulty;
  final NumberType numberType;
  final AnswerStyle answerStyle;
  final int players;
  final int questionTarget;
  final OperationQuestStageId? operationQuestStageId;
  final QuestionMechanic questionMechanic;
  final TimingStyle timingStyle;
  final List<Operation>? operationPool;
  final bool integerQuest;
  final bool decimalQuest;
  final WeakSkillsPlan? weakSkillsPlan;
  final MentalMathEntry? mentalMathEntry;

  GameRunSnapshot withTimingStyle(TimingStyle value) => GameRunSnapshot(
        runType: runType,
        mode: mode,
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        answerStyle: answerStyle,
        players: players,
        questionTarget: questionTarget,
        operationQuestStageId: operationQuestStageId,
        questionMechanic: questionMechanic,
        timingStyle: value,
        operationPool: operationPool,
        integerQuest: integerQuest,
        decimalQuest: decimalQuest,
        weakSkillsPlan: weakSkillsPlan,
        mentalMathEntry: mentalMathEntry,
      );
}

@visibleForTesting
({num answer, bool truth}) trueFalseProposal(Question question) {
  final correctIndex = question.choices.indexWhere(
    (choice) => (choice - question.ans).abs() < 1e-9,
  );
  assert(
    correctIndex >= 0,
    'True/False proposal requires the correct answer in choices.',
  );
  if (correctIndex < 0) {
    throw StateError(
      'True/False proposal requires the correct answer in choices.',
    );
  }
  if (correctIndex.isEven) {
    return (answer: question.choices[correctIndex], truth: true);
  }
  return (
    answer: question.choices.firstWhere(
      (choice) => (choice - question.ans).abs() >= 1e-9,
    ),
    truth: false,
  );
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
    PlayGamesService? playGamesService,
    AdultGateChallenge Function()? adultGateFactory,
    int Function()? nowMillisProvider,
    AdaptiveShadowEvaluator? adaptiveShadowEvaluator,
    QuestionGenerator? questionGenerator,
    P1F01IntegrityStore? p1F01IntegrityStore,
  })  : iapAdapter = iapAdapter ?? const UnavailableIapPurchaseAdapter(),
        adService = adService ?? const UnavailableAdMobService(),
        playGamesService = playGamesService ?? NativePlayGamesService(),
        _nowMillis =
            nowMillisProvider ?? (() => DateTime.now().millisecondsSinceEpoch),
        _adaptiveShadowEvaluator =
            adaptiveShadowEvaluator ?? evaluateAdaptiveShadow,
        _qgen = questionGenerator ?? QuestionGenerator(),
        _ownsP1F01IntegrityStore = p1F01IntegrityStore == null,
        _p1F01IntegrityStore = p1F01IntegrityStore ?? P1F01IntegrityStore(),
        _adultGateFactory =
            adultGateFactory ?? (() => AdultGateChallenge.random()) {
    _toastController = ToastController(onChanged: notifyListeners);
    _iapPurchaseSub = iapPurchaseStream?.listen((purchases) {
      for (final purchase in purchases) {
        unawaited(handleIapPurchase(purchase));
      }
    });
    P1F01DeviceValidationServiceExtension.register(
      P1F01DeviceValidationProbe(_p1F01IntegrityStore),
    );
  }

  static const double _masteryMax = AdaptiveDifficultyEngine.maxMastery;
  static const double _masteryDefault = AdaptiveDifficultyEngine.defaultMastery;
  static const int _untimedMasteryResponseMs = 2000;
  static const Map<Difficulty, int> _timeBankBaseMs = {
    Difficulty.easy: 10000,
    Difficulty.medium: 8000,
    Difficulty.hard: 6000,
  };
  static const int dailyBonusCoins = 20;
  static const int rewardedAdCoins = 10;
  static const int rewardedCooldownMs = 300000;
  static const int interstitialCadenceGames = 3;
  static const int familyGateSchemaVersion = 2;
  static const String familyGateVersionStorageKey = 'mc_familyGateVersion';
  static const String familyAgeRangeStorageKey = 'mc_familyAgeRange';
  static const String gameBrainPreferenceStorageKey = 'mc_gameBrainEnabled';
  static const _adaptiveDifficultyEngine = AdaptiveDifficultyEngine();
  static const _survivalProgressionPolicy = SurvivalProgressionPolicy();

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
    'mc_selectedAnswerStyle',
    'mc_operationQuestProgress',
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
    gameBrainPreferenceStorageKey,
  ];

  @visibleForTesting
  static List<String> get debugResetStorageKeys =>
      List.unmodifiable(_resetStorageKeys);

  final SettingsService settings;
  final AudioService audio;
  final IapPurchaseAdapter iapAdapter;
  final AdMobService adService;
  final PlayGamesService playGamesService;
  final AdultGateChallenge Function() _adultGateFactory;
  final int Function() _nowMillis;
  final AdaptiveShadowEvaluator _adaptiveShadowEvaluator;
  final QuestionGenerator _qgen;
  final bool _ownsP1F01IntegrityStore;
  final P1F01IntegrityStore _p1F01IntegrityStore;
  final Random _rng = Random();
  StreamSubscription<List<IapPurchase>>? _iapPurchaseSub;

  // Master-mode progression state (kept outside `rt` because it survives
  // stage-clear modal round-trips but is reset on quit).
  int _masterLevel = 0;
  int _masterLives = 3;
  int _masterProgress = 0;
  GameRunSnapshot? _runSnapshot;
  GameBrain? _gameBrain;
  ContextEvidenceResult? _lastContextEvidenceResult;
  OperationQuestStageId? _pendingOperationQuestStageId;
  QuestionMechanic _pendingQuestionMechanic = QuestionMechanic.standard;
  WeakSkillsPlan? _pendingWeakSkillsPlan;
  MentalMathEntry? _pendingMentalMathEntry;
  bool? _adaptiveBeforeMentalMath;
  bool _pendingPracticeStyle = false;

  // ─── Options ────────────────────────────────────────────────
  int players = 1;
  GameMode mode = GameMode.standard;
  Difficulty diff = Difficulty.easy;
  int questionCount = 10;
  bool adaptive = false;
  TimingStyle timingStyle = TimingStyle.perQuestion;
  bool gameBrainPreference = false;
  NumberType numType = NumberType.natural;
  AnswerStyle selectedAnswerStyle = AnswerStyle.choice4;

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
  final NumberTypeUnlockPolicy _numberTypeUnlockPolicy =
      const NumberTypeUnlockPolicy();
  int get coins => _coinLedger.balance;
  set coins(int value) => _coinLedger.balance = value;
  int gamesPlayed = 0;
  int cloudResetGeneration = 0;
  int? cloudRevision;
  String? cloudRevisionId;
  String? cloudParentRevisionId;
  List<String> _cloudMergeParentRevisionIds = [];
  List<String> get cloudMergeParentRevisionIds =>
      List.unmodifiable(_cloudMergeParentRevisionIds);
  String? cloudLastSyncedRevisionId;
  bool cloudDirty = false;
  bool cloudResetRecoveryBlocked = false;
  OperationQuestProgress operationQuestProgress = OperationQuestProgress();
  int operationQuestResultStars = 0;
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
  bool _playGamesBusy = false;
  bool _playGamesInitialized = false;
  PlayGamesConnectionState playGamesConnectionState =
      PlayGamesConnectionState.checking;
  FamilyEligibility familyEligibility = FamilyEligibility.unresolved;
  FamilyAgeRange? familyAgeRange;
  String familyGateError = '';
  final Stopwatch _diagnosticClock = Stopwatch()..start();

  GameRunSnapshot? get activeRunSnapshot => _runSnapshot;
  @visibleForTesting
  ContextEvidenceResult? get debugLastContextEvidenceResult =>
      _lastContextEvidenceResult;
  @visibleForTesting
  int get debugContextEvidenceObservationCount =>
      _gameBrain?.contextEvidenceMemory.observations.length ?? 0;
  @visibleForTesting
  bool get debugHasContextEvidenceObserver => _gameBrain != null;
  @visibleForTesting
  int get debugQuestionExperienceObservationCount => _questionExperience.count;
  @visibleForTesting
  List<QuestionExperienceObservation> get debugQuestionExperienceObservations =>
      _questionExperience.snapshot;
  @visibleForTesting
  int get debugQuestionDifficultyMeasurementCount =>
      _questionDifficultyMeasurements.count;
  @visibleForTesting
  List<QuestionDifficultyLegality?> get debugQuestionDifficultyMeasurements =>
      _questionDifficultyMeasurements.snapshot;
  @visibleForTesting
  List<QuestionDifficultyMeasurementOpportunity>
      get debugQuestionDifficultyMeasurementOpportunities =>
          _questionDifficultyMeasurements.opportunities;
  @visibleForTesting
  Future<P1F01IntegritySnapshot?> debugP1F01IntegritySnapshot() =>
      _p1F01IntegrityStore.latestSnapshot();
  @visibleForTesting
  bool get debugP1F01IntegrityRunEligible => _p1F01IntegrityRunEligible;
  @visibleForTesting
  void debugStartGameFromSnapshot(GameRunSnapshot snapshot) {
    _startGame(replaySnapshot: snapshot, skipMentalMathCountdown: true);
  }

  QuestionDifficultyLegality? get currentQuestionDifficultyLegality =>
      _questionDifficultyLegality;
  @visibleForTesting
  QuestionDifficultyLegality? get debugQuestionDifficultyLegality =>
      currentQuestionDifficultyLegality;
  bool get isPlayGamesEligible =>
      familyEligibility == FamilyEligibility.eligible;
  bool get isOperationQuest =>
      _runSnapshot?.runType == GameRunType.operationQuest;
  bool get isMissingOperation =>
      _runSnapshot?.questionMechanic == QuestionMechanic.missingOperation;
  bool get isMissingOperationQuest => isOperationQuest && isMissingOperation;
  bool get isMissingOperationPractice =>
      !isOperationQuest &&
      (_runSnapshot?.questionMechanic == QuestionMechanic.missingOperation ||
          _pendingQuestionMechanic == QuestionMechanic.missingOperation);
  bool get isMissingNumberQuest =>
      _runSnapshot?.questionMechanic == QuestionMechanic.missingNumber;
  WeakSkillsPlan? get setupWeakSkillsPlan => _pendingWeakSkillsPlan;
  MentalMathEntry? get setupMentalMathEntry => _pendingMentalMathEntry;
  bool get isMentalMathSetup => _pendingMentalMathEntry != null;
  int get setupPlayers => _pendingOperationQuestStageId == null &&
          _pendingWeakSkillsPlan == null &&
          !isMentalMathSetup
      ? players
      : 1;
  bool get canSelectDeepThinking =>
      _pendingOperationQuestStageId == null &&
      _pendingWeakSkillsPlan == null &&
      !isMentalMathSetup &&
      _pendingQuestionMechanic == QuestionMechanic.standard &&
      mode == GameMode.standard &&
      setupPlayers == 1 &&
      !adaptive &&
      rt.challenge != Operation.master &&
      rt.challenge != Operation.dailyBoss;
  bool get canSelectTimeBank =>
      canSelectDeepThinking && playerConfigurableDifficultySet.contains(diff);
  TimingStyle get setupTimingStyle => switch (timingStyle) {
        TimingStyle.untimed when canSelectDeepThinking => TimingStyle.untimed,
        TimingStyle.timeBank when canSelectTimeBank => TimingStyle.timeBank,
        _ => TimingStyle.perQuestion,
      };
  bool get _isDeepThinkingRun {
    final snapshot = _runSnapshot;
    return snapshot != null &&
        snapshot.timingStyle == TimingStyle.untimed &&
        snapshot.runType == GameRunType.normal &&
        snapshot.mode == GameMode.standard &&
        snapshot.players == 1 &&
        snapshot.questionMechanic == QuestionMechanic.standard &&
        snapshot.operation != Operation.master &&
        snapshot.operation != Operation.dailyBoss &&
        snapshot.operationQuestStageId == null &&
        snapshot.weakSkillsPlan == null;
  }

  bool get isTimeBankRun {
    final snapshot = _runSnapshot;
    return snapshot != null &&
        snapshot.timingStyle == TimingStyle.timeBank &&
        _supportsTimeBankSnapshot(snapshot);
  }

  int get timeBankRemainingMs {
    if (!isTimeBankRun) return 0;
    if (rt.timeBankTimerStart <= 0) return rt.timeBankRemainingMs;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - rt.timeBankTimerStart;
    return max(0, rt.timeBankRemainingMs - elapsed);
  }

  Iterable<PowerUp> get _availablePowerUpsForActiveRun => _isDeepThinkingRun ||
          isTimeBankRun
      ? PowerUp.values.where((pu) => pu != PowerUp.time && pu != PowerUp.freeze)
      : PowerUp.values;

  int get activePlayers => _runSnapshot?.players ?? players;
  GameMode get activeMode => _runSnapshot?.mode ?? mode;
  Difficulty get activeDifficulty => _runSnapshot?.difficulty ?? diff;
  NumberType get activeNumberType => _runSnapshot?.numberType ?? numType;
  bool get _isMentalMathFreePracticeRun =>
      _runSnapshot?.mentalMathEntry == MentalMathEntry.freePractice;
  bool get isMentalMathCountdown =>
      _isMentalMathFreePracticeRun && rt.state == 'countdown';
  bool get isMentalMathGameplay =>
      _isMentalMathFreePracticeRun && rt.state == 'playing';
  String get mentalMathCountdownLabel => switch (rt.mentalMathCountdownStep) {
        3 => '3',
        2 => '2',
        1 => '1',
        0 => 'GO!',
        _ => '',
      };
  int get activeQuestionTarget => _runSnapshot?.questionTarget ?? questionCount;
  bool get activeAdaptive =>
      isOperationQuest || isTimeBankRun || _runSnapshot?.mentalMathEntry != null
          ? false
          : adaptive;
  bool get effectiveGameBrainEnabled =>
      gameBrainPreference &&
      gameBrainEligibility == GameBrainEligibility.eligible;
  GameBrainEligibility get gameBrainEligibility =>
      gameBrainEligibilityFor(familyAgeRange);

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
  MentalMathResultSummary? mentalMathResultSummary;
  AdultGateChallenge? adultGateChallenge;
  IapProduct? pendingIapProduct;
  String adultGateError = '';
  bool adultGateBusy = false;
  bool _directIapStartBusy = false;
  GameModal _adultGateReturnModal = GameModal.none;
  int _turnSeq = 0;
  int _lastRunId = 0;
  int _activeRunId = 0;
  int _lastQuestionId = 0;
  int _activeQuestionId = 0;
  _QuestionTerminalClaim? _questionTerminalClaim;
  final _questionExperience = RunLocalQuestionExperienceCollector();
  final _questionDifficultyMeasurements =
      RunLocalQuestionDifficultyMeasurementCollector();
  QuestionDifficultyLegality? _questionDifficultyLegality;
  bool _p1F01IntegrityRunEligible = false;
  bool _p1F01IntegrityMeasurementFailed = false;
  bool _disposed = false;

  MasterLevel? get clearedMasterLevel {
    final idx = _masterLevel;
    if (currentModal != GameModal.stageCleared ||
        idx < 0 ||
        idx >= GameConfig.masterLevels.length) {
      return null;
    }
    return GameConfig.masterLevels[idx];
  }

  MasterLevel? get nextMasterLevel {
    final idx = _masterLevel + 1;
    if (idx < 0 || idx >= GameConfig.masterLevels.length) {
      return null;
    }
    return GameConfig.masterLevels[idx];
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
    _closeActiveQuestionNeutrally();
    rt.mentalMathCountdownTimer?.cancel();
    _invalidateActiveRun();
    rt.gameActive = false;
    _iapPurchaseSub?.cancel();
    _toastController.dispose();
    _bigEmojiHideTimer?.cancel();
    _postFeedbackTimer?.cancel();
    _delayedResultModalTimer?.cancel();
    _cancelDelayedLossEnd();
    rt.timer?.cancel();
    rt.timeBankTimer?.cancel();
    if (_ownsP1F01IntegrityStore) {
      unawaited(_p1F01IntegrityStore.close());
    }
    super.dispose();
  }

  // ─── Load / save ────────────────────────────────────────────
  Future<void> load() async {
    unawaited(_p1F01IntegrityStore.recoverOpenWindows());
    _loadFamilyEligibility();
    gameBrainPreference = Storage.getBool(gameBrainPreferenceStorageKey, false);
    final skipCloudOwnedLoad = await _recoverCloudResetIntent();
    if (!skipCloudOwnedLoad) {
      cloudResetGeneration = Storage.getInt('mc_cloudResetGeneration', 0);
      final storedCloudRevision = Storage.getInt('mc_cloudRevision', -1);
      cloudRevision = storedCloudRevision >= 0 ? storedCloudRevision : null;
      cloudRevisionId = _cloudString('mc_cloudRevisionId');
      cloudParentRevisionId = _cloudString('mc_cloudParentRevisionId');
      _cloudMergeParentRevisionIds = cloudParentRevisionId == null
          ? _loadCloudMergeParentRevisionIds()
          : [];
      cloudLastSyncedRevisionId = _cloudString('mc_cloudLastSyncedRevisionId');
      cloudDirty = Storage.getBool('mc_cloudDirty', false);
      coins = Storage.getInt('mc_coins', 0);
      gamesPlayed = Storage.getInt('mc_gamesPlayed', 0);
      operationQuestProgress = OperationQuestProgress.decode(
        Storage.getString('mc_operationQuestProgress', ''),
      );
      adaptLvlRaw = Storage.getDouble('mc_adaptLvl', 0);
      adaptLvl = adaptLvlRaw.round();
      achievements = _loadAchs();
      highScores = List<HighScore>.from(Storage.getObjectList<HighScore>(
          'mc_scores', (j) => HighScore.fromJson(j)));
      coins = Storage.getInt('mc_coins', 0);
      skillMap = _loadSkillMap();
      _recomputeAdaptiveLevel();
      numTypeUnlocked = _loadNumTypeUnlocked();
      avatarCustom['1'] = _loadAvatarCustom(1);
      avatarCustom['2'] = _loadAvatarCustom(2);
      shopOwned = _loadOwnedList('mc_shopOwned');
      unlockedAvatars = _loadStringListCompat('mc_unlockedAvatars');
      unlockedHats = _loadStringListCompat('mc_unlockedHats');
      _loadPlayerData(1);
      _loadPlayerData(2);
    }
    selectedAnswerStyle = AnswerStyle.fromString(
      Storage.getString('mc_selectedAnswerStyle', ''),
    );
    loginStreak = Storage.getInt('mc_loginStreak', 0);
    dailyProgress = _loadDailyProgress();
    dailyChallengeIds = _loadDailyChallengeIds();
    final today = DateTime.now();
    dailyBossDateKey = _dailyDateKey(today);
    dailyBoss = _generateDailyBoss(today);
    adsRemoved = Storage.getBool('mc_adsRemoved', false);
    iapDeliveredTxs = Storage.getStringList('mc_iapDeliveredTxs', []);
    adGameCount = Storage.getInt('mc_adGameCount', 0);
    lastRewardedAt = Storage.getInt('mc_lastRewardedAt', 0);
    await restorePurchases(silent: true, notify: false);
    await _updateLoginStreak(notify: false);
    _updateDailyBossClaimStatus();
    if (!skipCloudOwnedLoad) await _persistLoadedMigrationState();
    _hydrateDailyBonusPolicy();
    notifyListeners();
  }

  Future<bool> setGameBrainPreference(bool value) async {
    try {
      await Storage.setBool(gameBrainPreferenceStorageKey, value);
    } on Exception {
      showToast('Could not save GameBrain preference. Please try again.');
      return false;
    }
    gameBrainPreference = value;
    notifyListeners();
    return true;
  }

  Future<bool> clearGameBrainData() async {
    try {
      await Storage.remove(gameBrainPreferenceStorageKey);
      final integrityCleared = await _p1F01IntegrityStore.deleteAll();
      if (!integrityCleared) {
        throw Exception('Could not clear P1-F01 integrity state.');
      }
    } on Exception {
      showToast('Could not clear GameBrain data. Please try again.');
      return false;
    }
    gameBrainPreference = false;
    notifyListeners();
    return true;
  }

  Future<bool> submitFamilyAgeRange(FamilyAgeRange range) async {
    try {
      await Storage.setString(
        familyAgeRangeStorageKey,
        range.name,
      );
      await Storage.setInt(
        familyGateVersionStorageKey,
        familyGateSchemaVersion,
      );
    } on Exception {
      _setFamilyGateError('Could not save this setting. Please try again.');
      return false;
    }
    try {
      await Storage.remove('mc_familyEligibilityDate');
    } catch (_) {
      // A completed v2 decision remains valid if stale v1 cleanup fails.
    }
    familyAgeRange = range;
    familyEligibility = range.eligibility;
    familyGateError = '';
    playGamesConnectionState = isPlayGamesEligible
        ? PlayGamesConnectionState.checking
        : PlayGamesConnectionState.disconnected;
    notifyListeners();
    return true;
  }

  void _loadFamilyEligibility() {
    final version = Storage.getInt(familyGateVersionStorageKey, 0);
    final ageRange = parseFamilyAgeRange(
      Storage.getString(familyAgeRangeStorageKey, ''),
    );
    if (version != familyGateSchemaVersion || ageRange == null) {
      familyEligibility = FamilyEligibility.unresolved;
      familyAgeRange = null;
      playGamesConnectionState = PlayGamesConnectionState.disconnected;
      return;
    }
    familyAgeRange = ageRange;
    familyEligibility = ageRange.eligibility;
    playGamesConnectionState = isPlayGamesEligible
        ? PlayGamesConnectionState.checking
        : PlayGamesConnectionState.disconnected;
  }

  void _setFamilyGateError(String message) {
    familyGateError = message;
    notifyListeners();
  }

  Future<void> save() async {
    await Storage.setInt('mc_coins', coins);
    await Storage.setInt('mc_gamesPlayed', gamesPlayed);
    await Storage.setString(
      'mc_selectedAnswerStyle',
      selectedAnswerStyle.name,
    );
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
    await Storage.setInt('mc_cloudResetGeneration', cloudResetGeneration);
    if (cloudRevision == null) {
      await Storage.remove('mc_cloudRevision');
    } else {
      await Storage.setInt('mc_cloudRevision', cloudRevision!);
    }
    await Storage.setString('mc_cloudRevisionId', cloudRevisionId ?? '');
    await Storage.setString(
        'mc_cloudParentRevisionId', cloudParentRevisionId ?? '');
    await Storage.setStringList(
        'mc_cloudMergeParentRevisionIds', _cloudMergeParentRevisionIds);
    await Storage.setString(
        'mc_cloudLastSyncedRevisionId', cloudLastSyncedRevisionId ?? '');
    await Storage.setBool('mc_cloudDirty', cloudDirty);
  }

  String? _cloudString(String key) {
    final value = Storage.getString(key, '');
    return value.isEmpty ? null : value;
  }

  List<String> _loadCloudMergeParentRevisionIds() {
    final parents = Storage.getStringList('mc_cloudMergeParentRevisionIds', []);
    return parents.length == 2 &&
            parents.every((parent) => parent.isNotEmpty) &&
            parents.toSet().length == 2
        ? parents
        : [];
  }

  CloudProgress exportCloudProgress() => CloudProgress(
        coins: coins,
        gamesPlayed: gamesPlayed,
        achievements: achievements,
        operationQuestStars: {
          for (final entry in operationQuestProgress.stars.entries)
            entry.key.storageId: entry.value,
        },
        highScores: highScores,
        skillMap: skillMap,
        profile: CloudProfile(
          player1: CloudPlayerProfile(
              name: p[1].name,
              selectedAvatar: p[1].avatar.storageEmoji,
              customAvatar: avatarCustom['1']!),
          player2: CloudPlayerProfile(
              name: p[2].name,
              selectedAvatar: p[2].avatar.storageEmoji,
              customAvatar: avatarCustom['2']!),
        ),
        economy: CloudEconomy(
            numberTypeUnlocks: numTypeUnlocked,
            shopOwned: shopOwned,
            unlockedAvatars: unlockedAvatars,
            unlockedHats: unlockedHats,
            powerUpBonus: _loadPowerUpBonus()
                .map((key, value) => MapEntry(key.name, value)),
            livesBonus: _loadLivesBonus()),
      );

  Future<bool> importCloudProgress(CloudProgress progress) async {
    final previous = exportCloudProgress();
    _applyCloudProgress(progress);
    try {
      await save();
      _savePowerUpBonus({
        for (final entry in progress.economy.powerUpBonus.entries)
          PowerUp.values.byName(entry.key): entry.value,
      });
      await Storage.setInt('mc_livesBonus', progress.economy.livesBonus);
      notifyListeners();
      return true;
    } catch (_) {
      _applyCloudProgress(previous);
      return false;
    }
  }

  Future<bool> importCloudProgressDocument(CloudProgressDocument document) =>
      importCloudProgress(document.progress);

  Future<bool> acceptCloudProgressDocument(
    CloudProgressDocument document, {
    required bool importProgress,
  }) async {
    final previousProgress = importProgress ? exportCloudProgress() : null;
    final previousResetGeneration = cloudResetGeneration;
    final previousRevision = cloudRevision;
    final previousRevisionId = cloudRevisionId;
    final previousParentRevisionId = cloudParentRevisionId;
    final previousMergeParentRevisionIds = _cloudMergeParentRevisionIds;
    final previousLastSyncedRevisionId = cloudLastSyncedRevisionId;
    final previousDirty = cloudDirty;
    if (importProgress) _applyCloudProgress(document.progress);
    _applyCloudSyncMetadata(document);
    try {
      await save();
      if (importProgress) {
        _savePowerUpBonus({
          for (final entry in document.progress.economy.powerUpBonus.entries)
            PowerUp.values.byName(entry.key): entry.value,
        });
        await Storage.setInt(
            'mc_livesBonus', document.progress.economy.livesBonus);
      }
      notifyListeners();
      return true;
    } catch (_) {
      if (previousProgress != null) _applyCloudProgress(previousProgress);
      cloudResetGeneration = previousResetGeneration;
      cloudRevision = previousRevision;
      cloudRevisionId = previousRevisionId;
      cloudParentRevisionId = previousParentRevisionId;
      _cloudMergeParentRevisionIds = previousMergeParentRevisionIds;
      cloudLastSyncedRevisionId = previousLastSyncedRevisionId;
      cloudDirty = previousDirty;
      return false;
    }
  }

  void _applyCloudSyncMetadata(CloudProgressDocument document) {
    cloudResetGeneration = document.resetGeneration;
    cloudRevision = document.revision;
    cloudRevisionId = document.revisionId;
    cloudParentRevisionId = document.parentRevisionId;
    _cloudMergeParentRevisionIds = List.of(document.mergeParentRevisionIds);
    cloudLastSyncedRevisionId = document.revisionId;
    cloudDirty = false;
  }

  void _applyCloudProgress(CloudProgress progress) {
    coins = progress.coins;
    gamesPlayed = progress.gamesPlayed;
    achievements = Map<String, bool>.from(progress.achievements);
    operationQuestProgress = OperationQuestProgress({
      for (final entry in progress.operationQuestStars.entries)
        OperationQuestStageId.fromStorageId(entry.key)!: entry.value,
    });
    highScores = List<HighScore>.from(progress.highScores);
    skillMap = Map<String, SkillData>.from(progress.skillMap);
    p[1].name = progress.profile.player1.name;
    p[1].avatar = AvatarData.emoji(progress.profile.player1.selectedAvatar);
    p[2].name = progress.profile.player2.name;
    p[2].avatar = AvatarData.emoji(progress.profile.player2.selectedAvatar);
    avatarCustom = {
      '1': progress.profile.player1.customAvatar,
      '2': progress.profile.player2.customAvatar,
    };
    numTypeUnlocked = Map<String, int>.from(progress.economy.numberTypeUnlocks);
    shopOwned = List<String>.from(progress.economy.shopOwned);
    unlockedAvatars = List<String>.from(progress.economy.unlockedAvatars);
    unlockedHats = List<String>.from(progress.economy.unlockedHats);
    _recomputeAdaptiveLevel();
  }

  Future<void> _markCloudDirty() async {
    cloudDirty = true;
    await Storage.setBool('mc_cloudDirty', true);
  }

  static const _cloudResetIntentKey = 'mc_cloudResetIntent';
  static const _cloudProgressStorageKeys = [
    'mc_coins',
    'mc_scores',
    'mc_gamesPlayed',
    'mc_operationQuestProgress',
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
    'mc_avatarCustom',
    'mc_avatarCustom1',
    'mc_avatarCustom2',
    'mc_p1Data',
    'mc_p1_name',
    'mc_p1_avatar',
    'mc_p2Data',
    'mc_p2_name',
    'mc_p2_avatar',
    'mc_puBonus',
    'mc_livesBonus',
    'mc_shopOwned',
    'mc_unlockedAvatars',
    'mc_unlockedHats',
  ];

  Future<bool> resetCloudProgressEverywhere() async {
    final target = cloudResetGeneration + 1;
    try {
      await Storage.setString(
        _cloudResetIntentKey,
        jsonEncode({'v': 1, 'targetResetGeneration': target}),
      );
    } catch (_) {
      return false;
    }
    _applyCloudReset(target);
    notifyListeners();
    try {
      await _persistCloudReset(target);
      await Storage.remove(_cloudResetIntentKey);
      return true;
    } catch (_) {
      cloudResetRecoveryBlocked = true;
      return false;
    }
  }

  void _applyCloudReset(int target) {
    _applyCloudProgress(CloudProgress.empty());
    cloudResetGeneration = target;
    cloudRevision = null;
    cloudRevisionId = null;
    cloudParentRevisionId = null;
    _cloudMergeParentRevisionIds = [];
    cloudLastSyncedRevisionId = null;
    cloudDirty = true;
    cloudResetRecoveryBlocked = false;
  }

  Future<void> _persistCloudReset(int target) async {
    await Storage.setInt('mc_coins', coins);
    await Storage.setInt('mc_gamesPlayed', gamesPlayed);
    await Storage.setString('mc_achievements', _encodeAchs());
    await Storage.setString(
        'mc_operationQuestProgress', operationQuestProgress.encode());
    await Storage.setObjectList('mc_scores', highScores);
    await Storage.setString('mc_skillMap', _encodeSkillMap());
    await Storage.setInt(
        'mc_numTypeUnlocked_integers', numTypeUnlocked['integers'] ?? 0);
    await Storage.setInt(
        'mc_numTypeUnlocked_rationals', numTypeUnlocked['rationals'] ?? 0);
    await Storage.setObject('mc_avatarCustom1', avatarCustom['1']!.toJson());
    await Storage.setObject('mc_avatarCustom2', avatarCustom['2']!.toJson());
    await Storage.setString('mc_p1_name', p[1].name);
    await Storage.setString('mc_p1_avatar', p[1].avatar.storageEmoji);
    await Storage.setString('mc_p2_name', p[2].name);
    await Storage.setString('mc_p2_avatar', p[2].avatar.storageEmoji);
    await Storage.setStringList('mc_shopOwned', shopOwned);
    await Storage.setStringList('mc_unlockedAvatars', unlockedAvatars);
    await Storage.setStringList('mc_unlockedHats', unlockedHats);
    await Storage.setString(
        'mc_puBonus',
        jsonEncode({
          for (final pu in PowerUp.values) _powerUpBonusStorageKeys[pu]!: 0
        }));
    await Storage.setInt('mc_livesBonus', 0);
    await Storage.setInt('mc_cloudResetGeneration', target);
    await Storage.remove('mc_cloudRevision');
    await Storage.setString('mc_cloudRevisionId', '');
    await Storage.setString('mc_cloudParentRevisionId', '');
    await Storage.setStringList('mc_cloudMergeParentRevisionIds', []);
    await Storage.setString('mc_cloudLastSyncedRevisionId', '');
    await Storage.setBool('mc_cloudDirty', true);
    for (final key in _cloudProgressStorageKeys) {
      if (!const {
        'mc_coins',
        'mc_scores',
        'mc_gamesPlayed',
        'mc_operationQuestProgress',
        'mc_achievements',
        'mc_skillMap',
        'mc_numTypeUnlocked_integers',
        'mc_numTypeUnlocked_rationals',
        'mc_avatarCustom1',
        'mc_avatarCustom2',
        'mc_p1_name',
        'mc_p1_avatar',
        'mc_p2_name',
        'mc_p2_avatar',
        'mc_puBonus',
        'mc_livesBonus',
        'mc_shopOwned',
        'mc_unlockedAvatars',
        'mc_unlockedHats',
      }.contains(key)) await Storage.remove(key);
    }
  }

  Future<bool> _recoverCloudResetIntent() async {
    final raw = Storage.getString(_cloudResetIntentKey, '');
    if (raw.isEmpty) return false;
    final durableGeneration = Storage.getInt('mc_cloudResetGeneration', 0);
    int? target;
    try {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic> &&
          value['v'] == 1 &&
          value['targetResetGeneration'] is int &&
          (value['targetResetGeneration'] == durableGeneration ||
              value['targetResetGeneration'] == durableGeneration + 1)) {
        target = value['targetResetGeneration'] as int;
      }
    } catch (_) {}
    if (target == null) {
      _applyCloudProgress(CloudProgress.empty());
      cloudResetGeneration = durableGeneration;
      cloudRevision = null;
      cloudRevisionId = null;
      cloudParentRevisionId = null;
      _cloudMergeParentRevisionIds = [];
      cloudLastSyncedRevisionId = null;
      cloudDirty = true;
      cloudResetRecoveryBlocked = true;
      return true;
    }
    _applyCloudReset(target);
    try {
      await _persistCloudReset(target);
      await Storage.remove(_cloudResetIntentKey);
      return false;
    } catch (_) {
      cloudResetRecoveryBlocked = true;
      return true;
    }
  }

  Future<void> checkPlayGamesConnection() async {
    if (!isPlayGamesEligible) {
      _setPlayGamesConnectionState(PlayGamesConnectionState.disconnected);
      return;
    }
    if (_playGamesBusy) return;
    _playGamesBusy = true;
    _setPlayGamesConnectionState(PlayGamesConnectionState.checking);
    try {
      await _initializePlayGames();
      final connected = await playGamesService.isAuthenticated();
      if (_disposed) return;
      _setPlayGamesConnectionState(
        connected
            ? PlayGamesConnectionState.connected
            : PlayGamesConnectionState.disconnected,
      );
      if (connected) await _reconcilePlayGamesAchievements();
    } catch (_) {
      if (!_disposed) {
        _setPlayGamesConnectionState(PlayGamesConnectionState.unavailable);
      }
    } finally {
      _playGamesBusy = false;
    }
  }

  Future<void> connectPlayGames() async {
    if (!isPlayGamesEligible) {
      _setPlayGamesConnectionState(PlayGamesConnectionState.disconnected);
      return;
    }
    if (_playGamesBusy ||
        playGamesConnectionState == PlayGamesConnectionState.connected) {
      return;
    }
    _playGamesBusy = true;
    _setPlayGamesConnectionState(PlayGamesConnectionState.checking);
    try {
      await _initializePlayGames();
      final connected = await playGamesService.connect();
      if (_disposed) return;
      _setPlayGamesConnectionState(
        connected
            ? PlayGamesConnectionState.connected
            : PlayGamesConnectionState.disconnected,
      );
      if (connected) await _reconcilePlayGamesAchievements();
    } catch (_) {
      if (!_disposed) {
        _setPlayGamesConnectionState(PlayGamesConnectionState.unavailable);
      }
    } finally {
      _playGamesBusy = false;
    }
  }

  void _setPlayGamesConnectionState(PlayGamesConnectionState value) {
    playGamesConnectionState = value;
    if (!_disposed) notifyListeners();
  }

  Future<void> _initializePlayGames() async {
    if (_playGamesInitialized) return;
    await playGamesService.initializePgs();
    _playGamesInitialized = true;
  }

  Future<void> _reconcilePlayGamesAchievements() async {
    try {
      await playGamesService.reconcileUnlockedAchievements(achievements);
    } catch (_) {
      // Remote sync is best effort and never mutates local progress.
    }
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
    if (cloudResetRecoveryBlocked) return bonus;
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

  int _loadLivesBonus() =>
      cloudResetRecoveryBlocked ? 0 : Storage.getInt('mc_livesBonus', 0);

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
    required int players,
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

  Future<void> _updateLoginStreak({bool notify = true}) async {
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
    if (notify) notifyListeners();
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
    if (amount != 0) unawaited(_markCloudDirty());
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
      (screen == GameScreen.practiceStyle ||
          screen == GameScreen.numType ||
          screen == GameScreen.player);

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
    _logPerformance('interstitial eligibility started');
    if (adsRemoved) {
      _pendingInterstitialAd = false;
      await _hideAdsSafely();
      _logPerformance('interstitial ineligible: ads removed');
      return;
    }
    adGameCount++;
    if (adGameCount % interstitialCadenceGames == 0) {
      _pendingInterstitialAd = true;
    }
    await Storage.setInt('mc_adGameCount', adGameCount);
    _logPerformance(
      'interstitial eligibility completed: pending=$_pendingInterstitialAd',
    );
  }

  @visibleForTesting
  Future<void> debugRecordCompletedGameForAds() => _recordCompletedGameForAds();

  @visibleForTesting
  bool get debugPendingInterstitialAd => _pendingInterstitialAd;

  Future<void> _showPendingInterstitialAd() async {
    if (!_pendingInterstitialAd) {
      _logPerformance('interstitial skipped: cadence ineligible');
      return;
    }
    _pendingInterstitialAd = false;
    if (adsRemoved || rt.gameActive || rt.state == 'playing') {
      _logPerformance('interstitial skipped: navigation unsafe');
      return;
    }
    try {
      final shown = await adService.showInterstitialIfReady();
      _logPerformance('interstitial ready decision: shown=$shown');
    } on AdMobException {
      // Ad no-fill/service errors should not interrupt result dismissal.
    }
  }

  void _logPerformance(String event) {
    if (kDebugMode) {
      debugPrint('[perf +${_diagnosticClock.elapsedMilliseconds}ms] $event');
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
    if (s == GameScreen.menu) {
      _clearPendingMentalMathEntry();
      _pendingPracticeStyle = false;
      _pendingWeakSkillsPlan = null;
      _normalizeSetupTimingStyle();
    }
    _logPerformance('screen transition: ${currentScreen.name} -> ${s.name}');
    currentScreen = s;
    unawaited(syncBannerForCurrentScreen());
    notifyListeners();
  }

  void showModal(GameModal m) {
    _logPerformance('modal transition: ${currentModal.name} -> ${m.name}');
    currentModal = m;
    unawaited(syncBannerForCurrentScreen());
    if (rt.state == 'playing' && _isPausingModal(m) && !isTimeBankRun) {
      rt.state = 'paused';
    }
    notifyListeners();
  }

  void closeModal() {
    if (currentModal == GameModal.adultGate) {
      cancelAdultGate();
      return;
    }
    if (currentModal == GameModal.weakSkillsPractice) {
      _pendingWeakSkillsPlan = null;
      _pendingQuestionMechanic = QuestionMechanic.standard;
    }
    _logPerformance('modal transition: ${currentModal.name} -> none');
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
    _clearPendingMentalMathEntry();
    _pendingPracticeStyle = false;
    final missingOperation = operationName == 'missingOperation';
    final weakSkills = operationName == 'weakSkills';
    _pendingWeakSkillsPlan = weakSkills ? selectWeakSkillsPlan(skillMap) : null;
    final op = Operation.fromString(operationName);
    _pendingQuestionMechanic = missingOperation
        ? QuestionMechanic.missingOperation
        : QuestionMechanic.standard;
    _normalizeSetupTimingStyle();
    if (op == Operation.master) {
      rt.challenge = Operation.master;
      showModal(GameModal.masterIntro);
      return;
    }
    rt.challenge = missingOperation ? Operation.mixed : op;
    if (weakSkills) {
      showModal(GameModal.weakSkillsPractice);
      return;
    }
    showScreen(GameScreen.numType);
  }

  void goToPracticeStyle(String operationName) {
    _clearPendingMentalMathEntry();
    _pendingPracticeStyle = true;
    _pendingWeakSkillsPlan = null;
    _pendingOperationQuestStageId = null;
    _pendingQuestionMechanic = operationName == 'missingOperation'
        ? QuestionMechanic.missingOperation
        : QuestionMechanic.standard;
    rt.challenge = operationName == 'missingOperation'
        ? Operation.mixed
        : Operation.fromString(operationName);
    showScreen(GameScreen.practiceStyle);
  }

  void startTimingPractice() {
    _clearPendingMentalMathEntry();
    showScreen(GameScreen.numType);
  }

  void startMentalMathFreePractice() {
    _pendingMentalMathEntry = MentalMathEntry.freePractice;
    _adaptiveBeforeMentalMath ??= adaptive;
    adaptive = false;
    players = 1;
    mode = GameMode.standard;
    diff = Difficulty.medium;
    questionCount = 40;
    selectedAnswerStyle = AnswerStyle.choice4;
    timingStyle = TimingStyle.perQuestion;
    showScreen(GameScreen.numType);
  }

  void cancelPracticeStyle() {
    _clearPendingMentalMathEntry();
    _pendingPracticeStyle = false;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    showScreen(GameScreen.menu);
  }

  void _clearPendingMentalMathEntry() {
    _pendingMentalMathEntry = null;
    final previousAdaptive = _adaptiveBeforeMentalMath;
    _adaptiveBeforeMentalMath = null;
    if (previousAdaptive != null) adaptive = previousAdaptive;
  }

  void continueWeakSkillsSetup() {
    if (currentModal != GameModal.weakSkillsPractice ||
        _pendingWeakSkillsPlan == null) {
      return;
    }
    _logPerformance(
      'modal transition: ${currentModal.name} -> ${GameModal.none.name}',
    );
    currentModal = GameModal.none;
    showScreen(GameScreen.numType);
  }

  void cancelWeakSkillsSetup() => closeModal();

  Future<void> selectNumType(String numTypeName) async {
    final nt = NumberType.fromString(numTypeName);
    if (_numberTypeUnlockPolicy.requiresPurchase(nt, numTypeUnlocked)) {
      final price = _numberTypeUnlockPolicy.priceFor(nt);
      if (!_numberTypeUnlockPolicy.canAfford(nt, coins)) {
        numTypeUnlockFeedback = nt.name;
        notifyListeners();
        return;
      }
      addCoins(-price);
      numTypeUnlocked[nt.name] = 1;
    }
    numTypeUnlockFeedback = '';
    numType = nt;
    await save();
    if (isMentalMathSetup) {
      startGame();
      return;
    }
    showScreen(GameScreen.config);
  }

  void backFromNumType() {
    if (_pendingPracticeStyle) {
      _clearPendingMentalMathEntry();
      showScreen(GameScreen.practiceStyle);
      return;
    }
    showScreen(GameScreen.menu);
  }

  void setOption(String key, dynamic value) {
    switch (key) {
      case 'players':
        if (isMentalMathSetup && value != 1) return;
        players = value as int;
        if (!GameMode.isAvailableForPlayers(mode, players)) {
          mode = GameMode.standard;
        }
        break;
      case 'mode':
        final nextMode = GameMode.fromString(value as String);
        if (isMentalMathSetup && nextMode != GameMode.standard) return;
        if (GameMode.isAvailableForPlayers(nextMode, setupPlayers)) {
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
    _normalizeSetupTimingStyle();
    notifyListeners();
  }

  void setAdaptive(bool v) {
    if (isMentalMathSetup) return;
    adaptive = v;
    _normalizeSetupTimingStyle();
    notifyListeners();
  }

  void setTimingStyle(TimingStyle style) {
    timingStyle = switch (style) {
      TimingStyle.untimed when canSelectDeepThinking => style,
      TimingStyle.timeBank when canSelectTimeBank => style,
      _ => TimingStyle.perQuestion,
    };
    notifyListeners();
  }

  void setAnswerStyle(AnswerStyle style) {
    selectedAnswerStyle = style;
    unawaited(Storage.setString('mc_selectedAnswerStyle', style.name));
    notifyListeners();
  }

  AnswerStyle get effectiveAnswerStyle => mode == GameMode.standard &&
          setupPlayers == 1 &&
          rt.challenge != Operation.master &&
          rt.challenge != Operation.dailyBoss
      ? (_pendingQuestionMechanic == QuestionMechanic.missingOperation
          ? AnswerStyle.choice4
          : selectedAnswerStyle)
      : AnswerStyle.choice4;

  void goToPlayerSetup() {
    _normalizeSetupTimingStyle();
    showScreen(GameScreen.player);
  }

  void _normalizeSetupTimingStyle() {
    timingStyle = setupTimingStyle;
  }

  void showOperationQuest() {
    _clearPendingMentalMathEntry();
    _pendingWeakSkillsPlan = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    _pendingOperationQuestStageId = null;
    showModal(GameModal.operationQuest);
  }

  void startOperationQuestStage(OperationQuestStageId id) {
    _clearPendingMentalMathEntry();
    if (!operationQuestProgress.isUnlocked(id)) return;
    _pendingWeakSkillsPlan = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    _pendingOperationQuestStageId = id;
    closeModal();
    showScreen(GameScreen.player);
  }

  void backFromPlayers() {
    if (_pendingOperationQuestStageId != null) {
      _pendingOperationQuestStageId = null;
      showScreen(GameScreen.menu);
      showModal(GameModal.operationQuest);
      return;
    }
    if (rt.challenge == Operation.master ||
        rt.challenge == Operation.dailyBoss) {
      showScreen(GameScreen.menu);
      return;
    }
    showScreen(GameScreen.config);
  }

  void startMasterMode() {
    _clearPendingMentalMathEntry();
    _pendingWeakSkillsPlan = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    closeModal();
    _turnSeq++;
    players = 1;
    mode = GameMode.standard;
    adaptive = false;
    rt.challenge = Operation.master;
    _masterLevel = 0;
    _masterLives = 3 + _loadLivesBonus();
    Storage.setInt('mc_livesBonus', 0);
    _masterProgress = 0;
    showScreen(GameScreen.player);
  }

  void showDailyBoss() {
    _clearPendingMentalMathEntry();
    _pendingWeakSkillsPlan = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    showModal(GameModal.dailyBoss);
  }

  void startDailyBoss() {
    _clearPendingMentalMathEntry();
    _pendingWeakSkillsPlan = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    closeModal();
    rt.challenge = Operation.dailyBoss;
    rt.dailyBoss = dailyBoss;
    players = 1;
    mode = GameMode.standard;
    adaptive = false;
    showScreen(GameScreen.player);
  }

  void pickAvatar(int pid, String av) {
    if (p[pid].avatar.storageEmoji != av) unawaited(_markCloudDirty());
    p[pid].avatar = av;
    notifyListeners();
  }

  // ─── Game lifecycle ─────────────────────────────────────────
  void startGame() => _startGame();

  void _startGame({
    GameRunSnapshot? replaySnapshot,
    bool skipMentalMathCountdown = false,
  }) {
    _postFeedbackTimer?.cancel();
    _delayedResultModalTimer?.cancel();

    // Safety: block corrupted normal 2P + restricted-mode setup.
    if (replaySnapshot == null &&
        _pendingOperationQuestStageId == null &&
        !GameMode.isAvailableForPlayers(mode, setupPlayers)) {
      mode = GameMode.standard;
      notifyListeners();
      return;
    }

    if (replaySnapshot == null &&
        isMentalMathSetup &&
        !_isValidMentalMathFreePracticeSetup()) {
      notifyListeners();
      return;
    }

    _closeActiveQuestionNeutrally();
    rt.timer?.cancel();
    rt.mentalMathCountdownTimer?.cancel();
    _invalidateActiveRun();
    _activeRunId = ++_lastRunId;
    _cancelDelayedLossEnd();
    _turnSeq++;
    closeModal();

    final pendingQuestId = _pendingOperationQuestStageId;
    final previousSnapshot = replaySnapshot == null ? null : _runSnapshot;
    final snapshot = _normalizeSnapshotTimingStyle(
        replaySnapshot ??
            (pendingQuestId == null
                ? GameRunSnapshot(
                    runType: GameRunType.normal,
                    mode: mode,
                    operation: rt.challenge,
                    difficulty: diff,
                    numberType: numType,
                    answerStyle: effectiveAnswerStyle,
                    players: setupPlayers,
                    questionTarget: questionCount,
                    questionMechanic: _pendingQuestionMechanic,
                    timingStyle: setupTimingStyle,
                    weakSkillsPlan: _pendingWeakSkillsPlan,
                    mentalMathEntry: _pendingMentalMathEntry,
                  )
                : _operationQuestSnapshot(pendingQuestId)),
        previousSnapshot: previousSnapshot);
    _pendingOperationQuestStageId = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    _pendingWeakSkillsPlan = null;
    _clearPendingMentalMathEntry();
    _pendingPracticeStyle = false;
    _runSnapshot = snapshot;
    _gameBrain = GameBrain();
    _lastContextEvidenceResult = null;
    _beginP1F01IntegrityWindowIfSupported(snapshot);
    final isMaster = snapshot.operation == Operation.master;
    final isBoss = snapshot.operation == Operation.dailyBoss;
    for (var i = 1; i <= 2; i++) {
      p[i].resetForGame(
        isSinglePlayer: snapshot.players == 1,
        isMasterOrBoss: isMaster || isBoss,
      );
    }
    if (snapshot.mentalMathEntry == null) {
      _applyPowerUpBonusIfEligible(
        players: snapshot.players,
        isMaster: isMaster,
        isBoss: isBoss,
      );
    }
    _clearAnswerFeedback();
    celebration = const CelebrationEvent.none();
    screenShakeTick = 0;
    mentalMathResultSummary = null;

    // Reset runtime
    rt = RuntimeState()
      ..challenge = snapshot.operation
      ..dailyBoss = isBoss ? dailyBoss : null
      ..answerStyle = snapshot.answerStyle
      ..dailyBossLives = 3
      ..gameActive = snapshot.mentalMathEntry == null || skipMentalMathCountdown
      ..state = snapshot.mentalMathEntry == null || skipMentalMathCountdown
          ? 'playing'
          : 'countdown'
      ..isWarmUp = (snapshot.mode == GameMode.standard &&
          !isMaster &&
          !isBoss &&
          snapshot.mentalMathEntry == null);
    if (snapshot.timingStyle == TimingStyle.timeBank) {
      rt.timeBankRemainingMs =
          snapshot.questionTarget * (_timeBankBaseMs[snapshot.difficulty] ?? 0);
    }

    rt.maxTurns = isMaster
        ? (currentMasterLevel?.goal ?? GameConfig.endlessTurns)
        : isBoss
            ? (rt.dailyBoss?.goal ?? dailyBoss?.goal ?? GameConfig.endlessTurns)
            : ([
                GameMode.blitz,
                GameMode.death,
                GameMode.survival,
                GameMode.combo
              ].contains(snapshot.mode)
                ? GameConfig.endlessTurns
                : snapshot.players * snapshot.questionTarget);

    if (isMaster) {
      // Master reset: 3 lives
    }

    showScreen(GameScreen.game);

    if (snapshot.mentalMathEntry != null && !skipMentalMathCountdown) {
      rt.mentalMathCountdownStep = 3;
      _startMentalMathCountdown();
      notifyListeners();
      return;
    }

    audio.playStart();

    if (snapshot.mode == GameMode.blitz) {
      rt.blitzTotalMs = GameConfig.blitzTimerDefault;
      rt.blitzElapsedMs = 0;
      _startGlobalTimer(GameConfig.blitzTimerDefault);
    } else if (snapshot.mode == GameMode.combo) {
      rt.blitzTotalMs = GameConfig.comboTimerDefault;
      rt.blitzElapsedMs = 0;
      _startGlobalTimer(GameConfig.comboTimerDefault);
    }

    _nextTurn();
  }

  void _startMentalMathCountdown() {
    if (!isMentalMathCountdown ||
        rt.mentalMathCountdownTimer?.isActive == true) {
      return;
    }
    final runId = _activeRunId;
    rt.mentalMathCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (runId != _activeRunId || !isMentalMathCountdown) {
        timer.cancel();
        return;
      }
      if (rt.mentalMathCountdownStep > 0) {
        rt.mentalMathCountdownStep--;
        notifyListeners();
        return;
      }
      timer.cancel();
      rt.mentalMathCountdownTimer = null;
      _activateMentalMathGameplay(runId);
    });
  }

  void _activateMentalMathGameplay(int runId) {
    if (runId != _activeRunId || !isMentalMathCountdown) return;
    rt
      ..mentalMathCountdownStep = -1
      ..gameActive = true
      ..state = 'playing';
    audio.playStart();
    _nextTurn();
  }

  bool _supportsUntimedSnapshot(GameRunSnapshot snapshot) =>
      !adaptive &&
      snapshot.runType == GameRunType.normal &&
      snapshot.mode == GameMode.standard &&
      snapshot.players == 1 &&
      snapshot.questionMechanic == QuestionMechanic.standard &&
      snapshot.operation != Operation.master &&
      snapshot.operation != Operation.dailyBoss &&
      snapshot.operationQuestStageId == null &&
      snapshot.weakSkillsPlan == null;

  bool _supportsTimeBankSnapshot(GameRunSnapshot snapshot) =>
      snapshot.runType == GameRunType.normal &&
      snapshot.mode == GameMode.standard &&
      snapshot.players == 1 &&
      snapshot.questionMechanic == QuestionMechanic.standard &&
      playerConfigurableDifficultySet.contains(snapshot.difficulty) &&
      snapshot.operation != Operation.master &&
      snapshot.operation != Operation.dailyBoss &&
      snapshot.operationQuestStageId == null &&
      snapshot.weakSkillsPlan == null;

  bool _isValidMentalMathFreePracticeSetup() =>
      _pendingMentalMathEntry == MentalMathEntry.freePractice &&
      mode == GameMode.standard &&
      players == 1 &&
      (_pendingQuestionMechanic == QuestionMechanic.standard ||
          _pendingQuestionMechanic == QuestionMechanic.missingOperation) &&
      timingStyle == TimingStyle.perQuestion &&
      !adaptive &&
      const {
        Operation.addition,
        Operation.subtraction,
        Operation.multiplication,
        Operation.division,
        Operation.mixed,
      }.contains(rt.challenge) &&
      diff == Difficulty.medium &&
      questionCount == 40 &&
      const {NumberType.natural, NumberType.integers, NumberType.rationals}
          .contains(numType) &&
      effectiveAnswerStyle == AnswerStyle.choice4;

  GameRunSnapshot _normalizeSnapshotTimingStyle(
    GameRunSnapshot snapshot, {
    required GameRunSnapshot? previousSnapshot,
  }) {
    if (snapshot.timingStyle == TimingStyle.perQuestion) return snapshot;
    if (snapshot.timingStyle == TimingStyle.untimed &&
        _supportsUntimedSnapshot(snapshot)) {
      return snapshot;
    }
    if (snapshot.timingStyle == TimingStyle.timeBank &&
        (!adaptive || identical(snapshot, previousSnapshot)) &&
        _supportsTimeBankSnapshot(snapshot)) {
      return snapshot;
    }
    return snapshot.withTimingStyle(TimingStyle.perQuestion);
  }

  GameRunSnapshot _operationQuestSnapshot(OperationQuestStageId id) {
    final stage = operationQuestStage(id);
    return GameRunSnapshot(
      runType: GameRunType.operationQuest,
      mode: GameMode.standard,
      operation: stage.operation,
      difficulty: stage.difficulty,
      numberType: stage.numberType,
      answerStyle: stage.answerStyle,
      players: 1,
      questionTarget: stage.questionTarget,
      operationQuestStageId: id,
      questionMechanic: stage.questionMechanic,
      operationPool: stage.operationPool == null
          ? null
          : List.unmodifiable(stage.operationPool!),
      integerQuest: stage.integerQuest,
      decimalQuest: stage.decimalQuest,
    );
  }

  void _nextTurn() {
    if (!rt.gameActive) return;
    if (activePlayers == 2 &&
        activeMode == GameMode.standard &&
        rt.totalTurns > 0) {
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
    var d = activeDifficulty;
    var generatedNumType = activeNumberType;
    var difficultyRoute = _runSnapshot?.runType == GameRunType.operationQuest
        ? QuestionDifficultyRoute.operationQuestStage
        : QuestionDifficultyRoute.playerConfigured;
    Set<Difficulty>? legalDifficulties =
        _runSnapshot?.runType == GameRunType.operationQuest
            ? {activeDifficulty}
            : playerConfigurableDifficultySet.contains(activeDifficulty)
                ? playerConfigurableDifficultySet
                : null;

    if (_isMentalMathFreePracticeRun) {
      d = _mentalMathDifficultyFor(rt.momentum);
      difficultyRoute = QuestionDifficultyRoute.playerConfigured;
      legalDifficulties = {d};
    }

    // Follow-up reinforcement
    if (rt.isFollowUp && rt.followUpData != null) {
      type = rt.followUpData!.type;
      d = rt.followUpData!.diff;
      difficultyRoute = QuestionDifficultyRoute.followUp;
      legalDifficulties = {d};
      rt.isFollowUp = false;
      rt.followUpData = null;
    }

    // Resolve via rt.challenge and level info
    String? boss;
    if (rt.challenge == Operation.master) {
      final stageIdx = _masterLevel;
      final lvl = GameConfig.masterLevels[stageIdx];
      d = Difficulty.fromString(lvl.diff);
      difficultyRoute = QuestionDifficultyRoute.masterStage;
      legalDifficulties = {d};
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
      generatedNumType = numType;
    } else if (rt.challenge == Operation.dailyBoss) {
      final lvl = rt.dailyBoss ?? dailyBoss!;
      d = Difficulty.fromString(lvl.diff);
      difficultyRoute = QuestionDifficultyRoute.dailyBoss;
      legalDifficulties = {d};
      type = Operation.fromString(lvl.type);
      boss = lvl.icon;
      numType = lvl.numType == 'mixed'
          ? [
              NumberType.natural,
              NumberType.integers,
              NumberType.rationals
            ][_rng.nextInt(3)]
          : NumberType.fromString(lvl.numType);
      generatedNumType = numType;
    }

    if (activeMode == GameMode.survival) {
      d = Difficulty.fromString(
          GameConfig.phaseKeys[rt.survivalPhase.clamp(0, 4)]);
      difficultyRoute = QuestionDifficultyRoute.survivalPhase;
      legalDifficulties = {d};
    }

    final operationPool = _runSnapshot?.operationPool;
    if (operationPool != null) {
      type = operationPool[_rng.nextInt(operationPool.length)];
    } else if (type == Operation.mixed || type == Operation.survival) {
      final weakSkillsPlan = _runSnapshot?.weakSkillsPlan;
      if (weakSkillsPlan != null) {
        type = weakSkillsPlan.operationAt(rt.weakSkillsScheduleIndex++);
      } else {
        type = [
          Operation.multiplication,
          Operation.division,
          Operation.addition,
          Operation.subtraction
        ][_rng.nextInt(4)];
      }
    }

    // Adaptive difficulty
    if (!_isMentalMathFreePracticeRun &&
        activeAdaptive &&
        rt.challenge != Operation.master &&
        rt.challenge != Operation.dailyBoss &&
        activeMode != GameMode.survival) {
      d = _getAdaptDiff(type);
      difficultyRoute = QuestionDifficultyRoute.adaptive;
      legalDifficulties = adaptiveDifficultySet;
    }

    // Build question with uniqueness guarantee
    final filtersQuestQuestions = isMissingOperation || isMissingNumberQuest;
    Question? q = filtersQuestQuestions
        ? null
        : _qgen.build(
            type: type,
            diff: d,
            numType: generatedNumType,
            integerQuest: _runSnapshot?.integerQuest ?? false,
            decimalQuest: _runSnapshot?.decimalQuest ?? false,
          );
    Question? retainedMissingOperationQuestion;
    String? retainedMissingOperationKey;
    bool foundUnique = false;
    for (var attempt = 0; attempt < 500; attempt++) {
      final candidate = _qgen.build(
        type: type,
        diff: d,
        numType: generatedNumType,
        integerQuest: _runSnapshot?.integerQuest ?? false,
        decimalQuest: _runSnapshot?.decimalQuest ?? false,
      );
      final question = switch (_runSnapshot?.questionMechanic) {
        QuestionMechanic.missingOperation =>
          missingOperationQuestion(candidate, _rng),
        QuestionMechanic.missingNumber => missingNumberQuestion(candidate, d),
        _ => candidate,
      };
      if (question == null) continue;
      if (!rt.usedFacts.contains(candidate.key)) {
        rt.usedFacts.add(candidate.key);
        q = question;
        foundUnique = true;
        break;
      }
      if (isMissingOperation && retainedMissingOperationQuestion == null) {
        retainedMissingOperationQuestion = question;
        retainedMissingOperationKey = candidate.key;
      }
    }
    if (!foundUnique) {
      if (retainedMissingOperationQuestion != null) {
        rt.usedFacts
          ..clear()
          ..add(retainedMissingOperationKey!);
        q = retainedMissingOperationQuestion;
      } else if (filtersQuestQuestions) {
        throw StateError(
          '${isMissingOperation ? 'Missing Operation' : 'Missing Number'} could not generate a unique supported question.',
        );
      } else {
        rt.usedFacts.clear();
        q = _qgen.build(
          type: type,
          diff: d,
          numType: generatedNumType,
          integerQuest: _runSnapshot?.integerQuest ?? false,
          decimalQuest: _runSnapshot?.decimalQuest ?? false,
        );
        rt.usedFacts.add(q.key);
      }
    }

    final generatedQuestion = q!;
    final runtimeQuestion = Question(
      type: generatedQuestion.type,
      key: generatedQuestion.key,
      text: generatedQuestion.text,
      ans: generatedQuestion.ans,
      choices: generatedQuestion.choices,
      boss: boss,
      diff: d,
      numType: generatedNumType,
      ratDP: generatedQuestion.ratDP,
    );

    rt.q = runtimeQuestion;
    _questionDifficultyLegality = legalDifficulties == null
        ? null
        : QuestionDifficultyLegality(
            route: difficultyRoute,
            resolvedDifficulty: runtimeQuestion.diff ?? d,
            legalDifficulties: legalDifficulties,
          );
    _activeQuestionId = ++_lastQuestionId;
    final difficultyOpportunity = _questionDifficultyMeasurements.add(
      _questionDifficultyLegality,
      _currentQuestionToken,
    );
    _admitP1F01DifficultyOpportunityIfSupported(difficultyOpportunity);
    if (rt.answerStyle == AnswerStyle.trueFalse) {
      final proposal = trueFalseProposal(runtimeQuestion);
      rt.proposedAnswer = proposal.answer;
      rt.proposedTruth = proposal.truth;
    }
    rt.selectedAnswer = null;
    rt.lastAnswerCorrect = false;
    rt.bossMood = 'normal';
    rt.qStartTs = DateTime.now().millisecondsSinceEpoch;
    _questionTerminalClaim = null;
    rt.accepting = true;

    // Start per-question timer
    if (isTimeBankRun) {
      _startTimeBankTimer();
    } else if (activeMode != GameMode.blitz &&
        activeMode != GameMode.combo &&
        !_isDeepThinkingRun) {
      rt.qTimerLimit = 0;
      _startQuestionTimer();
    }
  }

  Difficulty _getAdaptDiff(Operation type) {
    final m = skillMap[type.name]?.mastery ?? _masteryDefault;
    return _adaptiveDifficultyEngine.difficultyForMastery(m);
  }

  Difficulty _mentalMathDifficultyFor(int momentum) {
    if (momentum <= -4) return Difficulty.easy;
    if (momentum >= 4) return Difficulty.hard;
    return Difficulty.medium;
  }

  int _getTimerLimitMs() {
    if (_isMentalMathFreePracticeRun) {
      return rt.nextQuestionTimerBudgetMs;
    }
    if (activeMode == GameMode.blitz || activeMode == GameMode.combo) {
      return rt.blitzTotalMs;
    }
    if (rt.challenge == Operation.master) {
      return (currentMasterLevel?.time ?? 10) * 1000;
    }
    if (rt.challenge == Operation.dailyBoss) {
      return (rt.dailyBoss?.time ?? dailyBoss?.time ?? 9) * 1000;
    }
    if (activeMode == GameMode.survival) {
      return GameConfig.phaseTimesMs[rt.survivalPhase.clamp(0, 4)];
    }

    final timerDiff =
        activeAdaptive && rt.q?.diff != null ? rt.q!.diff! : activeDifficulty;
    final baseMs = GameConfig.timerBaseMs[timerDiff.name] ??
        GameConfig.timerBaseMs['hard']!;
    final penalty =
        activeAdaptive ? (adaptLvl ~/ GameConfig.timerPenaltyStep) * 1000 : 0;
    return max(GameConfig.timerMinMs, baseMs - penalty);
  }

  void _startQuestionTimer({
    int resumeElapsedMs = 0,
    int? remainingMs,
  }) {
    final questionToken = _currentQuestionToken;
    final isMentalMath = _isMentalMathFreePracticeRun;
    final limitMs = isMentalMath
        ? (remainingMs ?? rt.nextQuestionTimerBudgetMs)
        : (rt.qTimerLimit > 0 ? rt.qTimerLimit * 1000 : _getTimerLimitMs());
    final duration = isMentalMath ? limitMs : max(0, limitMs - resumeElapsedMs);
    rt.qTimerLimit = (limitMs / 1000).ceil();
    rt.timerDurationMs = duration;
    rt.timerStart = DateTime.now().millisecondsSinceEpoch;
    rt.timer?.cancel();
    rt.timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isQuestionOpen(questionToken)) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
      if (elapsed >= duration) {
        t.cancel();
        _onTimeout(questionToken);
      } else {
        notifyListeners();
      }
    });
  }

  void _startGlobalTimer(int totalMs) {
    final runId = _activeRunId;
    rt.timerStart = DateTime.now().millisecondsSinceEpoch;
    rt.timerDurationMs = totalMs;
    rt.qTimerLimit = totalMs ~/ 1000;
    rt.timer?.cancel();
    rt.timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (runId != _activeRunId || !rt.gameActive) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
      rt.blitzElapsedMs = elapsed;
      if (elapsed >= totalMs) {
        t.cancel();
        _closeActiveQuestionNeutrally();
        _endGame(false, false);
      } else {
        notifyListeners();
      }
    });
  }

  void _startTimeBankTimer() {
    if (!isTimeBankRun ||
        rt.timeBankRemainingMs <= 0 ||
        !_isQuestionOpen(_currentQuestionToken)) {
      return;
    }
    if (rt.timeBankTimer?.isActive == true && rt.timeBankTimerStart > 0) {
      return;
    }
    final questionToken = _currentQuestionToken;
    rt.timeBankTimer?.cancel();
    rt.timeBankTimerStart = DateTime.now().millisecondsSinceEpoch;
    rt.timeBankTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!_isQuestionOpen(questionToken)) {
        t.cancel();
        return;
      }
      if (timeBankRemainingMs <= 0) {
        t.cancel();
        rt.timeBankRemainingMs = 0;
        rt.timeBankTimerStart = 0;
        rt.timeBankTimer = null;
        _onTimeBankExhausted(questionToken);
      } else {
        notifyListeners();
      }
    });
  }

  void _pauseTimeBank() {
    if (!isTimeBankRun) return;
    rt.timeBankRemainingMs = timeBankRemainingMs;
    rt.timeBankTimerStart = 0;
    rt.timeBankTimer?.cancel();
    rt.timeBankTimer = null;
  }

  void _onTimeBankExhausted(
    ({int runId, int questionId}) questionToken,
  ) {
    if (!isTimeBankRun || rt.timeBankExhausted) return;
    rt.timeBankExhausted = true;
    _onAnswer(null, false, true, questionToken);
  }

  void handleAppLifecycleChange({required bool resumed}) {
    if (isTimeBankRun) {
      if (!resumed) {
        _pauseTimeBank();
        return;
      }
      if (rt.timeBankRemainingMs <= 0) {
        _onTimeBankExhausted(_currentQuestionToken);
      } else {
        _startTimeBankTimer();
      }
      return;
    }
    if (!_isMentalMathFreePracticeRun) return;
    if (isMentalMathCountdown) {
      if (!resumed) {
        rt.mentalMathCountdownTimer?.cancel();
        rt.mentalMathCountdownTimer = null;
      } else {
        _startMentalMathCountdown();
      }
      return;
    }
    if (!resumed) {
      _pauseMentalMathQuestionTimer();
    } else {
      _resumeMentalMathQuestionTimer();
    }
  }

  void _pauseMentalMathQuestionTimer() {
    final questionToken = _currentQuestionToken;
    if (!_isQuestionOpen(questionToken) || rt.timer?.isActive != true) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
    rt.timerElapsedAtPause = max(0, rt.timerDurationMs - elapsed);
    rt.timer?.cancel();
    rt.timer = null;
    rt.timerStart = 0;
    rt.timerDurationMs = rt.timerElapsedAtPause;
  }

  void _resumeMentalMathQuestionTimer() {
    final questionToken = _currentQuestionToken;
    if (!_isQuestionOpen(questionToken) || rt.timer?.isActive == true) return;
    final remainingMs = rt.timerElapsedAtPause;
    if (remainingMs <= 0) return;
    rt.timerElapsedAtPause = 0;
    _startQuestionTimer(remainingMs: remainingMs);
  }

  void _onTimeout(({int runId, int questionId}) questionToken) {
    if (_isDeepThinkingRun || isTimeBankRun) return;
    if (isMentalMathCountdown) return;
    _onAnswer(null, false, true, questionToken);
  }

  @visibleForTesting
  void debugTimeoutForTest() => _onTimeout(_currentQuestionToken);

  // ─── Answer handler ─────────────────────────────────────────
  void onAnswer(num val) {
    _onAnswer(val, false, false, _currentQuestionToken);
  }

  void onTrueFalseAnswer(bool response) {
    if (rt.answerStyle != AnswerStyle.trueFalse || rt.proposedTruth == null) {
      return;
    }
    final q = rt.q!;
    final answer = response == rt.proposedTruth
        ? q.ans
        : q.choices.firstWhere(
            (choice) => (choice - q.ans).abs() >= 1e-9,
          );
    onAnswer(answer);
  }

  void skip() {
    if (_isMentalMathFreePracticeRun) return;
    if (!rt.accepting) return;
    _onAnswer(null, true, false, _currentQuestionToken);
  }

  void _onAnswer(
    num? val,
    bool isSkip,
    bool isTimeout,
    ({int runId, int questionId}) questionToken,
  ) {
    if (rt.state == 'paused') return;
    if (isTimeBankRun &&
        !isTimeout &&
        _isQuestionOpen(questionToken) &&
        timeBankRemainingMs <= 0) {
      _onTimeBankExhausted(questionToken);
      return;
    }
    final terminalClaim = isTimeout
        ? _QuestionTerminalClaim.timeout
        : isSkip
            ? _QuestionTerminalClaim.skip
            : _QuestionTerminalClaim.answer;
    if (!_claimQuestionTerminal(questionToken, terminalClaim)) return;
    if (activeMode != GameMode.blitz && activeMode != GameMode.combo) {
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

    if (_isMentalMathFreePracticeRun && !isTimeout) {
      rt.mentalMathAnsweredResponseTotalMs += timeTaken;
      rt.mentalMathAnsweredResponseCount++;
    }

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

    final masteryTimeTaken = _isDeepThinkingRun || isTimeBankRun
        ? _untimedMasteryResponseMs
        : timeTaken;
    _updateSkillMap(
      q.type,
      q.diff ?? activeDifficulty,
      isCorrect,
      masteryTimeTaken,
      timedOut: isTimeout,
    );
    if (!_isMentalMathFreePracticeRun) {
      _updateAdapt(isCorrect, masteryTimeTaken, q.type);
    }

    if (isCorrect) {
      _onCorrect(pl, pid, timeTaken);
    } else {
      _onWrong(pl, pid, isSkip, isTimeout, val);
    }

    rt.totalTurns++;
    final mentalMathTerminal = _applyMentalMathOutcome(
      isCorrect: isCorrect,
      isSkip: isSkip,
    );
    final exhaustedTimeBank = isTimeout && rt.timeBankExhausted;
    if (!exhaustedTimeBank && !_isMentalMathFreePracticeRun) {
      _checkStandardTurnLimit();
    }
    final observation = _captureQuestionExperienceIfSupported(
      q,
      isCorrect
          ? const AnsweredCorrect()
          : isTimeout
              ? const QuestionTimedOut()
              : isSkip
                  ? const QuestionSkipped()
                  : const AnsweredIncorrect(),
    );
    if (observation != null) {
      final linked =
          _questionDifficultyMeasurements.link(questionToken, observation);
      _reconcileP1F01TerminalIfSupported(questionToken, linked);
    }
    _observeContextEvidence(
      q,
      (
        submittedAnswer: val,
        correct: isCorrect,
        timedOut: isTimeout,
        responseTimeMs: timeTaken,
      ),
    );
    if (mentalMathTerminal || exhaustedTimeBank) {
      _endGameAfterFeedback(false, false);
    } else if (_delayedLossTimer == null) {
      _scheduleNextTurn();
    }
  }

  bool _applyMentalMathOutcome({
    required bool isCorrect,
    required bool isSkip,
  }) {
    if (!_isMentalMathFreePracticeRun || isSkip) return false;

    if (isCorrect) {
      rt.momentum++;
      rt.currentStreak++;
    } else {
      rt.momentum--;
      rt.currentStreak = 0;
    }
    rt.completedQuestions++;
    rt.peakMomentum = max(rt.peakMomentum, rt.momentum);
    rt.bestStreak = max(rt.bestStreak, rt.currentStreak);
    rt.nextQuestionTimerBudgetMs =
        (rt.nextQuestionTimerBudgetMs + (isCorrect ? -500 : 1000))
            .clamp(6000, 12000)
            .toInt();

    if (rt.momentum >= 10) {
      rt.terminalReason = MentalMathTerminalReason.masteryReached;
    } else if (rt.momentum <= -10) {
      rt.terminalReason = MentalMathTerminalReason.practiceComplete;
    } else if (rt.completedQuestions >= 40) {
      rt.terminalReason = MentalMathTerminalReason.trainingComplete;
    }
    return rt.terminalReason != null;
  }

  void _clearMentalMathRuntimeState() {
    rt.timer?.cancel();
    rt.mentalMathCountdownTimer?.cancel();
    mentalMathResultSummary = null;
    rt
      ..timer = null
      ..timerStart = 0
      ..timerDurationMs = 0
      ..timerElapsedAtPause = 0
      ..momentum = 0
      ..peakMomentum = 0
      ..currentStreak = 0
      ..bestStreak = 0
      ..completedQuestions = 0
      ..mentalMathAnsweredResponseTotalMs = 0
      ..mentalMathAnsweredResponseCount = 0
      ..nextQuestionTimerBudgetMs = 10000
      ..terminalReason = null
      ..mentalMathCountdownTimer = null
      ..mentalMathCountdownStep = -1;
  }

  void _observeContextEvidence(
    Question question,
    ({
      num? submittedAnswer,
      bool correct,
      bool timedOut,
      int responseTimeMs,
    }) outcome,
  ) {
    final snapshot = _runSnapshot!;
    if (snapshot.mentalMathEntry != null) return;
    final advisory = _gameBrain!.observeContextEvidence(
      ContextEvidenceObservation(
        context: _contextEvidenceKey(snapshot, question),
        difficulty: question.diff ?? snapshot.difficulty,
        correctAnswer: question.ans,
        submittedAnswer: outcome.submittedAnswer,
        correct: outcome.correct,
        timedOut: outcome.timedOut,
        responseTimeMs: outcome.responseTimeMs,
      ),
    );
    _lastContextEvidenceResult = advisory;
    _adaptiveShadowEvaluator(advisory, const AdaptiveAuthority.shadow());
  }

  QuestionExperienceObservation? _captureQuestionExperienceIfSupported(
    Question question,
    QuestionTerminalObservation terminal,
  ) {
    final snapshot = _runSnapshot;
    final numberType = question.numType;
    final difficulty = question.diff;
    final supported = effectiveGameBrainEnabled &&
        snapshot != null &&
        snapshot.runType == GameRunType.normal &&
        snapshot.players == 1 &&
        snapshot.mode == GameMode.standard &&
        snapshot.questionMechanic == QuestionMechanic.standard &&
        snapshot.timingStyle == TimingStyle.perQuestion &&
        snapshot.weakSkillsPlan == null &&
        snapshot.mentalMathEntry == null &&
        snapshot.answerStyle == AnswerStyle.choice4 &&
        _supportsContextRunOperation(snapshot.operation) &&
        ContextEvidenceKey.supportsOperation(question.type) &&
        numberType != null &&
        difficulty != null;
    if (!supported) return null;

    try {
      final observation = QuestionExperienceObservation(
        presented: QuestionPresentedSnapshot(
          operation: question.type,
          numberType: numberType,
          difficulty: difficulty,
          answerStyle: snapshot.answerStyle,
        ),
        terminal: terminal,
      );
      _questionExperience.add(observation);
      return observation;
    } catch (_) {
      // Observation failures must not affect canonical gameplay.
      return null;
    }
  }

  ContextEvidenceKey? _contextEvidenceKey(
    GameRunSnapshot snapshot,
    Question question,
  ) {
    final supported = snapshot.runType == GameRunType.normal &&
        snapshot.questionMechanic == QuestionMechanic.standard &&
        snapshot.timingStyle == TimingStyle.perQuestion &&
        snapshot.mentalMathEntry == null &&
        snapshot.answerStyle == AnswerStyle.choice4 &&
        _supportsContextRunOperation(snapshot.operation) &&
        ContextEvidenceKey.supportsOperation(question.type);
    if (!supported) return null;
    return ContextEvidenceKey(
      operation: question.type,
      numberType: snapshot.numberType,
    );
  }

  bool _supportsContextRunOperation(Operation operation) =>
      ContextEvidenceKey.supportsOperation(operation) ||
      operation == Operation.mixed;

  bool _supportsP1F01IntegrityRun(GameRunSnapshot snapshot) =>
      effectiveGameBrainEnabled &&
      snapshot.runType == GameRunType.normal &&
      snapshot.players == 1 &&
      snapshot.mode == GameMode.standard &&
      snapshot.questionMechanic == QuestionMechanic.standard &&
      snapshot.timingStyle == TimingStyle.perQuestion &&
      snapshot.weakSkillsPlan == null &&
      snapshot.mentalMathEntry == null &&
      snapshot.answerStyle == AnswerStyle.choice4 &&
      !activeAdaptive &&
      playerConfigurableDifficultySet.contains(snapshot.difficulty) &&
      _supportsContextRunOperation(snapshot.operation);

  void _beginP1F01IntegrityWindowIfSupported(GameRunSnapshot snapshot) {
    _p1F01IntegrityRunEligible = _supportsP1F01IntegrityRun(snapshot);
    _p1F01IntegrityMeasurementFailed = !_p1F01IntegrityRunEligible;
    if (!_p1F01IntegrityRunEligible) return;
    unawaited(_p1F01IntegrityStore.admitWindow().then((window) {
      if (window == null) _p1F01IntegrityMeasurementFailed = true;
    }));
  }

  void _admitP1F01DifficultyOpportunityIfSupported(
    QuestionDifficultyMeasurementOpportunity opportunity,
  ) {
    if (!_p1F01IntegrityRunEligible ||
        _p1F01IntegrityMeasurementFailed ||
        opportunity.legality?.route !=
            QuestionDifficultyRoute.playerConfigured) {
      return;
    }
    final legalSetCode = P1F01LegalSetCode.fromLegality(opportunity.legality);
    unawaited(_p1F01IntegrityStore
        .admitOpportunity(
      opportunityOrdinalWithinRun: opportunity.opportunityOrdinalWithinRun,
      legalSetCode: legalSetCode,
    )
        .then((result) {
      if (result == P1F01OpportunityAdmissionResult.failedClosed) {
        _p1F01IntegrityMeasurementFailed = true;
      }
    }));
  }

  void _reconcileP1F01TerminalIfSupported(
    ({int runId, int questionId}) questionToken,
    bool terminalLinkAccepted,
  ) {
    if (!_p1F01IntegrityRunEligible || _p1F01IntegrityMeasurementFailed) {
      return;
    }
    final opportunity = _questionDifficultyMeasurements.opportunityFor(
      questionToken,
    );
    if (opportunity == null) {
      _p1F01IntegrityMeasurementFailed = true;
      unawaited(_p1F01IntegrityStore.markLeftUnclean());
      return;
    }
    unawaited(_p1F01IntegrityStore
        .reconcileTerminal(
      opportunityOrdinalWithinRun: opportunity.opportunityOrdinalWithinRun,
      terminalLinkAccepted: terminalLinkAccepted,
    )
        .then((clean) {
      if (!clean) _p1F01IntegrityMeasurementFailed = true;
    }));
  }

  void _closeP1F01IntegrityCleanly() {
    if (!_p1F01IntegrityRunEligible) return;
    final failed = _p1F01IntegrityMeasurementFailed;
    _p1F01IntegrityRunEligible = false;
    _p1F01IntegrityMeasurementFailed = false;
    unawaited(
      failed
          ? _p1F01IntegrityStore.markLeftUnclean()
          : _p1F01IntegrityStore.closeCleanIfConsistent(),
    );
  }

  void _leaveP1F01IntegrityUnclean() {
    if (!_p1F01IntegrityRunEligible) return;
    _p1F01IntegrityRunEligible = false;
    _p1F01IntegrityMeasurementFailed = false;
    unawaited(_p1F01IntegrityStore.markLeftUnclean());
  }

  void _freezeQuestionTimer() {
    if (rt.timerDurationMs <= 0 || rt.timerStart <= 0) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
    rt.timerDurationMs =
        (rt.timerDurationMs - elapsed).clamp(0, rt.timerDurationMs).toInt();
    rt.timerStart = 0;
  }

  ({int runId, int questionId}) get _currentQuestionToken => (
        runId: _activeRunId,
        questionId: _activeQuestionId,
      );

  bool _isCurrentQuestion(({int runId, int questionId}) questionToken) =>
      questionToken.runId > 0 &&
      questionToken.runId == _activeRunId &&
      questionToken.questionId > 0 &&
      questionToken.questionId == _activeQuestionId;

  bool _isQuestionOpen(({int runId, int questionId}) questionToken) =>
      _isCurrentQuestion(questionToken) &&
      _questionTerminalClaim == null &&
      rt.accepting;

  bool _claimQuestionTerminal(
    ({int runId, int questionId}) questionToken,
    _QuestionTerminalClaim terminalClaim,
  ) {
    if (!_isQuestionOpen(questionToken)) return false;
    _questionTerminalClaim = terminalClaim;
    rt.accepting = false;
    _pauseTimeBank();
    return true;
  }

  void _closeActiveQuestionNeutrally() {
    _claimQuestionTerminal(
      _currentQuestionToken,
      _QuestionTerminalClaim.neutral,
    );
  }

  void _invalidateActiveRun() {
    _leaveP1F01IntegrityUnclean();
    _activeRunId = 0;
    _activeQuestionId = 0;
    rt.accepting = false;
    rt.timeBankTimer?.cancel();
    rt.timeBankTimer = null;
    rt.timeBankTimerStart = 0;
    _questionExperience.clear();
    _questionDifficultyMeasurements.clear();
    _questionDifficultyLegality = null;
  }

  void _onCorrect(PlayerState pl, int pid, int timeTaken) {
    pl.correct++;
    pl.streak++;
    pl.maxStreak = max(pl.maxStreak, pl.streak);
    if (timeTaken < pl.fastest) pl.fastest = timeTaken;
    if (!_isDeepThinkingRun && !isTimeBankRun && timeTaken < 2000) {
      rt.fastAnswers++;
    }

    if (_isMentalMathFreePracticeRun) {
      reactionPill = GameConfig.correctRx[_rng.nextInt(GameConfig.correctRx.length)];
      bigEmoji = reactionPill.split(' ').first;
      bigEmojiVisible = true;
      audio.playCorrect();
      audio.vibrateCorrect();
      notifyListeners();
      return;
    }

    var survivalBossDue = false;

    // Survival: phase + coin per correct
    if (activeMode == GameMode.survival) {
      rt.survivalCorrect++;
      final progression =
          _survivalProgressionPolicy.afterCorrect(rt.survivalCorrect);
      survivalBossDue = progression.bossDue;
      addCoins(1, true);
      if (survivalBossDue) {
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
      final newPhase = progression.phase;
      if (newPhase > rt.survivalPhase) {
        rt.survivalPhase = newPhase;
        audio.vibratePattern([60, 30, 60]);
        _shakeScreen(vibrate: false);
      }
    }

    // Combo mode
    if (activeMode == GameMode.combo) {
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
    final eligibleForPU = activePlayers == 1 &&
        rt.challenge != Operation.master &&
        rt.challenge != Operation.dailyBoss &&
        ![GameMode.combo, GameMode.survival].contains(activeMode);
    if (eligibleForPU && pl.correct == 1) {
      pl.pups.addAll(_availablePowerUpsForActiveRun);
      showToast('🎁 Got one of each power-up!');
    } else if (eligibleForPU &&
        pl.correct > 1 &&
        pl.correct % GameConfig.puRewardInterval == 0) {
      final powerUps = _availablePowerUpsForActiveRun.toList(growable: false);
      final pu = powerUps[_rng.nextInt(powerUps.length)];
      pl.pups.add(pu);
      showToast('🎁 Got: ${pu.label}!');
    }

    // Scoring
    int pts = rt.answerStyle.baseScore(classicBase: GameConfig.scoreBase);
    int bonus = 0;
    final isBlitz = activeMode == GameMode.blitz;
    final isMaster = rt.challenge == Operation.master;
    final isBoss = rt.challenge == Operation.dailyBoss;

    if (_isDeepThinkingRun || isTimeBankRun) {
      bonus = 0;
    } else if (!isBlitz && !isMaster && activeMode != GameMode.combo) {
      final remaining = max(0, (rt.qTimerLimit * 1000 - timeTaken) / 1000);
      bonus = remaining.ceil();
      if (timeTaken < 2000) {
        bonus += 2;
      } else if (timeTaken < 4000) bonus += 1;
    } else if (activeMode == GameMode.combo) {
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
    } else if (activeMode == GameMode.survival) {
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

    final bossDown = activeMode == GameMode.survival && survivalBossDue;
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
    if (activeMode == GameMode.blitz) _updateDailyProgress('blitz_15');
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
        if (_masterLevel == GameConfig.masterLevels.length - 1) {
          // Beat the game!
          unlockAch('math_legend');
          _endGameAfterFeedback(true, false);
        } else {
          if (_masterLevel + 1 >= 3) unlockAch('math_wizard');
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

  String _correctAnswerText() {
    final question = rt.q;
    if (question == null) return '';
    return isMissingOperation
        ? operatorSymbol(question.ans)
        : '${question.ans}';
  }

  void _onWrong(
      PlayerState pl, int pid, bool isSkip, bool isTimeout, num? val) {
    rt.combo = 0;
    rt.comboMultiplier = 1.0;

    if (activeMode == GameMode.combo) {
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

    if (activeMode == GameMode.death && !isSkip) {
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

    if (activeMode == GameMode.survival && !isSkip) {
      rt.survivalLives--;
      bigEmoji = '💔';
      reactionPill = '💔 Ans: ${_correctAnswerText()}';
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
      reactionPill = '💔 Boss hit! Ans: ${_correctAnswerText()}';
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
      reactionPill = '$wrongLabel 💔 Ans: ${_correctAnswerText()}';
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
        reactionPill = 'Skipped! Ans: ${_correctAnswerText()}';
      } else {
        bigEmoji = isTimeout ? '⏰' : wrongLabel.split(' ').first;
        reactionPill = '$wrongLabel Ans: ${_correctAnswerText()}';
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
      if (!_isMentalMathFreePracticeRun &&
          !isSkip &&
          !isTimeout &&
          activeMode == GameMode.standard &&
          rt.challenge != Operation.dailyBoss) {
        rt.isFollowUp = true;
        rt.followUpData =
            _FollowUpData(rt.q!.type, rt.q!.diff ?? activeDifficulty);
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
    _logPerformance('end game entered');
    _cancelDelayedLossEnd();
    if (!rt.gameActive || rt.state == 'ended') return;
    _closeActiveQuestionNeutrally();
    _closeP1F01IntegrityCleanly();
    _invalidateActiveRun();
    unawaited(_markCloudDirty());
    rt.gameActive = false;
    rt.state = 'ended';
    rt.timer?.cancel();
    final snapshot = _runSnapshot!;
    gamesPlayed++;
    unawaited(_recordCompletedGameForAds());
    _logPerformance('completed-game persistence scheduled');
    if (snapshot.mentalMathEntry == null && gamesPlayed >= 10) {
      unlockAch('persistent');
    }
    final questProgressSave = isOperationQuest
        ? _recordOperationQuestResult(snapshot.operationQuestStageId!)
        : null;

    // Save high score
    if (!isOperationQuest &&
        snapshot.mentalMathEntry == null &&
        snapshot.timingStyle == TimingStyle.perQuestion &&
        p[1].score > 0) {
      highScores.add(HighScore(
        name: p[1].name,
        score: p[1].score,
        mode: snapshot.mode,
        difficulty: rt.challenge == Operation.master ||
                rt.challenge == Operation.dailyBoss
            ? null
            : snapshot.difficulty,
        answerStyle: snapshot.answerStyle,
        date: DateTime.now().toIso8601String().substring(0, 10),
      ));
      highScores.sort((a, b) => b.score.compareTo(a.score));
      if (highScores.length > 10) highScores = highScores.sublist(0, 10);
    }

    final perfect = p[1].total > 0 && p[1].correct == p[1].total;
    if (snapshot.mentalMathEntry == null) {
      if (win && p[1].correct > 0) unlockAch('first_win');
      if (perfect) unlockAch('perfect_score');
      if (p[1].maxStreak >= 10) unlockAch('streak_master');
      if (snapshot.timingStyle == TimingStyle.perQuestion &&
          rt.fastAnswers >= 5) {
        unlockAch('speed_demon');
      }
      if (activeMode == GameMode.death && p[1].score >= 250) {
        unlockAch('survivor');
      }
      for (final e in skillMap.entries) {
        if (e.value.count >= 5 && e.value.mastery >= 90) {
          unlockAch('skill_master');
          break;
        }
      }
      if (adaptLvl >= 8) unlockAch('quick_learner');
    }

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

    _logPerformance('game save scheduled');
    unawaited(
      save().whenComplete(() => _logPerformance('game save completed')),
    );
    if (isBossWin) {
      _delayedResultModalTimer?.cancel();
      _delayedResultModalTimer = Timer(const Duration(milliseconds: 1250), () {
        if (rt.state == 'ended' && currentModal == GameModal.none) {
          showModal(GameModal.win);
        }
      });
    } else if (questProgressSave != null) {
      final seq = _turnSeq;
      unawaited(questProgressSave.whenComplete(() {
        _logPerformance('operation quest progress persistence completed');
        if (seq == _turnSeq &&
            rt.state == 'ended' &&
            currentModal == GameModal.none) {
          showModal(GameModal.win);
        }
      }));
    } else {
      showModal(GameModal.win);
    }
  }

  Future<void> _recordOperationQuestResult(OperationQuestStageId id) {
    operationQuestResultStars =
        operationQuestStarsForCorrectAnswers(p[1].correct);
    final updated = operationQuestProgress.recordBest(
      id,
      operationQuestResultStars,
    );
    if (identical(updated, operationQuestProgress)) return Future.value();
    operationQuestProgress = updated;
    unawaited(_markCloudDirty());
    return Storage.setString(
      'mc_operationQuestProgress',
      operationQuestProgress.encode(),
    );
  }

  void _prepareResultSummary({required bool win, required bool loss}) {
    final p1 = p[1];
    final p2 = p[2];

    if (_isMentalMathFreePracticeRun && rt.terminalReason != null) {
      final title = switch (rt.terminalReason!) {
        MentalMathTerminalReason.masteryReached => 'MASTERY REACHED',
        MentalMathTerminalReason.practiceComplete => 'PRACTICE COMPLETE',
        MentalMathTerminalReason.trainingComplete => 'TRAINING COMPLETE',
      };
      final message = switch (rt.terminalReason!) {
        MentalMathTerminalReason.masteryReached =>
          'Strong run. You reached full momentum.',
        MentalMathTerminalReason.practiceComplete =>
          'Practice complete. Your session still built useful fluency.',
        MentalMathTerminalReason.trainingComplete =>
          'Training complete. You reached the session limit.',
      };
      final completed = rt.completedQuestions;
      mentalMathResultSummary = MentalMathResultSummary(
        avatarEmoji: p1.avatar.storageEmoji,
        terminalTitle: title,
        message: message,
        peakMomentum: rt.peakMomentum,
        bestStreak: rt.bestStreak,
        accuracyPercent:
            completed == 0 ? 0 : ((p1.correct / completed) * 100).round(),
        averageResponseMs: rt.mentalMathAnsweredResponseCount == 0
            ? null
            : (rt.mentalMathAnsweredResponseTotalMs /
                    rt.mentalMathAnsweredResponseCount)
                .round(),
        fastestAnswerMs:
            p1.fastest == PlayerState.noFastestTime ? null : p1.fastest,
      );
      resultIcon = p1.avatar.storageEmoji;
      resultTitle = title;
      resultDescription = message;
      return;
    }

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

    if (isOperationQuest) {
      final stage = operationQuestStage(
        _runSnapshot!.operationQuestStageId!,
      );
      if (stage.integerQuest) {
        resultIcon = '🔢';
        resultTitle = stage.difficulty == Difficulty.hard &&
                operationQuestResultStars >= 1
            ? 'Integer Quest Complete'
            : '${stage.title} Complete';
        final stars = List.filled(operationQuestResultStars, '⭐').join();
        final emptyStars =
            List.filled(3 - operationQuestResultStars, '☆').join();
        resultDescription =
            '${p1.correct}/${stage.questionTarget} correct • $stars$emptyStars';
        return;
      }
      if (stage.decimalQuest) {
        resultIcon = '💧';
        resultTitle = stage.difficulty == Difficulty.hard &&
                operationQuestResultStars >= 1
            ? 'Decimal Quest Complete'
            : '${stage.title} Complete';
        final stars = List.filled(operationQuestResultStars, '⭐').join();
        final emptyStars =
            List.filled(3 - operationQuestResultStars, '☆').join();
        resultDescription =
            '${p1.correct}/${stage.questionTarget} correct • $stars$emptyStars';
        return;
      }
      resultIcon = operationQuestResultStars == 0
          ? switch (stage.answerStyle) {
              AnswerStyle.trueFalse => '✅',
              _ => switch (stage.questionMechanic) {
                  QuestionMechanic.missingOperation => '❔',
                  QuestionMechanic.missingNumber => '🔢',
                  _ => switch (stage.operation) {
                      Operation.addition => '➕',
                      Operation.subtraction => '➖',
                      Operation.multiplication => '✖️',
                      Operation.division => '➗',
                      Operation.mixed => '🧮',
                      _ => '⭐',
                    },
                },
            }
          : '⭐';
      final trailName = switch (stage.operation) {
        Operation.multiplication => 'Multiplication',
        Operation.mixed
            when stage.questionMechanic == QuestionMechanic.missingOperation =>
          'Missing Operation',
        Operation.mixed
            when stage.questionMechanic == QuestionMechanic.missingNumber =>
          'Missing Number',
        Operation.mixed when stage.answerStyle == AnswerStyle.trueFalse =>
          'True / False Quest',
        Operation.mixed => 'Mixed Operations',
        _ => stage.operation.label,
      };
      resultTitle =
          stage.difficulty == Difficulty.hard && operationQuestResultStars >= 1
              ? stage.answerStyle == AnswerStyle.trueFalse
                  ? '$trailName Complete'
                  : '$trailName Trail Complete'
              : '${stage.title} Complete';
      final stars = List.filled(operationQuestResultStars, '⭐').join();
      final emptyStars = List.filled(3 - operationQuestResultStars, '☆').join();
      resultDescription =
          '${p1.correct}/${stage.questionTarget} correct • $stars$emptyStars';
      return;
    }

    if (activePlayers == 2 && activeMode == GameMode.standard) {
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

    resultIcon = activeMode == GameMode.blitz || activeMode == GameMode.combo
        ? '⏱️'
        : '🌟';
    resultTitle = activeMode == GameMode.blitz || activeMode == GameMode.combo
        ? "Time's Up!"
        : 'Player Report';
    resultDescription = isTimeBankRun
        ? 'Time remaining: ${(timeBankRemainingMs / 1000).ceil()}s'
        : 'Final Score: ${p1.score}';
  }

  void advanceStage() {
    closeModal();
    _clearAnswerFeedback();
    rt.state = 'playing';
    if (_masterLevel < GameConfig.masterLevels.length - 1) _masterLevel++;
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
    _logPerformance('replay navigation entered');
    final snapshot = _runSnapshot;
    final dismissedResult = currentModal == GameModal.win;
    _closeActiveQuestionNeutrally();
    rt.timer?.cancel();
    _invalidateActiveRun();
    closeModal();
    if (dismissedResult) await _showPendingInterstitialAd();
    if (rt.challenge == Operation.master) {
      _masterLevel = 0;
      _masterProgress = 0;
      _masterLives = 3 + _loadLivesBonus();
      Storage.setInt('mc_livesBonus', 0);
    }
    if (snapshot?.runType == GameRunType.normal) {
      mode = snapshot!.mode;
      diff = snapshot.difficulty;
    }
    _startGame(replaySnapshot: snapshot);
    _logPerformance('replay started');
  }

  Future<void> quitToMenu() async {
    _logPerformance('main menu navigation entered');
    _closeActiveQuestionNeutrally();
    _invalidateActiveRun();
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
    final wasMentalMathRun = _isMentalMathFreePracticeRun;
    _runSnapshot = null;
    if (wasMentalMathRun) _clearMentalMathRuntimeState();
    _gameBrain = null;
    _lastContextEvidenceResult = null;
    _pendingOperationQuestStageId = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    _pendingWeakSkillsPlan = null;
    showScreen(GameScreen.menu);
    _logPerformance('main menu navigation completed');
  }

  Future<void> returnToOperationQuestMap() async {
    _logPerformance('operation quest map navigation entered');
    _closeActiveQuestionNeutrally();
    _invalidateActiveRun();
    _cancelDelayedLossEnd();
    _turnSeq++;
    final dismissedResult = currentModal == GameModal.win;
    closeModal();
    if (dismissedResult) await _showPendingInterstitialAd();
    rt.gameActive = false;
    rt.state = 'idle';
    rt.timer?.cancel();
    _runSnapshot = null;
    _gameBrain = null;
    _lastContextEvidenceResult = null;
    _pendingOperationQuestStageId = null;
    _pendingQuestionMechanic = QuestionMechanic.standard;
    _pendingWeakSkillsPlan = null;
    showScreen(GameScreen.menu);
    showModal(GameModal.operationQuest);
    _logPerformance('operation quest map navigation completed');
  }

  void showQuitConfirm() {
    showModal(GameModal.quitConfirm);
  }

  // ─── Adaptive + skill tracking ──────────────────────────────
  void _updateAdapt(bool correct, int timeMs, Operation type) {
    final sd = skillMap[type.name];
    if (sd == null) return;

    final prevMastery = sd.mastery == 0 ? _masteryDefault : sd.mastery;
    final nudge = _adaptiveDifficultyEngine.adaptiveNudgeFor(
      correct: correct,
      responseMilliseconds: timeMs,
    );
    if (correct) {
      sd.mastery = min(_masteryMax, prevMastery + nudge);
    } else {
      sd.mastery = max(0, prevMastery + nudge);
    }
    _recomputeAdaptiveLevel();
  }

  void _updateSkillMap(
    Operation type,
    Difficulty d,
    bool correct,
    int timeMs, {
    bool timedOut = false,
  }) {
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
    _updateMastery(sd, correct, timeMs, timedOut: timedOut);
    skillMap[type.name] = sd;
    unawaited(_markCloudDirty());
  }

  void _updateMastery(
    SkillData sd,
    bool correct,
    int timeMs, {
    required bool timedOut,
  }) {
    final timeoutLimitMs = rt.qTimerLimit > 0 ? rt.qTimerLimit * 1000 : 10000;
    final canTimeout = timedOut ||
        (!_isDeepThinkingRun &&
            !isTimeBankRun &&
            (timeMs == 0 || timeMs >= timeoutLimitMs));
    final outcome = correct
        ? MasteryOutcome.correct
        : canTimeout
            ? MasteryOutcome.timeout
            : MasteryOutcome.wrong;
    final update = _adaptiveDifficultyEngine.calculateMasteryUpdate(
      currentMastery: sd.mastery,
      currentConfidence: sd.confidence,
      outcome: outcome,
      responseMilliseconds: timeMs,
    );
    sd.mastery = update.mastery;
    sd.confidence = update.confidence;
    _recomputeAdaptiveLevel();
  }

  void _recomputeAdaptiveLevel() {
    final level = _adaptiveDifficultyEngine.levelFromMasteries(
      skillMap.values.map((skill) => skill.mastery),
    );
    adaptLvlRaw = level.raw;
    adaptLvl = level.level;
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
    unawaited(_markCloudDirty());
    final a = GameConfig.achievementsDef.firstWhere((e) => e.id == id);
    newlyUnlocked.add(a);
    _celebrate(
      CelebrationKind.achievement,
      emoji: a.icon,
      message: '${a.name} unlocked!',
    );
    showToast('${a.icon} ${a.name} unlocked!');
    if (isPlayGamesEligible &&
        _playGamesInitialized &&
        playGamesConnectionState == PlayGamesConnectionState.connected) {
      unawaited(_mirrorPlayGamesAchievement(id));
    }
  }

  Future<void> _mirrorPlayGamesAchievement(String id) async {
    try {
      await playGamesService.unlockAchievement(id);
    } catch (_) {
      // Local achievement state and feedback remain canonical.
    }
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
        final questionToken = _currentQuestionToken;
        rt.timer?.cancel();
        rt.timerDurationMs += 5000;
        if (rt.qTimerLimit > 0) rt.qTimerLimit += 5;
        rt.timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          if (!_isQuestionOpen(questionToken)) {
            t.cancel();
            return;
          }
          final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
          if (elapsed >= rt.timerDurationMs) {
            t.cancel();
            _onTimeout(questionToken);
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
        final questionToken = _currentQuestionToken;
        if (!_claimQuestionTerminal(
          questionToken,
          _QuestionTerminalClaim.switchReplacement,
        )) {
          break;
        }
        // P1-F00 v1.2: a requested replacement is outside the confirmatory
        // envelope. Establish the synchronous local admission firewall
        // BEFORE the replacement question can open; durable LEFT_UNCLEAN
        // bookkeeping is queued asynchronously and never awaited here.
        // Gameplay (the replacement itself) proceeds unchanged.
        _leaveP1F01IntegrityUnclean();
        final question = rt.q;
        if (question != null) {
          final observation = _captureQuestionExperienceIfSupported(
            question,
            const QuestionReplaced(),
          );
          if (observation != null) {
            final linked = _questionDifficultyMeasurements.link(
                questionToken, observation);
            _reconcileP1F01TerminalIfSupported(questionToken, linked);
          }
        }
        if (activeMode != GameMode.blitz && activeMode != GameMode.combo) {
          rt.timer?.cancel();
        }
        Timer(const Duration(milliseconds: 500), () {
          if (!_isCurrentQuestion(questionToken) ||
              _questionTerminalClaim !=
                  _QuestionTerminalClaim.switchReplacement ||
              !rt.gameActive ||
              rt.state != 'playing' ||
              rt.accepting) {
            return;
          }
          _generateQ();
          notifyListeners();
        });
        break;
    }
    audio.playPowerUp();
    notifyListeners();
  }

  bool _isPowerUpBlocked(PowerUp pu) {
    if (_isMentalMathFreePracticeRun) return true;
    if (pu == PowerUp.fifty && rt.answerStyle == AnswerStyle.trueFalse) {
      return true;
    }
    if (pu == PowerUp.time || pu == PowerUp.freeze) {
      if (_isDeepThinkingRun || isTimeBankRun) {
        return true;
      }
      if (activeMode == GameMode.blitz || activeMode == GameMode.combo) {
        return true;
      }
    }
    if (pu == PowerUp.freeze &&
        (activeMode == GameMode.survival || rt.frozen)) {
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
    unawaited(_markCloudDirty());
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
    await _markCloudDirty();
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
      Storage.setInt('mc_livesBonus', _loadLivesBonus() + 1);
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
    if (familyEligibility == FamilyEligibility.unresolved) {
      showToast('Complete the age check before making a purchase.');
      return;
    }
    if (familyEligibility == FamilyEligibility.eligible) {
      if (_directIapStartBusy) return;
      unawaited(_beginDirectIapPurchase(product));
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

  Future<void> _beginDirectIapPurchase(IapProduct product) async {
    _directIapStartBusy = true;
    try {
      await iapAdapter.buyProduct(product);
      showToast('Opening Google Play...');
    } on IapException catch (e) {
      await _handleIapError(e, product: product);
    } catch (_) {
      showToast('Purchase could not start');
    } finally {
      _directIapStartBusy = false;
    }
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

  Future<bool> restorePurchases(
      {bool silent = false, bool notify = true}) async {
    try {
      final purchases = await iapAdapter.restorePurchases();
      final restored = await _applyRestoredPurchases(purchases, notify: notify);
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

  Future<bool> _applyRestoredPurchases(
    List<IapPurchase> purchases, {
    required bool notify,
  }) async {
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
      if (!cloudResetRecoveryBlocked) await save();
      if (notify) notifyListeners();
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
    final nextCloudResetGeneration = cloudResetGeneration + 1;
    _closeActiveQuestionNeutrally();
    _invalidateActiveRun();
    rt.timer?.cancel();
    _cancelDelayedLossEnd();
    _turnSeq++;
    for (final key in _resetStorageKeys) {
      await Storage.remove(key);
    }
    await _p1F01IntegrityStore.deleteAll();
    _resetInMemoryData();
    cloudResetGeneration = nextCloudResetGeneration;
    cloudRevision = null;
    cloudRevisionId = null;
    cloudParentRevisionId = null;
    _cloudMergeParentRevisionIds = [];
    cloudLastSyncedRevisionId = null;
    cloudDirty = true;
    await Storage.setInt('mc_cloudResetGeneration', cloudResetGeneration);
    await Storage.remove('mc_cloudRevision');
    await Storage.setString('mc_cloudRevisionId', '');
    await Storage.setString('mc_cloudParentRevisionId', '');
    await Storage.setStringList('mc_cloudMergeParentRevisionIds', []);
    await Storage.setString('mc_cloudLastSyncedRevisionId', '');
    await _markCloudDirty();
    showToast('All data reset');
  }

  void _resetInMemoryData() {
    _coinLedger.reset();
    _dailyBonusPolicy.reset();
    gameBrainPreference = false;
    gamesPlayed = 0;
    selectedAnswerStyle = AnswerStyle.choice4;
    operationQuestProgress = OperationQuestProgress();
    operationQuestResultStars = 0;
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
    _runSnapshot = null;
    _gameBrain = null;
    _lastContextEvidenceResult = null;
    _pendingOperationQuestStageId = null;
    _pendingWeakSkillsPlan = null;
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
    if (p[pid].name != name) unawaited(_markCloudDirty());
    p[pid].name = name;
    notifyListeners();
  }
}
