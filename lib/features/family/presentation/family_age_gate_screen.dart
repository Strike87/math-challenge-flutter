import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../engine/game_state.dart';
import '../../../game_config.dart';
import '../../../services/settings.dart';
import '../../../widgets/common.dart';
import '../../cloud_save/application/cloud_save_controller.dart';

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
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    final accepted = await widget.state.submitFamilyDateOfBirth(
      '${_yearController.text.trim()}-'
      '${_monthController.text.trim().padLeft(2, '0')}-'
      '${_dayController.text.trim().padLeft(2, '0')}',
    );
    if (accepted && mounted) {
      await context.read<CloudSaveController>().resumeAfterFamilyGate();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
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
                        'Before you continue',
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
              'We use your age to provide an age-appropriate experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: settings.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              key: const ValueKey('familyDobDay'),
                              controller: _dayController,
                              enabled: !_busy,
                              label: 'Day',
                              hint: 'DD',
                              maxLength: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateField(
                              key: const ValueKey('familyDobMonth'),
                              controller: _monthController,
                              enabled: !_busy,
                              label: 'Month',
                              hint: 'MM',
                              maxLength: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _DateField(
                              key: const ValueKey('familyDobYear'),
                              controller: _yearController,
                              enabled: !_busy,
                              label: 'Year',
                              hint: 'YYYY',
                              maxLength: 4,
                              submit: _continue,
                            ),
                          ),
                        ],
                      ),
                      if (widget.state.familyGateError.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.state.familyGateError,
                          key: const ValueKey('familyDobError'),
                          style: const TextStyle(
                            color: Color(GameConfig.coral),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const ValueKey('familyDobContinue'),
                        onPressed: _busy ? null : _continue,
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
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.maxLength,
    this.submit,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final int maxLength;
  final Future<void> Function()? submit;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction:
            submit == null ? TextInputAction.next : TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        onSubmitted: submit == null ? null : (_) => submit!(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      );
}
