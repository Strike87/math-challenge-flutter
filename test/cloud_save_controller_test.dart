import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_controller.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/play_games.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  ({CloudSaveController controller, GameState state}) makeController(
    _Transport transport, {
    Future<void>? localLoad,
    _PlayGames? playGames,
  }) {
    final settings = SettingsService();
    final state = GameState(
      settings: settings,
      audio: AudioService(settings),
      playGamesService: playGames,
    );
    return (
      controller: CloudSaveController(
        state: state,
        localLoad: localLoad ?? Future.value(),
        service: CloudSaveService(state: state, transport: transport),
      ),
      state: state,
    );
  }

  test('maps synthetic transport failures and malformed documents', () async {
    for (final open in [
      SavedGamesTransportFailure(SavedGamesTransportError.unavailable),
      SavedGamesOpenedData(Uint8List.fromList([0xff])),
    ]) {
      final result = makeController(_Transport()..openResult = open).controller;
      await result.sync();
      expect(
          result.status,
          open is SavedGamesTransportFailure
              ? CloudSaveStatus.offlineOrTransportFailure
              : CloudSaveStatus.requiresAttention);
    }
  });

  test('maps no-change and restore results through the real service', () async {
    final unchanged = makeController(_Transport());
    await unchanged.state.load();
    await unchanged.controller.sync();
    expect(unchanged.controller.status, CloudSaveStatus.upToDate);

    final restored = makeController(_Transport()
      ..openResult = SavedGamesOpenedData(_bytes(
        _document(id: 'cloud', revision: 1, progress: _progress(7, 1)),
      )));
    await restored.state.load();
    await restored.controller.sync();
    expect(restored.controller.status, CloudSaveStatus.restoredFromCloud);
    expect(restored.state.coins, 7);
  });

  test('maps automatic merge and invalid metadata attention', () async {
    final pair = makeController(_Transport());
    await pair.state.acceptCloudProgressDocument(
      _document(
          id: 'local', revision: 3, progress: _progress(0, 1, 'first_win')),
      importProgress: true,
    );
    final mergedTransport = _Transport()
      ..openResult = SavedGamesOpenedData(_bytes(
        _document(
            id: 'cloud', revision: 5, progress: _progress(0, 2, 'speed_demon')),
      ));
    final merged = CloudSaveController(
      state: pair.state,
      localLoad: Future.value(),
      service: CloudSaveService(state: pair.state, transport: mergedTransport),
    );
    await merged.sync();
    expect(merged.status, CloudSaveStatus.automaticallyMerged);

    final invalid = makeController(_Transport());
    invalid.state.cloudRevisionId = 'orphan';
    await invalid.controller.sync();
    expect(invalid.controller.status, CloudSaveStatus.requiresAttention);
  });

  test('startup and manual sync share one operation while local load waits',
      () async {
    final localLoad = Completer<void>();
    final playGames = _PlayGames()..authenticated = true;
    final transport = _Transport();
    final result = makeController(
      transport,
      localLoad: localLoad.future,
      playGames: playGames,
    ).controller;

    final first = result.startAfterFirstFrame();
    final manual = result.sync();
    expect(result.isBusy, isTrue);
    expect(playGames.checks, 0);
    localLoad.complete();
    await Future.wait([first, manual]);

    expect(result.startupAttempted, isTrue);
    expect(playGames.checks, 1);
    expect(playGames.connects, 0);
    expect(transport.opens, 1);
    expect(result.status, CloudSaveStatus.uploaded);
  });

  test('unauthenticated startup does not sync', () async {
    final transport = _Transport();
    final result =
        makeController(transport, playGames: _PlayGames()).controller;

    await result.startAfterFirstFrame();

    expect(transport.opens, 0);
    expect(result.status, CloudSaveStatus.notAuthenticated);
  });

  test('coalesces listener-triggered sync calls before the service completes',
      () async {
    final transport = _Transport()
      ..openGate = Completer<SavedGamesOpenResult>();
    final result = makeController(transport).controller;
    result.addListener(() {
      if (result.status == CloudSaveStatus.syncing) result.sync();
    });

    final first = result.sync();
    expect(result.status, CloudSaveStatus.syncing);
    expect(transport.opens, 1);
    transport.openGate!.complete(SavedGamesOpenedEmpty());
    await first;

    expect(transport.opens, 1);
  });

  test('dirty state is presentation-only while up to date', () async {
    final pair = makeController(_Transport());
    await pair.state.load();
    await pair.controller.sync();
    pair.state.cloudDirty = true;

    expect(
        pair.controller.effectiveStatus, CloudSaveStatus.changesPendingLocally);
    expect(pair.state.cloudDirty, isTrue);
  });

  test('real empty transport uploads an uninitialized GameState', () async {
    final settings = SettingsService();
    final state = GameState(settings: settings, audio: AudioService(settings));
    final result = CloudSaveController(
        state: state,
        localLoad: Future.value(),
        service: CloudSaveService(state: state, transport: _Transport()));

    await result.sync();

    expect(result.status, CloudSaveStatus.uploaded);
  });

  test('retains and resolves the exact ordinary pending continuation',
      () async {
    final pair = makeController(_Transport());
    final local =
        _document(id: 'local', revision: 3, progress: _progress(10, 1));
    await pair.state.acceptCloudProgressDocument(local, importProgress: true);
    final transport = _Transport()
      ..openResult = SavedGamesOpenedData(_bytes(
        _document(id: 'cloud', revision: 5, progress: _progress(20, 2)),
      ));
    final controller = CloudSaveController(
      state: pair.state,
      localLoad: Future.value(),
      service: CloudSaveService(state: pair.state, transport: transport),
    );

    await controller.sync();
    final pending = controller.pendingChoice;
    expect(controller.status, CloudSaveStatus.needsOrdinaryChoice);
    expect(pending, isA<CloudSyncDeviceCloudChoice>());
    await controller.resolvePendingChoice(CloudSyncChoice.keepThisDevice);

    expect(controller.pendingChoice, isNull);
    expect(controller.status, CloudSaveStatus.userChoiceResolved);
    expect(transport.commits, hasLength(1));
  });

  test('native choice follows up once and stops on a second resync', () async {
    final primary = _bytes(
        _document(id: 'primary', revision: 1, progress: _progress(1, 1)));
    final child = _bytes(_document(
        id: 'child',
        revision: 2,
        parent: 'primary',
        progress: _progress(2, 2)));
    final transport = _Transport()
      ..openResults.addAll([
        SavedGamesConflict(
            handle: 'choice',
            snapshotBytes: _bytes(
                _document(id: 'a', revision: 2, progress: _progress(1, 1))),
            conflictingSnapshotBytes: _bytes(
                _document(id: 'b', revision: 4, progress: _progress(2, 2)))),
        SavedGamesConflict(
            handle: 'follow-up',
            snapshotBytes: primary,
            conflictingSnapshotBytes: child),
      ]);
    final controller = makeController(transport).controller;

    await controller.sync();
    final pending = controller.pendingChoice;
    expect(controller.status, CloudSaveStatus.needsNativeCloudChoice);
    expect(pending, isA<CloudSyncNativeCloudChoice>());
    await controller.resolvePendingChoice(CloudSyncChoice.conflictingCloud);

    expect(controller.pendingChoice, isNull);
    expect(controller.status, CloudSaveStatus.resyncRequired);
    expect(transport.opens, 2);
    expect(transport.resolves, hasLength(2));
  });

  test('non-choice results supersede each pending kind and clear it', () async {
    final ordinary = makeController(_Transport());
    await ordinary.state.acceptCloudProgressDocument(
      _document(id: 'local', revision: 3, progress: _progress(1, 1)),
      importProgress: true,
    );
    final ordinaryTransport = _Transport()
      ..openResults.addAll([
        SavedGamesOpenedData(_bytes(
          _document(id: 'cloud', revision: 5, progress: _progress(2, 2)),
        )),
        SavedGamesOpenedData(_bytes(
          _document(id: 'local', revision: 3, progress: _progress(1, 1)),
        )),
      ]);
    final ordinaryController = CloudSaveController(
      state: ordinary.state,
      localLoad: Future.value(),
      service:
          CloudSaveService(state: ordinary.state, transport: ordinaryTransport),
    );
    await ordinaryController.sync();
    expect(ordinaryController.pendingChoice, isA<CloudSyncDeviceCloudChoice>());
    await ordinaryController.sync();
    expect(ordinaryController.status, CloudSaveStatus.upToDate);
    expect(ordinaryController.pendingChoice, isNull);

    final nativeTransport = _Transport()
      ..openResults.addAll([
        SavedGamesConflict(
          handle: 'choice',
          snapshotBytes: _bytes(
              _document(id: 'a', revision: 2, progress: _progress(1, 1))),
          conflictingSnapshotBytes: _bytes(
              _document(id: 'b', revision: 4, progress: _progress(2, 2))),
        ),
        SavedGamesOpenedEmpty(),
      ]);
    final nativeController = makeController(nativeTransport).controller;
    await nativeController.sync();
    expect(nativeController.pendingChoice, isA<CloudSyncNativeCloudChoice>());
    await nativeController.sync();
    expect(nativeController.status, CloudSaveStatus.uploaded);
    expect(nativeController.pendingChoice, isNull);
  });

  test('choice resolution retains exact pending identity and maps failures',
      () async {
    for (final resolution in <SavedGamesResolveResult>[
      SavedGamesTransportFailure(SavedGamesTransportError.staleConflictHandle),
      SavedGamesConflict(
        handle: 'again',
        snapshotBytes: Uint8List(0),
        conflictingSnapshotBytes: Uint8List(0),
      ),
    ]) {
      final transport = _Transport()
        ..openResult = SavedGamesConflict(
          handle: 'choice',
          snapshotBytes: _bytes(
              _document(id: 'a', revision: 2, progress: _progress(1, 1))),
          conflictingSnapshotBytes: _bytes(
              _document(id: 'b', revision: 4, progress: _progress(2, 2))),
        )
        ..resolveResult = resolution;
      final pair = makeController(transport);
      final service = _RecordingCloudSaveService(
        state: pair.state,
        transport: transport,
      );
      final controller = CloudSaveController(
        state: pair.state,
        localLoad: Future.value(),
        service: service,
      );
      await controller.sync();
      final pending = controller.pendingChoice!;
      await controller.resolvePendingChoice(CloudSyncChoice.primaryCloud);
      expect(identical(service.resolvedPending, pending), isTrue);
      expect(controller.pendingChoice, isNull);
      expect(controller.status, CloudSaveStatus.resyncRequired);
    }
  });

  test('maps every real non-choice service error and preserves cloud dirtiness',
      () async {
    final malformed = makeController(_Transport()
      ..openResult = SavedGamesOpenedData(Uint8List.fromList([0xff])));
    final unsupported = makeController(_Transport()
      ..openResult = SavedGamesOpenedData(Uint8List.fromList(utf8.encode(
        _document(id: 'schema', revision: 1, progress: _progress(0, 0))
            .encode()
            .replaceFirst('"schemaVersion":2', '"schemaVersion":0'),
      ))));
    final invalidLineage = makeController(_Transport());
    await invalidLineage.state.acceptCloudProgressDocument(
      _document(id: 'same', revision: 1, progress: _progress(1, 1)),
      importProgress: true,
    );
    final invalidLineageController = CloudSaveController(
      state: invalidLineage.state,
      localLoad: Future.value(),
      service: CloudSaveService(
        state: invalidLineage.state,
        transport: _Transport()
          ..openResult = SavedGamesOpenedData(_bytes(
            _document(id: 'same', revision: 1, progress: _progress(2, 2)),
          )),
      ),
    );
    final unknown = makeController(_Transport());
    unknown.state.cloudRevisionId = 'missing';
    final invalidMetadata = makeController(_Transport());
    invalidMetadata.state.cloudRevision = 1;
    final cases = <(CloudSaveController, CloudSaveStatus)>[
      (malformed.controller, CloudSaveStatus.requiresAttention),
      (unsupported.controller, CloudSaveStatus.requiresAttention),
      (invalidLineageController, CloudSaveStatus.requiresAttention),
      (unknown.controller, CloudSaveStatus.requiresAttention),
      (invalidMetadata.controller, CloudSaveStatus.requiresAttention),
      (
        makeController(_Transport()
              ..openResult = SavedGamesTransportFailure(
                  SavedGamesTransportError.openFailed))
            .controller,
        CloudSaveStatus.offlineOrTransportFailure,
      ),
    ];
    for (final entry in cases) {
      await entry.$1.sync();
      expect(entry.$1.status, entry.$2);
      expect(entry.$1.pendingChoice, isNull);
    }

    final changed = makeController(_Transport());
    await changed.state.acceptCloudProgressDocument(
      _document(id: 'local', revision: 1, progress: _progress(1, 1)),
      importProgress: true,
    );
    final changedTransport = _Transport()
      ..openResult = SavedGamesOpenedData(_bytes(
        _document(id: 'cloud', revision: 2, progress: _progress(2, 2)),
      ));
    final changedController = CloudSaveController(
      state: changed.state,
      localLoad: Future.value(),
      service:
          CloudSaveService(state: changed.state, transport: changedTransport),
    );
    await changedController.sync();
    final pending = changedController.pendingChoice;
    changed.state
      ..coins = 3
      ..cloudDirty = true;
    await changedController
        .resolvePendingChoice(CloudSyncChoice.keepThisDevice);
    expect(pending, isNotNull);
    expect(changedController.status, CloudSaveStatus.changedLocalState);
    expect(changedController.pendingChoice, isNull);
    expect(changed.state.cloudDirty, isTrue);
  });

  test('maps real local persistence failure to requires attention', () async {
    final settings = SettingsService();
    final state =
        _RejectingGameState(settings: settings, audio: AudioService(settings))
          ..coins = 1
          ..cloudDirty = true;
    final controller = CloudSaveController(
      state: state,
      localLoad: Future.value(),
      service: CloudSaveService(state: state, transport: _Transport()),
    );

    await controller.sync();

    expect(controller.status, CloudSaveStatus.requiresAttention);
    expect(state.cloudDirty, isTrue);
  });
}

