import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/main.dart';
import 'package:math_challenge/services/admob.dart';
import 'package:math_challenge/services/iap.dart';
import 'package:math_challenge/services/storage.dart';
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
}
