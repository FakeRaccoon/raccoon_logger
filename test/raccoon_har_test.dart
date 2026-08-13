import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/utils/raccoon_har.dart';

void main() {
  RaccoonHttpCall getCall() => RaccoonHttpCall(
    id: 1,
    method: 'GET',
    endpoint: '/users',
    uri: 'https://api.test/users?page=2&sort=name',
    duration: 123,
    request: RaccoonHttpRequest(headers: {'Accept': 'application/json'}),
    response: RaccoonHttpResponse(
      status: 200,
      size: 42,
      headers: {'content-type': 'application/json'},
      body: '{"ok":true}',
    ),
  );

  RaccoonHttpCall postCall() => RaccoonHttpCall(
    id: 2,
    method: 'POST',
    endpoint: '/login',
    uri: 'https://api.test/login',
    duration: 50,
    request: RaccoonHttpRequest(
      body: '{"user":"a"}',
      contentType: 'application/json',
      size: 12,
    ),
    response: RaccoonHttpResponse(status: 201, size: 0),
  );

  RaccoonHttpCall pendingCall() =>
      RaccoonHttpCall(id: 3, method: 'GET', uri: 'https://api.test/pending');

  test('generates valid HAR 1.2 with one entry per completed call', () {
    final har =
        jsonDecode(RaccoonHar.generate([getCall(), postCall()]))
            as Map<String, dynamic>;

    final log = har['log'] as Map<String, dynamic>;
    expect(log['version'], '1.2');
    expect((log['creator'] as Map)['name'], 'raccoon');

    final entries = log['entries'] as List;
    expect(entries.length, 2);

    final first = entries.first as Map<String, dynamic>;
    final request = first['request'] as Map<String, dynamic>;
    expect(request['method'], 'GET');
    expect(request['url'], 'https://api.test/users?page=2&sort=name');
    expect((first['response'] as Map)['status'], 200);
    expect((first['timings'] as Map)['wait'], 123);
  });

  test('queryString is parsed from the URL', () {
    final har =
        jsonDecode(RaccoonHar.generate([getCall()])) as Map<String, dynamic>;
    final entry = ((har['log'] as Map)['entries'] as List).first as Map;
    final query = (entry['request'] as Map)['queryString'] as List;

    expect(
      query,
      containsAll([
        {'name': 'page', 'value': '2'},
        {'name': 'sort', 'value': 'name'},
      ]),
    );
  });

  test('POST body becomes postData; GET has none', () {
    final har =
        jsonDecode(RaccoonHar.generate([getCall(), postCall()]))
            as Map<String, dynamic>;
    final entries = (har['log'] as Map)['entries'] as List;

    expect((entries[0] as Map)['request'], isNot(contains('postData')));

    final postData = ((entries[1] as Map)['request'] as Map)['postData'] as Map;
    expect(postData['mimeType'], 'application/json');
    expect(postData['text'], '{"user":"a"}');
  });

  test('pending calls (no response) are excluded', () {
    final har =
        jsonDecode(RaccoonHar.generate([getCall(), pendingCall()]))
            as Map<String, dynamic>;
    expect(((har['log'] as Map)['entries'] as List).length, 1);
  });

  test('empty input yields a valid empty HAR', () {
    final har = jsonDecode(RaccoonHar.generate([])) as Map<String, dynamic>;
    expect((har['log'] as Map)['entries'], isEmpty);
  });
}
