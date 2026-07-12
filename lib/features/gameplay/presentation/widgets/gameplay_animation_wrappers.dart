import 'package:flutter/material.dart';

class WarningPulse extends StatefulWidget {
  const WarningPulse({
    super.key,
    required this.active,
    required this.effectsEnabled,
    required this.duration,
    required this.builder,
  });

  final bool active;
  final bool effectsEnabled;
  final Duration duration;
  final Widget Function(BuildContext context, double opacity) builder;

  @override
  State<WarningPulse> createState() => _WarningPulseState();
}

class _WarningPulseState extends State<WarningPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _safeDuration(widget.duration),
    );
    _opacity = _buildOpacity();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WarningPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextDuration = _safeDuration(widget.duration);
    if (_controller.duration != nextDuration) {
      _controller.duration = nextDuration;
      _opacity = _buildOpacity();
    }
    _sync();
  }

  Duration _safeDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return const Duration(milliseconds: 1000);
    }
    return duration;
  }

  Animation<double> _buildOpacity() {
    return Tween<double>(begin: 1, end: 0).animate(_controller);
  }

  void _sync() {
    if (widget.active && widget.effectsEnabled) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
      return;
    }
    _controller.stop();
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity =
            widget.active && widget.effectsEnabled ? _opacity.value : 1.0;
        return widget.builder(context, opacity);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
