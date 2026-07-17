import 'dart:convert';

import '../../../models/enums.dart';
import '../../../models/player.dart';

enum OperationQuestQuestionMechanic {
  standard,
  missingOperation,
  missingNumber,
}

enum OperationQuestStageId {
  additionEasy('addition_easy'),
  additionMedium('addition_medium'),
  additionHard('addition_hard'),
  subtractionEasy('subtraction_easy'),
  subtractionMedium('subtraction_medium'),
  subtractionHard('subtraction_hard'),
  multiplicationEasy('multiplication_easy'),
  multiplicationMedium('multiplication_medium'),
  multiplicationHard('multiplication_hard'),
  divisionEasy('division_easy'),
  divisionMedium('division_medium'),
  divisionHard('division_hard'),
  mixedEasy('mixed_easy'),
  mixedMedium('mixed_medium'),
  mixedHard('mixed_hard'),
  missingOperationEasy('missing_operation_easy'),
  missingOperationMedium('missing_operation_medium'),
  missingOperationHard('missing_operation_hard'),
  missingNumberEasy('missing_number_easy'),
  missingNumberMedium('missing_number_medium'),
  missingNumberHard('missing_number_hard');

  const OperationQuestStageId(this.storageId);

  final String storageId;

  static OperationQuestStageId? fromStorageId(String value) {
    for (final id in values) {
      if (id.storageId == value) return id;
    }
    return null;
  }
}

class OperationQuestStage {
  const OperationQuestStage({
    required this.id,
    required this.title,
    required this.operation,
    required this.difficulty,
    this.questionMechanic = OperationQuestQuestionMechanic.standard,
  });

  final OperationQuestStageId id;
  final String title;
  final Operation operation;
  final Difficulty difficulty;
  final OperationQuestQuestionMechanic questionMechanic;
  NumberType get numberType => NumberType.natural;
  int get questionTarget => 10;
}

const operationQuestStages = <OperationQuestStage>[
  OperationQuestStage(
    id: OperationQuestStageId.additionEasy,
    title: 'First Sums',
    operation: Operation.addition,
    difficulty: Difficulty.easy,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.additionMedium,
    title: 'Bigger Sums',
    operation: Operation.addition,
    difficulty: Difficulty.medium,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.additionHard,
    title: 'Addition Challenge',
    operation: Operation.addition,
    difficulty: Difficulty.hard,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.subtractionEasy,
    title: 'First Differences',
    operation: Operation.subtraction,
    difficulty: Difficulty.easy,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.subtractionMedium,
    title: 'Bigger Differences',
    operation: Operation.subtraction,
    difficulty: Difficulty.medium,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.subtractionHard,
    title: 'Subtraction Challenge',
    operation: Operation.subtraction,
    difficulty: Difficulty.hard,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.multiplicationEasy,
    title: 'Times Table Start',
    operation: Operation.multiplication,
    difficulty: Difficulty.easy,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.multiplicationMedium,
    title: 'Product Climb',
    operation: Operation.multiplication,
    difficulty: Difficulty.medium,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.multiplicationHard,
    title: 'Multiplication Challenge',
    operation: Operation.multiplication,
    difficulty: Difficulty.hard,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.divisionEasy,
    title: 'Sharing Basics',
    operation: Operation.division,
    difficulty: Difficulty.easy,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.divisionMedium,
    title: 'Quotient Climb',
    operation: Operation.division,
    difficulty: Difficulty.medium,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.divisionHard,
    title: 'Division Challenge',
    operation: Operation.division,
    difficulty: Difficulty.hard,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.mixedEasy,
    title: 'Mix It Up',
    operation: Operation.mixed,
    difficulty: Difficulty.easy,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.mixedMedium,
    title: 'Operation Switch',
    operation: Operation.mixed,
    difficulty: Difficulty.medium,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.mixedHard,
    title: 'Mixed Challenge',
    operation: Operation.mixed,
    difficulty: Difficulty.hard,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.missingOperationEasy,
    title: 'Find the Sign',
    operation: Operation.mixed,
    difficulty: Difficulty.easy,
    questionMechanic: OperationQuestQuestionMechanic.missingOperation,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.missingOperationMedium,
    title: 'Operator Detective',
    operation: Operation.mixed,
    difficulty: Difficulty.medium,
    questionMechanic: OperationQuestQuestionMechanic.missingOperation,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.missingOperationHard,
    title: 'Master Operator',
    operation: Operation.mixed,
    difficulty: Difficulty.hard,
    questionMechanic: OperationQuestQuestionMechanic.missingOperation,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.missingNumberEasy,
    title: 'Find the Number',
    operation: Operation.mixed,
    difficulty: Difficulty.easy,
    questionMechanic: OperationQuestQuestionMechanic.missingNumber,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.missingNumberMedium,
    title: 'Number Detective',
    operation: Operation.mixed,
    difficulty: Difficulty.medium,
    questionMechanic: OperationQuestQuestionMechanic.missingNumber,
  ),
  OperationQuestStage(
    id: OperationQuestStageId.missingNumberHard,
    title: 'Missing Number Master',
    operation: Operation.mixed,
    difficulty: Difficulty.hard,
    questionMechanic: OperationQuestQuestionMechanic.missingNumber,
  ),
];

