import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../models/enums.dart';
import 'presentation_answer.dart';
import 'target_clash_question.dart';
import 'target_clash_question_generator.dart';
import 'target_clash_run_config.dart';

enum TargetClashPhase {
  ordinaryStage1,
  ordinaryStage2,
  triple,
  boss,
  finalTarget,
  finished,
  technicalFailure,
}

enum TargetClashPowerShotOutcome { applied, unavailable, denied }

final class TargetClashPowerShotResult {
  const TargetClashPowerShotResult(this.state, this.outcome);

  final TargetClashRuntimeState state;
  final TargetClashPowerShotOutcome outcome;
}

/// Immutable, side-effect-free Target Clash progression state.
final class TargetClashRuntimeState {
  const TargetClashRuntimeState._({
    required this.phase,
    required this.preparedStage,
    required this.stageQuestionIndex,
    required this.score,
    required this.correctCount,
    required this.resolvedCount,
    required this.combo,
    required this.bestCombo,
    required this.perfectHits,
    required this.clashPower,
    required this.powerShotAppliedQuestionIndex,
    required this.feverRemaining,
    required this.tripleCorrectCount,
    required this.tripleClashesCompleted,
    required this.bossHealth,
    required this.bossQuestionsResolved,
    required this.bossesDefeated,
    required this.finalCorrect,
    required this.finalResolved,
    required this.generationFailure,
  });

  factory TargetClashRuntimeState.start(TargetClashStageResult result) {
    if (result.stage == null) return _failure(result.failure!);
    if (result.stage!.questions.isEmpty) {
      return _failure(TargetClashGenerationFailure.invalidRequest);
    }
    return TargetClashRuntimeState._(
      phase: TargetClashPhase.ordinaryStage1,
      preparedStage: result.stage,
      stageQuestionIndex: 0,
      score: 0,
      correctCount: 0,
      resolvedCount: 0,
      combo: 0,
      bestCombo: 0,
      perfectHits: 0,
      clashPower: 0,
      powerShotAppliedQuestionIndex: null,
      feverRemaining: 0,
      tripleCorrectCount: 0,
      tripleClashesCompleted: 0,
      bossHealth: 0,
      bossQuestionsResolved: 0,
      bossesDefeated: 0,
      finalCorrect: 0,
      finalResolved: 0,
      generationFailure: null,
    );
  }

  @visibleForTesting
  factory TargetClashRuntimeState.debugBossStateForTest(
    TargetClashStageResult result, {
    required int bossHealth,
    int stageQuestionIndex = 0,
  }) {
    final stage = result.stage;
    assert(stage != null && stage.questions.length > stageQuestionIndex + 1);
    assert(bossHealth > 0);
    return TargetClashRuntimeState._(
      phase: TargetClashPhase.boss,
      preparedStage: stage,
      stageQuestionIndex: stageQuestionIndex,
      score: 0,
      correctCount: 0,
      resolvedCount: 0,
      combo: 0,
      bestCombo: 0,
      perfectHits: 0,
      clashPower: 0,
      powerShotAppliedQuestionIndex: null,
      feverRemaining: 0,
      tripleCorrectCount: 0,
      tripleClashesCompleted: 0,
      bossHealth: bossHealth,
      bossQuestionsResolved: stageQuestionIndex,
      bossesDefeated: 0,
      finalCorrect: 0,
      finalResolved: 0,
      generationFailure: null,
    );
  }

  static TargetClashRuntimeState _failure(
          TargetClashGenerationFailure failure) =>
      TargetClashRuntimeState._(
        phase: TargetClashPhase.technicalFailure,
        preparedStage: null,
        stageQuestionIndex: 0,
        score: 0,
        correctCount: 0,
        resolvedCount: 0,
        combo: 0,
        bestCombo: 0,
        perfectHits: 0,
        clashPower: 0,
        powerShotAppliedQuestionIndex: null,
        feverRemaining: 0,
        tripleCorrectCount: 0,
        tripleClashesCompleted: 0,
        bossHealth: 0,
        bossQuestionsResolved: 0,
        bossesDefeated: 0,
        finalCorrect: 0,
        finalResolved: 0,
        generationFailure: failure,
      );

  final TargetClashPhase phase;
  final TargetClashStage? preparedStage;
  final int stageQuestionIndex;
  final int score;
  final int correctCount;
  final int resolvedCount;
  final int combo;
  final int bestCombo;
  final int perfectHits;
  final int clashPower;
  final int? powerShotAppliedQuestionIndex;
  final int feverRemaining;
  final int tripleCorrectCount;
  final int tripleClashesCompleted;
  final int bossHealth;
  final int bossQuestionsResolved;
  final int bossesDefeated;
  final int finalCorrect;
  final int finalResolved;
  final TargetClashGenerationFailure? generationFailure;

