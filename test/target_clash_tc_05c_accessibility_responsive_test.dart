import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/screens/game_screen.dart' as screen;
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final config = TargetClashRunConfig.tryCreate(
    operation: Operation.addition,
    difficulty: Difficulty.easy,
    numberType: NumberType.integers,
  )!;

  Future<GameState> makeState({
    bool dark = false,
    QuestionGenerator? generator,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();

    final state = GameState(
      settings: SettingsService()
        ..load(
          dark: dark,
          sound: false,
          vibration: false,
          dyslexia: false,
          colorblind: false,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 1,
        ),
      audio: _NoOpAudioService(),
      questionGenerator: generator ?? _Generator(),
    );

    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  Widget host(GameState state, {bool dark = false}) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
          ChangeNotifierProvider<GameState>.value(value: state),
        ],
        child: MaterialApp(
          theme: dark
              ? AppTheme.dark(state.settings)
              : AppTheme.light(state.settings),
          home: const Scaffold(
            body: screen.GameScreen(),
          ),
        ),
      );

  void configureView(
    WidgetTester tester,
    Size logicalSize, {
    double textScale = 1.0,
  }) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
  }

  void resetViewOnTearDown(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Finder relationButton(Key key) => find.descendant(
        of: find.byKey(key),
        matching: find.byType(FilledButton),
      );

  void expectButtonSemantics(
    WidgetTester tester,
    Finder finder,
  ) {
    expect(
      tester.getSemantics(finder).flagsCollection.isButton,
      isTrue,
    );
  }

  Future<void> expectReachable(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    expect(finder.hitTestable(), findsOneWidget);
  }

  void completeTargetClash(GameState state) {
    while (state.rt.gameActive) {
      final question = state.targetClashQuestion!;
      state.onTargetClashAnswer(question.correctAnswer);
      state.debugCompleteTargetClashRevealForTest();
    }
  }

  testWidgets(
    '360x640 at 1.5x keeps gameplay controls usable and semantics ordered',
    (tester) async {
      resetViewOnTearDown(tester);

      final state = await makeState();
      state.debugStartTargetClashForTest(config);

      configureView(
        tester,
        const Size(360, 640),
        textScale: 1.5,
      );

      await tester.pumpWidget(host(state));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('target-clash-gameplay')), findsOneWidget);

      final cases = <(Key, String)>[
        (const Key('target-clash-relation-less'), 'Less than target'),
        (const Key('target-clash-relation-equal'), 'Equal to target'),
        (const Key('target-clash-relation-greater'), 'Greater than target'),
      ];

      for (final entry in cases) {
        final key = entry.$1;
        final semanticsLabel = entry.$2;

        expect(find.bySemanticsLabel(semanticsLabel), findsOneWidget);
        expectButtonSemantics(
          tester,
          find.bySemanticsLabel(semanticsLabel),
        );

        final button = relationButton(key);

        expect(button, findsOneWidget);

        final size = tester.getSize(button);

        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: '$semanticsLabel height must remain a practical tap target.',
        );

        expect(
          size.width,
          greaterThanOrEqualTo(48),
          reason: '$semanticsLabel width must remain a practical tap target.',
        );

        expect(button.hitTestable(), findsOneWidget);
      }

      final lessX = tester
          .getCenter(relationButton(const Key('target-clash-relation-less')))
          .dx;
      final equalX = tester
          .getCenter(relationButton(const Key('target-clash-relation-equal')))
          .dx;
      final greaterX = tester
          .getCenter(relationButton(const Key('target-clash-relation-greater')))
          .dx;

      expect(lessX, lessThan(equalX));
      expect(equalX, lessThan(greaterX));

      expect(tester.takeException(), isNull);
      await state.quitToMenu();
    },
  );

  testWidgets(
    '1.5x reveal keeps textual meaning and disables relation controls',
    (tester) async {
      resetViewOnTearDown(tester);

      final state = await makeState();
      state.debugStartTargetClashForTest(config);

      configureView(
        tester,
        const Size(360, 640),
        textScale: 1.5,
      );

      await tester.pumpWidget(host(state));

      final wrong = PresentationAnswer.values.firstWhere(
        (answer) => answer != state.targetClashQuestion!.correctAnswer,
      );

      state.onTargetClashAnswer(wrong);
      await tester.pump();

      expect(tester.takeException(), isNull);

      expect(
        find.byKey(const Key('target-clash-reveal-relation')),
        findsOneWidget,
      );

      expect(
        find.textContaining('INCORRECT •'),
        findsOneWidget,
      );

      for (final key in const [
        Key('target-clash-relation-less'),
        Key('target-clash-relation-equal'),
        Key('target-clash-relation-greater'),
      ]) {
        expect(
          tester.widget<FilledButton>(relationButton(key)).onPressed,
          isNull,
        );
      }

      expect(tester.takeException(), isNull);
      await state.quitToMenu();
    },
  );

  testWidgets(
    'results stay scrollable reachable and semantic at 360x640 1.5x',
    (tester) async {
      resetViewOnTearDown(tester);

      final state = await makeState();
      state.debugStartTargetClashForTest(config);
      completeTargetClash(state);

      configureView(
        tester,
        const Size(360, 640),
        textScale: 1.5,
      );

      await tester.pumpWidget(host(state));
      await tester.pump();

      expect(tester.takeException(), isNull);

      expect(
        find.byKey(const Key('target-clash-results')),
        findsOneWidget,
      );

      expect(
        find.byType(SingleChildScrollView),
        findsWidgets,
      );

      final replay = find.byKey(const Key('target-clash-results-replay'));
      final menu = find.byKey(const Key('target-clash-results-menu'));

      await expectReachable(tester, replay);
      await expectReachable(tester, menu);

      expect(
        find.bySemanticsLabel('Replay Target Clash'),
        findsOneWidget,
      );

      expect(
        find.bySemanticsLabel('Back to menu'),
        findsOneWidget,
      );

      expectButtonSemantics(
        tester,
        find.bySemanticsLabel('Replay Target Clash'),
      );

      expectButtonSemantics(
        tester,
        find.bySemanticsLabel('Back to menu'),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'required responsive matrix has no overflow and preserves required actions',
    (tester) async {
      resetViewOnTearDown(tester);

      final gameplay = await makeState();
      gameplay.debugStartTargetClashForTest(config);

      for (final viewport in const [
        Size(390, 844),
        Size(844, 390),
        Size(834, 1194),
      ]) {
        configureView(tester, viewport);

        await tester.pumpWidget(host(gameplay));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Gameplay failed at $viewport.',
        );

        expect(
          find.byKey(const Key('target-clash-gameplay')),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('target-clash-relation-less')),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('target-clash-relation-equal')),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('target-clash-relation-greater')),
          findsOneWidget,
        );
      }

      final results = await makeState();
      results.debugStartTargetClashForTest(config);
      completeTargetClash(results);

      for (final viewport in const [
        Size(844, 390),
        Size(834, 1194),
      ]) {
        configureView(tester, viewport);

        await tester.pumpWidget(host(results));
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Results failed at $viewport.',
        );

        expect(
          find.byKey(const Key('target-clash-results')),
          findsOneWidget,
        );

        await expectReachable(
          tester,
          find.byKey(const Key('target-clash-results-replay')),
        );

        await expectReachable(
          tester,
          find.byKey(const Key('target-clash-results-menu')),
        );

        expect(tester.takeException(), isNull);
      }

      await gameplay.quitToMenu();
      await results.quitToMenu();
    },
  );

  testWidgets(
    'technical failure remains readable reachable and semantic',
    (tester) async {
      resetViewOnTearDown(tester);

      final state = await makeState(
        generator: _FailGenerator(),
      );

      state.debugStartTargetClashForTest(config);

      for (final caseData in const [
        (Size(360, 640), 1.5),
        (Size(844, 390), 1.0),
      ]) {
        configureView(
          tester,
          caseData.$1,
          textScale: caseData.$2,
        );

        await tester.pumpWidget(host(state));
        await tester.pump();

        expect(tester.takeException(), isNull);

        expect(
          find.byKey(const Key('target-clash-technical-failure')),
          findsOneWidget,
        );

        expect(
          find.text("Target Clash couldn't continue safely."),
          findsOneWidget,
        );

        final backToMenu = find.widgetWithText(
          FilledButton,
          'BACK TO MENU',
        );

        expect(backToMenu, findsOneWidget);

        expectButtonSemantics(
          tester,
          backToMenu,
        );

        expect(
          backToMenu.hitTestable(),
          findsOneWidget,
        );
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dark gameplay retains readable text and non-color state meaning',
    (tester) async {
      resetViewOnTearDown(tester);

      final state = await makeState(dark: true);
      state.debugStartTargetClashForTest(config);

      configureView(
        tester,
        const Size(390, 844),
      );

      await tester.pumpWidget(
        host(
          state,
          dark: true,
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);

      final expression = tester.widget<Text>(
        find.byKey(const Key('target-clash-expression')),
      );

      expect(
        expression.style?.color,
        isNot(equals(state.settings.surface)),
      );

      final wrong = PresentationAnswer.values.firstWhere(
        (answer) => answer != state.targetClashQuestion!.correctAnswer,
      );

      state.onTargetClashAnswer(wrong);
      await tester.pump();

      expect(
        find.textContaining('INCORRECT •'),
        findsOneWidget,
      );

      expect(
        find.byKey(const Key('target-clash-reveal-relation')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
      await state.quitToMenu();
    },
  );
}

final class _Generator extends QuestionGenerator {
  _Generator() : super(rng: Random(1));

  int _anchor = 0;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      _question(
        type,
        diff,
        numType,
        10 + ++_anchor,
      );

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) =>
      _question(
        type,
        diff,
        numType,
        result,
      );

  Question _question(
    Operation type,
    Difficulty diff,
    NumberType numType,
    num result,
  ) {
    final fact = MathFact(
      operation: type,
      left: result,
      right: 0,
      result: result,
      representation: FactRepresentation.direct,
      difficulty: diff,
      numberType: numType,
    );

    return Question(
      type: type,
      key: '$type:$result',
      text: '$result + 0',
      ans: result,
      choices: [result],
      diff: diff,
      numType: numType,
      fact: fact,
    );
  }
}

final class _FailGenerator extends QuestionGenerator {
  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      Question(
        type: type,
        key: 'invalid',
        text: 'invalid',
        ans: 0,
        choices: const [0],
      );
}

final class _NoOpAudioService implements AudioService {
  @override
  int get debugTonePlayCount => 0;

  @override
  int get debugVibrationCount => 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> playCorrect() async {}

  @override
  Future<void> playPowerUp() async {}

  @override
  Future<void> playStart() async {}

  @override
  Future<void> playTones(List<List<double>> tones) async {}

  @override
  Future<void> playWrong() async {}

  @override
  void vibrate(int ms) {}

  @override
  void vibrateCorrect() {}

  @override
  void vibratePattern(List<int> pattern) {}

  @override
  void vibratePowerUp() {}

  @override
  void vibrateWrong() {}
}
