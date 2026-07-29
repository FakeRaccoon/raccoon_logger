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
}
