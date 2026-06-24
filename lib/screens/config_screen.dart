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
                _ToggleOpt('👤 1 Player', 1, const Color(GameConfig.sky)),
                _ToggleOpt('👥 2 Players', 2, const Color(GameConfig.punch)),
              ],
              active: gs.players,
              onPick: (v) => gs.setOption('players', v),
            ),
            const SizedBox(height: 16),

            // Mode
            _SectionTitle('Game Mode', s),
            _ModeTabs(
              active: gs.mode,
              onPick: (m) => gs.setOption('mode', m.name),
            ),
            const SizedBox(height: 8),
            _ModeInfoCard(mode: gs.mode, s: s),
            const SizedBox(height: 16),

            // Difficulty
            _SectionTitle('Difficulty', s),
            _ToggleRow(
              options: [
                _ToggleOpt('🌱 Easy', 'easy', const Color(GameConfig.mint)),
                _ToggleOpt('🔥 Medium', 'medium', const Color(GameConfig.mango)),
                _ToggleOpt('💥 Hard', 'hard', const Color(GameConfig.punch)),
              ],
              active: gs.diff.name,
              onPick: (v) => gs.setOption('diff', v),
            ),
            const SizedBox(height: 4),
            Text(_diffDesc(gs.diff),
              style: TextStyle(color: s.muted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Question count
            _SectionTitle('Number of Questions', s),
            _ToggleRow(
              options: [
                _ToggleOpt('10', 10, const Color(GameConfig.sky)),
                _ToggleOpt('15', 15, const Color(GameConfig.sky)),
                _ToggleOpt('20', 20, const Color(GameConfig.sky)),
                _ToggleOpt('25', 25, const Color(GameConfig.sky)),
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: s.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adaptive Difficulty',
                          style: TextStyle(
                            color: s.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text('Auto-adjusts to your skill level',
                          style: TextStyle(color: s.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: gs.adaptive,
                    activeThumbColor: const Color(GameConfig.coral),
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
      case Difficulty.easy:    return '🌱 Numbers 1–20, plenty of time';
      case Difficulty.medium:  return '🔥 Numbers 11–49, less time';
      case Difficulty.hard:    return '💥 Numbers 25–99, fast pace';
      case Difficulty.expert:  return '⚡ Numbers 50–199, very fast';
      case Difficulty.insane:  return '💀 Numbers 100–499, lightning round';
    }
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.s, required this.title, required this.onBack});
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
          child: Text(title,
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
      child: Text(text,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isActive = o.value == active;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onPick(o.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? o.color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? o.color : o.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(o.label,
                style: TextStyle(
                  color: isActive ? Colors.white : o.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.active, required this.onPick});
  final GameMode active;
  final void Function(GameMode) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: GameMode.values.map((m) {
          final isActive = m == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPick(m),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(GameConfig.coral) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(m.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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
        color: const Color(GameConfig.coral).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(GameConfig.coral).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(mode.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.label.replaceAll(RegExp(r'[^\w ]'), '').trim(),
                  style: TextStyle(
                    color: s.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(mode.description,
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
