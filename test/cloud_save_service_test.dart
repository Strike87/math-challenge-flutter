import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  Future<GameState> state({bool rejectAcceptance = false}) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final settings = SettingsService()
      ..load(
        dark: false,
        sound: false,
        vibration: false,
        dyslexia: false,
        colorblind: false,
        lowPerf: true,
        reduceMotion: true,
        animSpeed: 1,
      );
    final GameState game = rejectAcceptance
        ? _RejectingGameState(settings, AudioService(settings))
        : GameState(settings: settings, audio: AudioService(settings));
    await game.load();
    addTearDown(game.dispose);
    return game;
  }

  CloudProgress progress({
    int coins = 0,
    int games = 0,
    String? achievement,
  }) {
    final empty = CloudProgress.empty();
    return CloudProgress(
      coins: coins,
      gamesPlayed: games,
      achievements: {
        ...empty.achievements,
        if (achievement != null) achievement: true,
      },
      operationQuestStars: empty.operationQuestStars,
      highScores: empty.highScores,
      skillMap: empty.skillMap,
      profile: empty.profile,
      economy: empty.economy,
    );
  }

  CloudProgressDocument document({
    int schemaVersion = 2,
    int revision = 0,
    String id = 'cloud',
    String? parent,
    List<String> mergeParents = const [],
    int reset = 0,
    int time = 1,
    CloudProgress? value,
  }) =>
      CloudProgressDocument(
        schemaVersion: schemaVersion,
        revision: revision,
        revisionId: id,
        parentRevisionId: parent,
        mergeParentRevisionIds: mergeParents,
        resetGeneration: reset,
        updatedAtUtcMs: time,
        progress: value ?? CloudProgress.empty(),
      );

  CloudSaveService service(
    GameState game,
    _FakeTransport transport, {
    List<String>? ids,
    int time = 1234,
  }) =>
      CloudSaveService(
        state: game,
        transport: transport,
        utcMilliseconds: () => time,
        revisionIdGenerator: ids == null ? null : () => ids.removeAt(0),
      );

  test('authentication and open failures are typed and do not mutate local',
      () async {
    for (final failure in [
      SavedGamesTransportFailure(SavedGamesTransportError.notAuthenticated),
      SavedGamesTransportFailure(
        SavedGamesTransportError.openFailed,
        diagnostic: 'offline',
      ),
    ]) {
      final game = await state()
        ..coins = 7;
      final before = game.exportCloudProgress();
      final transport = _FakeTransport()..openResult = failure;
      final result = await service(game, transport, ids: ['unused']).sync();
      expect(
        result,
        failure.error == SavedGamesTransportError.notAuthenticated
            ? isA<CloudSyncNotAuthenticated>()
            : isA<CloudSyncTransportFailure>(),
      );
      expect(game.exportCloudProgress(), before);
      expect(transport.commits, isEmpty);
    }
  });

  test('empty cloud is a no-op for fresh local and uploads truthful roots',
      () async {
    var generated = 0;
    final fresh = await state();
    final freshTransport = _FakeTransport();
    final freshResult = await CloudSaveService(
      state: fresh,
      transport: freshTransport,
      revisionIdGenerator: () {
        generated++;
        return 'unused';
      },
    ).sync();
    expect(freshResult, isA<CloudSyncNoChange>());
    expect(generated, 0);
    expect(freshTransport.commits, isEmpty);

    for (final reset in [false, true]) {
      final game = await state();
      if (reset) {
        game.cloudResetGeneration = 2;
      } else {
        game.coins = 9;
      }
      game.cloudDirty = true;
      final transport = _FakeTransport();
      final result =
          await service(game, transport, ids: ['root-id'], time: 77).sync();
      expect(result, isA<CloudSyncUploaded>());
      final uploaded = decode(transport.commits.single);
      expect(uploaded.schemaVersion, 2);
      expect(uploaded.revision, 0);
      expect(uploaded.revisionId, 'root-id');
      expect(uploaded.parentRevisionId, isNull);
      expect(uploaded.mergeParentRevisionIds, isEmpty);
      expect(uploaded.resetGeneration, reset ? 2 : 0);
      expect(uploaded.updatedAtUtcMs, 77);
      expect(game.cloudRevisionId, 'root-id');
      expect(game.cloudDirty, isFalse);
    }
  });

  test('default revision IDs are 128-bit lower-case hexadecimal', () async {
    final game = await state()
      ..coins = 1
      ..cloudDirty = true;
    final transport = _FakeTransport();
    expect(
      await CloudSaveService(state: game, transport: transport).sync(),
      isA<CloudSyncUploaded>(),
    );
    expect(
      decode(transport.commits.single).revisionId,
      matches(RegExp(r'^[0-9a-f]{32}$')),
    );
  });

  test('strict decoding distinguishes malformed, future, v1, and v2', () async {
    final malformedCases = <Uint8List, Matcher>{
      Uint8List.fromList([0xff]): isA<CloudSyncMalformedCloudDocument>(),
      Uint8List.fromList(utf8.encode('{')):
          isA<CloudSyncMalformedCloudDocument>(),
      Uint8List.fromList(utf8.encode(jsonEncode({
        ...document().toJson(),
        'schemaVersion': 3,
      }))): isA<CloudSyncUnsupportedSchema>(),
    };
    for (final entry in malformedCases.entries) {
      final game = await state();
      final result = await service(
        game,
        _FakeTransport()..openResult = SavedGamesOpenedData(entry.key),
        ids: ['unused'],
      ).sync();
      expect(result, entry.value);
      expect(game.cloudRevisionId, isNull);
    }

    final v1 = Uint8List.fromList(utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'revision': 4,
      'revisionId': 'v1',
      'parentRevisionId': 'older',
      'resetGeneration': 0,
      'updatedAtUtcMs': 1,
      'progress': progress(coins: 4).toJson(),
    })));
    final merge = bytes(document(
      revision: 9,
      id: 'merge',
      mergeParents: const ['a', 'b'],
      value: progress(coins: 9),
    ));
    for (final entry in [(v1, 'v1', 4), (merge, 'merge', 9)]) {
      final game = await state();
      final result = await service(
        game,
        _FakeTransport()..openResult = SavedGamesOpenedData(entry.$1),
        ids: ['unused'],
      ).sync();
      expect(result, isA<CloudSyncRestoredFromCloud>());
      expect(game.coins, entry.$3);
      expect(game.cloudRevisionId, entry.$2);
    }
  });

  test('clean root, linear, and merge heads preserve exact lineage on upload',
      () async {
    final heads = [
      document(revision: 2, id: 'root', reset: 1, value: progress(coins: 2)),
      document(
        revision: 3,
        id: 'linear',
        parent: 'root',
        reset: 1,
        value: progress(coins: 3),
      ),
      document(
        revision: 4,
        id: 'merge',
        mergeParents: const ['left', 'right'],
        reset: 1,
        value: progress(coins: 4),
      ),
    ];
    for (final head in heads) {
      final game = await state();
      expect(
        await game.acceptCloudProgressDocument(head, importProgress: true),
        isTrue,
      );
      final transport = _FakeTransport()
        ..openResult = SavedGamesOpenedData(bytes(document(
          id: 'stale',
          reset: 0,
          value: progress(coins: 99),
        )));
      expect(
        await service(game, transport, ids: ['unused'], time: 88).sync(),
        isA<CloudSyncUploaded>(),
      );
      final uploaded = decode(transport.commits.single);
      expect(uploaded.revision, head.revision);
      expect(uploaded.revisionId, head.revisionId);
      expect(uploaded.parentRevisionId, head.parentRevisionId);
      expect(uploaded.mergeParentRevisionIds, head.mergeParentRevisionIds);
      expect(uploaded.progress, head.progress);
      expect(uploaded.updatedAtUtcMs, 0);
    }
  });

  test('dirty children and legacy unknown revisions use recovered ancestry',
      () async {
    final game = await state();
    final accepted = document(
      revision: 7,
      id: 'accepted',
      mergeParents: const ['old-a', 'old-b'],
      value: progress(coins: 1),
    );
    await game.acceptCloudProgressDocument(accepted, importProgress: true);
    game
      ..coins = 2
      ..cloudDirty = true;
    final transport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(accepted));
    expect(
      await service(game, transport, ids: ['child'], time: 55).sync(),
      isA<CloudSyncUploaded>(),
    );
    final child = decode(transport.commits.single);
    expect(child.revision, 8);
    expect(child.parentRevisionId, 'accepted');
    expect(child.mergeParentRevisionIds, isEmpty);
    expect(child.revisionId, 'child');
    expect(child.updatedAtUtcMs, 55);

    final legacy = await state()
      ..cloudRevisionId = 'legacy'
      ..cloudRevision = null
      ..coins = 3
      ..cloudDirty = true;
    final legacyTransport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(document(
        revision: 12,
        id: 'legacy',
        value: progress(coins: 1),
      )));
    expect(
      await service(legacy, legacyTransport, ids: ['legacy-child']).sync(),
      isA<CloudSyncUploaded>(),
    );
    final recovered = decode(legacyTransport.commits.single);
    expect(recovered.revision, 13);
    expect(recovered.parentRevisionId, 'legacy');

    final unknown = await state()
      ..cloudRevisionId = 'missing'
      ..cloudRevision = null;
    final unknownTransport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(document(id: 'other')));
    expect(
      await service(unknown, unknownTransport, ids: ['unused']).sync(),
      isA<CloudSyncUnknownLocalRevision>(),
    );
    expect(unknownTransport.commits, isEmpty);

    final invalid = await state()
      ..cloudRevision = 1;
    final invalidTransport = _FakeTransport();
    expect(
      await service(invalid, invalidTransport, ids: ['unused']).sync(),
      isA<CloudSyncInvalidLocalMetadata>(),
    );
    expect(invalidTransport.opens, 0);
  });

  test('ordinary policy decisions adopt, restore, reset, and reject lineage',
      () async {
    final sameGame = await state();
    await sameGame.acceptCloudProgressDocument(
      document(revision: 1, id: 'local', value: progress(coins: 4)),
      importProgress: true,
    );
    var generated = 0;
    final sameTransport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(document(
        revision: 99,
        id: 'cloud',
        value: progress(coins: 4),
      )));
    final sameResult = await CloudSaveService(
      state: sameGame,
      transport: sameTransport,
      revisionIdGenerator: () {
        generated++;
        return 'unused';
      },
    ).sync();
    expect(sameResult, isA<CloudSyncNoChange>());
    expect(generated, 0);
    expect(sameGame.cloudRevisionId, 'cloud');
    expect(sameTransport.commits, isEmpty);

    final descendantGame = await state();
    await descendantGame.acceptCloudProgressDocument(
      document(revision: 1, id: 'base', value: progress(coins: 1)),
      importProgress: true,
    );
    final descendantTransport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(document(
        revision: 2,
        id: 'child',
        parent: 'base',
        value: progress(coins: 2),
      )));
    expect(
      await service(descendantGame, descendantTransport, ids: ['unused'])
          .sync(),
      isA<CloudSyncRestoredFromCloud>(),
    );
    expect(descendantGame.coins, 2);

    final localReset = await state()
      ..cloudResetGeneration = 2
      ..cloudDirty = true;
    final localResetTransport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(document(
        revision: 50,
        id: 'old',
        reset: 1,
        value: progress(coins: 50),
      )));
    expect(
      await service(localReset, localResetTransport, ids: ['reset']).sync(),
      isA<CloudSyncUploaded>(),
    );
    expect(decode(localResetTransport.commits.single).progress,
        CloudProgress.empty());

    final invalidGame = await state();
    await invalidGame.acceptCloudProgressDocument(
      document(id: 'same', value: progress(coins: 1)),
      importProgress: true,
    );
    final invalidResult = await service(
      invalidGame,
      _FakeTransport()
        ..openResult = SavedGamesOpenedData(
          bytes(document(id: 'same', value: progress(coins: 2))),
        ),
      ids: ['unused'],
    ).sync();
    expect(invalidResult, isA<CloudSyncInvalidLineage>());
  });

  test('automatic merge uses the exact policy plan and imports safe fields',
      () async {
    final game = await state();
    await game.acceptCloudProgressDocument(
      document(
        revision: 3,
        id: 'a',
        value: progress(games: 1, achievement: 'first_win'),
      ),
      importProgress: true,
    );
    final transport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(bytes(document(
        revision: 5,
        id: 'b',
        value: progress(games: 2, achievement: 'speed_demon'),
      )));
    expect(
      await service(game, transport, ids: ['merged'], time: 99).sync(),
      isA<CloudSyncAutomaticallyMerged>(),
    );
    final merged = decode(transport.commits.single);
    expect(merged.schemaVersion, 2);
    expect(merged.revision, 6);
    expect(merged.parentRevisionId, isNull);
    expect(merged.mergeParentRevisionIds, ['a', 'b']);
    expect(merged.revisionId, 'merged');
    expect(merged.updatedAtUtcMs, 99);
    expect(game.gamesPlayed, 2);
    expect(game.achievements['first_win'], isTrue);
    expect(game.achievements['speed_demon'], isTrue);
    expect(game.cloudRevision, 6);
    expect(game.cloudMergeParentRevisionIds, ['a', 'b']);
  });

  test('both ordinary choices create one new merge from the same policy plan',
      () async {
    for (final choice in [
      CloudSyncChoice.keepThisDevice,
      CloudSyncChoice.useCloud,
    ]) {
      final game = await state();
      await game.acceptCloudProgressDocument(
        document(
          revision: 3,
          id: 'local',
          value: progress(coins: 10, games: 1),
        ),
        importProgress: true,
      );
      final transport = _FakeTransport()
        ..openResult = SavedGamesOpenedData(bytes(document(
          revision: 5,
          id: 'cloud',
          value: progress(coins: 20, games: 2),
        )));
      final cloudService =
          service(game, transport, ids: ['choice-id'], time: 70);
      final pending = await cloudService.sync();
      expect(pending, isA<CloudSyncDeviceCloudChoice>());
      expect(transport.commits, isEmpty);
      final result = await cloudService.resolveUserChoice(
        pending as CloudSyncNeedsUserChoice,
        choice,
      );
      expect(result, isA<CloudSyncUserChoiceMerged>());
      final merged = decode(transport.commits.single);
      expect(merged.revision, 6);
      expect(merged.mergeParentRevisionIds, ['cloud', 'local']);
      expect(merged.revisionId, 'choice-id');
      expect(merged.progress.coins,
          choice == CloudSyncChoice.keepThisDevice ? 10 : 20);
      expect(merged.progress.gamesPlayed, 2);
      expect(game.exportCloudProgress(), merged.progress);
    }
  });

  test('local basis guards open, pending resolution, and successful commit',
      () async {
    final duringOpen = await state();
    await duringOpen.acceptCloudProgressDocument(
      document(id: 'base'),
      importProgress: true,
    );
    final openTransport = _FakeTransport()
      ..onOpen = () {
        duringOpen
          ..coins = 1
          ..cloudDirty = true;
        return SavedGamesOpenedData(bytes(document(id: 'base')));
      };
    expect(
      await service(duringOpen, openTransport, ids: ['unused']).sync(),
      isA<CloudSyncChangedLocalState>(),
    );
    expect(openTransport.commits, isEmpty);

    final pendingGame = await state();
    await pendingGame.acceptCloudProgressDocument(
      document(id: 'local', value: progress(coins: 1)),
      importProgress: true,
    );
    final pendingTransport = _FakeTransport()
      ..openResult = SavedGamesOpenedData(
        bytes(document(id: 'cloud', value: progress(coins: 2))),
      );
    final pendingService =
        service(pendingGame, pendingTransport, ids: ['unused']);
    final pending = await pendingService.sync() as CloudSyncDeviceCloudChoice;
    pendingGame
      ..coins = 3
      ..cloudDirty = true;
    expect(
      await pendingService.resolveUserChoice(
        pending,
        CloudSyncChoice.keepThisDevice,
      ),
      isA<CloudSyncChangedLocalState>(),
    );
    expect(pendingTransport.commits, isEmpty);

    final duringCommit = await state()
      ..coins = 1
      ..cloudDirty = true;
    final commitTransport = _FakeTransport()
      ..onCommit = (_) {
        duringCommit.coins = 2;
        return SavedGamesCommitted();
      };
    expect(
      await service(duringCommit, commitTransport, ids: ['remote']).sync(),
      isA<CloudSyncChangedLocalState>(),
    );
    expect(commitTransport.commits, hasLength(1));
    expect(duringCommit.cloudRevisionId, isNull);
    expect(duringCommit.cloudDirty, isTrue);
  });

  test('commit and local persistence failures never claim success', () async {
    for (final result in <SavedGamesCommitResult>[
      SavedGamesTransportFailure(SavedGamesTransportError.commitFailed),
      SavedGamesConflict(
        handle: 'new',
        snapshotBytes: Uint8List(0),
        conflictingSnapshotBytes: Uint8List(0),
      ),
    ]) {
      final game = await state()
        ..coins = 1
        ..cloudDirty = true;
      final transport = _FakeTransport()..commitResult = result;
      final syncResult =
          await service(game, transport, ids: ['discarded']).sync();
      expect(
        syncResult,
        result is SavedGamesConflict
            ? isA<CloudSyncRepeatedConflict>()
            : isA<CloudSyncTransportFailure>(),
      );
      expect(game.cloudRevisionId, isNull);
      expect(game.cloudDirty, isTrue);
    }

    final rejecting = await state(rejectAcceptance: true)
      ..coins = 1
      ..cloudDirty = true;
    final result =
        await service(rejecting, _FakeTransport(), ids: ['remote']).sync();
    expect(result, isA<CloudSyncLocalPersistenceFailure>());
    expect(rejecting.cloudRevisionId, isNull);
    expect(rejecting.cloudDirty, isTrue);
  });

  test('native direct and equal winners resolve exact existing bytes',
      () async {
    final primary = bytes(document(
      revision: 1,
      id: 'primary',
      value: progress(coins: 1),
    ));
    final child = bytes(document(
      revision: 2,
      id: 'child',
      parent: 'primary',
      value: progress(coins: 2),
    ));
    final equal = bytes(document(
      revision: 99,
      id: 'equal',
      value: progress(coins: 1),
    ));
    for (final entry in [
      (primary, child, child),
      (child, primary, child),
      (primary, equal, primary),
    ]) {
      final game = await state();
      final transport = _FakeTransport()
        ..openResult = SavedGamesConflict(
          handle: 'handle',
          snapshotBytes: entry.$1,
          conflictingSnapshotBytes: entry.$2,
        );
      expect(
        await service(game, transport, ids: ['unused']).sync(),
        isA<CloudSyncNativeConflictResolvedResyncRequired>(),
      );
      expect(transport.resolves.single.$1, 'handle');
      expect(transport.resolves.single.$2, entry.$3);
      expect(game.cloudRevisionId, isNull);
    }
  });

  test('native merge obeys three-history safety and requires later resync',
      () async {
    final game = await state()
      ..coins = 99
      ..cloudDirty = true;
    final before = game.exportCloudProgress();
    final transport = _FakeTransport()
      ..openResult = SavedGamesConflict(
        handle: 'handle',
        snapshotBytes: bytes(document(
          revision: 3,
          id: 'a',
          value: progress(games: 1, achievement: 'first_win'),
        )),
        conflictingSnapshotBytes: bytes(document(
          revision: 5,
          id: 'b',
          value: progress(games: 2, achievement: 'speed_demon'),
        )),
      );
    final cloudService = service(
      game,
      transport,
      ids: ['native-merge', 'local-root'],
      time: 44,
    );
    expect(
      await cloudService.sync(),
      isA<CloudSyncNativeConflictResolvedResyncRequired>(),
    );
    final merged = decode(transport.resolves.single.$2);
    expect(merged.revision, 6);
    expect(merged.mergeParentRevisionIds, ['a', 'b']);
    expect(merged.revisionId, 'native-merge');
    expect(game.exportCloudProgress(), before);
    expect(game.cloudDirty, isTrue);
    expect(game.cloudRevisionId, isNull);

    transport.openResult = SavedGamesOpenedData(bytes(merged));
    expect(await cloudService.sync(), isA<CloudSyncNeedsUserChoice>());
  });

  test('native unsafe choices, malformed sides, stale handles, and repeats',
      () async {
    final game = await state();
    final transport = _FakeTransport()
      ..openResult = SavedGamesConflict(
        handle: 'handle',
        snapshotBytes: bytes(document(
          revision: 2,
          id: 'a',
          value: progress(coins: 1, games: 1),
        )),
        conflictingSnapshotBytes: bytes(document(
          revision: 4,
          id: 'b',
          value: progress(coins: 2, games: 2),
        )),
      );
    final cloudService = service(game, transport, ids: ['native-choice']);
    final pending = await cloudService.sync();
    expect(pending, isA<CloudSyncNativeCloudChoice>());
    expect(transport.resolves, isEmpty);
    expect(
      await cloudService.resolveUserChoice(
        pending as CloudSyncNeedsUserChoice,
        CloudSyncChoice.conflictingCloud,
      ),
      isA<CloudSyncNativeConflictResolvedResyncRequired>(),
    );
    final chosen = decode(transport.resolves.single.$2);
    expect(chosen.revision, 5);
    expect(chosen.mergeParentRevisionIds, ['a', 'b']);
    expect(chosen.progress.coins, 2);
    expect(game.cloudRevisionId, isNull);

    for (final rejected in [
      (
        Uint8List.fromList([0xff]),
        isA<CloudSyncMalformedCloudDocument>(),
      ),
      (
        Uint8List.fromList(utf8.encode(jsonEncode({
          ...document().toJson(),
          'schemaVersion': 0,
        }))),
        isA<CloudSyncUnsupportedSchema>(),
      ),
    ]) {
      final rejectedTransport = _FakeTransport()
        ..openResult = SavedGamesConflict(
          handle: 'bad',
          snapshotBytes: rejected.$1,
          conflictingSnapshotBytes: bytes(document()),
        );
      expect(
        await service(
          await state(),
          rejectedTransport,
          ids: ['unused'],
        ).sync(),
        rejected.$2,
      );
      expect(rejectedTransport.resolves, isEmpty);
    }

    for (final resolveResult in <SavedGamesResolveResult>[
      SavedGamesTransportFailure(
        SavedGamesTransportError.staleConflictHandle,
      ),
      SavedGamesConflict(
        handle: 'again',
        snapshotBytes: Uint8List(0),
        conflictingSnapshotBytes: Uint8List(0),
      ),
    ]) {
      final retryGame = await state();
      final retryTransport = _FakeTransport()
        ..openResult = SavedGamesConflict(
          handle: 'handle',
          snapshotBytes: bytes(document(id: 'same')),
          conflictingSnapshotBytes: bytes(document(id: 'other')),
        )
        ..resolveResult = resolveResult;
      final result =
          await service(retryGame, retryTransport, ids: ['unused']).sync();
      expect(
        result,
        resolveResult is SavedGamesConflict
            ? isA<CloudSyncRepeatedConflict>()
            : isA<CloudSyncStaleConflict>(),
      );
      expect(retryTransport.resolves, hasLength(1));
    }
  });
}

