import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/play_games.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/modals.dart';
import 'package:provider/provider.dart';
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

  test(
      'canonical mapping contains every local ID once and every Google ID once',
      () {
    final localIds = GameConfig.achievementsDef.map((a) => a.id).toSet();
    expect(playGamesAchievementIds.keys.toSet(), localIds);
    expect(playGamesAchievementIds, hasLength(14));
    expect(playGamesAchievementIds.values, everyElement(isNotEmpty));
    expect(
      playGamesAchievementIds.values.toSet(),
      hasLength(playGamesAchievementIds.length),
    );
  });

  test('reconciliation is repeatable, unlocked-only, and failure-isolated',
      () async {
    final service = _FakePlayGamesService()
      ..failingAchievementIds.add('first_win');
    const local = {
      'first_win': true,
      'speed_demon': true,
      'perfect_score': false,
    };

    await service.reconcileUnlockedAchievements(local);
    await service.reconcileUnlockedAchievements(local);

    expect(
      service.unlockAttempts,
      ['first_win', 'speed_demon', 'first_win', 'speed_demon'],
    );
  });

  test('connection state and reconciliation do not alter local achievements',
      () async {
    final service = _FakePlayGamesService()
      ..authenticated = false
      ..connectResult = true;
    final state = await _makeState(service);
    addTearDown(state.dispose);
    state.achievements['first_win'] = true;

    await state.checkPlayGamesConnection();
    expect(
      state.playGamesConnectionState,
      PlayGamesConnectionState.disconnected,
    );
    expect(service.unlockAttempts, isEmpty);

    await state.connectPlayGames();
    expect(state.playGamesConnectionState, PlayGamesConnectionState.connected);
    expect(service.connectCalls, 1);
    expect(service.unlockAttempts, ['first_win']);
    expect(state.achievements['first_win'], isTrue);
  });

  test('local unlock mirrors only while connected and survives remote failure',
      () async {
    final connectedService = _FakePlayGamesService()
      ..authenticated = true
      ..failingAchievementIds.add('first_win');
    final connected = await _makeState(connectedService);
    addTearDown(connected.dispose);
    await connected.checkPlayGamesConnection();

    connected.unlockAch('first_win');
    await Future<void>.delayed(Duration.zero);

    expect(connected.achievements['first_win'], isTrue);
    expect(connected.newlyUnlocked.map((a) => a.id), contains('first_win'));
    expect(connectedService.unlockAttempts, ['first_win']);

    final disconnectedService = _FakePlayGamesService();
    final disconnected = await _makeState(disconnectedService);
    addTearDown(disconnected.dispose);
    disconnected.playGamesConnectionState =
        PlayGamesConnectionState.disconnected;
    disconnected.unlockAch('speed_demon');
    await Future<void>.delayed(Duration.zero);

    expect(disconnected.achievements['speed_demon'], isTrue);
    expect(disconnectedService.unlockAttempts, isEmpty);
  });

  test('reset makes no Play Games request', () async {
    final service = _FakePlayGamesService();
    final state = await _makeState(service);
    addTearDown(state.dispose);
    state.achievements['first_win'] = true;

    await state.resetAllData();

    expect(service.authenticationChecks, 0);
    expect(service.connectCalls, 0);
    expect(service.unlockAttempts, isEmpty);
    expect(state.achievements.values, everyElement(isFalse));
  });

  testWidgets('Settings shows states and dispatches Connect exactly once',
      (tester) async {
    final pendingConnect = Completer<bool>();
    final service = _FakePlayGamesService()
      ..connectFuture = pendingConnect.future;
    final state = await _makeState(service);
    addTearDown(state.dispose);
    state
      ..playGamesConnectionState = PlayGamesConnectionState.disconnected
      ..showModal(GameModal.settings);

    await tester.pumpWidget(_modalHost(state));
    await tester.pump();

    expect(find.text('Play Games'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Connect Play Games'), findsOneWidget);

    await tester.ensureVisible(find.text('Connect Play Games'));
    await tester.pump();
    await tester.tap(find.text('Connect Play Games'));
    await tester.tap(find.text('Connect Play Games'));
    await tester.pump();

    expect(service.connectCalls, 1);
    expect(find.text('Checking...'), findsOneWidget);

    pendingConnect.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Connect Play Games'), findsNothing);
  });

  testWidgets('post-frame authentication never blocks startup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final pendingAuthentication = Completer<bool>();
    final service = _FakePlayGamesService()
      ..authenticationFuture = pendingAuthentication.future;

    await tester.pumpWidget(MathChallengeApp(
      adService: const UnavailableAdMobService(),
      iapAdapter: const DevIapPurchaseAdapter(isNativeRelease: false),
      playGamesService: service,
    ));
    await tester.pump();

    expect(find.text('MATH'), findsOneWidget);
    expect(find.text('Master Challenge'), findsOneWidget);
    expect(service.authenticationChecks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable bridge leaves the app usable', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final service = _FakePlayGamesService()
      ..authenticationError = StateError(
        'unavailable',
      );

    await tester.pumpWidget(MathChallengeApp(
      adService: const UnavailableAdMobService(),
      iapAdapter: const DevIapPurchaseAdapter(isNativeRelease: false),
      playGamesService: service,
    ));
    await tester.pump();
    await tester.pump();

    final state = Provider.of<GameState>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    expect(
      state.playGamesConnectionState,
      PlayGamesConnectionState.unavailable,
    );
    expect(find.text('MATH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakePlayGamesService extends PlayGamesService {
  bool authenticated = false;
  bool connectResult = false;
  Future<bool>? authenticationFuture;
  Future<bool>? connectFuture;
  Object? authenticationError;
  int authenticationChecks = 0;
  int connectCalls = 0;
  final unlockAttempts = <String>[];
  final failingAchievementIds = <String>{};

  @override
  Future<bool> isAuthenticated() async {
    authenticationChecks++;
    if (authenticationError case final error?) throw error;
    return authenticationFuture == null
        ? authenticated
        : await authenticationFuture!;
  }

  @override
  Future<bool> connect() async {
    connectCalls++;
    return connectFuture == null ? connectResult : await connectFuture!;
  }

  @override
  Future<void> unlockAchievement(String localAchievementId) async {
    unlockAttempts.add(localAchievementId);
    if (failingAchievementIds.contains(localAchievementId)) {
      throw StateError('remote failure');
    }
  }
}

Future<GameState> _makeState(PlayGamesService playGamesService) async {
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
  final state = GameState(
    settings: settings,
    audio: AudioService(settings),
    playGamesService: playGamesService,
  );
  state.achievements = {
    for (final achievement in GameConfig.achievementsDef) achievement.id: false,
  };
  return state;
}

Widget _modalHost(GameState state) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameState>.value(value: state),
      ChangeNotifierProvider<SettingsService>.value(value: state.settings),
    ],
    child: const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(390, 700)),
        child: Scaffold(body: Stack(children: [ModalRouter()])),
      ),
    ),
  );
}
