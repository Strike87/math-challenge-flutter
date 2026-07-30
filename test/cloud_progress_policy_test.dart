import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_policy.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/game_data.dart';

void main() {
  const policy = CloudProgressPolicy();

  CloudProgressDocument doc({
    String id = 'local',
    String? parent,
    List<String> mergeParents = const [],
    int revision = 0,
    int reset = 0,
    int time = 0,
    CloudProgress? progress,
  }) =>
      CloudProgressDocument(
        revision: revision,
        revisionId: id,
        parentRevisionId: parent,
        mergeParentRevisionIds: mergeParents,
        resetGeneration: reset,
        updatedAtUtcMs: time,
        progress: progress ?? CloudProgress.empty(),
      );

  CloudProgress populated({
    int coins = 1,
    int games = 1,
    Map<String, bool>? achievements,
    Map<String, int>? stars,
    List<HighScore>? scores,
    double mastery = 20,
    String name = 'Player 1',
    String avatar = '🐶',
    int lives = 0,
  }) {
    final base = CloudProgress.empty();
    return CloudProgress(
      coins: coins,
      gamesPlayed: games,
      achievements: achievements ?? base.achievements,
      operationQuestStars: stars ?? const {},
      highScores: scores ?? const [],
      skillMap: {
        for (final entry in base.skillMap.entries)
          entry.key: SkillData(mastery: mastery),
      },
      profile: CloudProfile(
        player1: CloudPlayerProfile(
          name: name,
          selectedAvatar: avatar,
          customAvatar: base.profile.player1.customAvatar,
        ),
        player2: base.profile.player2,
      ),
      economy: CloudEconomy(
        numberTypeUnlocks: base.economy.numberTypeUnlocks,
        shopOwned: coins == 100 ? const ['av_dragon'] : const [],
        unlockedAvatars: const [],
        unlockedHats: const [],
        powerUpBonus: base.economy.powerUpBonus,
        livesBonus: lives,
      ),
    );
  }

  HighScore score(String name, int value) => HighScore(
        name: name,
        score: value,
        mode: GameMode.standard,
        difficulty: Difficulty.easy,
        answerStyle: AnswerStyle.choice4,
        date: '2026-01-01',
      );

  test('reset generation always wins without merging lower generation', () {
    final local =
        doc(reset: 2, revision: 1, time: 1, progress: populated(coins: 1));
    final cloud = doc(
        id: 'cloud',
        reset: 1,
        revision: 99,
        time: 999,
        progress: populated(coins: 100));
    expect(
        policy.decide(local, cloud).kind, CloudProgressDecisionKind.useLocal);
    expect(
        policy.decide(cloud, local).kind, CloudProgressDecisionKind.useCloud);
  });

  test('empty and semantic equality cases do not conflict', () {
    expect(policy.decide(doc(), doc(id: 'cloud')).kind,
        CloudProgressDecisionKind.noChange);
    expect(policy.decide(doc(), doc(id: 'cloud', progress: populated())).kind,
        CloudProgressDecisionKind.useCloud);
    expect(policy.decide(doc(progress: populated()), doc(id: 'cloud')).kind,
        CloudProgressDecisionKind.useLocal);
    expect(
        policy
            .decide(doc(progress: populated()),
                doc(id: 'cloud', revision: 9, time: 99, progress: populated()))
            .kind,
        CloudProgressDecisionKind.noChange);
  });

  test('proven linear ancestry resolves and inconsistent same IDs reject', () {
    final local = doc(id: 'base', progress: populated());
    expect(
        policy
            .decide(local,
                doc(id: 'cloud', parent: 'base', progress: populated(coins: 2)))
            .kind,
        CloudProgressDecisionKind.useCloud);
    expect(
        policy
            .decide(
                doc(id: 'local', parent: 'base', progress: populated(coins: 2)),
                local)
            .kind,
        CloudProgressDecisionKind.useLocal);
    expect(
        policy
            .decide(local, doc(id: 'base', progress: populated(coins: 2)))
            .kind,
        CloudProgressDecisionKind.invalidLineage);
  });

  test('revision and timestamp never choose unrelated divergent progress', () {
    final result = policy.decide(
      doc(revision: 100, time: 1, progress: populated(coins: 1)),
      doc(
          id: 'cloud',
          revision: 5,
          time: 999999,
          progress: populated(coins: 2)),
    );
    expect(result.kind, CloudProgressDecisionKind.needsUserChoice);
    expect(result.relation, CloudProgressRelation.unrelated);
    expect(
        policy
            .decide(doc(parent: 'sync', progress: populated()),
                doc(id: 'cloud', parent: 'sync', progress: populated(coins: 2)),
                lastSyncedRevisionId: 'sync')
            .relation,
        CloudProgressRelation.knownViaLastSynced);
  });

  test('divergence returns exactly two atomic candidates with only safe merges',
      () {
    final local = doc(
        progress: populated(
      coins: 100,
      games: 3,
      achievements: {...CloudProgress.empty().achievements, 'first_win': true},
      stars: const {'addition_easy': 1},
      scores: [score('L', 10)],
      mastery: 30,
      name: 'Local',
      lives: 2,
    ));
    final cloud = doc(
        id: 'cloud',
        progress: populated(
          coins: 600,
          games: 5,
          achievements: {
            ...CloudProgress.empty().achievements,
            'speed_demon': true
          },
          stars: const {'addition_easy': 3, 'subtraction_easy': 0},
          scores: [score('C', 20), score('L', 10)],
          mastery: 80,
          name: 'Cloud',
          lives: 7,
        ));
    final result = policy.decide(local, cloud);
    expect(result.kind, CloudProgressDecisionKind.needsUserChoice);
    final keep = result.keepLocalCandidate!;
    final use = result.useCloudCandidate!;
    expect(keep.gamesPlayed, 5);
    expect(keep.achievements['first_win'], isTrue);
    expect(keep.achievements['speed_demon'], isTrue);
    expect(keep.operationQuestStars['addition_easy'], 3);
    expect(keep.highScores.map((item) => item.score), [20, 10]);
    expect(keep.coins, 100);
    expect(keep.economy.shopOwned, ['av_dragon']);
    expect(keep.skillMap['addition']!.mastery, 30);
    expect(keep.profile.player1.name, 'Local');
    expect(keep.economy.livesBonus, 2);
    expect(use.coins, 600);
    expect(use.economy.shopOwned, isEmpty);
    expect(use.skillMap['addition']!.mastery, 80);
    expect(use.profile.player1.name, 'Cloud');
    expect(use.economy.livesBonus, 7);
    for (final candidate in [keep, use]) {
      final result = CloudProgressDocument.decode(
          jsonEncode(doc(progress: candidate).toJson()));
      expect(result.isSuccess, isTrue, reason: result.error);
    }
  });

  test('high scores use canonical ranking and retain ten unique entries', () {
    final local = doc(
        progress: populated(scores: List.generate(10, (i) => score('L$i', i))));
    final cloud = doc(
        id: 'cloud',
        progress: populated(scores: [score('L9', 9), score('C', 99)]));
    final scores = policy.decide(local, cloud).mergedCandidate!.highScores;
    expect(scores.length, 10);
    expect(scores.first.score, 99);
    expect(scores.where((item) => item.name == 'L9'), hasLength(1));
  });

  test('safe divergence creates a policy-owned merge plan', () {
    final local = doc(
      id: 'a',
      revision: 3,
      progress: populated(
        games: 1,
        achievements: {
          ...CloudProgress.empty().achievements,
          'first_win': true
        },
      ),
    );
    final cloud = doc(
      id: 'b',
      revision: 5,
      progress: populated(
        games: 2,
        achievements: {
          ...CloudProgress.empty().achievements,
          'speed_demon': true
        },
      ),
    );
    final result = policy.decide(local, cloud);
    expect(result.kind, CloudProgressDecisionKind.mergeRequired);
    expect(result.mergedCandidate!.gamesPlayed, 2);
    expect(result.mergedCandidate!.achievements['first_win'], isTrue);
    expect(result.mergedCandidate!.achievements['speed_demon'], isTrue);
    expect(result.mergePlan!.parentRevisionIds, ['a', 'b']);
    expect(result.mergePlan!.revision, 6);
  });

  test('safe sibling divergence requires a merge revision', () {
    final result = policy.decide(
      doc(
        id: 'a',
        parent: 'c',
        revision: 2,
        progress: populated(
          achievements: {
            ...CloudProgress.empty().achievements,
            'first_win': true,
          },
        ),
      ),
      doc(
        id: 'b',
        parent: 'c',
        revision: 4,
        progress: populated(
          achievements: {
            ...CloudProgress.empty().achievements,
            'speed_demon': true,
          },
        ),
      ),
      lastSyncedRevisionId: 'c',
    );
    expect(result.kind, CloudProgressDecisionKind.mergeRequired);
    expect(result.relation, CloudProgressRelation.knownViaLastSynced);
    expect(result.mergePlan!.parentRevisionIds, ['a', 'b']);
    expect(result.mergePlan!.revision, 5);
  });

  test('merge parents are direct descendants before semantic equality', () {
    final a = doc(id: 'a', revision: 1, progress: populated());
    final b = doc(id: 'b', revision: 2, progress: populated());
    final merge = doc(
      id: 'm',
      revision: 3,
      mergeParents: const ['b', 'a'],
      progress: populated(),
    );
    for (final parent in [a, b]) {
      expect(policy.decide(parent, merge).kind,
          CloudProgressDecisionKind.useCloud);
      expect(policy.decide(merge, parent).kind,
          CloudProgressDecisionKind.useLocal);
    }
  });

  test('unsafe divergence keeps both candidates and the same merge plan', () {
    final result = policy.decide(
      doc(id: 'a', parent: 'c', revision: 2, progress: populated(coins: 1)),
      doc(id: 'b', parent: 'c', revision: 4, progress: populated(coins: 2)),
      lastSyncedRevisionId: 'c',
    );
    expect(result.kind, CloudProgressDecisionKind.needsUserChoice);
    expect(result.relation, CloudProgressRelation.knownViaLastSynced);
    expect(result.mergePlan!.parentRevisionIds, ['a', 'b']);
    expect(result.mergePlan!.revision, 5);
  });

  test('simple outcomes do not request a merge plan', () {
    expect(policy.decide(doc(), doc(id: 'cloud')).mergePlan, isNull);
    expect(
      policy
          .decide(doc(id: 'a', progress: populated()),
              doc(id: 'b', parent: 'a', progress: populated(coins: 2)))
          .mergePlan,
      isNull,
    );
    expect(
      policy
          .decide(
            doc(id: 'b', parent: 'a', progress: populated(coins: 2)),
            doc(id: 'a', progress: populated()),
          )
          .mergePlan,
      isNull,
    );
  });
}
