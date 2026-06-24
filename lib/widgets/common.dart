import 'package:flutter/material.dart';
import '../game_config.dart';
import '../models/player.dart';
import '../services/settings.dart';

/// Helper widgets shared across screens.

class NeoButton extends StatelessWidget {
  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = GameConfig.coral,
    this.textColor = Colors.white,
    this.icon,
    this.outlined = false,
    this.padding,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback onPressed;
  final int color;
  final Color textColor;
  final IconData? icon;
  final bool outlined;
  final EdgeInsets? padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c, width: 2),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _content(),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        foregroundColor: textColor,
        elevation: 0,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _content(),
    );
  }

  Widget _content() {
    if (icon == null) {
      return Text(label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          fontFamily: AppFonts.body,
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: fontSize + 2),
      const SizedBox(width: 8),
      Text(label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          fontFamily: AppFonts.body,
        ),
      ),
    ]);
  }
}

class AppFonts {
  static const String head = 'Baloo2';
  static const String body = 'PlusJakartaSans';
}

/// Renders an avatar — either an emoji string or a [AvatarCustom] stack.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({super.key, required this.avatar, this.size = 48});
  final Object avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatar is String) {
      return Text(avatar as String,
        style: TextStyle(fontSize: size * 0.8),
      );
    }
    if (avatar is AvatarCustom) {
      final a = avatar as AvatarCustom;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(a.base, style: TextStyle(fontSize: size * 0.7)),
            if (a.color != null)
              Text(a.base,
                style: TextStyle(
                  fontSize: size * 0.7,
                  color: _parseColor(a.color!),
                  foreground: Paint()..color = _parseColor(a.color!),
                ),
              ),
            if (a.hat.isNotEmpty)
              Positioned(
                top: -size * 0.05,
                child: Text(a.hat, style: TextStyle(fontSize: size * 0.35)),
              ),
            if (a.accessory.isNotEmpty)
              Positioned(
                bottom: size * 0.05,
                child: Text(a.accessory, style: TextStyle(fontSize: size * 0.3)),
              ),
          ],
        ),
      );
    }
    return Text('🐶', style: TextStyle(fontSize: size * 0.8));
  }

  Color _parseColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return Colors.transparent;
  }
}

/// Coin counter pill.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins, required this.settings});
  final int coins;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(GameConfig.coin).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(GameConfig.coin), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🪙', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text('$coins',
          style: TextStyle(
            color: settings.text,
            fontWeight: FontWeight.w800,
            fontFamily: AppFonts.body,
          ),
        ),
      ]),
    );
  }
}

/// Mode badge chip shown on game screen.
class ModeBadge extends StatelessWidget {
  const ModeBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Streak fire emoji shown next to player avatars.
class StreakFire extends StatelessWidget {
  const StreakFire({super.key, required this.streak, this.size = 16});
  final int streak;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (streak < 3) return const SizedBox.shrink();
    int count = streak >= 10 ? 3 : streak >= 5 ? 2 : 1;
    return Text('🔥' * count, style: TextStyle(fontSize: size));
  }
}

/// Big emoji feedback overlay shown briefly after answering.
class BigEmojiOverlay extends StatelessWidget {
  const BigEmojiOverlay({
    super.key,
    required this.emoji,
    required this.visible,
  });
  final String emoji;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Text(emoji,
        style: const TextStyle(fontSize: 96),
      ),
    );
  }
}

/// Reusable card surface.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = 22,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
