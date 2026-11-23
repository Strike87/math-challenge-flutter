import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';

import 'visual_parity_test.dart'
    show MockAudioService, TestAppWrapper, loadAppFonts, setTestDevice;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  for (final size in <Size>[const Size(320, 568), const Size(390, 844)]) {
    for (final scale in <double>[1, 1.5, 2]) {
      testWidgets('challenge cards have equal row heights: $size at $scale',
          (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
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
        final state =
            GameState(settings: settings, audio: MockAudioService());
        await state.load();
        state.dailyBoss = GameConfig.dailyBosses.first;
        state.dailyBossDateKey = '2026-06-28';
        addTearDown(state.dispose);
        await setTestDevice(tester, logicalSize: size);

        await tester.pumpWidget(
          TestAppWrapper(
            state: state,
            child: Scaffold(
              body: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const MenuScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final names = <String>[
          'Master Challenge',
          'Target Clash',
          'Daily IQ Spark',
          state.dailyBoss?.name ?? 'Daily Boss',
        ];
        final rects = <Rect>[];
        for (final name in names) {
          final title = find.text(name);
          expect(title, findsOneWidget);
          final card = find.ancestor(
            of: title,
            matching: find.byType(InkWell),
          ).first;
          rects.add(tester.getRect(card));
        }
        expect((rects[0].height - rects[1].height).abs(), lessThan(1));
        expect((rects[2].height - rects[3].height).abs(), lessThan(1));
        expect(rects[0].left, lessThan(rects[1].left));
        expect(rects[2].left, lessThan(rects[3].left));
        expect(tester.takeException(), isNull);

        final footer = find.text(
          '🎓 Designed by Mr. Mohamed Khairy, Mathematics Supervisor',
        );
        expect(footer, findsOneWidget);
        expect(tester.widget<Text>(footer).maxLines, 1);
        expect(tester.widget<Text>(footer).softWrap, false);
      });
    }
  }
}
