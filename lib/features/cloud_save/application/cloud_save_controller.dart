import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../engine/game_state.dart';
import '../../../services/play_games.dart';
import 'cloud_save_service.dart';

enum CloudSaveStatus {
  neverAttempted,
  syncing,
  upToDate,
  uploaded,
  restoredFromCloud,
  automaticallyMerged,
  userChoiceResolved,
  changesPendingLocally,
  needsOrdinaryChoice,
  needsNativeCloudChoice,
  notAuthenticated,
  offlineOrTransportFailure,
  requiresAttention,
  changedLocalState,
  resyncRequired,
}

enum CloudSaveSyncSource {
  startup,
  manual,
  postConnect,
  postReset,
  nativeFollowUp
}

class CloudSaveController extends ChangeNotifier {
  CloudSaveController({
    required GameState state,
    required CloudSaveService service,
    required Future<void> localLoad,
  })  : _state = state,
        _service = service,
        _localLoad = localLoad;

  final GameState _state;
  final CloudSaveService _service;
  final Future<void> _localLoad;
  Future<void>? _operation;
  Future<void>? _resetOperation;
  int _epoch = 0;
  bool _startupAttempted = false;
  CloudSaveStatus _status = CloudSaveStatus.neverAttempted;
  CloudSyncNeedsUserChoice? _pendingChoice;

  CloudSaveStatus get status => _status;
  CloudSyncNeedsUserChoice? get pendingChoice => _pendingChoice;
  bool get isBusy => _operation != null;
  bool get isResetting => _resetOperation != null;
  bool get startupAttempted => _startupAttempted;
  CloudSaveStatus get effectiveStatus =>
      _status == CloudSaveStatus.upToDate && _state.cloudDirty
          ? CloudSaveStatus.changesPendingLocally
          : _status;
  bool get canSyncFromSettings =>
      !_state.cloudResetRecoveryBlocked &&
      _state.currentScreen == GameScreen.menu &&
      !_state.rt.gameActive;

  Future<void> resetEverywhere() {
    final existing = _resetOperation;
    if (existing != null) return existing;
    if (_state.currentScreen != GameScreen.menu || _state.rt.gameActive) {
      return Future.value();
    }
    final epoch = ++_epoch;
    _set(CloudSaveStatus.syncing, pending: null);
    final before = _operation;
    final completion = Completer<void>();
    final reset = completion.future;
    _resetOperation = reset;
    () async {
      try {
        if (before != null) {
          try {
            await before;
          } catch (_) {}
        }
        if (epoch != _epoch) return;
        _operation = reset;
        notifyListeners();
        final localReset = await _state.resetCloudProgressEverywhere();
        if (epoch != _epoch) return;
        if (!localReset || _state.cloudResetRecoveryBlocked) {
          _set(CloudSaveStatus.requiresAttention, pending: null);
          return;
        }
        if (_state.playGamesConnectionState !=
            PlayGamesConnectionState.connected) {
          _set(CloudSaveStatus.notAuthenticated, pending: null);
          return;
        }
        await _sync(CloudSaveSyncSource.postReset, epoch);
      } catch (_) {
        if (epoch == _epoch)
          _set(CloudSaveStatus.requiresAttention, pending: null);
      } finally {
        if (identical(_operation, reset)) _operation = null;
        if (identical(_resetOperation, reset)) _resetOperation = null;
        completion.complete();
        notifyListeners();
      }
    }();
    return reset;
  }

  Future<void> startAfterFirstFrame() {
    if (_startupAttempted) return _operation ?? Future.value();
    _startupAttempted = true;
    notifyListeners();
    return _run(() async {
      final epoch = _epoch;
      await _localLoad;
      if (epoch != _epoch) return;
      if (_blockSyncForResetRecovery()) return;
      await _state.checkPlayGamesConnection();
      if (epoch != _epoch) return;
      if (_state.playGamesConnectionState !=
          PlayGamesConnectionState.connected) {
        _set(CloudSaveStatus.notAuthenticated, pending: null);
        return;
      }
      await _sync(CloudSaveSyncSource.startup, epoch);
    });
  }

  Future<void> sync(
          {CloudSaveSyncSource source = CloudSaveSyncSource.manual}) =>
      _resetOperation ?? _run(() => _sync(source, _epoch));

  Future<void> syncFromSettings() =>
      _resetOperation ??
      _run(() async {
        if (_resetOperation != null) return;
        if (_blockSyncForResetRecovery()) return;
        if (!canSyncFromSettings || _pendingChoice != null) return;
        if (_state.playGamesConnectionState !=
            PlayGamesConnectionState.connected) {
          _set(CloudSaveStatus.notAuthenticated, pending: null);
          return;
        }
        await _sync(CloudSaveSyncSource.manual, _epoch);
      });

