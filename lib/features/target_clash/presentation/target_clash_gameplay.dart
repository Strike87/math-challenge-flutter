import 'dart:async';

import 'package:flutter/material.dart';

import '../../../engine/game_state.dart';
import '../../../features/gameplay/presentation/widgets/gameplay_controls.dart';
import '../../../features/target_clash/domain/presentation_answer.dart';
import '../../../features/target_clash/domain/target_clash_question.dart';
import '../../../features/target_clash/domain/target_clash_runtime_state.dart';
import '../../../game_config.dart';
import '../../../models/math_fact.dart';
import '../../../services/settings.dart';
import '../../../widgets/common.dart';

/// Presentation-only Target Clash surface. The runtime owns all gameplay facts.
class TargetClashGameplay extends StatefulWidget {
  const TargetClashGameplay({super.key, required this.gs, required this.s});

  final GameState gs;
  final SettingsService s;

  @override
  State<TargetClashGameplay> createState() => _TargetClashGameplayState();
}

class _TargetClashGameplayState extends State<TargetClashGameplay> {
  String? _powerShotMessage;
  TargetClashRevealState? _powerShotMessageReveal;

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final runtime = gs.targetClashRuntime;
    final reveal = gs.targetClashReveal;
    if (runtime == null ||
        (runtime.phase == TargetClashPhase.technicalFailure &&
            reveal == null)) {
      return _TerminalBridge(
        key: const Key('target-clash-technical-failure'),
        title: "Target Clash couldn't continue safely.",
        gs: gs,
        s: widget.s,
      );
    }
    if (runtime.finished && reveal == null) {
      return _TerminalBridge(
        key: const Key('target-clash-terminal-bridge'),
        title: 'TARGET CLASH COMPLETE',
        gs: gs,
        s: widget.s,
      );
    }

