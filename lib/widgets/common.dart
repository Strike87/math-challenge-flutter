import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/avatars.dart';
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
    final settings = context.watch<SettingsService>();
    final c = settings.accent(color);
    if (outlined) {
      return _PressableScale(
        onPressed: onPressed,
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withValues(alpha: 0.75), width: 1.5),
          ),
          child: DefaultTextStyle(
            style: _labelStyle(c),
            child: IconTheme(
              data: IconThemeData(color: c, size: fontSize + 2),
              child: _content(),
            ),
          ),
        ),
      );
    }
    return _PressableScale(
      onPressed: onPressed,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c, _gradientEnd(c)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFFB42814).withValues(alpha: 0.20),
              blurRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: _labelStyle(textColor),
          child: IconTheme(
            data: IconThemeData(color: textColor, size: fontSize + 2),
            child: _content(),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(Color color) {
    return TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: fontSize,
      fontFamily: AppFonts.head,
      letterSpacing: 0.5,
      height: 1.05,
    );
  }

  Color _gradientEnd(Color c) {
    if (color == GameConfig.coral) return const Color(0xFFD4681A);
    return Color.lerp(c, Colors.black, 0.18) ?? c;
  }

  Widget _content() {
    if (icon == null) {
      return Text(
        label,
        maxLines: 1,
        softWrap: false,
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: fontSize + 2),
      const SizedBox(width: 8),
      Text(label, maxLines: 1, softWrap: false),
    ]);
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    required this.onPressed,
  });

  final Widget child;
  final VoidCallback onPressed;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: settings.duration(180),
          curve: const Cubic(0.4, 0, 0.2, 1),
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0, 0.04) : Offset.zero,
            duration: settings.duration(180),
            curve: const Cubic(0.4, 0, 0.2, 1),
            child: widget.child,
          ),
        ),
      ),
    );
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
      return Text(
        avatar as String,
        style: TextStyle(fontSize: size * 0.8),
      );
    }
    if (avatar is AvatarCustom) {
      final a = avatar as AvatarCustom;
      final bgColor = a.color == null ? null : _parseColor(a.color!);
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (bgColor != null)
              Container(
                width: size * 0.86,
                height: size * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor.withValues(alpha: 0.26),
                  border: Border.all(
                    color: bgColor.withValues(alpha: 0.58),
                    width: size * 0.035,
                  ),
                ),
              ),
            Text(a.base, style: TextStyle(fontSize: size * 0.7)),
            if (a.hat.isNotEmpty)
              Positioned(
                top: -size * 0.05,
                child: Text(a.hat, style: TextStyle(fontSize: size * 0.35)),
              ),
            if (a.accessory.isNotEmpty)
              Positioned(
                bottom: size * 0.05,
                child:
                    Text(a.accessory, style: TextStyle(fontSize: size * 0.3)),
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
        Text(
          '$coins',
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
      child: Text(
        label,
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
    int count = streak >= 10
        ? 3
        : streak >= 5
            ? 2
            : 1;
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
    final settings = context.watch<SettingsService>();
    if (settings.reduceMotion) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      key: ValueKey('$emoji-$visible'),
      tween: Tween<double>(
        begin: visible ? 0.5 : 1.15,
        end: visible ? 1.15 : 0.5,
      ),
      duration: settings.duration(350),
      curve: const Cubic(0.2, 0.9, 0.3, 1),
      builder: (context, scale, child) {
        return AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: settings.duration(350),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 96,
          height: 1,
          shadows: [
            Shadow(
              color: Color(0x55FF5757),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
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
    this.borderRadius = 28,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final radius = BorderRadius.circular(borderRadius);
    Widget surface = Container(
      decoration: BoxDecoration(
        color: color ??
            (settings.dark ? const Color(0xBF1E1A16) : const Color(0xB8FFFFFF)),
        borderRadius: radius,
        border: Border.all(
          color: settings.dark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.88),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: settings.dark ? 0.35 : 0.09),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (settings.lowPerf) return surface;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: surface,
      ),
    );
  }
}

// ============================================================================
// AVATAR PICKER
// ============================================================================

/// A full-screen modal dialog that lets the user pick an avatar emoji.
///
/// Usage:
/// ```dart
/// final selected = await showDialog<String>(
///   context: context,
///   builder: (_) => const AvatarPickerDialog(currentAvatar: '🐶'),
/// );
/// if (selected != null) {
///   // Save to player profile / settings
///   setState(() => myAvatar = selected);
/// }
/// ```
class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({
    super.key,
    this.currentAvatar,
    this.availableAvatars,
  });

  /// Currently selected avatar (highlighted in the grid).
  final String? currentAvatar;
  final List<String>? availableAvatars;

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<AvatarCategory> _categories;

  @override
  void initState() {
    super.initState();
    final allowed = widget.availableAvatars?.toSet();
    final categories = allowed == null
        ? AvatarPool.categories
        : AvatarPool.categories
            .map((category) => AvatarCategory(
                  name: category.name,
                  emojis: category.emojis
                      .where((e) => allowed.contains(e))
                      .toList(),
                ))
            .where((category) => category.emojis.isNotEmpty)
            .toList();
    _categories = categories.isEmpty
        ? const [
            AvatarCategory(name: 'Original', emojis: AvatarPool.originals),
          ]
        : categories;
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final radius = BorderRadius.circular(28);
    final content = Container(
      decoration: BoxDecoration(
        color: settings.surface,
        borderRadius: radius,
        border: Border.all(
          color: settings.dark
              ? settings.border
              : Colors.white.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(GameConfig.coral),
                    Color(GameConfig.mango),
                    Color(GameConfig.sky),
                    Color(GameConfig.mint),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pick your avatar',
                      style: TextStyle(
                        color: settings.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.head,
                        height: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: settings.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: settings.surface2
                    .withValues(alpha: settings.dark ? 0.85 : 0.70),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: settings.muted,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(GameConfig.coral),
                      Color(0xFFD4681A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: AppFonts.head,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: AppFonts.head,
                  fontSize: 13,
                ),
                tabs: _categories.map((c) => Tab(text: c.name)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: category.emojis.length,
                    itemBuilder: (_, i) {
                      final emoji = category.emojis[i];
                      final isSelected = emoji == widget.currentAvatar;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(emoji),
                        child: AnimatedContainer(
                          duration: settings.duration(180),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(GameConfig.coral)
                                    .withValues(alpha: 0.15)
                                : settings.surface2.withValues(
                                    alpha: settings.dark ? 0.9 : 0.72),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(GameConfig.coral)
                                  : Colors.white.withValues(alpha: 0.68),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                        ? const Color(GameConfig.coral)
                                        : Colors.black)
                                    .withValues(
                                        alpha: isSelected ? 0.18 : 0.05),
                                blurRadius: isSelected ? 12 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    final wrapped = settings.lowPerf
        ? content
        : ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: content,
            ),
          );

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: wrapped,
    );
  }
}

/// Compact avatar selector tile — for use inside a settings screen.
///
/// Shows the current avatar with a "Change" button. Tapping opens
/// [AvatarPickerDialog] and calls [onChanged] with the new emoji.
///
/// Usage:
/// ```dart
/// AvatarSelectorTile(
///   currentAvatar: myAvatar,
///   onChanged: (emoji) {
///     setState(() => myAvatar = emoji);
///     Storage.setString('mc_avatar', emoji);
///   },
/// )
/// ```
class AvatarSelectorTile extends StatelessWidget {
  const AvatarSelectorTile({
    super.key,
    required this.currentAvatar,
    required this.onChanged,
    this.label = 'Avatar',
    this.availableAvatars,
  });

  final String currentAvatar;
  final ValueChanged<String> onChanged;
  final String label;
  final List<String>? availableAvatars;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(GameConfig.coral).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(currentAvatar, style: const TextStyle(fontSize: 28)),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontFamily: AppFonts.body,
        ),
      ),
      subtitle: const Text('Tap to change'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (_) => AvatarPickerDialog(
            currentAvatar: currentAvatar,
            availableAvatars: availableAvatars,
          ),
        );
        if (selected != null && selected != currentAvatar) {
          onChanged(selected);
        }
      },
    );
  }
}
