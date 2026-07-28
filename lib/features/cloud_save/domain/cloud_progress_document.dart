import 'dart:convert';

import '../../../features/adaptive/domain/adaptive_difficulty_engine.dart';
import '../../../features/operation_quest/domain/operation_quest.dart';
import '../../../game_config.dart';
import '../../../models/enums.dart';
import '../../../models/game_data.dart';
import '../../../models/player.dart';

const _schemaVersion = 1;
const _skillKeys = {'addition', 'subtraction', 'multiplication', 'division'};
final _achievementIds =
    GameConfig.achievementsDef.map((item) => item.id).toSet();
final _questIds =
    OperationQuestStageId.values.map((stage) => stage.storageId).toSet();
final _shopItems =
    GameConfig.shopItems.values.expand((items) => items).toList();
final _ownedShopIds = _shopItems
    .where((item) => !item.consumable && item.special == null)
    .map((item) => item.id)
    .toSet();
final _avatarValues = {
  ...GameConfig.avatarBases,
  ..._shopItems
      .where((item) => item.id.startsWith('av_'))
      .map((item) => item.emoji),
};
final _hatValues = {
  ...GameConfig.avatarHats,
  ..._shopItems
      .where((item) => item.id.startsWith('hat_'))
      .map((item) => item.emoji),
};

class CloudProgressDocument {
  const CloudProgressDocument({
    this.schemaVersion = _schemaVersion,
    required this.revision,
    required this.revisionId,
    this.parentRevisionId,
    required this.resetGeneration,
    required this.updatedAtUtcMs,
    required this.progress,
  });

  final int schemaVersion;
  final int revision;
  final String revisionId;
  final String? parentRevisionId;
  final int resetGeneration;
  final int updatedAtUtcMs;
  final CloudProgress progress;

  factory CloudProgressDocument.empty({
    required String revisionId,
    String? parentRevisionId,
    int revision = 0,
    int resetGeneration = 0,
    int updatedAtUtcMs = 0,
  }) =>
      CloudProgressDocument(
        revision: revision,
        revisionId: revisionId,
        parentRevisionId: parentRevisionId,
        resetGeneration: resetGeneration,
        updatedAtUtcMs: updatedAtUtcMs,
        progress: CloudProgress.empty(),
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'revision': revision,
        'revisionId': revisionId,
        'parentRevisionId': parentRevisionId,
        'resetGeneration': resetGeneration,
        'updatedAtUtcMs': updatedAtUtcMs,
        'progress': progress.toJson(),
      };

  String encode() => jsonEncode(toJson());

  bool hasSameProgressAs(CloudProgressDocument other) =>
      progress == other.progress;

  bool isSemanticallyEqualTo(CloudProgressDocument other) =>
      resetGeneration == other.resetGeneration && hasSameProgressAs(other);

  static CloudProgressParseResult decode(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map)
        return const CloudProgressParseResult.failure('root must be an object');
      final root = Map<String, Object?>.from(decoded);
      _onlyKeys(root, const {
        'schemaVersion',
        'revision',
        'revisionId',
        'parentRevisionId',
        'resetGeneration',
        'updatedAtUtcMs',
        'progress',
      });
      final schemaVersion = _int(root, 'schemaVersion');
      if (schemaVersion != _schemaVersion) {
        return CloudProgressParseResult.failure(
          schemaVersion > _schemaVersion
              ? 'unsupported future schema'
              : 'unsupported schema',
        );
      }
      final revision = _nonNegative(root, 'revision');
      final resetGeneration = _nonNegative(root, 'resetGeneration');
      final updatedAtUtcMs = _nonNegative(root, 'updatedAtUtcMs');
      final revisionId = _revisionId(root['revisionId']);
      final parent = root['parentRevisionId'];
      final parentRevisionId = parent == null ? null : _revisionId(parent);
      final progress = CloudProgress._fromJson(_map(root, 'progress'));
      return CloudProgressParseResult.success(CloudProgressDocument(
        revision: revision,
        revisionId: revisionId,
        parentRevisionId: parentRevisionId,
        resetGeneration: resetGeneration,
        updatedAtUtcMs: updatedAtUtcMs,
        progress: progress,
      ));
    } on FormatException catch (error) {
      return CloudProgressParseResult.failure(error.message);
    } catch (_) {
      return const CloudProgressParseResult.failure('invalid cloud document');
    }
  }
}

class CloudProgressParseResult {
  const CloudProgressParseResult.success(this.document) : error = null;
  const CloudProgressParseResult.failure(this.error) : document = null;

  final CloudProgressDocument? document;
  final String? error;
  bool get isSuccess => document != null;
}

