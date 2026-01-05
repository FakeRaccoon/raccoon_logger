import 'dart:convert';

import 'package:flutter/material.dart';

/// Utility class for formatting and syntax highlighting response bodies
class RaccoonFormatter {
  /// Detects the content type from headers or body
  static String detectContentType(
    Map<String, String>? headers,
    dynamic body,
  ) {
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
          final content = xml.substring(
            i,
            nextTag == -1 ? xml.length : nextTag,
          ).trim();

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

  /// Creates a syntax-highlighted widget for JSON
  static Widget buildJsonWidget(String json) {
    try {
      final lines = json.split('\n');
      return SelectableText.rich(
        TextSpan(
          children: lines
              .map((line) => TextSpan(
                    children: [
                      ..._highlightJsonLine(line),
                      const TextSpan(text: '\n'),
                    ],
                  ))
              .expand((span) => span.children!)
              .toList(),
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      );
    } catch (e) {
      return SelectableText(json);
    }
  }

  /// Creates a syntax-highlighted widget for XML
  static Widget buildXmlWidget(String xml) {
    return SelectableText.rich(
      TextSpan(
        children: _highlightXml(xml),
      ),
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
      ),
    );
  }

  static List<TextSpan> _highlightJsonLine(String line) {
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
        final isKey = end < trimmed.length - 1 &&
                     trimmed.substring(end + 1).trimLeft().startsWith(':');

        spans.add(TextSpan(
          text: trimmed.substring(i, end + 1),
          style: TextStyle(
            color: isKey ? Colors.purple[700] : Colors.green[700],
            fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
          ),
        ));
        i = end + 1;
        continue;
      }

      // Numbers
      if (_isDigitOrSign(trimmed[i])) {
        final match = RegExp(r'-?\d+\.?\d*').matchAsPrefix(trimmed, i);
        if (match != null) {
          spans.add(TextSpan(
            text: match.group(0),
            style: TextStyle(color: Colors.blue[700]),
          ));
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
        spans.add(TextSpan(
          text: word,
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.bold,
          ),
        ));
        i += word.length;
        continue;
      }

      // Structural characters
      if ('{[]},:'.contains(trimmed[i])) {
        spans.add(TextSpan(
          text: trimmed[i],
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ));
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
    return char == '-' || char == '+' || (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57);
  }

  static List<TextSpan> _highlightXml(String xml) {
    final spans = <TextSpan>[];
    final lines = xml.split('\n');

    for (final line in lines) {
      // Tag
      if (line.trim().startsWith('<')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: Colors.blue[700]),
        ));
      } else {
        // Content
        spans.add(TextSpan(text: line));
      }
      spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }
}
