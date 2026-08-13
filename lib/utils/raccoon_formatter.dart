import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';

/// Utility class for formatting and syntax highlighting response bodies
class RaccoonFormatter {
  /// Detects the content type from headers or body
  static String detectContentType(Map<String, String>? headers, dynamic body) {
    // Check headers first
    if (headers != null) {
      final contentType = headers['content-type'] ?? headers['Content-Type'];
      if (contentType != null) {
        final lowerType = contentType.toLowerCase();
        if (lowerType.contains('json')) return 'json';
        if (lowerType.contains('xml')) return 'xml';
        if (lowerType.contains('html')) return 'html';
        if (lowerType.contains('image')) return 'image';
        if (lowerType.contains('text')) return 'text';
      }
    }

    // Try to detect from body
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          jsonDecode(trimmed);
          return 'json';
        } catch (_) {}
      }
      if (trimmed.startsWith('<?xml') || trimmed.startsWith('<')) {
        return 'xml';
      }
    } else if (body is Uint8List) {
      // Captured bytes — an image or another binary payload. Checked before
      // the List branch below, which would otherwise call it a JSON array.
      return 'image';
    } else if (body is Map || body is List) {
      return 'json';
    }

    return 'text';
  }

  /// Formats JSON with proper indentation
  static String formatJson(dynamic json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      if (json is String) {
        final decoded = jsonDecode(json);
        return encoder.convert(decoded);
      }
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  /// Formats XML with proper indentation (simple implementation)
  static String formatXml(String xml) {
    try {
      final result = StringBuffer();
      var indent = 0;
      var i = 0;

      while (i < xml.length) {
        if (xml[i] == '<') {
          // Find end of tag
          final tagEnd = xml.indexOf('>', i);
          if (tagEnd == -1) break;

          final tag = xml.substring(i, tagEnd + 1);
          final isClosing = tag.startsWith('</');
          final isSelfClosing = tag.endsWith('/>') || tag.startsWith('<?');

          // Decrease indent for closing tags
          if (isClosing) indent = (indent - 1).clamp(0, 100);

          // Add indentation
          if (result.isNotEmpty && !result.toString().endsWith('\n')) {
            result.write('\n');
          }
          result.write('  ' * indent);
          result.write(tag);

          // Increase indent for opening tags
          if (!isClosing && !isSelfClosing && !tag.startsWith('<!')) {
            indent++;
          }

          i = tagEnd + 1;
        } else {
          // Text content between tags
          final nextTag = xml.indexOf('<', i);
          final content = xml
              .substring(i, nextTag == -1 ? xml.length : nextTag)
              .trim();

          if (content.isNotEmpty) {
            result.write(content);
          }

          i = nextTag == -1 ? xml.length : nextTag;
        }
      }

      return result.toString();
    } catch (e) {
      return xml;
    }
  }

  /// Monospace style the response body is rendered with.
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
  );

  /// Syntax-highlighted spans for JSON, in document order.
  ///
  /// The concatenated span texts equal [json], so offsets into [json] map
  /// directly onto the rendered text — which is what the response search uses
  /// to place its highlights.
  ///
  /// [brightness] selects the palette; pass `Theme.of(context).brightness` so
  /// the highlighting stays readable in both light and dark themes.
  static List<TextSpan> jsonSpans(String json, Brightness brightness) {
    final spans = <TextSpan>[];
    final lines = json.split('\n');
    for (var i = 0; i < lines.length; i++) {
      spans.addAll(_highlightJsonLine(lines[i], brightness));
      if (i != lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  /// Syntax-highlighted spans for XML or HTML, in document order.
  static List<TextSpan> xmlSpans(String xml, Brightness brightness) =>
      _highlightXml(xml, brightness);

  /// Creates a syntax-highlighted widget for JSON.
  static Widget buildJsonWidget(String json, {required Brightness brightness}) {
    try {
      return SelectableText.rich(
        TextSpan(children: jsonSpans(json, brightness)),
        style: bodyStyle,
      );
    } catch (e) {
      return SelectableText(json);
    }
  }

  /// Creates a syntax-highlighted widget for XML or HTML.
  ///
  /// [brightness] selects the palette; pass `Theme.of(context).brightness`.
  static Widget buildXmlWidget(String xml, {required Brightness brightness}) {
    return SelectableText.rich(
      TextSpan(children: xmlSpans(xml, brightness)),
      style: bodyStyle,
    );
  }

  /// Splits [spans] so that every occurrence of [query] gets a background,
  /// with the occurrence at [activeIndex] painted in [activeColor] — the
  /// browser find-in-page treatment.
  ///
  /// [spans] must be flat (no nested children) and their texts concatenated
  /// must be the searched text.
  static List<TextSpan> highlightMatches(
    List<TextSpan> spans, {
    required String query,
    required int activeIndex,
    required Color color,
    required Color activeColor,
  }) {
    if (query.isEmpty) {
      return spans;
    }

    // Match against the concatenated text, not per span: a hit can start in a
    // JSON key's span and end inside the punctuation or value span next to it.
    final matches = findMatches(
      spans.map((span) => span.text ?? '').join(),
      query,
    );
    if (matches.isEmpty) {
      return spans;
    }

    final result = <TextSpan>[];
    var spanStart = 0;
    var matchIndex = 0;

    for (final span in spans) {
      final text = span.text ?? '';
      if (text.isEmpty) {
        result.add(span);
        continue;
      }

      var cursor = 0;
      while (cursor < text.length) {
        // Drop matches that ended before this point.
        while (matchIndex < matches.length &&
            matches[matchIndex] + query.length <= spanStart + cursor) {
          matchIndex++;
        }

        if (matchIndex >= matches.length) {
          result.add(_sliced(span, text.substring(cursor)));
          break;
        }

        final start = matches[matchIndex] - spanStart;
        if (start > cursor) {
          final until = start < text.length ? start : text.length;
          result.add(_sliced(span, text.substring(cursor, until)));
          cursor = until;
          if (cursor >= text.length) {
            break;
          }
        }

        final matchEnd = matches[matchIndex] + query.length - spanStart;
        final until = matchEnd < text.length ? matchEnd : text.length;
        result.add(
          _highlighted(
            span,
            text.substring(cursor, until),
            matchIndex == activeIndex ? activeColor : color,
          ),
        );
        cursor = until;
      }

      spanStart += text.length;
    }

    return result;
  }

  static TextSpan _sliced(TextSpan source, String text) =>
      TextSpan(text: text, style: source.style);

  static TextSpan _highlighted(
    TextSpan source,
    String text,
    Color background,
  ) => TextSpan(
    text: text,
    style: (source.style ?? const TextStyle()).copyWith(
      backgroundColor: background,
    ),
  );

  /// Offsets of every case-insensitive occurrence of [query] in [text].
  static List<int> findMatches(String text, String query) {
    if (query.isEmpty) {
      return const [];
    }
    final lower = text.toLowerCase();
    final needle = query.toLowerCase();
    final offsets = <int>[];
    var from = 0;
    while (true) {
      final at = lower.indexOf(needle, from);
      if (at < 0) {
        return offsets;
      }
      offsets.add(at);
      from = at + needle.length;
    }
  }

  static List<TextSpan> _highlightJsonLine(String line, Brightness brightness) {
    final spans = <TextSpan>[];

    // Handle indentation (spaces)
    final leadingSpaces = line.length - line.trimLeft().length;
    if (leadingSpaces > 0) {
      spans.add(TextSpan(text: ' ' * leadingSpaces));
    }

    final trimmed = line.trimLeft();

    // Handle empty lines
    if (trimmed.isEmpty) {
      return spans;
    }

    var i = 0;
    while (i < trimmed.length) {
      // String keys (property names)
      if (trimmed[i] == '"') {
        final end = _findStringEnd(trimmed, i + 1);
        final isKey =
            end < trimmed.length - 1 &&
            trimmed.substring(end + 1).trimLeft().startsWith(':');

        spans.add(
          TextSpan(
            text: trimmed.substring(i, end + 1),
            style: TextStyle(
              color: RaccoonFormatHelpers.tone(
                isKey ? Colors.purple : Colors.green,
                brightness,
              ),
              fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
        i = end + 1;
        continue;
      }

      // Numbers
      if (_isDigitOrSign(trimmed[i])) {
        final match = RegExp(r'-?\d+\.?\d*').matchAsPrefix(trimmed, i);
        if (match != null) {
          spans.add(
            TextSpan(
              text: match.group(0),
              style: TextStyle(
                color: RaccoonFormatHelpers.tone(Colors.blue, brightness),
              ),
            ),
          );
          i = match.end;
          continue;
        }
      }

      // Booleans and null
      if (trimmed.substring(i).startsWith('true') ||
          trimmed.substring(i).startsWith('false') ||
          trimmed.substring(i).startsWith('null')) {
        final word = trimmed.substring(i).startsWith('true')
            ? 'true'
            : trimmed.substring(i).startsWith('false')
            ? 'false'
            : 'null';
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: RaccoonFormatHelpers.tone(Colors.orange, brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        i += word.length;
        continue;
      }

      // Structural characters
      if ('{[]},:'.contains(trimmed[i])) {
        spans.add(
          TextSpan(
            text: trimmed[i],
            style: TextStyle(
              color: RaccoonFormatHelpers.tone(Colors.grey, brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        i++;
        continue;
      }

      // Default (whitespace, etc.)
      spans.add(TextSpan(text: trimmed[i]));
      i++;
    }

    return spans;
  }

  static int _findStringEnd(String str, int start) {
    for (var i = start; i < str.length; i++) {
      if (str[i] == '"' && (i == 0 || str[i - 1] != '\\')) {
        return i;
      }
    }
    return str.length - 1;
  }

  static bool _isDigitOrSign(String char) {
    return char == '-' ||
        char == '+' ||
        (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57);
  }

  static final RegExp _xmlTagPattern = RegExp(r'<[^>]*>');

  /// Colors `<tags>` and leaves text content in the default (theme) color, so
  /// a line like `<title>403 Forbidden</title>` stays readable.
  static List<TextSpan> _highlightXml(String xml, Brightness brightness) {
    final tagStyle = TextStyle(
      color: RaccoonFormatHelpers.tone(Colors.blue, brightness),
    );
    final spans = <TextSpan>[];

    var index = 0;
    for (final match in _xmlTagPattern.allMatches(xml)) {
      if (match.start > index) {
        spans.add(TextSpan(text: xml.substring(index, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: tagStyle));
      index = match.end;
    }
    if (index < xml.length) {
      spans.add(TextSpan(text: xml.substring(index)));
    }

    return spans;
  }
}
