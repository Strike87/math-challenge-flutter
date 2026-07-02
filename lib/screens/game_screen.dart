import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_state.dart';
import '../game_config.dart';
import '../models/enums.dart';
import '../services/settings.dart';
import '../widgets/common.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    final rt = gs.rt;

    return SafeArea(
      child: _ScreenShake(
        tick: gs.screenShakeTick,
        enabled: !s.reduceMotion,
        duration: s.duration(500),
        child: Stack(
          children: [
            // ===== Original screen content =====
            Column(
              children: [
                _GameTopBar(
                  gs: gs,
                  s: s,
                  label: _modeLabel(gs),
                  color: _modeColor(gs),
                ),

                // Scorecards + boss
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _ScorecardsRow(
                            gs: gs,
                            s: s,
                            timerReserve: rt.timer == null ? 0 : 56,
                          ),
                          if (rt.timer != null)
                            Positioned(
                              right: 0,
                              top: 10,
                              child: _TimerCircle(gs: gs, s: s),
                            ),
                        ],
                      ),
                      _ScoreProgress(gs: gs, s: s),
                    ],
                  ),
                ),

                // Mode-specific widgets
                if (gs.mode == GameMode.survival &&
                    gs.rt.challenge != Operation.dailyBoss)
                  _LivesRow(gs: gs, s: s),
                if (gs.mode == GameMode.combo) _ComboMeter(gs: gs, s: s),

                // Power-up HUD
                if (_shouldShowPowerUpHud(gs))
                  _PowerUpHud(gs: gs, pid: rt.activePlayer, s: s),

                // Question card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _QuestionCard(gs: gs, s: s),
                        const SizedBox(height: 16),
                        _AnswersGrid(gs: gs, s: s),
                        const SizedBox(height: 12),
                        if (gs.reactionPill.isNotEmpty)
                          _ReactionPill(text: gs.reactionPill, s: s),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(GameState gs) {
    if (gs.rt.challenge == Operation.master) return '🏆 Master';
    if (gs.rt.challenge == Operation.dailyBoss) return '🐲 Daily Boss';
    return gs.mode.label;
  }

  Color _modeColor(GameState gs) {
    if (gs.rt.challenge == Operation.master)
      return const Color(GameConfig.mango);
    if (gs.rt.challenge == Operation.dailyBoss)
      return const Color(GameConfig.punch);
    switch (gs.mode) {
      case GameMode.blitz:
        return const Color(GameConfig.mango);
      case GameMode.death:
        return const Color(GameConfig.punch);
      case GameMode.survival:
        return const Color(GameConfig.mint);
      case GameMode.combo:
        return const Color(GameConfig.coral);
      default:
        return const Color(GameConfig.sky);
    }
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.text, required this.s});

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

