import 'package:flutter/material.dart';

import '../../../../features/weak_skills/domain/weak_skills_policy.dart';
import '../../../../game_config.dart';
import '../../../../models/enums.dart';
import '../../../../services/settings.dart';
import '../../../../widgets/common.dart';

class OverallMasteryCard extends StatelessWidget {
  const OverallMasteryCard({
    super.key,
    required this.settings,
    required this.masteryPercent,
  });

  final SettingsService settings;
  final double masteryPercent;

  @override
  Widget build(BuildContext context) {
    final value = masteryPercent.clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: settings.surface2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: settings.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: settings.dark ? 0.18 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${value.round()}%',
            style: TextStyle(
              color: settings.text,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.headFor(settings),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overall Mastery',
            style: TextStyle(
              color: settings.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 12,
              backgroundColor: settings.border.withValues(alpha: 0.45),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(GameConfig.mint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkillMasteryCard extends StatelessWidget {
  const SkillMasteryCard({
    super.key,
    required this.settings,
    required this.symbol,
    required this.label,
    required this.masteryPercent,
    required this.accentColor,
  });

  final SettingsService settings;
  final String symbol;
  final String label;
  final double masteryPercent;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final value = masteryPercent.clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: settings.border, width: 1.25),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: settings.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${value.round()}%',
                      style: TextStyle(
                        color: settings.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 9,
                    backgroundColor: settings.border.withValues(alpha: 0.45),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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

class WeakSkillsRecommendationCard extends StatelessWidget {
  const WeakSkillsRecommendationCard({
    super.key,
    required this.settings,
    required this.plan,
    required this.onTap,
  });

  final SettingsService settings;
  final WeakSkillsPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final focusText = plan.focusedOperations.map(_operationName).join(' and ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('skill-dashboard-weak-skills-recommendation'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7C3AED),
                Color(0xFFDB2777),
                Color(GameConfig.coral),
              ],
            ),
          ),
          child: Row(
            children: [
              const Text(
                '\u{1F9E0}+',
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.isFallback
                          ? 'Build Your Practice Profile'
                          : 'Recommended Practice',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Build Your Skills',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.isFallback
                          ? 'Practice all four operations to personalize your recommendations.'
                          : 'Focus on $focusText',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _operationName(Operation operation) {
  return switch (operation) {
    Operation.addition => 'Addition',
    Operation.subtraction => 'Subtraction',
    Operation.multiplication => 'Multiplication',
    Operation.division => 'Division',
    _ => operation.label,
  };
}
