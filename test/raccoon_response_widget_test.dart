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
}
