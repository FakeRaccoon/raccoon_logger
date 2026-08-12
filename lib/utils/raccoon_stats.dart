import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';

/// Why a call needs attention. A failed call is reported as [failed] even when
/// it was also slow, so it is only listed once.
enum RaccoonAttention { failed, slow }

/// One row of the "needs attention" list.
class RaccoonAttentionEntry {
  const RaccoonAttentionEntry(this.call, this.reason);

  final RaccoonHttpCall call;
  final RaccoonAttention reason;
}

/// Aggregated timings for one `METHOD /endpoint` pair.
class RaccoonEndpointStat {
  const RaccoonEndpointStat({
    required this.method,
    required this.endpoint,
    required this.count,
    required this.p95,
    required this.totalDuration,
  });

  final String method;
  final String endpoint;
  final int count;
  final int p95;

  /// Time spent across every call to this endpoint — the number that decides
  /// where the app's time actually goes, unlike a single slow outlier.
  final int totalDuration;
}

/// Summary of a set of captured calls, as rendered by the statistics screen.
class RaccoonStats {
  const RaccoonStats({
    required this.total,
    required this.failed,
    required this.slow,
    required this.p50,
    required this.p95,
    required this.maxDuration,
    required this.bytesSent,
    required this.bytesReceived,
    required this.statusClasses,
    required this.methods,
    required this.endpoints,
    required this.attention,
    required this.slowThreshold,
  });

  final int total;
  final int failed;
  final int slow;

  /// Percentiles over completed calls. Averages hide the tail that matters:
  /// fifty fast calls bury the three that took three seconds.
  final int p50;
  final int p95;
  final int maxDuration;

  final int bytesSent;
  final int bytesReceived;

  /// Counts keyed by status class — `2xx`…`5xx`, plus `err` for calls that
  /// never got a response.
  final Map<String, int> statusClasses;
  final Map<String, int> methods;

  /// Endpoints, slowest by total time first.
  final List<RaccoonEndpointStat> endpoints;

  /// Failed and slow calls in one list, worst first.
  final List<RaccoonAttentionEntry> attention;

  final int slowThreshold;

  double get failureRate => total == 0 ? 0 : failed * 100 / total;

  /// Builds the summary.
  ///
  /// [slowThreshold] is the duration in milliseconds at or above which a
  /// completed call counts as slow.
  factory RaccoonStats.from(
    List<RaccoonHttpCall> calls, {
    int slowThreshold = 500,
  }) {
    final completed = <RaccoonHttpCall>[];
    final statusClasses = <String, int>{};
    final methods = <String, int>{};
    final durationsByEndpoint = <String, List<int>>{};
    var failed = 0;
    var slow = 0;
    var bytesSent = 0;
    var bytesReceived = 0;
    final attention = <RaccoonAttentionEntry>[];

    for (final call in calls) {
      methods[call.method] = (methods[call.method] ?? 0) + 1;
      bytesSent += call.request?.size ?? 0;
      bytesReceived += call.response?.size ?? 0;

      final status = call.response?.status;
      if (status == null) {
        continue; // Still in flight.
      }

      completed.add(call);
      statusClasses.update(
        statusClassOf(call),
        (count) => count + 1,
        ifAbsent: () => 1,
      );

      final isFailed = isFailure(call);
      final isSlow = slowThreshold > 0 && call.duration >= slowThreshold;
      if (isFailed) {
        failed++;
      }
      if (isSlow) {
        slow++;
      }
      if (isFailed || isSlow) {
        attention.add(
          RaccoonAttentionEntry(
            call,
            isFailed ? RaccoonAttention.failed : RaccoonAttention.slow,
          ),
        );
      }

      final key = '${call.method} ${call.endpoint}';
      (durationsByEndpoint[key] ??= []).add(call.duration);
    }

    // Failures first, then the slowest — the order you want to read them in.
    attention.sort((a, b) {
      final byReason = a.reason.index.compareTo(b.reason.index);
      return byReason != 0
          ? byReason
          : b.call.duration.compareTo(a.call.duration);
    });

    final durations = completed.map((call) => call.duration).toList()..sort();

    final endpoints = durationsByEndpoint.entries.map((entry) {
      final sorted = List<int>.from(entry.value)..sort();
      final space = entry.key.indexOf(' ');
      return RaccoonEndpointStat(
        method: entry.key.substring(0, space),
        endpoint: entry.key.substring(space + 1),
        count: sorted.length,
        p95: percentile(sorted, 95),
        totalDuration: sorted.reduce((a, b) => a + b),
      );
    }).toList()..sort((a, b) => b.totalDuration.compareTo(a.totalDuration));

    return RaccoonStats(
      total: calls.length,
      failed: failed,
      slow: slow,
      p50: percentile(durations, 50),
      p95: percentile(durations, 95),
      maxDuration: durations.isEmpty ? 0 : durations.last,
      bytesSent: bytesSent,
      bytesReceived: bytesReceived,
      statusClasses: statusClasses,
      methods: methods,
      endpoints: endpoints,
      attention: attention,
      slowThreshold: slowThreshold,
    );
  }

