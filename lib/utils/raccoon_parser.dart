import 'dart:convert';

import 'package:dio/dio.dart';

/// Body parser helper used to parsing body data.
class RaccoonParser {
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