    final question = reveal?.question ?? gs.targetClashQuestion;
    if (question == null)
      return const SizedBox(key: Key('target-clash-gameplay'));
    final compactScreen =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height ||
            MediaQuery.sizeOf(context).height < 650;
    final accepting = gs.rt.accepting && reveal == null;
    final actionArea = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RelationControls(
          key: ObjectKey(question),
          gs: gs,
          enabled: accepting,
          question: question,
          reveal: reveal,
          s: widget.s,
          compact: compactScreen,
        ),
        if (reveal != null &&
            !runtime.finished &&
            runtime.phase != TargetClashPhase.technicalFailure) ...[
          const SizedBox(height: 14),
          _PowerShot(
            runtime: runtime,
            enabled: runtime.isPowerShotReady && !runtime.isTriple,
            s: widget.s,
            onPressed: () {
              final currentReveal = gs.targetClashReveal;
              final outcome = gs.activateTargetClashPowerShot();
              setState(() {
                _powerShotMessage = switch (outcome) {
                  TargetClashPowerShotOutcome.applied => 'POWER SHOT ARMED',
                  TargetClashPowerShotOutcome.unavailable =>
                    'POWER SHOT UNAVAILABLE',
                  TargetClashPowerShotOutcome.denied => 'POWER SHOT DENIED',
                };
                _powerShotMessageReveal = currentReveal;
              });
            },
          ),
          if (_powerShotMessage != null &&
              identical(_powerShotMessageReveal, reveal))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _powerShotMessage!,
                key: const Key('target-clash-power-shot-feedback'),
                style: TextStyle(
                  color: widget.s.text,
                  fontFamily: AppFonts.headFor(widget.s),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ],
    );
    // GameScreen already supplies the SafeArea and AppShell supplies the mesh.
    // Keep the playable group top-anchored: spare height belongs below controls.
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, compactScreen ? 4 : 8, 16, 8),
          child: Row(children: [
            QuitPill(onPressed: gs.showQuitConfirm),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const ModeBadge(
                    label: 'TARGET CLASH',
                    color: Color(GameConfig.grape),
                  ),
                ),
              ),
            ),
            SizedBox(width: compactScreen ? 48 : 72),
          ]),
        ),
        _Hud(
          runtime: runtime,
          reveal: reveal,
          s: widget.s,
          compact: compactScreen,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              compactScreen ? 8 : 12,
              16,
              compactScreen ? 12 : 16,
            ),
            child: Center(
              child: ConstrainedBox(
                key: const Key('target-clash-gameplay'),
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ClashArsenal(gs: gs, s: widget.s),
                    SizedBox(height: compactScreen ? 8 : 12),
                    AnimatedSwitcher(
                      duration: (!widget.s.reduceMotion && !widget.s.lowPerf)
                          ? widget.s.duration(180)
                          : Duration.zero,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      // Keep a newly resolved question gently entering without
                      // stacking its text over the outgoing question mid-frame.
                      // Input remains owned by the sibling answer section.
                      layoutBuilder: (currentChild, _) =>
                          currentChild ?? const SizedBox.shrink(),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .035),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _QuestionPanel(
                        key: ValueKey(
                            '${question.expression}:${question.targetValue}:${reveal != null}'),
                        question: question,
                        reveal: reveal,
                        s: widget.s,
                        compact: compactScreen,
                      ),
                    ),
                    SizedBox(height: compactScreen ? 12 : 16),
                    Semantics(
                      container: true,
                      label: 'Relation answers',
                      child: Column(
                        key: const Key('target-clash-answers-section'),
                        mainAxisSize: MainAxisSize.min,
                        children: [actionArea],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClashArsenal extends StatelessWidget {
  const _ClashArsenal({required this.gs, required this.s});
  final GameState gs;
  final SettingsService s;

  Future<void> _show(BuildContext context, String title, String description,
      bool Function() activate) async {
    final questionToken = gs.clashQuestionToken;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(description),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('CANCEL')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('USE'))
              ],
            ));
    if (confirmed == true &&
        context.mounted &&
        (gs.clashQuestionToken != questionToken || !activate())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('That question is no longer available.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = gs.targetClashRuntime!;
    final accepting = gs.rt.accepting && gs.targetClashReveal == null;
    final question = gs.targetClashQuestion;
    final lensReason = !accepting
        ? 'Available while answering'
        : gs.clashLensActive
            ? 'Already active for this question'
            : gs.clashLensRemaining == 0
                ? 'No uses remaining'
                : gs.clashSignRule == null
                    ? 'No signed-number rule applies'
                    : null;
    final scanReason = !accepting
        ? 'Available while answering'
        : gs.clashScanUsed
            ? 'Already used this run'
            : null;
    final guardReason = !accepting
        ? 'Available while answering'
        : runtime.phase != TargetClashPhase.boss
            ? 'Available during Boss only'
            : gs.clashGuardUsed
                ? 'Already used this run'
                : null;
    final memoryReason = !accepting
        ? 'Available while answering'
        : !runtime.isTriple
            ? 'Available during Triple Clash only'
            : gs.clashTripleHistory.isEmpty
                ? 'No completed comparisons yet'
                : null;
    Widget control(
            String id,
            String label,
            String usage,
            bool active,
            bool consumed,
            IconData icon,
            Color color,
            String? reason,
            VoidCallback onTap) =>
        Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Tooltip(
                  message: '$label. $usage. ${reason ?? 'Available'}',
                  excludeFromSemantics: true,
                  child: Semantics(
                      key: Key('target-clash-arsenal-$id'),
                      label: label,
                      value:
                          '${active ? 'Armed' : consumed ? 'Consumed' : reason == null ? 'Available' : 'Disabled'}. $usage',
                      hint: reason ?? 'Open help and usage details',
                      button: true,
                      enabled: reason == null,
                      onTap: reason == null ? onTap : null,
                      excludeSemantics: true,
                      child: OutlinedButton(
                        onPressed: reason == null ? onTap : null,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            disabledForegroundColor:
                                color.withValues(alpha: .5),
                            backgroundColor:
                                active ? color.withValues(alpha: .14) : null,
                            side: BorderSide(
                                color:
                                    color.withValues(alpha: active ? 1 : .45),
                                width: active ? 2 : 1),
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.all(8)),
                        child: Stack(clipBehavior: Clip.none, children: [
                          Icon(icon, size: 24),
                          if (active || consumed)
                            Positioned(
                                right: -9,
                                top: -7,
                                child: Icon(
                                    active
                                        ? Icons.check_circle
                                        : Icons.done_all,
                                    size: 13)),
                        ]),
                      )))),
        );
    return Column(key: const Key('target-clash-arsenal'), children: [
      Row(key: const Key('target-clash-arsenal-row'), children: [
        control(
            'lens',
            'Sign Lens',
            '${gs.clashLensRemaining} uses remaining',
            gs.clashLensActive,
            gs.clashLensRemaining == 0,
            Icons.lightbulb_outline,
            const Color(GameConfig.grape),
            lensReason,
            () => _show(
                context,
                'Sign Lens',
                'Use one of ${gs.clashLensRemaining} remaining uses to show an applicable signed-number rule for this question.',
                gs.activateClashLens)),
        control(
            'scan',
            'Balance Scan',
            '${gs.clashScanUsed ? 0 : 1} uses remaining',
            gs.clashScanActive,
            gs.clashScanUsed,
            Icons.balance,
            const Color(GameConfig.sky),
            scanReason,
            () => _show(
                context,
                'Balance Scan',
                'Reveal the expression value for this question. This consumes your one use immediately. A correct answer earns half its normal final points after all bonuses; incorrect answers and timeouts earn zero. The effect expires with this question.',
                gs.activateClashScan)),
        control(
            'guard',
            'Boss Guard',
            '${gs.clashGuardUsed ? 0 : 1} uses remaining',
            gs.clashGuardActive,
            gs.clashGuardUsed,
            Icons.shield_outlined,
            const Color(GameConfig.coral),
            guardReason,
            () => _show(
                context,
                'Boss Guard',
                'Consume your one use now. An incorrect submitted answer on this Boss question preserves Combo, which can increase later multipliers. Correct answers, timeout or replacement expire it; timeout resets Combo. Wrong answers still earn zero and do no Boss damage.',
                gs.activateClashGuard)),
        control(
            'memory',
            'Triple Memory',
            '${gs.clashTripleHistory.length} completed comparisons; reusable',
            false,
            false,
            Icons.history,
            const Color(GameConfig.mango),
            memoryReason, () {
          gs.markClashMemoryRead();
          showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                      title: const Text('Triple Memory'),
                      content: SingleChildScrollView(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final item in gs.clashTripleHistory)
                          Text(
                              '${_expression(item.question.expression)} = ${_number(item.question.expressionValue, item.question.expression)} ${_relation(item.question.correctAnswer)} ${_number(item.question.targetValue, item.question.expression)}')
                      ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CLOSE'))
                      ]));
        }),
      ]),
      if (gs.clashLensActive)
        Text(gs.clashSignRule ?? '',
            key: const Key('target-clash-sign-rule'),
            textAlign: TextAlign.center),
      if (gs.clashScanActive && question != null)
        Text(
            'Expression value: ${_number(question.expressionValue, question.expression)}',
            key: const Key('target-clash-scan-value')),
      if (gs.clashGuardActive) const Text('Boss Guard armed for this question'),
    ]);
  }
}

