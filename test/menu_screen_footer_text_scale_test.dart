import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/game_config.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';

import 'visual_parity_test.dart' show MockAudioService, TestAppWrapper, loadAppFonts, setTestDevice;

const _attribution =
    '🎓 Designed by Mr. Mohamed Khairy, Mathematics Supervisor';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  for (final size in <Size>[const Size(320, 568), const Size(390, 844)]) {
    for (final scale in <double>[1, 1.5, 2]) {
      testWidgets('menu attribution wraps at $size, text scale $scale',
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
        final state = GameState(settings: settings, audio: MockAudioService());
        await state.load();
        state.dailyBoss = GameConfig.dailyBosses.first;
        state.dailyBossDateKey = '2026-06-28';
        addTearDown(state.dispose);

        await setTestDevice(tester, logicalSize: size);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
            child: TestAppWrapper(state: state, child: const Scaffold(body: MenuScreen())),
          ),
        );
        await tester.pumpAndSettle();

        final footer = find.text(_attribution);
        expect(footer, findsOneWidget);
        final text = tester.widget<Text>(footer);
        expect(text.softWrap, isTrue);
        expect(text.maxLines, isNull);
        expect(text.textAlign, TextAlign.center);
        expect(find.ancestor(of: footer, matching: find.byType(FittedBox)),
            findsNothing);

        await tester.ensureVisible(footer);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final paragraph = tester.renderObject<RenderParagraph>(footer);
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
          textAlign: paragraph.textAlign,
        )..layout(maxWidth: paragraph.size.width);
        final lines = painter.computeLineMetrics();
        expect(lines, isNotEmpty);
        if (scale == 2) {
          expect(lines.length, greaterThanOrEqualTo(2));
        }
        painter.dispose();

        final rect = tester.getRect(footer);
        final safe = tester.getRect(find.byType(Scaffold));
        expect(rect.left, greaterThanOrEqualTo(safe.left));
        expect(rect.right, lessThanOrEqualTo(safe.right));
        expect(rect.top, greaterThanOrEqualTo(safe.top));
        expect(rect.bottom, lessThanOrEqualTo(safe.bottom));
      });
    }
  }
}
