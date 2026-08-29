import 'dart:math';
import '../models/enums.dart';
import '../models/math_fact.dart';
import '../models/player.dart';

/// Random question generator.
///
/// Mirrors the original HTML game's `_buildQ`, `_applyNumType`, and
/// `_generateQCore` logic, adapted to Dart.
class QuestionGenerator {
  QuestionGenerator({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  /// Build a question for the given operation + difficulty + numType.
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
    bool integerQuest = false,
    bool decimalQuest = false,
  }) {
    var q = integerQuest
        ? _buildIntegerQuest(type, diff)
        : decimalQuest
            ? _buildDecimalQuest(type, diff)
            : _applyNumType(_buildBase(type, diff), type, diff, numType);
    final fact = q.fact.copyWith(
      difficulty: diff,
      numberType: numType,
      rationalDecimalPlaces: q.ratDP,
      allowsRelatedMissingRepresentations:
          numType == NumberType.natural || !q.numberTypeTransformed,
    );
    final choices = _buildChoices(q, numType);
    return Question(
      type: q.type,
      key: q.key,
      text: q.text,
      ans: q.ans,
      choices: choices,
      diff: diff,
      numType: numType,
      ratDP: q.ratDP,
      fact: fact,
    );
  }

  /// Builds a different, legal representation of a generator-created fact.
  ///
  /// [allowedOperations] contains effective basic operations. Supplying both
  /// members of an inverse pair permits that pair; a single-operation scope
  /// cannot escape to its inverse.
  Question? buildRelated({
    required MathFact fact,
    required Difficulty diff,
    required NumberType numType,
    required Set<Operation> allowedOperations,
    Set<FactRepresentation> excludedRepresentations = const {},
  }) {
    if (fact.difficulty != diff ||
        fact.numberType != numType ||
        !fact.isMathematicallyValid ||
        !allowedOperations.contains(fact.operation)) {
      return null;
    }

    final candidates = <MathFact>[];
    void add(MathFact candidate) {
      if (_representationAllowed(candidate.representation, diff) &&
          (candidate.representation == FactRepresentation.direct ||
              fact.allowsRelatedMissingRepresentations) &&
          !excludedRepresentations.contains(candidate.representation) &&
          !_sameRenderedForm(candidate, fact) &&
          candidate.isMathematicallyValid &&
          _isWithinCanonicalRange(candidate)) {
        candidates.add(candidate);
      }
    }

    void same(Operation operation, num left, num right, num result,
        FactRepresentation representation) {
      if (allowedOperations.contains(operation)) {
        add(MathFact(
          operation: operation,
          left: left,
          right: right,
          result: result,
          representation: representation,
          difficulty: diff,
          numberType: numType,
          rationalDecimalPlaces: fact.rationalDecimalPlaces,
          allowsRelatedMissingRepresentations:
              fact.allowsRelatedMissingRepresentations,
        ));
      }
    }

    same(fact.operation, fact.left, fact.right, fact.result,
        FactRepresentation.direct);
    same(fact.operation, fact.left, fact.right, fact.result,
        FactRepresentation.missingLeft);
    same(fact.operation, fact.left, fact.right, fact.result,
        FactRepresentation.missingRight);
    if (fact.operation == Operation.addition ||
        fact.operation == Operation.multiplication) {
      same(fact.operation, fact.right, fact.left, fact.result,
          FactRepresentation.direct);
      same(fact.operation, fact.right, fact.left, fact.result,
          FactRepresentation.missingLeft);
      same(fact.operation, fact.right, fact.left, fact.result,
          FactRepresentation.missingRight);
    }

    final inverse = _inverseOperation(fact.operation);
    if (inverse != null && allowedOperations.contains(inverse)) {
      switch (fact.operation) {
        case Operation.addition:
          same(inverse, fact.result, fact.right, fact.left,
              FactRepresentation.direct);
          same(inverse, fact.result, fact.left, fact.right,
              FactRepresentation.direct);
        case Operation.subtraction:
          same(inverse, fact.result, fact.right, fact.left,
              FactRepresentation.direct);
          same(inverse, fact.right, fact.result, fact.left,
              FactRepresentation.direct);
        case Operation.multiplication:
          if (fact.left != 0 && fact.right != 0) {
            same(inverse, fact.result, fact.right, fact.left,
                FactRepresentation.direct);
            same(inverse, fact.result, fact.left, fact.right,
                FactRepresentation.direct);
          }
        case Operation.division:
          same(inverse, fact.result, fact.right, fact.left,
              FactRepresentation.direct);
          same(inverse, fact.right, fact.result, fact.left,
              FactRepresentation.direct);
        default:
          break;
      }
    }

    if (candidates.isEmpty) return null;
    return _renderFact(candidates[_rng.nextInt(candidates.length)]);
  }