class _Hud extends StatefulWidget {
  const _Hud({
    required this.runtime,
    required this.reveal,
    required this.s,
    required this.compact,
  });

  final TargetClashRuntimeState runtime;
  final TargetClashRevealState? reveal;
  final SettingsService s;
  final bool compact;

  @override
  State<_Hud> createState() => _HudState();
}

class _HudState extends State<_Hud> {
  late int _observedBossHealth;
  late int _bossHealthFrom;
  late bool _wasBoss;
  late bool _wasFever;
  late bool _wasTriple;
  bool _bossHit = false;
  bool _feverEntry = false;
  bool _tripleEntry = false;
  Timer? _bossHitTimer;
  Timer? _feverEntryTimer;
  Timer? _tripleEntryTimer;

  TargetClashRuntimeState get runtime => widget.runtime;
  TargetClashRevealState? get reveal => widget.reveal;
  SettingsService get s => widget.s;
  bool get compact => widget.compact;
  bool get _effectsEnabled => !s.reduceMotion && !s.lowPerf;

  @override
  void initState() {
    super.initState();
    _observedBossHealth = runtime.bossHealth;
    _bossHealthFrom = runtime.bossHealth;
    _wasBoss = runtime.phase == TargetClashPhase.boss;
    _wasFever = runtime.isFeverActive;
    _wasTriple = runtime.isTriple;
  }

  @override
  void didUpdateWidget(covariant _Hud oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasBoss = _wasBoss;
    final isBoss = runtime.phase == TargetClashPhase.boss;
    final healthDropped =
        wasBoss && isBoss && runtime.bossHealth < _observedBossHealth;
    _bossHealthFrom = _observedBossHealth;
    _observedBossHealth = runtime.bossHealth;
    _wasBoss = isBoss;
    final feverEntered = !_wasFever && runtime.isFeverActive;
    final tripleEntered = !_wasTriple && runtime.isTriple;
    _wasFever = runtime.isFeverActive;
    _wasTriple = runtime.isTriple;
    if (!_effectsEnabled) return;
    if (healthDropped) _startBossHit();
    if (feverEntered) _startFeverEntry();
    if (tripleEntered) _startTripleEntry();
  }

