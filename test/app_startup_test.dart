import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/features/family/domain/family_eligibility.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_controller.dart';
import 'package:math_challenge/features/cloud_save/application/cloud_save_service.dart';
import 'package:math_challenge/features/cloud_save/domain/cloud_progress_document.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/play_games.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app startup paints menu after splash', (tester) async {
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();

    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.text('MATH'), findsOneWidget);
    expect(find.text('CHALLENGE'), findsOneWidget);
    expect(find.text('Master Challenge'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
      isFalse,
    );
  });

  testWidgets('startup checks authentication only after the first frame',
      (tester) async {
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();
    final playGames = _UnauthenticatedPlayGames();

    tester.binding.attachRootWidget(tester.binding.wrapWithDefaultView(
      MathChallengeApp(
        adService: UnavailableAdMobService(),
        iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
        playGamesService: playGames,
      ),
    ));
    expect(playGames.authenticationChecks, 0);

    await tester.pump();

    expect(find.text('MATH'), findsOneWidget);
    expect(playGames.authenticationChecks, 1);
    final controller = Provider.of<CloudSaveController>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    expect(controller.status, CloudSaveStatus.notAuthenticated);
  });

  testWidgets(
      'startup orders first frame, local load, authentication, and sync',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    final events = <String>[];
    final iap = _HeldRestoreIap(events);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (call) async {
      if (call.method == 'isAuthenticated') events.add('auth');
      return true;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (call) async {
      if (call.method == 'openSnapshot') events.add('sync');
      return switch (call.method) {
        'openSnapshot' => {'status': 'openedEmpty'},
        'commitSnapshot' => {'status': 'committed'},
        _ => null,
      };
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();

    await tester.pumpWidget(MathChallengeApp(
      adService: const UnavailableAdMobService(),
      iapAdapter: iap,
    ));
    events.add('first frame');
    expect(find.text('MATH'), findsOneWidget);
    expect(events, ['local load started', 'first frame']);

    iap.complete();
    await tester.pumpAndSettle();
    expect(events, [
      'local load started',
      'first frame',
      'local load complete',
      'auth',
      'sync'
    ]);
  });

  testWidgets('startup keeps the first frame usable until cloud sync finishes',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    final opened = Completer<Object?>();
    var checks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (call) async {
      if (call.method == 'isAuthenticated') checks++;
      return call.method == 'isAuthenticated';
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (call) => opened.future);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();

    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    expect(find.text('MATH'), findsOneWidget);
    expect(checks, 1);
    expect(find.text('Master Challenge'), findsOneWidget);
    expect(find.byKey(const ValueKey('modalRouter')), findsOneWidget);
    opened.complete({'status': 'openedEmpty'});
    await tester.pumpAndSettle();
  });

  testWidgets('unauthenticated startup stays silent and never connects',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    var connects = 0;
    var opens = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (call) async {
      if (call.method == 'connect') connects++;
      return false;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (call) async {
      opens++;
      return {'status': 'openedEmpty'};
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();
    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('MATH'), findsOneWidget);
    expect(connects, 0);
    expect(opens, 0);
    expect(find.byKey(const ValueKey('modalRouter')), findsOneWidget);
  });

  testWidgets('authenticated startup runs once across provider rebuilds',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    var checks = 0;
    var opens = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (call) async {
      if (call.method == 'isAuthenticated') checks++;
      return true;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (call) async {
      if (call.method == 'openSnapshot') opens++;
      return switch (call.method) {
        'openSnapshot' => {'status': 'openedEmpty'},
        'commitSnapshot' => {'status': 'committed'},
        _ => null,
      };
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();
    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pumpAndSettle();
    final settings = Provider.of<SettingsService>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    settings.toggleDark();
    await tester.pumpAndSettle();

    expect(checks, 1);
    expect(opens, 1);
    expect(find.text('MATH'), findsOneWidget);
  });

  testWidgets('startup conflict stays on the usable menu without a modal',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (_) async => true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (call) async {
      if (call.method != 'openSnapshot') return null;
      return {
        'status': 'conflict',
        'handle': 'choice',
        'snapshotBytes': _documentBytes('a', 2, 1),
        'conflictingSnapshotBytes': _documentBytes('b', 4, 2),
      };
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();
    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pumpAndSettle();

    final controller = Provider.of<CloudSaveController>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );
    expect(controller.pendingChoice, isA<CloudSyncNativeCloudChoice>());
    expect(find.text('MATH'), findsOneWidget);
    expect(find.byKey(const ValueKey('modalRouter')), findsOneWidget);
  });

  testWidgets('startup restore updates the already-mounted menu',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (_) async => true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            savedGames,
            (call) async => switch (call.method) {
                  'openSnapshot' => {
                      'status': 'openedData',
                      'bytes': _documentBytes('cloud', 1, 7),
                    },
                  _ => null,
                });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();
    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    expect(find.text('0'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(find.text('MATH'), findsOneWidget);
  });

  testWidgets(
      'authenticated channel startup syncs without connecting or a modal',
      (tester) async {
    const playGames = MethodChannel('math_challenge/play_games');
    const savedGames = MethodChannel('math_challenge/play_games_saved_games');
    var connects = 0;
    var opens = 0;
    var commits = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playGames, (call) async {
      if (call.method == 'connect') connects++;
      return call.method == 'isAuthenticated';
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(savedGames, (call) async {
      if (call.method == 'openSnapshot') opens++;
      if (call.method == 'commitSnapshot') commits++;
      return switch (call.method) {
        'openSnapshot' => {'status': 'openedEmpty'},
        'commitSnapshot' => {'status': 'committed'},
        _ => null,
      };
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(playGames, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(savedGames, null);
    });
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();
    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    expect(find.text('MATH'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(connects, 0);
    expect(opens, 1);
    expect(commits, 0);
    expect(find.byKey(const ValueKey('modalRouter')), findsOneWidget);
  });

  testWidgets('modal keeps settings visible without blanking app',
      (tester) async {
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();

    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('MATH'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('reduce motion renders modal immediately', (tester) async {
    SharedPreferences.setMockInitialValues(
      _eligibleStorage({'mc_reduceMotion': true}),
    );
    await Storage.init();

    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('MATH'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('daily bonus keeps Packs open until Shop is closed',
      (tester) async {
    SharedPreferences.setMockInitialValues(_eligibleStorage());
    await Storage.init();

    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    final state = Provider.of<GameState>(
      tester.element(find.byType(Scaffold)),
      listen: false,
    );

    await tester.ensureVisible(find.text('Shop'));
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shopHub_packs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+20 Coins'));
    await tester.pumpAndSettle();

    expect(state.coins, GameState.dailyBonusCoins);
    expect(find.text('PACKS'), findsOneWidget);
    expect(find.text('Claimed'), findsOneWidget);

    await tester.tap(find.text('+20 Coins'));
    await tester.pumpAndSettle();
    expect(state.coins, GameState.dailyBonusCoins);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Shop'));
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shopHub_packs')), findsOneWidget);
    expect(find.byKey(const Key('shopBackToHub')), findsNothing);
  });
}

Map<String, Object> _eligibleStorage([Map<String, Object> values = const {}]) =>
    {
      GameState.familyGateVersionStorageKey: GameState.familyGateSchemaVersion,
      GameState.familyAgeRangeStorageKey: FamilyAgeRange.adult18plus.name,
      ...values,
    };

class _UnauthenticatedPlayGames extends PlayGamesService {
  int authenticationChecks = 0;

  @override
  Future<void> initializePgs() async {}

  @override
  Future<bool> isAuthenticated() async {
    authenticationChecks++;
    return false;
  }

  @override
  Future<bool> connect() async => false;

  @override
  Future<void> unlockAchievement(String localAchievementId) async {}
}

class _HeldRestoreIap implements IapPurchaseAdapter {
  _HeldRestoreIap(this.events);

  final List<String> events;
  final _restore = Completer<List<IapPurchase>>();

  void complete() => _restore.complete(const []);

  @override
  Future<void> buyProduct(IapProduct product) async {}

  @override
  Future<void> completePurchase(IapPurchase purchase) async {}

  @override
  String? priceFor(String productId) => null;

  @override
  Future<List<IapPurchase>> restorePurchases() async {
    events.add('local load started');
    final purchases = await _restore.future;
    events.add('local load complete');
    return purchases;
  }
}

Uint8List _documentBytes(String id, int revision, int coins) {
  final empty = CloudProgress.empty();
  return Uint8List.fromList(utf8.encode(CloudProgressDocument(
    schemaVersion: 2,
    revision: revision,
    revisionId: id,
    parentRevisionId: null,
    mergeParentRevisionIds: const [],
    resetGeneration: 0,
    updatedAtUtcMs: 1,
    progress: CloudProgress(
      coins: coins,
      gamesPlayed: 0,
      achievements: empty.achievements,
      operationQuestStars: empty.operationQuestStars,
      highScores: empty.highScores,
      skillMap: empty.skillMap,
      profile: empty.profile,
      economy: empty.economy,
    ),
  ).encode()));
}
