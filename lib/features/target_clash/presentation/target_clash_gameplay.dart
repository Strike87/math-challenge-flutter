import 'package:flutter/material.dart';

import '../../../engine/game_state.dart';
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
      );
    }
    if (runtime.finished && reveal == null) {
      return _TerminalBridge(
        key: const Key('target-clash-terminal-bridge'),
        title: 'TARGET CLASH COMPLETE',
        gs: gs,
      );
    }

    final question = reveal?.question ?? gs.targetClashQuestion;
    if (question == null)
      return const SizedBox(key: Key('target-clash-gameplay'));
    final accepting = gs.rt.accepting && reveal == null;
    final actionArea = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RelationControls(gs: gs, enabled: accepting, s: widget.s),
        if (reveal != null &&
            !runtime.finished &&
            runtime.phase != TargetClashPhase.technicalFailure) ...[
          const SizedBox(height: 14),
          _PowerShot(
            runtime: runtime,
            enabled: runtime.isPowerShotReady && !runtime.isTriple,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                IconButton(
                  tooltip: 'Quit game',
                  onPressed: gs.showQuitConfirm,
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Center(
                    child: ModeBadge(
                      label: 'TARGET CLASH',
                      color: Color(GameConfig.grape),
                    ),
                  ),
                ),
                const SizedBox(width: 72),
              ]),
            ),
            _Hud(runtime: runtime, s: widget.s),
            Expanded(
              child: LayoutBuilder(builder: (context, available) {
                final compact = available.maxHeight < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.25;
                final panel = _QuestionPanel(
                  question: question,
                  reveal: reveal,
                  s: widget.s,
                );
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      key: const Key('target-clash-gameplay'),
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: compact
                          ? SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 16),
                                  panel,
                                  const SizedBox(height: 20),
                                  actionArea,
                                ],
                              ),
                            )
                          : Column(children: [
                              Expanded(child: Center(child: panel)),
                              actionArea,
                            ]),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.runtime, required this.s});

  final TargetClashRuntimeState runtime;
  final SettingsService s;

  @override
  Widget build(BuildContext context) {
    final count = runtime.preparedStage?.questions.length ?? 0;
    final phase = switch (runtime.phase) {
      TargetClashPhase.ordinaryStage1 ||
      TargetClashPhase.ordinaryStage2 =>
        'TARGET STREAK',
      TargetClashPhase.triple => 'TRIPLE CLASH',
      TargetClashPhase.boss => 'BOSS TARGET',
      TargetClashPhase.finalTarget => 'FINAL TARGET',
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        NeoCard(
          key: const Key('target-clash-hud'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          color: s.surface,
          borderRadius: 20,
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text(
                  phase,
                  key: const Key('target-clash-phase'),
                  style: TextStyle(
                    color: s.text,
                    fontSize: 14,
                    fontFamily: AppFonts.headFor(s),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (count > 0)
                Text(
                  'STAGE ${runtime.stageQuestionIndex + 1} / $count',
                  key: const Key('target-clash-progress'),
                  style: TextStyle(
                    color: s.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _Metric('SCORE', '${runtime.score}',
                      const Key('target-clash-score'), s)),
              Expanded(
                  child: _Metric('COMBO', '${runtime.displayCombo}',
                      const Key('target-clash-combo'), s)),
              Expanded(
                  child: _Metric('MULTI', '×${runtime.comboMultiplier}',
                      const Key('target-clash-multiplier'), s)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: Text(
                'CLASH POWER',
                style: TextStyle(
                    color: s.text2, fontSize: 11, fontWeight: FontWeight.w800),
              )),
              Text(
                runtime.isPowerShotReady
                    ? '6 / 6 READY'
                    : '${runtime.clashPower} / 6',
                key: const Key('target-clash-power'),
                style: TextStyle(
                    color: s.text, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                    child: Container(
                  key: Key('target-clash-power-segment-$i'),
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < runtime.clashPower
                        ? s.accent(GameConfig.grape)
                        : s.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )),
              ],
            ]),
          ]),
        ),
        if (runtime.phase == TargetClashPhase.boss ||
            runtime.isFeverActive) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (runtime.phase == TargetClashPhase.boss)
                Semantics(
                  label: 'Boss health, ${runtime.bossHealth} remaining',
                  child: Container(
                    key: const Key('target-clash-boss-health'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: s.accent(GameConfig.coral).withValues(alpha: .12),
                      border: Border.all(
                        color: s.accent(GameConfig.coral).withValues(alpha: .5),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'BOSS HEALTH  ${runtime.bossHealth}',
                        style: TextStyle(
                            color: s.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < runtime.bossHealth; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.accent(GameConfig.coral),
                            ),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                ),
              if (runtime.isFeverActive)
                Semantics(
                  label: 'Fever times two, ${runtime.feverRemaining} remaining',
                  child: Container(
                    key: const Key('target-clash-fever'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: s.accent(GameConfig.mango).withValues(alpha: .17),
                      border: Border.all(
                        color:
                            s.accent(GameConfig.mango).withValues(alpha: .55),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'FEVER ×2',
                        style: TextStyle(
                            color: s.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${runtime.feverRemaining} left',
                        style: TextStyle(
                            color: s.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w900),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.keyValue, this.s);

  final String label;
  final String value;
  final Key keyValue;
  final SettingsService s;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                color: s.text2, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: keyValue,
              style: TextStyle(
                  color: s.text,
                  fontFamily: AppFonts.headFor(s),
                  fontSize: 20,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      );
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel(
      {required this.question, required this.reveal, required this.s});
  final TargetClashQuestion question;
  final TargetClashRevealState? reveal;
  final SettingsService s;

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
    return NeoCard(
      key: const Key('target-clash-question-panel'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      color: s.surface,
      borderRadius: 24,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          'Choose the correct relation',
          style: TextStyle(
              color: s.text2, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Semantics(
          label: isReveal
              ? 'Resolved mathematical relation'
              : 'Compare the expression with the target. Choose the unknown relation.',
          child: Wrap(
            key: const Key('target-clash-inline-relation'),
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(_expression(question.expression),
                  key: const Key('target-clash-expression'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: s.text,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppFonts.headFor(s))),
              _UnknownRelation(s: s),
              Text(_number(question.targetValue, question.expression),
                  key: const Key('target-clash-inline-target'),
                  style: TextStyle(
                      color: s.text,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppFonts.headFor(s))),
            ],
          ),
        ),
        if (isReveal) ...[
          const SizedBox(height: 10),
          Text(
              '= ${_number(question.expressionValue, question.expression)} $relation ${_number(question.targetValue, question.expression)}',
              key: const Key('target-clash-reveal-relation'),
              style: TextStyle(color: s.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('${reveal!.wasPowerShot ? 'POWER SHOT • ' : ''}$feedback',
              key: const Key('target-clash-reveal-feedback'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ]),
    );
  }
}

class _UnknownRelation extends StatelessWidget {
  const _UnknownRelation({required this.s});

  final SettingsService s;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('target-clash-unknown-relation'),
        constraints: const BoxConstraints(minWidth: 58, minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: s.accent(GameConfig.grape).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: s.accent(GameConfig.grape), width: 1.5),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            '?',
            style: TextStyle(
              color: s.accent(GameConfig.grape),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.headFor(s),
            ),
          ),
        ),
      );
}

class _RelationControls extends StatelessWidget {
  const _RelationControls(
      {required this.gs, required this.enabled, required this.s});
  final GameState gs;
  final bool enabled;
  final SettingsService s;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-less'),
                label: '<',
                semanticLabel: 'Less than target',
                enabled: enabled,
                s: s,
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.lessThan))),
        const SizedBox(width: 10),
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-equal'),
                label: '=',
                semanticLabel: 'Equal to target',
                enabled: enabled,
                s: s,
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.equalTo))),
        const SizedBox(width: 10),
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-greater'),
                label: '>',
                semanticLabel: 'Greater than target',
                enabled: enabled,
                s: s,
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.greaterThan))),
      ]);
}

