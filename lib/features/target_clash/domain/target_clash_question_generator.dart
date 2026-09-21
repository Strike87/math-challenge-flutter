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
}

final class TargetClashStage {
  TargetClashStage._(this.targetValue, List<TargetClashQuestion> questions)
      : questions = List.unmodifiable(questions);

  final num targetValue;
  final List<TargetClashQuestion> questions;

  TargetClashStage? replacingQuestion({
    required int index,
    required TargetClashQuestion replacement,
  }) {
    if (index < 0 ||
        index >= questions.length ||
        replacement.targetValue != targetValue) {
      return null;
    }
    final next = List<TargetClashQuestion>.of(questions);
    next[index] = replacement;
    return TargetClashStage._(targetValue, next);
  }
}

final class TargetClashStageResult {
  const TargetClashStageResult._success(TargetClashStage this.stage)
      : failure = null;
  const TargetClashStageResult._failure(
      TargetClashGenerationFailure this.failure)
      : stage = null;

  final TargetClashStage? stage;
  final TargetClashGenerationFailure? failure;
}

final class TargetClashQuestionResult {
  const TargetClashQuestionResult._success(TargetClashQuestion this.question)
      : failure = null;
  const TargetClashQuestionResult._failure(
      TargetClashGenerationFailure this.failure)
      : question = null;

  final TargetClashQuestion? question;
  final TargetClashGenerationFailure? failure;
}

final class TargetClashQuestionGenerator {
  TargetClashQuestionGenerator({QuestionGenerator? questionGenerator})
      : _questionGenerator = questionGenerator ?? QuestionGenerator();

  static const int maxAttempts = 8;
  final QuestionGenerator _questionGenerator;

  TargetClashStageResult prepareStage({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required List<TargetClashQuestionRequest> requests,
  }) {
    if (!TargetClashQuestion.supportsConfiguration(
      operation: operation,
      difficulty: difficulty,
      numberType: numberType,
    )) {
      return const TargetClashStageResult._failure(
        TargetClashGenerationFailure.unsupportedConfiguration,
      );
    }
    final orderedRequests = List<TargetClashQuestionRequest>.of(requests);
    if (orderedRequests.any((request) => !request.isValid)) {
      return const TargetClashStageResult._failure(
        TargetClashGenerationFailure.invalidRequest,
      );
    }

    TargetClashQuestion? anchorCandidate() {
      final fact = _questionGenerator
          .build(
            type: operation,
            diff: difficulty,
            numType: numberType,
          )
          .fact;
      if (fact == null ||
          !fact.isMathematicallyValid ||
          fact.representation != FactRepresentation.direct ||
          fact.operation != operation ||
          fact.difficulty != difficulty ||
          fact.numberType != numberType) {
        return null;
      }
      return TargetClashQuestion.tryCreate(
        expression: fact,
        targetValue: fact.result,
      );
    }

    TargetClashQuestion? anchor;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      anchor = anchorCandidate();
      if (anchor != null) break;
    }
    if (anchor == null) {
      return const TargetClashStageResult._failure(
        TargetClashGenerationFailure.anchorGenerationFailed,
      );
    }

