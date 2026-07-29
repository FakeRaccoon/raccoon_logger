import 'dart:convert';

import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';

/// Serializes captured calls into a [HAR 1.2](http://www.softwareishard.com/blog/har-12-spec/)
/// document (JSON) for import into browser devtools, Charles, Postman, etc.
class RaccoonHar {
  /// Returns a pretty-printed HAR 1.2 JSON string for [calls]. Only completed
  /// calls (those with a response) are included — an entry with no response is
  /// not valid HAR.
  static String generate(List<RaccoonHttpCall> calls) {
    final entries = calls.where((c) => c.response != null).map(_entry).toList();

    final har = {
      'log': {
        'version': '1.2',
        'creator': {'name': 'raccoon', 'version': '1.0'},
        'entries': entries,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(har);
  }

  static Map<String, dynamic> _entry(RaccoonHttpCall call) {
    final req = call.request;
    final res = call.response!;
    final uri = Uri.tryParse(call.uri);

    return {
      'startedDateTime': call.createdTime.toUtc().toIso8601String(),
      'time': call.duration,
      'request': {
        'method': call.method,
        'url': call.uri,
        'httpVersion': 'HTTP/1.1',
        'headers': _headers(req?.headers),
        'queryString': _query(uri),
        'cookies': const [],
        'headersSize': -1,
        'bodySize': req?.size ?? 0,
        if (_hasBody(req)) 'postData': _postData(req!),
      },
      'response': {
        'status': res.status ?? 0,
        'statusText': RaccoonFormatHelpers.getStatusMessage(res.status),
        'httpVersion': 'HTTP/1.1',
        'headers': _headers(res.headers),
        'cookies': const [],
        'content': {
          'size': res.size,
          'mimeType': _contentType(res.headers),
          'text': res.body?.toString() ?? '',
        },
        'redirectURL': '',
        'headersSize': -1,
        'bodySize': res.size,
      },
      'cache': const {},
      // Only the total duration is captured, so it all lands in `wait`.
      'timings': {'send': 0, 'wait': call.duration, 'receive': 0},
    };
  }

  static List<Map<String, String>> _headers(Map<String, String>? headers) {
    if (headers == null) return const [];
    return headers.entries
        .map((e) => {'name': e.key, 'value': e.value})
        .toList();
  }

  static List<Map<String, String>> _query(Uri? uri) {
    if (uri == null) return const [];
    return uri.queryParameters.entries
        .map((e) => {'name': e.key, 'value': e.value})
        .toList();
  }

  static bool _hasBody(RaccoonHttpRequest? req) {
    if (req == null) return false;
    if (req.formDataFields != null && req.formDataFields!.isNotEmpty) {
      return true;
    }
    final body = req.body;
    if (body == null) return false;
    if (body is String && (body.isEmpty || body == 'Form Data')) return false;
    return true;
  }

  static Map<String, dynamic> _postData(RaccoonHttpRequest req) {
    final mimeType = req.contentType ?? '';
    final fields = req.formDataFields;
    if (fields != null && fields.isNotEmpty) {
      return {
        'mimeType': mimeType,
        'params': fields
            .map((f) => {'name': f.name, 'value': f.value})
            .toList(),
      };
    }
    return {'mimeType': mimeType, 'text': req.body.toString()};
  }

  static String _contentType(Map<String, String> headers) {
    return headers['content-type'] ?? headers['Content-Type'] ?? '';
  }
}
