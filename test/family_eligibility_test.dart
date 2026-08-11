import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_controller.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/data/play_games_saved_games_transport.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/family/presentation/family_age_gate_screen.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/play_games.dart';
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

  test('stored ranges parse safely and retain the existing eligibility policy',
      () {
    expect(
      parseFamilyAgeRange(FamilyAgeRange.under13.name)?.eligibility,
      FamilyEligibility.child,
    );
    expect(
      parseFamilyAgeRange(FamilyAgeRange.teen13to17.name)?.eligibility,
      FamilyEligibility.eligible,
    );
    expect(
      parseFamilyAgeRange(FamilyAgeRange.adult18plus.name)?.eligibility,
      FamilyEligibility.eligible,
    );
    expect(parseFamilyAgeRange('adult'), isNull);
    expect(parseFamilyAgeRange(' adult18plus '), isNull);
  });

  test('only a valid v2 range resolves the family gate', () async {
    for (final values in [
      <String, Object>{},
      <String, Object>{
        GameState.familyGateVersionStorageKey: 1,
        'mc_familyEligibilityDate': '2000-01-01',
      },
      <String, Object>{
        GameState.familyGateVersionStorageKey:
            GameState.familyGateSchemaVersion,
      },
      <String, Object>{
        GameState.familyGateVersionStorageKey:
            GameState.familyGateSchemaVersion,
        GameState.familyAgeRangeStorageKey: 'invalid',
      },
    ]) {
      SharedPreferences.setMockInitialValues(values);
      await Storage.init();
      final games = _RecordingPlayGames(authenticated: true);
      final state = _state(games);
      await state.load();

      expect(state.familyEligibility, FamilyEligibility.unresolved);
      expect(state.familyAgeRange, isNull);
      expect(state.isPlayGamesEligible, isFalse);
      await state.checkPlayGamesConnection();
      expect(games.initializeCalls, 0);
      state.dispose();
    }
  });

  test('stored range eligibility controls PGS and cloud startup', () async {
    for (final entry in [
      (FamilyAgeRange.under13, FamilyEligibility.child, 0),
      (FamilyAgeRange.teen13to17, FamilyEligibility.eligible, 1),
      (FamilyAgeRange.adult18plus, FamilyEligibility.eligible, 1),
    ]) {
      SharedPreferences.setMockInitialValues({
        GameState.familyGateVersionStorageKey:
            GameState.familyGateSchemaVersion,
        GameState.familyAgeRangeStorageKey: entry.$1.name,
      });
      await Storage.init();
      final games = _RecordingPlayGames(authenticated: true);
      final state = _state(games);
      final service = _RecordingCloudService(state);
      final controller = CloudSaveController(
        state: state,
        service: service,
        localLoad: state.load(),
      );

      await controller.startAfterFirstFrame();

      expect(state.familyEligibility, entry.$2);
      expect(games.initializeCalls, entry.$3);
      expect(games.authenticationChecks, entry.$3);
      expect(service.syncCalls, entry.$3);
      state.dispose();
      controller.dispose();
    }
  });

  test('submission succeeds when best-effort v1 cleanup fails', () async {
    SharedPreferences.setMockInitialValues({
      GameState.familyGateVersionStorageKey: 1,
      'mc_familyEligibilityDate': '2000-01-01',
    });
    await Storage.init();
    Storage.writeFailureHook = (key, operation) {
      if (key == 'mc_familyEligibilityDate' && operation == 'remove') {
        throw StateError('legacy cleanup failed');
      }
    };
    addTearDown(() => Storage.writeFailureHook = null);
    final state = _state(_RecordingPlayGames(authenticated: true));

    expect(await state.submitFamilyAgeRange(FamilyAgeRange.teen13to17), isTrue);
    expect(state.familyAgeRange, FamilyAgeRange.teen13to17);
    expect(state.familyEligibility, FamilyEligibility.eligible);
    expect(
      Storage.getString(GameState.familyAgeRangeStorageKey, ''),
      FamilyAgeRange.teen13to17.name,
    );
    expect(
      Storage.getInt(GameState.familyGateVersionStorageKey, 0),
      GameState.familyGateSchemaVersion,
    );
    expect(Storage.getString('mc_familyEligibilityDate', ''), '2000-01-01');
    state.dispose();
  });

  test('family-gate resume joins startup in flight and syncs exactly once',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final games = _RecordingPlayGames(authenticated: true);
    final state = _state(games);
    final localLoad = Completer<void>();
    final service = _RecordingCloudService(state);
    final controller = CloudSaveController(
      state: state,
      service: service,
      localLoad: localLoad.future,
    );
    addTearDown(state.dispose);
    addTearDown(controller.dispose);

    final startup = controller.startAfterFirstFrame();
    expect(
        await state.submitFamilyAgeRange(FamilyAgeRange.adult18plus), isTrue);
    final resumed = controller.resumeAfterFamilyGate();
    localLoad.complete();
    await Future.wait([startup, resumed]);

    expect(games.initializeCalls, 1);
    expect(games.authenticationChecks, 1);
    expect(service.syncCalls, 1);
  });

  testWidgets('age-range gate requires a selection and keeps under-13 local',
      (tester) async {
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    var nativeCloudCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (_) async {
      nativeCloudCalls++;
      return {'status': 'openedEmpty'};
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final games = _RecordingPlayGames(authenticated: true);

    await tester.pumpWidget(MathChallengeApp(
      adService: const UnavailableAdMobService(),
      iapAdapter: const DevIapPurchaseAdapter(isNativeRelease: false),
      playGamesService: games,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Choose your age group'), findsOneWidget);
    expect(find.byType(FamilyAgeGateScreen), findsOneWidget);
    expect(
      find.text('This helps us provide the right game features.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('12 or younger'), findsOneWidget);
    expect(find.text('13–17'), findsOneWidget);
    expect(find.text('18 or older'), findsOneWidget);
    expect(find.text('MATH'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('familyAgeRangeContinue')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const ValueKey('familyAgeRange_under13')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('familyAgeRangeContinue')));
    await tester.pumpAndSettle();

    expect(find.byType(FamilyAgeGateScreen), findsNothing);
    expect(games.initializeCalls, 0);
    expect(games.authenticationChecks, 0);
    expect(nativeCloudCalls, 0);
    expect(
      Storage.getString(GameState.familyAgeRangeStorageKey, ''),
      FamilyAgeRange.under13.name,
    );
    expect(
      Storage.getInt(GameState.familyGateVersionStorageKey, 0),
      GameState.familyGateSchemaVersion,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().where((key) {
        final lower = key.toLowerCase();
        return lower.contains('birth') ||
            lower.contains('dob') ||
            lower.contains('eligibilitydate');
      }),
      isEmpty,
    );

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Play Games'), findsNothing);
    expect(find.text('Cloud Save'), findsNothing);
    expect(find.text('Reset Everywhere'), findsNothing);
    expect(find.text('RESTART GAME PROGRESS'), findsOneWidget);
    expect(
      find.text(
        'Erase game progress on this device. Settings, purchases, and age eligibility will be kept.',
      ),
      findsOneWidget,
    );
    expect(find.text('Restore Purchases'), findsOneWidget);

    final restartRow = find.ancestor(
      of: find.text('RESTART GAME PROGRESS'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(restartRow);
    await tester.tap(restartRow);
    await tester.pumpAndSettle();
    expect(find.text('Restart Game Progress?'), findsOneWidget);
    expect(
      find.text(
        'Coins, scores, mastery, achievements, player names, avatars, and Quest progress will be erased from this device. Settings, purchases, and age eligibility will remain. This can’t be undone.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Older cloud saves'), findsNothing);
  });

  test('child guards manual PGS/cloud calls and normal reset retains the gate',
      () async {
    SharedPreferences.setMockInitialValues({
      GameState.familyGateVersionStorageKey: GameState.familyGateSchemaVersion,
      GameState.familyAgeRangeStorageKey: FamilyAgeRange.under13.name,
    });
    await Storage.init();
    final games = _RecordingPlayGames(authenticated: true);
    final state = _state(games);
    await state.load();
    final service = _RecordingCloudService(state);
    final controller = CloudSaveController(
      state: state,
      service: service,
      localLoad: Future.value(),
    );

    await state.checkPlayGamesConnection();
    await state.connectPlayGames();
    await controller.sync();
    await controller.connectThenSync();
    await state.resetAllData();

    expect(games.initializeCalls, 0);
    expect(games.authenticationChecks, 0);
    expect(games.connectCalls, 0);
    expect(service.syncCalls, 0);
    expect(
      Storage.getString(GameState.familyAgeRangeStorageKey, ''),
      FamilyAgeRange.under13.name,
    );
    expect(
      Storage.getInt(GameState.familyGateVersionStorageKey, 0),
      GameState.familyGateSchemaVersion,
    );
    state.dispose();
    controller.dispose();
  });

  test('child and unresolved restart locally without PGS or cloud calls',
      () async {
    for (final eligibility in [
      FamilyEligibility.child,
      FamilyEligibility.unresolved,
    ]) {
      final storedFamilyValues = eligibility == FamilyEligibility.child
          ? <String, Object>{
              GameState.familyGateVersionStorageKey:
                  GameState.familyGateSchemaVersion,
              GameState.familyAgeRangeStorageKey: FamilyAgeRange.under13.name,
            }
          : <String, Object>{};
      SharedPreferences.setMockInitialValues(storedFamilyValues);
      await Storage.init();
      final games = _RecordingPlayGames(authenticated: true);
      final state = _state(games);
      await state.load();
      state.coins = 42;
      final service = _RecordingCloudService(state);
      final controller = CloudSaveController(
        state: state,
        service: service,
        localLoad: Future.value(),
      );

      await controller.resetEverywhere();

      expect(state.familyEligibility, eligibility);
      expect(state.coins, 0);
      expect(state.cloudResetGeneration, 1);
      expect(state.cloudDirty, isTrue);
      expect(controller.status, CloudSaveStatus.changesPendingLocally);
      expect(games.initializeCalls, 0);
      expect(games.authenticationChecks, 0);
      expect(games.connectCalls, 0);
      expect(service.syncCalls, 0);
      expect(
        Storage.getString(GameState.familyAgeRangeStorageKey, ''),
        eligibility == FamilyEligibility.child
            ? FamilyAgeRange.under13.name
            : '',
      );
      expect(
        Storage.getInt(GameState.familyGateVersionStorageKey, 0),
        eligibility == FamilyEligibility.child
            ? GameState.familyGateSchemaVersion
            : 0,
      );
      state.dispose();
      controller.dispose();
    }
  });

  test('Android removes auto-init and safely handles every pre-init PGS path',
      () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final application = File(
      'android/app/src/main/kotlin/com/mohamedk/mathchallenge/'
      'MathChallengeApplication.kt',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/mohamedk/mathchallenge/MainActivity.kt',
    ).readAsStringSync();
    final savedGames = File(
      'android/app/src/main/kotlin/com/mohamedk/mathchallenge/'
      'PlayGamesSavedGamesTransport.kt',
    ).readAsStringSync();

    expect(
        manifest, contains('xmlns:tools="http://schemas.android.com/tools"'));
    expect(
      manifest,
      contains('com.google.android.gms.games.provider.PlayGamesInitProvider'),
    );
    expect(RegExp(r'tools:node="remove"').allMatches(manifest), hasLength(1));
    expect(application, isNot(contains('PlayGamesSdk')));
    expect(activity, contains('"initializePgs"'));
    expect(activity, contains('PlayGamesInitialization.initialize(this)'));
    expect(
      RegExp(r'if \(!PlayGamesInitialization\.isInitialized\)')
          .allMatches(activity),
      hasLength(3),
    );
    expect(activity, isNot(contains('PGS_NOT_INITIALIZED')));
    final normalizedActivity = activity.replaceAll('\r\n', '\n');
    expect(
      normalizedActivity,
      contains(
        'if (!PlayGamesInitialization.isInitialized) {\n'
        '                            result.success(null)',
      ),
    );
    expect(savedGames, contains('if (!PlayGamesInitialization.isInitialized)'));
    expect(savedGames, contains('failure("notAuthenticated")'));
  });
}

GameState _state(_RecordingPlayGames games) {
  final settings = SettingsService();
  return GameState(
    settings: settings,
    audio: AudioService(settings),
    playGamesService: games,
  );
}

class _RecordingPlayGames extends PlayGamesService {
  _RecordingPlayGames({required this.authenticated});

  final bool authenticated;
  int initializeCalls = 0;
  int authenticationChecks = 0;
  int connectCalls = 0;
  Completer<bool>? authenticationGate;

  @override
  Future<void> initializePgs() async {
    initializeCalls++;
  }

  @override
  Future<bool> isAuthenticated() async {
    authenticationChecks++;
    return authenticationGate == null
        ? authenticated
        : await authenticationGate!.future;
  }

  @override
  Future<bool> connect() async {
    connectCalls++;
    return authenticated;
  }

  @override
  Future<void> unlockAchievement(String localAchievementId) async {}
}

class _RecordingCloudService extends CloudSaveService {
  _RecordingCloudService(GameState state)
      : super(state: state, transport: _NoopTransport());

  int syncCalls = 0;

  @override
  Future<CloudSyncResult> sync() async {
    syncCalls++;
    return const CloudSyncNoChange();
  }
}

class _NoopTransport implements SavedGamesTransport {
  @override
  Future<SavedGamesCommitResult> commit(Uint8List bytes) async =>
      SavedGamesCommitted();

  @override
  Future<SavedGamesOpenResult> open() async => SavedGamesOpenedEmpty();

  @override
  Future<SavedGamesResolveResult> resolve(
          String handle, Uint8List bytes) async =>
      SavedGamesResolved();
}
