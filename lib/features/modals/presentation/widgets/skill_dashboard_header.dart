import 'package:flutter/material.dart';

import '../../../../services/settings.dart';
import '../../../../widgets/common.dart';

class SkillDashboardHeader extends StatelessWidget {
  const SkillDashboardHeader({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📈', style: TextStyle(fontSize: 44)),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Skills Dashboard',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: settings.text,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                fontFamily: AppFonts.headFor(settings),
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
