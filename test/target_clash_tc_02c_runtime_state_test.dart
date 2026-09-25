import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/presentation_answer.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_question_generator.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_run_config.dart';
import 'package:math_challenge/features/target_clash/domain/target_clash_runtime_state.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/math_fact.dart';
import 'package:math_challenge/models/player.dart';

void main() {
  test('initial state, profiles, and Triple mapping are deterministic', () {
    final state = TargetClashRuntimeState.start(_stage());
    expect(state.phase, TargetClashPhase.ordinaryStage1);
    expect(state.currentQuestion, isNotNull);
    expect(state.score, 0);
    expect(state.finished, isFalse);
    expect(
        TargetClashRuntimeState.ordinaryRequests(Difficulty.easy, 1)
            .map((r) => r.zone),
        [TargetZone.normal, TargetZone.normal, TargetZone.bullseye]);
    expect(TargetClashRuntimeState.tripleRequests(0)!.map((r) => r.answer), [
      PresentationAnswer.lessThan,
      PresentationAnswer.equalTo,
      PresentationAnswer.greaterThan
    ]);
    expect(TargetClashRuntimeState.tripleRequests(6), isNull);
  });

  test(
      'legacy empty successful stages fail closed only at the runtime boundary',
      () {
    final empty = _freshEmptyStage();
    expect(empty.stage, isNotNull);
    expect(empty.stage!.questions, isEmpty);
    final initial = TargetClashRuntimeState.start(empty);
    expect(initial.phase, TargetClashPhase.technicalFailure);
    expect(
        initial.generationFailure, TargetClashGenerationFailure.invalidRequest);
    expect(initial.preparedStage, isNull);
    expect(initial.currentQuestion, isNull);
    expect(initial.finished, isFalse);

    final boundary = TargetClashRuntimeState.start(
      _stage(requests: const [_lessNormal]),
    ).resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.easy,
      nextStage: empty,
    );
    expect(boundary.phase, TargetClashPhase.technicalFailure);
    expect(boundary.generationFailure,
        TargetClashGenerationFailure.invalidRequest);
    expect(boundary.preparedStage, isNull);
    expect(boundary.currentQuestion, isNull);
    expect(boundary.finished, isFalse);
  });

  test(
      'correct resolution scores, advances immutably, and timeout resets combo',
      () {
    final first = TargetClashRuntimeState.start(_stage());
    final second = first.resolve(
        answer: PresentationAnswer.lessThan,
        difficulty: Difficulty.easy,
        nextStage: _stage());
    expect(first.score, 0);
    expect(first.stageQuestionIndex, 0);
    expect(second.score, 10);
    expect(second.combo, 1);
    final timedOut =
        second.resolve(difficulty: Difficulty.easy, nextStage: _stage());
    expect(timedOut.combo, 0);
    expect(timedOut.score, 10);
  });

  test('all ordinary, boss, final, and Triple profiles are deterministic', () {
    List<(PresentationAnswer, TargetZone)> pairs(
            List<TargetClashQuestionRequest> requests) =>
        requests.map((request) => (request.answer, request.zone)).toList();
    const ln = (PresentationAnswer.lessThan, TargetZone.normal);
    const gn = (PresentationAnswer.greaterThan, TargetZone.normal);
    const lc = (PresentationAnswer.lessThan, TargetZone.closeCall);
    const gc = (PresentationAnswer.greaterThan, TargetZone.closeCall);
    const ld = (PresentationAnswer.lessThan, TargetZone.danger);
    const gd = (PresentationAnswer.greaterThan, TargetZone.danger);
    const eq = (PresentationAnswer.equalTo, TargetZone.bullseye);
    expect(pairs(TargetClashRuntimeState.ordinaryRequests(Difficulty.easy, 1)),
        const [ln, gn, eq]);
    expect(pairs(TargetClashRuntimeState.ordinaryRequests(Difficulty.easy, 2)),
        const [gn, ln, eq]);
    expect(
        pairs(TargetClashRuntimeState.ordinaryRequests(Difficulty.medium, 1)),
        const [ln, gc, eq]);
    expect(
        pairs(TargetClashRuntimeState.ordinaryRequests(Difficulty.medium, 2)),
        const [gn, lc, eq]);
    expect(pairs(TargetClashRuntimeState.ordinaryRequests(Difficulty.hard, 1)),
        const [lc, gd, eq]);
    expect(pairs(TargetClashRuntimeState.ordinaryRequests(Difficulty.hard, 2)),
        const [gc, ld, eq]);
    expect(pairs(TargetClashRuntimeState.bossRequests(Difficulty.easy)),
        const [ln, gd, eq]);
    expect(pairs(TargetClashRuntimeState.bossRequests(Difficulty.medium)),
        const [ln, gc, ld, eq]);
    expect(pairs(TargetClashRuntimeState.bossRequests(Difficulty.hard)),
        const [ln, gc, ld, gd, eq]);
    expect(pairs(TargetClashRuntimeState.finalRequests(Difficulty.easy)),
        const [ln, gc, eq]);
    expect(pairs(TargetClashRuntimeState.finalRequests(Difficulty.medium)),
        const [lc, gd, eq]);
    expect(pairs(TargetClashRuntimeState.finalRequests(Difficulty.hard)),
        const [ld, gd, eq]);
    expect(
      List.generate(
          6,
          (index) => TargetClashRuntimeState.tripleRequests(index)!
              .map((request) => request.answer)
              .toList()),
      const [
        [
          PresentationAnswer.lessThan,
          PresentationAnswer.equalTo,
          PresentationAnswer.greaterThan
        ],
        [
          PresentationAnswer.lessThan,
          PresentationAnswer.greaterThan,
          PresentationAnswer.equalTo
        ],
        [
          PresentationAnswer.equalTo,
          PresentationAnswer.lessThan,
          PresentationAnswer.greaterThan
        ],
        [
          PresentationAnswer.equalTo,
          PresentationAnswer.greaterThan,
          PresentationAnswer.lessThan
        ],
        [
          PresentationAnswer.greaterThan,
          PresentationAnswer.lessThan,
          PresentationAnswer.equalTo
        ],
        [
          PresentationAnswer.greaterThan,
          PresentationAnswer.equalTo,
          PresentationAnswer.lessThan
        ],
      ],
    );
    expect(TargetClashRuntimeState.tripleRequests(-1), isNull);
    expect(TargetClashRuntimeState.tripleRequests(6), isNull);
  });

  test('Perfect Hit, combo-four, and technical failure preserve state facts',
      () {
    var state = TargetClashRuntimeState.start(_stage(requests: const [
      TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
    ]));
    state = state.resolve(
        answer: PresentationAnswer.equalTo,
        difficulty: Difficulty.easy,
        nextStage: _stage());
    expect(state.score, 20);
    for (var i = 0; i < 3; i++) {
      state = state.resolve(
          answer: PresentationAnswer.lessThan,
          difficulty: Difficulty.easy,
          nextStage: _stage());
    }
    expect(state.score, 60);
    final failed = state.resolve(
        answer: PresentationAnswer.lessThan,
        difficulty: Difficulty.easy,
        nextStage: _failedStage());
    expect(failed.phase, TargetClashPhase.technicalFailure);
    expect(failed.currentQuestion, isNull);
    expect(failed.finished, isFalse);
    expect(failed.generationFailure,
        TargetClashGenerationFailure.slotGenerationFailed);
  });

  test('best Combo survives a reset and Perfect Hit increments its counter',
      () {
    var combo = TargetClashRuntimeState.start(_stage(requests: const [
      _lessNormal,
      _lessNormal,
    ]));
    combo = combo.resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.easy,
      nextStage: _stage(),
    );
    combo = combo.resolve(difficulty: Difficulty.easy, nextStage: _stage());
    expect(combo.combo, 0);
    expect(combo.bestCombo, 1);

    final perfect = TargetClashRuntimeState.start(_stage(requests: const [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
    ])).resolve(
      answer: PresentationAnswer.equalTo,
      difficulty: Difficulty.easy,
      nextStage: _stage(),
    );
    expect(perfect.perfectHits, 1);
  });

  test(
      'Power Shot replaces only its slot, clears once, and unavailable is inert',
      () {
    final requests = <TargetClashQuestionRequest>[
      const TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      const TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      const TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      const TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      const TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
    ];
    var state = TargetClashRuntimeState.start(_stage(requests: requests));
    for (var i = 0; i < 3; i++) {
      state = state.resolve(
          answer: PresentationAnswer.equalTo,
          difficulty: Difficulty.easy,
          nextStage: _stage());
    }
    final before = state.preparedStage!;
    expect(state.clashPower, 6);
    final applied = state.activatePowerShot(
        config: _config(),
        generator:
            TargetClashQuestionGenerator(questionGenerator: _Generator()));
    expect(applied.outcome, TargetClashPowerShotOutcome.applied);
    expect(applied.state.clashPower, 0);
    expect(
        applied.state.preparedStage!.questions[0], same(before.questions[0]));
    final cleared = applied.state.resolve(
        answer: PresentationAnswer.lessThan,
        difficulty: Difficulty.easy,
        nextStage: _stage());
    expect(cleared.powerShotAppliedQuestionIndex, isNull);
    final unavailable = state.activatePowerShot(
        config: _config(),
        generator:
            TargetClashQuestionGenerator(questionGenerator: _NullGenerator()));
    expect(unavailable.outcome, TargetClashPowerShotOutcome.unavailable);
    expect(unavailable.state, same(state));
  });

  test(
      'Hard Fever consumes wrong and timeout, retains Bullseye, and fallback is inert',
      () {
    var state = _hardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
    ]));
    expect(state.feverRemaining, 3);
    final bullseye = state.currentQuestion!;
    state = state.hardenForFever(
        config: _hardConfig(),
        generator:
            TargetClashQuestionGenerator(questionGenerator: _NullGenerator()));
    expect(state.currentQuestion, same(bullseye));
    state = state.resolve(
        answer: PresentationAnswer.equalTo,
        difficulty: Difficulty.hard,
        nextStage: _stage());
    expect(state.feverRemaining, 2);
    final beforeFallback = state.preparedStage;
    state = state.hardenForFever(
        config: _hardConfig(),
        generator:
            TargetClashQuestionGenerator(questionGenerator: _NullGenerator()));
    expect(state.preparedStage, same(beforeFallback));
    expect(state.phase, TargetClashPhase.boss);
    state = state.resolve(
        answer: PresentationAnswer.greaterThan,
        difficulty: Difficulty.hard,
        nextStage: _stage());
    expect(state.feverRemaining, 1);
    state = state.resolve(difficulty: Difficulty.hard, nextStage: _stage());
    expect(state.feverRemaining, 0);
    expect(state.phase, isNot(TargetClashPhase.technicalFailure));
  });

  test(
      'combo-four Fever Power Shot scores 120 and Triple completion arms Fever',
      () {
    final state = _hardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
    ]));
    expect(state.phase, TargetClashPhase.boss);
    expect(state.feverRemaining, 3);
    expect(state.clashPower, 6);
    final armed = state
        .activatePowerShot(
            config: _hardConfig(),
            generator:
                TargetClashQuestionGenerator(questionGenerator: _Generator()))
        .state;
    final before = armed.score;
    final resolved = armed.resolve(
        answer: PresentationAnswer.greaterThan,
        difficulty: Difficulty.hard,
        nextStage: _stage());
    expect(resolved.score - before, 120);
    expect(resolved.powerShotAppliedQuestionIndex, isNull);
  });

  test(
      'Boss early defeat discards slots while cap exit does not count a defeat',
      () {
    var early = _hardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
    ]));
    for (var index = 0; index < 3; index++) {
      early = early.resolve(
          answer: PresentationAnswer.equalTo,
          difficulty: Difficulty.hard,
          nextStage: _stage());
    }
    expect(early.phase, TargetClashPhase.finalTarget);
    expect(early.bossesDefeated, 1);
    expect(early.bossQuestionsResolved, 3);
    var capped = _hardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
    ]));
    for (var index = 0; index < 5; index++) {
      capped = capped.resolve(
          answer: PresentationAnswer.greaterThan,
          difficulty: Difficulty.hard,
          nextStage: _stage());
    }
    expect(capped.phase, TargetClashPhase.finalTarget);
    expect(capped.bossesDefeated, 0);
    expect(capped.bossQuestionsResolved, 5);
    expect(capped.preparedStage!.questions.length, 2);
  });

  test('Final finishes after exactly three and clears only with two correct',
      () {
    var cleared = _easyFinalState();
    for (var index = 0; index < 3; index++) {
      cleared = cleared.resolve(
          answer: PresentationAnswer.lessThan,
          difficulty: Difficulty.easy,
          nextStage: _stage());
    }
    expect(cleared.finished, isTrue);
    expect(cleared.finalResolved, 3);
    expect(cleared.finalTargetCompleted, isTrue);
    expect(cleared.finalTargetCleared, isTrue);
    var notCleared = _easyFinalState();
    for (var index = 0; index < 3; index++) {
      notCleared = notCleared.resolve(
          answer: PresentationAnswer.greaterThan,
          difficulty: Difficulty.easy,
          nextStage: _stage());
    }
    expect(notCleared.finished, isTrue);
    expect(notCleared.finalCorrect, 0);
    expect(notCleared.finalTargetCleared, isFalse);
  });

  test('complete paths resolve the exact configured question targets', () {
    for (final entry in const [
      (Difficulty.easy, 12),
      (Difficulty.medium, 16),
      (Difficulty.hard, 17),
    ]) {
      var state = TargetClashRuntimeState.start(_stageWithLength(3));
      while (!state.finished) {
        final phase = state.phase;
        state = state.resolve(
          answer: state.currentQuestion!.correctAnswer,
          difficulty: entry.$1,
          nextStage: _stageWithLength(switch (phase) {
            TargetClashPhase.triple => switch (entry.$1) {
                Difficulty.easy => 3,
                Difficulty.medium => 4,
                Difficulty.hard => 5,
                _ => 0,
              },
            _ => 3,
          }),
        );
      }
      expect(state.resolvedCount, entry.$2);
      expect(state.displayCombo, 9);
      expect(state.combo, entry.$2);
    }
  });

  test('Triple completion is one-shot and Hard alone arms Fever', () {
    var hard = _tripleState(Difficulty.hard);
    for (var index = 0; index < 3; index++) {
      hard = hard.resolve(
        answer: PresentationAnswer.equalTo,
        difficulty: Difficulty.hard,
        nextStage: _stage(requests: const [_lessNormal]),
      );
    }
    expect(hard.phase, TargetClashPhase.boss);
    expect(hard.tripleClashesCompleted, 1);
    expect(hard.feverRemaining, 3);
    hard = hard.resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.hard,
      nextStage: _stage(),
    );
    expect(hard.tripleClashesCompleted, 1);

    var partial = _tripleState(Difficulty.hard);
    for (var index = 0; index < 2; index++) {
      partial = partial.resolve(
        answer: PresentationAnswer.equalTo,
        difficulty: Difficulty.hard,
        nextStage: _stage(requests: const [_lessNormal]),
      );
    }
    expect(partial.phase, TargetClashPhase.triple);
    expect(partial.tripleClashesCompleted, 0);
    expect(partial.feverRemaining, 0);
    partial = partial.resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.hard,
      nextStage: _stage(requests: const [_lessNormal]),
    );
    expect(partial.phase, TargetClashPhase.boss);
    expect(partial.currentQuestion, isNotNull);
    expect(partial.tripleCorrectCount, 2);
    expect(partial.tripleClashesCompleted, 0);
    expect(partial.feverRemaining, 0);
  });

  test('Power Shot denial, danger identity, and unavailable state are exact',
      () {
    final below = TargetClashRuntimeState.start(_stage());
    expect(
      below
          .activatePowerShot(config: _config(), generator: _tcGenerator())
          .outcome,
      TargetClashPowerShotOutcome.denied,
    );
    final triple = _chargedTripleState();
    expect(triple.clashPower, 6);
    expect(
      triple
          .activatePowerShot(config: _hardConfig(), generator: _tcGenerator())
          .outcome,
      TargetClashPowerShotOutcome.denied,
    );
    final dangerState = _chargedHardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.lessThan,
        zone: TargetZone.danger,
      ),
    ]));
    final source = _CountingGenerator();
    final applied = dangerState.activatePowerShot(
      config: _hardConfig(),
      generator: TargetClashQuestionGenerator(questionGenerator: source),
    );
    expect(applied.outcome, TargetClashPowerShotOutcome.applied);
    expect(applied.state.currentQuestion, same(dangerState.currentQuestion));
    expect(source.directCalls, 0);
    expect(applied.state.clashPower, 0);
    expect(applied.state.powerShotAppliedQuestionIndex, 0);
    final unavailable = _chargedHardBossState(_stage()).activatePowerShot(
      config: _hardConfig(),
      generator:
          TargetClashQuestionGenerator(questionGenerator: _NullGenerator()),
    );
    expect(unavailable.outcome, TargetClashPowerShotOutcome.unavailable);
    expect(unavailable.state.clashPower, 6);
    expect(unavailable.state.powerShotAppliedQuestionIndex, isNull);
    expect(unavailable.state.phase, isNot(TargetClashPhase.technicalFailure));
  });

  test('a Power Shot marker clears on its slot and grants no next-slot bonus',
      () {
    final armed = _chargedHardBossState(_stage(requests: const [
      _lessNormal,
    ]))
        .activatePowerShot(config: _hardConfig(), generator: _tcGenerator())
        .state;
    final marked = armed.resolve(
      answer: armed.currentQuestion!.correctAnswer,
      difficulty: Difficulty.hard,
      nextStage: _stage(requests: const [_lessNormal]),
    );
    expect(marked.powerShotAppliedQuestionIndex, isNull);
    final before = marked.score;
    final following = marked.resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.hard,
      nextStage: _stage(),
    );
    expect(following.score - before, 60);
    expect(following.powerShotAppliedQuestionIndex, isNull);
  });

  test('manual Power Shot may replace a Bullseye slot', () {
    final state = _chargedHardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
    ]));
    final original = state.currentQuestion!;
    final applied = state.activatePowerShot(
      config: _hardConfig(),
      generator: _tcGenerator(),
    );
    final replacement = applied.state.currentQuestion!;
    expect(applied.outcome, TargetClashPowerShotOutcome.applied);
    expect(replacement, isNot(same(original)));
    expect(replacement.targetValue, original.targetValue);
    expect(replacement.zone, anyOf(TargetZone.danger, TargetZone.closeCall));
    expect(applied.state.clashPower, 0);
    expect(applied.state.powerShotAppliedQuestionIndex, 0);
  });

  test('Fever hardening preserves less-than and greater-than relations', () {
    for (final answer in const [
      PresentationAnswer.lessThan,
      PresentationAnswer.greaterThan,
    ]) {
      final state = _chargedHardBossState(_stage(requests: [
        TargetClashQuestionRequest(answer: answer, zone: TargetZone.normal),
      ]));
      final before = state.currentQuestion!;
      final hardened = state.hardenForFever(
        config: _hardConfig(),
        generator: _tcGenerator(),
      );
      expect(hardened.currentQuestion!.correctAnswer, answer);
      expect(hardened.currentQuestion!.zone, TargetZone.danger);
      expect(hardened.currentQuestion!.targetValue, before.targetValue);
    }
  });

  test('Fever and Power Shot materialize a scheduled slot only once', () {
    final state = _chargedHardBossState(_stage(requests: const [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.lessThan,
        zone: TargetZone.normal,
      ),
    ]));
    final source = _CountingGenerator();
    final generator = TargetClashQuestionGenerator(questionGenerator: source);
    final armed = state
        .activatePowerShot(config: _hardConfig(), generator: generator)
        .state;
    expect(source.directCalls, 1);
    final hardened =
        armed.hardenForFever(config: _hardConfig(), generator: generator);
    expect(hardened.currentQuestion, same(armed.currentQuestion));
    expect(source.directCalls, 1);
  });

  test('Final completion separates all four correct-count outcomes', () {
    for (final correct in [0, 1, 2, 3]) {
      var state = _easyFinalState();
      for (var index = 0; index < 3; index++) {
        state = state.resolve(
          answer: index < correct
              ? PresentationAnswer.lessThan
              : PresentationAnswer.greaterThan,
          difficulty: Difficulty.easy,
          nextStage: _stage(),
        );
      }
      expect(state.finalTargetCompleted, isTrue);
      expect(state.finalTargetCleared, correct >= 2);
    }
  });

  test('Boss damage and Clash Power use only correct and Perfect Hit rules',
      () {
    TargetClashRuntimeState resolveBoss(
      TargetClashQuestionRequest request,
      PresentationAnswer? answer,
    ) =>
        _chargedHardBossState(_stage(requests: [request])).resolve(
          answer: answer,
          difficulty: Difficulty.hard,
          nextStage: _stage(),
        );
    expect(
      resolveBoss(_lessNormal, PresentationAnswer.lessThan).bossHealth,
      4,
    );
    expect(
      resolveBoss(
        const TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo,
          zone: TargetZone.bullseye,
        ),
        PresentationAnswer.equalTo,
      ).bossHealth,
      3,
    );
    expect(
        resolveBoss(_lessNormal, PresentationAnswer.greaterThan).bossHealth, 5);
    expect(resolveBoss(_lessNormal, null).bossHealth, 5);
    final correct =
        TargetClashRuntimeState.start(_stage(requests: const [_lessNormal]))
            .resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.easy,
      nextStage: _stage(),
    );
    final perfect = TargetClashRuntimeState.start(_stage(requests: const [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
    ])).resolve(
      answer: PresentationAnswer.equalTo,
      difficulty: Difficulty.easy,
      nextStage: _stage(),
    );
    expect(correct.clashPower, 1);
    expect(perfect.clashPower, 2);
    expect(_chargedHardBossState(_stage()).clashPower, 6);
    expect(
      TargetClashRuntimeState.start(_stage())
          .resolve(
            difficulty: Difficulty.easy,
            nextStage: _stage(),
          )
          .clashPower,
      0,
    );
  });

  test('generation failures are terminal at every stage boundary', () {
    final initial = TargetClashRuntimeState.start(_failedStage());
    final boundaries = <TargetClashRuntimeState>[
      TargetClashRuntimeState.start(_stage(requests: const [_lessNormal]))
          .resolve(
        answer: PresentationAnswer.lessThan,
        difficulty: Difficulty.easy,
        nextStage: _failedStage(),
      ),
      _mediumTripleBoundaryFailure(),
      _easyBossBoundaryFailure(),
      _chargedHardBossState(_stage(requests: const [_lessNormal])).resolve(
        answer: PresentationAnswer.lessThan,
        difficulty: Difficulty.hard,
        nextStage: _failedStage(),
      ),
    ];
    for (final state in [initial, ...boundaries]) {
      expect(state.phase, TargetClashPhase.technicalFailure);
      expect(state.generationFailure, isNotNull);
      expect(state.preparedStage, isNull);
      expect(state.currentQuestion, isNull);
      expect(state.finished, isFalse);
    }
  });
}

