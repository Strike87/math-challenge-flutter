import 'package:flutter/material.dart';

/// Wrap between words; reduce only this label's scale if a word cannot fit.
class SetupWordFitText extends StatelessWidget {
  const SetupWordFitText(this.text, {
    super.key,
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
        final baseSize = effectiveStyle.fontSize ?? 14;
        final requested = scaler.scale(baseSize) / baseSize;
        var chosen = requested;
        if (constraints.hasBoundedWidth && constraints.maxWidth > 2) {
          final painter = TextPainter(
            textDirection: Directionality.of(context),
            maxLines: 1,
          );
          final words = text.split(RegExp(r'\s+'));
          bool fits(double scale) {
            painter.textScaler = TextScaler.linear(scale);
            for (final word in words) {
              painter.text = TextSpan(text: word, style: effectiveStyle);
              painter.layout();
              if (painter.width > constraints.maxWidth - 2) return false;
            }
            return true;
          }

          if (!fits(requested)) {
            var low = 0.0;
            var high = requested;
            for (var i = 0; i < 16; i++) {
              final mid = (low + high) / 2;
              if (fits(mid)) {
                low = mid;
              } else {
                high = mid;
              }
            }
            chosen = low;
          }
          painter.dispose();
        }
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          softWrap: true,
          textScaler: chosen < requested ? TextScaler.linear(chosen) : scaler,
        );
      },
    );
  }
}
