import '../../../features/adaptive/domain/adaptive_difficulty_engine.dart';
import '../../../models/enums.dart';

enum QuestionDifficultyRoute {
  playerConfigured,
  operationQuestStage,
  followUp,
  masterStage,
  dailyBoss,
  survivalPhase,
  adaptive,
}

const List<Difficulty> playerConfigurableDifficulties = <Difficulty>[
  Difficulty.easy,
  Difficulty.medium,
  Difficulty.hard,
];

Set<Difficulty> get playerConfigurableDifficultySet =>
    Set<Difficulty>.unmodifiable(playerConfigurableDifficulties);

Set<Difficulty> get adaptiveDifficultySet => Set<Difficulty>.unmodifiable(
      AdaptiveDifficultyEngine.legalOutputDifficulties,
    );

class QuestionDifficultyLegality {
  QuestionDifficultyLegality({
    required this.route,
    required this.resolvedDifficulty,
    required Iterable<Difficulty> legalDifficulties,
  }) : legalDifficulties = Set<Difficulty>.unmodifiable(legalDifficulties);

  final QuestionDifficultyRoute route;
  final Difficulty resolvedDifficulty;
  final Set<Difficulty> legalDifficulties;
}
