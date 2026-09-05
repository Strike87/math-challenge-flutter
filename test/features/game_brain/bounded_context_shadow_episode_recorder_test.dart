import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  final context = ContextEvidenceKey(
    operation: Operation.addition,
    numberType: NumberType.natural,
  );

  test('1: capacity must be positive', () {
    expect(() => BoundedContextShadowEpisodeRecorder(capacity: 0),
        throwsArgumentError);
    expect(() => BoundedContextShadowEpisodeRecorder(capacity: -1),
        throwsArgumentError);
  });

  test('2: empty input records an insufficient first episode', () {
    final episode =
        BoundedContextShadowEpisodeRecorder(capacity: 2).record(const []);

    expect(episode.sequence, 1);
    expect(episode.interpretation.state,
        BoundedContextShadowInterpretationState.insufficient);
    expect(episode.interpretation.aggregate, isNull);
    expect(episode.authority, BoundedContextShadowAuthority.none);
    expect(episode.mayAffectGameplay, isFalse);
  });

  test('3: a correct observation records an observational first episode', () {
    final episode = BoundedContextShadowEpisodeRecorder(capacity: 2)
        .record([_observation(context: context)]);

    expect(episode.sequence, 1);
    expect(episode.interpretation.state,
        BoundedContextShadowInterpretationState.observational);
    expect(episode.interpretation.aggregate?.correctCount, 1);
  });

  test('4: identical evidence keeps factual semantics but advances sequence',
      () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2);
    final observations = [_observation(context: context)];
    final first = recorder.record(observations);
    final second = recorder.record(observations);

    expect(first.sequence, 1);
    expect(second.sequence, 2);
    expect(first.interpretation.state, second.interpretation.state);
    expect(first.interpretation.aggregate?.accuracy,
        second.interpretation.aggregate?.accuracy);
    expect(first.interpretation.factualContextId,
        second.interpretation.factualContextId);
  });

  test('5: cumulative snapshots remain individual factual episodes', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 3);
    recorder.record([_observation(context: context)]);
    recorder.record([
      _observation(context: context),
      _observation(context: context, correct: false),
    ]);
    recorder.record([
      _observation(context: context),
      _observation(context: context, correct: false),
      _observation(context: context, timedOut: true),
    ]);

    expect(recorder.episodes[0].interpretation.aggregate?.evidenceCount, 1);
    expect(recorder.episodes[1].interpretation.aggregate?.evidenceCount, 2);
    expect(recorder.episodes[2].interpretation.aggregate?.evidenceCount, 3);
    expect(recorder.episodes[2].interpretation.aggregate?.correctCount, 1);
    expect(recorder.episodes[2].interpretation.aggregate?.incorrectCount, 1);
    expect(recorder.episodes[2].interpretation.aggregate?.timeoutCount, 1);
  });

  test('6: FIFO eviction retains original sequence numbers', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2);
    recorder.record(const []);
    recorder.record(const []);
    recorder.record(const []);

    expect(recorder.episodes.map((episode) => episode.sequence), [2, 3]);
  });

  test('7: episode snapshots are unmodifiable', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 1)
      ..record(const []);

    expect(() => recorder.episodes.clear(), throwsUnsupportedError);
  });

  test('8: mixed contexts fail without storing or consuming a sequence', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2);
    final multiplication = ContextEvidenceKey(
      operation: Operation.multiplication,
      numberType: NumberType.natural,
    );

    expect(
      () => recorder.record([
        _observation(context: context),
        _observation(context: multiplication),
      ]),
      throwsArgumentError,
    );
    expect(recorder.episodes, isEmpty);
    expect(recorder.record([_observation(context: context)]).sequence, 1);
  });

  test('9: mixed difficulties fail without storing an episode', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2);

    expect(
      () => recorder.record([
        _observation(context: context, difficulty: Difficulty.easy),
        _observation(context: context, difficulty: Difficulty.medium),
      ]),
      throwsArgumentError,
    );
    expect(recorder.episodes, isEmpty);
  });

  test('10: recorded episodes retain no caller observation list', () {
    final observations = [_observation(context: context)];
    final episode =
        BoundedContextShadowEpisodeRecorder(capacity: 1).record(observations);
    observations.clear();

    expect(episode.interpretation.aggregate?.evidenceCount, 1);
    expect(episode.interpretation.factualContextId, contains('addition'));
  });

  test('11: every episode has no gameplay authority', () {
    final recorder = BoundedContextShadowEpisodeRecorder(capacity: 2)
      ..record(const [])
      ..record([_observation(context: context)]);

    for (final episode in recorder.episodes) {
      expect(episode.authority, BoundedContextShadowAuthority.none);
      expect(episode.mayAffectGameplay, isFalse);
    }
  });

  test('12: recorded explanations contain no reliable-learning language', () {
    final explanation = BoundedContextShadowEpisodeRecorder(capacity: 1)
        .record([_observation(context: context)])
        .interpretation
        .explanation
        .toLowerCase();

    for (final forbidden in ['reliable', 'learning', 'mastery', 'ability']) {
      expect(explanation, isNot(contains(forbidden)));
    }
  });

  test('13: independent recorders produce deterministic episodes', () {
    final first = BoundedContextShadowEpisodeRecorder(capacity: 3);
    final second = BoundedContextShadowEpisodeRecorder(capacity: 3);
    final snapshots = [
      [_observation(context: context)],
      [
        _observation(context: context),
        _observation(context: context, correct: false),
      ],
    ];
    for (final snapshot in snapshots) {
      first.record(snapshot);
      second.record(snapshot);
    }

    for (var index = 0; index < first.episodes.length; index++) {
      final left = first.episodes[index];
      final right = second.episodes[index];
      expect(left.sequence, right.sequence);
      expect(left.interpretation.state, right.interpretation.state);
      expect(left.interpretation.aggregate?.evidenceCount,
          right.interpretation.aggregate?.evidenceCount);
      expect(left.interpretation.aggregate?.correctCount,
          right.interpretation.aggregate?.correctCount);
      expect(left.interpretation.aggregate?.incorrectCount,
          right.interpretation.aggregate?.incorrectCount);
      expect(left.interpretation.aggregate?.timeoutCount,
          right.interpretation.aggregate?.timeoutCount);
      expect(left.interpretation.aggregate?.accuracy,
          right.interpretation.aggregate?.accuracy);
      expect(left.interpretation.factualContextId,
          right.interpretation.factualContextId);
      expect(left.interpretation.explanation, right.interpretation.explanation);
    }
  });
}

ContextEvidenceObservation _observation({
  required ContextEvidenceKey context,
  Difficulty difficulty = Difficulty.easy,
  bool correct = true,
  bool timedOut = false,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: timedOut ? null : (correct ? 4 : 3),
      correct: timedOut ? false : correct,
      timedOut: timedOut,
      responseTimeMs: 1000,
    );
