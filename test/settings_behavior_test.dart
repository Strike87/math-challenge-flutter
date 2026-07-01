import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SettingsService makeSettings() {
    return SettingsService()
      ..load(
        dark: false,
        sound: true,
        vibration: true,
        dyslexia: false,
        colorblind: false,
        lowPerf: false,
        reduceMotion: false,
        animSpeed: 1.0,
      );
  }

  test('performance mode forces original animation speed values', () async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final settings = makeSettings();

    settings.toggleLowPerf();
    expect(settings.lowPerf, isTrue);
    expect(settings.animSpeed, 0.3);
    expect(settings.duration(1000), const Duration(milliseconds: 300));
    expect(Storage.getBool('mc_lowPerf', false), isTrue);
    expect(Storage.getDouble('mc_animSpeed', 1.0), 0.3);

    settings.toggleLowPerf();
    expect(settings.lowPerf, isFalse);
    expect(settings.animSpeed, 1.0);
    expect(settings.duration(1000), const Duration(milliseconds: 1000));
    expect(Storage.getBool('mc_lowPerf', true), isFalse);
    expect(Storage.getDouble('mc_animSpeed', 0.3), 1.0);
  });

  test('manual or platform reduce motion disables shared animation duration',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final settings = makeSettings()..setAnimSpeed(2.0);

    expect(settings.duration(1000), const Duration(milliseconds: 2000));

    settings.setPlatformReduceMotion(true);
    expect(settings.manualReduceMotion, isFalse);
    expect(settings.reduceMotion, isTrue);
    expect(settings.duration(1000), Duration.zero);

    settings.setPlatformReduceMotion(false);
    settings.toggleReduceMotion();
    expect(settings.manualReduceMotion, isTrue);
    expect(settings.reduceMotion, isTrue);
    expect(settings.duration(1000), Duration.zero);
    expect(Storage.getBool('mc_reduceMotion', false), isTrue);
  });

  test('color-blind palette remaps visible accent colors', () async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final settings = makeSettings();

    expect(settings.accent(GameConfig.coral), const Color(GameConfig.coral));
    expect(settings.opColor(Operation.addition), const Color(GameConfig.mint));

    settings.toggleColorblind();

    expect(settings.accent(GameConfig.coral),
        isNot(const Color(GameConfig.coral)));
    expect(settings.opColor(Operation.addition),
        isNot(const Color(GameConfig.mint)));
  });

  testWidgets('reduce motion hides big answer emoji reactions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final settings = makeSettings();

    await tester.pumpWidget(_emojiHost(settings));
    expect(find.text('🔥'), findsOneWidget);

    settings.toggleReduceMotion();
    await tester.pumpWidget(_emojiHost(settings));
    expect(find.text('🔥'), findsNothing);
  });
}

Widget _emojiHost(SettingsService settings) {
  return ChangeNotifierProvider<SettingsService>.value(
    value: settings,
    child: const MaterialApp(
      home: Scaffold(
        body: BigEmojiOverlay(emoji: '🔥', visible: true),
      ),
    ),
  );
}
