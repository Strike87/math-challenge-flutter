import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_challenge/engine/game_state.dart';
import 'package:math_challenge/engine/question_generator.dart';
import 'package:math_challenge/models/enums.dart';
import 'package:math_challenge/models/player.dart';
import 'package:math_challenge/services/audio.dart';
import 'package:math_challenge/services/settings.dart';
import 'package:math_challenge/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ops = <Operation>[
  Operation.addition,
  Operation.subtraction,
  Operation.multiplication,
  Operation.division,
];

const _numberTypes = <NumberType>[
  NumberType.natural,
  NumberType.integers,
  NumberType.rationals,
];

const _additionRanges = <Difficulty, _IntRange>{
  Difficulty.easy: _IntRange(1, 10),
  Difficulty.medium: _IntRange(11, 49),
  Difficulty.hard: _IntRange(25, 99),
  Difficulty.expert: _IntRange(50, 199),
  Difficulty.insane: _IntRange(100, 499),
};

const _subtractionRanges = <Difficulty, _IntRange>{
  Difficulty.easy: _IntRange(1, 9),
  Difficulty.medium: _IntRange(5, 44),
  Difficulty.hard: _IntRange(15, 79),
  Difficulty.expert: _IntRange(50, 149),
  Difficulty.insane: _IntRange(100, 399),
};

const _multiplicationRanges = <Difficulty, _IntRange>{
  Difficulty.easy: _IntRange(2, 5),
  Difficulty.medium: _IntRange(2, 10),
  Difficulty.hard: _IntRange(3, 12),
  Difficulty.expert: _IntRange(11, 20),
  Difficulty.insane: _IntRange(15, 25),
};

const _divisionRanges = <Difficulty, _IntRange>{
  Difficulty.easy: _IntRange(2, 5),
  Difficulty.medium: _IntRange(2, 10),
  Difficulty.hard: _IntRange(3, 12),
  Difficulty.expert: _IntRange(11, 15),
  Difficulty.insane: _IntRange(12, 20),
};

const _rationalDecimalPlaces = <Difficulty, int>{
  Difficulty.easy: 1,
  Difficulty.medium: 1,
  Difficulty.hard: 2,
  Difficulty.expert: 2,
  Difficulty.insane: 3,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, null);
  });

  group('RT-009 question generation core', () {
    test('natural operation ranges match source for all five difficulties', () {
      var seed = 100;
      for (final diff in Difficulty.values) {
        for (final op in _ops) {
          final qgen = QuestionGenerator(rng: Random(seed++));
          for (var i = 0; i < 120; i++) {
            final q = qgen.build(
              type: op,
              diff: diff,
              numType: NumberType.natural,
            );

            expect(q.diff, diff);
            expect(q.numType, NumberType.natural);
            _expectNaturalSourceRange(q, op, diff);
            _expectChoicesAreValid(q);
          }
        }
      }
    });

    test('integer number type supports negative operands and answers', () {
      var seed = 900;
      for (final op in _ops) {
        final qgen = QuestionGenerator(rng: Random(seed++));
        var foundNegative = false;
        for (var i = 0; i < 500; i++) {
          final q = qgen.build(
            type: op,
            diff: Difficulty.medium,
            numType: NumberType.integers,
          );
          _expectChoicesAreValid(q);
          foundNegative = foundNegative || _containsNegative(q);
        }

        expect(
          foundNegative,
          isTrue,
          reason: '${op.name} should generate negative integer content',
        );
      }
    });

    test('rational transforms use source decimal precision by difficulty', () {
      var seed = 1200;
      for (final diff in Difficulty.values) {
        final expectedDp = _rationalDecimalPlaces[diff]!;
        for (final op in _ops) {
          final qgen = QuestionGenerator(rng: Random(seed++));
          var transformed = 0;
          for (var i = 0; i < 180; i++) {
            final q = qgen.build(
              type: op,
              diff: diff,
              numType: NumberType.rationals,
            );
            _expectChoicesAreValid(q);

            if (!q.key.startsWith('r')) continue;
            transformed++;
            expect(q.ratDP, expectedDp);
            _expectRoundedTo(q.ans, expectedDp);
            for (final choice in q.choices) {
              _expectRoundedTo(choice, expectedDp);
            }
            if (op == Operation.division) {
              _expectRationalDivisionKeyIsClean(q, expectedDp);
            }
          }

          expect(
            transformed,
            greaterThan(0),
            reason: '${op.name}/${diff.name} should produce rational questions',
          );
        }
      }
    });

    test('distractors are unique and answer positions are shuffled', () {
      final answerPositions = <int>{};
      var seed = 1700;

      for (final numType in _numberTypes) {
        for (final diff in Difficulty.values) {
          for (final op in _ops) {
            final qgen = QuestionGenerator(rng: Random(seed++));
            for (var i = 0; i < 35; i++) {
              final q = qgen.build(type: op, diff: diff, numType: numType);
              _expectChoicesAreValid(q);
              answerPositions.add(_answerIndex(q));
            }
          }
        }
      }

      expect(answerPositions.length, greaterThan(1));
    });

    test('mixed runtime selects only the original four operation set',
        () async {
      final state = await _makeState();
      final allowed = _ops.toSet();
      final seen = <Operation>{};

      for (var i = 0; i < 100; i++) {
        state.players = 1;
        state.mode = GameMode.standard;
        state.rt.challenge = Operation.mixed;
        state.startGame();
        seen.add(state.rt.q!.type);
        expect(allowed, contains(state.rt.q!.type));
        state.rt.timer?.cancel();
      }

      expect(seen.difference(allowed), isEmpty);
      expect(seen, isNot(contains(Operation.mixed)));
    });

    testWidgets('answer comparison uses epsilon tolerance', (tester) async {
      final state = await _makeState();
      state.players = 1;
      state.mode = GameMode.standard;
      state.rt.challenge = Operation.addition;
      state.questionCount = 1;
      state.startGame();

      final nearAnswer = state.rt.q!.ans + 5e-10;
      state.onAnswer(nearAnswer);
      await tester.pump(const Duration(milliseconds: 4000));
      state.rt.timer?.cancel();

      expect(state.p[1].correct, 1);
    });
  });
}

