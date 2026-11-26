import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/widgets/setup_header.dart';

import 'support/expect_whole_words.dart';

void main() {
  for (final width in <double>[320, 390]) {
    for (final scale in <double>[1, 1.5, 2]) {
      testWidgets('setup header at width $width and scale $scale',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = SettingsService();
        addTearDown(settings.dispose);
        var backCount = 0;
        const backKey = Key('player-setup-back');

        for (final title in <String>[
          'Number Type',
          'Game Setup',
          'Player 2 Setup',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SetupHeader(
                        title: title,
                        subtitle: 'Second player, your turn',
                        onBack: () => backCount++,
                        s: settings,
                        backKey: backKey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(title), findsOneWidget);
          expectWholeWords(tester, title);
          expectWholeWords(tester, 'Second player, your turn');
          expect(tester.getSize(find.byKey(backKey)), const Size(48, 48));
          final titleRect = tester.getRect(find.text(title));
          expect(titleRect.center.dx, closeTo(width / 2, 1));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(backKey));
          await tester.pumpAndSettle();
        }
        expect(backCount, 3);
      });
    }
  }
}
