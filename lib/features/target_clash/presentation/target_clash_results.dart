import 'package:flutter/material.dart';

import '../../../engine/game_state.dart';
import '../../../game_config.dart';
import '../../../services/settings.dart';
import '../../../widgets/common.dart';

class TargetClashResults extends StatefulWidget {
  const TargetClashResults({super.key, required this.gs, required this.s});

  final GameState gs;
  final SettingsService s;

  @override
  State<TargetClashResults> createState() => _TargetClashResultsState();
}

class _TargetClashResultsState extends State<TargetClashResults> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.gs.targetClashResultSummary;
    final config = widget.gs.activeRunSnapshot?.targetClashConfig;
    if (summary == null || config == null) return const SizedBox.shrink();
    final rows = [
      ('Score', '${summary.score}'),
      ('Correct', '${summary.correct}'),
      ('Accuracy', '${summary.accuracyPercent.round()}%'),
      ('Best Combo', '${summary.bestCombo}'),
      ('Perfect Hits', '${summary.perfectHits}'),
      ('Bosses Defeated', '${summary.bossesDefeated}'),
      ('Final Target Completed', summary.finalTargetCompleted ? 'YES' : 'NO'),
      ('Final Target Cleared', summary.finalTargetCleared ? 'YES' : 'NO'),
      ('Triple Clashes Completed', '${summary.tripleClashesCompleted}'),
      ('Operation', config.operation.label),
      ('Difficulty', config.difficulty.label),
      ('Number Type', config.numberType.label),
      ('Question Target', '${config.questionTarget}'),
    ];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              key: const Key('target-clash-results'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TARGET CLASH COMPLETE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(GameConfig.sky),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppFonts.headFor(widget.s),
                  ),
                ),
                const SizedBox(height: 20),
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.$1)),
                        Text(row.$2,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Semantics(
                  label: 'Replay Target Clash',
                  button: true,
                  child: FilledButton(
                    key: const Key('target-clash-results-replay'),
                    onPressed: _busy ? null : () => _run(widget.gs.replayGame),
                    child: const Text('REPLAY'),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Back to menu',
                  button: true,
                  child: OutlinedButton(
                    key: const Key('target-clash-results-menu'),
                    onPressed: _busy ? null : () => _run(widget.gs.quitToMenu),
                    child: const Text('BACK TO MENU'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
