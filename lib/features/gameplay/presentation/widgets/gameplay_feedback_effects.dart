import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../game_config.dart';
import '../../../../services/settings.dart';

class ReactionPill extends StatelessWidget {
  const ReactionPill({super.key, required this.text, required this.s});

  final String text;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final shield = text == '🛡️ Shield absorbed it!';
    final color =
        shield ? const Color(GameConfig.mint) : const Color(GameConfig.coral);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
    if (!shield || s.reduceMotion || s.lowPerf) return pill;
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: 1),
      duration: s.duration(300),
      curve: const Cubic(0.34, 1.5, 0.64, 1),
      child: pill,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1).toDouble(),
        child: Transform.scale(scale: 0.4 + (0.6 * t), child: child),
      ),
    );
  }
}

class ScreenShake extends StatelessWidget {
  const ScreenShake({
    super.key,
    required this.tick,
    required this.enabled,
    required this.duration,
    required this.child,
  });

  final int tick;
  final bool enabled;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || tick == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(tick),
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      child: child,
      builder: (_, t, child) {
        final dx = math.sin(t * math.pi * 8) * (1 - t) * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
