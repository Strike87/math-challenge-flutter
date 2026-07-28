import '../../../game_config.dart';
import '../../../models/game_data.dart';
import 'cloud_progress_document.dart';

enum CloudProgressRelation {
  same,
  localDirectDescendant,
  cloudDirectDescendant,
  knownViaLastSynced,
  unrelated,
}

enum CloudProgressDecisionKind {
  noChange,
  useLocal,
  useCloud,
  needsUserChoice,
  invalidLineage,
}

class CloudProgressDecision {
  const CloudProgressDecision._(
    this.kind, {
    required this.relation,
    this.keepLocalCandidate,
    this.useCloudCandidate,
  });

  const CloudProgressDecision.noChange(CloudProgressRelation relation)
      : this._(CloudProgressDecisionKind.noChange, relation: relation);
  const CloudProgressDecision.useLocal(CloudProgressRelation relation)
      : this._(CloudProgressDecisionKind.useLocal, relation: relation);
  const CloudProgressDecision.useCloud(CloudProgressRelation relation)
      : this._(CloudProgressDecisionKind.useCloud, relation: relation);
  const CloudProgressDecision.invalidLineage(CloudProgressRelation relation)
      : this._(CloudProgressDecisionKind.invalidLineage, relation: relation);
  const CloudProgressDecision.needsUserChoice(
    CloudProgressRelation relation,
    CloudProgress keepLocalCandidate,
    CloudProgress useCloudCandidate,
  ) : this._(
          CloudProgressDecisionKind.needsUserChoice,
          relation: relation,
          keepLocalCandidate: keepLocalCandidate,
          useCloudCandidate: useCloudCandidate,
        );

  final CloudProgressDecisionKind kind;
  final CloudProgressRelation relation;
  final CloudProgress? keepLocalCandidate;
  final CloudProgress? useCloudCandidate;
}

class CloudProgressPolicy {
  const CloudProgressPolicy();

  CloudProgressDecision decide(
    CloudProgressDocument local,
    CloudProgressDocument cloud, {
    String? lastSyncedRevisionId,
  }) {
    final relation = _relation(local, cloud, lastSyncedRevisionId);
    if (local.resetGeneration != cloud.resetGeneration) {
      return local.resetGeneration > cloud.resetGeneration
          ? const CloudProgressDecision.useLocal(
              CloudProgressRelation.unrelated)
          : const CloudProgressDecision.useCloud(
              CloudProgressRelation.unrelated);
    }
    if (local.isSemanticallyEqualTo(cloud)) {
      return CloudProgressDecision.noChange(relation);
    }
    final empty = CloudProgress.empty();
    if (local.progress == empty && cloud.progress == empty) {
      return CloudProgressDecision.noChange(relation);
    }
    if (local.progress == empty)
      return CloudProgressDecision.useCloud(relation);
    if (cloud.progress == empty)
      return CloudProgressDecision.useLocal(relation);
    if (relation == CloudProgressRelation.same) {
      return CloudProgressDecision.invalidLineage(relation);
    }
    if (relation == CloudProgressRelation.cloudDirectDescendant) {
      return CloudProgressDecision.useCloud(relation);
    }
    if (relation == CloudProgressRelation.localDirectDescendant) {
      return CloudProgressDecision.useLocal(relation);
    }
    final safe = _safeProgress(local.progress, cloud.progress);
    return CloudProgressDecision.needsUserChoice(
      relation,
      _withAtomicGroups(safe, local.progress),
      _withAtomicGroups(safe, cloud.progress),
    );
  }

  CloudProgressRelation _relation(
    CloudProgressDocument local,
    CloudProgressDocument cloud,
    String? lastSyncedRevisionId,
  ) {
    if (local.revisionId == cloud.revisionId) return CloudProgressRelation.same;
    if (local.parentRevisionId == cloud.revisionId) {
      return CloudProgressRelation.localDirectDescendant;
    }
    if (cloud.parentRevisionId == local.revisionId) {
      return CloudProgressRelation.cloudDirectDescendant;
    }
    if (lastSyncedRevisionId != null &&
        local.parentRevisionId == lastSyncedRevisionId &&
        cloud.parentRevisionId == lastSyncedRevisionId) {
      return CloudProgressRelation.knownViaLastSynced;
    }
    return CloudProgressRelation.unrelated;
  }

  CloudProgress _safeProgress(CloudProgress local, CloudProgress cloud) =>
      CloudProgress(
        coins: 0,
        gamesPlayed: local.gamesPlayed > cloud.gamesPlayed
            ? local.gamesPlayed
            : cloud.gamesPlayed,
        achievements: {
          for (final achievement in GameConfig.achievementsDef)
            achievement.id: (local.achievements[achievement.id] ?? false) ||
                (cloud.achievements[achievement.id] ?? false),
        },
        operationQuestStars: {
          for (final id in {
            ...local.operationQuestStars.keys,
            ...cloud.operationQuestStars.keys,
          })
            id: _maxStars(
                local.operationQuestStars[id], cloud.operationQuestStars[id]),
        },
        highScores: _mergeScores(local.highScores, cloud.highScores),
        skillMap: local.skillMap,
        profile: local.profile,
        economy: local.economy,
      );

  CloudProgress _withAtomicGroups(CloudProgress safe, CloudProgress side) =>
      CloudProgress(
        coins: side.coins,
        gamesPlayed: safe.gamesPlayed,
        achievements: safe.achievements,
        operationQuestStars: safe.operationQuestStars,
        highScores: safe.highScores,
        skillMap: side.skillMap,
        profile: side.profile,
        economy: side.economy,
      );

  List<HighScore> _mergeScores(List<HighScore> local, List<HighScore> cloud) {
    final unique = <String, HighScore>{};
    for (final score in [...local, ...cloud]) {
      unique.putIfAbsent(_scoreKey(score), () => score);
    }
    final scores = unique.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scores.take(10).toList();
  }

  int _maxStars(int? local, int? cloud) {
    final localStars = local ?? 0;
    final cloudStars = cloud ?? 0;
    return localStars > cloudStars ? localStars : cloudStars;
  }

  String _scoreKey(HighScore score) => [
        score.name,
        score.score,
        score.mode.name,
        score.difficulty?.name,
        score.answerStyle.name,
        score.date,
      ].join('\u0000');
}