  _QBase _buildDecimalQuest(Operation type, Difficulty diff) {
    final decimalPlaces = diff == Difficulty.hard ? 2 : 1;
    final factor = pow(10, decimalPlaces).toInt();
    double decimal(int minWhole, int maxWhole) => double.parse(
        (_randInt(minWhole * factor + 1, (maxWhole + 1) * factor - 1) / factor)
            .toStringAsFixed(decimalPlaces));
    double quantize(num value) =>
        double.parse(value.toStringAsFixed(decimalPlaces));

    switch (type) {
      case Operation.addition:
        final a = decimal(1, 15);
        final b = decimal(1, 15);
        return _QBase(
          type: type,
          key: 'dqa$a+$b',
          text: '$a + $b = ?',
          ans: quantize(a + b),
          ratDP: decimalPlaces,
          fact: _fact(type, a, b, quantize(a + b), FactRepresentation.direct),
        );
      case Operation.subtraction:
        final b = decimal(1, 15);
        final result = decimal(1, 8);
        final a = quantize(b + result);
        return _QBase(
          type: type,
          key: 'dqs$a-$b',
          text: '$a − $b = ?',
          ans: result,
          ratDP: decimalPlaces,
          fact: _fact(type, a, b, result, FactRepresentation.direct),
        );
      case Operation.multiplication:
        final a = decimal(1, 15);
        final b = _randInt(2, 9);
        return _QBase(
          type: type,
          key: 'dqm${a}x$b',
          text: '$a × $b = ?',
          ans: quantize(a * b),
          ratDP: decimalPlaces,
          fact: _fact(type, a, b, quantize(a * b), FactRepresentation.direct),
        );
      case Operation.division:
        final b = _randInt(2, 9);
        final result = decimal(1, 15);
        final a = quantize(b * result);
        return _QBase(
          type: type,
          key: 'dqd$a/$b',
          text: '$a ÷ $b = ?',
          ans: result,
          ratDP: decimalPlaces,
          fact: _fact(type, a, b, result, FactRepresentation.direct),
        );
      default:
        throw ArgumentError.value(
            type, 'type', 'Decimal Quest needs a basic operation.');
    }
  }

  _QBase _buildIntegerQuest(Operation type, Difficulty diff) {
    int magnitude(int easyMin, int easyMax, int hardMin, int hardMax) =>
        _randInt(
          diff == Difficulty.hard ? hardMin : easyMin,
          diff == Difficulty.hard ? hardMax : easyMax,
        );
    int signed(int value) => _rng.nextBool() ? -value : value;
    String wrap(int value) => value < 0 ? '($value)' : '$value';

    switch (type) {
      case Operation.addition:
        final a = signed(magnitude(1, 10, 25, 99));
        final b = signed(magnitude(1, 10, 25, 99));
        return _QBase(
          type: type,
          key: 'qi+$a+$b',
          text: '${wrap(a)} + ${wrap(b)} = ?',
          ans: a + b,
          fact: _fact(type, a, b, a + b, FactRepresentation.direct),
        );
      case Operation.subtraction:
        final a = signed(magnitude(1, 9, 15, 79));
        final b = signed(magnitude(1, 9, 15, 79));
        return _QBase(
          type: type,
          key: 'qi-$a-$b',
          text: '${wrap(a)} − ${wrap(b)} = ?',
          ans: a - b,
          fact: _fact(type, a, b, a - b, FactRepresentation.direct),
        );
      case Operation.multiplication:
        final a = signed(magnitude(2, 10, 3, 12));
        final b = signed(magnitude(2, 10, 3, 12));
        return _QBase(
          type: type,
          key: 'qix${a}x$b',
          text: '${wrap(a)} × ${wrap(b)} = ?',
          ans: a * b,
          fact: _fact(type, a, b, a * b, FactRepresentation.direct),
        );
      case Operation.division:
        final divisor = signed(magnitude(2, 10, 3, 12));
        final quotient = signed(magnitude(2, 10, 3, 12));
        final dividend = divisor * quotient;
        return _QBase(
          type: type,
          key: 'qid$dividend/$divisor',
          text: '${wrap(dividend)} ÷ ${wrap(divisor)} = ?',
          ans: quotient,
          fact: _fact(
              type, dividend, divisor, quotient, FactRepresentation.direct),
        );
      default:
        throw ArgumentError.value(
            type, 'type', 'Integer Quest needs a basic operation.');
    }
  }