Future<GameState> _makeState() async {
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
  final settings = SettingsService()
    ..load(
      dark: false,
      sound: false,
      vibration: false,
      dyslexia: false,
      colorblind: false,
      lowPerf: true,
      reduceMotion: true,
      animSpeed: 1,
    );
  final state = GameState(settings: settings, audio: AudioService(settings));
  await state.load();
  addTearDown(state.dispose);
  return state;
}

void _expectNaturalSourceRange(
  Question q,
  Operation op,
  Difficulty diff,
) {
  switch (op) {
    case Operation.addition:
      _expectAdditionKey(q, _additionRanges[diff]!);
      break;
    case Operation.subtraction:
      _expectSubtractionKey(q, _subtractionRanges[diff]!);
      break;
    case Operation.multiplication:
      _expectMultiplicationKey(q, _multiplicationRanges[diff]!);
      break;
    case Operation.division:
      _expectDivisionKey(q, _divisionRanges[diff]!);
      break;
    case Operation.mixed:
    case Operation.master:
    case Operation.dailyBoss:
    case Operation.survival:
      fail('Unexpected generated operation: $op');
  }
}

void _expectAdditionKey(Question q, _IntRange range) {
  final direct = RegExp(r'^a(\d+)\+(\d+)$').firstMatch(q.key);
  if (direct != null) {
    final a = _intGroup(direct, 1);
    final b = _intGroup(direct, 2);
    _expectInRange(a, range, 'addition left operand');
    _expectInRange(b, range, 'addition right operand');
    expect(q.ans, a + b);
    return;
  }

  final missingLeft = RegExp(r'^a\?\+(\d+)=(\d+)$').firstMatch(q.key);
  if (missingLeft != null) {
    final b = _intGroup(missingLeft, 1);
    final sum = _intGroup(missingLeft, 2);
    final a = sum - b;
    _expectInRange(a, range, 'addition hidden left operand');
    _expectInRange(b, range, 'addition right operand');
    expect(q.ans, a);
    return;
  }

  final missingRight = RegExp(r'^a(\d+)\+\?=(\d+)$').firstMatch(q.key);
  if (missingRight != null) {
    final a = _intGroup(missingRight, 1);
    final sum = _intGroup(missingRight, 2);
    final b = sum - a;
    _expectInRange(a, range, 'addition left operand');
    _expectInRange(b, range, 'addition hidden right operand');
    expect(q.ans, b);
    return;
  }

  fail('Unexpected addition key: ${q.key}');
}

void _expectSubtractionKey(Question q, _IntRange range) {
  final direct = RegExp(r'^s(\d+)-(\d+)$').firstMatch(q.key);
  if (direct != null) {
    final a = _intGroup(direct, 1);
    final b = _intGroup(direct, 2);
    final result = a - b;
    _expectInRange(b, range, 'subtraction subtrahend');
    _expectInRange(result, range, 'subtraction result');
    expect(q.ans, result);
    return;
  }

  final missingLeft = RegExp(r'^s\?-(\d+)=(\d+)$').firstMatch(q.key);
  if (missingLeft != null) {
    final b = _intGroup(missingLeft, 1);
    final result = _intGroup(missingLeft, 2);
    final a = b + result;
    _expectInRange(b, range, 'subtraction subtrahend');
    _expectInRange(result, range, 'subtraction result');
    expect(q.ans, a);
    return;
  }

  final missingRight = RegExp(r'^s(\d+)-\?=(\d+)$').firstMatch(q.key);
  if (missingRight != null) {
    final a = _intGroup(missingRight, 1);
    final result = _intGroup(missingRight, 2);
    final b = a - result;
    _expectInRange(b, range, 'subtraction hidden subtrahend');
    _expectInRange(result, range, 'subtraction result');
    expect(q.ans, b);
    return;
  }

  fail('Unexpected subtraction key: ${q.key}');
}

