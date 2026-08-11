import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_controller.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
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
    SharedPreferences.setMockInitialValues({
      GameState.familyGateVersionStorageKey: GameState.familyGateSchemaVersion,
      GameState.familyAgeRangeStorageKey: FamilyAgeRange.adult18plus.name,
    });
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
    )..familyEligibility = FamilyEligibility.eligible;
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

  test('reset wins over startup still waiting to sync', () async {
    final transport = _Transport();
    final authenticated = Completer<bool>();
    final playGames = _PlayGames()..authenticationGate = authenticated;
    final pair = makeController(
      transport,
      playGames: playGames,
    );
    final startup = pair.controller.startAfterFirstFrame();
    await Future<void>.delayed(Duration.zero);
    expect(playGames.checks, 1);
    final reset = pair.controller.resetEverywhere();

    authenticated.complete(true);
    await Future.wait([startup, reset]);

    expect(transport.opens, 1);
    expect(pair.state.cloudResetGeneration, 1);
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
    final state = GameState(settings: settings, audio: AudioService(settings))
      ..familyEligibility = FamilyEligibility.eligible;
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

  test('ordinary use-cloud resolution coalesces through the controller',
      () async {
    final pair = makeController(_Transport());
    await pair.state.acceptCloudProgressDocument(
      _document(id: 'local', revision: 3, progress: _progress(10, 1)),
      importProgress: true,
    );
    final transport = _Transport()
      ..openResult = SavedGamesOpenedData(_bytes(
        _document(id: 'cloud', revision: 5, progress: _progress(20, 2)),
      ));
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
    await Future.wait([
      controller.resolvePendingChoice(CloudSyncChoice.useCloud),
      controller.resolvePendingChoice(CloudSyncChoice.useCloud),
    ]);

    expect(identical(service.resolvedPending, pending), isTrue);
    expect(service.resolveCalls, 1);
    expect(service.resolvedChoice, CloudSyncChoice.useCloud);
    expect(pair.state.coins, 20);
    expect(pair.state.gamesPlayed, 2);
    expect(controller.pendingChoice, isNull);
    expect(controller.status, CloudSaveStatus.userChoiceResolved);
  });

  test('native Version 1 and Version 2 coalesce with one follow-up sync',
      () async {
    for (final choice in [
      CloudSyncChoice.primaryCloud,
      CloudSyncChoice.conflictingCloud,
    ]) {
      final transport = _Transport()
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
      await Future.wait([
        controller.resolvePendingChoice(choice),
        controller.resolvePendingChoice(choice),
      ]);

      expect(identical(service.resolvedPending, pending), isTrue);
      expect(service.resolveCalls, 1);
      expect(service.resolvedChoice, choice);
      expect(transport.resolves, hasLength(1));
      expect(transport.opens, 2);
      expect(controller.pendingChoice, isNull);
      expect(controller.status, CloudSaveStatus.uploaded);
    }
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
          ..familyEligibility = FamilyEligibility.eligible
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

  test('settings sync is allowed only from an inactive menu', () async {
    final pair = makeController(_Transport());
    expect(pair.controller.canSyncFromSettings, isTrue);
    pair.state.currentScreen = GameScreen.game;
    expect(pair.controller.canSyncFromSettings, isFalse);
    pair.state.currentScreen = GameScreen.menu;
    pair.state.rt.gameActive = true;
    expect(pair.controller.canSyncFromSettings, isFalse);
  });

  test('settings manual sync protects unsafe and pending state', () async {
    final transport = _Transport();
    final pair = makeController(transport);
    pair.state
      ..playGamesConnectionState = PlayGamesConnectionState.connected
      ..cloudDirty = true
      ..currentScreen = GameScreen.game;
    await pair.controller.syncFromSettings();
    expect(transport.opens, 0);
    expect(pair.state.cloudDirty, isTrue);

    pair.state.currentScreen = GameScreen.menu;
    await pair.controller.syncFromSettings();
    final pending = pair.controller.pendingChoice;
    expect(transport.opens, 1);
    if (pending != null) {
      await pair.controller.syncFromSettings();
      expect(identical(pair.controller.pendingChoice, pending), isTrue);
    }
  });

  test('connect then sync coalesces and defers unsafe sync', () async {
    final playGames = _PlayGames()..connectResult = true;
    final transport = _Transport();
    final pair = makeController(transport, playGames: playGames);
    await Future.wait([
      pair.controller.connectThenSync(),
      pair.controller.syncFromSettings(),
    ]);
    expect(playGames.connects, 1);
    expect(transport.opens, 1);

    final unsafe = makeController(_Transport(),
        playGames: _PlayGames()..connectResult = true);
    unsafe.state.rt.gameActive = true;
    await unsafe.controller.connectThenSync();
    expect(unsafe.state.playGamesConnectionState,
        PlayGamesConnectionState.connected);
  });

  test('failed connect does not sync or mutate local cloud state', () async {
    final playGames = _PlayGames();
    final transport = _Transport();
    final pair = makeController(transport, playGames: playGames);
    pair.state
      ..coins = 9
      ..cloudDirty = true;
    await pair.controller.connectThenSync();
    expect(playGames.connects, 1);
    expect(transport.opens, 0);
    expect(pair.controller.status, CloudSaveStatus.notAuthenticated);
    expect(pair.state.coins, 9);
    expect(pair.state.cloudDirty, isTrue);
  });

  test('post-connect sync waits for connection and reconciles once', () async {
    final gate = Completer<bool>();
    final playGames = _PlayGames()
      ..connectGate = gate
      ..connectResult = true;
    final transport = _Transport();
    final pair = makeController(transport, playGames: playGames);
    pair.state.achievements['first_win'] = true;
    final operation = pair.controller.connectThenSync();
    await Future<void>.delayed(Duration.zero);
    expect(playGames.connects, 1);
    expect(transport.opens, 0);
    gate.complete(true);
    await operation;
    expect(playGames.unlocked, ['first_win']);
    expect(transport.opens, 1);
  });

  test('ordinary and native pending choices block manual and post-connect sync',
      () async {
    ({
      CloudSyncNeedsUserChoice? pending,
      CloudSaveStatus status,
      bool dirty,
      int coins,
      int games,
      int? revision,
      String? revisionId,
      String? parentId,
      List<String> mergeParents,
      int opens,
    }) baseline(({CloudSaveController controller, GameState state}) pair,
            _Transport transport) =>
        (
          pending: pair.controller.pendingChoice,
          status: pair.controller.status,
          dirty: pair.state.cloudDirty,
          coins: pair.state.coins,
          games: pair.state.gamesPlayed,
          revision: pair.state.cloudRevision,
          revisionId: pair.state.cloudRevisionId,
          parentId: pair.state.cloudParentRevisionId,
          mergeParents: pair.state.cloudMergeParentRevisionIds,
          opens: transport.opens,
        );
    final ordinaryTransport = _Transport()
      ..openResult = SavedGamesOpenedData(_bytes(
        _document(id: 'cloud', revision: 5, progress: _progress(20, 2)),
      ));
    final ordinary = makeController(ordinaryTransport,
        playGames: _PlayGames()..connectResult = true);
    await ordinary.state.acceptCloudProgressDocument(
      _document(id: 'local', revision: 3, progress: _progress(10, 1)),
      importProgress: true,
    );
    ordinary.state.cloudDirty = true;
    await ordinary.controller.sync();
    final ordinaryBaseline = baseline(ordinary, ordinaryTransport);
    final ordinaryProgress = _cloudSnapshot(ordinary.state);
    final ordinaryPending = ordinaryBaseline.pending;
    expect(ordinaryPending, isA<CloudSyncDeviceCloudChoice>());
    await ordinary.controller.syncFromSettings();
    await ordinary.controller.connectThenSync();
    expect(ordinaryTransport.opens, ordinaryBaseline.opens);
    expect(
        identical(ordinary.controller.pendingChoice, ordinaryPending), isTrue);
    expect(ordinary.controller.status, CloudSaveStatus.needsOrdinaryChoice);
    expect(ordinary.state.cloudDirty, ordinaryBaseline.dirty);
    expect(ordinary.state.coins, ordinaryBaseline.coins);
    expect(ordinary.state.gamesPlayed, ordinaryBaseline.games);
    expect(ordinary.state.cloudRevision, ordinaryBaseline.revision);
    expect(ordinary.state.cloudRevisionId, ordinaryBaseline.revisionId);
    expect(ordinary.state.cloudParentRevisionId, ordinaryBaseline.parentId);
    expect(ordinary.state.cloudMergeParentRevisionIds,
        ordinaryBaseline.mergeParents);
    expect(_cloudSnapshot(ordinary.state), ordinaryProgress);

    final nativeTransport = _Transport()
      ..openResult = SavedGamesConflict(
        handle: 'choice',
        snapshotBytes:
            _bytes(_document(id: 'a', revision: 2, progress: _progress(1, 1))),
        conflictingSnapshotBytes:
            _bytes(_document(id: 'b', revision: 4, progress: _progress(2, 2))),
      );
    final native = makeController(nativeTransport,
        playGames: _PlayGames()..connectResult = true);
    native.state.cloudDirty = true;
    await native.controller.sync();
    final nativeBaseline = baseline(native, nativeTransport);
    final nativeProgress = _cloudSnapshot(native.state);
    final nativePending = nativeBaseline.pending;
    expect(nativePending, isA<CloudSyncNativeCloudChoice>());
    await native.controller.syncFromSettings();
    await native.controller.connectThenSync();
    expect(nativeTransport.opens, nativeBaseline.opens);
    expect(identical(native.controller.pendingChoice, nativePending), isTrue);
    expect(native.controller.status, CloudSaveStatus.needsNativeCloudChoice);
    expect(native.state.cloudDirty, nativeBaseline.dirty);
    expect(native.state.coins, nativeBaseline.coins);
    expect(native.state.gamesPlayed, nativeBaseline.games);
    expect(native.state.cloudRevision, nativeBaseline.revision);
    expect(native.state.cloudRevisionId, nativeBaseline.revisionId);
    expect(native.state.cloudParentRevisionId, nativeBaseline.parentId);
    expect(
        native.state.cloudMergeParentRevisionIds, nativeBaseline.mergeParents);
    expect(_cloudSnapshot(native.state), nativeProgress);
  });

  test('unsafe connect defers until an explicit later settings sync', () async {
    final transport = _Transport();
    final pair = makeController(transport,
        playGames: _PlayGames()..connectResult = true);
    pair.state
      ..coins = 7
      ..cloudDirty = true
      ..rt.gameActive = true;
    final baseline = (
      pair.state.coins,
      pair.state.gamesPlayed,
      pair.state.cloudDirty,
      pair.state.cloudRevision,
      pair.state.cloudRevisionId,
      pair.state.cloudParentRevisionId,
      pair.state.cloudMergeParentRevisionIds,
      pair.controller.status,
      transport.opens,
    );
    final progress = _cloudSnapshot(pair.state);
    await pair.controller.connectThenSync();
    expect(transport.opens, baseline.$9);
    expect(pair.state.coins, baseline.$1);
    expect(pair.state.gamesPlayed, baseline.$2);
    expect(pair.state.cloudDirty, baseline.$3);
    expect(pair.state.cloudRevision, baseline.$4);
    expect(pair.state.cloudRevisionId, baseline.$5);
    expect(pair.state.cloudParentRevisionId, baseline.$6);
    expect(pair.state.cloudMergeParentRevisionIds, baseline.$7);
    expect(pair.controller.status, baseline.$8);
    expect(_cloudSnapshot(pair.state), progress);
    pair.state.rt.gameActive = false;
    await Future<void>.delayed(Duration.zero);
    expect(transport.opens, 0);
    await pair.controller.syncFromSettings();
    expect(transport.opens, 1);
  });

  test('non-menu inactive settings sync preserves every cloud baseline',
      () async {
    final transport = _Transport();
    final pair = makeController(transport);
    pair.state
      ..currentScreen = GameScreen.config
      ..coins = 8
      ..gamesPlayed = 4
      ..cloudDirty = true
      ..cloudRevision = 3
      ..cloudRevisionId = 'revision'
      ..cloudParentRevisionId = 'parent';
    final baseline = (
      pair.state.coins,
      pair.state.gamesPlayed,
      pair.state.cloudDirty,
      pair.state.cloudRevision,
      pair.state.cloudRevisionId,
      pair.state.cloudParentRevisionId,
      pair.state.cloudMergeParentRevisionIds,
      pair.controller.status,
      transport.opens,
    );
    final progress = _cloudSnapshot(pair.state);
    await pair.controller.syncFromSettings();
    expect(transport.opens, baseline.$9);
    expect(pair.state.coins, baseline.$1);
    expect(pair.state.gamesPlayed, baseline.$2);
    expect(pair.state.cloudDirty, baseline.$3);
    expect(pair.state.cloudRevision, baseline.$4);
    expect(pair.state.cloudRevisionId, baseline.$5);
    expect(pair.state.cloudParentRevisionId, baseline.$6);
    expect(pair.state.cloudMergeParentRevisionIds, baseline.$7);
    expect(pair.controller.status, baseline.$8);
    expect(_cloudSnapshot(pair.state), progress);
  });

  test('failed connect releases the gate for one successful retry', () async {
    final games = _PlayGames();
    final transport = _Transport();
    final pair = makeController(transport, playGames: games);
    pair.state.cloudDirty = true;
    await pair.controller.connectThenSync();
    expect(games.connects, 1);
    expect(transport.opens, 0);
    expect(pair.controller.status, CloudSaveStatus.notAuthenticated);
    games.connectResult = true;
    await pair.controller.connectThenSync();
    expect(games.connects, 2);
    expect(transport.opens, 1);
  });

  test('post-connect waits for independently gated reconciliation', () async {
    final events = <String>[];
    final connectGate = Completer<bool>();
    final reconcileGate = Completer<void>();
    final games = _PlayGames()
      ..connectGate = connectGate
      ..unlockGate = reconcileGate
      ..events = events;
    final transport = _Transport()..events = events;
    final pair = makeController(transport, playGames: games);
    pair.state.achievements['first_win'] = true;
    final operation = pair.controller.connectThenSync();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['connect-start']);
    connectGate.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(events, ['connect-start', 'connect-complete', 'reconcile-start']);
    expect(transport.opens, 0);
    reconcileGate.complete();
    await operation;
    expect(events, [
      'connect-start',
      'connect-complete',
      'reconcile-start',
      'reconcile-complete',
      'sync-postConnect',
    ]);
    expect(transport.opens, 1);
  });

  test('gated Connect and manual requests coalesce without a second sync',
      () async {
    final gate = Completer<bool>();
    final games = _PlayGames()
      ..connectGate = gate
      ..connectResult = true;
    final transport = _Transport();
    final pair = makeController(transport, playGames: games);
    final first = pair.controller.connectThenSync();
    final second = pair.controller.connectThenSync();
    final manual = pair.controller.syncFromSettings();
    await Future<void>.delayed(Duration.zero);
    expect(games.connects, 1);
    expect(transport.opens, 0);
    gate.complete(true);
    await Future.wait([first, second, manual]);
    expect(transport.opens, 1);
    await Future<void>.delayed(Duration.zero);
    expect(transport.opens, 1);
  });

  test('reset wins over a connecting sync before it reaches cloud sync',
      () async {
    final connectGate = Completer<bool>();
    final transport = _Transport();
    final pair = makeController(
      transport,
      playGames: _PlayGames()
        ..connectGate = connectGate
        ..connectResult = true,
    );
    final connect = pair.controller.connectThenSync();
    final reset = pair.controller.resetEverywhere();

    connectGate.complete(true);
    await Future.wait([connect, reset]);

    expect(transport.opens, 1);
    expect(pair.state.cloudResetGeneration, 1);
  });

  test('Reset Everywhere is local-first when unauthenticated', () async {
    final pair = makeController(_Transport());
    await pair.state.load();
    pair.state.coins = 42;

    await pair.controller.resetEverywhere();

    expect(pair.state.exportCloudProgress(), CloudProgress.empty());
    expect(pair.state.cloudResetGeneration, 1);
    expect(pair.state.cloudDirty, isTrue);
    expect(pair.controller.status, CloudSaveStatus.notAuthenticated);
  });

  test('reset persistence failure blocks every cloud sync route', () async {
    final transport = _Transport();
    final pair = makeController(transport,
        playGames: _PlayGames()..authenticated = true);
    await pair.state.load();
    Storage.writeFailureHook = (key, _) {
      if (key == 'mc_puBonus') throw StateError('injected');
    };
    addTearDown(() => Storage.writeFailureHook = null);

    await pair.controller.resetEverywhere();
    expect(pair.state.cloudResetRecoveryBlocked, isTrue);
    expect(transport.opens, 0);

    await pair.controller.sync();
    await pair.controller.syncFromSettings();
    await pair.controller.connectThenSync();
    expect(transport.opens, 0);
    expect(pair.controller.status, CloudSaveStatus.requiresAttention);
  });

  test('Reset Everywhere coalesces callers and runs once after an active sync',
      () async {
    final transport = _Transport()
      ..openGate = Completer<SavedGamesOpenResult>();
    final pair = makeController(transport);
    await pair.state.load();
    pair.state.playGamesConnectionState = PlayGamesConnectionState.connected;
    final sync = pair.controller.sync();
    final first = pair.controller.resetEverywhere();
    final second = pair.controller.resetEverywhere();
    expect(identical(first, second), isTrue);
    expect(transport.opens, 1);

    transport.openGate!.complete(SavedGamesOpenedEmpty());
    await sync;
    await first;

    expect(pair.state.cloudResetGeneration, 1);
    expect(pair.state.exportCloudProgress(), CloudProgress.empty());
    expect(transport.opens, 2);
    expect(pair.controller.status, CloudSaveStatus.uploaded);
  });
}

String _cloudSnapshot(GameState state) =>
    jsonEncode(state.exportCloudProgress().toJson());

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
  List<String>? events;
  @override
  Future<SavedGamesOpenResult> open() {
    opens++;
    events?.add('sync-postConnect');
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
  CloudSyncChoice? resolvedChoice;
  int resolveCalls = 0;

  @override
  Future<CloudSyncResult> resolveUserChoice(
    CloudSyncNeedsUserChoice pending,
    CloudSyncChoice choice,
  ) {
    resolvedPending = pending;
    resolvedChoice = choice;
    resolveCalls++;
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
  Completer<bool>? authenticationGate;
  bool connectResult = false;
  Completer<bool>? connectGate;
  Completer<void>? unlockGate;
  List<String>? events;
  final unlocked = <String>[];

  @override
  Future<void> initializePgs() async {}

  @override
  Future<bool> isAuthenticated() async {
    checks++;
    final gate = authenticationGate;
    return gate == null ? authenticated : await gate.future;
  }

  @override
  Future<bool> connect() async {
    connects++;
    events?.add('connect-start');
    final gate = connectGate;
    final result = gate == null ? connectResult : await gate.future;
    events?.add('connect-complete');
    return result;
  }

  @override
  Future<void> unlockAchievement(String localAchievementId) async {
    unlocked.add(localAchievementId);
    events?.add('reconcile-start');
    final gate = unlockGate;
    if (gate != null) await gate.future;
    events?.add('reconcile-complete');
  }
}
