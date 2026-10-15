import 'dart:math';

import '../../../engine/question_generator.dart';
import '../../../models/enums.dart';
import '../../../models/math_fact.dart';
import 'presentation_answer.dart';
import 'target_clash_question.dart';

final class TargetClashQuestionRequest {
  const TargetClashQuestionRequest({required this.answer, required this.zone});
  final PresentationAnswer answer;
  final TargetZone zone;
  bool get isValid =>
      (answer == PresentationAnswer.equalTo) == (zone == TargetZone.bullseye);
}

enum TargetClashGenerationFailure {
  unsupportedConfiguration,
  invalidRequest,
  anchorGenerationFailed,
  slotGenerationFailed,
  canonicalDomainMaterializationMismatch,
}

final class TargetClashStage {
  TargetClashStage._(this.targetValue, List<TargetClashQuestion> questions)
      : questions = List.unmodifiable(questions);
  final num targetValue;
  final List<TargetClashQuestion> questions;
  TargetClashStage? replacingQuestion(
      {required int index, required TargetClashQuestion replacement}) {
    if (index < 0 ||
        index >= questions.length ||
        replacement.targetValue != targetValue) return null;
    final next = List<TargetClashQuestion>.of(questions)..[index] = replacement;
    return TargetClashStage._(targetValue, next);
  }
}

final class TargetClashStageResult {
  const TargetClashStageResult._success(TargetClashStage this.stage)
      : failure = null;
  const TargetClashStageResult._failure(this.failure) : stage = null;
  final TargetClashStage? stage;
  final TargetClashGenerationFailure? failure;
}

final class TargetClashQuestionResult {
  const TargetClashQuestionResult._success(TargetClashQuestion this.question)
      : failure = null;
  const TargetClashQuestionResult._failure(this.failure) : question = null;
  final TargetClashQuestion? question;
  final TargetClashGenerationFailure? failure;
}

/// Plans a complete Target Clash stage before materializing any question.
final class TargetClashQuestionGenerator {
  TargetClashQuestionGenerator(
      {QuestionGenerator? questionGenerator, Random? selectionRandom})
      : _questionGenerator = questionGenerator ?? QuestionGenerator(),
        _selectionRandom = selectionRandom ?? Random();

  final QuestionGenerator _questionGenerator;
  final Random _selectionRandom;

  TargetClashStageResult prepareStage({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required List<TargetClashQuestionRequest> requests,
    List<TargetClashQuestionRequest> futureRequests = const [],
  }) {
    if (!_supports(operation, difficulty, numberType)) return _unsupported;
    if (!_validRequests(requests) ||
        !_validRequests(futureRequests, allowEmpty: true)) return _invalid;
    final domain = _questionGenerator.canonicalDirectResultDomain(
        type: operation, diff: difficulty, numType: numberType);
    if (domain.isEmpty) return _anchorFailed;
    final domainSet = domain.toSet();
    final requested = [...requests, ...futureRequests];
    final feasible = domain
        .where((target) =>
            _isFeasible(target, requested, domainSet, difficulty, numberType))
        .toList(growable: false);
    if (feasible.isEmpty) return _anchorFailed;
    final target = feasible.length == 1
        ? feasible.single
        : feasible[_selectionRandom.nextInt(feasible.length)];
    return _materializeStage(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        targetValue: target,
        requests: requests,
        domain: domainSet);
  }

  TargetClashStageResult prepareStageForTarget({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required num targetValue,
    required List<TargetClashQuestionRequest> requests,
  }) {
    if (!_supports(operation, difficulty, numberType)) return _unsupported;
    if (!_validRequests(requests)) return _invalid;
    final domain = _questionGenerator
        .canonicalDirectResultDomain(
            type: operation, diff: difficulty, numType: numberType)
        .toSet();
    if (!domain.contains(targetValue) ||
        !_isFeasible(targetValue, requests, domain, difficulty, numberType))
      return _slotFailed;
    return _materializeStage(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        targetValue: targetValue,
        requests: requests,
        domain: domain);
  }