  // ─── Base builder ───────────────────────────────────────────
  _QBase _buildBase(Operation type, Difficulty diff) {
    int a, b;
    num ans;
    String key, text;
    final r = _rng;
    int randInt(int min, int max) => min + r.nextInt(max - min + 1);

    if (type == Operation.addition) {
      switch (diff) {
        case Difficulty.easy:
          a = randInt(1, 10);
          b = randInt(1, 10);
          break;
        case Difficulty.medium:
          a = randInt(11, 49);
          b = randInt(11, 49);
          break;
        case Difficulty.hard:
          a = randInt(25, 99);
          b = randInt(25, 99);
          break;
        case Difficulty.expert:
          a = randInt(50, 199);
          b = randInt(50, 199);
          break;
        case Difficulty.insane:
          a = randInt(100, 499);
          b = randInt(100, 499);
          break;
      }
      final missing = diff == Difficulty.easy ? 3 : randInt(1, 3);
      if (missing == 3) {
        key = 'a${min(a, b)}+${max(a, b)}';
        text = '$a + $b = ?';
        ans = a + b;
      } else if (missing == 1) {
        key = 'a?+$b=${a + b}';
        text = '? + $b = ${a + b}';
        ans = a;
      } else {
        key = 'a$a+?=${a + b}';
        text = '$a + ? = ${a + b}';
        ans = b;
      }
      return _QBase(
        type: type,
        key: key,
        text: text,
        ans: ans,
        fact: _fact(
          type,
          a,
          b,
          a + b,
          _representationForMissing(missing),
        ),
      );
    }

    if (type == Operation.subtraction) {
      switch (diff) {
        case Difficulty.easy:
          b = randInt(1, 9);
          ans = randInt(1, 9);
          break;
        case Difficulty.medium:
          b = randInt(5, 44);
          ans = randInt(5, 44);
          break;
        case Difficulty.hard:
          b = randInt(15, 79);
          ans = randInt(15, 79);
          break;
        case Difficulty.expert:
          b = randInt(50, 149);
          ans = randInt(50, 149);
          break;
        case Difficulty.insane:
          b = randInt(100, 399);
          ans = randInt(100, 399);
          break;
      }
      a = b + ans as int;
      final result = a - b;
      final missing = diff == Difficulty.easy ? 3 : randInt(1, 3);
      if (missing == 3) {
        key = 's$a-$b';
        text = '$a - $b = ?';
        ans = result;
      } else if (missing == 1) {
        key = 's?-$b=$result';
        text = '? - $b = $result';
        ans = a;
      } else {
        key = 's$a-?=$result';
        text = '$a - ? = $result';
        ans = b;
      }
      return _QBase(
        type: type,
        key: key,
        text: text,
        ans: ans,
        fact: _fact(type, a, b, result, _representationForMissing(missing)),
      );
    }

    if (type == Operation.multiplication) {
      late int mA, mB;
      switch (diff) {
        case Difficulty.easy:
          mA = randInt(2, 5);
          mB = randInt(2, 5);
          break;
        case Difficulty.medium:
          mA = randInt(2, 10);
          mB = randInt(2, 10);
          break;
        case Difficulty.hard:
          mA = randInt(3, 12);
          mB = randInt(3, 12);
          break;
        case Difficulty.expert:
          mA = randInt(11, 20);
          mB = randInt(11, 20);
          break;
        case Difficulty.insane:
          mA = randInt(15, 25);
          mB = randInt(15, 25);
          break;
      }
      a = mA;
      b = mB;
      final prod = a * b;
      final missing = diff == Difficulty.easy ? 3 : randInt(1, 3);
      if (missing == 3) {
        key = 'm${min(a, b)}x${max(a, b)}';
        text = '$a × $b = ?';
        ans = prod;
      } else if (missing == 1) {
        key = 'm?x$b=$prod';
        text = '? × $b = $prod';
        ans = a;
      } else {
        key = 'm${a}x?=$prod';
        text = '$a × ? = $prod';
        ans = b;
      }
      return _QBase(
        type: type,
        key: key,
        text: text,
        ans: ans,
        fact: _fact(type, a, b, prod, _representationForMissing(missing)),
      );
    }

    if (type == Operation.division) {
      late int dB, dAns;
      switch (diff) {
        case Difficulty.easy:
          dB = randInt(2, 5);
          dAns = randInt(2, 5);
          break;
        case Difficulty.medium:
          dB = randInt(2, 10);
          dAns = randInt(2, 10);
          break;
        case Difficulty.hard:
          dB = randInt(3, 12);
          dAns = randInt(3, 12);
          break;
        case Difficulty.expert:
          dB = randInt(11, 15);
          dAns = randInt(11, 15);
          break;
        case Difficulty.insane:
          dB = randInt(12, 20);
          dAns = randInt(12, 20);
          break;
      }
      b = dB;
      ans = dAns;
      a = b * (ans as int);
      final quotient = ans;
      final missing = diff == Difficulty.easy ? 3 : randInt(1, 3);
      if (missing == 3) {
        key = 'd$a/$b';
        text = '$a ÷ $b = ?';
        ans = quotient;
      } else if (missing == 1) {
        key = 'd?/$b=$quotient';
        text = '? ÷ $b = $quotient';
        ans = a;
      } else {
        key = 'd$a/?=$quotient';
        text = '$a ÷ ? = $quotient';
        ans = b;
      }
      return _QBase(
        type: type,
        key: key,
        text: text,
        ans: ans,
        fact: _fact(
          type,
          a,
          b,
          quotient,
          _representationForMissing(missing),
        ),
      );
    }

    // Fallback to multiplication
    final maxN = diff == Difficulty.easy
        ? 5
        : diff == Difficulty.medium
            ? 10
            : 12;
    final a2 = randInt(2, maxN);
    final b2 = randInt(2, maxN);
    return _QBase(
      type: Operation.multiplication,
      key: 'm${min(a2, b2)}x${max(a2, b2)}',
      text: '$a2 × $b2 = ?',
      ans: a2 * b2,
      fact: _fact(
        Operation.multiplication,
        a2,
        b2,
        a2 * b2,
        FactRepresentation.direct,
      ),
    );
  }