  TargetClashQuestion? get currentQuestion => preparedStage == null ||
          stageQuestionIndex < 0 ||
          stageQuestionIndex >= preparedStage!.questions.length
      ? null
      : preparedStage!.questions[stageQuestionIndex];
  num? get currentTarget => currentQuestion?.targetValue;
  int get displayCombo => combo > 9 ? 9 : combo;
  int get comboMultiplier =>
      combo == 0 ? 1 : (1 + ((combo - 1) ~/ 3)).clamp(1, 3);
  bool get isTriple => phase == TargetClashPhase.triple;
  bool get isFeverActive => feverRemaining > 0;
  bool get finalTargetCompleted => finalResolved == 3;
  bool get finalTargetCleared => finalCorrect >= 2;
  bool get finished => phase == TargetClashPhase.finished;
  bool get isPowerShotReady => clashPower == 6;

  static List<TargetClashQuestionRequest> ordinaryRequests(
    Difficulty difficulty,
    int stage,
  ) =>
      switch ((difficulty, stage)) {
        (Difficulty.easy, 1) => const [_ln, _gn, _eq],
        (Difficulty.easy, 2) => const [_gn, _ln, _eq],
        (Difficulty.medium, 1) => const [_ln, _gc, _eq],
        (Difficulty.medium, 2) => const [_gn, _lc, _eq],
        (Difficulty.hard, 1) => const [_lc, _gd, _eq],
        (Difficulty.hard, 2) => const [_gc, _ld, _eq],
        _ => const [],
      };

  static List<TargetClashQuestionRequest>? tripleRequests(int index) {
    const permutations = [
      [_ln, _eq, _gn],
      [_ln, _gn, _eq],
      [_eq, _ln, _gn],
      [_eq, _gn, _ln],
      [_gn, _ln, _eq],
      [_gn, _eq, _ln],
    ];
    return index < 0 || index >= permutations.length
        ? null
        : permutations[index];
  }

  static List<TargetClashQuestionRequest> bossRequests(Difficulty difficulty) =>
      switch (difficulty) {
        Difficulty.easy => const [_ln, _gd, _eq],
        Difficulty.medium => const [_ln, _gc, _ld, _eq],
        Difficulty.hard => const [_ln, _gc, _ld, _gd, _eq],
        _ => const [],
      };

  static List<TargetClashQuestionRequest> finalRequests(
          Difficulty difficulty) =>
      switch (difficulty) {
        Difficulty.easy => const [_ln, _gc, _eq],
        Difficulty.medium => const [_lc, _gd, _eq],
        Difficulty.hard => const [_ld, _gd, _eq],
        _ => const [],
      };

  TargetClashRuntimeState resolve({
    PresentationAnswer? answer,
    required Difficulty difficulty,
    TargetClashStageResult? nextStage,
  }) {
    final question = currentQuestion;
    if (question == null) return this;
    final correct = answer == question.correctAnswer;
    final perfect = correct &&
        question.zone == TargetZone.bullseye &&
        question.correctAnswer == PresentationAnswer.equalTo &&
        answer == PresentationAnswer.equalTo;
    final nextCombo = correct ? combo + 1 : 0;
    final multiplier = correct ? (1 + ((nextCombo - 1) ~/ 3)).clamp(1, 3) : 1;
    final feverActive = isFeverActive;
    final armed = powerShotAppliedQuestionIndex == stageQuestionIndex;
    final gained = correct
        ? (10 + (perfect ? 10 : 0) + (armed ? 20 : 0)) *
            multiplier *
            (feverActive ? 2 : 1)
        : 0;
    final base = _copy(
      score: score + gained,
      correctCount: correctCount + (correct ? 1 : 0),
      resolvedCount: resolvedCount + 1,
      combo: nextCombo,
      bestCombo: nextCombo > bestCombo ? nextCombo : bestCombo,
      perfectHits: perfectHits + (perfect ? 1 : 0),
      clashPower: correct
          ? (clashPower + 1 + (perfect ? 1 : 0)).clamp(0, 6)
          : clashPower,
      feverRemaining: feverActive ? feverRemaining - 1 : feverRemaining,
      powerShotAppliedQuestionIndex:
          armed ? null : powerShotAppliedQuestionIndex,
      tripleCorrectCount: phase == TargetClashPhase.triple && correct
          ? tripleCorrectCount + 1
          : tripleCorrectCount,
      bossHealth: phase == TargetClashPhase.boss && correct
          ? bossHealth - (perfect ? 2 : 1)
          : bossHealth,
      bossQuestionsResolved: phase == TargetClashPhase.boss
          ? bossQuestionsResolved + 1
          : bossQuestionsResolved,
      finalCorrect: phase == TargetClashPhase.finalTarget && correct
          ? finalCorrect + 1
          : finalCorrect,
      finalResolved: phase == TargetClashPhase.finalTarget
          ? finalResolved + 1
          : finalResolved,
    );
    if (base.phase == TargetClashPhase.finalTarget && base.finalResolved == 3) {
      return base._copy(
          phase: TargetClashPhase.finished,
          preparedStage: null,
          stageQuestionIndex: 0,
          clearStage: true);
    }
    if (base.phase == TargetClashPhase.boss && base.bossHealth <= 0) {
      return base._advance(difficulty, nextStage, defeatedBoss: true);
    }
    if (base.phase == TargetClashPhase.boss &&
        base.bossQuestionsResolved >= _bossCap(difficulty)) {
      return base._advance(difficulty, nextStage);
    }
    if (base.stageQuestionIndex + 1 < base.preparedStage!.questions.length) {
      return base._copy(stageQuestionIndex: base.stageQuestionIndex + 1);
    }
    return base._advance(difficulty, nextStage);
  }

