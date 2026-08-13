import 'dart:convert';

import 'package:raccoon/utils/raccoon_format_helpers.dart';

/// What the inspector keeps of a request or response body, and how big the
/// body actually was.
typedef RaccoonCapturedBody = ({Object? body, int size});

/// Bounds what a captured body costs.
///
/// Bodies are held in memory for up to the call cap, so a handful of large
/// downloads would otherwise be enough to push an app over. Measuring is
/// bounded too: sizing a body used to stringify it and then encode that string
/// to bytes purely to count them, throwing both away.
class RaccoonBody {
  /// Bodies above this are stored truncated. 256 KB is far more than anyone
  /// reads in an inspector, and small enough that a full call list stays cheap.
  // ponytail: fixed cap; expose a setter only if someone asks for it.
  static const int maxBytes = 256 * 1024;

  /// Captures [body], truncating it past [maxBytes].
  ///
  /// [declaredSize] is the size the transport already knows — `content-length`
  /// or the byte count of a buffered response. When it is present and over the
  /// cap, the body is never stringified at all.
  static RaccoonCapturedBody capture(Object? body, {int? declaredSize}) {
    if (body == null) {
      return (body: '', size: declaredSize ?? 0);
    }

    if (declaredSize != null && declaredSize > maxBytes) {
      return (body: notCaptured(declaredSize), size: declaredSize);
    }

    if (body is String) {
      final size = declaredSize ?? utf8.encode(body).length;
      return (body: size > maxBytes ? _truncate(body, size) : body, size: size);
    }

    // Raw bytes (an image, a download): already their own size, and encoding
    // them as JSON would turn a payload into a list of integers.
    if (body is List<int>) {
      final size = body.length;
      return (body: size > maxBytes ? notCaptured(size) : body, size: size);
    }

    // Encode once and reuse the result for both the size and the stored copy.
    // toString() is not an option: it renders a Map as `{a: 1}`, which is not
    // JSON and breaks the formatter.
    final encoded = _encode(body);
    final size = declaredSize ?? utf8.encode(encoded).length;
    if (size > maxBytes) {
      return (body: _truncate(encoded, size), size: size);
    }
    // Small enough to keep the decoded structure, which renders better.
    return (body: body, size: size);
  }

  /// Size of a request body without keeping it — used for the request side,
  /// where the body is stored separately.
  static int sizeOf(Object? body) {
    if (body == null) {
      return 0;
    }
    return utf8.encode(body is String ? body : _encode(body)).length;
  }

  static String _encode(Object? body) {
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  /// Placeholder for a body that was too large to keep. Callers that already
  /// hold the bytes use this to skip decoding entirely.
  static String notCaptured(int size) =>
      '<body not captured: ${RaccoonFormatHelpers.formatBytes(size)}>';

  static String _truncate(String text, int size) =>
      '${text.substring(0, text.length < maxBytes ? text.length : maxBytes)}\n'
      '… truncated, body was ${RaccoonFormatHelpers.formatBytes(size)}';
}
