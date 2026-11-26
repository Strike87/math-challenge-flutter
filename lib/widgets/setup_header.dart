import 'package:flutter/material.dart';

import '../game_config.dart';
import '../services/settings.dart';
import 'common.dart';
import 'setup_word_fit_text.dart';

class SetupHeader extends StatelessWidget {
  const SetupHeader({
    super.key,
    this.backKey,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.s,
  });

  final Key? backKey;
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
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: backKey,
                borderRadius: BorderRadius.circular(18),
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
                SetupWordFitText(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.headFor(s),
                  ),
                ),
                const SizedBox(height: 2),
                SetupWordFitText(
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
