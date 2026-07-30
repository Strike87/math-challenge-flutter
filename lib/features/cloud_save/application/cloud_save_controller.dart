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
  bool _startupAttempted = false;
  CloudSaveStatus _status = CloudSaveStatus.neverAttempted;
  CloudSyncNeedsUserChoice? _pendingChoice;

  CloudSaveStatus get status => _status;
  CloudSyncNeedsUserChoice? get pendingChoice => _pendingChoice;
  bool get isBusy => _operation != null;
  bool get startupAttempted => _startupAttempted;
  CloudSaveStatus get effectiveStatus =>
      _status == CloudSaveStatus.upToDate && _state.cloudDirty
          ? CloudSaveStatus.changesPendingLocally
          : _status;

  Future<void> startAfterFirstFrame() {
    if (_startupAttempted) return _operation ?? Future.value();
    _startupAttempted = true;
    notifyListeners();
    return _run(() async {
      await _localLoad;
      await _state.checkPlayGamesConnection();
      if (_state.playGamesConnectionState !=
          PlayGamesConnectionState.connected) {
        _set(CloudSaveStatus.notAuthenticated, pending: null);
        return;
      }
      await _sync(CloudSaveSyncSource.startup);
    });
  }

  Future<void> sync(
          {CloudSaveSyncSource source = CloudSaveSyncSource.manual}) =>
      _run(() => _sync(source));

  Future<void> resolvePendingChoice(CloudSyncChoice choice) {
    final pending = _pendingChoice;
    if (pending == null) return Future.value();
    return _run(() async {
      _set(CloudSaveStatus.syncing);
      final result = await _service.resolveUserChoice(pending, choice);
      _apply(result);
      if (result is CloudSyncNativeConflictResolvedResyncRequired) {
        await _sync(CloudSaveSyncSource.nativeFollowUp);
      }
    });
  }

  Future<void> _sync(CloudSaveSyncSource source) async {
    _set(CloudSaveStatus.syncing);
    debugPrint('[cloud-save] sync ${source.name}');
    final result = await _service.sync();
    debugPrint('[cloud-save] result ${result.runtimeType}');
    _apply(result);
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