class _RelationButton extends StatelessWidget {
  const _RelationButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.s,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final SettingsService s;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        button: true,
        child: SizedBox(
          height: 68,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: s.surface,
              foregroundColor: s.text,
              disabledBackgroundColor: s.surface2,
              disabledForegroundColor: s.muted,
              side: BorderSide(
                color: s.accent(GameConfig.coral).withValues(alpha: .75),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
            ),
            onPressed: enabled ? onPressed : null,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.headFor(s),
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}

class _PowerShot extends StatelessWidget {
  const _PowerShot(
      {required this.runtime, required this.enabled, required this.onPressed});
  final TargetClashRuntimeState runtime;
  final bool enabled;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: const Key('target-clash-power-shot'),
          onPressed: enabled ? onPressed : null,
          child: Text(runtime.isPowerShotReady && runtime.isTriple
              ? 'POWER SHOT BLOCKED IN TRIPLE'
              : enabled
                  ? 'POWER SHOT READY'
                  : 'POWER SHOT ${runtime.clashPower} / 6'),
        ),
      );
}

class _TerminalBridge extends StatelessWidget {
  const _TerminalBridge({super.key, required this.title, required this.gs});
  final String title;
  final GameState gs;
  @override
  Widget build(BuildContext context) => Scaffold(
      key: const Key('target-clash-gameplay'),
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: gs.quitToMenu, child: const Text('BACK TO MENU')),
        ],
      )));
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
