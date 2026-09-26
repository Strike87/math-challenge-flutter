import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart' as engine;
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/screens/config_screen.dart';
import 'package:math_challenge/screens/game_screen.dart';
import 'package:math_challenge/screens/menu_screen.dart';
import 'package:math_challenge/screens/numtype_screen.dart';
import 'package:math_challenge/screens/player_screen.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:math_challenge/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<engine.GameState> makeState({QuestionGenerator? generator}) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final state = engine.GameState(
      settings: SettingsService()
        ..load(
          dark: false,
          sound: false,
          vibration: false,
          dyslexia: false,
          colorblind: false,
          lowPerf: true,
          reduceMotion: true,
          animSpeed: 1,
        ),
      audio: _NoOpAudioService(),
      questionGenerator: generator ?? _TargetClashQuestionGenerator(),
    );
    await state.load();
    addTearDown(state.dispose);
    return state;
  }

  TargetClashRunConfig config([Difficulty difficulty = Difficulty.easy]) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  void resolveAndOpen(engine.GameState state) {
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    state.debugCompleteTargetClashRevealForTest();
  }

  Future<void> chargePowerShot(engine.GameState state) async {
    for (var i = 0; i < 5; i++) {
      resolveAndOpen(state);
    }
  }

  testWidgets('production setup flow reaches dedicated Target Clash gameplay',
      (tester) async {
    final state = await makeState();
    await tester.pumpWidget(_Host(state));
    await tester.tap(find.byKey(const Key('target-clash-challenge-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Natural Numbers'));
    await tester.pumpAndSettle();
    final continueButton = find.text('Continue to Player Setup →');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player-setup-primary')));
    await tester.pump();

    expect(state.activeRunSnapshot!.runType, GameRunType.targetClash);
    expect(state.activeRunSnapshot!.mode, GameMode.standard);
    expect(state.activeRunSnapshot!.players, 1);
    expect(state.activeRunSnapshot!.timingStyle, TimingStyle.perQuestion);
    expect(state.activeRunSnapshot!.targetClashConfig, isNotNull);
    expect(find.byKey(const Key('target-clash-gameplay')), findsOneWidget);
    expect(find.byKey(const Key('answers-grid')), findsNothing);
    await state.quitToMenu();
  });

  testWidgets('open prompt has typed expression and relation controls in order',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config());
    await tester.pumpWidget(_Host(state));

    expect(find.byKey(const Key('target-clash-target')), findsOneWidget);
    expect(find.byKey(const Key('target-clash-expression')), findsOneWidget);
    expect(find.byKey(const Key('target-clash-reveal-relation')), findsNothing);
    final buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));
    expect(
        buttons.map((button) => (button.child! as Text).data), ['<', '=', '>']);
    expect(find.bySemanticsLabel('Less than target'), findsOneWidget);
    expect(find.bySemanticsLabel('Equal to target'), findsOneWidget);
    expect(find.bySemanticsLabel('Greater than target'), findsOneWidget);
    expect(find.byKey(const Key('target-clash-power-shot')), findsNothing);
    await state.quitToMenu();
  });

  testWidgets('typed answer reveals resolved question until canonical 1300ms',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config());
    await tester.pumpWidget(_Host(state));
    await tester.tap(find.byKey(const Key('target-clash-relation-less')));
    await tester.pump();

    expect(state.targetClashReveal, isNotNull);
    expect(
        find.byKey(const Key('target-clash-reveal-relation')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.descendant(
            of: find.byKey(const Key('target-clash-relation-less')),
            matching: find.byType(FilledButton),
          ))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 1299));
    expect(state.targetClashReveal, isNotNull);
    await tester.pump(const Duration(milliseconds: 1));
    expect(state.targetClashReveal, isNull);
    expect(state.rt.accepting, isTrue);
    await state.quitToMenu();
  });

  testWidgets('reveal power shot is presentation-only and accepting hides it',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config());
    await tester.pumpWidget(_Host(state));
    expect(find.byKey(const Key('target-clash-power-shot')), findsNothing);
    state.onTargetClashAnswer(PresentationAnswer.lessThan);
    await tester.pump();
    final powerShot = find.byKey(const Key('target-clash-power-shot'));
    if (powerShot.evaluate().isNotEmpty) {
      expect(tester.widget<OutlinedButton>(powerShot).onPressed, isNull);
    }
    await state.quitToMenu();
  });

  testWidgets('Power Shot applies only during a ready nonterminal reveal',
      (tester) async {
    final state = await makeState(generator: _TargetClashQuestionGenerator());
    state.debugStartTargetClashForTest(config());
    await chargePowerShot(state);
    await tester.pumpWidget(_Host(state));

    final prior = state.targetClashQuestion!;
    state.onTargetClashAnswer(prior.correctAnswer);
    await tester.pump();
    final next = state.targetClashQuestion!;
    final powerShot = find.byKey(const Key('target-clash-power-shot'));
    expect(powerShot, findsOneWidget);
    expect(tester.widget<OutlinedButton>(powerShot).onPressed, isNotNull);
    await tester.tap(powerShot);
    await tester.pump();

    expect(find.text('POWER SHOT ARMED'), findsOneWidget);
    expect(state.targetClashReveal!.question, same(prior));
    expect(state.targetClashQuestion, isNot(same(next)));
    expect(state.rt.accepting, isFalse);
    await state.quitToMenu();
  });

  testWidgets('Triple reveal keeps ready Power Shot non-actionable',
      (tester) async {
    final triple = await makeState(generator: _TargetClashQuestionGenerator());
    triple.debugStartTargetClashForTest(config(Difficulty.medium));
    await chargePowerShot(triple);
    triple.onTargetClashAnswer(triple.targetClashQuestion!.correctAnswer);
    await tester.pumpWidget(_Host(triple));
    final before = triple.targetClashRuntime;
    final powerShot = find.byKey(const Key('target-clash-power-shot'));
    expect(triple.targetClashRuntime!.isTriple, isTrue);
    expect(triple.targetClashRuntime!.clashPower, 6);
    expect(find.text('POWER SHOT BLOCKED IN TRIPLE'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(powerShot).onPressed, isNull);
    await tester.tap(powerShot, warnIfMissed: false);
    await tester.pump();
    expect(triple.targetClashRuntime, same(before));
    expect(triple.activateTargetClashPowerShot(),
        TargetClashPowerShotOutcome.denied);
    await triple.quitToMenu();
  });

  testWidgets('Power Shot unavailable feedback stays canonical',
      (tester) async {
    final generator = _ToggleDirectGenerator();
    final unavailable = await makeState(generator: generator);
    unavailable.debugStartTargetClashForTest(config());
    await chargePowerShot(unavailable);
    unavailable
        .onTargetClashAnswer(unavailable.targetClashQuestion!.correctAnswer);
    generator.rejectDirect = true;
    await tester.pumpWidget(_Host(unavailable));
    final charge = unavailable.targetClashRuntime!.clashPower;
    await tester.tap(find.byKey(const Key('target-clash-power-shot')));
    await tester.pump();
    expect(find.text('POWER SHOT UNAVAILABLE'), findsOneWidget);
    expect(unavailable.targetClashRuntime!.clashPower, charge);
    await unavailable.quitToMenu();
  });

  testWidgets('Power Shot feedback is scoped to its originating reveal',
      (tester) async {
    final state = await makeState(generator: _TargetClashQuestionGenerator());
    state.debugStartTargetClashForTest(config());
    await chargePowerShot(state);
    await tester.pumpWidget(_Host(state));

    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    await tester.pump();
    final revealA = state.targetClashReveal;
    await tester.tap(find.byKey(const Key('target-clash-power-shot')));
    await tester.pump();
    expect(find.text('POWER SHOT ARMED'), findsOneWidget);

    state.debugCompleteTargetClashRevealForTest();
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    await tester.pump();
    final revealB = state.targetClashReveal;
    expect(revealB, isNot(same(revealA)));
    expect(find.text('POWER SHOT ARMED'), findsNothing);
    expect(find.text('POWER SHOT DENIED'), findsNothing);
    expect(find.text('POWER SHOT UNAVAILABLE'), findsNothing);
    await state.quitToMenu();
  });

  testWidgets('wrong and timeout reveals retain canonical relation feedback',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config());
    await tester.pumpWidget(_Host(state));
    final wrong = PresentationAnswer.values.firstWhere(
        (answer) => answer != state.targetClashQuestion!.correctAnswer);
    state.onTargetClashAnswer(wrong);
    await tester.pump();
    expect(find.textContaining('INCORRECT •'), findsOneWidget);
    expect(
        find.byKey(const Key('target-clash-reveal-relation')), findsOneWidget);
    state.debugCompleteTargetClashRevealForTest();
    state.debugTimeoutForTest();
    await tester.pump();
    expect(find.textContaining('TIMEOUT •'), findsOneWidget);
    await state.quitToMenu();
  });

  testWidgets(
      'terminal and technical reveals hide Power Shot before their bridges',
      (tester) async {
    final completed = await makeState();
    completed.debugStartTargetClashForTest(config());
    for (var i = 0; i < 11; i++) {
      resolveAndOpen(completed);
    }
    completed.onTargetClashAnswer(completed.targetClashQuestion!.correctAnswer);
    await tester.pumpWidget(_Host(completed));
    expect(completed.targetClashReveal, isNotNull);
    expect(find.byKey(const Key('target-clash-power-shot')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(
        find.byKey(const Key('target-clash-terminal-bridge')), findsOneWidget);
    await completed.quitToMenu();

    final technical = await makeState(generator: _FailSecondStageGenerator());
    technical.debugStartTargetClashForTest(config());
    for (var i = 0; i < 2; i++) {
      resolveAndOpen(technical);
    }
    // The failure is reached by resolving the last first-stage question.
    technical.onTargetClashAnswer(technical.targetClashQuestion!.correctAnswer);
    await tester.pumpWidget(_Host(technical));
    expect(technical.targetClashReveal, isNotNull);
    expect(find.byKey(const Key('target-clash-power-shot')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byKey(const Key('target-clash-technical-failure')),
        findsOneWidget);
    await technical.quitToMenu();
  });

  testWidgets(
      'Target Clash remains readable in compact and landscape reduced-motion viewports',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config());
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(360, 640), const Size(844, 390)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(_Host(state));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('target-clash-gameplay')), findsOneWidget);
    }
    await state.quitToMenu();
  });

  testWidgets('HUD and phase labels project canonical Target Clash runtime',
      (tester) async {
    final ready = await makeState();
    ready.debugStartTargetClashForTest(config());
    await chargePowerShot(ready);
    await tester.pumpWidget(_Host(ready));
    for (final key in const [
      Key('target-clash-score'),
      Key('target-clash-combo'),
      Key('target-clash-multiplier'),
      Key('target-clash-power'),
      Key('target-clash-progress'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(find.text('6 / 6 READY'), findsOneWidget);
    await ready.quitToMenu();

    final triple = await makeState();
    triple.debugStartTargetClashForTest(config(Difficulty.medium));
    for (var i = 0; i < 6; i++) {
      resolveAndOpen(triple);
    }
    await tester.pumpWidget(_Host(triple));
    expect(find.text('TRIPLE CLASH'), findsOneWidget);
    await triple.quitToMenu();

    final fever = await makeState();
    fever.debugStartTargetClashForTest(config(Difficulty.hard));
    for (var i = 0; i < 9; i++) {
      resolveAndOpen(fever);
    }
    await tester.pumpWidget(_Host(fever));
    expect(find.text('BOSS TARGET'), findsOneWidget);
    expect(find.text('FEVER ×2'), findsOneWidget);
    await fever.quitToMenu();

    final finalTarget = await makeState();
    finalTarget.debugStartTargetClashForTest(config());
    for (var i = 0; i < 9; i++) {
      resolveAndOpen(finalTarget);
    }
    await tester.pumpWidget(_Host(finalTarget));
    expect(find.text('FINAL TARGET'), findsOneWidget);
    await finalTarget.quitToMenu();
  });

  testWidgets('initial technical failure has no fabricated reveal',
      (tester) async {
    final state = await makeState(generator: _FailInitialGenerator());
    state.debugStartTargetClashForTest(config());
    await tester.pumpWidget(_Host(state));

    expect(state.targetClashReveal, isNull);
    expect(find.byKey(const Key('target-clash-technical-failure')),
        findsOneWidget);
    expect(find.byKey(const Key('target-clash-relation-less')), findsNothing);
    await state.quitToMenu();
  });

  testWidgets('Target Clash excludes ordinary answer, power-up, and results UI',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config());
    await tester.pumpWidget(_Host(state));

    expect(find.byKey(const Key('answers-grid')), findsNothing);
    expect(find.byKey(const Key('true-false-proposal')), findsNothing);
    expect(find.byKey(const Key('power-up-hud')), findsNothing);
    expect(find.text('REPLAY'), findsNothing);
    expect(find.text('VIEW RESULTS'), findsNothing);
    await state.quitToMenu();
  });
}

