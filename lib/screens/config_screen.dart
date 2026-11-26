import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../features/gameplay/domain/question_difficulty_legality.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../services/settings.dart';
import '../widgets/common.dart';
import '../widgets/setup_header.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    final weakSkillsPlan = gs.setupWeakSkillsPlan;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SetupHeader(
                      s: s,
                      title: 'Game Setup',
                      subtitle: 'Build your challenge',
                      onBack: () => gs.showScreen(GameScreen.numType),
                    ),
                    const SizedBox(height: 18),

                    // HOW YOU'LL PLAY
                    _SetupGroup(
                      s: s,
                      title: 'HOW YOU\'LL PLAY',
                      icon: Icons.sports_esports_rounded,
                      accent: s.accent(GameConfig.sky),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle('Players', s),
                          _ToggleRow(
                            options: [
                              _ToggleOpt(
                                '👤 1 Player',
                                1,
                                s.accent(GameConfig.sky),
                              ),
                              _ToggleOpt(
                                '👥 2 Players',
                                2,
                                s.accent(GameConfig.punch),
                                enabled: !gs.isTargetClashSetup &&
                                    !gs.isMentalMathSetup &&
                                    weakSkillsPlan == null &&
                                    gs.setupTimingStyle ==
                                        TimingStyle.perQuestion,
                              ),
                            ],
                            active: gs.setupPlayers,
                            onPick: (v) => gs.setOption('players', v),
                          ),
                          const SizedBox(height: 18),
                          _SectionTitle('Game Mode', s),
                          _ModeTabs(
                            active: gs.setupMode,
                            players: gs.setupPlayers,
                            standardOnly:
                                gs.isMentalMathSetup || gs.isTargetClashSetup,
                            onPick: (m) => gs.setOption('mode', m.name),
                          ),
                          const SizedBox(height: 10),
                          _ModeInfoCard(mode: gs.setupMode, s: s),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // QUESTION SETTINGS
                    _SetupGroup(
                      s: s,
                      title: 'QUESTION SETTINGS',
                      icon: Icons.tune_rounded,
                      accent: s.accent(GameConfig.mango),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (gs.isTargetClashSetup) ...[
                            _SectionTitle('Answer', s),
                            Text(
                              '<   =   >',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: s.accent(GameConfig.sky),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SectionTitle('Operation', s),
                            _ToggleRow(
                              options: [
                                _ToggleOpt('Addition', Operation.addition,
                                    s.accent(GameConfig.sky)),
                                _ToggleOpt('Subtraction', Operation.subtraction,
                                    s.accent(GameConfig.mint)),
                                _ToggleOpt(
                                    'Multiplication',
                                    Operation.multiplication,
                                    s.accent(GameConfig.mango)),
                                _ToggleOpt('Division', Operation.division,
                                    s.accent(GameConfig.punch)),
                              ],
                              active: gs.targetClashSetupOperation,
                              onPick: gs.setTargetClashOperation,
                            ),
                            const SizedBox(height: 18),
                          ] else if (gs.mode == GameMode.standard &&
                              gs.setupPlayers == 1) ...[
                            _SectionTitle('Answer Style', s),
                            _ToggleRow(
                              options: [
                                _ToggleOpt(
                                  '🔢 ${AnswerStyle.choice4.label}',
                                  AnswerStyle.choice4,
                                  s.accent(GameConfig.sky),
                                ),
                                _ToggleOpt(
                                  '✓ ${AnswerStyle.trueFalse.label}',
                                  AnswerStyle.trueFalse,
                                  s.accent(GameConfig.mint),
                                  enabled: !gs.isMissingOperationPractice,
                                ),
                              ],
                              active: gs.effectiveAnswerStyle,
                              onPick: (style) {
                                if (!gs.isMissingOperationPractice) {
                                  gs.setAnswerStyle(style);
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                          ],
                          _SectionTitle('Difficulty', s),
                          _ToggleRow(
                            options: playerConfigurableDifficulties
                                .map((difficulty) =>
                                    _difficultyOption(difficulty, s))
                                .toList(growable: false),
                            active: (gs.isTargetClashSetup
                                    ? gs.targetClashSetupDifficulty
                                    : gs.diff)
                                .name,
                            onPick: (v) => gs.setOption('diff', v),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _diffDesc(gs.isTargetClashSetup
                                ? gs.targetClashSetupDifficulty
                                : gs.diff),
                            style: TextStyle(
                              color: s.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (gs.isTargetClashSetup)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const Key(
                                    'target-clash-how-to-play-reopen'),
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('How to Play'),
                                    content: Text(
                                      gs.targetClashSetupDifficulty ==
                                              Difficulty.easy
                                          ? 'Build a Target Streak, face the Boss, then clear the Final Target. Sign Lens, Balance Scan, Boss Guard, and Triple Memory are available when their conditions are met.'
                                          : 'Build a Target Streak, complete Triple Clash, face the Boss, then clear the Final Target. Sign Lens, Balance Scan, Boss Guard, and Triple Memory are available when their conditions are met.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('CLOSE'),
                                      ),
                                    ],
                                  ),
                                ),
                                icon: const Icon(Icons.help_outline),
                                label: const Text('HOW TO PLAY'),
                              ),
                            ),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            gs.isTargetClashSetup
                                ? 'Target Clash Questions'
                                : 'Number of Questions',
                            s,
                          ),
                          if (gs.isTargetClashSetup)
                            Text(
                              '${gs.pendingTargetClashConfig?.questionTarget ?? 0} derived from difficulty',
                              style: TextStyle(
                                color: s.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            _ToggleRow(
                              options: [
                                _ToggleOpt('10', 10, s.accent(GameConfig.sky)),
                                _ToggleOpt('15', 15, s.accent(GameConfig.sky)),
                                _ToggleOpt('20', 20, s.accent(GameConfig.sky)),
                                _ToggleOpt('25', 25, s.accent(GameConfig.sky)),
                              ],
                              active: gs.questionCount,
                              onPick: (v) => gs.setOption('q', v),
                            ),
                          const SizedBox(height: 18),
                          _SectionTitle('Timing', s),
                          _ToggleRow(
                            options: [
                              _ToggleOpt(
                                'Per Question',
                                TimingStyle.perQuestion,
                                s.accent(GameConfig.sky),
                              ),
                              _ToggleOpt(
                                'Deep Thinking',
                                TimingStyle.untimed,
                                s.accent(GameConfig.mint),
                                enabled: gs.canSelectDeepThinking,
                              ),
                              _ToggleOpt(
                                'Time Bank',
                                TimingStyle.timeBank,
                                s.accent(GameConfig.mango),
                                enabled: gs.canSelectTimeBank,
                              ),
                            ],
                            active: gs.setupTimingStyle,
                            onPick: gs.setTimingStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            switch (gs.setupTimingStyle) {
                              TimingStyle.perQuestion =>
                                'Timed per question based on your selected difficulty.',
                              TimingStyle.untimed =>
                                'No countdown - take the time you need.',
                              TimingStyle.timeBank =>
                                'One shared bank: 10s Easy, 8s Medium, or 6s Hard per question.',
                            },
                            style: TextStyle(
                              color: s.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PERSONALIZATION
                    _SetupGroup(
                      s: s,
                      title: 'PERSONALIZATION',
                      icon: Icons.auto_awesome_rounded,
                      accent: s.accent(GameConfig.coral),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: s
                                  .accent(GameConfig.coral)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.psychology_alt_rounded,
                              color: s.accent(GameConfig.coral),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adaptive Difficulty',
                                  style: TextStyle(
                                    color: s.text,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: AppFonts.headFor(s),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Automatically adjusts the challenge to your skill level',
                                        style: TextStyle(
                                          color: s.muted,
                                          fontSize: 11,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch.adaptive(
                                      value: gs.isMentalMathSetup
                                          ? false
                                          : gs.setupAdaptive,
                                      activeThumbColor:
                                          s.accent(GameConfig.coral),
                                      onChanged: gs.isMentalMathSetup ||
                                              gs.isTargetClashSetup ||
                                              gs.setupTimingStyle !=
                                                  TimingStyle.perQuestion
                                          ? null
                                          : gs.setAdaptive,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    NeoButton(
                      label: 'Continue to Player Setup →',
                      color: GameConfig.coral,
                      onPressed: gs.goToPlayerSetup,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _diffDesc(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return '🌱 Numbers 1–20, plenty of time';
      case Difficulty.medium:
        return '🔥 Numbers 11–49, less time';
      case Difficulty.hard:
        return '💥 Numbers 25–99, fast pace';
      case Difficulty.expert:
        return '⚡ Numbers 50–199, very fast';
      case Difficulty.insane:
        return '💀 Numbers 100–499, lightning round';
    }
  }

  _ToggleOpt<String> _difficultyOption(
    Difficulty difficulty,
    SettingsService s,
  ) {
    return switch (difficulty) {
      Difficulty.easy => _ToggleOpt(
          '🌱 Easy',
          difficulty.name,
          s.accent(GameConfig.mint),
        ),
      Difficulty.medium => _ToggleOpt(
          '🔥 Medium',
          difficulty.name,
          s.accent(GameConfig.mango),
        ),
      Difficulty.hard => _ToggleOpt(
          '💥 Hard',
          difficulty.name,
          s.accent(GameConfig.punch),
        ),
      Difficulty.expert || Difficulty.insane => throw StateError(
          'Config screen supports only player-configured difficulties.'),
    };
  }
}

class _SetupGroup extends StatelessWidget {
  const _SetupGroup({
    required this.s,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final SettingsService s;
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: s.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.headFor(s),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.s);
  final String text;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: s.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleOpt<T> {
  final String label;
  final T value;
  final Color color;
  final bool enabled;
  _ToggleOpt(this.label, this.value, this.color, {this.enabled = true});
}

class _ToggleRow<T> extends StatelessWidget {
  const _ToggleRow({
    required this.options,
    required this.active,
    required this.onPick,
  });
  final List<_ToggleOpt<T>> options;
  final T active;
  final void Function(T) onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final numericOnly = options.every((option) => option.value is int &&
            int.tryParse(option.label) != null);
        final columns = numericOnly
            ? options.length
            : _optionColumns(constraints.maxWidth, scale, options.length, 8);
        return _ConfigOptionRows(
          columns: columns,
          gap: 8,
          children: [
            for (final option in options)
              _ToggleButton(option: option, active: active, onPick: onPick),
          ],
        );
      },
    );
  }
}

// Keep the original single row at normal text sizes. At enlarged text
// sizes, reserve more width per label without changing option order.
int _optionColumns(double width, double scale, int count, double gap) {
  if (scale <= 1.3) return count;
  return ((width + gap) / (100 * scale + gap))
      .floor()
      .clamp(1, count)
      .toInt();
}

class _ConfigOptionRows extends StatelessWidget {
  const _ConfigOptionRows({
    required this.columns,
    required this.gap,
    required this.children,
  });

  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns) ...[
          if (start != 0) SizedBox(height: gap),
          Row(
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column != 0) SizedBox(width: gap),
                Expanded(
                  child: start + column < children.length
                      ? children[start + column]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ToggleButton<T> extends StatelessWidget {
  const _ToggleButton({
    required this.option,
    required this.active,
    required this.onPick,
  });

  final _ToggleOpt<T> option;
  final T active;
  final void Function(T) onPick;

  @override
  Widget build(BuildContext context) {
    final o = option;
    final isActive = o.value == active;
    final s = context.watch<SettingsService>();
    final parts = _splitIconLabel(o.label);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final enlarged = scale > 1.3;
    return Opacity(
      opacity: o.enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: o.enabled ? () => onPick(o.value) : null,
          child: Container(
            height: enlarged ? 64 : 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        o.color,
                        Color.lerp(o.color, Colors.black, 0.18)!,
                      ],
                    )
                  : null,
              color: isActive ? null : s.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.35)
                    : o.color.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: o.color.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (parts.icon.isNotEmpty) ...[
                  SizedBox(
                    width: enlarged ? 28 : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(parts.icon,
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      parts.label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive ? Colors.white : o.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        fontFamily: AppFonts.headFor(s),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({String icon, String label}) _splitIconLabel(String value) {
  final firstSpace = value.indexOf(' ');
  if (firstSpace <= 0 || value.codeUnitAt(0) < 128) {
    return (icon: '', label: value);
  }
  final icon = value.substring(0, firstSpace);
  final label = value.substring(firstSpace + 1).trim();
  if (label.isEmpty) return (icon: '', label: value);
  return (icon: icon, label: label);
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs(
      {required this.active,
      required this.onPick,
      required this.players,
      required this.standardOnly});
  final GameMode active;
  final void Function(GameMode) onPick;
  final int players;
  final bool standardOnly;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final availableModes = GameMode.values;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(GameConfig.borderMdLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
          return _ConfigOptionRows(
            columns: _optionColumns(
                constraints.maxWidth, scale, availableModes.length, 4),
            gap: 4,
            children: [
              for (final mode in availableModes)
                _ModeTabButton(
                  mode: mode,
                  active: mode == active,
                  disabled: !GameMode.isAvailableForPlayers(mode, players) ||
                      (standardOnly && mode != GameMode.standard) ||
                      (context.watch<GameState>().setupTimingStyle !=
                              TimingStyle.perQuestion &&
                          mode != GameMode.standard),
                  compact: compact,
                  settings: s,
                  onPick: onPick,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.mode,
    required this.active,
    required this.disabled,
    required this.compact,
    required this.settings,
    required this.onPick,
  });

  final GameMode mode;
  final bool active;
  final bool disabled;
  final bool compact;
  final SettingsService settings;
  final void Function(GameMode) onPick;

  @override
  Widget build(BuildContext context) {
    final activeColor = settings.accent(GameConfig.coral);
    final enlarged = MediaQuery.textScalerOf(context).scale(12) > 15.6;
    Widget buttonContent = Container(
      height: enlarged ? 84 : 60,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 5,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  activeColor,
                  Color.lerp(activeColor, Colors.black, 0.18)!,
                ],
              )
            : null,
        color: active ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: enlarged ? 32 : 23,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(mode.icon, style: const TextStyle(fontSize: 21)),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: enlarged ? 30 : 18,
            width: double.infinity,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _modeText(mode),
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : settings.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11 : 12,
                    fontFamily: AppFonts.headFor(settings),
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (disabled) {
      buttonContent = Opacity(
        opacity: 0.4,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: buttonContent,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : () => onPick(mode),
        child: buttonContent,
      ),
    );
  }
}

String _modeText(GameMode mode) {
  switch (mode) {
    case GameMode.standard:
      return 'Standard';
    case GameMode.blitz:
      return 'Blitz';
    case GameMode.death:
      return 'Death';
    case GameMode.survival:
      return 'Survival';
    case GameMode.combo:
      return 'Combo';
  }
}

class _ModeInfoCard extends StatelessWidget {
  const _ModeInfoCard({required this.mode, required this.s});
  final GameMode mode;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(GameConfig.coral).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(GameConfig.coral).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Text(mode.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.label.replaceAll(RegExp(r'[^\w ]'), '').trim(),
                  style: TextStyle(
                    color: s.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  mode.description,
                  style: TextStyle(color: s.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