    final questions = <TargetClashQuestion>[];
    for (final request in orderedRequests) {
      if (request.answer == PresentationAnswer.equalTo) {
        questions.add(anchor);
        continue;
      }
      TargetClashQuestion? selected;
      for (final result in _candidateResults(anchor, request)) {
        final fact = _questionGenerator
            .buildDirectForResult(
              type: operation,
              diff: difficulty,
              numType: numberType,
              result: result,
            )
            ?.fact;
        if (fact == null ||
            !fact.isMathematicallyValid ||
            fact.representation != FactRepresentation.direct ||
            fact.operation != operation ||
            fact.difficulty != difficulty ||
            fact.numberType != numberType) {
          continue;
        }
        final question = TargetClashQuestion.tryCreate(
          expression: fact,
          targetValue: anchor.targetValue,
        );
        if (question != null &&
            question.correctAnswer == request.answer &&
            question.zone == request.zone) {
          selected = question;
          break;
        }
      }
      if (selected == null) {
        return const TargetClashStageResult._failure(
          TargetClashGenerationFailure.slotGenerationFailed,
        );
      }
      questions.add(selected);
    }
    return TargetClashStageResult._success(
      TargetClashStage._(anchor.targetValue, questions),
    );
  }

  TargetClashStageResult prepareStageForTarget({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required num targetValue,
    required List<TargetClashQuestionRequest> requests,
  }) {
    if (!_supports(operation, difficulty, numberType)) {
      return const TargetClashStageResult._failure(
        TargetClashGenerationFailure.unsupportedConfiguration,
      );
    }
    final orderedRequests = List<TargetClashQuestionRequest>.of(requests);
    if (orderedRequests.isEmpty ||
        orderedRequests.any((request) => !request.isValid)) {
      return const TargetClashStageResult._failure(
        TargetClashGenerationFailure.invalidRequest,
      );
    }
    final questions = <TargetClashQuestion>[];
    for (final request in orderedRequests) {
      final result = materializeForTarget(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
        targetValue: targetValue,
        request: request,
      );
      if (result.question == null) {
        return TargetClashStageResult._failure(result.failure!);
      }
      questions.add(result.question!);
    }
    return TargetClashStageResult._success(
      TargetClashStage._(targetValue, questions),
    );
  }

  TargetClashQuestionResult materializeForTarget({
    required Operation operation,
    required Difficulty difficulty,
    required NumberType numberType,
    required num targetValue,
    required TargetClashQuestionRequest request,
  }) {
    if (!_supports(operation, difficulty, numberType)) {
      return const TargetClashQuestionResult._failure(
        TargetClashGenerationFailure.unsupportedConfiguration,
      );
    }
    if (!request.isValid) {
      return const TargetClashQuestionResult._failure(
        TargetClashGenerationFailure.invalidRequest,
      );
    }
    for (final result in _candidateResultsForTarget(
      targetValue: targetValue,
      difficulty: difficulty,
      numberType: numberType,
      request: request,
    )) {
      final fact = _questionGenerator
          .buildDirectForResult(
            type: operation,
            diff: difficulty,
            numType: numberType,
            result: result,
          )
          ?.fact;
      if (!_isCanonicalFact(fact, operation, difficulty, numberType)) continue;
      final question = TargetClashQuestion.tryCreate(
        expression: fact!,
        targetValue: targetValue,
      );
      if (question != null &&
          question.correctAnswer == request.answer &&
          question.zone == request.zone) {
        return TargetClashQuestionResult._success(question);
      }
    }
    return const TargetClashQuestionResult._failure(
      TargetClashGenerationFailure.slotGenerationFailed,
    );
  }

  bool _supports(
          Operation operation, Difficulty difficulty, NumberType numberType) =>
      TargetClashQuestion.supportsConfiguration(
        operation: operation,
        difficulty: difficulty,
        numberType: numberType,
      );

  bool _isCanonicalFact(
    MathFact? fact,
    Operation operation,
    Difficulty difficulty,
    NumberType numberType,
  ) =>
      fact != null &&
      fact.isMathematicallyValid &&
      fact.representation == FactRepresentation.direct &&
      fact.operation == operation &&
      fact.difficulty == difficulty &&
      fact.numberType == numberType;

  Iterable<num> _candidateResults(
    TargetClashQuestion anchor,
    TargetClashQuestionRequest request,
  ) sync* {
    final distances = switch (request.zone) {
      TargetZone.danger => const [1],
      TargetZone.closeCall => const [2, 3],
      TargetZone.normal => const [4, 5, 6],
      TargetZone.bullseye => const <int>[],
    };
    final direction = request.answer == PresentationAnswer.lessThan ? -1 : 1;
    if (anchor.expression.numberType == NumberType.rationals) {
      final places = anchor.expression.rationalDecimalPlaces ?? 1;
      var factor = 1;
      for (var place = 0; place < places; place++) {
        factor *= 10;
      }
      final targetTick = (anchor.targetValue * factor).round();
      for (final distance in distances) {
        yield (targetTick + direction * distance) / factor;
      }
      return;
    }
    for (final distance in distances) {
      yield anchor.targetValue + direction * distance;
    }
  }

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
      final direction = request.answer == PresentationAnswer.lessThan ? -1 : 1;
      for (final distance in distances) {
        yield (targetTick + direction * distance) / factor;
      }
      return;
    }
    final direction = request.answer == PresentationAnswer.lessThan ? -1 : 1;
    for (final distance in distances) {
      yield targetValue + direction * distance;
    }
  }
}
