import 'dart:convert';

import 'package:dio/dio.dart';

/// Body parser helper used to parsing body data.
class RaccoonParser {
  /// Builds a cURL command from client-agnostic request parts.
  ///
  /// [formParts] are rendered as `--form` flags (`name=value`, or
  /// `name=@filename` for files) and take precedence over [body].
  static String buildCurl({
    required String method,
    required Uri uri,
    Map<String, String> headers = const <String, String>{},
    List<String> formParts = const <String>[],
    String? body,
  }) {
    final curl = StringBuffer('curl -X $method');

    headers.forEach((key, value) {
      curl.write(' -H "$key: $value"');
    });

    if (formParts.isNotEmpty) {
      for (final part in formParts) {
        curl.write(' --form "$part"');
      }
    } else if (body != null) {
      curl.write(" -d '${body.replaceAll("'", "\\'")}'");
    }

    curl.write(' "$uri"');

    return curl.toString();
  }

  static String generateCurlCommand(RequestOptions options) {
    final headers = options.headers.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final data = options.data;

    if (data is FormData) {
      return buildCurl(
        method: options.method,
        uri: options.uri,
        headers: headers,
        formParts: [
          for (final field in data.fields) '${field.key}=${field.value}',
          for (final file in data.files) '${file.key}=@${file.value.filename}',
        ],
      );
    }

    return buildCurl(
      method: options.method,
      uri: options.uri,
      headers: headers,
      body: data == null
          ? null
          : data is Map
          ? jsonEncode(data)
          : data.toString(),
    );
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