const _lessNormal = TargetClashQuestionRequest(
  answer: PresentationAnswer.lessThan,
  zone: TargetZone.normal,
);

TargetClashStageResult _freshEmptyStage() =>
    TargetClashQuestionGenerator(questionGenerator: _FreshGenerator())
        .prepareStage(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      requests: const [],
    );

TargetClashStageResult _stageWithLength(int length) => _stage(
      requests: List.filled(
        length,
        const TargetClashQuestionRequest(
          answer: PresentationAnswer.lessThan,
          zone: TargetZone.normal,
        ),
      ),
    );

TargetClashStageResult _stage({List<TargetClashQuestionRequest>? requests}) =>
    TargetClashQuestionGenerator(
      questionGenerator: _Generator(),
    ).prepareStageForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      targetValue: 10,
      requests: requests ??
          const [
            TargetClashQuestionRequest(
                answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
            TargetClashQuestionRequest(
                answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
          ],
    );

TargetClashRunConfig _config() => TargetClashRunConfig.tryCreate(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
    )!;

TargetClashStageResult _failedStage() =>
    TargetClashQuestionGenerator(questionGenerator: _NullGenerator())
        .prepareStageForTarget(
      operation: Operation.addition,
      difficulty: Difficulty.easy,
      numberType: NumberType.natural,
      targetValue: 10,
      requests: const [
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      ],
    );

TargetClashRunConfig _hardConfig() => TargetClashRunConfig.tryCreate(
      operation: Operation.addition,
      difficulty: Difficulty.hard,
      numberType: NumberType.natural,
    )!;

TargetClashQuestionGenerator _tcGenerator() =>
    TargetClashQuestionGenerator(questionGenerator: _Generator());

TargetClashRuntimeState _tripleState(Difficulty difficulty) {
  var state = TargetClashRuntimeState.start(_stage(requests: const [
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
  ]));
  final one = _stage(requests: const [
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
  ]);
  final triple = _stage(requests: const [
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
  ]);
  state = state.resolve(
    answer: PresentationAnswer.equalTo,
    difficulty: difficulty,
    nextStage: one,
  );
  return state.resolve(
    answer: PresentationAnswer.equalTo,
    difficulty: difficulty,
    nextStage: triple,
  );
}

TargetClashRuntimeState _chargedTripleState() {
  var state = TargetClashRuntimeState.start(_stage(requests: const [
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
    TargetClashQuestionRequest(
      answer: PresentationAnswer.equalTo,
      zone: TargetZone.bullseye,
    ),
  ]));
  for (var index = 0; index < 3; index++) {
    state = state.resolve(
      answer: PresentationAnswer.equalTo,
      difficulty: Difficulty.hard,
      nextStage: _stage(requests: const [
        TargetClashQuestionRequest(
          answer: PresentationAnswer.equalTo,
          zone: TargetZone.bullseye,
        ),
      ]),
    );
  }
  return state.resolve(
    answer: PresentationAnswer.equalTo,
    difficulty: Difficulty.hard,
    nextStage: _stage(requests: const [
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
      TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo,
        zone: TargetZone.bullseye,
      ),
    ]),
  );
}

