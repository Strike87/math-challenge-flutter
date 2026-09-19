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
}