  /// Whether a finished call counts as a failure: a transport error, the
  /// interceptors' `-1` "no response" marker, or a 4xx/5xx status.
  static bool isFailure(RaccoonHttpCall call) {
    final status = call.response?.status;
    return call.error != null ||
        status == -1 ||
        (status != null && status >= 400);
  }

  /// `2xx`…`5xx`, or `err` for a call that never got a response.
  static String statusClassOf(RaccoonHttpCall call) {
    final status = call.response?.status;
    if (status == null || status < 100) {
      return 'err';
    }
    return '${status ~/ 100}xx';
  }

  /// Nearest-rank percentile over an ascending list; 0 when empty.
  static int percentile(List<int> ascending, int percent) {
    if (ascending.isEmpty) {
      return 0;
    }
    final rank = (ascending.length * percent / 100).ceil().clamp(
      1,
      ascending.length,
    );
    return ascending[rank - 1];
  }

  /// The report behind the screen's download button.
  String toMarkdown({DateTime? generatedAt}) {
    final buf = StringBuffer();
    final now = generatedAt ?? DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');

    buf
      ..writeln('# Raccoon Stats Report')
      ..writeln(
        '_Generated ${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}_',
      )
      ..writeln()
      ..writeln('## Overview')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('|--------|-------|')
      ..writeln('| Total requests | $total |')
      ..writeln('| Failed | $failed (${failureRate.toStringAsFixed(1)}%) |')
      ..writeln('| Slow (>= $slowThreshold ms) | $slow |')
      ..writeln('| p50 / p95 / max | $p50 / $p95 / $maxDuration ms |')
      ..writeln('| Sent | ${RaccoonFormatHelpers.formatBytes(bytesSent)} |')
      ..writeln(
        '| Received | ${RaccoonFormatHelpers.formatBytes(bytesReceived)} |',
      )
      ..writeln();

    if (statusClasses.isNotEmpty) {
      buf
        ..writeln('## Status')
        ..writeln();
      final keys = statusClasses.keys.toList()..sort();
      for (final key in keys) {
        buf.writeln('- $key: ${statusClasses[key]}');
      }
      buf.writeln();
    }

    if (methods.isNotEmpty) {
      buf
        ..writeln('## Methods')
        ..writeln();
      for (final entry in methods.entries) {
        buf.writeln('- ${entry.key}: ${entry.value}');
      }
      buf.writeln();
    }

    if (endpoints.isNotEmpty) {
      buf
        ..writeln('## Endpoints (by total time)')
        ..writeln()
        ..writeln('| Endpoint | Calls | p95 | Total |')
        ..writeln('|----------|-------|-----|-------|');
      for (final endpoint in endpoints) {
        buf.writeln(
          '| `${endpoint.method} ${endpoint.endpoint}` | ${endpoint.count} '
          '| ${endpoint.p95} ms | ${endpoint.totalDuration} ms |',
        );
      }
      buf.writeln();
    }

    if (attention.isNotEmpty) {
      buf
        ..writeln('## Needs attention')
        ..writeln()
        ..writeln('| Status | Endpoint | Duration | Reason |')
        ..writeln('|--------|----------|----------|--------|');
      for (final entry in attention) {
        final status = entry.call.response?.status;
        buf.writeln(
          '| ${status == -1 || status == null ? 'ERR' : status} '
          '| `${entry.call.method} ${entry.call.endpoint}` '
          '| ${entry.call.duration} ms '
          '| ${entry.reason == RaccoonAttention.failed ? 'failed' : 'slow'} |',
        );
      }
      buf.writeln();
    }

    return buf.toString();
  }
}
