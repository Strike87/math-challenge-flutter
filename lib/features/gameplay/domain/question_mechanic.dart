import 'dart:math';

import '../../../models/enums.dart';
import '../../../models/player.dart';

enum QuestionMechanic { standard, missingOperation, missingNumber }

const operatorAnswerChoices = <int>[0, 1, 2, 3];

String operatorSymbol(num code) => switch (code) {
      0 => '+',
      1 => '−',
      2 => '×',
      3 => '÷',
      _ => throw StateError('Unknown Missing Operation answer code: $code'),
    };

Question? missingOperationQuestion(Question question, Random random) {
  const number = r'\(?[−-]?\d+(?:\.\d+)?\)?';
  final match = RegExp('^($number) ([+−×÷-]) ($number) = \\?\$')
      .firstMatch(question.text);
  if (match == null) return null;
  final leftText = match.group(1)!;
  final rightText = match.group(3)!;
  final left = _parseNumber(leftText);
  final right = _parseNumber(rightText);
  final symbol = match.group(2)!.replaceAll('-', '−');
  final expectedSymbol = switch (question.type) {
    Operation.addition => '+',
    Operation.subtraction => '−',
    Operation.multiplication => '×',
    Operation.division => '÷',
    _ => null,
  };
  if (symbol != expectedSymbol) return null;

  final valid = <Operation>[
    if (_equal(left + right, question.ans)) Operation.addition,
    if (_equal(left - right, question.ans)) Operation.subtraction,
    if (_equal(left * right, question.ans)) Operation.multiplication,
    if (!_equal(right, 0) && _equal(left / right, question.ans))
      Operation.division,
  ];
  if (valid.length != 1 || valid.single != question.type) return null;

  final code = switch (question.type) {
    Operation.addition => 0,
    Operation.subtraction => 1,
    Operation.multiplication => 2,
    Operation.division => 3,
    _ => throw StateError('Missing Operation requires a concrete operation.'),
  };
  final choices = List<num>.from(operatorAnswerChoices)..shuffle(random);
  return Question(
    type: question.type,
    key: '${question.key}:missing-operation',
    text: '$leftText ? $rightText = ${question.ans}',
    ans: code,
    choices: choices,
    boss: question.boss,
    diff: question.diff,
    numType: question.numType,
    ratDP: question.ratDP,
  );
}

num _parseNumber(String value) =>
    num.parse(value.replaceAll(RegExp(r'[()]'), '').replaceAll('−', '-'));

bool _equal(num left, num right) => (left - right).abs() < 1e-9;
