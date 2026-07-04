import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android production safety config is explicit', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final gradle = File('android/app/build.gradle').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final modals = File('lib/widgets/modals.dart').readAsStringSync();

    expect(manifest, contains('com.android.vending.BILLING'));
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:supportsRtl="true"'));
    expect(manifest, contains(r'${adMobApplicationId}'));
    expect(gradle, contains('applicationId = "com.mohamedk.mathchallenge"'));
    expect(gradle, isNot(contains('com.example.')));
    expect(gradle, contains('minifyEnabled = false'));
    expect(gradle, contains('shrinkResources = false'));
    expect(gradle, contains('ca-app-pub-5674349229505017~2144672982'));
    expect(main, contains('ADMOB_USE_TEST_ADS'));
    expect(main, isNot(contains('ADMOB_BANNER_AD_UNIT_ID')));
    expect(main, isNot(contains('ca-app-pub-3940256099942544/')));
    for (final price in [r'$0.99', r'$3.99', r'$7.99', r'$1.99']) {
      expect(modals, isNot(contains(price)));
    }
  });
}
