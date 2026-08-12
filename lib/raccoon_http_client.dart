import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:raccoon/model/raccoon_form_data_field.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_form_data_file.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/utils/raccoon_body.dart';
import 'package:raccoon/utils/raccoon_parser.dart';

/// [http.Client] wrapper that captures requests, responses and errors into the
/// shared [RaccoonService] — the `package:http` counterpart of
/// `RaccoonInterceptor`.
///
/// Wrap the client you already use and send everything through it:
///
/// ```dart
/// final client = RaccoonHttpClient();
///
/// await client.get(Uri.parse('https://example.com/todos'));
/// ```
///
/// Response bodies are buffered so they can be shown in the inspector, so a
/// streamed download is fully read into memory before it reaches your code.
class RaccoonHttpClient extends http.BaseClient {
  /// Wraps [inner], or a plain [http.Client] when none is given.
  RaccoonHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final RaccoonService _service = RaccoonService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = identityHashCode(request);
    _captureRequest(request, id);

    try {
      final streamed = await _inner.send(request);
      final bytes = await streamed.stream.toBytes();

      _service.addResponse(
        RaccoonHttpResponse(
          status: streamed.statusCode,
          size: bytes.length,
          // The byte count is already known, so nothing re-measures it — and
          // an oversized body is never decoded in the first place.
          body: bytes.length > RaccoonBody.maxBytes
              ? RaccoonBody.notCaptured(bytes.length)
              : _decodeBody(bytes),
          headers: streamed.headers,
        ),
        id,
      );

      // The original stream is consumed above; hand the caller an equivalent
      // response backed by the buffered bytes.
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        streamed.statusCode,
        contentLength: bytes.length,
        request: streamed.request ?? request,
        headers: streamed.headers,
        isRedirect: streamed.isRedirect,
        persistentConnection: streamed.persistentConnection,
        reasonPhrase: streamed.reasonPhrase,
      );
    } catch (error, stackTrace) {
      _service.addError(
        RaccoonHttpError(error: error.toString(), stackTrace: stackTrace),
        id,
      );
      // Mirrors the Dio interceptor: -1 marks "no response was received".
      _service.addResponse(RaccoonHttpResponse(status: -1), id);
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  void _captureRequest(http.BaseRequest request, int id) {
    try {
      final uri = request.url;
      final path = uri.path.isEmpty ? '/' : uri.path;

      var captured = RaccoonHttpRequest(
        headers: request.headers,
        contentType: request.headers['content-type'] ?? '',
      );

      if (request is http.Request) {
        captured = captured.copyWith(
          body: request.body,
          size: request.bodyBytes.length,
          curl: RaccoonParser.buildCurl(
            method: request.method,
            uri: uri,
            headers: request.headers,
            body: request.body.isEmpty ? null : request.body,
          ),
        );
      } else if (request is http.MultipartRequest) {
        captured = captured.copyWith(
          body: 'Form Data',
          size: request.contentLength,
          formDataFields: [
            for (final entry in request.fields.entries)
              RaccoonFormDataField(entry.key, entry.value),
          ],
          formDataFiles: [
            for (final file in request.files)
              RaccoonHttpFormDataFile(
                file.filename,
                file.contentType.toString(),
              ),
          ],
          curl: RaccoonParser.buildCurl(
            method: request.method,
            uri: uri,
            headers: request.headers,
            formParts: [
              for (final entry in request.fields.entries)
                '${entry.key}=${entry.value}',
              for (final file in request.files)
                '${file.field}=@${file.filename}',
            ],
          ),
        );
      } else {
        // http.StreamedRequest and custom subclasses: the body can only be read
        // once, and that read belongs to the caller.
        captured = captured.copyWith(
          body: '(streamed request)',
          size: request.contentLength ?? 0,
          curl: RaccoonParser.buildCurl(
            method: request.method,
            uri: uri,
            headers: request.headers,
          ),
        );
      }

      _service.addCall(
        RaccoonHttpCall(
          id: id,
          method: request.method,
          endpoint: path,
          server: uri.host,
          uri: uri.toString(),
          request: captured,
        ),
      );
    } catch (e) {
      log('Raccoon: error on request: $e');
    }
  }

  /// Decodes a response body as UTF-8, falling back to a size marker for
  /// binary payloads (images, archives) that would only render as noise.
  static String _decodeBody(List<int> bytes) {
    if (bytes.isEmpty) {
      return '';
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return '<binary body, ${bytes.length} bytes>';
    }
  }
}
