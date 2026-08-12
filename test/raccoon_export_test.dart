import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/raccoon.dart';
import 'package:raccoon/utils/raccoon_file_export.dart';

void main() {
  final service = RaccoonService();

  setUp(service.clearCalls);

  test('saveExportFile writes the contents and returns the path', () async {
    final path = await saveExportFile('raccoon_test.har', '{"log":{}}');

    expect(path, isNotNull);
    final file = File(path!);
    addTearDown(() => file.existsSync() ? file.deleteSync() : null);
    expect(file.readAsStringSync(), '{"log":{}}');
  });

  test('exportHar returns a HAR document of the captured calls', () {
    service.addCall(
      RaccoonHttpCall(
        id: 1,
        method: 'GET',
        endpoint: '/users',
        uri: 'https://example.com/users',
        request: RaccoonHttpRequest(),
        response: RaccoonHttpResponse(status: 200),
      ),
    );

    final har = jsonDecode(Raccoon().exportHar()) as Map<String, dynamic>;
    final log = har['log'] as Map<String, dynamic>;

    expect(log['version'], '1.2');
    expect(log['entries'], hasLength(1));
  });

  test('exportStatsMarkdown reports the threshold the inspector uses', () {
    Raccoon().setDiscordConfig(url: 'https://example.com/hook', threshold: 900);
    addTearDown(
      () => Raccoon().setDiscordConfig(
        url: 'https://example.com/hook',
        threshold: 0,
      ),
    );

    expect(Raccoon().exportStatsMarkdown(), contains('| Slow (>= 900 ms) |'));
  });

  test('the stats threshold falls back to 500 ms when alerts are off', () {
    Raccoon().setDiscordConfig(url: 'https://example.com/hook', threshold: 0);

    expect(RaccoonService().effectiveSlowThreshold, 500);
    expect(Raccoon().exportStatsMarkdown(), contains('| Slow (>= 500 ms) |'));
  });
}
