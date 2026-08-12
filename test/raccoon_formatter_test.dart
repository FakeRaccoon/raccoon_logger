import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/utils/raccoon_formatter.dart';

void main() {
  group('detectContentType', () {
    test('from content-type header', () {
      expect(
        RaccoonFormatter.detectContentType({
          'content-type': 'application/json',
        }, ''),
        'json',
      );
      expect(
        RaccoonFormatter.detectContentType({'Content-Type': 'text/xml'}, ''),
        'xml',
      );
    });

    test('from body when no header', () {
      expect(RaccoonFormatter.detectContentType(null, '{"a":1}'), 'json');
      expect(RaccoonFormatter.detectContentType(null, '<root/>'), 'xml');
      expect(RaccoonFormatter.detectContentType(null, {'a': 1}), 'json');
      expect(RaccoonFormatter.detectContentType(null, 'plain'), 'text');
    });
  });

  group('formatJson', () {
    test('pretty-prints a map', () {
      expect(RaccoonFormatter.formatJson({'a': 1}), '{\n  "a": 1\n}');
    });

    test('parses then pretty-prints a json string', () {
      expect(RaccoonFormatter.formatJson('{"a":1}'), '{\n  "a": 1\n}');
    });

    test('returns input string on invalid json', () {
      expect(RaccoonFormatter.formatJson('not json'), 'not json');
    });
  });

  group('formatXml', () {
    test('indents nested elements onto separate lines', () {
      final out = RaccoonFormatter.formatXml('<a><b>1</b></a>');
      final lines = out.split('\n');
      expect(lines.first, '<a>');
      expect(lines.last, '</a>');
      expect(out, contains('  <b>')); // child indented two spaces
      expect(lines.length, greaterThan(2));
    });
  });

  group('syntax highlighting', () {
    /// Flattens the rendered spans into (text, color) pairs.
    List<(String, Color?)> spansOf(Widget widget) {
      final root = (widget as SelectableText).textSpan!;
      return [
        for (final span in root.children!.cast<TextSpan>())
          (span.text ?? '', span.style?.color),
      ];
    }

    test('xml colors tags but leaves text content readable', () {
      final spans = spansOf(
        RaccoonFormatter.buildXmlWidget(
          '<title>403 Forbidden</title>',
          brightness: Brightness.dark,
        ),
      );

      final content = spans.firstWhere((s) => s.$1 == '403 Forbidden');
      final tag = spans.firstWhere((s) => s.$1 == '<title>');

      // The whole line used to be painted as a tag, hiding the message.
      expect(content.$2, isNull, reason: 'content inherits the theme color');
      expect(tag.$2, isNotNull);
    });

    test('the palette follows the theme brightness', () {
      Color? tagColor(Brightness brightness) => spansOf(
        RaccoonFormatter.buildXmlWidget('<a>x</a>', brightness: brightness),
      ).firstWhere((s) => s.$1 == '<a>').$2;

      expect(tagColor(Brightness.dark), isNot(tagColor(Brightness.light)));
    });
  });
}