TargetClashRuntimeState _mediumTripleBoundaryFailure() {
  var state =
      TargetClashRuntimeState.start(_stage(requests: const [_lessNormal]));
  state = state.resolve(
    answer: PresentationAnswer.lessThan,
    difficulty: Difficulty.medium,
    nextStage: _stage(requests: const [_lessNormal]),
  );
  return state.resolve(
    answer: PresentationAnswer.lessThan,
    difficulty: Difficulty.medium,
    nextStage: _failedStage(),
  );
}

TargetClashRuntimeState _easyBossBoundaryFailure() {
  var state =
      TargetClashRuntimeState.start(_stage(requests: const [_lessNormal]));
  state = state.resolve(
    answer: PresentationAnswer.lessThan,
    difficulty: Difficulty.easy,
    nextStage: _stage(requests: const [_lessNormal]),
  );
  return state.resolve(
    answer: PresentationAnswer.lessThan,
    difficulty: Difficulty.easy,
    nextStage: _failedStage(),
  );
}

TargetClashRuntimeState _chargedHardBossState(TargetClashStageResult stage) =>
    _hardBossState(stage);

TargetClashRuntimeState _hardBossState(TargetClashStageResult bossStage) {
  var state = TargetClashRuntimeState.start(_stage(requests: const [
    TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
  ]));
  final one = _stage(requests: const [
    TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
  ]);
  final triple = _stage(requests: const [
    TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
    TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
    TargetClashQuestionRequest(
        answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye),
  ]);
  state = state.resolve(
      answer: PresentationAnswer.equalTo,
      difficulty: Difficulty.hard,
      nextStage: one);
  state = state.resolve(
      answer: PresentationAnswer.equalTo,
      difficulty: Difficulty.hard,
      nextStage: triple);
  for (var index = 0; index < 3; index++) {
    state = state.resolve(
        answer: PresentationAnswer.equalTo,
        difficulty: Difficulty.hard,
        nextStage: index == 2 ? bossStage : one);
  }
  return state;
}

