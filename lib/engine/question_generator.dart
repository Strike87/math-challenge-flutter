import 'dart:math';
import '../models/enums.dart';
import '../models/player.dart';

/// Random question generator.
///
/// Mirrors the original HTML game's `_buildQ`, `_applyNumType`, and
/// `_generateQCore` logic, adapted to Dart.
class QuestionGenerator {
  final Random _rng = Random();

  /// Build a question for the given operation + difficulty + numType.
  Question build({
    required Operation type,
    required Difficulty diff,
    required NumberType numType,
  }) {
    var q = _buildBase(type, diff);
    q = _applyNumType(q, type, diff, numType);
    final choices = _buildChoices(q, numType);
    return Question(
      type: q.type,
      key: q.key,
      text: q.text,
      ans: q.ans,
      choices: choices,
      diff: diff,
      ratDP: q.ratDP,
    );
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
        case Difficulty.easy:    a = randInt(1, 10);  b = randInt(1, 10);  break;
        case Difficulty.medium:  a = randInt(11, 49); b = randInt(11, 49); break;
        case Difficulty.hard:    a = randInt(25, 99); b = randInt(25, 99); break;
        case Difficulty.expert:  a = randInt(50, 199);b = randInt(50, 199);break;
        case Difficulty.insane:  a = randInt(100,499);b = randInt(100,499);break;
      }
      final missing = diff == Difficulty.easy ? 3 : randInt(1, 3);
      if (missing == 3) {
        key = 'a${min(a,b)}+${max(a,b)}';
        text = '$a + $b = ?';
        ans = a + b;
      } else if (missing == 1) {
        key = 'a?+$b=${a+b}';
        text = '? + $b = ${a + b}';
        ans = a;
      } else {
        key = 'a$a+?=${a+b}';
        text = '$a + ? = ${a + b}';
        ans = b;
      }
      return _QBase(type: type, key: key, text: text, ans: ans);
    }

    if (type == Operation.subtraction) {
      switch (diff) {
        case Difficulty.easy:    b = randInt(1, 9);     ans = randInt(1, 9);    break;
        case Difficulty.medium:  b = randInt(5, 44);    ans = randInt(5, 44);   break;
        case Difficulty.hard:    b = randInt(15, 79);   ans = randInt(15, 79);  break;
        case Difficulty.expert:  b = randInt(50, 149);  ans = randInt(50, 149); break;
        case Difficulty.insane:  b = randInt(100, 399); ans = randInt(100, 399);break;
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
      return _QBase(type: type, key: key, text: text, ans: ans);
    }

    if (type == Operation.multiplication) {
      late int mA, mB;
      switch (diff) {
        case Difficulty.easy:    mA = randInt(2, 5);   mB = randInt(2, 5);   break;
        case Difficulty.medium:  mA = randInt(2, 10);  mB = randInt(2, 10);  break;
        case Difficulty.hard:    mA = randInt(3, 12);  mB = randInt(3, 12);  break;
        case Difficulty.expert:  mA = randInt(11, 20); mB = randInt(11, 20); break;
        case Difficulty.insane:  mA = randInt(15, 25); mB = randInt(15, 25); break;
      }
      a = mA; b = mB;
      final prod = a * b;
      final missing = diff == Difficulty.easy ? 3 : randInt(1, 3);
      if (missing == 3) {
        key = 'm${min(a,b)}x${max(a,b)}';
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
      return _QBase(type: type, key: key, text: text, ans: ans);
    }

    if (type == Operation.division) {
      late int dB, dAns;
      switch (diff) {
        case Difficulty.easy:    dB = randInt(2, 5);   dAns = randInt(2, 5);   break;
        case Difficulty.medium:  dB = randInt(2, 10);  dAns = randInt(2, 10);  break;
        case Difficulty.hard:    dB = randInt(3, 12);  dAns = randInt(3, 12);  break;
        case Difficulty.expert:  dB = randInt(11, 15); dAns = randInt(11, 15); break;
        case Difficulty.insane:  dB = randInt(12, 20); dAns = randInt(12, 20); break;
      }
      b = dB; ans = dAns; a = b * (ans as int);
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
      return _QBase(type: type, key: key, text: text, ans: ans);
    }

    // Fallback to multiplication
    final maxN = diff == Difficulty.easy ? 5 : diff == Difficulty.medium ? 10 : 12;
    final a2 = randInt(2, maxN);
    final b2 = randInt(2, maxN);
    return _QBase(
      type: Operation.multiplication,
      key: 'm${min(a2,b2)}x${max(a2,b2)}',
      text: '$a2 × $b2 = ?',
      ans: a2 * b2,
    );
  }

  // ─── Number type modifier ───────────────────────────────────
  _QBase _applyNumType(_QBase q, Operation type, Difficulty diff, NumberType numType) {
    if (numType == NumberType.natural) return q;
    if (q.key.contains('?') || q.text.contains('NaN')) return q;

    final r = _rng;
    int randInt(int min, int max) => min + r.nextInt(max - min + 1);
    double random() => r.nextDouble();
    String wrap(num n) => n < 0 ? '($n)' : '$n';

    final decPlaces = {
      Difficulty.easy: 1, Difficulty.medium: 1, Difficulty.hard: 2,
      Difficulty.expert: 2, Difficulty.insane: 3,
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
            type: type, ans: a + b,
            text: '${wrap(a)} + ${wrap(b)} = ?',
            key: 'int+$a+$b',
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
            type: type, ans: a - b,
            text: '${wrap(a)} − ${wrap(b)} = ?',
            key: 'int-$a-$b',
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
            type: type, ans: a * b,
            text: '${wrap(a)} × ${wrap(b)} = ?',
            key: 'intx${a}x$b',
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
              type: type, ans: ans.toInt(),
              text: '${wrap(a)} ÷ ${wrap(b)} = ?',
              key: 'intd$a/$b',
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
          type: type, ans: ans,
          text: '$a + $b = ?',
          key: 'ra$a+$b', ratDP: decPlaces,
        );
      }
      if (type == Operation.subtraction) {
        final b = makeDecimal();
        final extra = round(randInt(1, 8) + randInt(1, factor - 1) / factor, decPlaces);
        final a = safeNum(b + extra);
        final ans = safeAns(a - b);
        if (ans.isNaN) return q;
        return _QBase(
          type: type, ans: ans,
          text: '$a − $b = ?',
          key: 'rs$a-$b', ratDP: decPlaces,
        );
      }
      if (type == Operation.multiplication) {
        final a = makeDecimal();
        final b = randInt(2, 9);
        final ans = double.parse((a * b).toStringAsFixed(decPlaces));
        if (ans.isNaN) return q;
        return _QBase(
          type: type, ans: ans,
          text: '$a × $b = ?',
          key: 'rm${a}x$b', ratDP: decPlaces,
        );
      }
      if (type == Operation.division) {
        final b = randInt(2, 9);
        final ans = makeDecimal();
        final a = safeNum(b * ans);
        if (a.isNaN || ans.isNaN) return q;
        return _QBase(
          type: type, ans: ans,
          text: '$a ÷ $b = ?',
          key: 'rd$a/$b', ratDP: decPlaces,
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
    final candidates = <num?>[
      q.ans + 1, q.ans - 1,
      q.ans + 10, q.ans - 10,
      (q.ans * 1.1).round(), (q.ans * 0.9).round(),
      isIntegers ? -q.ans : null,
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
}

class _QBase {
  final Operation type;
  String key;
  String text;
  num ans;
  final int? ratDP;
  _QBase({
    required this.type,
    required this.key,
    required this.text,
    required this.ans,
    this.ratDP,
  });
}