  // ─── Number type modifier ───────────────────────────────────
  _QBase _applyNumType(
      _QBase q, Operation type, Difficulty diff, NumberType numType) {
    if (numType == NumberType.natural) return q;
    if (q.key.contains('?') || q.text.contains('NaN')) return q;

    final r = _rng;
    int randInt(int min, int max) => min + r.nextInt(max - min + 1);
    double random() => r.nextDouble();
    String wrap(num n) => n < 0 ? '($n)' : '$n';

    final decPlaces = {
      Difficulty.easy: 1,
      Difficulty.medium: 1,
      Difficulty.hard: 2,
      Difficulty.expert: 2,
      Difficulty.insane: 3,
    }[diff]!;
    final factor = pow(10, decPlaces).toInt();
    double round(num n, int dp) =>
        (n * pow(10, dp)).round() / pow(10, dp).toDouble();

    if (numType == NumberType.integers) {
      if (type == Operation.addition) {
        final signA = random() < 0.5 ? -1 : 1;
        final signB = random() < 0.5 ? -1 : 1;
        final parts = q.key.replaceAll('a', '').split('+');
        if (parts.length == 2) {
          final rawA = int.tryParse(parts[0]);
          final rawB = int.tryParse(parts[1]);
          if (rawA == null || rawB == null) return q;
          final a = rawA * signA;
          final b = rawB * signB;
          return _QBase(
            type: type,
            ans: a + b,
            text: '${wrap(a)} + ${wrap(b)} = ?',
            key: 'int+$a+$b',
            fact: _fact(type, a, b, a + b, FactRepresentation.direct),
            numberTypeTransformed: true,
          );
        }
      } else if (type == Operation.subtraction) {
        final signB = random() < 0.5 ? -1 : 1;
        final parts = q.key.replaceAll('s', '').split('-');
        if (parts.length == 2) {
          final rawA = int.tryParse(parts[0]);
          final rawB = int.tryParse(parts[1]);
          if (rawA == null || rawB == null) return q;
          final a = rawA;
          final b = rawB * signB;
          return _QBase(
            type: type,
            ans: a - b,
            text: '${wrap(a)} − ${wrap(b)} = ?',
            key: 'int-$a-$b',
            fact: _fact(type, a, b, a - b, FactRepresentation.direct),
            numberTypeTransformed: true,
          );
        }
      } else if (type == Operation.multiplication) {
        final signA = random() < 0.5 ? -1 : 1;
        final signB = random() < 0.5 ? -1 : 1;
        final parts = q.key.replaceAll('m', '').split('x');
        if (parts.length == 2) {
          final rawA = int.tryParse(parts[0]);
          final rawB = int.tryParse(parts[1]);
          if (rawA == null || rawB == null) return q;
          final a = rawA * signA;
          final b = rawB * signB;
          return _QBase(
            type: type,
            ans: a * b,
            text: '${wrap(a)} × ${wrap(b)} = ?',
            key: 'intx${a}x$b',
            fact: _fact(type, a, b, a * b, FactRepresentation.direct),
            numberTypeTransformed: true,
          );
        }
      } else if (type == Operation.division) {
        final signA = random() < 0.5 ? -1 : 1;
        final parts = q.key.replaceAll('d', '').split('/');
        if (parts.length == 2) {
          final rawA = int.tryParse(parts[0]);
          final rawB = int.tryParse(parts[1]);
          if (rawA == null || rawB == null || rawB == 0) return q;
          final a = rawA * signA;
          final b = rawB;
          final ans = a / b;
          if (ans == ans.roundToDouble()) {
            return _QBase(
              type: type,
              ans: ans.toInt(),
              text: '${wrap(a)} ÷ ${wrap(b)} = ?',
              key: 'intd$a/$b',
              fact: _fact(type, a, b, ans.toInt(), FactRepresentation.direct),
              numberTypeTransformed: true,
            );
          }
        }
      }
      return q;
    }

    if (numType == NumberType.rationals) {
      double makeDecimal() {
        final intPart = randInt(1, 15);
        final fracPart = randInt(1, factor - 1);
        return round(intPart + fracPart / factor, decPlaces);
      }

      double safeNum(num n) => double.parse(n.toStringAsFixed(decPlaces));
      double safeAns(num n) => double.parse(n.toStringAsFixed(decPlaces));

      if (type == Operation.addition) {
        final a = makeDecimal();
        final b = makeDecimal();
        final ans = safeAns(a + b);
        if (ans.isNaN) return q;
        return _QBase(
          type: type,
          ans: ans,
          text: '$a + $b = ?',
          key: 'ra$a+$b',
          ratDP: decPlaces,
          fact: _fact(type, a, b, ans, FactRepresentation.direct),
          numberTypeTransformed: true,
        );
      }
      if (type == Operation.subtraction) {
        final b = makeDecimal();
        final extra =
            round(randInt(1, 8) + randInt(1, factor - 1) / factor, decPlaces);
        final a = safeNum(b + extra);
        final ans = safeAns(a - b);
        if (ans.isNaN) return q;
        return _QBase(
          type: type,
          ans: ans,
          text: '$a − $b = ?',
          key: 'rs$a-$b',
          ratDP: decPlaces,
          fact: _fact(type, a, b, ans, FactRepresentation.direct),
          numberTypeTransformed: true,
        );
      }
      if (type == Operation.multiplication) {
        final a = makeDecimal();
        final b = randInt(2, 9);
        final ans = double.parse((a * b).toStringAsFixed(decPlaces));
        if (ans.isNaN) return q;
        return _QBase(
          type: type,
          ans: ans,
          text: '$a × $b = ?',
          key: 'rm${a}x$b',
          ratDP: decPlaces,
          fact: _fact(type, a, b, ans, FactRepresentation.direct),
          numberTypeTransformed: true,
        );
      }
      if (type == Operation.division) {
        final b = randInt(2, 9);
        final ans = makeDecimal();
        final a = safeNum(b * ans);
        if (a.isNaN || ans.isNaN) return q;
        return _QBase(
          type: type,
          ans: ans,
          text: '$a ÷ $b = ?',
          key: 'rd$a/$b',
          ratDP: decPlaces,
          fact: _fact(type, a, b, ans, FactRepresentation.direct),
          numberTypeTransformed: true,
        );
      }
    }
    return q;
  }