Uint8List bytes(CloudProgressDocument document) =>
    Uint8List.fromList(utf8.encode(document.encode()));

CloudProgressDocument decode(Uint8List source) =>
    CloudProgressDocument.decode(utf8.decode(source)).document!;

final class _FakeTransport implements SavedGamesTransport {
  SavedGamesOpenResult openResult = SavedGamesOpenedEmpty();
  SavedGamesCommitResult commitResult = SavedGamesCommitted();
  SavedGamesResolveResult resolveResult = SavedGamesResolved();
  FutureOr<SavedGamesOpenResult> Function()? onOpen;
  FutureOr<SavedGamesCommitResult> Function(Uint8List bytes)? onCommit;
  final commits = <Uint8List>[];
  final resolves = <(String, Uint8List)>[];
  int opens = 0;

  @override
  Future<SavedGamesOpenResult> open() async {
    opens++;
    return await (onOpen?.call() ?? openResult);
  }

  @override
  Future<SavedGamesCommitResult> commit(Uint8List bytes) async {
    commits.add(bytes);
    return await (onCommit?.call(bytes) ?? commitResult);
  }

  @override
  Future<SavedGamesResolveResult> resolve(
    String handle,
    Uint8List bytes,
  ) async {
    resolves.add((handle, bytes));
    return resolveResult;
  }
}

final class _RejectingGameState extends GameState {
  _RejectingGameState(SettingsService settings, AudioService audio)
      : super(settings: settings, audio: audio);

  @override
  Future<bool> acceptCloudProgressDocument(
    CloudProgressDocument document, {
    required bool importProgress,
  }) async =>
      false;
}
