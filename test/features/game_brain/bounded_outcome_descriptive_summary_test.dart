import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/game_brain.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  const summarizer = BoundedOutcomeDescriptiveSummarizer();
  final addition = _context(Operation.addition);
  final multiplication = _context(Operation.multiplication);

  test('1: empty input produces zero counts and null rates', () {
    final summary = summarizer.summarize(const []);

    expect(summary.context, isNull);
    expect(summary.difficulty, isNull);
    expect(summary.evidenceCount, 0);
    expect(summary.answeredCount, 0);
    expect(summary.correctCount, 0);
    expect(summary.incorrectCount, 0);
    expect(summary.timeoutCount, 0);
    expect(summary.answeredRate, isNull);
    expect(summary.correctRate, isNull);
    expect(summary.incorrectRate, isNull);
    expect(summary.timeoutRate, isNull);
  });

  test('2: one correct observation produces answered correct rates', () {
    final summary = summarizer.summarize([_observation(context: addition)]);

    expect(summary.evidenceCount, 1);
    expect(summary.answeredCount, 1);
    expect(summary.correctCount, 1);
    expect(summary.incorrectCount, 0);
    expect(summary.timeoutCount, 0);
    expect(summary.answeredRate, 1);
    expect(summary.correctRate, 1);
    expect(summary.incorrectRate, 0);
    expect(summary.timeoutRate, 0);
  });

  test('3: one non-timeout wrong observation is answered and incorrect', () {
    final summary =
        summarizer.summarize([_observation(context: addition, correct: false)]);

    expect(summary.answeredCount, 1);
    expect(summary.incorrectCount, 1);
    expect(summary.timeoutCount, 0);
  });

  test('4: one timeout is timeout only and not answered', () {
    final summary =
        summarizer.summarize([_observation(context: addition, timedOut: true)]);

    expect(summary.answeredCount, 0);
    expect(summary.correctCount, 0);
    expect(summary.incorrectCount, 0);
    expect(summary.timeoutCount, 1);
  });

  test('5: correct wrong and timeout outcomes remain exclusive', () {
    final summary = summarizer.summarize([
      _observation(context: addition),
      _observation(context: addition, correct: false),
      _observation(context: addition, timedOut: true),
    ]);

    expect(summary.correctCount, 1);
    expect(summary.incorrectCount, 1);
    expect(summary.timeoutCount, 1);
    expect(summary.answeredCount, 2);
  });

  test('6: rates use total evidence as their denominator', () {
    final summary = summarizer.summarize([
      _observation(context: addition),
      _observation(context: addition, correct: false),
      _observation(context: addition, timedOut: true),
    ]);

    expect(summary.correctRate, closeTo(1 / 3, 1e-12));
    expect(summary.incorrectRate, closeTo(1 / 3, 1e-12));
    expect(summary.timeoutRate, closeTo(1 / 3, 1e-12));
    expect(summary.answeredRate, closeTo(2 / 3, 1e-12));
  });

  test('7: outcome rates sum to one for non-empty evidence', () {
    final summary = summarizer.summarize([
      _observation(context: addition),
      _observation(context: addition, correct: false),
      _observation(context: addition, timedOut: true),
    ]);

    expect(
      summary.correctRate! + summary.incorrectRate! + summary.timeoutRate!,
      closeTo(1, 1e-12),
    );
  });

  test('8: matching context and difficulty are accepted', () {
    final summary = summarizer.summarize([
      _observation(context: addition),
      _observation(context: addition, correct: false),
    ]);

    expect(summary.context, addition);
    expect(summary.difficulty, Difficulty.easy);
    expect(summary.evidenceCount, 2);
  });

  test('9: different contexts fail closed', () {
    expect(
      () => summarizer.summarize([
        _observation(context: addition),
        _observation(context: multiplication),
      ]),
      throwsArgumentError,
    );
  });

  test('10: different difficulties fail closed', () {
    expect(
      () => summarizer.summarize([
        _observation(context: addition),
        _observation(context: addition, difficulty: Difficulty.medium),
      ]),
      throwsArgumentError,
    );
  });

  test('11: null context fails closed', () {
    expect(
      () => summarizer.summarize([_observation(context: null)]),
      throwsArgumentError,
    );
  });

  test('12: input order does not change the summary', () {
    final observations = [
      _observation(context: addition),
      _observation(context: addition, correct: false),
      _observation(context: addition, timedOut: true),
    ];

    expectSameSummary(
      summarizer.summarize(observations),
      summarizer.summarize(observations.reversed.toList()),
    );
  });

  test('13: response time values do not change any summary field', () {
    final ordinary = [_observation(context: addition, responseTimeMs: 1)];
    final delayed = [_observation(context: addition, responseTimeMs: 999999)];

    expectSameSummary(
      summarizer.summarize(ordinary),
      summarizer.summarize(delayed),
    );
  });

  test('14: caller-list mutation does not change a returned summary', () {
    final observations = <ContextEvidenceObservation>[
      _observation(context: addition)
    ];
    final summary = summarizer.summarize(observations);
    observations
      ..clear()
      ..add(_observation(context: multiplication, correct: false));

    expect(summary.context, addition);
    expect(summary.evidenceCount, 1);
    expect(summary.correctCount, 1);
  });

  test('15: summaries retain no gameplay authority', () {
    final summary = summarizer.summarize([_observation(context: addition)]);

    expect(summary.authority, BoundedOutcomeDescriptiveAuthority.none);
    expect(summary.mayAffectGameplay, isFalse);
  });
}

ContextEvidenceKey _context(Operation operation) => ContextEvidenceKey(
      operation: operation,
      numberType: NumberType.natural,
    );

ContextEvidenceObservation _observation({
  required ContextEvidenceKey? context,
  Difficulty difficulty = Difficulty.easy,
  bool correct = true,
  bool timedOut = false,
  int responseTimeMs = 1000,
}) =>
    ContextEvidenceObservation(
      context: context,
      difficulty: difficulty,
      correctAnswer: 4,
      submittedAnswer: timedOut ? null : (correct ? 4 : 3),
      correct: timedOut ? false : correct,
      timedOut: timedOut,
      responseTimeMs: responseTimeMs,
    );

void expectSameSummary(
  BoundedOutcomeDescriptiveSummary first,
  BoundedOutcomeDescriptiveSummary second,
) {
  expect(first.context, second.context);
  expect(first.difficulty, second.difficulty);
  expect(first.evidenceCount, second.evidenceCount);
  expect(first.answeredCount, second.answeredCount);
  expect(first.correctCount, second.correctCount);
  expect(first.incorrectCount, second.incorrectCount);
  expect(first.timeoutCount, second.timeoutCount);
  expect(first.answeredRate, second.answeredRate);
  expect(first.correctRate, second.correctRate);
  expect(first.incorrectRate, second.incorrectRate);
  expect(first.timeoutRate, second.timeoutRate);
  expect(first.authority, second.authority);
  expect(first.mayAffectGameplay, second.mayAffectGameplay);
}