void _expectMultiplicationKey(Question q, _IntRange range) {
  final direct = RegExp(r'^m(\d+)x(\d+)$').firstMatch(q.key);
  if (direct != null) {
    final a = _intGroup(direct, 1);
    final b = _intGroup(direct, 2);
    _expectInRange(a, range, 'multiplication left operand');
    _expectInRange(b, range, 'multiplication right operand');
    expect(q.ans, a * b);
    return;
  }

  final missingLeft = RegExp(r'^m\?x(\d+)=(\d+)$').firstMatch(q.key);
  if (missingLeft != null) {
    final b = _intGroup(missingLeft, 1);
    final product = _intGroup(missingLeft, 2);
    final a = product ~/ b;
    expect(product % b, 0);
    _expectInRange(a, range, 'multiplication hidden left operand');
    _expectInRange(b, range, 'multiplication right operand');
    expect(q.ans, a);
    return;
  }

  final missingRight = RegExp(r'^m(\d+)x\?=(\d+)$').firstMatch(q.key);
  if (missingRight != null) {
    final a = _intGroup(missingRight, 1);
    final product = _intGroup(missingRight, 2);
    final b = product ~/ a;
    expect(product % a, 0);
    _expectInRange(a, range, 'multiplication left operand');
    _expectInRange(b, range, 'multiplication hidden right operand');
    expect(q.ans, b);
    return;
  }

  fail('Unexpected multiplication key: ${q.key}');
}

void _expectDivisionKey(Question q, _IntRange range) {
  final direct = RegExp(r'^d(\d+)/(\d+)$').firstMatch(q.key);
  if (direct != null) {
    final dividend = _intGroup(direct, 1);
    final divisor = _intGroup(direct, 2);
    expect(dividend % divisor, 0);
    _expectInRange(divisor, range, 'division divisor');
    _expectInRange(q.ans, range, 'division quotient');
    expect(q.ans, dividend ~/ divisor);
    return;
  }

  final missingLeft = RegExp(r'^d\?/(\d+)=(\d+)$').firstMatch(q.key);
  if (missingLeft != null) {
    final divisor = _intGroup(missingLeft, 1);
    final quotient = _intGroup(missingLeft, 2);
    final dividend = divisor * quotient;
    _expectInRange(divisor, range, 'division divisor');
    _expectInRange(quotient, range, 'division quotient');
    expect(q.ans, dividend);
    return;
  }

  final missingRight = RegExp(r'^d(\d+)/\?=(\d+)$').firstMatch(q.key);
  if (missingRight != null) {
    final dividend = _intGroup(missingRight, 1);
    final quotient = _intGroup(missingRight, 2);
    final divisor = dividend ~/ quotient;
    expect(dividend % quotient, 0);
    _expectInRange(divisor, range, 'division hidden divisor');
    _expectInRange(quotient, range, 'division quotient');
    expect(q.ans, divisor);
    return;
  }

  fail('Unexpected division key: ${q.key}');
}

void _expectChoicesAreValid(Question q) {
  expect(q.ans.isFinite, isTrue);
  expect(q.ans.isNaN, isFalse);
  expect(q.choices.length, 4);
  expect(q.choices.toSet().length, 4);
  expect(
    q.choices.where((choice) => _sameAnswer(choice, q.ans)).length,
    1,
    reason: 'Choices must contain the correct answer exactly once',
  );
  for (final choice in q.choices) {
    expect(choice.isFinite, isTrue);
    expect(choice.isNaN, isFalse);
  }
}

void _expectRationalDivisionKeyIsClean(Question q, int decimalPlaces) {
  final match = RegExp(r'^rd([0-9.]+)/(\d+)$').firstMatch(q.key);
  expect(match, isNotNull, reason: 'Unexpected rational division key ${q.key}');
  final dividend = double.parse(match!.group(1)!);
  final divisor = int.parse(match.group(2)!);
  final expectedDividend = _roundTo(q.ans * divisor, decimalPlaces);
  expect((dividend - expectedDividend).abs(), lessThan(1e-9));
}

void _expectRoundedTo(num value, int decimalPlaces) {
  expect((value - _roundTo(value, decimalPlaces)).abs(), lessThan(1e-9));
}

double _roundTo(num value, int decimalPlaces) {
  return double.parse(value.toStringAsFixed(decimalPlaces));
}

bool _containsNegative(Question q) {
  return q.text.contains('(-') ||
      q.ans < 0 ||
      q.choices.any((choice) => choice < 0);
}

int _answerIndex(Question q) {
  return q.choices.indexWhere((choice) => _sameAnswer(choice, q.ans));
}

bool _sameAnswer(num a, num b) => (a - b).abs() < 1e-9;

int _intGroup(RegExpMatch match, int group) => int.parse(match.group(group)!);

void _expectInRange(num value, _IntRange range, String label) {
  expect(value, value.roundToDouble(), reason: '$label should be an integer');
  expect(value, inInclusiveRange(range.min, range.max), reason: label);
}

class _IntRange {
  const _IntRange(this.min, this.max);

  final int min;
  final int max;
}
