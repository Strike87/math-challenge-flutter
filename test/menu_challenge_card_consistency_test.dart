import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      testWidgets('challenge cards adapt layout: $size at $scale',
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

        Future<void> capturePreview(String suffix) async {
          if (Platform.environment['CAPTURE_MENU_PREVIEWS'] != '1') return;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('visual-root')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            try {
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              final directory = Directory('build/menu-previews');
              await directory.create(recursive: true);
              await File(
                '${directory.path}/menu-${size.width.toInt()}-${(scale * 100).toInt()}$suffix.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        await capturePreview('');

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
          final labels = find.descendant(
            of: card,
            matching: find.byType(RichText),
          );
          for (final element in labels.evaluate()) {
            final paragraph = element.renderObject;
            if (paragraph is! RenderParagraph) continue;
            final text = paragraph.text.toPlainText();
            if (text != name && !text.contains(' ')) continue;
            expect(paragraph.didExceedMaxLines, isFalse,
                reason: 'Truncated label: $text');
            for (final match in RegExp(r'\S+').allMatches(text)) {
              final boxes = paragraph.getBoxesForSelection(
                TextSelection(baseOffset: match.start, extentOffset: match.end),
              );
              if (boxes.isEmpty) continue;
              final firstTop = boxes.first.top;
              expect(
                boxes.every((box) => (box.top - firstTop).abs() < 1),
                isTrue,
                reason: 'Word split across lines: ${match.group(0)} in $text',
              );
              for (final box in boxes) {
                expect(box.left, greaterThanOrEqualTo(-1));
                expect(box.right, lessThanOrEqualTo(paragraph.size.width + 1));
              }
            }
          }
        }
        expect((rects[0].height - rects[1].height).abs(), lessThan(1));
        expect((rects[2].height - rects[3].height).abs(), lessThan(1));
        expect(rects[0].left, lessThan(rects[1].left));
        expect(rects[2].left, lessThan(rects[3].left));
        expect(rects[0].top, closeTo(rects[1].top, 1));
        expect(rects[2].top, closeTo(rects[3].top, 1));
        expect(rects[2].top, greaterThanOrEqualTo(rects[0].bottom));
        expect(tester.takeException(), isNull);

        final footer = find.text(
          '🎓 Designed by Mr. Mohamed Khairy, Mathematics Supervisor',
        );
        expect(footer, findsOneWidget);
        expect(tester.widget<Text>(footer).maxLines, 1);
        expect(tester.widget<Text>(footer).softWrap, false);

        final viewport = find.byType(SingleChildScrollView);
        expect(viewport, findsOneWidget);
        final arena = find.byKey(const Key('weak-skills-practice-row'));
        expect(arena, findsOneWidget);
        await tester.ensureVisible(arena);
        await tester.pumpAndSettle();
        expect(tester.getRect(viewport).overlaps(tester.getRect(arena)), isTrue);
        expect(tester.takeException(), isNull);
        await capturePreview('-arena');

        await tester.ensureVisible(footer);
        await tester.pumpAndSettle();
        final viewportRect = tester.getRect(viewport);
        final footerRect = tester.getRect(footer);
        expect(footerRect.top, greaterThanOrEqualTo(viewportRect.top - 1));
        expect(footerRect.bottom, lessThanOrEqualTo(viewportRect.bottom + 1));
        expect(footerRect.left, greaterThanOrEqualTo(viewportRect.left - 1));
        expect(footerRect.right, lessThanOrEqualTo(viewportRect.right + 1));
        expect(tester.takeException(), isNull);
        final dockLabels = <String>[
          'Hall of Fame',
          'Achievements',
          'Shop',
          'Skills',
          'Daily',
        ];
        final dockRects = <Rect>[];
        for (final label in dockLabels) {
          final finder = find.text(label);
          expect(finder, findsOneWidget);
          final text = tester.widget<Text>(finder);
          expect(text.maxLines, 1);
          expect(text.softWrap, false);
          dockRects.add(tester.getRect(finder));
        }
        for (var i = 0; i < dockRects.length; i++) {
          expect(dockRects[i].center.dy, closeTo(dockRects.first.center.dy, 1));
          expect(dockRects[i].width, greaterThan(0));
          if (i > 0) {
            expect(dockRects[i].left - dockRects[i - 1].right,
                greaterThanOrEqualTo(6));
          }
        }
        await capturePreview('-bottom');
      });
    }
  }
}
