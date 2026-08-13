import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_form_data_field.dart';
import 'package:raccoon/model/raccoon_http_form_data_file.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/raccoon.dart';

/// Answers every request with 200 and records the options it was handed.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? seen;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final service = RaccoonService();
  late _CapturingAdapter adapter;

  setUp(() {
    adapter = _CapturingAdapter();
    service.setDioInstance(Dio()..httpClientAdapter = adapter);
  });

  test('the query string is sent once, not doubled', () async {
    await service.replayRequest(
      RaccoonHttpCall(
        id: 1,
        method: 'GET',
        uri: 'https://example.com/users?page=2&sort=name',
        request: RaccoonHttpRequest(),
      ),
    );

    expect(
      adapter.seen!.uri.toString(),
      'https://example.com/users?page=2&sort=name',
    );
    expect(adapter.seen!.uri.queryParametersAll['page'], ['2']);
  });

  test('content-length and host are not replayed', () async {
    await service.replayRequest(
      RaccoonHttpCall(
        id: 1,
        method: 'POST',
        uri: 'https://example.com/orders',
        request: RaccoonHttpRequest(
          body: '{"a":1}',
          headers: const {
            'Content-Length': '999',
            'host': 'stale.example.com',
            'authorization': 'Bearer token',
          },
        ),
      ),
    );

    final headers = {
      for (final entry in adapter.seen!.headers.entries)
        entry.key.toLowerCase(): '${entry.value}',
    };
    // The stale length is gone; whatever content-length goes out is the one
    // Dio computed for the body it is actually sending.
    expect(headers['content-length'], isNot('999'));
    expect(headers['content-length'], '${'{"a":1}'.length}');
    expect(headers.containsKey('host'), isFalse);
    // Everything else is the request, and is replayed as captured.
    expect(headers['authorization'], 'Bearer token');
  });

  test('replayHeaders drops transmission headers case-insensitively', () {
    expect(
      RaccoonService.replayHeaders(const {
        'CONTENT-LENGTH': '12',
        'Transfer-Encoding': 'chunked',
        'Content-Type': 'application/json',
      }),
      {'Content-Type': 'application/json'},
    );
  });

  test('a multipart upload refuses to replay instead of dropping the file', () {
    expect(
      () => service.replayRequest(
        RaccoonHttpCall(
          id: 1,
          method: 'POST',
          uri: 'https://example.com/upload',
          request: RaccoonHttpRequest(
            body: 'Form Data',
            formDataFiles: const [
              RaccoonHttpFormDataFile('avatar.png', 'image/png'),
            ],
          ),
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('file contents are not captured'),
        ),
      ),
    );
  });

  test('form fields alone still replay', () async {
    await service.replayRequest(
      RaccoonHttpCall(
        id: 1,
        method: 'POST',
        uri: 'https://example.com/form',
        request: RaccoonHttpRequest(
          body: 'Form Data',
          formDataFields: [RaccoonFormDataField('name', 'raccoon')],
        ),
      ),
    );

    expect(adapter.seen!.data, isA<FormData>());
  });
}
