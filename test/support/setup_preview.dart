import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> captureSetupPreview(
  WidgetTester tester, {
  required String screen,
  required Size size,
  required double scale,
  required String position,
}) async {
  if (Platform.environment['CAPTURE_SETUP_PREVIEWS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('visual-root')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/setup-previews');
      await directory.create(recursive: true);
      final name =
          '$screen-${size.width.toInt()}-${(scale * 100).toInt()}-$position';
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