class CloudProgress {
  CloudProgress({
    required this.coins,
    required this.gamesPlayed,
    required Map<String, bool> achievements,
    required Map<String, int> operationQuestStars,
    required List<HighScore> highScores,
    required Map<String, SkillData> skillMap,
    required this.profile,
    required this.economy,
  })  : achievements = Map.unmodifiable(_sortedMap(achievements)),
        operationQuestStars = Map.unmodifiable(_sortedMap(operationQuestStars)),
        highScores = List.unmodifiable(highScores),
        skillMap = Map.unmodifiable(_sortedMap(skillMap));

  factory CloudProgress.empty() => CloudProgress(
        coins: 0,
        gamesPlayed: 0,
        achievements: {for (final id in _achievementIds) id: false},
        operationQuestStars: const {},
        highScores: const [],
        skillMap: {for (final key in _skillKeys) key: SkillData()},
        profile: CloudProfile.empty(),
        economy: CloudEconomy.empty(),
      );

  final int coins;
  final int gamesPlayed;
  final Map<String, bool> achievements;
  final Map<String, int> operationQuestStars;
  final List<HighScore> highScores;
  final Map<String, SkillData> skillMap;
  final CloudProfile profile;
  final CloudEconomy economy;

  Map<String, Object?> toJson() => {
        'coins': coins,
        'gamesPlayed': gamesPlayed,
        'achievements': _sortedMap(achievements),
        'operationQuestStars': _sortedMap(operationQuestStars),
        'highScores': highScores.map((score) => score.toJson()).toList(),
        'skillMap': _sortedMap(
          skillMap.map((key, value) => MapEntry(key, value.toJson())),
        ),
        'profile': profile.toJson(),
        'economy': economy.toJson(),
      };

