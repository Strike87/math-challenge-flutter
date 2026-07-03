import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';
import '../engine/game_state.dart';
import '../models/celebration.dart';
import '../services/settings.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.state,
    required this.settings,
  });

  final GameState state;
  final SettingsService settings;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confettiController;
  Timer? _hideTimer;
  int _lastEventId = 0;
  bool _showBadge = false;
  CelebrationEvent _event = const CelebrationEvent.none();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 950),
    );
  }

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.state.celebration;
    if (next.isActive && next.id != _lastEventId) {
      _lastEventId = next.id;
      _play(next);
    }
    if (!_confettiAllowed &&
        _confettiController.state == ConfettiControllerState.playing) {
      _confettiController.stop();
    }
  }

  bool get _confettiAllowed =>
      !widget.settings.reduceMotion && !widget.settings.lowPerf;

  void _play(CelebrationEvent event) {
    _hideTimer?.cancel();
    setState(() {
      _event = event;
      _showBadge = true;
    });

    if (_confettiAllowed && _usesConfetti(event.kind)) {
      _confettiController.play();
    }

    _hideTimer = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) {
        setState(() => _showBadge = false);
      }
    });
  }

  bool _usesConfetti(CelebrationKind kind) {
    return switch (kind) {
      CelebrationKind.none => false,
      CelebrationKind.reward => true,
      CelebrationKind.achievement => true,
      CelebrationKind.stageClear => true,
      CelebrationKind.bossClear => true,
      CelebrationKind.win => true,
      CelebrationKind.perfect => true,
    };
  }

  List<Color> _colorsFor(CelebrationKind kind) {
    final base = [
      const Color(GameConfig.coral),
      const Color(GameConfig.mango),
      const Color(GameConfig.mint),
      const Color(GameConfig.sky),
      const Color(GameConfig.punch),
    ];
    return switch (kind) {
      CelebrationKind.perfect => [
          const Color(GameConfig.mango),
          Colors.white,
          const Color(GameConfig.mint),
          const Color(GameConfig.sky),
        ],
      CelebrationKind.bossClear => [
          const Color(GameConfig.punch),
          const Color(GameConfig.mango),
          const Color(GameConfig.coral),
          Colors.white,
        ],
      CelebrationKind.stageClear => [
          const Color(GameConfig.mint),
          const Color(GameConfig.mango),
          const Color(GameConfig.sky),
          Colors.white,
        ],
      _ => base,
    };
  }

  int _particlesFor(CelebrationKind kind) {
    return switch (kind) {
      CelebrationKind.reward => 14,
      CelebrationKind.achievement => 18,
      CelebrationKind.stageClear => 24,
      CelebrationKind.bossClear => 30,
      CelebrationKind.win => 26,
      CelebrationKind.perfect => 34,
      CelebrationKind.none => 0,
    };
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_event.isActive && !_showBadge) {
      return const Positioned.fill(child: SizedBox.shrink());
    }

    final fadeDuration = widget.settings.duration(180);
    final popDuration = widget.settings.duration(260);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_confettiAllowed)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.055,
                  numberOfParticles: _particlesFor(_event.kind),
                  minBlastForce: 8,
                  maxBlastForce: 24,
                  gravity: 0.22,
                  shouldLoop: false,
                  colors: _colorsFor(_event.kind),
                ),
              ),
            AnimatedOpacity(
              opacity: _showBadge ? 1 : 0,
              duration: fadeDuration,
              child: AnimatedScale(
                scale: _showBadge ? 1 : 0.86,
                duration: popDuration,
                curve: Curves.easeOutBack,
                child: _CelebrationBadge(event: _event),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationBadge extends StatelessWidget {
  const _CelebrationBadge({required this.event});

  final CelebrationEvent event;

  @override
  Widget build(BuildContext context) {
    if (!event.isActive) return const SizedBox.shrink();

    final badgeBg = Colors.white.withValues(alpha: 0.96);
    final borderColor = const Color(GameConfig.mango).withValues(alpha: 0.65);
    final shadowColor = Colors.black.withValues(alpha: 0.18);

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(event.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              event.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(GameConfig.textLight),
                fontWeight: FontWeight.w900,
                fontSize: 17,
                height: 1.08,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
