import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const interpreter = BoundedContextShadowInterpreter();
  final context = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );

  test('A: exact factual replay is deterministic', () {
    final observations = _mixed(context);
    expectSameInterpretation(
      interpreter.interpret(observations),
      interpreter.interpret(observations),
    );
  });

  test('B: independent interpreters are deterministic', () {
    expectSameInterpretation(
      const BoundedContextShadowInterpreter().interpret(_mixed(context)),
      const BoundedContextShadowInterpreter().interpret(_mixed(context)),
    );
  });

  test('C: homogeneous observation permutations preserve semantics', () {
    final correct = _observation(context: context);
    final wrong = _observation(context: context, correct: false);
    final timeout = _observation(context: context, timedOut: true);
    final expected = interpreter.interpret([correct, wrong, timeout]);

    for (final observations in [
      [timeout, correct, wrong],
      [wrong, timeout, correct],
      [wrong, correct, timeout],
    ]) {
      expectSameInterpretation(expected, interpreter.interpret(observations));
    }
  });

  test('D: response time does not affect bounded semantics', () {
    expectSameInterpretation(
      interpreter
          .interpret([_observation(context: context, responseTimeMs: 1)]),
      interpreter
          .interpret([_observation(context: context, responseTimeMs: 999999)]),
    );
  });

  test('E: different wrong values preserve bounded semantics', () {
    expectSameInterpretation(
      interpreter.interpret(
          [_observation(context: context, correct: false, submittedAnswer: 3)]),
      interpreter.interpret([
        _observation(context: context, correct: false, submittedAnswer: 99)
      ]),
    );
  });

  test('F: controlled outcome changes alter only aggregate facts', () {
    final wrong = interpreter.interpret([
      _observation(context: context),
      _observation(context: context, correct: false),
    ]);
    final timeout = interpreter.interpret([
      _observation(context: context),
      _observation(context: context, timedOut: true),
    ]);

    expect(wrong.aggregate?.correctCount, 1);
    expect(wrong.aggregate?.incorrectCount, 1);
    expect(wrong.aggregate?.timeoutCount, 0);
    expect(timeout.aggregate?.correctCount, 1);
    expect(timeout.aggregate?.incorrectCount, 0);
    expect(timeout.aggregate?.timeoutCount, 1);
    expect(wrong.factualContextId, timeout.factualContextId);
  });

  test('G: episode sequence does not alter interpretation semantics', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2);
    final first = recorder.record(_mixed(context));
    final second = recorder.record(_mixed(context));

    expect(first.sequence, 1);
    expect(second.sequence, 2);
    expectSameInterpretation(first.interpretation, second.interpretation);
  });

  test('H: independent recorders are deterministic', () {
    final first = BoundedContextShadowEpisodeRecorder(capacity: 3);
    final second = BoundedContextShadowEpisodeRecorder(capacity: 3);
    for (final snapshot in [
      _mixed(context),
      [_observation(context: context)]
    ]) {
      first.record(snapshot);
      second.record(snapshot);
    }

    for (var index = 0; index < first.episodes.length; index++) {
      expect(first.episodes[index].sequence, second.episodes[index].sequence);
      expectSameInterpretation(
        first.episodes[index].interpretation,
        second.episodes[index].interpretation,
      );
    }
  });

  test('I: prior recorder history does not change later semantics', () {
    final earlier = [_observation(context: context)];
    final later = _mixed(context);
    final withHistory = BoundedContextShadowEpisodeRecorder(capacity: 3)
      ..record(earlier);
    final historicalEpisode = withHistory.record(later);
    final freshEpisode =
        BoundedContextShadowEpisodeRecorder(capacity: 3).record(later);

    expectSameInterpretation(
        historicalEpisode.interpretation, freshEpisode.interpretation);
  });

  test('J: FIFO eviction does not change a new snapshot interpretation', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2)
      ..record(const [])
      ..record([_observation(context: context)]);
    final snapshot = _mixed(context);
    final episode = recorder.record(snapshot);

    expect(recorder.episodes.map((item) => item.sequence), [2, 3]);
    expectSameInterpretation(
        episode.interpretation, interpreter.interpret(snapshot));
  });

  test('K: malformed contexts and difficulties fail closed without mutation',
      () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 3);
    final multiplication = ContextEvidenceKey(
      operation: Operation.multiplication,
      numberType: NumberType.natural,
    );
    final mixedContexts = [
      _observation(context: context),
      _observation(context: multiplication),
    ];
    final mixedDifficulties = [
      _observation(context: context, difficulty: Difficulty.easy),
      _observation(context: context, difficulty: Difficulty.medium),
    ];

    expect(() => recorder.record(mixedContexts), throwsArgumentError);
    expect(() => recorder.record(mixedContexts), throwsArgumentError);
    expect(() => recorder.record(mixedDifficulties), throwsArgumentError);
    expect(() => recorder.record(mixedDifficulties), throwsArgumentError);
    expect(recorder.episodes, isEmpty);
    expect(recorder.record([_observation(context: context)]).sequence, 1);
  });

  test('L: empty input remains deterministically insufficient', () {
    final first = interpreter.interpret(const []);
    final second = interpreter.interpret(const []);

    expectSameInterpretation(first, second);
    expect(first.state, BoundedContextShadowInterpretationState.insufficient);
    expect(first.aggregate, isNull);
    expect(first.factualContextId, isNull);
    expect(first.authority, BoundedContextShadowAuthority.none);
    expect(first.mayAffectGameplay, isFalse);
  });

  test('M: controlled explanations contain no higher-level claims', () {
    final explanations = [
      interpreter.interpret(const []).explanation,
      interpreter.interpret(_mixed(context)).explanation,
      BoundedContextShadowEpisodeRecorder(capacity: 1)
          .record(_mixed(context))
          .interpretation
          .explanation,
    ];

    for (final explanation in explanations) {
      for (final forbidden in [
        'learned',
        'learning',
        'mastery',
        'mastered',
        'ability',
        'reliable improvement',
        'improved reliably',
        'trend',
        'declining',
        'struggling',
        'productive challenge',
        'overchallenged',
        'underchallenged',
        'should increase difficulty',
        'should decrease difficulty',
      ]) {
        expect(explanation.toLowerCase(), isNot(contains(forbidden)));
      }
    }
  });
}

