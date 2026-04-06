import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          AnimatedBuilder(
            animation: service,
            builder: (context, _) => service.calls.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Export as Markdown',
                    onPressed: () => _showMarkdownExport(
                      context,
                      _calculateStats(service.calls),
                    ),
                  ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final calls = service.calls;

          if (calls.isEmpty) {
            return Center(
              child: Text(
                'No data available',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final divider = Container(
      width: 1,
      height: 36,
      color: onSurface.withValues(alpha: 0.08),
    );

    return Column(
      children: [
        // Row 1: Total · Success · Failed
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Total',
                  stats.totalCalls.toString(),
                ),
              ),
              divider,
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Success',
                  stats.successCount.toString(),
                  valueColor: stats.successCount > 0 ? Colors.green : null,
                ),
              ),
              divider,
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Failed',
                  stats.errorCount.toString(),
                  valueColor: stats.errorCount > 0 ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: onSurface.withValues(alpha: 0.08)),
        // Row 2: Avg · Slow · Transfer
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Avg',
                  RaccoonFormatHelpers.formatDuration(
                    stats.avgResponseTime.round(),
                  ),
                ),
              ),
              divider,
              Expanded(
                child: _buildOverviewItem(
                  context,
                  'Slow >500ms',
                  stats.slowCount.toString(),
                  valueColor: stats.slowCount > 0 ? Colors.orange : null,
                ),
              ),
              divider,
              Expanded(child: _buildTransferItem(context, stats)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransferItem(BuildContext context, _Stats stats) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_upward,
                size: 10,
                color: onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 3),
              Text(
                RaccoonFormatHelpers.formatBytes(stats.totalBytesSent),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_downward,
                size: 10,
                color: onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 3),
              Text(
                RaccoonFormatHelpers.formatBytes(stats.totalBytesReceived),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Transfer',
            style: TextStyle(
              fontSize: 10,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
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
              Divider(height: 1, color: onSurface.withValues(alpha: 0.08)),
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
                        LinearProgressIndicator(
                          value: fraction.clamp(0.0, 1.0),
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            avgColor.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'min ${RaccoonFormatHelpers.formatDuration(ep.minDuration)}'
                          '  ·  '
                          'max ${RaccoonFormatHelpers.formatDuration(ep.maxDuration)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: onSurface.withValues(alpha: 0.4),
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
                          color: onSurface.withValues(alpha: 0.4),
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
              Divider(height: 1, color: onSurface.withValues(alpha: 0.08)),
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
                          LinearProgressIndicator(
                            value: fraction.clamp(0.0, 1.0),
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                            backgroundColor: onSurface.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              durationColor.withValues(alpha: 0.5),
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
                            color: onSurface.withValues(alpha: 0.4),
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
              Divider(height: 1, color: onSurface.withValues(alpha: 0.08)),
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
                                color: Colors.red.withValues(alpha: 0.7),
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
                              color: onSurface.withValues(alpha: 0.4),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 13,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _emptyLabel(BuildContext context, String message) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
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
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(3),
                    backgroundColor: onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 22,
                child: Text(
                  '${entry.value}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Markdown export ───────────────────────────────────────────────────────

  void _showMarkdownExport(BuildContext context, _Stats stats) {
    final md = _generateMarkdown(stats);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'raccoon_stats.md',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: md));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  md,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateMarkdown(_Stats stats) {
    final buf = StringBuffer();
    final now = DateTime.now();
    buf.writeln('# Raccoon Stats Report');
    buf.writeln(
      '_Generated ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}_',
    );
    buf.writeln();

    // Overview
    buf.writeln('## Overview');
    buf.writeln();
    buf.writeln('| Metric | Value |');
    buf.writeln('|--------|-------|');
    buf.writeln('| Total requests | ${stats.totalCalls} |');
    buf.writeln('| Successful (2xx) | ${stats.successCount} |');
    buf.writeln('| Failed | ${stats.errorCount} |');
    buf.writeln('| Slow (>500ms) | ${stats.slowCount} |');
    buf.writeln(
      '| Avg response time | ${RaccoonFormatHelpers.formatDuration(stats.avgResponseTime.round())} |',
    );
    buf.writeln(
      '| Data sent | ${RaccoonFormatHelpers.formatBytes(stats.totalBytesSent)} |',
    );
    buf.writeln(
      '| Data received | ${RaccoonFormatHelpers.formatBytes(stats.totalBytesReceived)} |',
    );
    buf.writeln();

    // Status codes
    buf.writeln('## Status Codes');
    buf.writeln();
    buf.writeln('| Code | Count | % |');
    buf.writeln('|------|-------|---|');
    for (final e in stats.statusCodeDistribution.entries) {
      final pct = (e.value / stats.totalCalls * 100).toStringAsFixed(1);
      buf.writeln('| ${e.key} | ${e.value} | $pct% |');
    }
    buf.writeln();

    // Methods
    buf.writeln('## Methods');
    buf.writeln();
    buf.writeln('| Method | Count | % |');
    buf.writeln('|--------|-------|---|');
    for (final e in stats.methodDistribution.entries) {
      final pct = (e.value / stats.totalCalls * 100).toStringAsFixed(1);
      buf.writeln('| ${e.key} | ${e.value} | $pct% |');
    }
    buf.writeln();

    // Endpoints
    if (stats.endpointStats.isNotEmpty) {
      buf.writeln('## Endpoints');
      buf.writeln();
      buf.writeln('| Method | Endpoint | Count | Avg | Min | Max |');
      buf.writeln('|--------|----------|-------|-----|-----|-----|');
      for (final ep in stats.endpointStats) {
        buf.writeln(
          '| ${ep.method} | ${ep.endpoint} | ${ep.count} '
          '| ${RaccoonFormatHelpers.formatDuration(ep.avgDuration)} '
          '| ${RaccoonFormatHelpers.formatDuration(ep.minDuration)} '
          '| ${RaccoonFormatHelpers.formatDuration(ep.maxDuration)} |',
        );
      }
      buf.writeln();
    }

    // Slow requests
    if (stats.slowCalls.isNotEmpty) {
      buf.writeln('## Slow Requests (>500ms)');
      buf.writeln();
      buf.writeln('| Method | Endpoint | Duration | Status |');
      buf.writeln('|--------|----------|----------|--------|');
      for (final call in stats.slowCalls) {
        buf.writeln(
          '| ${call.method} | ${call.endpoint} '
          '| ${RaccoonFormatHelpers.formatDuration(call.duration)} '
          '| ${_statusText(call)} |',
        );
      }
      buf.writeln();
    }

    // Failed requests
    if (stats.failedCalls.isNotEmpty) {
      buf.writeln('## Failed Requests');
      buf.writeln();
      buf.writeln('| Method | Endpoint | Status | Error |');
      buf.writeln('|--------|----------|--------|-------|');
      for (final call in stats.failedCalls) {
        final error = call.error?.error?.toString() ?? '';
        buf.writeln(
          '| ${call.method} | ${call.endpoint} '
          '| ${_statusText(call)} | $error |',
        );
      }
      buf.writeln();
    }

    return buf.toString();
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

    final slowCalls = completedCalls.where((c) => c.duration > 500).toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));

    final failedCalls =
        calls
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
      maxDuration: slowCalls.isEmpty
          ? 1
          : slowCalls.first.duration.clamp(1, 999999),
      slowCount: completedCalls.where((c) => c.duration > 500).length,
      endpointStats: _buildEndpointStats(completedCalls),
      totalBytesSent: totalBytesSent,
      totalBytesReceived: totalBytesReceived,
    );
  }

  List<_EndpointStat> _buildEndpointStats(
    List<RaccoonHttpCall> completedCalls,
  ) {
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
    }).toList()..sort((a, b) => b.avgDuration.compareTo(a.avgDuration));
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
