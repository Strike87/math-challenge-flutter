import 'dart:convert';

import '../../../models/enums.dart';

enum OperationQuestStageId {
  additionEasy('addition_easy'),
  additionMedium('addition_medium'),
  additionHard('addition_hard');

  const OperationQuestStageId(this.storageId);

  final String storageId;

  static OperationQuestStageId? fromStorageId(String value) {
    for (final id in values) {
      if (id.storageId == value) return id;
    }
    return null;
  }
}

class OperationQuestStage {
  const OperationQuestStage({
    required this.id,
    required this.title,
    required this.difficulty,
  });

  final OperationQuestStageId id;
  final String title;
  final Difficulty difficulty;
  Operation get operation => Operation.addition;
  NumberType get numberType => NumberType.natural;
  int get questionTarget => 10;
}

const operationQuestStages = <OperationQuestStage>[
  OperationQuestStage(
    id: OperationQuestStageId.additionEasy,
    title: 'First Sums',
    difficulty: Difficulty.easy,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.additionMedium,
    title: 'Bigger Sums',
    difficulty: Difficulty.medium,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.additionHard,
    title: 'Addition Challenge',
    difficulty: Difficulty.hard,
  ),
];

OperationQuestStage operationQuestStage(OperationQuestStageId id) =>
    operationQuestStages.firstWhere((stage) => stage.id == id);

int operationQuestStarsForCorrectAnswers(int correct) {
  if (correct >= 10) return 3;
  if (correct >= 8) return 2;
  if (correct >= 6) return 1;
  return 0;
}

class OperationQuestProgress {
  OperationQuestProgress([Map<OperationQuestStageId, int> stars = const {}])
      : stars = Map.unmodifiable(stars);

  factory OperationQuestProgress.decode(String raw) {
    if (raw.isEmpty) return OperationQuestProgress();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return OperationQuestProgress();
      }
      final rawStars = decoded['stars'];
      if (rawStars is! Map) return OperationQuestProgress();
      final stars = <OperationQuestStageId, int>{};
      for (final entry in rawStars.entries) {
        final id = OperationQuestStageId.fromStorageId('${entry.key}');
        final value = entry.value;
        if (id == null || value is! num) continue;
        stars[id] = value.toInt().clamp(0, 3);
      }
      return OperationQuestProgress(stars);
    } catch (_) {
      return OperationQuestProgress();
    }
  }

  final Map<OperationQuestStageId, int> stars;

  int bestStars(OperationQuestStageId id) => stars[id] ?? 0;

  bool isUnlocked(OperationQuestStageId id) {
    final index = operationQuestStages.indexWhere((stage) => stage.id == id);
    return index <= 0 || bestStars(operationQuestStages[index - 1].id) >= 1;
  }

  OperationQuestProgress recordBest(OperationQuestStageId id, int value) {
    final clamped = value.clamp(0, 3);
    if (clamped <= bestStars(id)) return this;
    return OperationQuestProgress({...stars, id: clamped});
  }

  String encode() => jsonEncode({
        'version': 1,
        'stars': {
          for (final entry in stars.entries) entry.key.storageId: entry.value,
        },
      });
}
