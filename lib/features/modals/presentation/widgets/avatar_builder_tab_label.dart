import 'package:flutter/material.dart';

import '../../../../widgets/common.dart';

class AvatarBuilderTabLabel extends StatelessWidget {
  const AvatarBuilderTabLabel({
    super.key,
    required this.icon,
    required this.label,
  });

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 17)),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.body,
            ),
          ),
        ],
      ),
    );
  }
}