OperationQuestStage operationQuestStage(OperationQuestStageId id) =>
    operationQuestStages.firstWhere((stage) => stage.id == id);

List<OperationQuestStage> operationQuestStagesFor(Operation operation) =>
    operationQuestStages
        .where((stage) => stage.operation == operation)
        .toList();

const _operationQuestOperatorChoices = <int>[0, 1, 2, 3];

String operationQuestOperatorSymbol(num code) => switch (code) {
      0 => '+',
      1 => '−',
      2 => '×',
      3 => '÷',
      _ => throw StateError('Unknown Missing Operation answer code: $code'),
    };

Question? missingOperationQuestion(Question question) {
  final match =
      RegExp(r'^(\d+) ([+\-×÷]) (\d+) = \?$').firstMatch(question.text);
  if (match == null) return null;
  final a = int.parse(match.group(1)!);
  final b = int.parse(match.group(3)!);
  final symbol = match.group(2)!;
  final expectedSymbol = switch (question.type) {
    Operation.addition => '+',
    Operation.subtraction => '-',
    Operation.multiplication => '×',
    Operation.division => '÷',
    _ => null,
  };
  if (symbol != expectedSymbol) return null;

  final result = question.ans;
  final validOperations = <Operation>[
    if (a + b == result) Operation.addition,
    if (a - b == result) Operation.subtraction,
    if (a * b == result) Operation.multiplication,
    if (b != 0 && a % b == 0 && a ~/ b == result) Operation.division,
  ];
  if (validOperations.length != 1 || validOperations.single != question.type) {
    return null;
  }

  final code = switch (question.type) {
    Operation.addition => 0,
    Operation.subtraction => 1,
    Operation.multiplication => 2,
    Operation.division => 3,
    _ => throw StateError('Missing Operation requires a concrete operation.'),
  };
  return Question(
    type: question.type,
    key: '${question.key}:missing-operation',
    text: '$a ? $b = $result',
    ans: code,
    choices: List<num>.from(_operationQuestOperatorChoices),
    boss: question.boss,
    diff: question.diff,
    numType: question.numType,
    ratDP: question.ratDP,
  );
}

Question? missingNumberQuestion(Question question, Difficulty difficulty) {
  final direct = RegExp(r'^\d+ [+\-×÷] \d+ = \?$').hasMatch(question.text);
  final missingLeft = RegExp(r'^\? [+\-×÷] \d+ = \d+$').hasMatch(question.text);
  final missingRight =
      RegExp(r'^\d+ [+\-×÷] \? = \d+$').hasMatch(question.text);
  final allowed = switch (difficulty) {
    Difficulty.easy => direct,
    Difficulty.medium => missingLeft || missingRight,
    Difficulty.hard => direct || missingLeft || missingRight,
    _ => false,
  };
  return allowed ? question : null;
}

int operationQuestStarsForCorrectAnswers(int correct) {
  if (correct >= 10) return 3;
  if (correct >= 8) return 2;
  if (correct >= 6) return 1;
  return 0;
}

