import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SetupHeader(
              s: s,
              title: 'Game Setup',
              onBack: () => gs.showScreen(GameScreen.numType),
            ),
            const SizedBox(height: 8),

            // Players
            _SectionTitle('Players', s),
            _ToggleRow(
              options: [
                _ToggleOpt('👤 1 Player', 1, s.accent(GameConfig.sky)),
                _ToggleOpt('👥 2 Players', 2, s.accent(GameConfig.punch)),
              ],
              active: gs.players,
              onPick: (v) => gs.setOption('players', v),
            ),
            const SizedBox(height: 16),

            // Mode
            _SectionTitle('Game Mode', s),
            _ModeTabs(
              active: gs.mode,
              players: gs.players,
              onPick: (m) => gs.setOption('mode', m.name),
            ),
            const SizedBox(height: 8),
            _ModeInfoCard(mode: gs.mode, s: s),
            const SizedBox(height: 16),

            // Difficulty
            _SectionTitle('Difficulty', s),
            _ToggleRow(
              options: [
                _ToggleOpt('🌱 Easy', 'easy', s.accent(GameConfig.mint)),
                _ToggleOpt('🔥 Medium', 'medium', s.accent(GameConfig.mango)),
                _ToggleOpt('💥 Hard', 'hard', s.accent(GameConfig.punch)),
              ],
              active: gs.diff.name,
              onPick: (v) => gs.setOption('diff', v),
            ),
            const SizedBox(height: 4),
            Text(
              _diffDesc(gs.diff),
              style: TextStyle(
                  color: s.muted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Question count
            _SectionTitle('Number of Questions', s),
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
            const SizedBox(height: 16),

            // Adaptive toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: const Color(GameConfig.borderMdLight)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adaptive Difficulty',
                          style: TextStyle(
                            color: s.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Auto-adjusts to your skill level',
                          style: TextStyle(color: s.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: gs.adaptive,
                    activeThumbColor: s.accent(GameConfig.coral),
                    onChanged: gs.setAdaptive,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            NeoButton(
              label: 'Next: Player Setup →',
              color: GameConfig.coral,
              onPressed: gs.goToPlayerSetup,
            ),
          ],
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
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader(
      {required this.s, required this.title, required this.onBack});
  final SettingsService s;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: s.text,
          onPressed: onBack,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: s.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.head,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
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
  _ToggleOpt(this.label, this.value, this.color);
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
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _ToggleButton(
              option: options[i],
              active: active,
              onPick: onPick,
            ),
          ),
          if (i != options.length - 1) const SizedBox(width: 8),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onPick(o.value),
        child: Container(
          height: 48,
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
                Text(parts.icon, style: const TextStyle(fontSize: 16)),
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
                      fontFamily: AppFonts.head,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({String icon, String label}) _splitIconLabel(String value) {
  final firstSpace = value.indexOf(' ');
  if (firstSpace <= 0) return (icon: '', label: value);
  final icon = value.substring(0, firstSpace);
  final label = value.substring(firstSpace + 1).trim();
  if (label.isEmpty) return (icon: '', label: value);
  return (icon: icon, label: label);
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs(
      {required this.active, required this.onPick, required this.players});
  final GameMode active;
  final void Function(GameMode) onPick;
  final int players;

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
          return Row(
            children: [
              for (var i = 0; i < availableModes.length; i++) ...[
                Expanded(
                  child: _ModeTabButton(
                    mode: availableModes[i],
                    active: availableModes[i] == active,
                    disabled: !GameMode.isAvailableForPlayers(
                        availableModes[i], players),
                    compact: compact,
                    settings: s,
                    onPick: onPick,
                  ),
                ),
                if (i != availableModes.length - 1) const SizedBox(width: 4),
              ],
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
    Widget buttonContent = Container(
      height: 60,
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
            height: 23,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(mode.icon, style: const TextStyle(fontSize: 21)),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
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
                    fontFamily: AppFonts.head,
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

    return GestureDetector(
      onTap: disabled ? null : () => onPick(mode),
      child: buttonContent,
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
        color: s.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(GameConfig.coral).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