  TargetClashPowerShotResult activatePowerShot({
    required TargetClashRunConfig config,
    required TargetClashQuestionGenerator generator,
  }) {
    final question = currentQuestion;
    if (question == null || !isPowerShotReady || isTriple) {
      return TargetClashPowerShotResult(
          this, TargetClashPowerShotOutcome.denied);
    }
    if (question.zone == TargetZone.danger) {
      return TargetClashPowerShotResult(
          _copy(
              clashPower: 0, powerShotAppliedQuestionIndex: stageQuestionIndex),
          TargetClashPowerShotOutcome.applied);
    }
    for (final request in const [_gd, _gc]) {
      final replacement = generator
          .materializeForTarget(
            operation: config.operation,
            difficulty: config.difficulty,
            numberType: config.numberType,
            targetValue: question.targetValue,
            request: request,
          )
          .question;
      if (replacement == null) continue;
      final stage = preparedStage!.replacingQuestion(
          index: stageQuestionIndex, replacement: replacement)!;
      return TargetClashPowerShotResult(
          _copy(
              preparedStage: stage,
              clashPower: 0,
              powerShotAppliedQuestionIndex: stageQuestionIndex),
          TargetClashPowerShotOutcome.applied);
    }
    return TargetClashPowerShotResult(
        this, TargetClashPowerShotOutcome.unavailable);
  }

  TargetClashRuntimeState hardenForFever({
    required TargetClashRunConfig config,
    required TargetClashQuestionGenerator generator,
  }) {
    final question = currentQuestion;
    if (!isFeverActive ||
        question == null ||
        question.zone == TargetZone.danger ||
        question.zone == TargetZone.bullseye ||
        powerShotAppliedQuestionIndex == stageQuestionIndex) return this;
    final requests = question.correctAnswer == PresentationAnswer.lessThan
        ? const [_ld, _lc]
        : const [_gd, _gc];
    for (final request in requests) {
      final replacement = generator
          .materializeForTarget(
            operation: config.operation,
            difficulty: config.difficulty,
            numberType: config.numberType,
            targetValue: question.targetValue,
            request: request,
          )
          .question;
      if (replacement != null) {
        return _copy(
            preparedStage: preparedStage!.replacingQuestion(
                index: stageQuestionIndex, replacement: replacement));
      }
    }
    return this;
  }

