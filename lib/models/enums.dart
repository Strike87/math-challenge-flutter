/// Operation types supported by the game.
enum Operation {
  addition,
  subtraction,
  multiplication,
  division,
  mixed,
  master,
  dailyBoss,
  survival;

  String get label {
    switch (this) {
      case Operation.addition:
        return 'Addition';
      case Operation.subtraction:
        return 'Subtraction';
      case Operation.multiplication:
        return 'Multiply';
      case Operation.division:
        return 'Division';
      case Operation.mixed:
        return 'Mixed';
      case Operation.master:
        return 'Master';
      case Operation.dailyBoss:
        return 'Daily Boss';
      case Operation.survival:
        return 'Survival';
    }
  }

  String get symbol {
    switch (this) {
      case Operation.addition:
        return '+';
      case Operation.subtraction:
        return '−';
      case Operation.multiplication:
        return '×';
      case Operation.division:
        return '÷';
      default:
        return '?';
    }
  }

  static Operation fromString(String s) {
    return Operation.values.firstWhere(
      (e) => e.name == s,
      orElse: () => Operation.mixed,
    );
  }
}

/// Difficulty tiers used throughout the game.
enum Difficulty {
  easy,
  medium,
  hard,
  expert,
  insane;

  String get label => name[0].toUpperCase() + name.substring(1);

  static Difficulty fromString(String s) {
    return Difficulty.values.firstWhere(
      (e) => e.name == s,
      orElse: () => Difficulty.easy,
    );
  }
}

/// Number domain types.
enum NumberType {
  natural,
  integers,
  rationals,
  mixed;

  String get label {
    switch (this) {
      case NumberType.natural:
        return 'Natural';
      case NumberType.integers:
        return 'Integers';
      case NumberType.rationals:
        return 'Rationals';
      case NumberType.mixed:
        return 'Mixed';
    }
  }

  static NumberType fromString(String s) {
    return NumberType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => NumberType.natural,
    );
  }
}

/// Game modes that determine rules and timer behaviour.
enum GameMode {
  standard,
  blitz,
  death,
  survival,
  combo;

  String get label {
    switch (this) {
      case GameMode.standard:
        return 'Standard';
      case GameMode.blitz:
        return '⚡ Blitz';
      case GameMode.death:
        return '💀 Death';
      case GameMode.survival:
        return '💪 Survival';
      case GameMode.combo:
        return '🔥 Combo';
    }
  }

  String get description {
    switch (this) {
      case GameMode.standard:
        return 'Classic timed quiz — score points for every correct answer!';
      case GameMode.blitz:
        return '60 seconds — answer as many as possible';
      case GameMode.death:
        return 'One wrong answer = Game Over!';
      case GameMode.survival:
        return 'You have 3 hearts — lose one for each wrong answer. Stay alive!';
      case GameMode.combo:
        return 'Build your streak for bigger multipliers';
    }
  }

  String get icon {
    switch (this) {
      case GameMode.standard:
        return '⭐';
      case GameMode.blitz:
        return '⚡';
      case GameMode.death:
        return '💀';
      case GameMode.survival:
        return '💪';
      case GameMode.combo:
        return '🔥';
    }
  }

  /// Modes restricted to single-player games.
  static const Set<GameMode> singlePlayerOnly = {
    GameMode.blitz,
    GameMode.death,
    GameMode.survival,
    GameMode.combo,
  };

  /// Returns true if [mode] is available for the given player count.
  static bool isAvailableForPlayers(GameMode mode, int players) {
    return players == 1 || !singlePlayerOnly.contains(mode);
  }

  static GameMode fromString(String s) {
    return GameMode.values.firstWhere(
      (e) => e.name == s,
      orElse: () => GameMode.standard,
    );
  }
}

/// Answer presentation used for a game session.
enum AnswerStyle {
  choice4,
  trueFalse;

  String get label => switch (this) {
        AnswerStyle.choice4 => '4 Choices',
        AnswerStyle.trueFalse => 'True / False',
      };

  int baseScore({required int classicBase}) => switch (this) {
        AnswerStyle.choice4 => classicBase,
        AnswerStyle.trueFalse => classicBase ~/ 2,
      };

  static AnswerStyle fromString(String storedName) =>
      AnswerStyle.values.firstWhere(
        (style) => style.name == storedName,
        orElse: () => AnswerStyle.choice4,
      );
}

/// Power-up kinds awarded to single-player Standard runs.
enum PowerUp {
  time,
  fifty,
  double,
  shield,
  freeze,
  switchOp;

  String get label {
    switch (this) {
      case PowerUp.time:
        return '+5s';
      case PowerUp.fifty:
        return '50/50';
      case PowerUp.double:
        return '×2';
      case PowerUp.shield:
        return '🛡️';
      case PowerUp.freeze:
        return '⏸️ Freeze';
      case PowerUp.switchOp:
        return '🔀 Swap';
    }
  }

  String get icon {
    switch (this) {
      case PowerUp.time:
        return '⏱️';
      case PowerUp.fifty:
        return '✂️';
      case PowerUp.double:
        return '✨';
      case PowerUp.shield:
        return '🛡️';
      case PowerUp.freeze:
        return '❄️';
      case PowerUp.switchOp:
        return '🔀';
    }
  }
}
