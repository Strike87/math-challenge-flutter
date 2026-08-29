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
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: settings.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: settings.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: settings.dark ? 0.22 : 0.08,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: settings
                                .accent(GameConfig.sky)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Choose your age range',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: settings.text,
                                  fontFamily: AppFonts.headFor(settings),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select the option that applies to you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: settings.muted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
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
                          const SizedBox(height: 14),
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
                        const SizedBox(height: 10),
                        AnimatedScale(
                          scale: _selectedRange == null ? 0.98 : 1,
                          duration: settings.duration(200),
                          curve: Curves.easeOutCubic,
                          child: FilledButton(
                            key: const ValueKey('familyAgeRangeContinue'),
                            onPressed: _busy || _selectedRange == null
                                ? null
                                : _continue,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              textStyle: TextStyle(
                                fontFamily: AppFonts.headFor(settings),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(_busy ? 'Saving...' : 'Continue →'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: settings.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'No date of birth required',
                              style: TextStyle(
                                color: settings.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
  Widget build(BuildContext context) {
    final accent = const Color(GameConfig.sky);
    final duration = settings.duration(200);
    return Semantics(
      container: true,
      label: label,
      selected: selected,
      button: true,
      enabled: enabled,
      onTap: enabled ? onSelected : null,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1.01 : 1,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (selected ? accent : Colors.black).withValues(
                  alpha: selected ? 0.18 : 0.06,
                ),
                blurRadius: selected ? 16 : 8,
                offset: Offset(0, selected ? 6 : 3),
              ),
            ],
          ),
          child: SizedBox(
            height: 88,
            child: OutlinedButton(
              key: ValueKey('familyAgeRange_${range.name}'),
              onPressed: enabled ? onSelected : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: settings.text,
                backgroundColor: selected
                    ? accent.withValues(alpha: 0.15)
                    : settings.surface2.withValues(alpha: 0.38),
                side: BorderSide(
                  color: selected ? accent : settings.border,
                  width: selected ? 3 : 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: duration,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: selected ? 0.20 : 0.11),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(range),
                      color: selected ? accent : settings.muted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: settings.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppFonts.headFor(settings),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? accent : settings.muted,
                        width: 2,
                      ),
                    ),
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: duration,
                      curve: Curves.easeOutBack,
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(FamilyAgeRange range) => switch (range) {
        FamilyAgeRange.under13 => Icons.sentiment_satisfied_alt_rounded,
        FamilyAgeRange.teen13to17 => Icons.auto_awesome_rounded,
        FamilyAgeRange.adult18plus => Icons.workspace_premium_rounded,
      };
}