  // ─── Choice builder ─────────────────────────────────────────
  List<num> _buildChoices(_QBase q, NumberType numType) {
    final isIntegers = numType == NumberType.integers;
    final isRationals = numType == NumberType.rationals;
    final allowNeg = isIntegers;
    final spread = max(3, (q.ans.abs() * 0.3).ceil() + 2);
    final ratDP = isRationals ? (q.ratDP ?? 2) : 0;
    double ratRound(num n) => double.parse(n.toStringAsFixed(ratDP));

    final choices = <num>{q.ans};
    final signedInteger = isIntegers && q.text.contains('(-') && q.ans != 0;
    final candidates = <num?>[
      signedInteger ? -q.ans : null,
      q.ans + 1,
      q.ans - 1,
      q.ans + 10,
      q.ans - 10,
      (q.ans * 1.1).round(),
      (q.ans * 0.9).round(),
      isRationals ? ratRound(q.ans + 0.1) : null,
      isRationals ? ratRound(q.ans - 0.1) : null,
      isRationals ? ratRound(q.ans + 1) : null,
      isRationals ? ratRound(q.ans - 1) : null,
    ];
    for (final v in candidates) {
      if (choices.length >= 4) break;
      if (v == null || v == q.ans) continue;
      if (!allowNeg && !isRationals && v <= 0) continue;
      choices.add(v);
    }
    int guard = 0;
    while (choices.length < 4 && guard++ < 300) {
      num fake;
      if (isRationals) {
        fake = ratRound(q.ans + (_rng.nextDouble() - 0.5) * spread);
      } else {
        fake = q.ans + _randInt(-spread, spread);
        if (!allowNeg && fake <= 0) fake = q.ans + _randInt(1, spread + 3);
      }
      if (fake != q.ans) choices.add(fake);
    }
    final list = choices.toList();
    list.shuffle(_rng);
    return list;
  }

