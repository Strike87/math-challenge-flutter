import 'dart:math';
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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  String? _feedbackEmoji;
  bool _feedbackShowing = false;

 // Emoji pools — randomly chosen per answer to add variety.
  // Expanded from the original HTML game's CORRECT_RX / WRONG_RX arrays
  // plus extras for more variety on long play sessions.
  static const _correctEmojis = <String>[
    // From original HTML CORRECT_RX:
    '🎉', '🥳', '🤩', '👍', '💯', '⭐', '🔥',
    // Added for variety:
    '😊', '✨', '💪', '🌟', '⚡', '🏆', '👏',
    '🎊', '😎', '🙌', '😃', '🚀', '🌈',
  ];
  static const _wrongEmojis = <String>[
    // From original HTML WRONG_RX:
    '🙈', '😥', '🤔', '😕', '😬',
    // Added for variety:
    '😢', '💥', '👎', '😞', '😔', '😫', '💔',
    '😤', '🙊', '😒', '😴', '🤦', '🤷',
  ];

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  /// Called from answer button taps — fires the emoji pop animation.
  void _showFeedback(bool correct) {
    final pool = correct ? _correctEmojis : _wrongEmojis;
    final emoji = pool[Random().nextInt(pool.length)];

    setState(() {
      _feedbackEmoji = emoji;
      _feedbackShowing = true;
    });
    _popController.forward(from: 0);

    // Auto-hide after the animation finishes (~900ms total visible time).
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _feedbackShowing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final s = context.watch<SettingsService>();
    final rt = gs.rt;
    final pl = gs.p[rt.activePlayer];

    return SafeArea(
      child: Stack(
        children: [
          // ===== Original screen content =====
          Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: gs.showQuitConfirm,
                    ),
                    ModeBadge(
                      label: _modeLabel(gs),
                      color: _modeColor(gs),
                    ),
                    if (rt.comboMultiplier > 1.0 && gs.mode != GameMode.combo)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(GameConfig.mango),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('⚡ ×${rt.comboMultiplier.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (rt.timer != null && gs.mode != GameMode.blitz && gs.mode != GameMode.combo)
                      _TimerCircle(gs: gs, s: s),
                  ],
                ),
              ),

              // Scorecards + boss
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _ScorecardsRow(gs: gs, s: s),
              ),

              // Mode-specific widgets
              if (gs.mode == GameMode.survival || gs.rt.challenge == Operation.dailyBoss)
                _LivesRow(gs: gs, s: s),
              if (gs.mode == GameMode.combo)
                _ComboMeter(gs: gs, s: s),

              // Power-up HUD
              if (pl.pups.isNotEmpty && gs.players == 1)
                _PowerUpHud(gs: gs, pid: rt.activePlayer, s: s),

              // Question card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _QuestionCard(gs: gs, s: s),
                      const SizedBox(height: 16),
                      _AnswersGrid(gs: gs, s: s, onAnswered: _showFeedback),
                      const SizedBox(height: 12),
                      if (gs.reactionPill.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(GameConfig.coral).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(gs.reactionPill,
                            style: const TextStyle(
                              color: Color(GameConfig.coral),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ===== Emoji feedback overlay =====
          if (_feedbackShowing && _feedbackEmoji != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _popController,
                    builder: (_, __) {
                      return Opacity(
                        opacity: _opacityAnim.value,
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _feedbackEmoji!,
                                style: const TextStyle(fontSize: 80),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _modeLabel(GameState gs) {
    if (gs.rt.challenge == Operation.master) return '🏆 Master';
    if (gs.rt.challenge == Operation.dailyBoss) return '🐲 Daily Boss';
    return gs.mode.label;
  }

  Color _modeColor(GameState gs) {
    if (gs.rt.challenge == Operation.master) return const Color(GameConfig.mango);
    if (gs.rt.challenge == Operation.dailyBoss) return const Color(GameConfig.punch);
    switch (gs.mode) {
      case GameMode.blitz: return const Color(GameConfig.mango);
      case GameMode.death: return const Color(GameConfig.punch);
      case GameMode.survival: return const Color(GameConfig.mint);
      case GameMode.combo: return const Color(GameConfig.coral);
      default: return const Color(GameConfig.sky);
    }
  }
}

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final rt = gs.rt;
    final elapsed = DateTime.now().millisecondsSinceEpoch - rt.timerStart;
    final remaining = (rt.timerDurationMs - elapsed) ~/ 1000;
    final pct = (rt.timerDurationMs - elapsed) / rt.timerDurationMs;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: s.border,
            color: remaining <= 3 ? const Color(GameConfig.punch) : const Color(GameConfig.coral),
          ),
          Center(
            child: Text('${remaining < 0 ? 0 : remaining}',
              style: TextStyle(
                color: s.text,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorecardsRow extends StatelessWidget {
  const _ScorecardsRow({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final isMaster = gs.rt.challenge == Operation.master;
    final isBoss = gs.rt.challenge == Operation.dailyBoss;
    return Row(
      children: [
        if (isMaster || isBoss)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(GameConfig.punch).withValues(alpha: 0.15),
              border: Border.all(color: const Color(GameConfig.punch), width: 2),
            ),
            child: Center(
              child: Text(gs.rt.dailyBoss?.icon ?? '🦍',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        if (isMaster || isBoss) const SizedBox(width: 8),
        Expanded(
          child: _PlayerCard(gs: gs, pid: 1, active: gs.rt.activePlayer == 1),
        ),
        const SizedBox(width: 8),
        if (gs.players == 2 && !isMaster && !isBoss)
          Expanded(
            child: _PlayerCard(gs: gs, pid: 2, active: gs.rt.activePlayer == 2),
          )
        else if (isMaster || isBoss)
          Expanded(
            child: _MasterInfo(gs: gs, s: s),
          ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.gs, required this.pid, required this.active});
  final GameState gs;
  final int pid;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final pl = gs.p[pid];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? const Color(GameConfig.coral).withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(GameConfig.coral) : Colors.grey.shade300,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(avatar: pl.avatar, size: 36),
              if (pl.streak >= 3)
                Positioned(
                  right: -6, bottom: -4,
                  child: StreakFire(streak: pl.streak, size: 12),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(pl.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('${pl.score}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(GameConfig.coral),
              fontFamily: AppFonts.head,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterInfo extends StatelessWidget {
  const _MasterInfo({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final isBoss = gs.rt.challenge == Operation.dailyBoss;
    final lives = isBoss ? gs.rt.dailyBossLives : 3;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('❤️' * (lives < 0 ? 0 : lives),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Text(isBoss ? 'Boss Battle' : 'Stage 1',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: s.muted,
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
          Text('❤️' * (lives < 0 ? 0 : lives),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(GameConfig.punch).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(isBoss ? 'Boss' : (GameConfig.phaseNames[gs.rt.survivalPhase.clamp(0, 4)]),
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
              const Text('Combo Streak',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text('×${gs.rt.comboMultiplier.toInt()}',
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
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: pl.pups.length,
        itemBuilder: (_, i) {
          final pu = pl.pups[i];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => gs.usePowerUp(pu),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(GameConfig.mango).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(GameConfig.mango), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pu.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(pu.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(GameConfig.mango),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: s.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (gs.mode != GameMode.blitz && gs.mode != GameMode.combo &&
                  gs.rt.challenge != Operation.master && gs.rt.challenge != Operation.dailyBoss)
                Text('Q ${gs.rt.totalTurns + 1} / ${gs.rt.maxTurns == 99999 ? '∞' : gs.rt.maxTurns}',
                  style: TextStyle(
                    color: s.muted, fontSize: 12, fontWeight: FontWeight.w700,
                  ),
                )
              else
                const SizedBox.shrink(),
              Expanded(
                child: Text(promptText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: s.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (![GameMode.death, GameMode.survival].contains(gs.mode) &&
                  gs.rt.challenge != Operation.master &&
                  gs.rt.challenge != Operation.dailyBoss)
                TextButton(
                  onPressed: gs.skip,
                  child: const Text('Skip ⏩',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(GameConfig.sky),
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          // Big question text
          RichText(
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
          const SizedBox(height: 16),
          // Mode warning
          if (_modeWarning(gs) != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(GameConfig.punch).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_modeWarning(gs)!,
                style: const TextStyle(
                  color: Color(GameConfig.punch),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _prompt(GameState gs) {
    if (gs.rt.isWarmUp && gs.rt.warmUpCount <= 3) return '🌱 Warm-Up • Q ${gs.rt.warmUpCount}/3';
    if (gs.rt.challenge == Operation.master) return 'Solve it!';
    if (gs.rt.challenge == Operation.dailyBoss) return 'Boss Battle!';
    switch (gs.mode) {
      case GameMode.blitz:    return '⚡ Blitz Mode — answer fast!';
      case GameMode.death:    return '💀 Streak: ${gs.p[gs.rt.activePlayer].streak}';
      case GameMode.survival: return '💪 Q ${gs.rt.totalTurns + 1} • ${GameConfig.phaseNames[gs.rt.survivalPhase.clamp(0, 4)]}';
      case GameMode.combo:    return '🔥 Combo — Streak: ${gs.rt.comboStreak}';
      default: return gs.players == 2
          ? "${gs.p[gs.rt.activePlayer].name}'s Turn"
          : 'Solve it!';
    }
  }

  String? _modeWarning(GameState gs) {
    switch (gs.mode) {
      case GameMode.blitz:    return '⚡ Answer fast for more points!';
      case GameMode.death:    return '💀 ONE WRONG = GAME OVER';
      case GameMode.survival: return '💪 3 Lives — How far can you go?';
      case GameMode.combo:    return '🔥 Build your streak for bigger multipliers!';
      default: return null;
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
            child: Text('?',
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
  const _AnswersGrid({required this.gs, required this.s, required this.onAnswered});
  final GameState gs;
  final SettingsService s;
  // Callback invoked with `true` for correct, `false` for wrong.
  final void Function(bool correct) onAnswered;

  @override
  Widget build(BuildContext context) {
    final q = gs.rt.q;
    if (q == null) return const SizedBox.shrink();
    return GridView.builder(
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
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: gs.rt.accepting
                ? () {
                    // Detect correctness BEFORE calling onAnswer,
                    // because onAnswer advances the question.
                    final correct = c == q.ans;
                    gs.onAnswer(c);
                    onAnswered(correct);
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(GameConfig.coral).withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(
                child: Text(_fmt(c),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: s.text,
                    fontFamily: AppFonts.head,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmt(num n) {
    if (n == n.roundToDouble()) return '${n.toInt()}';
    return n.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
