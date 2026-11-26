import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_state.dart';
import '../game_config.dart';
import '../services/settings.dart';
import '../widgets/common.dart';
import '../widgets/setup_header.dart';
import '../widgets/setup_word_fit_text.dart';

class PracticeStyleScreen extends StatelessWidget {
  const PracticeStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final settings = context.watch<SettingsService>();
    final isTrainingArena = state.setupWeakSkillsPlan != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SetupHeader(
                  backKey: const Key('practice-style-back'),
                  s: settings,
                  onBack: state.cancelPracticeStyle,
                  title: isTrainingArena
                      ? 'Training Arena'
                      : 'Choose Practice Style',
                  subtitle: isTrainingArena
                      ? 'Pick how you want to train'
                      : 'Pick how you want to practice',
                ),
                const SizedBox(height: 20),
                SetupWordFitText(
                  'CHOOSE YOUR STYLE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: settings.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _StyleCard(
                  title: 'Timing Practice',
                  description:
                      'Sharpen your speed with the classic timed challenge.',
                  icon: Icons.timer_outlined,
                  color: GameConfig.coral,
                  buttonKey: const Key('timing-practice-button'),
                  onPressed: state.startTimingPractice,
                ),
                const SizedBox(height: 14),
                _StyleCard(
                  title: 'IQ Spark',
                  description: isTrainingArena
                      ? 'Momentum-driven focused practice.'
                      : 'Focus on clear, steady practice at your own pace.',
                  icon: Icons.psychology_alt_outlined,
                  color: GameConfig.sky,
                  buttonKey: const Key('mental-math-button'),
                  onPressed: isTrainingArena
                      ? state.startMentalMathWeakSkillsPractice
                      : state.startMentalMathFreePractice,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard(
      {required this.title,
      required this.description,
      required this.icon,
      required this.color,
      required this.buttonKey,
      required this.onPressed});

  final String title;
  final String description;
  final IconData icon;
  final int color;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final accent = settings.accent(color);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: settings.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, color: accent, size: 30),
          const SizedBox(height: 8),
          SetupWordFitText(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: settings.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  fontFamily: AppFonts.headFor(settings))),
          const SizedBox(height: 4),
          SetupWordFitText(description,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: settings.muted, fontSize: 12, height: 1.3)),
          const SizedBox(height: 14),
          NeoButton(
              key: buttonKey,
              label: 'Choose $title',
              color: color,
              onPressed: onPressed),
        ],
      ),
    );
  }
}