  static CloudProgress _fromJson(Map<String, Object?> json) {
    _onlyKeys(json, const {
      'coins',
      'gamesPlayed',
      'achievements',
      'operationQuestStars',
      'highScores',
      'skillMap',
      'profile',
      'economy',
    });
    final achievements =
        _boolMap(_map(json, 'achievements'), _achievementIds, 'achievement');
    if (achievements.length != _achievementIds.length) {
      throw const FormatException(
          'achievements must contain every canonical ID');
    }
    final stars =
        _intMap(_map(json, 'operationQuestStars'), _questIds, 'quest stage');
    if (stars.values.any((value) => value < 0 || value > 3)) {
      throw const FormatException('quest stars must be between 0 and 3');
    }
    final skillMap = _skillMap(_map(json, 'skillMap'));
    if (skillMap.length != _skillKeys.length ||
        !skillMap.keys.every(_skillKeys.contains)) {
      throw const FormatException(
          'skill map must contain canonical operations');
    }
    final scoreList = _list(json, 'highScores').map(_highScore).toList();
    if (scoreList.length > 10)
      throw const FormatException('too many high scores');
    return CloudProgress(
      coins: _nonNegative(json, 'coins'),
      gamesPlayed: _nonNegative(json, 'gamesPlayed'),
      achievements: achievements,
      operationQuestStars: stars,
      highScores: scoreList,
      skillMap: skillMap,
      profile: CloudProfile._fromJson(_map(json, 'profile')),
      economy: CloudEconomy._fromJson(_map(json, 'economy')),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CloudProgress &&
      jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

class CloudProfile {
  const CloudProfile({required this.player1, required this.player2});

  factory CloudProfile.empty() => CloudProfile(
        player1: CloudPlayerProfile.empty(1),
        player2: CloudPlayerProfile.empty(2),
      );

  final CloudPlayerProfile player1;
  final CloudPlayerProfile player2;

  Map<String, Object?> toJson() => {
        'player1': player1.toJson(),
        'player2': player2.toJson(),
      };

  static CloudProfile _fromJson(Map<String, Object?> json) {
    _onlyKeys(json, const {'player1', 'player2'});
    return CloudProfile(
      player1: CloudPlayerProfile._fromJson(_map(json, 'player1')),
      player2: CloudPlayerProfile._fromJson(_map(json, 'player2')),
    );
  }
}

class CloudPlayerProfile {
  const CloudPlayerProfile({
    required this.name,
    required this.selectedAvatar,
    required this.customAvatar,
  });

  factory CloudPlayerProfile.empty(int player) => CloudPlayerProfile(
        name: 'Player $player',
        selectedAvatar: player == 1 ? '🐶' : '🐱',
        customAvatar: AvatarCustom(base: player == 1 ? '🐶' : '🐸'),
      );

  final String name;
  final String selectedAvatar;
  final AvatarCustom customAvatar;

  Map<String, Object?> toJson() => {
        'name': name,
        'selectedAvatar': selectedAvatar,
        'customAvatar': customAvatar.toJson(),
      };

  static CloudPlayerProfile _fromJson(Map<String, Object?> json) {
    _onlyKeys(json, const {'name', 'selectedAvatar', 'customAvatar'});
    final name = _string(json, 'name');
    final selectedAvatar = _string(json, 'selectedAvatar');
    if (name.trim().isEmpty || !_avatarValues.contains(selectedAvatar)) {
      throw const FormatException('invalid player profile');
    }
    return CloudPlayerProfile(
      name: name,
      selectedAvatar: selectedAvatar,
      customAvatar: _avatarCustom(_map(json, 'customAvatar')),
    );
  }
}

class CloudEconomy {
  CloudEconomy({
    required Map<String, int> numberTypeUnlocks,
    required List<String> shopOwned,
    required List<String> unlockedAvatars,
    required List<String> unlockedHats,
    required Map<String, int> powerUpBonus,
    required this.livesBonus,
  })  : numberTypeUnlocks = Map.unmodifiable(_sortedMap(numberTypeUnlocks)),
        shopOwned = List.unmodifiable(_sortedUnique(shopOwned)),
        unlockedAvatars = List.unmodifiable(_sortedUnique(unlockedAvatars)),
        unlockedHats = List.unmodifiable(_sortedUnique(unlockedHats)),
        powerUpBonus = Map.unmodifiable(_sortedMap(powerUpBonus));

  factory CloudEconomy.empty() => CloudEconomy(
        numberTypeUnlocks: const {'integers': 0, 'rationals': 0},
        shopOwned: const [],
        unlockedAvatars: const [],
        unlockedHats: const [],
        powerUpBonus: {for (final powerUp in PowerUp.values) powerUp.name: 0},
        livesBonus: 0,
      );

  final Map<String, int> numberTypeUnlocks;
  final List<String> shopOwned;
  final List<String> unlockedAvatars;
  final List<String> unlockedHats;
  final Map<String, int> powerUpBonus;
  final int livesBonus;

  Map<String, Object?> toJson() => {
        'numberTypeUnlocks': _sortedMap(numberTypeUnlocks),
        'shopOwned': shopOwned,
        'unlockedAvatars': unlockedAvatars,
        'unlockedHats': unlockedHats,
        'powerUpBonus': _sortedMap(powerUpBonus),
        'livesBonus': livesBonus,
      };

  static CloudEconomy _fromJson(Map<String, Object?> json) {
    _onlyKeys(json, const {
      'numberTypeUnlocks',
      'shopOwned',
      'unlockedAvatars',
      'unlockedHats',
      'powerUpBonus',
      'livesBonus',
    });
    final unlocks = _intMap(
      _map(json, 'numberTypeUnlocks'),
      const {'integers', 'rationals'},
      'number type',
    );
    if (unlocks.length != 2 ||
        unlocks.values.any((value) => value != 0 && value != 1)) {
      throw const FormatException('invalid number type unlocks');
    }
    final bonuses = _intMap(
      _map(json, 'powerUpBonus'),
      PowerUp.values.map((powerUp) => powerUp.name).toSet(),
      'power up',
    );
    if (bonuses.length != PowerUp.values.length ||
        bonuses.values.any((value) => value < 0)) {
      throw const FormatException('invalid power up bonus');
    }
    return CloudEconomy(
      numberTypeUnlocks: unlocks,
      shopOwned: _identifierList(json, 'shopOwned', _ownedShopIds),
      unlockedAvatars: _identifierList(json, 'unlockedAvatars', _avatarValues),
      unlockedHats: _identifierList(json, 'unlockedHats', _hatValues),
      powerUpBonus: bonuses,
      livesBonus: _nonNegative(json, 'livesBonus'),
    );
  }
}

Map<String, T> _sortedMap<T>(Map<String, T> values) {
  final keys = values.keys.toList()..sort();
  return {for (final key in keys) key: values[key] as T};
}

List<String> _sortedUnique(Iterable<String> values) =>
    (values.toSet().toList()..sort());

Map<String, Object?> _map(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! Map) throw FormatException('$key must be an object');
  try {
    return Map<String, Object?>.from(value);
  } catch (_) {
    throw FormatException('$key must be an object');
  }
}

void _onlyKeys(Map<String, Object?> source, Set<String> allowed) {
  if (source.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('unknown cloud field');
  }
}

List<Object?> _list(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! List) throw FormatException('$key must be a list');
  return List<Object?>.from(value);
}

String _string(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}

int _int(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! int) throw FormatException('$key must be an integer');
  return value;
}

int _nonNegative(Map<String, Object?> source, String key) {
  final value = _int(source, key);
  if (value < 0) throw FormatException('$key must not be negative');
  return value;
}

