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

  test('age 13 uses local date boundaries and conservative leap-day policy',
      () {
    final eligibility = FamilyEligibilityPolicy.eligibilityDateFor(
      DateTime(2013, 8, 11),
    );
    expect(eligibility, DateTime(2026, 8, 11));
    for (final boundary in [
      (DateTime(2026, 8, 10), false),
      (DateTime(2026, 8, 11), true),
      (DateTime(2026, 8, 12), true),
    ]) {
      expect(
        FamilyEligibilityPolicy.isEligible(eligibility, boundary.$1),
        boundary.$2,
      );
    }

    final leapEligibility = FamilyEligibilityPolicy.eligibilityDateFor(
      DateTime(2016, 2, 29),
    );
    expect(leapEligibility, DateTime(2029, 3, 1));
    expect(
      FamilyEligibilityPolicy.isEligible(
        leapEligibility,
        DateTime(2029, 2, 28),
      ),
      isFalse,
    );
    expect(
      FamilyEligibilityPolicy.isEligible(
        leapEligibility,
        DateTime(2029, 3, 1),
      ),
      isTrue,
    );
  });

  test('stored eligibility is re-evaluated before PGS and cloud startup',
      () async {
    for (final boundary in [
      (DateTime(2026, 8, 10), false),
      (DateTime(2026, 8, 11), true),
      (DateTime(2026, 8, 12), true),
    ]) {
      SharedPreferences.setMockInitialValues({
        GameState.familyGateVersionStorageKey:
            GameState.familyGateSchemaVersion,
        GameState.familyEligibilityDateStorageKey: '2026-08-11',
      });
      await Storage.init();
      final games = _RecordingPlayGames(authenticated: true);
      final state = _state(games, today: boundary.$1);
      final localLoad = state.load();
      final service = _RecordingCloudService(state);
      final controller = CloudSaveController(
        state: state,
        service: service,
        localLoad: localLoad,
      );

      await controller.startAfterFirstFrame();
      await controller.resumeAfterFamilyGate();

      expect(state.isPlayGamesEligible, boundary.$2);
      expect(games.initializeCalls, boundary.$2 ? 1 : 0);
      expect(games.authenticationChecks, boundary.$2 ? 1 : 0);
      expect(service.syncCalls, boundary.$2 ? 1 : 0);
      state.dispose();
      controller.dispose();
    }
  });

  test('eligibility freshness is checked again before PGS check and connect',
      () async {
    SharedPreferences.setMockInitialValues({
      GameState.familyGateVersionStorageKey: GameState.familyGateSchemaVersion,
      GameState.familyEligibilityDateStorageKey: '2026-08-11',
    });
    await Storage.init();
    var today = DateTime(2026, 8, 10);
    final games = _RecordingPlayGames(authenticated: false);
    final settings = SettingsService();
    final state = GameState(
      settings: settings,
      audio: AudioService(settings),
      playGamesService: games,
      localDateProvider: () => today,
    );
    addTearDown(state.dispose);
    await state.load();
    expect(state.isPlayGamesEligible, isFalse);

    today = DateTime(2026, 8, 11);
    await state.checkPlayGamesConnection();
    await state.connectPlayGames();

    expect(state.isPlayGamesEligible, isTrue);
    expect(games.initializeCalls, 1);
    expect(games.authenticationChecks, 1);
    expect(games.connectCalls, 1);
  });

  test('family-gate resume joins startup in flight and syncs exactly once',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final games = _RecordingPlayGames(authenticated: true);
    final state = _state(games, today: DateTime(2026, 8, 11));
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
    expect(await state.submitFamilyDateOfBirth('2000-01-01'), isTrue);
    final resumed = controller.resumeAfterFamilyGate();
    localLoad.complete();
    await Future.wait([startup, resumed]);

    expect(games.initializeCalls, 1);
    expect(games.authenticationChecks, 1);
    expect(service.syncCalls, 1);
  });

  testWidgets(
      'blank neutral gate validates input, stores no DOB, and keeps child local',
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
      localDateProvider: () => DateTime(2026, 8, 11),
    ));
    await tester.pumpAndSettle();

    final day = find.byKey(const ValueKey('familyDobDay'));
    final month = find.byKey(const ValueKey('familyDobMonth'));
    final year = find.byKey(const ValueKey('familyDobYear'));
    expect(find.text('Before you continue'), findsOneWidget);
    expect(find.byType(FamilyAgeGateScreen), findsOneWidget);
    expect(
      find.text('We use your age to provide an age-appropriate experience.'),
      findsOneWidget,
    );
    for (final field in [day, month, year]) {
      final textField = find.descendant(
        of: field,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(textField).controller!.text, isEmpty);
    }
    expect(find.text('MATH'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('familyDobContinue')));
    await tester.pump();
    expect(find.textContaining('valid date'), findsOneWidget);

    await tester.enterText(day, '12');
    await tester.enterText(month, '8');
    await tester.enterText(year, '2026');
    await tester.tap(find.byKey(const ValueKey('familyDobContinue')));
    await tester.pump();
    expect(find.textContaining('future'), findsOneWidget);

    await tester.enterText(day, '2');
    await tester.enterText(month, '1');
    await tester.enterText(year, '2020');
    await tester.tap(find.byKey(const ValueKey('familyDobContinue')));
    await tester.pumpAndSettle();

    expect(find.text('MATH'), findsOneWidget);
    expect(games.initializeCalls, 0);
    expect(games.authenticationChecks, 0);
    expect(nativeCloudCalls, 0);
    expect(
      Storage.getString(GameState.familyEligibilityDateStorageKey, ''),
      '2033-01-02',
    );
    expect(
      Storage.getInt(GameState.familyGateVersionStorageKey, 0),
      GameState.familyGateSchemaVersion,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().where((key) {
        final lower = key.toLowerCase();
        return lower.contains('birth') || lower.contains('dob');
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
      GameState.familyEligibilityDateStorageKey: '2033-01-02',
    });
    await Storage.init();
    final games = _RecordingPlayGames(authenticated: true);
    final state = _state(games, today: DateTime(2026, 8, 11));
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
      Storage.getString(GameState.familyEligibilityDateStorageKey, ''),
      '2033-01-02',
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
              GameState.familyEligibilityDateStorageKey: '2033-01-02',
            }
          : <String, Object>{};
      SharedPreferences.setMockInitialValues(storedFamilyValues);
      await Storage.init();
      final games = _RecordingPlayGames(authenticated: true);
      final state = _state(games, today: DateTime(2026, 8, 11));
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
        Storage.getString(GameState.familyEligibilityDateStorageKey, ''),
        eligibility == FamilyEligibility.child ? '2033-01-02' : '',
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

GameState _state(_RecordingPlayGames games, {required DateTime today}) {
  final settings = SettingsService();
  return GameState(
    settings: settings,
    audio: AudioService(settings),
    playGamesService: games,
    localDateProvider: () => today,
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
