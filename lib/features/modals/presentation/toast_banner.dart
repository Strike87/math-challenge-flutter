import 'package:flutter/material.dart';

import '../../../game_config.dart';
import '../../../services/settings.dart';
import '../../../widgets/common.dart';

/// Presentation-only renderer for the app's existing queued toast state.
///
/// Message timing, replacement/queue behavior, and reset semantics remain owned
/// by [ToastController] through GameState. This widget only draws the currently
/// visible message.
class AppToastBanner extends StatelessWidget {
  const AppToastBanner({
    super.key,
    required this.message,
    required this.settings,
  });

  final String message;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    const accent = Color(GameConfig.coral);

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              settings.surface.withValues(alpha: settings.dark ? 0.98 : 0.96),
              settings.surface2.withValues(alpha: settings.dark ? 0.95 : 0.90),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: settings.dark ? 0.24 : 0.12,
              ),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: settings.dark ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.20),
                ),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                size: 20,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: settings.text,
                  fontFamily: AppFonts.bodyFor(settings),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final centered = Center(child: card);
    if (settings.reduceMotion || settings.lowPerf) {
      return IgnorePointer(child: centered);
    }

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(message),
        tween: Tween<double>(begin: 0, end: 1),
        duration: settings.duration(200),
        curve: Curves.easeOutCubic,
        child: centered,
        builder: (context, t, child) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -12 * (1 - t)),
              child: Transform.scale(
                scale: 0.97 + (0.03 * t),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