TargetClashRuntimeState _easyFinalState() {
  var state = TargetClashRuntimeState.start(_stage(requests: const [
    TargetClashQuestionRequest(
        answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
  ]));
  final one = _stage(requests: const [
    TargetClashQuestionRequest(
        answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
  ]);
  state = state.resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.easy,
      nextStage: one);
  state = state.resolve(
      answer: PresentationAnswer.lessThan,
      difficulty: Difficulty.easy,
      nextStage: _stage(requests: const [
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
        TargetClashQuestionRequest(
            answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
      ]));
  for (var index = 0; index < 3; index++) {
    state = state.resolve(
        answer: PresentationAnswer.lessThan,
        difficulty: Difficulty.easy,
        nextStage: _stage(requests: const [
          TargetClashQuestionRequest(
              answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
          TargetClashQuestionRequest(
              answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
          TargetClashQuestionRequest(
              answer: PresentationAnswer.lessThan, zone: TargetZone.normal),
        ]));
  }
  return state;
}

class _Generator extends QuestionGenerator {
  @override
  Question buildDirectForResult(
          {required Operation type,
          required Difficulty diff,
          required NumberType numType,
          required num result}) =>
      Question(
        type: type,
        key: '$result',
        text: '$result',
        ans: result,
        choices: const [],
        fact: MathFact(
            operation: type,
            left: result,
            right: 0,
            result: result,
            representation: FactRepresentation.direct,
            difficulty: diff,
            numberType: numType),
      );
}

final class _FreshGenerator extends _Generator {
  @override
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) =>
      buildDirectForResult(
        type: type,
        diff: diff,
        numType: numType,
        result: 10,
      );
}

final class _NullGenerator extends QuestionGenerator {
  @override
  Question? buildDirectForResult(
          {required Operation type,
          required Difficulty diff,
          required NumberType numType,
          required num result}) =>
      null;
}

final class _CountingGenerator extends _Generator {
  int directCalls = 0;

  @override
  Question buildDirectForResult({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    required num result,
  }) {
    directCalls++;
    return super.buildDirectForResult(
      type: type,
      diff: diff,
      numType: numType,
      result: result,
    );
  }
}