  int _randInt(int min, int max) => min + _rng.nextInt(max - min + 1);

  MathFact _fact(
    Operation operation,
    num left,
    num right,
    num result,
    FactRepresentation representation,
  ) =>
      MathFact(
        operation: operation,
        left: left,
        right: right,
        result: result,
        representation: representation,
        difficulty: Difficulty.easy,
        numberType: NumberType.natural,
      );

  FactRepresentation _representationForMissing(int missing) =>
      switch (missing) {
        1 => FactRepresentation.missingLeft,
        2 => FactRepresentation.missingRight,
        _ => FactRepresentation.direct,
      };

  bool _representationAllowed(
          FactRepresentation representation, Difficulty diff) =>
      diff != Difficulty.easy || representation == FactRepresentation.direct;

  Operation? _inverseOperation(Operation operation) => switch (operation) {
        Operation.addition => Operation.subtraction,
        Operation.subtraction => Operation.addition,
        Operation.multiplication => Operation.division,
        Operation.division => Operation.multiplication,
        _ => null,
      };

  bool _sameRenderedForm(MathFact left, MathFact right) =>
      left.operation == right.operation &&
      left.left == right.left &&
      left.right == right.right &&
      left.result == right.result &&
      left.representation == right.representation;

  bool _isWithinCanonicalRange(MathFact fact) {
    if (fact.numberType == NumberType.mixed) return false;
    if (fact.numberType == NumberType.rationals) {
      return _isWithinRationalRange(fact);
    }
    final abs = fact.numberType == NumberType.integers;
    num value(num number) => abs ? number.abs() : number;
    final range = _operandRange(fact.operation, fact.difficulty);
    bool inRange(num number) => number >= range.$1 && number <= range.$2;

    return switch (fact.operation) {
      Operation.addition =>
        inRange(value(fact.left)) && inRange(value(fact.right)),
      Operation.subtraction =>
        inRange(value(fact.right)) && inRange(value(fact.result)),
      Operation.multiplication =>
        inRange(value(fact.left)) && inRange(value(fact.right)),
      Operation.division => fact.right != 0 &&
          inRange(value(fact.right)) &&
          inRange(value(fact.result)),
      _ => false,
    };
  }