String _revisionId(Object? value) {
  if (value is! String ||
      !RegExp(r'^[A-Za-z0-9._~-]{1,100}$').hasMatch(value)) {
    throw const FormatException('invalid revision ID');
  }
  return value;
}

Map<String, bool> _boolMap(
    Map<String, Object?> value, Set<String> allowed, String label) {
  final result = <String, bool>{};
  for (final entry in value.entries) {
    if (!allowed.contains(entry.key) || entry.value is! bool) {
      throw FormatException('invalid $label');
    }
    result[entry.key] = entry.value as bool;
  }
  return result;
}

Map<String, int> _intMap(
    Map<String, Object?> value, Set<String> allowed, String label) {
  final result = <String, int>{};
  for (final entry in value.entries) {
    if (!allowed.contains(entry.key) || entry.value is! int) {
      throw FormatException('invalid $label');
    }
    result[entry.key] = entry.value as int;
  }
  return result;
}

Map<String, SkillData> _skillMap(Map<String, Object?> json) {
  final result = <String, SkillData>{};
  for (final entry in json.entries) {
    if (!_skillKeys.contains(entry.key) || entry.value is! Map) {
      throw const FormatException('invalid skill map');
    }
    final value = Map<String, Object?>.from(entry.value as Map);
    _onlyKeys(value, const {
      'easy',
      'medium',
      'hard',
      'expert',
      'insane',
      'correct',
      'count',
      'mastery',
      'confidence',
    });
    final easy = _nonNegative(value, 'easy');
    final medium = _nonNegative(value, 'medium');
    final hard = _nonNegative(value, 'hard');
    final expert = _nonNegative(value, 'expert');
    final insane = _nonNegative(value, 'insane');
    final correct = _nonNegative(value, 'correct');
    final count = _nonNegative(value, 'count');
    final mastery = _boundedDouble(value, 'mastery');
    final confidence = _boundedDouble(value, 'confidence');
    if (correct > count || easy + medium + hard + expert + insane > correct) {
      throw const FormatException('invalid skill counters');
    }
    result[entry.key] = SkillData(
      easy: easy,
      medium: medium,
      hard: hard,
      expert: expert,
      insane: insane,
      correct: correct,
      count: count,
      mastery: mastery,
      confidence: confidence,
    );
  }
  return result;
}

double _boundedDouble(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      value > AdaptiveDifficultyEngine.maxMastery) {
    throw FormatException('invalid $key');
  }
  return value.toDouble();
}

HighScore _highScore(Object? raw) {
  if (raw is! Map) throw const FormatException('invalid high score');
  final json = Map<String, Object?>.from(raw);
  _onlyKeys(json, const {
    'name',
    'score',
    'mode',
    'difficulty',
    'answerStyle',
    'date',
  });
  final name = _string(json, 'name');
  final score = _nonNegative(json, 'score');
  final date = _string(json, 'date');
  final mode = _enumValue(GameMode.values, _string(json, 'mode'), 'mode');
  final answerStyle = _enumValue(
      AnswerStyle.values, _string(json, 'answerStyle'), 'answer style');
  final difficultyRaw = json['difficulty'];
  final difficulty = difficultyRaw == null
      ? null
      : difficultyRaw is String
          ? _enumValue(Difficulty.values, difficultyRaw, 'difficulty')
          : throw const FormatException('invalid difficulty');
  if (name.trim().isEmpty || date.trim().isEmpty)
    throw const FormatException('invalid high score');
  return HighScore(
      name: name,
      score: score,
      mode: mode,
      difficulty: difficulty,
      answerStyle: answerStyle,
      date: date);
}

T _enumValue<T extends Enum>(List<T> values, String value, String label) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  throw FormatException('invalid $label');
}

AvatarCustom _avatarCustom(Map<String, Object?> json) {
  _onlyKeys(json, const {'base', 'hat', 'accessory', 'color'});
  final base = _string(json, 'base');
  final hat = _string(json, 'hat');
  final accessory = _string(json, 'accessory');
  final color = json['color'];
  if (!GameConfig.avatarBases.contains(base) ||
      !GameConfig.avatarHats.contains(hat) ||
      !GameConfig.avatarAccessories.contains(accessory) ||
      (color != null &&
          (color is! String || !GameConfig.avatarColors.contains(color)))) {
    throw const FormatException('invalid custom avatar');
  }
  return AvatarCustom(
      base: base, hat: hat, accessory: accessory, color: color as String?);
}

List<String> _identifierList(
    Map<String, Object?> source, String key, Set<String> allowed) {
  final values = _list(source, key);
  if (values.any((value) => value is! String || !allowed.contains(value))) {
    throw FormatException('invalid $key');
  }
  return _sortedUnique(values.cast<String>());
}