CloudProgress _progress(int coins, int games, [String? achievement]) {
  final empty = CloudProgress.empty();
  return CloudProgress(
    coins: coins,
    gamesPlayed: games,
    achievements: {
      ...empty.achievements,
      if (achievement != null) achievement: true
    },
    operationQuestStars: empty.operationQuestStars,
    highScores: empty.highScores,
    skillMap: empty.skillMap,
    profile: empty.profile,
    economy: empty.economy,
  );
}

CloudProgressDocument _document({
  required String id,
  required int revision,
  required CloudProgress progress,
  String? parent,
}) =>
    CloudProgressDocument(
      schemaVersion: 2,
      revision: revision,
      revisionId: id,
      parentRevisionId: parent,
      mergeParentRevisionIds: const [],
      resetGeneration: 0,
      updatedAtUtcMs: 1,
      progress: progress,
    );

Uint8List _bytes(CloudProgressDocument document) =>
    Uint8List.fromList(utf8.encode(document.encode()));

class _Transport implements SavedGamesTransport {
  SavedGamesOpenResult openResult = SavedGamesOpenedEmpty();
  Completer<SavedGamesOpenResult>? openGate;
  int opens = 0;
  final commits = <Uint8List>[];
  final resolves = <(String, Uint8List)>[];
  final openResults = <SavedGamesOpenResult>[];
  SavedGamesCommitResult commitResult = SavedGamesCommitted();
  SavedGamesResolveResult resolveResult = SavedGamesResolved();
  @override
  Future<SavedGamesOpenResult> open() {
    opens++;
    return openGate?.future ??
        Future.value(
            openResults.isEmpty ? openResult : openResults.removeAt(0));
  }

