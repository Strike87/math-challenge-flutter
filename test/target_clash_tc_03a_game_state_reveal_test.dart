import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TargetClashRunConfig config(Difficulty difficulty) =>
      TargetClashRunConfig.tryCreate(
        operation: Operation.addition,
        difficulty: difficulty,
        numberType: NumberType.integers,
      )!;

  Future<GameState> makeState({QuestionGenerator? generator}) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    final state = GameState(
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

  void resolveAndOpen(GameState state, {bool correct = true}) {
    final question = state.targetClashQuestion!;
    state.onTargetClashAnswer(correct
        ? question.correctAnswer
        : PresentationAnswer.values
            .firstWhere((answer) => answer != question.correctAnswer));
    state.debugCompleteTargetClashRevealForTest();
  }

  testWidgets(
      'reveal keeps resolved facts, locks input, and opens only at 1300 ms',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final resolved = state.targetClashQuestion!;
    final timer = state.rt.timer;
    state.onTargetClashAnswer(
      PresentationAnswer.values
          .firstWhere((answer) => answer != resolved.correctAnswer),
    );

    final reveal = state.targetClashReveal!;
    expect(reveal.question, same(resolved));
    expect(reveal.playerAnswer, isNot(reveal.question.correctAnswer));
    expect(reveal.wasCorrect, isFalse);
    expect(reveal.question.correctAnswer, isNotNull);
    expect(state.targetClashQuestion, isNot(same(resolved)));
    expect(state.rt.accepting, isFalse);
    expect(timer!.isActive, isFalse);
    state.onTargetClashAnswer(reveal.question.correctAnswer);
    state.debugTimeoutForTest();
    expect(state.targetClashRuntime!.resolvedCount, 1);

    await tester.pump(const Duration(milliseconds: 1299));
    expect(state.targetClashReveal, same(reveal));
    expect(state.rt.accepting, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(state.targetClashReveal, isNull);
    expect(state.rt.accepting, isTrue);
    expect(state.rt.timer, isNot(same(timer)));
    expect(state.rt.timer!.isActive, isTrue);
    state.dispose();
  });

  test('timeout reveal has no player answer and preserves the correct relation',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    final resolved = state.targetClashQuestion!;
    state.debugTimeoutForTest();

    expect(state.targetClashReveal!.question, same(resolved));
    expect(state.targetClashReveal!.playerAnswer, isNull);
    expect(state.targetClashReveal!.question.correctAnswer,
        resolved.correctAnswer);
    expect(state.rt.accepting, isFalse);
  });

  test('Power Shot applies only to the canonical next slot during reveal',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    for (var i = 0; i < 5; i++) {
      resolveAndOpen(state);
    }
    expect(state.targetClashRuntime!.clashPower, 6);
    final prior = state.targetClashQuestion!;
    state.onTargetClashAnswer(prior.correctAnswer);
    final reveal = state.targetClashReveal!;
    final next = state.targetClashQuestion!;

    expect(state.activateTargetClashPowerShot(),
        TargetClashPowerShotOutcome.applied);
    expect(state.targetClashReveal, same(reveal));
    expect(reveal.question, same(prior));
    expect(state.targetClashQuestion, isNot(same(next)));
    expect(state.rt.accepting, isFalse);
    state.debugCompleteTargetClashRevealForTest();
    expect(state.rt.accepting, isTrue);
    expect(state.targetClashQuestion, isNot(same(next)));
  });

  test(
      'Power Shot fails closed outside reveal, after open, and in terminal reveal',
      () async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    expect(state.activateTargetClashPowerShot(),
        TargetClashPowerShotOutcome.denied);
    for (var i = 0; i < 11; i++) {
      resolveAndOpen(state);
    }
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    expect(state.targetClashRuntime!.finished, isTrue);
    expect(state.activateTargetClashPowerShot(),
        TargetClashPowerShotOutcome.denied);
    state.debugCompleteTargetClashRevealForTest();
    expect(state.rt.gameActive, isFalse);
  });

  test('terminal and technical-failure resolutions retain their reveal',
      () async {
    final finalState = await makeState();
    finalState.debugStartTargetClashForTest(config(Difficulty.easy));
    for (var i = 0; i < 11; i++) {
      resolveAndOpen(finalState);
    }
    final finalQuestion = finalState.targetClashQuestion!;
    finalState.onTargetClashAnswer(finalQuestion.correctAnswer);
    expect(finalState.targetClashRuntime!.finished, isTrue);
    expect(finalState.targetClashReveal!.question, same(finalQuestion));
    expect(finalState.rt.gameActive, isTrue);
    finalState.debugCompleteTargetClashRevealForTest();
    expect(finalState.rt.gameActive, isFalse);

    final technical = await makeState(generator: _FailSecondStageGenerator());
    technical.debugStartTargetClashForTest(config(Difficulty.easy));
    resolveAndOpen(technical);
    resolveAndOpen(technical);
    final resolved = technical.targetClashQuestion!;
    technical.onTargetClashAnswer(resolved.correctAnswer);
    expect(
        technical.targetClashRuntime!.phase, TargetClashPhase.technicalFailure);
    expect(technical.targetClashReveal!.question, same(resolved));
    expect(technical.rt.gameActive, isTrue);
    technical.debugCompleteTargetClashRevealForTest();
    expect(technical.rt.gameActive, isFalse);
  });

  testWidgets('a cancelled reveal callback cannot open a newer run',
      (tester) async {
    final state = await makeState();
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    state.onTargetClashAnswer(state.targetClashQuestion!.correctAnswer);
    state.debugStartTargetClashForTest(config(Difficulty.easy));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(state.targetClashReveal, isNull);
    expect(state.targetClashRuntime!.resolvedCount, 0);
    expect(state.rt.accepting, isTrue);
    state.dispose();
  });

  test('Triple denial and unavailable preserve canonical runtime behavior',
      () async {
    final triple = await makeState();
    triple.debugStartTargetClashForTest(config(Difficulty.medium));
    for (var i = 0; i < 6; i++) {
      resolveAndOpen(triple);
    }
    expect(triple.targetClashRuntime!.phase, TargetClashPhase.triple);
    triple.onTargetClashAnswer(triple.targetClashQuestion!.correctAnswer);
    expect(triple.activateTargetClashPowerShot(),
        TargetClashPowerShotOutcome.denied);

    final generator = _ToggleDirectGenerator();
    final unavailable = await makeState(generator: generator);
    unavailable.debugStartTargetClashForTest(config(Difficulty.easy));
    for (var i = 0; i < 5; i++) {
      resolveAndOpen(unavailable);
    }
    unavailable
        .onTargetClashAnswer(unavailable.targetClashQuestion!.correctAnswer);
    generator.rejectDirect = true;
    final power = unavailable.targetClashRuntime!.clashPower;
    expect(unavailable.activateTargetClashPowerShot(),
        TargetClashPowerShotOutcome.unavailable);
    expect(unavailable.targetClashRuntime!.clashPower, power);
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
              type: type,
              diff: diff,
              numType: numType,
              result: result,
            );
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
      return super.build(
        type: type,
        diff: diff,
        numType: numType,
        integerQuest: integerQuest,
        decimalQuest: decimalQuest,
      );
    }
    return Question(
      type: type,
      key: 'invalid',
      text: 'invalid',
      ans: 0,
      choices: const [0],
    );
  }
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