List<ContextEvidenceObservation> _mixed(ContextEvidenceKey context) => [
      _observation(context: context),
      _observation(context: context, correct: false),
      _observation(context: context, timedOut: true),
    ];

ContextEvidenceObservation _observation({
  required ContextEvidenceKey context,
  Difficulty difficulty = Difficulty.easy,
  bool correct = true,
  bool timedOut = false,
  int responseTimeMs = 1000,
  num? submittedAnswer,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: timedOut ? null : submittedAnswer ?? (correct ? 4 : 3),
      correct: timedOut ? false : correct,
      timedOut: timedOut,
      responseTimeMs: responseTimeMs,
    );

void expectSameInterpretation(
  BoundedContextShadowInterpretation actual,
  BoundedContextShadowInterpretation expected,
) {
  expect(actual.state, expected.state);
  expect(actual.aggregate?.evidenceCount, expected.aggregate?.evidenceCount);
  expect(actual.aggregate?.correctCount, expected.aggregate?.correctCount);
  expect(actual.aggregate?.incorrectCount, expected.aggregate?.incorrectCount);
  expect(actual.aggregate?.timeoutCount, expected.aggregate?.timeoutCount);
  expect(actual.aggregate?.accuracy, expected.aggregate?.accuracy);
  expect(actual.factualContextId, expected.factualContextId);
  expect(actual.explanation, expected.explanation);
  expect(actual.authority, expected.authority);
  expect(actual.mayAffectGameplay, expected.mayAffectGameplay);
}