  void _startBossHit() {
    _bossHitTimer?.cancel();
    _bossHit = true;
    _bossHitTimer = Timer(s.duration(180), () {
      if (mounted) setState(() => _bossHit = false);
    });
  }

  void _startFeverEntry() {
    _feverEntryTimer?.cancel();
    _feverEntry = true;
    _feverEntryTimer = Timer(s.duration(200), () {
      if (mounted) setState(() => _feverEntry = false);
    });
  }

  void _startTripleEntry() {
    _tripleEntryTimer?.cancel();
    _tripleEntry = true;
    _tripleEntryTimer = Timer(s.duration(200), () {
      if (mounted) setState(() => _tripleEntry = false);
    });
  }

  @override
  void dispose() {
    _bossHitTimer?.cancel();
    _feverEntryTimer?.cancel();
    _tripleEntryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectsEnabled = _effectsEnabled;
    final count = reveal?.resolvedStageQuestionCount ??
        runtime.preparedStage?.questions.length ??
        0;
    final stageIndex =
        reveal?.resolvedStageQuestionIndex ?? runtime.stageQuestionIndex;
    final displayedPhase = reveal?.phase ?? runtime.phase;
    final phase = switch (displayedPhase) {
      TargetClashPhase.ordinaryStage1 ||
      TargetClashPhase.ordinaryStage2 =>
        'TARGET STREAK',
      TargetClashPhase.triple => 'TRIPLE CLASH',
      TargetClashPhase.boss => 'BOSS TARGET',
      TargetClashPhase.finalTarget => 'FINAL TARGET',
      _ => '',
    };
    final accent = switch (displayedPhase) {
      TargetClashPhase.triple => const Color(GameConfig.grape),
      TargetClashPhase.boss => const Color(GameConfig.punch),
      TargetClashPhase.finalTarget => const Color(GameConfig.mango),
      _ => const Color(GameConfig.sky),
    };
    final bossIndicator = runtime.phase == TargetClashPhase.boss
        ? Semantics(
            label: 'Boss health, ${runtime.bossHealth} remaining',
            child: AnimatedContainer(
              key: const Key('target-clash-boss-health'),
              duration: effectsEnabled ? s.duration(200) : Duration.zero,
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 7 : 10,
              ),
              decoration: _statusDecoration(
                s: s,
                color: GameConfig.coral,
                alpha: _bossHit ? .30 : .12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      color: s.accent(GameConfig.coral),
                      size: compact ? 16 : 20),
                  SizedBox(height: compact ? 2 : 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'BOSS HEALTH  ${runtime.bossHealth}',
                      maxLines: 1,
                      softWrap: false,
                      style: _statusLabel(s, compact),
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: _bossHealthFrom.toDouble(),
                      end: runtime.bossHealth.toDouble(),
                    ),
                    duration: effectsEnabled ? s.duration(200) : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (context, health, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 5; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Container(
                            width: compact ? 8 : 11,
                            height: compact ? 8 : 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.accent(GameConfig.coral).withValues(
                                    alpha: (health - i)
                                        .clamp(0.12, 1.0)
                                        .toDouble(),
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;
    final feverIndicator = runtime.isFeverActive
        ? Semantics(
            label: 'Fever times two, ${runtime.feverRemaining} remaining',
            child: AnimatedContainer(
              key: const Key('target-clash-fever'),
              duration: effectsEnabled ? s.duration(200) : Duration.zero,
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 7 : 10,
              ),
              decoration: _statusDecoration(
                s: s,
                color: GameConfig.mango,
                alpha: _feverEntry ? .34 : .17,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: s.accent(GameConfig.mango),
                      size: compact ? 16 : 20),
                  SizedBox(height: compact ? 2 : 4),
                  Text('FEVER ×2', style: _statusLabel(s, compact)),
                  SizedBox(height: compact ? 3 : 6),
                  Text(
                    '${runtime.feverRemaining} left',
                    style: TextStyle(
                      color: s.text,
                      fontFamily: AppFonts.headFor(s),
                      fontSize: compact ? 11 : 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        DecoratedBox(
          key: const Key('target-clash-hud-edge'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: .6), width: 2),
          ),
          child: AnimatedContainer(
            key: const Key('target-clash-hud'),
            duration: effectsEnabled ? s.duration(200) : Duration.zero,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
                18, compact ? 10 : 14, 18, compact ? 11 : 16),
            decoration: BoxDecoration(
              color: s.surface.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AnimatedContainer(
                      duration:
                          effectsEnabled ? s.duration(200) : Duration.zero,
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: _tripleEntry &&
                                  displayedPhase == TargetClashPhase.triple
                              ? .30
                              : .15,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        phase,
                        key: const Key('target-clash-phase'),
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.05,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Text(
                        'STAGE ${stageIndex + 1} / $count',
                        key: const Key('target-clash-progress'),
                        style: TextStyle(
                          color: s.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ]),
              SizedBox(height: compact ? 4 : 8),
              Row(children: [
                Expanded(
                    child: _Metric(
                  'SCORE',
                  '${runtime.score}',
                  const Key('target-clash-score'),
                  s,
                  compact,
                  const Color(GameConfig.sky),
                )),
                Expanded(
                    child: _Metric(
                  'COMBO',
                  '${runtime.displayCombo}',
                  const Key('target-clash-combo'),
                  s,
                  compact,
                  const Color(GameConfig.mango),
                )),
                Expanded(
                    child: _Metric(
                  'MULTI',
                  '×${runtime.comboMultiplier}',
                  const Key('target-clash-multiplier'),
                  s,
                  compact,
                  const Color(GameConfig.grape),
                )),
              ]),
              SizedBox(height: compact ? 4 : 8),
              Semantics(
                label:
                    'Clash Power, ${runtime.clashPower} of 6${runtime.isPowerShotReady ? ', ready' : ''}',
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Text(
                      'CLASH POWER',
                      style: TextStyle(
                          color: s.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900),
                    )),
                    Text(
                      runtime.isPowerShotReady
                          ? 'READY'
                          : '${runtime.clashPower} / 6',
                      key: const Key('target-clash-power'),
                      style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900),
                    ),
                  ]),
                  SizedBox(height: compact ? 4 : 6),
                  Row(children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Expanded(
                          child: AnimatedContainer(
                        key: Key('target-clash-power-segment-$i'),
                        duration:
                            effectsEnabled ? s.duration(200) : Duration.zero,
                        curve: Curves.easeOutCubic,
                        height: compact ? 7 : 8,
                        decoration: BoxDecoration(
                          color: i < runtime.clashPower
                              ? runtime.isPowerShotReady
                                  ? s.accent(GameConfig.mint)
                                  : accent
                              : s.surface2,
                          border: s.dark ? Border.all(color: s.border) : null,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      )),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        if (bossIndicator != null || feverIndicator != null) ...[
          const SizedBox(height: 8),
          _StatusGroup(
            boss: bossIndicator,
            fever: feverIndicator,
          ),
        ],
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      this.label, this.value, this.keyValue, this.s, this.compact, this.color);

  final String label;
  final String value;
  final Key keyValue;
  final SettingsService s;
  final bool compact;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                color: s.muted, fontSize: 10, fontWeight: FontWeight.w900),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: keyValue,
              style: TextStyle(
                  color: color,
                  fontFamily: AppFonts.headFor(s),
                  fontSize: compact ? 19 : 24,
                  height: 1,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      );
}

class _StatusGroup extends StatelessWidget {
  const _StatusGroup({required this.boss, required this.fever});

  final Widget? boss;
  final Widget? fever;

  @override
  Widget build(BuildContext context) {
    final both = boss != null && fever != null;
    if (!both) {
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: boss ?? fever!,
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: boss!),
          const SizedBox(width: 8),
          Expanded(child: fever!),
        ],
      ),
    );
  }
}

BoxDecoration _statusDecoration({
  required SettingsService s,
  required int color,
  required double alpha,
}) {
  final accent = s.accent(color);
  return BoxDecoration(
    color: accent.withValues(alpha: alpha),
    border: Border.all(color: accent.withValues(alpha: .5)),
    borderRadius: BorderRadius.circular(16),
  );
}

TextStyle _statusLabel(SettingsService s, bool compact) => TextStyle(
      color: s.text,
      fontFamily: AppFonts.headFor(s),
      fontSize: compact ? 11 : 13,
      fontWeight: FontWeight.w900,
    );

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel(
      {super.key,
      required this.question,
      required this.reveal,
      required this.s,
      required this.compact});
  final TargetClashQuestion question;
  final TargetClashRevealState? reveal;
  final SettingsService s;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isReveal = reveal != null;
    final relation = _relation(question.correctAnswer);
    final feedback = isReveal
        ? reveal!.playerAnswer == null
            ? 'TIMEOUT • $relation'
            : reveal!.wasCorrect
                ? reveal!.wasPerfectHit
                    ? 'PERFECT HIT'
                    : 'CORRECT • $relation'
                : 'INCORRECT • $relation'
        : null;
    return SizedBox(
      width: double.infinity,
      child: Container(
        key: const Key('target-clash-question-panel'),
        padding: EdgeInsets.all(compact ? 12 : 20),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: s.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: s.dark ? .18 : .06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Choose the correct relation',
            style: TextStyle(
                color: s.muted,
                fontSize: compact ? 15 : 17,
                height: 1.08,
                fontWeight: FontWeight.w900,
                fontFamily: AppFonts.headFor(s)),
          ),
          SizedBox(height: compact ? 8 : 16),
          Semantics(
            label: isReveal
                ? 'Resolved mathematical relation'
                : 'Compare the expression with the target. Choose the unknown relation.',
            child: LayoutBuilder(
              builder: (context, constraints) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  key: const Key('target-clash-inline-relation'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_expression(question.expression),
                        key: const Key('target-clash-expression'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: s.text,
                            fontSize: compact ? 24 : 36,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppFonts.headFor(s))),
                    const SizedBox(width: 8),
                    _UnknownRelation(s: s, compact: compact),
                    const SizedBox(width: 8),
                    Text(_number(question.targetValue, question.expression),
                        key: const Key('target-clash-inline-target'),
                        style: TextStyle(
                            color: s.text,
                            fontSize: compact ? 24 : 36,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppFonts.headFor(s))),
                  ],
                ),
              ),
            ),
          ),
          if (isReveal) ...[
            SizedBox(height: compact ? 4 : 10),
            Text(
                '${_number(question.expressionValue, question.expression)} $relation ${_number(question.targetValue, question.expression)}',
                key: const Key('target-clash-reveal-relation'),
                style: TextStyle(
                    color: s.text,
                    fontFamily: AppFonts.headFor(s),
                    fontWeight: FontWeight.w800)),
            SizedBox(height: compact ? 4 : 10),
            Semantics(
              liveRegion: true,
              child: Text(
                  '${reveal!.wasPowerShot ? 'POWER SHOT • ' : ''}$feedback',
                  key: const Key('target-clash-reveal-feedback'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: s.text,
                      fontFamily: AppFonts.headFor(s),
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _UnknownRelation extends StatelessWidget {
  const _UnknownRelation({required this.s, required this.compact});

  final SettingsService s;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('target-clash-unknown-relation'),
        constraints: BoxConstraints(
          minWidth: compact ? 52 : 68,
          minHeight: compact ? 52 : 72,
        ),
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: 4),
        decoration: BoxDecoration(
          color: s.accent(GameConfig.grape).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          border: Border.all(color: s.accent(GameConfig.grape), width: 2),
          boxShadow: [
            BoxShadow(
              color: s.accent(GameConfig.grape).withValues(alpha: .25),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            '?',
            style: TextStyle(
              color: s.accent(GameConfig.grape),
              fontSize: compact ? 34 : 44,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.headFor(s),
              height: 1.1,
            ),
          ),
        ),
      );
}

class _RelationControls extends StatelessWidget {
  const _RelationControls(
      {super.key,
      required this.gs,
      required this.enabled,
      required this.question,
      required this.reveal,
      required this.s,
      required this.compact});
  final GameState gs;
  final bool enabled;
  final TargetClashQuestion question;
  final TargetClashRevealState? reveal;
  final SettingsService s;
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-less'),
                label: '<',
                semanticLabel: 'Less than target',
                enabled: enabled,
                feedback: _feedbackFor(PresentationAnswer.lessThan),
                s: s,
                compact: compact,
                color: s.accent(GameConfig.coral),
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.lessThan))),
        SizedBox(width: compact ? 6 : 10),
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-equal'),
                label: '=',
                semanticLabel: 'Equal to target',
                enabled: enabled,
                feedback: _feedbackFor(PresentationAnswer.equalTo),
                s: s,
                compact: compact,
                color: s.accent(GameConfig.coral),
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.equalTo))),
        SizedBox(width: compact ? 6 : 10),
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-greater'),
                label: '>',
                semanticLabel: 'Greater than target',
                enabled: enabled,
                feedback: _feedbackFor(PresentationAnswer.greaterThan),
                s: s,
                compact: compact,
                color: s.accent(GameConfig.coral),
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.greaterThan))),
      ]);

  Color? _feedbackFor(PresentationAnswer answer) {
    final current = reveal;
    if (current == null ||
        !identical(current.question, question) ||
        current.playerAnswer != answer) {
      return null;
    }
    return current.wasCorrect
        ? const Color(GameConfig.mint)
        : const Color(GameConfig.coral);
  }
}

