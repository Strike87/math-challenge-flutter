import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../engine/game_state.dart';
import '../../../game_config.dart';
import '../../../services/settings.dart';
import '../../../widgets/common.dart';
import '../../cloud_save/application/cloud_save_controller.dart';
import '../domain/family_eligibility.dart';

class FamilyAgeGateScreen extends StatefulWidget {
  const FamilyAgeGateScreen({
    super.key,
    required this.state,
    required this.settings,
  });

  final GameState state;
  final SettingsService settings;

  @override
  State<FamilyAgeGateScreen> createState() => _FamilyAgeGateScreenState();
}

class _FamilyAgeGateScreenState extends State<FamilyAgeGateScreen> {
  FamilyAgeRange? _selectedRange;
  bool _busy = false;

  Future<void> _continue() async {
    final range = _selectedRange;
    if (range == null || _busy) return;
    setState(() => _busy = true);
    final accepted = await widget.state.submitFamilyAgeRange(range);
    if (accepted && mounted) {
      await context.read<CloudSaveController>().resumeAfterFamilyGate();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: settings.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: settings.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: settings.border, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Choose your age group',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: settings.text,
                            fontFamily: AppFonts.headFor(settings),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This helps us provide the right game features.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: settings.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final option in const [
                          (FamilyAgeRange.under13, '12 or younger'),
                          (FamilyAgeRange.teen13to17, '13–17'),
                          (FamilyAgeRange.adult18plus, '18 or older'),
                        ]) ...[
                          _AgeRangeCard(
                            range: option.$1,
                            label: option.$2,
                            selected: _selectedRange == option.$1,
                            enabled: !_busy,
                            onSelected: () => setState(
                              () => _selectedRange = option.$1,
                            ),
                            settings: settings,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.state.familyGateError.isNotEmpty) ...[
                          Text(
                            widget.state.familyGateError,
                            style: const TextStyle(
                              color: Color(GameConfig.coral),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        FilledButton(
                          key: const ValueKey('familyAgeRangeContinue'),
                          onPressed: _busy || _selectedRange == null
                              ? null
                              : _continue,
                          child: Text(_busy ? 'Saving...' : 'Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeRangeCard extends StatelessWidget {
  const _AgeRangeCard({
    required this.range,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.settings,
  });

  final FamilyAgeRange range;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;
  final SettingsService settings;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: SizedBox(
          height: 64,
          child: OutlinedButton(
            key: ValueKey('familyAgeRange_${range.name}'),
            onPressed: enabled ? onSelected : null,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: settings.text,
              backgroundColor: selected
                  ? const Color(GameConfig.sky).withValues(alpha: 0.16)
                  : settings.surface,
              side: BorderSide(
                color: selected ? const Color(GameConfig.sky) : settings.border,
                width: selected ? 3 : 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
}