class _ScreenShake extends StatelessWidget {
  const _ScreenShake({
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

class _GameTopBar extends StatelessWidget {
  const _GameTopBar({
    required this.gs,
    required this.s,
    required this.label,
    required this.color,
  });

  final GameState gs;
  final SettingsService s;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rt = gs.rt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: s.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _QuitPill(onPressed: gs.showQuitConfirm),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModeBadge(label: label.toUpperCase(), color: color),
                    if (rt.comboMultiplier > 1.0 &&
                        gs.mode != GameMode.combo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(GameConfig.mango),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '⚡ ×${rt.comboMultiplier.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuitPill extends StatelessWidget {
  const _QuitPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(GameConfig.punch).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(GameConfig.punch).withValues(alpha: 0.28),
              width: 1.8,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded,
                  color: Color(GameConfig.punch), size: 24),
              SizedBox(width: 5),
              Text(
                'Quit',
                style: TextStyle(
                  color: Color(GameConfig.punch),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  fontFamily: AppFonts.head,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _timerRemainingMs(GameState gs) {
  final rt = gs.rt;
  if (rt.timerDurationMs <= 0 || rt.timerStart <= 0) return 0;
  final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
  return (rt.timerDurationMs - elapsed).clamp(0, rt.timerDurationMs).toInt();
}

double _timerPct(GameState gs) {
  final duration = gs.rt.timerDurationMs;
  if (duration <= 0) return 0;
  return (_timerRemainingMs(gs) / duration).clamp(0.0, 1.0);
}

bool _timerWarning(GameState gs) {
  final remaining = _timerRemainingMs(gs);
  final threshold =
      gs.mode == GameMode.blitz || gs.mode == GameMode.combo ? 5000 : 3000;
  return remaining <= threshold && remaining > 0;
}

class _WarningPulse extends StatefulWidget {
  const _WarningPulse({
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
  State<_WarningPulse> createState() => _WarningPulseState();
}

class _WarningPulseState extends State<_WarningPulse>
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
  void didUpdateWidget(covariant _WarningPulse oldWidget) {
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

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final remainingMs = _timerRemainingMs(gs);
    final seconds = (remainingMs / 1000).ceil();
    final danger = _timerWarning(gs);
    final effectsEnabled = danger && !s.lowPerf && !s.reduceMotion;
    return _WarningPulse(
      active: danger,
      effectsEnabled: effectsEnabled,
      duration: s.duration(1000),
      builder: (context, pulseOpacity) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (danger)
              Positioned.fill(
                left: -6,
                right: -6,
                top: -6,
                bottom: -6,
                child: Opacity(
                  opacity: pulseOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          const Color(GameConfig.punch).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Opacity(
              opacity: pulseOpacity,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFFF0F3)
                      : const Color(0xFFE8F7FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: danger
                        ? const Color(GameConfig.punch)
                        : const Color(GameConfig.sky),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (danger
                              ? const Color(GameConfig.punch)
                              : const Color(GameConfig.sky))
                          .withValues(alpha: danger ? 0.32 : 0.20),
                      blurRadius: danger ? 22 : 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  seconds.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: danger
                        ? const Color(GameConfig.punch)
                        : const Color(0xFF0098E5),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    fontFamily: AppFonts.head,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuestionTimerBar extends StatelessWidget {
  const _QuestionTimerBar({required this.gs, required this.s});

  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    if (gs.rt.timerDurationMs <= 0) return const SizedBox.shrink();
    final value = _timerPct(gs);
    final danger = _timerWarning(gs);
    final colors = danger
        ? const [Color(GameConfig.punch), Color(GameConfig.coral)]
        : const [Color(GameConfig.sky), Color(GameConfig.mint)];

    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: s.surface2.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: s.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: danger ? 0.50 : 0.40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreProgress extends StatelessWidget {
  const _ScoreProgress({required this.gs, required this.s});

  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final isBoss = gs.rt.challenge == Operation.dailyBoss;
    final isStandard = gs.mode == GameMode.standard &&
        gs.rt.challenge != Operation.master &&
        gs.rt.challenge != Operation.dailyBoss;
    if (!isBoss && !isStandard) return const SizedBox(height: 8);

    final current = isBoss ? gs.rt.dailyBossProgress : gs.p[1].correct;
    final target = isBoss
        ? (gs.rt.dailyBoss?.goal ?? 1)
        : (gs.rt.maxTurns == 99999 ? gs.questionCount : gs.rt.maxTurns);
    final clampedTarget = target <= 0 ? 1 : target;
    final value = (current / clampedTarget).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(GameConfig.coral),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('0', style: _progressLabelStyle(s)),
              const Spacer(),
              Text('$current', style: _progressLabelStyle(s)),
              const Spacer(),
              Text('$clampedTarget', style: _progressLabelStyle(s)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _progressLabelStyle(SettingsService s) {
    return TextStyle(
      color: s.muted,
      fontSize: 16,
      fontWeight: FontWeight.w900,
      fontFamily: AppFonts.head,
    );
  }
}

class _ScorecardsRow extends StatelessWidget {
  const _ScorecardsRow({
    required this.gs,
    required this.s,
    required this.timerReserve,
  });
  final GameState gs;
  final SettingsService s;
  final double timerReserve;

  @override
  Widget build(BuildContext context) {
    final isMaster = gs.rt.challenge == Operation.master;
    final isBoss = gs.rt.challenge == Operation.dailyBoss;
    final playerOne =
        _PlayerCard(gs: gs, pid: 1, active: gs.rt.activePlayer == 1);

    if (isMaster || isBoss) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth <= 560;
          final bossCircle = _BossCircle(gs: gs);
          final info = _MasterInfo(gs: gs, s: s);

          if (narrow) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: timerReserve),
                  child: Row(
                    children: [
                      bossCircle,
                      const SizedBox(width: 8),
                      Expanded(child: playerOne),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.center, child: info),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(right: timerReserve),
            child: Row(
              children: [
                bossCircle,
                const SizedBox(width: 8),
                Expanded(child: playerOne),
                const SizedBox(width: 8),
                Expanded(child: info),
              ],
            ),
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.only(right: timerReserve),
      child: Row(
        children: [
          Expanded(child: playerOne),
          if (gs.players == 2) ...[
            const SizedBox(width: 8),
            Expanded(
              child:
                  _PlayerCard(gs: gs, pid: 2, active: gs.rt.activePlayer == 2),
            ),
          ],
        ],
      ),
    );
  }
}

class _BossCircle extends StatefulWidget {
  const _BossCircle({required this.gs});

  final GameState gs;

  @override
  State<_BossCircle> createState() => _BossCircleState();
}

class _BossCircleState extends State<_BossCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsService>();
    final effectsEnabled = !s.reduceMotion && !s.lowPerf;
    if (effectsEnabled) {
      if (!_float.isAnimating) _float.repeat();
    } else {
      _float.stop();
      _float.value = 0;
    }

    final gs = widget.gs;
    final isMaster = gs.rt.challenge == Operation.master;
    final normalIcon = isMaster
        ? (gs.currentMasterLevel?.boss ?? '🦍')
        : (gs.rt.dailyBoss?.icon ?? gs.dailyBoss?.icon ?? '🐲');
    final icon = gs.rt.bossMood == 'wrong' ? '👾' : normalIcon;
    final circle = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(GameConfig.punch).withValues(alpha: 0.15),
          border: Border.all(color: const Color(GameConfig.punch), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(GameConfig.punch).withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
        ));

    return AnimatedBuilder(
      animation: _float,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(
            '${gs.rt.bossMood}-${gs.rt.totalTurns}-${gs.rt.selectedAnswer}'),
        tween: Tween(
            begin: 0,
            end:
                (gs.rt.bossMood == 'hit' || gs.rt.bossMood == 'wrong') ? 1 : 0),
        duration: s.duration(450),
        curve: Curves.easeOut,
        child: circle,
        builder: (_, t, child) {
          if (!effectsEnabled ||
              (gs.rt.bossMood != 'hit' && gs.rt.bossMood != 'wrong')) {
            return child!;
          }
          final dx = math.sin(t * math.pi * 8) * (1 - t) * 8;
          final rot = math.sin(t * math.pi * 8) * (1 - t) * 0.08;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(angle: rot, child: child),
          );
        },
      ),
      builder: (_, child) {
        final dy =
            effectsEnabled ? math.sin(_float.value * math.pi * 2) * -4.5 : 0.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard(
      {required this.gs, required this.pid, required this.active});
  final GameState gs;
  final int pid;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final pl = gs.p[pid];
    final s = context.watch<SettingsService>();
    final activePowerUps = [
      if (pl.doubleActive) '✨',
      if (pl.shieldActive) '🛡️',
    ];
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: active ? 1 : 0.96,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: active ? 1 : 0.65,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? const Color(GameConfig.coral) : s.border,
              width: active ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(GameConfig.coral).withValues(alpha: 0.24)
                    : s.border.withValues(alpha: 0.75),
                blurRadius: active ? 16 : 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (active)
                Positioned(
                  top: -13,
                  left: -15,
                  right: -15,
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(GameConfig.coral),
                          Color(GameConfig.mango),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Stack(
                    children: [
                      AvatarWidget(avatar: pl.avatar, size: 38),
                      if (pl.streak >= 3)
                        Positioned(
                          right: -6,
                          bottom: -4,
                          child: StreakFire(streak: pl.streak, size: 12),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pl.name,
                          style: TextStyle(
                            color: s.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${pl.score}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(GameConfig.coral),
                            fontFamily: AppFonts.head,
                            height: 1,
                          ),
                        ),
                        if (activePowerUps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: activePowerUps
                                  .map(
                                    (icon) => Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: _ActivePlayerPowerUpIcon(
                                        icon: icon,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePlayerPowerUpIcon extends StatelessWidget {
  const _ActivePlayerPowerUpIcon({
    required this.icon,
  });

  final String icon;

  @override
  Widget build(BuildContext context) {
    final isShield = icon == '🛡️';
    final child = SizedBox(
      key: isShield ? const Key('player-card-shield-active') : null,
      width: 22,
      height: 22,
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 15, height: 1)),
      ),
    );
    return child;
  }
}

class _MasterInfo extends StatelessWidget {
  const _MasterInfo({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final isBoss = gs.rt.challenge == Operation.dailyBoss;
    final lives = isBoss ? gs.rt.dailyBossLives : gs.masterLives;
    final stageIdx =
        gs.masterLevel.clamp(0, GameConfig.masterLevels.length - 1);
    final masterGoal = GameConfig.masterLevels[stageIdx].goal;
    final progress = isBoss
        ? '${gs.rt.dailyBossProgress}/${gs.rt.dailyBoss?.goal ?? 0}'
        : '${gs.masterProgress}/$masterGoal';
    final stageLabel = isBoss ? 'Boss Battle' : 'Stage ${stageIdx + 1}';
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E0), Color(0xFFFFF0C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(GameConfig.mango).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(GameConfig.mango).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '♥' * (lives < 0 ? 0 : lives),
                style: const TextStyle(
                  color: Color(GameConfig.coral),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stageLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: s.muted,
                ),
              ),
            ],
          ),
          Text(
            progress,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(GameConfig.mango),
              fontFamily: AppFonts.head,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final isBoss = gs.rt.challenge == Operation.dailyBoss;
    final lives = isBoss ? gs.rt.dailyBossLives : gs.rt.survivalLives;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            '♥' * (lives < 0 ? 0 : lives),
            style: const TextStyle(
              color: Color(GameConfig.coral),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(GameConfig.punch).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isBoss
                  ? 'Boss'
                  : (GameConfig.phaseNames[gs.rt.survivalPhase.clamp(0, 4)]),
              style: const TextStyle(
                color: Color(GameConfig.punch),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboMeter extends StatelessWidget {
  const _ComboMeter({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final streak = gs.rt.comboStreak;
    final pct = (streak / 10 * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Combo Streak',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '×${gs.rt.comboMultiplier.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(GameConfig.coral),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: s.border,
              color: const Color(GameConfig.coral),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerUpHud extends StatelessWidget {
  const _PowerUpHud({required this.gs, required this.pid, required this.s});
  final GameState gs;
  final int pid;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final pl = gs.p[pid];
    final counts = <PowerUp, int>{};
    for (final pu in pl.pups) {
      counts[pu] = (counts[pu] ?? 0) + 1;
    }
    final powerUps = PowerUp.values;

    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: s.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: const Color(GameConfig.mint).withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < powerUps.length; i++) ...[
            Expanded(
              child: Builder(builder: (_) {
                final pu = powerUps[i];
                final count = counts[pu] ?? 0;
                final active = (pu == PowerUp.shield && pl.shieldActive) ||
                    (pu == PowerUp.double && pl.doubleActive);
                final disabled = active ||
                    !gs.rt.accepting ||
                    count == 0 ||
                    gs.isPowerUpBlocked(pu);
                final color = _powerUpColor(pu);
                final tile = GestureDetector(
                  key: pu == PowerUp.shield
                      ? const Key('powerup-shield-button')
                      : null,
                  onTap: disabled ? null : () => gs.usePowerUp(pu),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: active ? 1 : (disabled ? 0.42 : 1),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.64),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  color.withValues(alpha: active ? 0.95 : 0.36),
                              width: active ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                    alpha: active ? 0.32 : 0.15),
                                blurRadius: active ? 16 : 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _powerUpShortLabel(pu),
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  fontFamily: AppFonts.head,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -3,
                        top: -7,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(GameConfig.punch),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(GameConfig.punch)
                                    .withValues(alpha: 0.28),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (pu == PowerUp.shield) {
                  return _ShieldArmedPulse(
                    active: active,
                    s: s,
                    child: tile,
                  );
                }
                return _ActivePowerUpGlow(
                  active: active,
                  s: s,
                  color: color,
                  child: tile,
                );
              }),
            ),
            if (i != powerUps.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

bool _shouldShowPowerUpHud(GameState gs) {
  if (gs.players != 1) return false;
  if (gs.rt.challenge == Operation.master ||
      gs.rt.challenge == Operation.dailyBoss) {
    return false;
  }
  final pl = gs.p[gs.rt.activePlayer];
  return pl.pups.isNotEmpty ||
      pl.shieldActive ||
      pl.doubleActive ||
      gs.rt.frozen;
}

class _ActivePowerUpGlow extends StatelessWidget {
  const _ActivePowerUpGlow({
    required this.active,
    required this.s,
    required this.color,
    required this.child,
  });

  final bool active;
  final SettingsService s;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effectsEnabled = !s.reduceMotion && !s.lowPerf;
    return _WarningPulse(
      active: active,
      effectsEnabled: active && effectsEnabled,
      duration: s.duration(700),
      builder: (_, opacity) {
        final glowOpacity = active ? 0.08 + (opacity * 0.32) : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (active)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: glowOpacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            Opacity(
                opacity: active ? 0.72 + (opacity * 0.28) : 1, child: child),
          ],
        );
      },
    );
  }
}

class _ShieldArmedPulse extends StatelessWidget {
  const _ShieldArmedPulse({
    required this.active,
    required this.s,
    required this.child,
  });

  final bool active;
  final SettingsService s;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final effectsEnabled = !s.reduceMotion && !s.lowPerf;
    return _WarningPulse(
      active: active,
      effectsEnabled: effectsEnabled,
      duration: s.duration(700),
      builder: (_, opacity) {
        final pulse = 1 - opacity;
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  key: const Key('shield-hud-armed-overlay'),
                  opacity: effectsEnabled ? pulse * 0.34 : 0.16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _powerUpShortLabel(PowerUp pu) {
  switch (pu) {
    case PowerUp.time:
      return '+5s';
    case PowerUp.fifty:
      return '50/50';
    case PowerUp.double:
      return '×2';
    case PowerUp.shield:
      return '🛡';
    case PowerUp.freeze:
      return '▮▮';
    case PowerUp.switchOp:
      return '🔀';
  }
}

Color _powerUpColor(PowerUp pu) {
  switch (pu) {
    case PowerUp.time:
      return const Color(GameConfig.sky);
    case PowerUp.fifty:
      return const Color(0xFF8B5CF6);
    case PowerUp.double:
      return const Color(GameConfig.mango);
    case PowerUp.shield:
      return const Color(GameConfig.mint);
    case PowerUp.freeze:
      return const Color(GameConfig.sky);
    case PowerUp.switchOp:
      return const Color(0xFFB45CFF);
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final q = gs.rt.q;
    if (q == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const CircularProgressIndicator(),
      );
    }
    final promptText = _prompt(gs);
    final showCounter = gs.mode != GameMode.blitz &&
        gs.mode != GameMode.combo &&
        gs.rt.challenge != Operation.master &&
        gs.rt.challenge != Operation.dailyBoss;
    final showSkip = ![GameMode.death, GameMode.survival].contains(gs.mode) &&
        gs.rt.challenge != Operation.master &&
        gs.rt.challenge != Operation.dailyBoss;
    final danger = _timerWarning(gs);
    final effectsEnabled = danger && !s.lowPerf && !s.reduceMotion;
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: danger ? const Color(GameConfig.punch) : s.border,
          width: danger ? 2 : 1,
        ),
        boxShadow: [
          if (danger)
            BoxShadow(
              color: const Color(GameConfig.punch).withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final sideWidth = constraints.maxWidth < 310 ? 58.0 : 72.0;
              final headerFont = constraints.maxWidth < 310 ? 12.0 : 13.0;
              return Row(
                children: [
                  SizedBox(
                    width: sideWidth,
                    child: showCounter
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Q ${gs.rt.totalTurns + 1} / ${gs.rt.maxTurns == 99999 ? '∞' : gs.rt.maxTurns}',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: s.muted,
                                fontSize: headerFont,
                                fontWeight: FontWeight.w900,
                                fontFamily: AppFonts.head,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        promptText,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: s.muted,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppFonts.head,
                          height: 1.08,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: sideWidth,
                    child: showSkip
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: gs.skip,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 6),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Skip ⏩',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(GameConfig.sky),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Big question text
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: s.text,
                    fontFamily: AppFonts.head,
                    height: 1.2,
                  ),
                  children: _spans(q.text, s),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mode warning
          if (_modeWarning(gs) != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(GameConfig.punch).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _modeWarning(gs)!,
                style: const TextStyle(
                  color: Color(GameConfig.punch),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _QuestionTimerBar(gs: gs, s: s),
        ],
      ),
    );
    return _WarningPulse(
      active: danger,
      effectsEnabled: effectsEnabled,
      duration: s.duration(1000),
      builder: (context, pulseOpacity) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (danger)
              Positioned.fill(
                left: -5,
                right: -5,
                top: -5,
                bottom: -5,
                child: Opacity(
                  opacity: pulseOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          const Color(GameConfig.punch).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            Opacity(opacity: pulseOpacity, child: card),
          ],
        );
      },
    );
  }

  String _prompt(GameState gs) {
    if (gs.rt.isWarmUp && gs.rt.warmUpCount <= 3)
      return '🌱 Warm-Up • Q ${gs.rt.warmUpCount}/3';
    if (gs.rt.challenge == Operation.master) return 'Solve it!';
    if (gs.rt.challenge == Operation.dailyBoss) return 'Boss Battle!';
    switch (gs.mode) {
      case GameMode.blitz:
        return '⚡ Blitz Mode — answer fast!';
      case GameMode.death:
        return '💀 Streak: ${gs.p[gs.rt.activePlayer].streak}';
      case GameMode.survival:
        return '💪 Q ${gs.rt.totalTurns + 1} • ${GameConfig.phaseNames[gs.rt.survivalPhase.clamp(0, 4)]}';
      case GameMode.combo:
        return '🔥 Combo — Streak: ${gs.rt.comboStreak}';
      default:
        return gs.players == 2
            ? "${gs.p[gs.rt.activePlayer].name}'s Turn"
            : 'Solve it!';
    }
  }

  String? _modeWarning(GameState gs) {
    switch (gs.mode) {
      case GameMode.blitz:
        return '⚡ Answer fast for more points!';
      case GameMode.death:
        return '💀 ONE WRONG = GAME OVER';
      case GameMode.survival:
        return '💪 3 Lives — How far can you go?';
      case GameMode.combo:
        return '🔥 Build your streak for bigger multipliers!';
      default:
        return null;
    }
  }

  List<InlineSpan> _spans(String text, SettingsService s) {
    final parts = text.split('?');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(GameConfig.coral),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFamily: AppFonts.head,
              ),
            ),
          ),
        ));
      }
    }
    return spans;
  }
}

class _AnswersGrid extends StatelessWidget {
  const _AnswersGrid({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final q = gs.rt.q;
    if (q == null) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: q.choices.length,
          itemBuilder: (_, i) {
            final c = q.choices[i];
            final selected = gs.rt.selectedAnswer;
            final revealed = !gs.rt.accepting && selected != null;
            final isCorrectChoice = (c - q.ans).abs() < 1e-9;
            final isSelectedChoice =
                selected != null && (c - selected).abs() < 1e-9;
            final isRightReveal = revealed && isCorrectChoice;
            final isWrongReveal =
                revealed && isSelectedChoice && !isCorrectChoice;
            final fillColor = isRightReveal
                ? const Color(GameConfig.mint)
                : isWrongReveal
                    ? const Color(GameConfig.punch)
                    : s.surface;
            final borderColor = isRightReveal
                ? const Color(GameConfig.mint)
                : isWrongReveal
                    ? const Color(GameConfig.punch)
                    : const Color(GameConfig.coral).withValues(alpha: 0.3);
            final answerTextColor =
                (isRightReveal || isWrongReveal) ? Colors.white : s.text;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: gs.rt.accepting
                    ? () {
                        gs.onAnswer(c);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: s.duration(160),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _fmt(c),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: answerTextColor,
                        fontFamily: AppFonts.head,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        IgnorePointer(
          child: BigEmojiOverlay(
            emoji: gs.bigEmoji,
            visible: gs.bigEmojiVisible && gs.bigEmoji.isNotEmpty,
          ),
        ),
      ],
    );
  }

  String _fmt(num n) {
    if (n == n.roundToDouble()) return '${n.toInt()}';
    return n
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
