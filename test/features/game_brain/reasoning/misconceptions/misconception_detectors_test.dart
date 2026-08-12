import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/features/game_brain/domain/brain_observation.dart';
import 'package:math_challenge/features/game_brain/domain/misconception_evidence.dart';
import 'package:math_challenge/features/game_brain/reasoning/misconceptions/composite_misconception_detector.dart';
import 'package:math_challenge/features/game_brain/reasoning/misconceptions/division_inverse_detector.dart';
import 'package:math_challenge/features/game_brain/reasoning/misconceptions/misconception_detector.dart';
import 'package:math_challenge/features/game_brain/reasoning/misconceptions/multiplication_fact_detector.dart';
import 'package:math_challenge/features/game_brain/reasoning/misconceptions/operation_substitution_detector.dart';
import 'package:math_challenge/features/game_brain/reasoning/misconceptions/sign_rule_detector.dart';
import 'package:math_challenge/models/enums.dart';

void main() {
  BrainObservation observation({
    required Operation operation,
    required num correctAnswer,
    String? submittedAnswer,
    num? leftOperand,
    num? rightOperand,
    bool correct = false,
    bool timedOut = false,
    NumberType numberType = NumberType.natural,
  }) =>
      BrainObservation(
        operation: operation,
        difficulty: Difficulty.easy,
        numberType: numberType,
        correctAnswer: '$correctAnswer',
        submittedAnswer: submittedAnswer,
        correct: correct,
        timedOut: timedOut,
        responseTimeMs: 800,
        masteryBefore: 20,
        masteryAfter: 20,
        leftOperand: leftOperand,
        rightOperand: rightOperand,
      );

  group('SignRuleDetector', () {
    const detector = SignRuleDetector();

    test('recognizes positive correct and negative submitted answers', () {
      final result = detector.detect(
        observation(
          operation: Operation.addition,
          correctAnswer: 32,
          submittedAnswer: '-32',
        ),
      );

      expect(result?.type, MisconceptionType.signRule);
      expect(result?.reason, MisconceptionReason.oppositeSignSameMagnitude);
      expect(result?.confidence, 0.95);
    });

    test('recognizes negative correct and positive submitted answers', () {
      expect(
        detector
            .detect(
              observation(
                operation: Operation.subtraction,
                correctAnswer: -32,
                submittedAnswer: '32',
              ),
            )
            ?.type,
        MisconceptionType.signRule,
      );
    });

    test('rejects same-sign wrong magnitudes, zero, and correct answers', () {
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 32,
            submittedAnswer: '31',
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 0,
            submittedAnswer: '-0',
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 32,
            submittedAnswer: '32',
            correct: true,
          ),
        ),
        isNull,
      );
    });

    test('rejects a timeout or omitted submitted answer', () {
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 32,
            submittedAnswer: '-32',
            timedOut: true,
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 32,
          ),
        ),
        isNull,
      );
    });
  });

  group('OperationSubstitutionDetector', () {
    const detector = OperationSubstitutionDetector();

    test('recognizes multiplication answered as addition', () {
      final result = detector.detect(
        observation(
          operation: Operation.multiplication,
          leftOperand: 7,
          rightOperand: 4,
          correctAnswer: 28,
          submittedAnswer: '11',
        ),
      );

      expect(result?.type, MisconceptionType.operationSubstitution);
      expect(result?.tag, 'operation-substitution:addition');
    });

    test(
        'recognizes unambiguous addition, subtraction, and division alternatives',
        () {
      expect(
        detector
            .detect(
              observation(
                operation: Operation.addition,
                leftOperand: 2,
                rightOperand: 3,
                correctAnswer: 5,
                submittedAnswer: '6',
              ),
            )
            ?.tag,
        'operation-substitution:multiplication',
      );
      expect(
        detector
            .detect(
              observation(
                operation: Operation.subtraction,
                leftOperand: 7,
                rightOperand: 4,
                correctAnswer: 3,
                submittedAnswer: '1.75',
              ),
            )
            ?.tag,
        'operation-substitution:division',
      );
      expect(
        detector
            .detect(
              observation(
                operation: Operation.division,
                leftOperand: 8,
                rightOperand: 2,
                correctAnswer: 4,
                submittedAnswer: '10',
              ),
            )
            ?.tag,
        'operation-substitution:addition',
      );
    });

    test('rejects correct, equivalent, and ambiguous alternatives', () {
      expect(
        detector.detect(
          observation(
            operation: Operation.multiplication,
            leftOperand: 7,
            rightOperand: 4,
            correctAnswer: 28,
            submittedAnswer: '28',
            correct: true,
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            leftOperand: 5,
            rightOperand: 0,
            correctAnswer: 5,
            submittedAnswer: '5',
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.subtraction,
            leftOperand: 2,
            rightOperand: 2,
            correctAnswer: 0,
            submittedAnswer: '4',
          ),
        ),
        isNull,
      );
    });
  });

  group('MultiplicationFactDetector', () {
    const detector = MultiplicationFactDetector();

    test('recognizes one adjacent natural multiplication fact', () {
      final result = detector.detect(
        observation(
          operation: Operation.multiplication,
          leftOperand: 6,
          rightOperand: 7,
          correctAnswer: 42,
          submittedAnswer: '36',
        ),
      );

      expect(result?.type, MisconceptionType.multiplicationFact);
      expect(result?.reason, MisconceptionReason.adjacentMultiplicationFactor);
      expect(result?.confidence, 0.75);
    });

    test('rejects unrelated, non-multiplication, and ambiguous facts', () {
      expect(
        detector.detect(
          observation(
            operation: Operation.multiplication,
            leftOperand: 6,
            rightOperand: 7,
            correctAnswer: 42,
            submittedAnswer: '40',
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.addition,
            leftOperand: 6,
            rightOperand: 7,
            correctAnswer: 13,
            submittedAnswer: '36',
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.multiplication,
            leftOperand: 6,
            rightOperand: 6,
            correctAnswer: 36,
            submittedAnswer: '30',
          ),
        ),
        isNull,
      );
    });
  });

  group('DivisionInverseDetector', () {
    const detector = DivisionInverseDetector();

    test('recognizes exact reversed nonzero division operands', () {
      final result = detector.detect(
        observation(
          operation: Operation.division,
          leftOperand: 8,
          rightOperand: 2,
          correctAnswer: 4,
          submittedAnswer: '0.25',
        ),
      );

      expect(result?.type, MisconceptionType.divisionInverse);
      expect(result?.reason, MisconceptionReason.reversedDivisionOperands);
    });

    test('rejects correct, zero-divisor, and unrelated answers', () {
      expect(
        detector.detect(
          observation(
            operation: Operation.division,
            leftOperand: 8,
            rightOperand: 2,
            correctAnswer: 4,
            submittedAnswer: '4',
            correct: true,
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.division,
            leftOperand: 8,
            rightOperand: 0,
            correctAnswer: 0,
            submittedAnswer: '0',
          ),
        ),
        isNull,
      );
      expect(
        detector.detect(
          observation(
            operation: Operation.division,
            leftOperand: 8,
            rightOperand: 2,
            correctAnswer: 4,
            submittedAnswer: '3',
          ),
        ),
        isNull,
      );
    });
  });

  group('CompositeMisconceptionDetector', () {
    test('returns one clear match and is repeatable', () {
      final detector = CompositeMisconceptionDetector();
      final input = observation(
        operation: Operation.multiplication,
        leftOperand: 7,
        rightOperand: 4,
        correctAnswer: 28,
        submittedAnswer: '11',
      );

      expect(detector.detect(input)?.tag, 'operation-substitution:addition');
      expect(detector.detect(input)?.tag, 'operation-substitution:addition');
    });

    test('returns null for no match or multiple matches', () {
      final noMatch = CompositeMisconceptionDetector();
      expect(
        noMatch.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 4,
            submittedAnswer: '3',
          ),
        ),
        isNull,
      );
      final ambiguous = CompositeMisconceptionDetector(
        detectors: const [
          _EvidenceDetector('first'),
          _EvidenceDetector('second')
        ],
      );
      expect(
        ambiguous.detect(
          observation(
            operation: Operation.addition,
            correctAnswer: 4,
            submittedAnswer: '3',
          ),
        ),
        isNull,
      );
    });
  });
}

final class _EvidenceDetector implements MisconceptionDetector {
  const _EvidenceDetector(this.tag);

  final String tag;

  @override
  MisconceptionEvidence detect(BrainObservation observation) =>
      MisconceptionEvidence(tag: tag);
}