  @override
  Future<SavedGamesCommitResult> commit(Uint8List bytes) {
    commits.add(bytes);
    return Future.value(commitResult);
  }

  @override
  Future<SavedGamesResolveResult> resolve(String handle, Uint8List bytes) {
    resolves.add((handle, bytes));
    return Future.value(resolveResult);
  }
}

class _RecordingCloudSaveService extends CloudSaveService {
  _RecordingCloudSaveService({required super.state, required super.transport});

  CloudSyncNeedsUserChoice? resolvedPending;

  @override
  Future<CloudSyncResult> resolveUserChoice(
    CloudSyncNeedsUserChoice pending,
    CloudSyncChoice choice,
  ) {
    resolvedPending = pending;
    return super.resolveUserChoice(pending, choice);
  }
}

class _RejectingGameState extends GameState {
  _RejectingGameState({required super.settings, required super.audio});

  @override
  Future<bool> acceptCloudProgressDocument(
    CloudProgressDocument document, {
    required bool importProgress,
  }) async =>
      false;
}

class _PlayGames extends PlayGamesService {
  int checks = 0;
  int connects = 0;
  bool authenticated = false;

  @override
  Future<bool> isAuthenticated() async {
    checks++;
    return authenticated;
  }

  @override
  Future<bool> connect() async {
    connects++;
    return false;
  }

  @override
  Future<void> unlockAchievement(String localAchievementId) async {}
}
