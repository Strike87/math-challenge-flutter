import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../services/settings.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('practice-menu-back'),
                      tooltip: 'Back to Home',
                      onPressed: () => gs.showScreen(GameScreen.menu),
                      icon: Icon(Icons.arrow_back_rounded, color: s.text),
                    ),
                    Expanded(
                      child: Text(
                        'Practice',
                        style: TextStyle(
                          color: s.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PracticeCampaign(
                  key: const Key('operation-quest-practice-entry'),
                  icon: '🧭',
                  title: 'Operation Quest',
                  subtitle: '10 TRAILS • 30 STAGES',
                  colors: const [
                    Color(GameConfig.mango),
                    Color(GameConfig.punch),
                  ],
                  onTap: gs.showOperationQuest,
                ),
                const SizedBox(height: 18),
                Text(
                  'QUICK PRACTICE',
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _PracticeTile(
                          '+',
                          'Addition',
                          s.opColor(Operation.addition),
                          width,
                          () => gs.goToPracticeStyle('addition'),
                        ),
                        _PracticeTile(
                          '−',
                          'Subtraction',
                          s.opColor(Operation.subtraction),
                          width,
                          () => gs.goToPracticeStyle('subtraction'),
                        ),
                        _PracticeTile(
                          '×',
                          'Multiplication',
                          s.opColor(Operation.multiplication),
                          width,
                          () => gs.goToPracticeStyle('multiplication'),
                        ),
                        _PracticeTile(
                          '÷',
                          'Division',
                          s.opColor(Operation.division),
                          width,
                          () => gs.goToPracticeStyle('division'),
                        ),
                        _PracticeTile(
                          '?',
                          'Missing Operation',
                          s.opColor(Operation.mixed),
                          width,
                          () => gs.goToPracticeStyle('missingOperation'),
                        ),
                        _PracticeTile(
                          '🧮',
                          'Mixed Operations',
                          s.opColor(Operation.mixed),
                          width,
                          () => gs.goToPracticeStyle('mixed'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCampaign extends StatelessWidget {
  const _PracticeCampaign({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });
  final String icon, title, subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(
                  icon == '🧭'
                      ? Icons.explore_rounded
                      : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .9),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile(
    this.symbol,
    this.label,
    this.color,
    this.width,
    this.onTap,
  );
  final String symbol, label;
  final Color color;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = 112 + ((textScale - 1) * 32).clamp(0.0, 64.0);
    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(color, Colors.white, .16)!,
                    Color.lerp(color, Colors.black, .18)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .26)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    symbol == '🧮'
                        ? const Icon(Icons.calculate_rounded,
                            color: Colors.white, size: 32)
                        : Text(
                            symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
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
