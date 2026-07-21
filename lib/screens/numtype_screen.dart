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
    final integersUnlocked = (gs.numTypeUnlocked['integers'] ?? 0) > 0;
    final rationalsUnlocked = (gs.numTypeUnlocked['rationals'] ?? 0) > 0;

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
                    _SetupHeader(
                      title: 'Choose Number Type',
                      subtitle: 'Pick your number world',
                      onBack: () => gs.showScreen(GameScreen.menu),
                      s: s,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeading(
                      s: s,
                      title: 'NUMBER TYPES',
                      subtitle: 'Choose the numbers you want to practice',
                    ),
                    const SizedBox(height: 12),
                    _NumTypeCard(
                      icon: '🔢',
                      label: 'Natural Numbers',
                      desc: '1, 2, 3, 4, …',
                      color: s.accent(GameConfig.mint),
                      status: 'READY',
                      statusIcon: Icons.check_rounded,
                      onTap: () {
                        gs.selectNumType('natural');
                      },
                      s: s,
                    ),
                    const SizedBox(height: 14),
                    _NumTypeCard(
                      icon: '±',
                      label: 'Integers',
                      desc: gs.numTypeUnlockFeedback == 'integers'
                          ? 'Need 🪙 500'
                          : integersUnlocked
                              ? 'Includes negatives: −3, 0, 5, …'
                              : 'Unlock to practice positive and negative numbers',
                      color: s.accent(GameConfig.sky),
                      locked: !integersUnlocked,
                      status: integersUnlocked
                          ? 'READY'
                          : gs.numTypeUnlockFeedback == 'integers'
                              ? 'NEED 500'
                              : '500 🪙',
                      statusIcon: integersUnlocked
                          ? Icons.check_rounded
                          : Icons.lock_rounded,
                      onTap: () {
                        gs.selectNumType('integers');
                      },
                      s: s,
                    ),
                    const SizedBox(height: 14),
                    _NumTypeCard(
                      icon: '💧',
                      label: 'Rationals / Decimals',
                      desc: gs.numTypeUnlockFeedback == 'rationals'
                          ? 'Need 🪙 1200'
                          : rationalsUnlocked
                              ? '1.5, 2.7, 0.3, …'
                              : 'Unlock to practice decimal and rational values',
                      color: s.accent(GameConfig.punch),
                      locked: !rationalsUnlocked,
                      status: rationalsUnlocked
                          ? 'READY'
                          : gs.numTypeUnlockFeedback == 'rationals'
                              ? 'NEED 1200'
                              : '1200 🪙',
                      statusIcon: rationalsUnlocked
                          ? Icons.check_rounded
                          : Icons.lock_rounded,
                      onTap: () {
                        gs.selectNumType('rationals');
                      },
                      s: s,
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
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.s,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final accent = s.accent(GameConfig.sky);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: s.text,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.head,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 58),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.s,
    required this.title,
    required this.subtitle,
  });

  final SettingsService s;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: s.accent(GameConfig.mango).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calculate_rounded,
              color: s.accent(GameConfig.mango),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: s.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.head,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumTypeCard extends StatelessWidget {
  const _NumTypeCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.status,
    required this.statusIcon,
    required this.onTap,
    required this.s,
    this.locked = false,
  });

  final String icon;
  final String label;
  final String desc;
  final Color color;
  final String status;
  final IconData statusIcon;
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
            border: Border.all(
              color: color.withValues(alpha: locked ? 0.22 : 0.38),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: locked ? 0.07 : 0.14),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: locked ? 0.09 : 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withValues(alpha: locked ? 0.14 : 0.22),
                  ),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 27,
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
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: s.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: locked ? 0.08 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: color.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 13,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
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
