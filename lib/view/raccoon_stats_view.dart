import 'dart:math';

import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';
import 'package:raccoon/view/raccoon_detail_view.dart';

class RaccoonStatsView extends StatelessWidget {
  const RaccoonStatsView({super.key, required this.service});

  final RaccoonService service;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final calls = service.calls;

          if (calls.isEmpty) {
            return Center(
              child: Text(
                'No data available',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            );
          }

          final stats = _calculateStats(calls);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverview(context, stats),
                const SizedBox(height: 12),
                _buildTransfer(context, stats),
                const SizedBox(height: 28),
                _buildSection(
                  context,
                  'Timeline',
                  _buildTimeline(context, stats),
                  subtitle: '${stats.timelineBuckets.length} buckets',
                ),
                const SizedBox(height: 28),
                _buildSection(
                  context,
                  'Status Codes',
                  _buildDistribution(
                    context,
                    stats.statusCodeDistribution,
                    stats.totalCalls,
                    _statusCodeColor,
                    labelWidth: 52,
                  ),
                ),
                const SizedBox(height: 28),
                _buildSection(
                  context,
                  'Methods',
                  _buildDistribution(
                    context,
                    stats.methodDistribution,
                    stats.totalCalls,
                    _methodColor,
                    labelWidth: 68,
                  ),
                ),
                const SizedBox(height: 28),
                _buildSection(
                  context,
                  'Endpoints',
                  stats.endpointStats.isEmpty
                      ? _emptyLabel(context, 'No completed requests')
                      : _buildEndpointList(context, stats.endpointStats),
                  subtitle:
                      '${stats.endpointStats.length} unique · avg duration',
                ),
                const SizedBox(height: 28),
                _buildSection(
                  context,
                  'Slow Requests',
                  stats.slowCalls.isEmpty
                      ? _emptyLabel(context, 'No requests above 500ms')
                      : _buildSlowList(
                          context,
                          stats.slowCalls,
                          stats.maxDuration,
                        ),
                  subtitle: '${stats.slowCalls.length} requests · >500ms',
                ),
                const SizedBox(height: 28),
                _buildSection(
                  context,
                  'Failed Requests',
                  stats.failedCalls.isEmpty
                      ? _emptyLabel(context, 'No failed requests')
                      : _buildFailedList(context, stats.failedCalls),
                  subtitle: '${stats.failedCalls.length} errors & 4xx/5xx',
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Overview ──────────────────────────────────────────────────────────────

  Widget _buildOverview(BuildContext context, _Stats stats) {
    final items = [
      ('Total', stats.totalCalls.toString()),
      ('Success', stats.successCount.toString()),
      ('Failed', stats.errorCount.toString()),
      ('Avg', RaccoonFormatHelpers.formatDuration(stats.avgResponseTime.round())),
      ('Slow >500ms', stats.slowCount.toString()),
    ];

    return Row(
      children: items.expand((item) sync* {
        yield Expanded(child: _buildOverviewItem(context, item.$1, item.$2));
        if (item != items.last) {
          yield VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          );
        }
      }).toList(),
    );
  }

  Widget _buildTransfer(BuildContext context, _Stats stats) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(Icons.arrow_upward, size: 11, color: onSurface.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          RaccoonFormatHelpers.formatBytes(stats.totalBytesSent),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.arrow_downward, size: 11, color: onSurface.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          RaccoonFormatHelpers.formatBytes(stats.totalBytesReceived),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context, _Stats stats) {
    if (stats.timelineBuckets.isEmpty) return _emptyLabel(context, 'No data');

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final maxCount =
        stats.timelineBuckets.map((b) => b.count).reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.timelineBuckets.map((bucket) {
              final fraction =
                  maxCount > 0 ? bucket.count / maxCount : 0.0;
              final hasErrors = bucket.errorCount > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: fraction.clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasErrors
                            ? Colors.red.withOpacity(0.55)
                            : onSurface.withOpacity(0.18),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              RaccoonFormatHelpers.formatTimestamp(
                stats.timelineBuckets.first.time,
              ),
              style: TextStyle(
                fontSize: 10,
                color: onSurface.withOpacity(0.35),
              ),
            ),
            Text(
              RaccoonFormatHelpers.formatTimestamp(
                stats.timelineBuckets.last.time,
              ),
              style: TextStyle(
                fontSize: 10,
                color: onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Endpoints ─────────────────────────────────────────────────────────────

  Widget _buildEndpointList(
    BuildContext context,
    List<_EndpointStat> endpoints,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final maxAvg = endpoints.first.avgDuration;

    return Column(
      children: endpoints.mapIndexed((index, ep) {
        final fraction = maxAvg > 0 ? ep.avgDuration / maxAvg : 0.0;
        final avgColor = _durationColor(ep.avgDuration);

        return Column(
          children: [
            if (index > 0)
              Divider(height: 1, color: onSurface.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _MethodText(method: ep.method),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ep.endpoint,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: fraction.clamp(0.0, 1.0),
                            minHeight: 2,
                            backgroundColor: onSurface.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              avgColor.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'min ${RaccoonFormatHelpers.formatDuration(ep.minDuration)}'
                          '  ·  '
                          'max ${RaccoonFormatHelpers.formatDuration(ep.maxDuration)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        RaccoonFormatHelpers.formatDuration(ep.avgDuration),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: avgColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ep.count}×',
                        style: TextStyle(
                          fontSize: 11,
                          color: onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Slow / Failed ─────────────────────────────────────────────────────────

  Widget _buildSlowList(
    BuildContext context,
    List<RaccoonHttpCall> calls,
    int maxDuration,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: calls.mapIndexed((index, call) {
        final durationColor = _durationColor(call.duration);
        final fraction = call.duration / maxDuration;

        return Column(
          children: [
            if (index > 0)
              Divider(height: 1, color: onSurface.withOpacity(0.08)),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RaccoonDetailView(call: call),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _MethodText(method: call.method),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.endpoint,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: fraction.clamp(0.0, 1.0),
                              minHeight: 2,
                              backgroundColor: onSurface.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                durationColor.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          RaccoonFormatHelpers.formatDuration(call.duration),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: durationColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusText(call),
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFailedList(BuildContext context, List<RaccoonHttpCall> calls) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: calls.mapIndexed((index, call) {
        final statusCode = call.response?.status;
        final isNetworkError = call.error != null && statusCode == null;
        final statusColor =
            (isNetworkError || (statusCode != null && statusCode >= 500))
                ? Colors.red
                : Colors.orange;

        return Column(
          children: [
            if (index > 0)
              Divider(height: 1, color: onSurface.withOpacity(0.08)),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RaccoonDetailView(call: call),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _MethodText(method: call.method),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.endpoint,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isNetworkError) ...[
                            const SizedBox(height: 2),
                            Text(
                              call.error?.error?.toString() ?? 'Network error',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isNetworkError ? 'ERR' : statusCode.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        if (call.duration > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            RaccoonFormatHelpers.formatDuration(call.duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Shared builders ───────────────────────────────────────────────────────

  Widget _buildSection(
    BuildContext context,
    String title,
    Widget content, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _emptyLabel(BuildContext context, String message) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
      ),
    );
  }

  Widget _buildDistribution(
    BuildContext context,
    Map<String, int> distribution,
    int total,
    Color Function(String) colorFor, {
    required double labelWidth,
  }) {
    if (distribution.isEmpty) return _emptyLabel(context, 'No data');

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: distribution.entries.map((entry) {
        final color = colorFor(entry.key);
        final fraction = entry.value / total;
        final pct = (fraction * 100).toStringAsFixed(0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    backgroundColor: onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(
                  '$pct% · ${entry.value}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _statusText(RaccoonHttpCall call) {
    final status = call.response?.status;
    if (status == null) return '—';
    return status.toString();
  }

  Color _durationColor(int ms) {
    if (ms < 500) return Colors.green;
    if (ms < 1000) return Colors.orange;
    if (ms < 3000) return Colors.deepOrange;
    return Colors.red;
  }

  Color _statusCodeColor(String statusCode) {
    final code = int.tryParse(statusCode) ?? 0;
    if (code >= 200 && code < 300) return Colors.green;
    if (code >= 300 && code < 400) return Colors.blue;
    if (code >= 400 && code < 500) return Colors.orange;
    if (code >= 500) return Colors.red;
    return Colors.grey;
  }

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ── Stats calculation ─────────────────────────────────────────────────────

  _Stats _calculateStats(List<RaccoonHttpCall> calls) {
    final totalCalls = calls.length;
    var successCount = 0;
    var errorCount = 0;
    var totalDuration = 0;
    var totalBytesSent = 0;
    var totalBytesReceived = 0;
    final statusCodeDistribution = <String, int>{};
    final methodDistribution = <String, int>{};
    final completedCalls = <RaccoonHttpCall>[];

    for (final call in calls) {
      final statusCode = call.response?.status;
      if (statusCode != null) {
        final status = statusCode.toString();
        statusCodeDistribution[status] =
            (statusCodeDistribution[status] ?? 0) + 1;

        if (statusCode >= 200 && statusCode < 300) {
          successCount++;
        } else if (statusCode >= 400) {
          errorCount++;
        }

        completedCalls.add(call);
      }

      if (call.error != null) errorCount++;

      methodDistribution[call.method] =
          (methodDistribution[call.method] ?? 0) + 1;

      totalDuration += call.duration;
      totalBytesSent += call.request?.size ?? 0;
      totalBytesReceived += call.response?.size ?? 0;
    }

    final slowCalls = completedCalls
        .where((c) => c.duration > 500)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));

    final failedCalls = calls
        .where(
          (c) =>
              c.error != null ||
              (c.response?.status != null && c.response!.status! >= 400),
        )
        .toList()
      ..sort((a, b) => b.createdTime.compareTo(a.createdTime));

    return _Stats(
      totalCalls: totalCalls,
      successCount: successCount,
      errorCount: errorCount,
      avgResponseTime: totalCalls > 0 ? totalDuration / totalCalls : 0,
      statusCodeDistribution: statusCodeDistribution,
      methodDistribution: methodDistribution,
      slowCalls: slowCalls,
      failedCalls: failedCalls,
      maxDuration:
          slowCalls.isEmpty ? 1 : slowCalls.first.duration.clamp(1, 999999),
      slowCount: completedCalls.where((c) => c.duration > 500).length,
      endpointStats: _buildEndpointStats(completedCalls),
      timelineBuckets: _buildTimelineBuckets(calls),
      totalBytesSent: totalBytesSent,
      totalBytesReceived: totalBytesReceived,
    );
  }

  List<_EndpointStat> _buildEndpointStats(List<RaccoonHttpCall> completedCalls) {
    final durationMap = <String, List<int>>{};
    final methodMap = <String, String>{};
    final endpointMap = <String, String>{};

    for (final call in completedCalls) {
      final key = '${call.method} ${call.endpoint}';
      methodMap[key] = call.method;
      endpointMap[key] = call.endpoint;
      (durationMap[key] ??= []).add(call.duration);
    }

    return durationMap.entries.map((entry) {
      final durations = entry.value;
      final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
      final minD = durations.reduce(min);
      final maxD = durations.reduce(max);
      return _EndpointStat(
        method: methodMap[entry.key]!,
        endpoint: endpointMap[entry.key]!,
        count: durations.length,
        avgDuration: avg,
        minDuration: minD,
        maxDuration: maxD,
      );
    }).toList()
      ..sort((a, b) => b.avgDuration.compareTo(a.avgDuration));
  }

  List<_TimelineBucket> _buildTimelineBuckets(List<RaccoonHttpCall> calls) {
    if (calls.isEmpty) return [];

    final sorted = List<RaccoonHttpCall>.from(calls)
      ..sort((a, b) => a.createdTime.compareTo(b.createdTime));

    final start = sorted.first.createdTime;
    final end = sorted.last.createdTime;
    final spanMs = end.difference(start).inMilliseconds;

    // Aim for ~20 buckets, minimum 1 second each
    final bucketMs = spanMs <= 0 ? 1000 : max(1000, spanMs ~/ 20);

    final bucketMap = <int, _TimelineBucket>{};

    for (final call in sorted) {
      final offsetMs = call.createdTime.difference(start).inMilliseconds;
      final bucketIndex = offsetMs ~/ bucketMs;
      final bucketTime = start.add(Duration(milliseconds: bucketIndex * bucketMs));
      final isError = call.error != null ||
          (call.response?.status != null && call.response!.status! >= 400);

      final existing = bucketMap[bucketIndex];
      bucketMap[bucketIndex] = _TimelineBucket(
        time: bucketTime,
        count: (existing?.count ?? 0) + 1,
        errorCount: (existing?.errorCount ?? 0) + (isError ? 1 : 0),
      );
    }

    return bucketMap.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _Stats {
  final int totalCalls;
  final int successCount;
  final int errorCount;
  final double avgResponseTime;
  final Map<String, int> statusCodeDistribution;
  final Map<String, int> methodDistribution;
  final List<RaccoonHttpCall> slowCalls;
  final List<RaccoonHttpCall> failedCalls;
  final int maxDuration;
  final int slowCount;
  final List<_EndpointStat> endpointStats;
  final List<_TimelineBucket> timelineBuckets;
  final int totalBytesSent;
  final int totalBytesReceived;

  _Stats({
    required this.totalCalls,
    required this.successCount,
    required this.errorCount,
    required this.avgResponseTime,
    required this.statusCodeDistribution,
    required this.methodDistribution,
    required this.slowCalls,
    required this.failedCalls,
    required this.maxDuration,
    required this.slowCount,
    required this.endpointStats,
    required this.timelineBuckets,
    required this.totalBytesSent,
    required this.totalBytesReceived,
  });
}

class _EndpointStat {
  final String method;
  final String endpoint;
  final int count;
  final int avgDuration;
  final int minDuration;
  final int maxDuration;

  _EndpointStat({
    required this.method,
    required this.endpoint,
    required this.count,
    required this.avgDuration,
    required this.minDuration,
    required this.maxDuration,
  });
}

class _TimelineBucket {
  final DateTime time;
  final int count;
  final int errorCount;

  _TimelineBucket({
    required this.time,
    required this.count,
    required this.errorCount,
  });
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _MethodText extends StatelessWidget {
  const _MethodText({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: Text(
        method,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _methodColor(method),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'PATCH':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

extension _IterableIndexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