class _RelationButton extends StatefulWidget {
  const _RelationButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.feedback,
    required this.s,
    required this.color,
    required this.compact,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final Color? feedback;
  final SettingsService s;
  final VoidCallback onPressed;
  final Color color;
  final bool compact;

  @override
  State<_RelationButton> createState() => _RelationButtonState();
}

class _RelationButtonState extends State<_RelationButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectsEnabled = !widget.s.reduceMotion && !widget.s.lowPerf;
    final color = widget.feedback ?? widget.color;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: AnimatedScale(
        duration: effectsEnabled ? widget.s.duration(180) : Duration.zero,
        scale: _pressed && effectsEnabled ? .97 : 1,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.compact ? 52 : 72),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: widget.feedback?.withValues(alpha: .20) ??
                          Colors.black.withValues(alpha: .08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor:
                  widget.feedback?.withValues(alpha: .16) ?? widget.s.surface,
              foregroundColor: color,
              disabledBackgroundColor:
                  widget.feedback?.withValues(alpha: .16) ?? widget.s.surface2,
              disabledForegroundColor: widget.feedback ?? widget.s.muted,
              side: BorderSide(
                color: widget.feedback ??
                    (widget.enabled
                        ? color.withValues(alpha: .30)
                        : widget.s.border),
                width: widget.feedback == null && widget.enabled ? 1.5 : 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: widget.enabled ? widget.onPressed : null,
            child: Listener(
              onPointerDown: widget.enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onPointerUp: (_) => setState(() => _pressed = false),
              onPointerCancel: (_) => setState(() => _pressed = false),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.headFor(widget.s),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerShot extends StatelessWidget {
  const _PowerShot(
      {required this.runtime,
      required this.enabled,
      required this.s,
      required this.onPressed});
  final TargetClashRuntimeState runtime;
  final bool enabled;
  final SettingsService s;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: const Key('target-clash-power-shot'),
          onPressed: enabled ? onPressed : null,
          child: Text(
            runtime.isPowerShotReady && runtime.isTriple
                ? 'POWER SHOT BLOCKED IN TRIPLE'
                : enabled
                    ? 'POWER SHOT READY'
                    : 'POWER SHOT ${runtime.clashPower} / 6',
            style: TextStyle(
              fontFamily: AppFonts.headFor(s),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}

class _TerminalBridge extends StatelessWidget {
  const _TerminalBridge(
      {super.key, required this.title, required this.gs, required this.s});
  final String title;
  final GameState gs;
  final SettingsService s;
  @override
  Widget build(BuildContext context) => Center(
        key: const Key('target-clash-gameplay'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.headFor(s))),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: gs.quitToMenu,
                child: Text('BACK TO MENU',
                    style: TextStyle(
                        fontFamily: AppFonts.headFor(s),
                        fontWeight: FontWeight.w900))),
          ],
        ),
      );
}

String _expression(MathFact fact) =>
    '${_number(fact.left, fact)} ${fact.operation.symbol} ${_number(fact.right, fact)}';

String _relation(PresentationAnswer answer) => switch (answer) {
      PresentationAnswer.lessThan => '<',
      PresentationAnswer.equalTo => '=',
      PresentationAnswer.greaterThan => '>',
    };

String _number(num value, MathFact fact) {
  final places =
      fact.numberType.name == 'rationals' ? fact.rationalDecimalPlaces : null;
  if (places != null) return value.toStringAsFixed(places);
  return value == value.toInt() ? value.toInt().toString() : value.toString();
}
