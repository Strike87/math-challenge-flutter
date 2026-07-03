import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class NumTypeScreen extends StatelessWidget {
  const NumTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SetupHeader(
              title: 'Choose Number Type',
              onBack: () => gs.showScreen(GameScreen.menu),
              s: s,
            ),
            const SizedBox(height: 16),
            _NumTypeCard(
              icon: '🔢',
              label: 'Natural Numbers',
              desc: '1, 2, 3, 4, …',
              color: const Color(GameConfig.mint),
              onTap: () {
                gs.selectNumType('natural');
              },
              s: s,
            ),
            const SizedBox(height: 12),
            _NumTypeCard(
              icon: '±',
              label: 'Integers',
              desc: gs.numTypeUnlockFeedback == 'integers'
                  ? 'Need 🪙 500'
                  : gs.numTypeUnlocked['integers']! > 0
                      ? 'Includes negatives: −3, 0, 5, …'
                      : '🔒 Unlock for 🪙 500',
              color: const Color(GameConfig.sky),
              locked: gs.numTypeUnlocked['integers']! == 0,
              onTap: () {
                gs.selectNumType('integers');
              },
              s: s,
            ),
            const SizedBox(height: 12),
            _NumTypeCard(
              icon: '💧',
              label: 'Rationals / Decimals',
              desc: gs.numTypeUnlockFeedback == 'rationals'
                  ? 'Need 🪙 1200'
                  : gs.numTypeUnlocked['rationals']! > 0
                      ? '1.5, 2.7, 0.3, …'
                      : '🔒 Unlock for 🪙 1200',
              color: const Color(GameConfig.punch),
              locked: gs.numTypeUnlocked['rationals']! == 0,
              onTap: () {
                gs.selectNumType('rationals');
              },
              s: s,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.title,
    required this.onBack,
    required this.s,
  });
  final String title;
  final VoidCallback onBack;
  final SettingsService s;

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
        const SizedBox(width: 48), // balance the back button
      ],
    );
  }
}

class _NumTypeCard extends StatelessWidget {
  const _NumTypeCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
    required this.s,
    this.locked = false,
  });
  final String icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  final SettingsService s;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: locked ? 0.08 : 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: locked ? s.muted : s.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: s.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  locked ? Icons.lock : Icons.chevron_right,
                  color: color,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
