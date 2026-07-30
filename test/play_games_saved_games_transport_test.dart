import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('math_challenge/play_games_saved_games');
  final transport = MethodChannelSavedGamesTransport(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('open', () {
    test('maps empty, data, conflict, typed failures, and malformed results',
        () async {
      await _reply(channel, {'status': 'openedEmpty'});
      expect(await transport.open(), isA<SavedGamesOpenedEmpty>());

      final data = Uint8List.fromList([0, 255, 1]);
      await _reply(channel, {'status': 'openedData', 'bytes': data});
      expect((await transport.open() as SavedGamesOpenedData).bytes, data);

      await _reply(channel, _conflict('open-conflict'));
      final conflict = await transport.open() as SavedGamesConflict;
      expect(conflict.handle, 'open-conflict');
      expect(conflict.snapshotBytes, Uint8List.fromList([1]));
      expect(conflict.conflictingSnapshotBytes, Uint8List.fromList([2]));

      await _reply(channel, _failure('notAuthenticated'));
      expect(
        (await transport.open() as SavedGamesTransportFailure).error,
        SavedGamesTransportError.notAuthenticated,
      );

      await _reply(channel, _failure('openFailed'));
      expect(
        (await transport.open() as SavedGamesTransportFailure).error,
        SavedGamesTransportError.openFailed,
      );

      await _reply(channel, {'status': 'openedData'});
      expect(
        (await transport.open() as SavedGamesTransportFailure).error,
        SavedGamesTransportError.invalidNativeResult,
      );
    });
  });

  group('commit', () {
    test('maps success, failures, and a returned conflict without overwrite',
        () async {
      final bytes = Uint8List.fromList([3, 0, 255]);
      await _reply(channel, {'status': 'committed'}, expectBytes: bytes);
      expect(await transport.commit(bytes), isA<SavedGamesCommitted>());

      for (final error in [
        'notAuthenticated',
        'payloadTooLarge',
        'commitFailed'
      ]) {
        await _reply(channel, _failure(error));
        expect(
          (await transport.commit(bytes) as SavedGamesTransportFailure)
              .error
              .name,
          error,
        );
      }

      await _reply(channel, _conflict('commit-conflict'));
      expect(await transport.commit(bytes), isA<SavedGamesConflict>());
    });
  });

  group('resolve', () {
    test('maps success, a repeated conflict, and typed failures', () async {
      final bytes = Uint8List.fromList([4, 0, 254]);
      await _reply(channel, {'status': 'resolved'},
          expectHandle: 'old', expectBytes: bytes);
      expect(await transport.resolve('old', bytes), isA<SavedGamesResolved>());

      await _reply(channel, _conflict('new-conflict'));
      final conflict =
          await transport.resolve('old', bytes) as SavedGamesConflict;
      expect(conflict.handle, 'new-conflict');

      for (final error in [
        'staleConflictHandle',
        'payloadTooLarge',
        'commitFailed'
      ]) {
        await _reply(channel, _failure(error));
        expect(
          (await transport.resolve('old', bytes) as SavedGamesTransportFailure)
              .error
              .name,
          error,
        );
      }
    });
  });

  test('zero-byte data is valid and distinct from a malformed result',
      () async {
    await _reply(channel, {'status': 'openedData', 'bytes': Uint8List(0)});
    expect((await transport.open() as SavedGamesOpenedData).bytes, isEmpty);

    await _reply(channel, Uint8List(0));
    expect(
      (await transport.open() as SavedGamesTransportFailure).error,
      SavedGamesTransportError.invalidNativeResult,
    );
  });
}

Future<void> _reply(
  MethodChannel channel,
  Object? value, {
  String? expectHandle,
  Uint8List? expectBytes,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (expectHandle != null) {
      expect((call.arguments as Map<Object?, Object?>)['handle'], expectHandle);
    }
    if (expectBytes != null) {
      expect((call.arguments as Map<Object?, Object?>)['bytes'], expectBytes);
    }
    return value;
  });
}

Map<String, Object> _conflict(String handle) => {
      'status': 'conflict',
      'handle': handle,
      'snapshotBytes': Uint8List.fromList([1]),
      'conflictingSnapshotBytes': Uint8List.fromList([2]),
    };

Map<String, String> _failure(String errorCode) => {
      'status': 'failure',
      'errorCode': errorCode,
    };
