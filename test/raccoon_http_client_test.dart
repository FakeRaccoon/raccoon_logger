import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:raccoon/raccoon.dart';

void main() {
  final service = RaccoonService();

  setUp(service.clearCalls);

  test('captures the request and returns the body unchanged', () async {
    final client = RaccoonHttpClient(
      MockClient(
        (request) async => http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    final response = await client.post(
      Uri.parse('https://example.com/todos?page=2'),
      body: '{"title":"hi"}',
      headers: {'content-type': 'application/json'},
    );

    // The wrapper buffers the stream — the caller must still see the body.
    expect(response.body, '{"ok":true}');
    expect(response.statusCode, 200);

    final call = service.calls.single;
    expect(call.method, 'POST');
    expect(call.endpoint, '/todos');
    expect(call.server, 'example.com');
    expect(call.uri, 'https://example.com/todos?page=2');
    expect(call.request?.body, '{"title":"hi"}');
    expect(call.request?.curl, contains('curl -X POST'));
    expect(call.response?.status, 200);
    expect(call.response?.body, '{"ok":true}');
    expect(call.response?.size, utf8.encode('{"ok":true}').length);
    expect(call.error, isNull);
  });

  test(
    'captures 4xx responses without treating them as transport errors',
    () async {
      final client = RaccoonHttpClient(
        MockClient((request) async => http.Response('nope', 404)),
      );

      await client.get(Uri.parse('https://example.com/missing'));

      expect(service.calls.single.response?.status, 404);
      expect(service.calls.single.error, isNull);
    },
  );

  test('records transport failures and rethrows them', () async {
    final client = RaccoonHttpClient(
      MockClient((request) async => throw http.ClientException('boom')),
    );

    await expectLater(
      client.get(Uri.parse('https://example.com/down')),
      throwsA(isA<http.ClientException>()),
    );

    final call = service.calls.single;
    expect(call.error?.error, contains('boom'));
    expect(call.response?.status, -1);
  });

  test('captures multipart fields and files', () async {
    final client = RaccoonHttpClient(
      MockClient((request) async => http.Response('', 200)),
    );

    final request =
        http.MultipartRequest('POST', Uri.parse('https://example.com/upload'))
          ..fields['title'] = 'avatar'
          ..files.add(
            http.MultipartFile.fromBytes('file', [1, 2, 3], filename: 'a.png'),
          );

    await client.send(request);

    final captured = service.calls.single.request;
    expect(captured?.body, 'Form Data');
    expect(captured?.formDataFields?.single.name, 'title');
    expect(captured?.formDataFiles?.single.fileName, 'a.png');
    expect(captured?.curl, contains('--form "title=avatar"'));
    expect(captured?.curl, contains('--form "file=@a.png"'));
  });

  test('falls back to a size marker for binary bodies', () async {
    final client = RaccoonHttpClient(
      MockClient(
        (request) async => http.Response.bytes([0xC3, 0x28, 0xFF], 200),
      ),
    );

    await client.get(Uri.parse('https://example.com/image.png'));

    expect(service.calls.single.response?.body, '<binary body, 3 bytes>');
  });
}
