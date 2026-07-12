import 'package:flutter/material.dart';

import '../../../../game_config.dart';
import '../../../../widgets/common.dart';

class QuitPill extends StatelessWidget {
  const QuitPill({super.key, required this.onPressed});

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
              Icon(
                Icons.close_rounded,
                color: Color(GameConfig.punch),
                size: 24,
              ),
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
