import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/gameplay/presentation/widgets/gameplay_controls.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/widgets/common.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('QuitPill follows the dyslexia setting and remains tappable',
      (tester) async {
    final settings = SettingsService();
    var taps = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: QuitPill(onPressed: () => taps++),
          ),
        ),
      ),
    );

    Text quitText() => tester.widget<Text>(find.text('Quit'));

    expect(quitText().style?.fontFamily, AppFonts.head);

    settings.load(
      dark: false,
      sound: true,
      vibration: true,
      dyslexia: true,
      colorblind: false,
      lowPerf: false,
      reduceMotion: false,
      animSpeed: 1,
    );
    await tester.pump();

    expect(quitText().style?.fontFamily, AppFonts.dyslexia);

    await tester.tap(find.text('Quit'));
    expect(taps, 1);
  });
}
