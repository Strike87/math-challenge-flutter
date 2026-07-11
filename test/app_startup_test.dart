import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app startup paints menu after splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('modal keeps settings visible without blanking app',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    SharedPreferences.setMockInitialValues({'mc_reduceMotion': true});
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
    SharedPreferences.setMockInitialValues({});
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