class OperationQuestProgress {
  OperationQuestProgress([Map<OperationQuestStageId, int> stars = const {}])
      : stars = Map.unmodifiable(stars);

  factory OperationQuestProgress.decode(String raw) {
    if (raw.isEmpty) return OperationQuestProgress();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return OperationQuestProgress();
      }
      final rawStars = decoded['stars'];
      if (rawStars is! Map) return OperationQuestProgress();
      final stars = <OperationQuestStageId, int>{};
      for (final entry in rawStars.entries) {
        final id = OperationQuestStageId.fromStorageId('${entry.key}');
        final value = entry.value;
        if (id == null || value is! num) continue;
        stars[id] = value.toInt().clamp(0, 3);
      }
      return OperationQuestProgress(stars);
    } catch (_) {
      return OperationQuestProgress();
    }
  }

  final Map<OperationQuestStageId, int> stars;

  int bestStars(OperationQuestStageId id) => stars[id] ?? 0;

  bool isUnlocked(OperationQuestStageId id) => switch (id) {
        OperationQuestStageId.additionEasy => true,
        OperationQuestStageId.additionMedium =>
          bestStars(OperationQuestStageId.additionEasy) >= 1,
        OperationQuestStageId.additionHard =>
          bestStars(OperationQuestStageId.additionMedium) >= 1,
        OperationQuestStageId.subtractionEasy =>
          bestStars(OperationQuestStageId.additionHard) >= 1,
        OperationQuestStageId.subtractionMedium =>
          bestStars(OperationQuestStageId.subtractionEasy) >= 1,
        OperationQuestStageId.subtractionHard =>
          bestStars(OperationQuestStageId.subtractionMedium) >= 1,
        OperationQuestStageId.multiplicationEasy =>
          bestStars(OperationQuestStageId.subtractionHard) >= 1,
        OperationQuestStageId.multiplicationMedium =>
          bestStars(OperationQuestStageId.multiplicationEasy) >= 1,
        OperationQuestStageId.multiplicationHard =>
          bestStars(OperationQuestStageId.multiplicationMedium) >= 1,
        OperationQuestStageId.divisionEasy =>
          bestStars(OperationQuestStageId.multiplicationHard) >= 1,
        OperationQuestStageId.divisionMedium =>
          bestStars(OperationQuestStageId.divisionEasy) >= 1,
        OperationQuestStageId.divisionHard =>
          bestStars(OperationQuestStageId.divisionMedium) >= 1,
        OperationQuestStageId.mixedEasy =>
          bestStars(OperationQuestStageId.divisionHard) >= 1,
        OperationQuestStageId.mixedMedium =>
          bestStars(OperationQuestStageId.mixedEasy) >= 1,
        OperationQuestStageId.mixedHard =>
          bestStars(OperationQuestStageId.mixedMedium) >= 1,
        OperationQuestStageId.missingOperationEasy =>
          bestStars(OperationQuestStageId.mixedHard) >= 1,
        OperationQuestStageId.missingOperationMedium =>
          bestStars(OperationQuestStageId.missingOperationEasy) >= 1,
        OperationQuestStageId.missingOperationHard =>
          bestStars(OperationQuestStageId.missingOperationMedium) >= 1,
        OperationQuestStageId.missingNumberEasy =>
          bestStars(OperationQuestStageId.missingOperationHard) >= 1,
        OperationQuestStageId.missingNumberMedium =>
          bestStars(OperationQuestStageId.missingNumberEasy) >= 1,
        OperationQuestStageId.missingNumberHard =>
          bestStars(OperationQuestStageId.missingNumberMedium) >= 1,
      };

  OperationQuestProgress recordBest(OperationQuestStageId id, int value) {
    final clamped = value.clamp(0, 3);
    if (clamped <= bestStars(id)) return this;
    return OperationQuestProgress({...stars, id: clamped});
  }

  String encode() => jsonEncode({
        'version': 1,
        'stars': {
          for (final entry in stars.entries) entry.key.storageId: entry.value,
        },
      });
}
