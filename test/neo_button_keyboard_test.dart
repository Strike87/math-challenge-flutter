import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/widgets/common.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('NeoButton mouse activation preserves press animation',
      (tester) async {
    final cases = <({String label, bool outlined, IconData? icon})>[
      (label: 'Filled', outlined: false, icon: null),
      (label: 'Outlined', outlined: true, icon: null),
      (label: 'Icon', outlined: false, icon: Icons.add),
    ];

    for (var index = 0; index < cases.length; index++) {
      final testCase = cases[index];
      var presses = 0;
      await _pump(
        tester,
        NeoButton(
          label: testCase.label,
          outlined: testCase.outlined,
          icon: testCase.icon,
          onPressed: () => presses++,
        ),
      );

      final inkWell = find.byType(InkWell);
      expect(
        tester.widget<InkWell>(inkWell).borderRadius,
        BorderRadius.circular(testCase.outlined ? 18 : 24),
      );

      final mouse = TestPointer(index + 1, PointerDeviceKind.mouse);
      final center = tester.getCenter(inkWell);
      await tester.sendEventToBinding(mouse.hover(center));
      await tester.sendEventToBinding(mouse.down(center));
      await tester.pump();
      expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.95);
      expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
          const Offset(0, 0.04));

      await tester.sendEventToBinding(mouse.up());
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
          Offset.zero);
      expect(presses, 1);

      await tester.sendEventToBinding(mouse.down(center));
      await tester.pump();
      expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.95);
      expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
          const Offset(0, 0.04));
      await tester.sendEventToBinding(mouse.cancel());
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
          Offset.zero);
      expect(presses, 1);
      await tester.sendEventToBinding(mouse.removePointer());
    }
  });

  testWidgets('NeoButton keyboard traversal activates each control once',
      (tester) async {
    var firstPresses = 0;
    var secondPresses = 0;
    await _pump(
      tester,
      Row(
        children: [
          NeoButton(label: 'First', onPressed: () => firstPresses++),
          NeoButton(label: 'Second', onPressed: () => secondPresses++),
        ],
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('First'))).hasFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
        tester
            .widgetList<AnimatedScale>(find.byType(AnimatedScale))
            .first
            .scale,
        0.95);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 100));
    expect(firstPresses, 1);
    expect(secondPresses, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(Focus.of(tester.element(find.text('Second'))).hasFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(
        tester.widgetList<AnimatedScale>(find.byType(AnimatedScale)).last.scale,
        0.95);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 100));
    expect(firstPresses, 1);
    expect(secondPresses, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(Focus.of(tester.element(find.text('First'))).hasFocus, isTrue);
    expect(firstPresses, 1);
    expect(secondPresses, 1);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: false,
      reduceMotion: false,
      animSpeed: 1,
    );
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    ),
  );
}