  TargetClashRuntimeState _advance(
    Difficulty difficulty,
    TargetClashStageResult? nextStage, {
    bool defeatedBoss = false,
  }) {
    final nextPhase = switch (phase) {
      TargetClashPhase.ordinaryStage1 => TargetClashPhase.ordinaryStage2,
      TargetClashPhase.ordinaryStage2 => difficulty == Difficulty.easy
          ? TargetClashPhase.boss
          : TargetClashPhase.triple,
      TargetClashPhase.triple => TargetClashPhase.boss,
      TargetClashPhase.boss => TargetClashPhase.finalTarget,
      _ => phase,
    };
    final stage = nextStage?.stage;
    if (stage == null || stage.questions.isEmpty) {
      return _copy(
        phase: TargetClashPhase.technicalFailure,
        preparedStage: null,
        stageQuestionIndex: 0,
        generationFailure: nextStage?.failure ??
            (stage?.questions.isEmpty ?? false
                ? TargetClashGenerationFailure.invalidRequest
                : TargetClashGenerationFailure.slotGenerationFailed),
        clearStage: true,
      );
    }
    return _copy(
      phase: nextPhase,
      preparedStage: stage,
      stageQuestionIndex: 0,
      powerShotAppliedQuestionIndex: null,
      tripleClashesCompleted:
          phase == TargetClashPhase.triple && tripleCorrectCount == 3
              ? tripleClashesCompleted + 1
              : tripleClashesCompleted,
      feverRemaining: phase == TargetClashPhase.triple &&
              tripleCorrectCount == 3 &&
              difficulty == Difficulty.hard
          ? 3
          : feverRemaining,
      bossHealth: nextPhase == TargetClashPhase.boss
          ? _bossCap(difficulty)
          : bossHealth,
      bossQuestionsResolved:
          nextPhase == TargetClashPhase.boss ? 0 : bossQuestionsResolved,
      bossesDefeated: defeatedBoss ? bossesDefeated + 1 : bossesDefeated,
    );
  }

  static int _bossCap(Difficulty difficulty) => switch (difficulty) {
        Difficulty.easy => 3,
        Difficulty.medium => 4,
        Difficulty.hard => 5,
        _ => 0,
      };

  TargetClashRuntimeState _copy({
    TargetClashPhase? phase,
    TargetClashStage? preparedStage,
    int? stageQuestionIndex,
    int? score,
    int? correctCount,
    int? resolvedCount,
    int? combo,
    int? bestCombo,
    int? perfectHits,
    int? clashPower,
    int? powerShotAppliedQuestionIndex,
    int? feverRemaining,
    int? tripleCorrectCount,
    int? tripleClashesCompleted,
    int? bossHealth,
    int? bossQuestionsResolved,
    int? bossesDefeated,
    int? finalCorrect,
    int? finalResolved,
    TargetClashGenerationFailure? generationFailure,
    bool clearStage = false,
  }) =>
      TargetClashRuntimeState._(
        phase: phase ?? this.phase,
        preparedStage: clearStage ? null : preparedStage ?? this.preparedStage,
        stageQuestionIndex: stageQuestionIndex ?? this.stageQuestionIndex,
        score: score ?? this.score,
        correctCount: correctCount ?? this.correctCount,
        resolvedCount: resolvedCount ?? this.resolvedCount,
        combo: combo ?? this.combo,
        bestCombo: bestCombo ?? this.bestCombo,
        perfectHits: perfectHits ?? this.perfectHits,
        clashPower: clashPower ?? this.clashPower,
        powerShotAppliedQuestionIndex: powerShotAppliedQuestionIndex,
        feverRemaining: feverRemaining ?? this.feverRemaining,
        tripleCorrectCount: tripleCorrectCount ?? this.tripleCorrectCount,
        tripleClashesCompleted:
            tripleClashesCompleted ?? this.tripleClashesCompleted,
        bossHealth: bossHealth ?? this.bossHealth,
        bossQuestionsResolved:
            bossQuestionsResolved ?? this.bossQuestionsResolved,
        bossesDefeated: bossesDefeated ?? this.bossesDefeated,
        finalCorrect: finalCorrect ?? this.finalCorrect,
        finalResolved: finalResolved ?? this.finalResolved,
        generationFailure: generationFailure ?? this.generationFailure,
      );
}

const _eq = TargetClashQuestionRequest(
    answer: PresentationAnswer.equalTo, zone: TargetZone.bullseye);
const _gd = TargetClashQuestionRequest(
    answer: PresentationAnswer.greaterThan, zone: TargetZone.danger);
const _ld = TargetClashQuestionRequest(
    answer: PresentationAnswer.lessThan, zone: TargetZone.danger);
const _gc = TargetClashQuestionRequest(
    answer: PresentationAnswer.greaterThan, zone: TargetZone.closeCall);
const _lc = TargetClashQuestionRequest(
    answer: PresentationAnswer.lessThan, zone: TargetZone.closeCall);
const _gn = TargetClashQuestionRequest(
    answer: PresentationAnswer.greaterThan, zone: TargetZone.normal);
const _ln = TargetClashQuestionRequest(
    answer: PresentationAnswer.lessThan, zone: TargetZone.normal);
