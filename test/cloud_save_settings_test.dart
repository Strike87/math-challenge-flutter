import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_controller.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/play_games.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cloud Save row covers all approved settings states',
      (tester) async {
    final cases = <Future<_Pair> Function()>[
      () => _pair(const CloudSyncNoChange(), connected: false),
      () => _pair(const CloudSyncNoChange()),
      () => _busyPair(),
      () => _dirtyPair(),
      () => _completedPair(const CloudSyncNoChange()),
      () => _completedPair(const CloudSyncUploaded()),
      () => _completedPair(const CloudSyncRestoredFromCloud()),
      () => _completedPair(const CloudSyncAutomaticallyMerged()),
      () => _completedPair(const CloudSyncUserChoiceMerged()),
      () => _completedPair(const CloudSyncTransportFailure(
          SavedGamesTransportError.unavailable)),
      () => _completedPair(const CloudSyncChangedLocalState()),
      () => _completedPair(const CloudSyncStaleConflict()),
      () => _completedPair(const CloudSyncLocalPersistenceFailure()),
      () => _ordinaryPendingPair(),
      () => _nativePendingPair(),
      _blockedPair,
      () => _unsafePair(active: true),
      () => _unsafePair(active: false),
    ];
    final expectations = <(String, String?, bool)>[
      ('Connect Play Games to sync', null, false),
      ('Ready to sync', 'SYNC NOW', true),
      ('Syncing…', 'SYNC NOW', false),
      ('Changes waiting to sync', 'SYNC NOW', true),
      ('Up to date', 'SYNC NOW', true),
      ('Sync accepted', 'SYNC NOW', true),
      ('Progress restored', 'SYNC NOW', true),
      ('Progress merged', 'SYNC NOW', true),
      ('Progress merged', 'SYNC NOW', true),
      ('Couldn’t sync', 'TRY AGAIN', true),
      ('Sync again to use the latest progress', 'TRY AGAIN', true),
      ('Sync again to use the latest progress', 'TRY AGAIN', true),
      ('Cloud save needs attention', 'TRY AGAIN', true),
      ('Cloud save needs review', 'REVIEW', true),
      ('Cloud save needs review', 'REVIEW', true),
      ('Reset recovery required', null, false),
      ('Sync available from Main Menu', 'SYNC NOW', false),
      ('Sync available from Main Menu', 'SYNC NOW', false),
    ];
    final statuses = <CloudSaveStatus>[
      CloudSaveStatus.neverAttempted,
      CloudSaveStatus.neverAttempted,
      CloudSaveStatus.syncing,
      CloudSaveStatus.upToDate,
      CloudSaveStatus.upToDate,
      CloudSaveStatus.uploaded,
      CloudSaveStatus.restoredFromCloud,
      CloudSaveStatus.automaticallyMerged,
      CloudSaveStatus.userChoiceResolved,
      CloudSaveStatus.offlineOrTransportFailure,
      CloudSaveStatus.changedLocalState,
      CloudSaveStatus.resyncRequired,
      CloudSaveStatus.requiresAttention,
      CloudSaveStatus.needsOrdinaryChoice,
      CloudSaveStatus.needsNativeCloudChoice,
      CloudSaveStatus.neverAttempted,
      CloudSaveStatus.neverAttempted,
      CloudSaveStatus.neverAttempted,
    ];

    for (var index = 0; index < cases.length; index++) {
      final pair = await cases[index]();
      final expected = expectations[index];
      await _pump(tester, pair);
      await _expectRow(tester, expected.$1, expected.$2, expected.$3);
      expect(pair.controller.status, statuses[index]);
      final before = pair.service.calls;
      final connectionsBefore = pair.playGames.calls;
      await _tapRow(tester, ensureVisible: expected.$3);
      await tester.pump();
      expect(pair.service.calls,
          before + (expected.$2 == 'REVIEW' ? 0 : (expected.$3 ? 1 : 0)));
      expect(pair.playGames.calls, connectionsBefore);
      if (pair.service.gate != null) {
        pair.service.gate!.complete(const CloudSyncNoChange());
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets(
      'enabled actions, disabled actions, and retry taps have exact deltas',
      (tester) async {
    final enabled = await _pair(const CloudSyncNoChange());
    await _pump(tester, enabled);
    final before = enabled.service.calls;
    await _tapRow(tester);
    await tester.pumpAndSettle();
    expect(enabled.service.calls, before + 1);
    expect(enabled.playGames.calls, 0);

    final disabled = await _unsafePair(active: true);
    await _pump(tester, disabled);
    final disabledBefore = disabled.service.calls;
    await _tapRow(tester);
    await tester.pump();
    expect(disabled.service.calls, disabledBefore);
    expect(disabled.playGames.calls, 0);

    final retry = await _completedPair(
        const CloudSyncTransportFailure(SavedGamesTransportError.unavailable));
    retry.service.gate = Completer<CloudSyncResult>();
    await _pump(tester, retry);
    final retryBefore = retry.service.calls;
    await _tapRow(tester);
    await _tapRow(tester);
    await tester.pump();
    expect(retry.service.calls, retryBefore + 1);
    expect(retry.playGames.calls, 0);
    retry.service.gate!.complete(
        const CloudSyncTransportFailure(SavedGamesTransportError.unavailable));
    await tester.pumpAndSettle();
    expect(retry.service.calls, retryBefore + 1);
  });

  testWidgets('SYNC NOW double tap starts one cloud operation', (tester) async {
    final pair = await _pair(const CloudSyncNoChange());
    pair.service.gate = Completer<CloudSyncResult>();
    await _pump(tester, pair);
    await _tapRow(tester);
    await _tapRow(tester);
    await tester.pump();
    expect(pair.service.calls, 1);
    expect(pair.playGames.calls, 0);
    pair.service.gate!.complete(const CloudSyncNoChange());
    await tester.pumpAndSettle();
    expect(pair.service.calls, 1);
  });

  testWidgets('requires attention yields to disconnected and unsafe context',
      (tester) async {
    final disconnected = await _completedPair(
      const CloudSyncLocalPersistenceFailure(),
      connected: false,
    );
    final disconnectedCalls = disconnected.service.calls;
    final disconnectedConnections = disconnected.playGames.calls;
    await _pump(tester, disconnected);
    await _expectRow(tester, 'Connect Play Games to sync', null, false);
    await _tapRow(tester, ensureVisible: false);
    await tester.pump();
    expect(disconnected.service.calls, disconnectedCalls);
    expect(disconnected.playGames.calls, disconnectedConnections);

    final unsafe =
        await _completedPair(const CloudSyncLocalPersistenceFailure());
    unsafe.state.currentScreen = GameScreen.game;
    final unsafeCalls = unsafe.service.calls;
    final unsafeConnections = unsafe.playGames.calls;
    await _pump(tester, unsafe);
    await _expectRow(
        tester, 'Sync available from Main Menu', 'TRY AGAIN', false);
    await _tapRow(tester, ensureVisible: false);
    await tester.pump();
    expect(unsafe.service.calls, unsafeCalls);
    expect(unsafe.playGames.calls, unsafeConnections);
  });

  testWidgets('pending review stays non-actionable in unsafe contexts',
      (tester) async {
    final cases = [
      (
        await _ordinaryPendingPair(),
        CloudSaveStatus.needsOrdinaryChoice,
        true,
      ),
      (
        await _nativePendingPair(),
        CloudSaveStatus.needsNativeCloudChoice,
        false,
      ),
    ];
    for (final testCase in cases) {
      final pair = testCase.$1;
      if (testCase.$3) {
        pair.state.rt.gameActive = true;
      } else {
        pair.state.currentScreen = GameScreen.game;
      }
      final pending = pair.controller.pendingChoice;
      final syncCalls = pair.service.calls;
      final resolutionCalls = pair.service.resolutions.length;
      final snapshot = _snapshot(pair.state);

      expect(pending, isNotNull);
      expect(pair.controller.status, testCase.$2);
      await _pump(tester, pair);
      await _expectRow(tester, 'Cloud save needs review', 'REVIEW', false);
      await tester.ensureVisible(find.text('REVIEW'));
      await tester.tap(find.text('REVIEW'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Review Cloud Save'), findsNothing);
      expect(pair.service.calls, syncCalls);
      expect(pair.service.resolutions.length, resolutionCalls);
      expect(identical(pair.controller.pendingChoice, pending), isTrue);
      expect(pair.controller.status, testCase.$2);
      expect(_snapshot(pair.state), snapshot);
    }
  });

  testWidgets('ordinary and native pending survive Settings close and reopen',
      (tester) async {
    for (final pair in [
      await _ordinaryPendingPair(),
      await _nativePendingPair()
    ]) {
      final pending = pair.controller.pendingChoice;
      final status = pair.controller.status;
      final calls = pair.service.calls;
      final snapshot = _snapshot(pair.state);
      await _pump(tester, pair);
      await _expectRow(tester, 'Cloud save needs review', 'REVIEW', true);
      await _tapRow(tester);
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsOneWidget);
      expect(pair.service.calls, calls);
      pair.state.closeModal();
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsNothing);
      expect(identical(pair.controller.pendingChoice, pending), isTrue);
      expect(pair.service.calls, calls);
      expect(_snapshot(pair.state), snapshot);
      pair.state.showModal(GameModal.settings);
      await tester.pumpAndSettle();
      expect(identical(pair.controller.pendingChoice, pending), isTrue);
      expect(pair.controller.status, status);
      expect(pair.service.calls, calls);
      expect(_snapshot(pair.state), snapshot);
      await _expectRow(tester, 'Cloud save needs review', 'REVIEW', true);
      await _tapRow(tester);
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('explicit Close preserves each typed pending conflict',
      (tester) async {
    for (final testCase in [
      (
        await _ordinaryPendingPair(),
        CloudSaveStatus.needsOrdinaryChoice,
      ),
      (
        await _nativePendingPair(),
        CloudSaveStatus.needsNativeCloudChoice,
      ),
    ]) {
      final pair = testCase.$1;
      final pending = pair.controller.pendingChoice;
      final initialStatus = pair.controller.status;
      final calls = pair.service.calls;
      final resolutionCalls = pair.service.resolutions.length;
      expect(initialStatus, testCase.$2);
      await _pump(tester, pair);
      await _tapRow(tester);
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsOneWidget);
      expect(
          find.text(
              pair.controller.status == CloudSaveStatus.needsOrdinaryChoice
                  ? 'This Device'
                  : 'Version 1'),
          findsOneWidget);
      expect(
          find.text(
              pair.controller.status == CloudSaveStatus.needsOrdinaryChoice
                  ? 'Cloud Progress'
                  : 'Version 2'),
          findsOneWidget);
      expect(pair.service.calls, calls);
      expect(identical(pair.controller.pendingChoice, pending), isTrue);
      final beforeClose = _snapshot(pair.state);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsNothing);
      expect(pair.service.resolutions.length, resolutionCalls);
      expect(pair.service.calls, calls);
      expect(identical(pair.controller.pendingChoice, pending), isTrue);
      expect(pair.controller.status, initialStatus);
      expect(pair.controller.status, testCase.$2);
      expect(_snapshot(pair.state), beforeClose);
      await _tapRow(tester);
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('resolving conflict blocks dismissal and duplicate actions',
      (tester) async {
    final pair = await _ordinaryPendingPair();
    pair.service.resolutionGate = Completer<CloudSyncResult>();
    await _pump(tester, pair);
    await _tapRow(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep This Device'));
    await tester.pump();

    expect(find.text('Resolving your choice…'), findsOneWidget);
    expect(pair.service.resolutions, hasLength(1));
    for (final label in [
      'Keep This Device',
      'Use Cloud Progress',
      'Close',
    ]) {
      await tester.tap(find.text(label), warnIfMissed: false);
    }
    await tester.tapAt(const Offset(5, 5));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Review Cloud Save'), findsOneWidget);
    expect(pair.service.resolutions, hasLength(1));

    pair.service.resolutionGate!.complete(const CloudSyncUserChoiceMerged());
    await tester.pumpAndSettle();
    expect(find.text('Review Cloud Save'), findsNothing);
  });

  testWidgets('closing Settings disposes an in-flight conflict dialog safely',
      (tester) async {
    final pair = await _ordinaryPendingPair();
    pair.service.resolutionGate = Completer<CloudSyncResult>();
    final syncCalls = pair.service.calls;
    await _pump(tester, pair);
    await _tapRow(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep This Device'));
    await tester.pump();

    expect(pair.service.resolutions, hasLength(1));
    pair.state.closeModal();
    await tester.pumpAndSettle();
    expect(find.text('Review Cloud Save'), findsNothing);

    pair.service.resolutionGate!.complete(const CloudSyncUserChoiceMerged());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(pair.service.resolutions, hasLength(1));
    expect(pair.service.calls, syncCalls);
    expect(find.text('Review Cloud Save'), findsNothing);
  });

  testWidgets('all four conflict actions map once to their captured pending',
      (tester) async {
    final cases = [
      (
        _ordinaryPendingPair,
        'Keep This Device',
        CloudSyncChoice.keepThisDevice
      ),
      (_ordinaryPendingPair, 'Use Cloud Progress', CloudSyncChoice.useCloud),
      (_nativePendingPair, 'Use Version 1', CloudSyncChoice.primaryCloud),
      (_nativePendingPair, 'Use Version 2', CloudSyncChoice.conflictingCloud),
    ];
    for (final testCase in cases) {
      final pair = await testCase.$1();
      final pending = pair.controller.pendingChoice;
      final syncCalls = pair.service.calls;
      pair.service.resolutionResult = const CloudSyncUserChoiceMerged();
      await _pump(tester, pair);
      await _tapRow(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text(testCase.$2));
      await tester.tap(find.text(testCase.$2), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pair.service.resolutions, [(pending, testCase.$3)]);
      expect(pair.service.calls, syncCalls);
    }
  });

  testWidgets('stale cleared and superseded conflicts never resolve',
      (tester) async {
    for (final superseded in [false, true]) {
      final pair = await _ordinaryPendingPair();
      final pendingA = pair.controller.pendingChoice;
      final snapshot = _snapshot(pair.state);
      await _pump(tester, pair);
      await _tapRow(tester);
      await tester.pumpAndSettle();

      CloudSyncNeedsUserChoice? pendingB;
      if (superseded) {
        pendingB = (await _nativePendingPair()).controller.pendingChoice;
        pair.service.nextSyncResult = pendingB;
      } else {
        pair.service.nextSyncResult = const CloudSyncNoChange();
      }
      await pair.controller.sync();
      expect(identical(pair.controller.pendingChoice, pendingA), isFalse);
      await tester.tap(find.text('Keep This Device'));
      await tester.pumpAndSettle();

      expect(pair.service.resolutions, isEmpty);
      expect(identical(pair.controller.pendingChoice, pendingB), isTrue);
      expect(
        pair.controller.status,
        superseded
            ? CloudSaveStatus.needsNativeCloudChoice
            : CloudSaveStatus.upToDate,
      );
      expect(_snapshot(pair.state), snapshot);
      expect(find.text('Review Cloud Save'), findsNothing);
    }
  });

  testWidgets('resolution results use existing Settings presentations',
      (tester) async {
    final cases = <(CloudSyncResult, String, String, CloudSaveStatus)>[
      (
        const CloudSyncUserChoiceMerged(),
        'Progress merged',
        'SYNC NOW',
        CloudSaveStatus.userChoiceResolved,
      ),
      (
        const CloudSyncChangedLocalState(),
        'Sync again to use the latest progress',
        'TRY AGAIN',
        CloudSaveStatus.changedLocalState,
      ),
      (
        const CloudSyncTransportFailure(SavedGamesTransportError.unavailable),
        'Couldn’t sync',
        'TRY AGAIN',
        CloudSaveStatus.offlineOrTransportFailure,
      ),
      (
        const CloudSyncLocalPersistenceFailure(),
        'Cloud save needs attention',
        'TRY AGAIN',
        CloudSaveStatus.requiresAttention,
      ),
    ];
    for (final testCase in cases) {
      final pair = await _ordinaryPendingPair();
      final syncCalls = pair.service.calls;
      pair.service.resolutionResult = testCase.$1;
      await _pump(tester, pair);
      await _tapRow(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep This Device'));
      await tester.pumpAndSettle();
      expect(find.text('Review Cloud Save'), findsNothing);
      await _expectRow(tester, testCase.$2, testCase.$3, true);
      expect(pair.controller.status, testCase.$4);
      expect(pair.service.calls, syncCalls);
      expect(pair.service.resolutions, hasLength(1));
      if (testCase.$1 is! CloudSyncUserChoiceMerged) {
        _expectNoCloudSuccessCopy();
      }
    }

    final native = await _nativePendingPair();
    final syncCalls = native.service.calls;
    native.service
      ..resolutionResult = const CloudSyncNativeConflictResolvedResyncRequired()
      ..nextSyncResult = const CloudSyncStaleConflict();
    await _pump(tester, native);
    await _tapRow(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Version 1'));
    await tester.pumpAndSettle();
    expect(find.text('Review Cloud Save'), findsNothing);
    await _expectRow(
      tester,
      'Sync again to use the latest progress',
      'TRY AGAIN',
      true,
    );
    expect(native.controller.status, CloudSaveStatus.resyncRequired);
    expect(native.service.calls, syncCalls + 1);
    expect(native.service.resolutions, hasLength(1));
    _expectNoCloudSuccessCopy();
  });

  testWidgets('changed local conflict preserves state and offers retry',
      (tester) async {
    final pair = await _ordinaryPendingPair();
    final pending = pair.controller.pendingChoice;
    final syncCalls = pair.service.calls;
    await _pump(tester, pair);
    await _tapRow(tester);
    await tester.pumpAndSettle();

    pair.state
      ..coins += 1
      ..cloudDirty = true;
    final protectedSnapshot = _snapshot(pair.state);
    await tester.tap(find.text('Keep This Device'));
    await tester.pumpAndSettle();

    expect(pending, isNotNull);
    expect(pair.controller.status, CloudSaveStatus.changedLocalState);
    expect(pair.controller.pendingChoice, isNull);
    expect(find.text('Review Cloud Save'), findsNothing);
    await _expectRow(
      tester,
      'Sync again to use the latest progress',
      'TRY AGAIN',
      true,
    );
    expect(_snapshot(pair.state), protectedSnapshot);
    expect(pair.state.coins, 11);
    expect(
        pair.service.resolutions, [(pending, CloudSyncChoice.keepThisDevice)]);
    expect(pair.service.calls, syncCalls);
    _expectNoCloudSuccessCopy();
  });

  testWidgets('Cloud Save row priority is busy, pending, auth, unsafe, status',
      (tester) async {
    final busyPending = await _ordinaryPendingPair(dirty: true);
    await tester.pump();
    busyPending.transport.commitGate = Completer<SavedGamesCommitResult>();
    final resolving = busyPending.controller
        .resolvePendingChoice(CloudSyncChoice.keepThisDevice);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(busyPending.controller.isBusy, isTrue);
    expect(busyPending.controller.status, CloudSaveStatus.syncing);
    await _pump(tester, busyPending);
    await _expectRow(tester, 'Syncing…', 'SYNC NOW', false);
    busyPending.transport.commitGate!.complete(SavedGamesCommitted());
    await resolving;

    for (final pair in [
      await _ordinaryPendingPair(),
      await _nativePendingPair()
    ]) {
      pair.state
        ..playGamesConnectionState = PlayGamesConnectionState.disconnected
        ..cloudDirty = true;
      await _pump(tester, pair);
      await _expectRow(tester, 'Cloud save needs review', 'REVIEW', true);
    }

    final auth =
        await _completedPair(const CloudSyncUploaded(), connected: false);
    auth.state.cloudDirty = true;
    await _pump(tester, auth);
    await _expectRow(tester, 'Connect Play Games to sync', null, false);

    final unsafe = await _completedPair(const CloudSyncUploaded());
    unsafe.state
      ..cloudDirty = true
      ..currentScreen = GameScreen.game;
    await _pump(tester, unsafe);
    await _expectRow(
        tester, 'Sync available from Main Menu', 'SYNC NOW', false);
  });

  testWidgets(
      'Restart Game Progress is the only reset action and confirmation is mutation-free until submitted',
      (tester) async {
    final pair = await _pair(const CloudSyncNoChange(), connected: false);
    await _pump(tester, pair);
    expect(find.text('🗑️ Reset All Data'), findsNothing);
    expect(find.text('Data'), findsNothing);
    expect(find.text('RESTART GAME PROGRESS'), findsOneWidget);
    expect(
      find.text(
          'Erase game progress on this device and all connected devices. Settings and purchases will be kept.'),
      findsOneWidget,
    );
    final resetRow = find.ancestor(
      of: find.text('RESTART GAME PROGRESS'),
      matching: find.byType(InkWell),
    );
    expect(resetRow, findsOneWidget);
    final snapshot = _snapshot(pair.state);
    final calls = pair.service.calls;
    await tester.ensureVisible(resetRow);
    await tester.tap(resetRow);
    await tester.pumpAndSettle();
    expect(find.text('Restart Game Progress?'), findsOneWidget);
    expect(
      find.text(
          'Coins, scores, mastery, achievements, player names, avatars, and Quest progress will be erased. Older cloud saves will not restore them. Settings and purchases will remain. This can’t be undone.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Restart Progress'), findsOneWidget);
    expect(pair.service.calls, calls);
    expect(pair.state.cloudResetGeneration, 0);
    expect(_snapshot(pair.state), snapshot);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(pair.state.cloudResetGeneration, 0);
    expect(pair.service.calls, calls);
    expect(_snapshot(pair.state), snapshot);
  });

  testWidgets('Restart Game Progress only dismisses before submission',
      (tester) async {
    final pair = await _pair(const CloudSyncNoChange());
    pair.service.gate = Completer<CloudSyncResult>();
    await _pump(tester, pair);
    final resetRow = find.ancestor(
      of: find.text('RESTART GAME PROGRESS'),
      matching: find.byType(InkWell),
    );
    final snapshot = _snapshot(pair.state);
    await tester.ensureVisible(resetRow);
    await tester.tap(resetRow);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Restart Game Progress?'), findsNothing);
    expect(pair.state.cloudResetGeneration, 0);
    expect(_snapshot(pair.state), snapshot);

    await tester.tap(resetRow);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Restart Game Progress?'), findsNothing);
    expect(pair.state.cloudResetGeneration, 0);
    expect(_snapshot(pair.state), snapshot);

    await tester.tap(resetRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart Progress'));
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Restart Game Progress?'), findsOneWidget);
    expect(pair.state.cloudResetGeneration, 1);

    pair.service.gate!.complete(const CloudSyncNoChange());
    await tester.pumpAndSettle();
  });

  testWidgets('native reset Escape cancels only before submission',
      (tester) async {
    final pair = await _pair(const CloudSyncNoChange());
    pair.service.gate = Completer<CloudSyncResult>();
    await _pump(tester, pair);
    final resetRow = find.ancestor(
      of: find.text('RESTART GAME PROGRESS'),
      matching: find.byType(InkWell),
    );
    final snapshot = _snapshot(pair.state);

    await tester.ensureVisible(resetRow);
    await tester.tap(resetRow);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Restart Game Progress?'), findsNothing);
    expect(pair.state.cloudResetGeneration, 0);
    expect(_snapshot(pair.state), snapshot);

    await tester.tap(resetRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart Progress'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Restart Game Progress?'), findsOneWidget);
    expect(pair.state.cloudResetGeneration, 1);
    pair.service.gate!.complete(const CloudSyncNoChange());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('native cloud conflict Escape closes idle and not resolving',
      (tester) async {
    final pair = await _ordinaryPendingPair();
    await _pump(tester, pair);
    await _tapRow(tester);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Review Cloud Save'), findsNothing);
    expect(pair.service.resolutions, isEmpty);

    pair.service.resolutionGate = Completer<CloudSyncResult>();
    await _tapRow(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep This Device'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Review Cloud Save'), findsOneWidget);
    expect(pair.service.resolutions, hasLength(1));
    pair.service.resolutionGate!.complete(const CloudSyncUserChoiceMerged());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Restart Game Progress dispatches once and remains unavailable outside the safe menu',
      (tester) async {
    final pair = await _pair(const CloudSyncNoChange());
    await _pump(tester, pair);
    final resetRow = find.ancestor(
      of: find.text('RESTART GAME PROGRESS'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(resetRow);
    await tester.tap(resetRow);
    await tester.pump();
    await tester.tap(find.text('Restart Progress'));
    await tester.tap(find.text('Restart Progress'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(pair.state.cloudResetGeneration, 1);
    expect(pair.service.calls, 1);

    pair.state.showScreen(GameScreen.game);
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(resetRow).onTap, isNull);
  });
}

Future<void> _expectRow(
  WidgetTester tester,
  String status,
  String? action,
  bool enabled,
) async {
  expect(find.text('Cloud Save'), findsOneWidget);
  expect(find.text(status), findsOneWidget);
  expect(find.text('SYNC NOW'),
      action == 'SYNC NOW' ? findsOneWidget : findsNothing);
  expect(find.text('TRY AGAIN'),
      action == 'TRY AGAIN' ? findsOneWidget : findsNothing);
  expect(
      find.text('REVIEW'), action == 'REVIEW' ? findsOneWidget : findsNothing);
  final row = _row();
  expect(tester.widget<InkWell>(row).onTap == null, isNot(enabled));
}

Finder _row() => find.ancestor(
      of: find.text('Cloud Save'),
      matching: find.byType(InkWell),
    );

void _expectNoCloudSuccessCopy() {
  for (final copy in [
    'Up to date',
    'Sync accepted',
    'Progress restored',
    'Progress merged',
  ]) {
    expect(find.text(copy), findsNothing);
  }
}

Future<void> _tapRow(WidgetTester tester, {bool ensureVisible = true}) async {
  if (ensureVisible) await tester.ensureVisible(find.text('Cloud Save'));
  await tester.tap(_row(), warnIfMissed: false);
}

Future<_Pair> _pair(
  CloudSyncResult result, {
  bool connected = true,
  bool realService = false,
}) async {
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
  final playGames = _PlayGames();
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    playGamesService: playGames,
  )
    ..currentScreen = GameScreen.menu
    ..playGamesConnectionState = connected
        ? PlayGamesConnectionState.connected
        : PlayGamesConnectionState.disconnected
    ..showModal(GameModal.settings);
  final transport = _Transport();
  final service = _Service(
    state: state,
    result: result,
    transport: transport,
    realService: realService,
  );
  return _Pair(
      state,
      transport,
      service,
      playGames,
      CloudSaveController(
          state: state, service: service, localLoad: Future.value()));
}

Future<_Pair> _completedPair(CloudSyncResult result,
    {bool connected = true}) async {
  final pair = await _pair(result, connected: connected);
  await pair.controller.sync();
  return pair;
}

Future<_Pair> _dirtyPair() async {
  final pair = await _completedPair(const CloudSyncNoChange());
  pair.state.cloudDirty = true;
  return pair;
}

Future<_Pair> _unsafePair({required bool active}) async {
  final pair = await _pair(const CloudSyncNoChange());
  if (active) {
    pair.state.rt.gameActive = true;
  } else {
    pair.state.currentScreen = GameScreen.game;
  }
  return pair;
}

Future<_Pair> _blockedPair() async {
  final pair = await _pair(const CloudSyncNoChange());
  pair.state.cloudResetRecoveryBlocked = true;
  return pair;
}

Future<_Pair> _busyPair() async {
  final pair = await _pair(const CloudSyncNoChange());
  pair.service.gate = Completer<CloudSyncResult>();
  unawaited(pair.controller.syncFromSettings());
  return pair;
}

Future<_Pair> _ordinaryPendingPair({bool dirty = false}) async {
  final pair = await _realPair();
  final local = _progress(10, 1);
  await pair.state.acceptCloudProgressDocument(_document('local', 3, local),
      importProgress: true);
  pair.state.cloudDirty = dirty;
  pair.transport.openResult =
      SavedGamesOpenedData(_bytes(_document('cloud', 5, _progress(20, 2))));
  await pair.controller.sync();
  expect(pair.controller.status, CloudSaveStatus.needsOrdinaryChoice);
  pair.state.showModal(GameModal.settings);
  return pair;
}

Future<_Pair> _nativePendingPair() async {
  final pair = await _realPair();
  pair.transport.openResult = SavedGamesConflict(
    handle: 'choice',
    snapshotBytes: _bytes(_document('primary', 2, _progress(1, 1))),
    conflictingSnapshotBytes: _bytes(_document('conflict', 4, _progress(2, 2))),
  );
  await pair.controller.sync();
  expect(pair.controller.status, CloudSaveStatus.needsNativeCloudChoice);
  pair.state.showModal(GameModal.settings);
  return pair;
}

Future<_Pair> _realPair() async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  final settings = SettingsService();
  final playGames = _PlayGames();
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    playGamesService: playGames,
  )
    ..currentScreen = GameScreen.menu
    ..playGamesConnectionState = PlayGamesConnectionState.connected;
  final transport = _Transport();
  final service = _Service(
    state: state,
    result: const CloudSyncNoChange(),
    transport: transport,
    realService: true,
  );
  return _Pair(
    state,
    transport,
    service,
    playGames,
    CloudSaveController(
        state: state, service: service, localLoad: Future.value()),
  );
}

CloudProgress _progress(int coins, int games) {
  final empty = CloudProgress.empty();
  return CloudProgress(
    coins: coins,
    gamesPlayed: games,
    achievements: empty.achievements,
    operationQuestStars: empty.operationQuestStars,
    highScores: empty.highScores,
    skillMap: empty.skillMap,
    profile: empty.profile,
    economy: empty.economy,
  );
}

CloudProgressDocument _document(
        String id, int revision, CloudProgress progress) =>
    CloudProgressDocument(
      revision: revision,
      revisionId: id,
      resetGeneration: 0,
      updatedAtUtcMs: 1,
      progress: progress,
    );

Uint8List _bytes(CloudProgressDocument document) =>
    Uint8List.fromList(utf8.encode(document.encode()));

String _snapshot(GameState state) => jsonEncode({
      'progress': state.exportCloudProgress().toJson(),
      'dirty': state.cloudDirty,
      'revision': state.cloudRevision,
      'revisionId': state.cloudRevisionId,
      'parentRevisionId': state.cloudParentRevisionId,
      'mergeParentRevisionIds': state.cloudMergeParentRevisionIds,
    });

Future<void> _pump(WidgetTester tester, _Pair pair) async {
  await tester.pumpWidget(_host(pair));
  if (pair.controller.isBusy) {
    await tester.pump();
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

Widget _host(_Pair pair) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pair.state),
        ChangeNotifierProvider.value(value: pair.state.settings),
        ChangeNotifierProvider.value(value: pair.controller),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Stack(children: [ModalRouter()])),
      ),
    );

class _Pair {
  _Pair(this.state, this.transport, this.service, this.playGames,
      this.controller);
  final GameState state;
  final _Transport transport;
  final _Service service;
  final _PlayGames playGames;
  final CloudSaveController controller;
}

class _PlayGames extends PlayGamesService {
  int calls = 0;
  @override
  Future<bool> isAuthenticated() async => false;
  @override
  Future<bool> connect() async {
    calls++;
    return false;
  }

  @override
  Future<void> unlockAchievement(String localAchievementId) async {}
}

class _Service extends CloudSaveService {
  _Service({
    required super.state,
    required this.result,
    required super.transport,
    required this.realService,
  });
  CloudSyncResult result;
  final bool realService;
  Completer<CloudSyncResult>? gate;
  Completer<CloudSyncResult>? resolutionGate;
  CloudSyncResult? resolutionResult;
  CloudSyncResult? nextSyncResult;
  final resolutions = <(CloudSyncNeedsUserChoice, CloudSyncChoice)>[];
  int calls = 0;
  @override
  Future<CloudSyncResult> sync() {
    calls++;
    final next = nextSyncResult;
    if (next != null) {
      nextSyncResult = null;
      return Future.value(next);
    }
    return realService ? super.sync() : gate?.future ?? Future.value(result);
  }

  @override
  Future<CloudSyncResult> resolveUserChoice(
    CloudSyncNeedsUserChoice pending,
    CloudSyncChoice choice,
  ) {
    resolutions.add((pending, choice));
    return resolutionGate?.future ??
        (resolutionResult == null
            ? super.resolveUserChoice(pending, choice)
            : Future.value(resolutionResult));
  }
}

class _Transport implements SavedGamesTransport {
  SavedGamesOpenResult openResult = SavedGamesOpenedEmpty();
  Completer<SavedGamesCommitResult>? commitGate;
  @override
  Future<SavedGamesCommitResult> commit(Uint8List bytes) async =>
      await (commitGate?.future ?? Future.value(SavedGamesCommitted()));
  @override
  Future<SavedGamesOpenResult> open() async => openResult;
  @override
  Future<SavedGamesResolveResult> resolve(String handle, Uint8List bytes) =>
      Future.value(SavedGamesResolved());
}
