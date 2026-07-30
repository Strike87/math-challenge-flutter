import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';

void main() {
  CloudProgressDocument fresh({String id = 'revision-1', int reset = 0}) =>
      CloudProgressDocument.empty(revisionId: id, resetGeneration: reset);

  Map<String, dynamic> jsonOf(CloudProgressDocument document) =>
      jsonDecode(document.encode()) as Map<String, dynamic>;

  test('new documents use deterministic schema v2 encoding', () {
    final document = fresh();
    final decoded = CloudProgressDocument.decode(document.encode());
    expect(decoded.isSuccess, isTrue, reason: decoded.error);
    expect(decoded.document!.isSemanticallyEqualTo(document), isTrue);
    expect(decoded.document!.encode(), document.encode());
  });

  test('strict v1 documents remain readable and v1-shaped', () {
    final v1 = CloudProgressDocument(
      schemaVersion: 1,
      revision: 0,
      revisionId: 'v1',
      resetGeneration: 0,
      updatedAtUtcMs: 0,
      progress: CloudProgress.empty(),
    );
    final decoded = CloudProgressDocument.decode(v1.encode());
    expect(decoded.isSuccess, isTrue, reason: decoded.error);
    expect(decoded.document!.schemaVersion, 1);
    expect(decoded.document!.mergeParentRevisionIds, isEmpty);
    expect(decoded.document!.encode(), v1.encode());
    expect(jsonOf(v1), isNot(contains('mergeParentRevisionIds')));
    final invalid = jsonOf(v1)..['mergeParentRevisionIds'] = <String>[];
    expect(
        CloudProgressDocument.decode(jsonEncode(invalid)).isSuccess, isFalse);
  });

  test('v1 progress, economy, and profile payloads remain compatible', () {
    final v1 = jsonOf(fresh())
      ..['schemaVersion'] = 1
      ..remove('mergeParentRevisionIds');
    final progress = v1['progress'] as Map<String, dynamic>;
    progress['coins'] = 5;
    progress['economy']['numberTypeUnlocks']['integers'] = 1;
    progress['profile']['player1']['name'] = 'Ada';
    final decoded = CloudProgressDocument.decode(jsonEncode(v1));
    expect(decoded.isSuccess, isTrue, reason: decoded.error);
    expect(decoded.document!.schemaVersion, 1);
    expect(decoded.document!.progress.coins, 5);
    expect(decoded.document!.progress.economy.numberTypeUnlocks['integers'], 1);
    expect(decoded.document!.progress.profile.player1.name, 'Ada');
  });

  test('validates and canonicalizes v2 merge parents', () {
    final merge = CloudProgressDocument(
      revision: 4,
      revisionId: 'merge',
      mergeParentRevisionIds: const ['b', 'a'],
      resetGeneration: 0,
      updatedAtUtcMs: 2,
      progress: CloudProgress.empty(),
    );
    expect(merge.mergeParentRevisionIds, ['a', 'b']);
    expect(merge.directParentRevisionIds, ['a', 'b']);
    final reversed = jsonOf(merge)
      ..['mergeParentRevisionIds'] = <String>['b', 'a'];
    expect(
        CloudProgressDocument.decode(jsonEncode(reversed)).document!.encode(),
        merge.encode());
  });

  test('rejects invalid v2 lineage combinations', () {
    final base = jsonOf(fresh(id: 'self'));
    for (final mergeParents in <Object?>[
      <String>['a'],
      <String>['a', 'b', 'c'],
      <String>['a', 'a'],
      <String>['', 'a'],
      <String>['self', 'a'],
    ]) {
      final json = Map<String, dynamic>.from(base)
        ..['mergeParentRevisionIds'] = mergeParents;
      expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
    }
    final scalarAndMerge = Map<String, dynamic>.from(base)
      ..['parentRevisionId'] = 'a'
      ..['mergeParentRevisionIds'] = <String>['b', 'c'];
    expect(CloudProgressDocument.decode(jsonEncode(scalarAndMerge)).isSuccess,
        isFalse);
    final scalarSelf = Map<String, dynamic>.from(base)
      ..['parentRevisionId'] = 'self';
    expect(CloudProgressDocument.decode(jsonEncode(scalarSelf)).isSuccess,
        isFalse);
  });

  test('empty progress uses current production defaults', () {
    final progress = fresh().progress;
    expect(progress.coins, 0);
    expect(progress.gamesPlayed, 0);
    expect(progress.achievements.values, everyElement(isFalse));
    expect(progress.operationQuestStars, isEmpty);
    expect(progress.highScores, isEmpty);
    expect(
        progress.skillMap.keys,
        containsAll(
            <String>['addition', 'subtraction', 'multiplication', 'division']));
    for (final skill in progress.skillMap.values) {
      expect(skill.easy, 0);
      expect(skill.medium, 0);
      expect(skill.hard, 0);
      expect(skill.expert, 0);
      expect(skill.insane, 0);
      expect(skill.correct, 0);
      expect(skill.count, 0);
      expect(skill.mastery, 20);
      expect(skill.confidence, 0);
    }
    expect(progress.profile.player1.name, 'Player 1');
    expect(progress.profile.player1.selectedAvatar, '🐶');
    expect(progress.profile.player1.customAvatar.base, '🐶');
    expect(progress.profile.player1.customAvatar.hat, '');
    expect(progress.profile.player1.customAvatar.accessory, '');
    expect(progress.profile.player1.customAvatar.color, isNull);
    expect(progress.profile.player2.name, 'Player 2');
    expect(progress.profile.player2.selectedAvatar, '🐱');
    expect(progress.profile.player2.customAvatar.base, '🐸');
    expect(progress.profile.player2.customAvatar.hat, '');
    expect(progress.profile.player2.customAvatar.accessory, '');
    expect(progress.profile.player2.customAvatar.color, isNull);
    expect(progress.economy.numberTypeUnlocks, {'integers': 0, 'rationals': 0});
    expect(progress.economy.shopOwned, isEmpty);
    expect(progress.economy.unlockedAvatars, isEmpty);
    expect(progress.economy.unlockedHats, isEmpty);
    expect(progress.economy.powerUpBonus, {
      'time': 0,
      'fifty': 0,
      'double': 0,
      'shield': 0,
      'freeze': 0,
      'switchOp': 0,
    });
    expect(progress.economy.livesBonus, 0);
  });

  test('serializes equivalent maps and identifier lists identically', () {
    final first = jsonOf(fresh());
    final second = jsonOf(fresh());
    final firstProgress = first['progress'] as Map<String, dynamic>;
    final secondProgress = second['progress'] as Map<String, dynamic>;
    final achievements = firstProgress['achievements'] as Map<String, dynamic>;

    firstProgress['achievements'] = Map<String, dynamic>.fromEntries(
      achievements.entries.toList().reversed,
    );
    firstProgress['operationQuestStars'] = {
      'addition_medium': 2,
      'addition_easy': 1,
    };
    secondProgress['operationQuestStars'] = {
      'addition_easy': 1,
      'addition_medium': 2,
    };
    firstProgress['economy']['numberTypeUnlocks'] = {
      'rationals': 1,
      'integers': 0,
    };
    secondProgress['economy']['numberTypeUnlocks'] = {
      'integers': 0,
      'rationals': 1,
    };
    firstProgress['economy']['shopOwned'] = ['hat_crown', 'av_dragon'];
    secondProgress['economy']['shopOwned'] = ['av_dragon', 'hat_crown'];

    final firstDocument =
        CloudProgressDocument.decode(jsonEncode(first)).document!;
    final secondDocument =
        CloudProgressDocument.decode(jsonEncode(second)).document!;
    expect(firstDocument.encode(), secondDocument.encode());
  });

  test('semantic equality ignores metadata but not reset generation', () {
    final local = fresh(id: 'local');
    final metadataOnly = CloudProgressDocument(
      revision: 99,
      revisionId: 'cloud',
      parentRevisionId: 'local',
      resetGeneration: 0,
      updatedAtUtcMs: 4,
      progress: local.progress,
    );
    expect(local.isSemanticallyEqualTo(metadataOnly), isTrue);
    expect(local.isSemanticallyEqualTo(fresh(id: 'reset', reset: 1)), isFalse);
  });

  test('rejects malformed roots, schemas, and metadata', () {
    expect(CloudProgressDocument.decode('{').isSuccess, isFalse);
    expect(CloudProgressDocument.decode('[]').isSuccess, isFalse);
    for (final change in <String, Object?>{
      'schemaVersion': 0,
      'revision': -1,
      'revisionId': 'bad id',
      'resetGeneration': -1,
      'updatedAtUtcMs': -1,
    }.entries) {
      final json = jsonOf(fresh())..[change.key] = change.value;
      expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
    }
  });

  test('rejects future schema versions explicitly', () {
    final json = jsonOf(fresh())..['schemaVersion'] = 3;
    expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
  });

  test('rejects progression-changing invalid payload values', () {
    final invalids = <void Function(Map<String, dynamic>)>[
      (json) => json['progress']['coins'] = -1,
      (json) => json['progress']['gamesPlayed'] = -1,
      (json) => json['progress']['achievements']['unknown'] = true,
      (json) => json['progress']['achievements']['first_win'] = 1,
      (json) => json['progress']['operationQuestStars']['unknown'] = 1,
      (json) => json['progress']['operationQuestStars']['addition_easy'] = 4,
      (json) => json['progress']['skillMap']['addition']['mastery'] = 101,
      (json) => json['progress']['highScores'] = [<String, Object?>{}],
      (json) => json['progress']['profile']['player1']['selectedAvatar'] = 'x',
      (json) =>
          json['progress']['economy']['numberTypeUnlocks']['integers'] = 2,
      (json) => json['progress']['economy']['livesBonus'] = -1,
    ];
    for (final invalidate in invalids) {
      final json = jsonOf(fresh());
      invalidate(json);
      expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
    }
  });

  test('normalizes duplicate identifier lists and excludes non-v1 fields', () {
    final json = jsonOf(fresh());
    json['progress']['economy']['shopOwned'] = ['av_dragon', 'av_dragon'];
    final decoded = CloudProgressDocument.decode(jsonEncode(json));
    expect(decoded.document!.progress.economy.shopOwned, ['av_dragon']);
    final encoded = decoded.document!.encode();
    for (final excluded in [
      'adaptLvlRaw',
      'dailyProgress',
      'dark',
      'adsRemoved',
      'iapDeliveredTxs',
      'timer'
    ]) {
      expect(encoded, isNot(contains(excluded)));
    }
    json['progress']['dailyProgress'] = <String, Object?>{};
    expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
  });

  test('rejects malformed custom avatar data atomically', () {
    final json = jsonOf(fresh());
    json['progress']['profile']['player1']['customAvatar']['hat'] = 1;
    expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
  });

  test('rejects negative power-up bonus', () {
    final json = jsonOf(fresh());
    json['progress']['economy']['powerUpBonus']['time'] = -1;
    expect(CloudProgressDocument.decode(jsonEncode(json)).isSuccess, isFalse);
  });
}
