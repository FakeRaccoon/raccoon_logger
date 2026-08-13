import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_request.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/utils/raccoon_stats.dart';

int _id = 0;

RaccoonHttpCall _call({
  int? status,
  int duration = 0,
  String method = 'GET',
  String endpoint = '/a',
  String? error,
  int sent = 0,
  int received = 0,
}) => RaccoonHttpCall(
  id: _id++,
  method: method,
  endpoint: endpoint,
  duration: duration,
  request: RaccoonHttpRequest(size: sent),
  response: status == null
      ? null
      : RaccoonHttpResponse(status: status, size: received),
  error: error == null ? null : RaccoonHttpError(error: error),
);

void main() {
  test('percentile uses nearest rank and survives an empty list', () {
    expect(RaccoonStats.percentile(const [], 95), 0);
    expect(RaccoonStats.percentile(const [10], 50), 10);
    expect(RaccoonStats.percentile(const [1, 2, 3, 4], 50), 2);
    expect(RaccoonStats.percentile(const [1, 2, 3, 4], 95), 4);
  });

  test('p95 tracks the tail that an average would bury', () {
    // 18 fast calls and 2 slow ones: the average is ~309 ms, which describes
    // neither group. Nearest-rank p95 of 20 samples is the 19th, so the slow
    // pair is what p95 reports.
    final stats = RaccoonStats.from([
      for (var i = 0; i < 18; i++) _call(status: 200, duration: 10),
      _call(status: 200, duration: 3000),
      _call(status: 200, duration: 3000),
    ]);

    expect(stats.p50, 10);
    expect(stats.p95, 3000);
    expect(stats.maxDuration, 3000);
  });

  test('in-flight calls are counted but excluded from timings', () {
    final stats = RaccoonStats.from([
      _call(status: 200, duration: 100),
      _call(duration: 9999), // no response yet
    ]);

    expect(stats.total, 2);
    expect(stats.p95, 100);
    expect(stats.attention, isEmpty);
  });

  test('failures cover errors, 4xx/5xx and the no-response marker', () {
    final stats = RaccoonStats.from([
      _call(status: 200),
      _call(status: 404),
      _call(status: 500),
      _call(status: -1, error: 'SocketException'),
    ]);

    expect(stats.failed, 3);
    expect(stats.failureRate, 75);
    expect(stats.statusClasses, {'2xx': 1, '4xx': 1, '5xx': 1, 'err': 1});
  });

  group('attention list', () {
    test('lists a slow failure once, as a failure', () {
      final stats = RaccoonStats.from([
        _call(status: 500, duration: 4000),
      ], slowThreshold: 500);

      expect(stats.attention, hasLength(1));
      expect(stats.attention.single.reason, RaccoonAttention.failed);
      expect(stats.failed, 1);
      expect(stats.slow, 1);
    });

    test('puts failures before slow calls, worst first', () {
      final stats = RaccoonStats.from([
        _call(status: 200, duration: 900, endpoint: '/slow-a'),
        _call(status: 200, duration: 2000, endpoint: '/slow-b'),
        _call(status: 500, duration: 10, endpoint: '/failed'),
      ], slowThreshold: 500);

      expect(stats.attention.map((e) => e.call.endpoint), [
        '/failed',
        '/slow-b',
        '/slow-a',
      ]);
    });

    test('fast successful calls stay out of it', () {
      final stats = RaccoonStats.from([
        _call(status: 200, duration: 10),
      ], slowThreshold: 500);

      expect(stats.attention, isEmpty);
      expect(stats.slow, 0);
    });
  });

  test('endpoints rank by total time, not by a single outlier', () {
    final stats = RaccoonStats.from([
      _call(status: 200, duration: 3000, endpoint: '/one-off'),
      for (var i = 0; i < 40; i++)
        _call(status: 200, duration: 200, endpoint: '/hot'),
    ]);

    expect(stats.endpoints.first.endpoint, '/hot');
    expect(stats.endpoints.first.count, 40);
    expect(stats.endpoints.first.totalDuration, 8000);
    expect(stats.endpoints.first.p95, 200);
  });

  test('transfer totals sum request and response sizes', () {
    final stats = RaccoonStats.from([
      _call(status: 200, sent: 100, received: 900),
      _call(status: 200, sent: 20, received: 80),
    ]);

    expect(stats.bytesSent, 120);
    expect(stats.bytesReceived, 980);
  });

  test('markdown reports the threshold that produced the numbers', () {
    final markdown = RaccoonStats.from(
      [_call(status: 500, duration: 1200, endpoint: '/orders', method: 'POST')],
      slowThreshold: 1000,
    ).toMarkdown(generatedAt: DateTime(2026, 8, 12, 9, 5));

    expect(markdown, contains('_Generated 2026-08-12 09:05_'));
    expect(markdown, contains('| Slow (>= 1000 ms) | 1 |'));
    expect(markdown, contains('`POST /orders`'));
    expect(markdown, contains('failed'));
  });
}
