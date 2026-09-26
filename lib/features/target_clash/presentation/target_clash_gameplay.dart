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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Center(
                  child: ConstrainedBox(
                    key: const Key('target-clash-gameplay'),
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(children: [
                      _QuestionPanel(
                        question: question,
                        reveal: reveal,
                        s: widget.s,
                      ),
                      const SizedBox(height: 18),
                      _RelationControls(gs: gs, enabled: accepting),
                      if (reveal != null &&
                          !runtime.finished &&
                          runtime.phase !=
                              TargetClashPhase.technicalFailure) ...[
                        const SizedBox(height: 14),
                        _PowerShot(
                          runtime: runtime,
                          enabled:
                              runtime.isPowerShotReady && !runtime.isTriple,
                          onPressed: () {
                            final currentReveal = gs.targetClashReveal;
                            final outcome = gs.activateTargetClashPowerShot();
                            setState(() {
                              _powerShotMessage = switch (outcome) {
                                TargetClashPowerShotOutcome.applied =>
                                  'POWER SHOT ARMED',
                                TargetClashPowerShotOutcome.unavailable =>
                                  'POWER SHOT UNAVAILABLE',
                                TargetClashPowerShotOutcome.denied =>
                                  'POWER SHOT DENIED',
                              };
                              _powerShotMessageReveal = currentReveal;
                            });
                          },
                        ),
                        if (_powerShotMessage != null &&
                            identical(_powerShotMessageReveal, reveal))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_powerShotMessage!,
                                key: const Key(
                                    'target-clash-power-shot-feedback'),
                                style: TextStyle(
                                    color: widget.s.text,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ]),
                  ),
                ),
              ),
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
    final stageCount = runtime.preparedStage?.questions.length ?? 0;
    final phase = switch (runtime.phase) {
      TargetClashPhase.ordinaryStage1 ||
      TargetClashPhase.ordinaryStage2 =>
        'TARGET STREAK',
      TargetClashPhase.triple => 'TRIPLE CLASH',
      TargetClashPhase.boss => 'BOSS TARGET',
      TargetClashPhase.finalTarget => 'FINAL TARGET',
      _ => '',
    };
    return Container(
      key: const Key('target-clash-hud'),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(GameConfig.grape)),
      ),
      child: Column(children: [
        Text(phase,
            key: const Key('target-clash-phase'),
            style:
                const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 6,
            children: [
              _Metric(
                  'SCORE', '${runtime.score}', const Key('target-clash-score')),
              _Metric('COMBO', '${runtime.displayCombo}',
                  const Key('target-clash-combo')),
              _Metric('×', '${runtime.comboMultiplier}',
                  const Key('target-clash-multiplier')),
              _Metric(
                  'CLASH POWER',
                  runtime.isPowerShotReady
                      ? '6 / 6 READY'
                      : '${runtime.clashPower} / 6',
                  const Key('target-clash-power')),
              if (stageCount > 0)
                _Metric(
                    'STAGE',
                    '${runtime.stageQuestionIndex + 1} / $stageCount',
                    const Key('target-clash-progress')),
              if (runtime.isFeverActive)
                _Metric('FEVER ×2', '${runtime.feverRemaining} remaining',
                    const Key('target-clash-fever')),
              if (runtime.phase == TargetClashPhase.boss)
                _Metric('BOSS HEALTH', '${runtime.bossHealth}',
                    const Key('target-clash-boss-health')),
            ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.keyValue);
  final String label;
  final String value;
  final Key keyValue;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        Text(value,
            key: keyValue, style: const TextStyle(fontWeight: FontWeight.w900)),
      ]);
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: s.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Text('TARGET ${_number(question.targetValue, question.expression)}',
            key: const Key('target-clash-target'),
            style: TextStyle(color: s.muted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Text(_expression(question.expression),
            key: const Key('target-clash-expression'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: s.text,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                fontFamily: AppFonts.headFor(s))),
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

class _RelationControls extends StatelessWidget {
  const _RelationControls({required this.gs, required this.enabled});
  final GameState gs;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-less'),
                label: '<',
                semanticLabel: 'Less than target',
                enabled: enabled,
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.lessThan))),
        const SizedBox(width: 10),
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-equal'),
                label: '=',
                semanticLabel: 'Equal to target',
                enabled: enabled,
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.equalTo))),
        const SizedBox(width: 10),
        Expanded(
            child: _RelationButton(
                key: const Key('target-clash-relation-greater'),
                label: '>',
                semanticLabel: 'Greater than target',
                enabled: enabled,
                onPressed: () =>
                    gs.onTargetClashAnswer(PresentationAnswer.greaterThan))),
      ]);
}

class _RelationButton extends StatelessWidget {
  const _RelationButton(
      {super.key,
      required this.label,
      required this.semanticLabel,
      required this.enabled,
      required this.onPressed});
  final String label;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        button: true,
        child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900)),
            )),
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
