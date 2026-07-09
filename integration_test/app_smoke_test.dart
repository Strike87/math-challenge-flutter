import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: menu to gameplay answer grid', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();

    await tester.pumpWidget(const MathChallengeApp(
      adService: UnavailableAdMobService(),
      iapAdapter: DevIapPurchaseAdapter(isNativeRelease: false),
    ));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('MATH'), findsOneWidget);
    expect(find.text('CHALLENGE'), findsOneWidget);
    expect(find.text('Master Challenge'), findsOneWidget);

    await tester.tap(find.text('ADDITION'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Choose Number Type'), findsOneWidget);

    await tester.tap(find.text('Natural Numbers'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Game Setup'), findsOneWidget);

    await tester.tap(find.text('Next: Player Setup →'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Player Setup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('player-setup-primary')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(GridView), findsOneWidget);
  });
}
