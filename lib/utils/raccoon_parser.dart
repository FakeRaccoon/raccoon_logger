import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Body parser helper used to parsing body data.
class RaccoonParser {
  static const String _jsonContentTypeSmall = 'content-type';
  static const String _jsonContentTypeBig = 'Content-Type';
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  static String generateCurlCommand(RequestOptions options) {
    final curl = StringBuffer();
    curl.write("curl -X ${options.method}");

    // Add headers
    options.headers.forEach((key, value) {
      curl.write(' -H "$key: $value"');
    });

    // Handle FormData
    if (options.data is FormData) {
      final formData = options.data as FormData;

      // Add fields
      for (var field in formData.fields) {
        curl.write(' --form "${field.key}=${field.value}"');
      }

      // Add files
      for (var file in formData.files) {
        curl.write(' --form "${file.key}=@${file.value.filename}"');
      }
    } else if (options.data != null) {
      // Handle other data types
      final data = options.data is Map
          ? jsonEncode(options.data)
          : options.data.toString();
      curl.write(" -d '${data.replaceAll("'", "\\'")}'");
    }

    // Add URL
    curl.write(' "${options.uri}"');

    return curl.toString();
  }

  /// Formats body based on [contentType]. If body is null it will return
  /// [_emptyBody]. Otherwise if body type is json - it will try to format it.
  ///
  static String formatJson(Map<String, dynamic> jsonString) {
    try {
      return _encoder.convert(jsonString); // Pretty-print with indentation
    } catch (e) {
      return ""; // Return the original string if it's not valid JSON
    }
  }

  /// Get content type from [headers]. It looks for json and if it can't find
  /// it, it will return unknown content type.
  static String? getContentType({
    required BuildContext context,
    Map<String, String>? headers,
  }) {
    if (headers != null) {
      if (headers.containsKey(_jsonContentTypeSmall)) {
        return headers[_jsonContentTypeSmall];
      }
      if (headers.containsKey(_jsonContentTypeBig)) {
        return headers[_jsonContentTypeBig];
      }
    }
    return "Unknown content type";
  }

  /// Parses headers from [dynamic] to [Map<String,String>], if possible.
  /// Otherwise it will throw error.
  static Map<String, String> parseHeaders({dynamic headers}) {
    if (headers is Map<String, String>) {
      return headers;
    }

    if (headers is Map<String, dynamic>) {
      return headers.map((key, value) => MapEntry(key, value.toString()));
    }

    throw ArgumentError("Invalid headers value.");
  }
}
