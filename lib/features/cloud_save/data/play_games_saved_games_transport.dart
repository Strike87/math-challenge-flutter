import 'package:flutter/services.dart';

const playGamesSavedGamesSnapshotName = 'math-challenge-progress-v1';

enum SavedGamesTransportError {
  notAuthenticated,
  unavailable,
  openFailed,
  readFailed,
  writeFailed,
  commitFailed,
  payloadTooLarge,
  staleConflictHandle,
  invalidNativeResult,
}

sealed class SavedGamesOperationResult {}

sealed class SavedGamesOpenResult extends SavedGamesOperationResult {}

sealed class SavedGamesCommitResult extends SavedGamesOperationResult {}

sealed class SavedGamesResolveResult extends SavedGamesOperationResult {}

final class SavedGamesOpenedEmpty extends SavedGamesOpenResult {}

final class SavedGamesOpenedData extends SavedGamesOpenResult {
  SavedGamesOpenedData(this.bytes);

  final Uint8List bytes;
}

final class SavedGamesConflict extends SavedGamesOperationResult
    implements
        SavedGamesOpenResult,
        SavedGamesCommitResult,
        SavedGamesResolveResult {
  SavedGamesConflict({
    required this.handle,
    required this.snapshotBytes,
    required this.conflictingSnapshotBytes,
  });

  final String handle;
  final Uint8List snapshotBytes;
  final Uint8List conflictingSnapshotBytes;
}

final class SavedGamesCommitted extends SavedGamesCommitResult {}

final class SavedGamesResolved extends SavedGamesResolveResult {}

final class SavedGamesTransportFailure extends SavedGamesOperationResult
    implements
        SavedGamesOpenResult,
        SavedGamesCommitResult,
        SavedGamesResolveResult {
  SavedGamesTransportFailure(this.error, {this.diagnostic});

  final SavedGamesTransportError error;
  final String? diagnostic;
}

abstract interface class SavedGamesTransport {
  Future<SavedGamesOpenResult> open();

  Future<SavedGamesCommitResult> commit(Uint8List bytes);

  Future<SavedGamesResolveResult> resolve(String handle, Uint8List bytes);
}

final class MethodChannelSavedGamesTransport implements SavedGamesTransport {
  MethodChannelSavedGamesTransport({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'math_challenge/play_games_saved_games';

  final MethodChannel _channel;

  @override
  Future<SavedGamesOpenResult> open() async => _mapOpen(
        await _invoke('openSnapshot'),
      );

  @override
  Future<SavedGamesCommitResult> commit(Uint8List bytes) async => _mapCommit(
        await _invoke('commitSnapshot', {'bytes': bytes}),
      );

  @override
  Future<SavedGamesResolveResult> resolve(
    String handle,
    Uint8List bytes,
  ) async =>
      _mapResolve(
        await _invoke('resolveConflict', {'handle': handle, 'bytes': bytes}),
      );

  Future<Object?> _invoke(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      return {
        'status': 'failure',
        'errorCode': _errorFromCode(error.code).name,
        'diagnostic': error.message,
      };
    }
  }

  SavedGamesOpenResult _mapOpen(Object? raw) {
    final map = _map(raw);
    switch (map?['status']) {
      case 'openedEmpty':
        return SavedGamesOpenedEmpty();
      case 'openedData':
        final bytes = _bytes(map?['bytes']);
        return bytes == null ? _invalidOpen() : SavedGamesOpenedData(bytes);
      case 'conflict':
        return (_conflict(map) ?? _invalidOpen()) as SavedGamesOpenResult;
      case 'failure':
        return _failure(map);
      default:
        return _invalidOpen();
    }
  }

  SavedGamesCommitResult _mapCommit(Object? raw) {
    final map = _map(raw);
    switch (map?['status']) {
      case 'committed':
        return SavedGamesCommitted();
      case 'conflict':
        return (_conflict(map) ?? _invalidCommit()) as SavedGamesCommitResult;
      case 'failure':
        return _failure(map);
      default:
        return _invalidCommit();
    }
  }

  SavedGamesResolveResult _mapResolve(Object? raw) {
    final map = _map(raw);
    switch (map?['status']) {
      case 'resolved':
        return SavedGamesResolved();
      case 'conflict':
        return (_conflict(map) ?? _invalidResolve()) as SavedGamesResolveResult;
      case 'failure':
        return _failure(map);
      default:
        return _invalidResolve();
    }
  }

  Map<Object?, Object?>? _map(Object? raw) => raw is Map ? raw : null;

  Uint8List? _bytes(Object? value) => value is Uint8List ? value : null;

  SavedGamesConflict? _conflict(Map<Object?, Object?>? map) {
    final handle = map?['handle'];
    final snapshotBytes = _bytes(map?['snapshotBytes']);
    final conflictingSnapshotBytes = _bytes(map?['conflictingSnapshotBytes']);
    if (handle is! String ||
        handle.isEmpty ||
        snapshotBytes == null ||
        conflictingSnapshotBytes == null) {
      return null;
    }
    return SavedGamesConflict(
      handle: handle,
      snapshotBytes: snapshotBytes,
      conflictingSnapshotBytes: conflictingSnapshotBytes,
    );
  }

  SavedGamesTransportFailure _failure(Map<Object?, Object?>? map) {
    final code = map?['errorCode'];
    return SavedGamesTransportFailure(
      code is String
          ? _errorFromCode(code)
          : SavedGamesTransportError.invalidNativeResult,
      diagnostic:
          map?['diagnostic'] is String ? map!['diagnostic'] as String : null,
    );
  }

  SavedGamesTransportFailure _invalidOpen() =>
      SavedGamesTransportFailure(SavedGamesTransportError.invalidNativeResult);

  SavedGamesTransportFailure _invalidCommit() =>
      SavedGamesTransportFailure(SavedGamesTransportError.invalidNativeResult);

  SavedGamesTransportFailure _invalidResolve() =>
      SavedGamesTransportFailure(SavedGamesTransportError.invalidNativeResult);

  SavedGamesTransportError _errorFromCode(String code) {
    for (final value in SavedGamesTransportError.values) {
      if (value.name == code) return value;
    }
    return SavedGamesTransportError.invalidNativeResult;
  }
}
