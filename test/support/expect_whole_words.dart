import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void expectWholeWords(WidgetTester tester, String text) {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse, reason: text);
  for (final match in RegExp(r'\S+').allMatches(text)) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: match.start, extentOffset: match.end),
    );
    expect(boxes, isNotEmpty, reason: 'Missing glyphs: ${match.group(0)}');
    final top = boxes.first.top;
    for (final box in boxes) {
      expect(box.top, closeTo(top, 1),
          reason: 'Split word: ${match.group(0)} in $text');
      expect(box.left, greaterThanOrEqualTo(-1));
      expect(box.right, lessThanOrEqualTo(paragraph.size.width + 1));
    }
  }
}
