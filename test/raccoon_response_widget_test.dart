import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/utils/raccoon_formatter.dart';
import 'package:raccoon/view/components/raccoon_response_widget.dart';

/// (text, backgroundColor) for every span, so highlight placement is visible.
List<(String, Color?)> _painted(List<TextSpan> spans) => [
  for (final span in spans) (span.text ?? '', span.style?.backgroundColor),
];

void main() {
  group('highlightMatches', () {
    const yellow = Color(0xFFFFFF00);
    const orange = Color(0xFFFF9800);

    List<TextSpan> highlight(List<TextSpan> spans, String query, int active) =>
        RaccoonFormatter.highlightMatches(
          spans,
          query: query,
          activeIndex: active,
          color: yellow,
          activeColor: orange,
        );

    test('splits a span around each match and marks the active one', () {
      final spans = highlight([const TextSpan(text: 'ab XY ab')], 'ab', 1);

      expect(_painted(spans), [('ab', yellow), (' XY ', null), ('ab', orange)]);
    });

    test('keeps the original style of the span it splits', () {
      const style = TextStyle(fontWeight: FontWeight.bold);
      final spans = highlight(
        [const TextSpan(text: 'name', style: style)],
        'am',
        0,
      );

      expect(
        spans.map((s) => s.style?.fontWeight),
        everyElement(style.fontWeight),
      );
    });

    test('matches that straddle two spans are highlighted in both', () {
      final spans = highlight(
        [const TextSpan(text: '"name"'), const TextSpan(text: ': 1')],
        '": ',
        0,
      );

      expect(_painted(spans), [
        ('"name', null),
        ('"', orange),
        (': ', orange),
        ('1', null),
      ]);
    });

    test('an empty query and a query with no hits leave the spans alone', () {
      const spans = [TextSpan(text: 'abc')];
      expect(highlight(spans, '', 0), same(spans));
      expect(highlight(spans, 'zzz', 0), same(spans));
    });

    test('findMatches reports every occurrence, case-insensitively', () {
      expect(RaccoonFormatter.findMatches('aXa xa', 'A'), [0, 2, 5]);
      expect(RaccoonFormatter.findMatches('aaa', ''), isEmpty);
    });
  });

  group('find bar', () {
    Future<void> pumpResponse(WidgetTester tester, dynamic body) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RaccoonResponseWidget(
                call: RaccoonHttpCall(
                  id: 1,
                  response: RaccoonHttpResponse(
                    status: 200,
                    body: body,
                    headers: const {'content-type': 'application/json'},
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('counts matches and steps through them, wrapping around', (
      tester,
    ) async {
      await pumpResponse(tester, {'name': 'na', 'other': 'nap'});

      await tester.enterText(find.byType(TextField), 'na');
      await tester.pumpAndSettle();

      // "name", "na", "nap"
      expect(find.text('1/3'), findsOneWidget);

      await tester.tap(find.byTooltip('Next match'));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous match'));
      await tester.tap(find.byTooltip('Previous match'));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
    });

    testWidgets('a query with no hits reports 0/0 and disables stepping', (
      tester,
    ) async {
      await pumpResponse(tester, {'name': 'Ervin Howell'});

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('0/0'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.keyboard_arrow_down),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('the body is fully rendered, not filtered down to hits', (
      tester,
    ) async {
      await pumpResponse(tester, {'name': 'Ervin', 'city': 'Wisokyburgh'});

      await tester.enterText(find.byType(TextField), 'name');
      await tester.pumpAndSettle();

      final shown = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!
          .toPlainText();

      expect(shown, contains('name'));
      expect(shown, contains('Wisokyburgh'));
    });
  });

  group('large and binary bodies', () {
    Future<void> pump(
      WidgetTester tester,
      Object? body,
      Map<String, String> headers,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RaccoonResponseWidget(
            call: RaccoonHttpCall(
              id: 1,
              response: RaccoonHttpResponse(
                status: 200,
                body: body,
                headers: headers,
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('a body past the highlight cap renders as one plain span', (
      tester,
    ) async {
      final big = jsonEncode({
        for (var i = 0; i < 4000; i++) 'key$i': 'value$i',
      });
      expect(big.length, greaterThan(64 * 1024));

      await pump(tester, big, const {'content-type': 'application/json'});

      final span = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .textSpan!;
      // Highlighting would have produced a span per token; the whole body is
      // still rendered, just uncoloured.
      expect(span.children, hasLength(1));
      expect(
        span.children!.single.toPlainText().length,
        greaterThan(RaccoonResponseWidget.maxHighlightChars),
      );
    });

    testWidgets('captured image bytes are rendered', (tester) async {
      await pump(tester, _transparentPng, const {'content-type': 'image/png'});
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // no find bar for images
    });

    testWidgets('an image too large to capture explains itself', (
      tester,
    ) async {
      await pump(tester, '<body not captured: 4.0 MB>', const {
        'content-type': 'image/png',
      });

      expect(find.textContaining('too large to capture'), findsOneWidget);
    });
  });
}

/// Smallest valid PNG: a 1×1 transparent pixel.
final Uint8List _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);