  Future<void> connectThenSync() =>
      _resetOperation ??
      _run(() async {
        if (_resetOperation != null) return;
        if (_blockSyncForResetRecovery()) return;
        final epoch = _epoch;
        await _state.connectPlayGames();
        if (epoch != _epoch) return;
        if (_state.playGamesConnectionState !=
            PlayGamesConnectionState.connected) {
          _set(CloudSaveStatus.notAuthenticated, pending: _pendingChoice);
          return;
        }
        if (!canSyncFromSettings || _pendingChoice != null) return;
        await _sync(CloudSaveSyncSource.postConnect, epoch);
      });

  Future<void> resolvePendingChoice(CloudSyncChoice choice) {
    final pending = _pendingChoice;
    if (pending == null) return Future.value();
    return _run(() async {
      if (_blockSyncForResetRecovery()) return;
      final epoch = _epoch;
      _set(CloudSaveStatus.syncing);
      final result = await _service.resolveUserChoice(pending, choice);
      if (epoch != _epoch) return;
      _apply(result);
      if (result is CloudSyncNativeConflictResolvedResyncRequired) {
        await _sync(CloudSaveSyncSource.nativeFollowUp, epoch);
      }
    });
  }

  Future<void> _sync(CloudSaveSyncSource source, int epoch) async {
    if (epoch != _epoch) return;
    if (_blockSyncForResetRecovery()) return;
    _set(CloudSaveStatus.syncing);
    debugPrint('[cloud-save] sync ${source.name}');
    final result = await _service.sync();
    debugPrint('[cloud-save] result ${result.runtimeType}');
    if (epoch == _epoch) _apply(result);
  }

  bool _blockSyncForResetRecovery() {
    if (!_state.cloudResetRecoveryBlocked) return false;
    _set(CloudSaveStatus.requiresAttention, pending: null);
    return true;
  }

  Future<void> _run(Future<void> Function() action) {
    final active = _operation;
    if (active != null) return active;
    final completion = Completer<void>();
    final operation = completion.future;
    _operation = operation;
    () async {
      try {
        await action();
        completion.complete();
      } catch (error, stackTrace) {
        completion.completeError(error, stackTrace);
      } finally {
        if (identical(_operation, operation)) {
          _operation = null;
          notifyListeners();
        }
      }
    }();
    return operation;
  }

  void _apply(CloudSyncResult result) {
    if (result is CloudSyncDeviceCloudChoice) {
      debugPrint('[cloud-save] pending ordinary');
      _set(CloudSaveStatus.needsOrdinaryChoice, pending: result);
    } else if (result is CloudSyncNativeCloudChoice) {
      debugPrint('[cloud-save] pending native');
      _set(CloudSaveStatus.needsNativeCloudChoice, pending: result);
    } else if (result is CloudSyncNoChange) {
      _set(CloudSaveStatus.upToDate, pending: null);
    } else if (result is CloudSyncUploaded) {
      _set(CloudSaveStatus.uploaded, pending: null);
    } else if (result is CloudSyncRestoredFromCloud) {
      _set(CloudSaveStatus.restoredFromCloud, pending: null);
    } else if (result is CloudSyncAutomaticallyMerged) {
      _set(CloudSaveStatus.automaticallyMerged, pending: null);
    } else if (result is CloudSyncUserChoiceMerged) {
      _set(CloudSaveStatus.userChoiceResolved, pending: null);
    } else if (result is CloudSyncNotAuthenticated) {
      _set(CloudSaveStatus.notAuthenticated, pending: null);
    } else if (result is CloudSyncTransportFailure) {
      _set(CloudSaveStatus.offlineOrTransportFailure, pending: null);
    } else if (result is CloudSyncChangedLocalState) {
      _set(CloudSaveStatus.changedLocalState, pending: null);
    } else if (result is CloudSyncStaleConflict ||
        result is CloudSyncRepeatedConflict ||
        result is CloudSyncNativeConflictResolvedResyncRequired) {
      _set(CloudSaveStatus.resyncRequired, pending: null);
    } else {
      _set(CloudSaveStatus.requiresAttention, pending: null);
    }
  }

  void _set(CloudSaveStatus status, {CloudSyncNeedsUserChoice? pending}) {
    final pendingChanged = !identical(_pendingChoice, pending);
    if (_status == status && !pendingChanged) return;
    _status = status;
    _pendingChoice = pending;
    notifyListeners();
  }
}