  (int, int) _operandRange(Operation operation, Difficulty difficulty) {
    final index = difficulty.index;
    return switch (operation) {
      Operation.addition => const [
          (1, 10),
          (11, 49),
          (25, 99),
          (50, 199),
          (100, 499)
        ][index],
      Operation.subtraction => const [
          (1, 9),
          (5, 44),
          (15, 79),
          (50, 149),
          (100, 399)
        ][index],
      Operation.multiplication => const [
          (2, 5),
          (2, 10),
          (3, 12),
          (11, 20),
          (15, 25)
        ][index],
      Operation.division => const [
          (2, 5),
          (2, 10),
          (3, 12),
          (11, 15),
          (12, 20)
        ][index],
      _ => throw ArgumentError.value(operation, 'operation'),
    };
  }

  bool _isWithinRationalRange(MathFact fact) {
    bool decimalOperand(num value) => value > 1 && value < 16;
    bool smallInteger(num value) =>
        value == value.roundToDouble() && value >= 2 && value <= 9;
    return switch (fact.operation) {
      Operation.addition =>
        decimalOperand(fact.left) && decimalOperand(fact.right),
      Operation.subtraction =>
        decimalOperand(fact.right) && fact.left > fact.right && fact.left < 25,
      Operation.multiplication =>
        decimalOperand(fact.left) && smallInteger(fact.right),
      Operation.division => fact.right != 0 &&
          smallInteger(fact.right) &&
          decimalOperand(fact.result),
      _ => false,
    };
  }

  Question _renderFact(MathFact fact) {
    String number(num value) => value < 0 ? '($value)' : '$value';
    final symbol = fact.operation.symbol;
    final text = switch (fact.representation) {
      FactRepresentation.direct =>
        '${number(fact.left)} $symbol ${number(fact.right)} = ?',
      FactRepresentation.missingLeft =>
        '? $symbol ${number(fact.right)} = ${number(fact.result)}',
      FactRepresentation.missingRight =>
        '${number(fact.left)} $symbol ? = ${number(fact.result)}',
    };
    final answer = switch (fact.representation) {
      FactRepresentation.direct => fact.result,
      FactRepresentation.missingLeft => fact.left,
      FactRepresentation.missingRight => fact.right,
    };
    final q = _QBase(
      type: fact.operation,
      key: 'fact:${fact.operation.name}:${fact.left}:${fact.right}:'
          '${fact.result}:${fact.representation.name}',
      text: text,
      ans: answer,
      ratDP: fact.rationalDecimalPlaces,
      fact: fact,
    );
    return Question(
      type: q.type,
      key: q.key,
      text: q.text,
      ans: q.ans,
      choices: _buildChoices(q, fact.numberType),
      diff: fact.difficulty,
      numType: fact.numberType,
      ratDP: q.ratDP,
      fact: fact,
    );
  }
}

class _QBase {
  final Operation type;
  String key;
  String text;
  num ans;
  final int? ratDP;
  final MathFact fact;
  final bool numberTypeTransformed;
  _QBase({
    required this.type,
    required this.key,
    required this.text,
    required this.ans,
    this.ratDP,
    required this.fact,
    this.numberTypeTransformed = false,
  });
}