  TargetClashQuestionResult materializeForTarget({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required num targetValue,
    required TargetClashQuestionRequest request,
  }) {
    final stage = prepareStageForTarget(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        targetValue: targetValue,
        requests: [request]);
    return stage.stage == null
        ? TargetClashQuestionResult._failure(stage.failure!)
        : TargetClashQuestionResult._success(stage.stage!.questions.single);
  }

  TargetClashStageResult _materializeStage({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required num targetValue,
    required List<TargetClashQuestionRequest> requests,
    required Set<num> domain,
  }) {
    final questions = <TargetClashQuestion>[];
    for (final request in requests) {
      TargetClashQuestion? selected;
      for (final result in _candidateResultsForTarget(
              targetValue: targetValue,
              difficulty: difficulty,
              numberType: numberType,
              request: request)
          .where(domain.contains)) {
        final fact = _questionGenerator
            .buildDirectForResult(
                type: operation,
                diff: difficulty,
                numType: numberType,
                result: result)
            ?.fact;
        if (!_isCanonicalFact(fact, operation, difficulty, numberType) ||
            fact!.result != result) {
          return const TargetClashStageResult._failure(
              TargetClashGenerationFailure
                  .canonicalDomainMaterializationMismatch);
        }
        final question = TargetClashQuestion.tryCreate(
            expression: fact, targetValue: targetValue);
        if (question != null &&
            question.correctAnswer == request.answer &&
            question.zone == request.zone) {
          selected = question;
          break;
        }
      }
      if (selected == null) return _slotFailed;
      questions.add(selected);
    }
    return TargetClashStageResult._success(
        TargetClashStage._(targetValue, questions));
  }

  bool _isFeasible(num target, List<TargetClashQuestionRequest> requests,
          Set<num> domain, Difficulty difficulty, NumberType numberType) =>
      requests.every((request) => _candidateResultsForTarget(
              targetValue: target,
              difficulty: difficulty,
              numberType: numberType,
              request: request)
          .any(domain.contains));

  bool _validRequests(List<TargetClashQuestionRequest> requests,
          {bool allowEmpty = false}) =>
      (allowEmpty || requests.isNotEmpty) &&
      requests.every((request) => request.isValid);

  bool _supports(
          Operation operation, Difficulty difficulty, NumberType numberType) =>
      TargetClashQuestion.supportsConfiguration(
          operation: operation, difficulty: difficulty, numberType: numberType);

  bool _isCanonicalFact(MathFact? fact, Operation operation,
          Difficulty difficulty, NumberType numberType) =>
      fact != null &&
      fact.isMathematicallyValid &&
      fact.representation == FactRepresentation.direct &&
      fact.operation == operation &&
      fact.difficulty == difficulty &&
      fact.numberType == numberType;

  Iterable<num> _candidateResultsForTarget({
    required num targetValue,
    required Difficulty difficulty,
    required NumberType numberType,
    required TargetClashQuestionRequest request,
  }) sync* {
    final distances = switch (request.zone) {
      TargetZone.danger => const [1],
      TargetZone.closeCall => const [2, 3],
      TargetZone.normal => const [4, 5, 6],
      TargetZone.bullseye => const [0],
    };
    final direction = request.answer == PresentationAnswer.lessThan ? -1 : 1;
    if (numberType == NumberType.rationals) {
      final places = switch (difficulty) {
        Difficulty.easy || Difficulty.medium => 1,
        Difficulty.hard => 2,
        _ => 0,
      };
      var factor = 1;
      for (var place = 0; place < places; place++) {
        factor *= 10;
      }
      final targetTick = (targetValue * factor).round();
      for (final distance in distances) {
        yield (targetTick + direction * distance) / factor;
      }
      return;
    }
    for (final distance in distances) {
      yield targetValue + direction * distance;
    }
  }

  static const _unsupported = TargetClashStageResult._failure(
      TargetClashGenerationFailure.unsupportedConfiguration);
  static const _invalid = TargetClashStageResult._failure(
      TargetClashGenerationFailure.invalidRequest);
  static const _anchorFailed = TargetClashStageResult._failure(
      TargetClashGenerationFailure.anchorGenerationFailed);
  static const _slotFailed = TargetClashStageResult._failure(
      TargetClashGenerationFailure.slotGenerationFailed);
}