class _TargetClashQuestionGenerator extends QuestionGenerator {
  _TargetClashQuestionGenerator() : super(rng: Random(1));
  int _anchors = 0;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      _question(type, diff, numType, 10 + ++_anchors);

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) =>
      _question(type, diff, numType, result);

  Question _question(
      Operation type, Difficulty diff, NumberType numType, num result) {
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

final class _ToggleDirectGenerator extends _TargetClashQuestionGenerator {
  bool rejectDirect = false;

  @override
  Question? buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) =>
      rejectDirect
          ? null
          : super.buildDirectForResult(
              type: type, diff: diff, numType: numType, result: result);
}

final class _FailSecondStageGenerator extends _TargetClashQuestionGenerator {
  int _builds = 0;

  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) {
    if (++_builds < 2) {
      return super.build(type: type, diff: diff, numType: numType);
    }
    return Question(
        type: type,
        key: 'invalid',
        text: 'invalid',
        ans: 0,
        choices: const [0]);
  }
}

final class _FailInitialGenerator extends QuestionGenerator {
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
          choices: const [0]);
}

class _Host extends StatelessWidget {
  const _Host(this.state);
  final engine.GameState state;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: state.settings),
          ChangeNotifierProvider<engine.GameState>.value(value: state),
        ],
        child: MaterialApp(
          theme: AppTheme.light(state.settings),
          home: Scaffold(
            body: Consumer<engine.GameState>(
              builder: (context, gs, _) => switch (gs.currentScreen) {
                engine.GameScreen.menu => const MenuScreen(),
                engine.GameScreen.numType => const NumTypeScreen(),
                engine.GameScreen.config => const ConfigScreen(),
                engine.GameScreen.player => const PlayerSetupScreen(),
                engine.GameScreen.game => const GameScreen(),
                _ => const SizedBox(),
              },
            ),
          ),
        ),
      );
}

class _NoOpAudioService implements AudioService {
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
