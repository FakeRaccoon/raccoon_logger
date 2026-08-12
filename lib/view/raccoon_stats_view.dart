import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/raccoon_theme.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';
import 'package:raccoon/utils/raccoon_stats.dart';
import 'package:raccoon/view/raccoon_detail_view.dart';

/// Statistics screen: a headline summary, the status/method mix, the endpoints
/// that cost the most time, and the calls that need attention.
class RaccoonStatsView extends StatelessWidget {
  const RaccoonStatsView({super.key, required this.service});

  /// Fallback for when no Discord threshold is configured.
  static const int defaultSlowThreshold = 500;

  final RaccoonService service;

  @override
  Widget build(BuildContext context) {
    return RaccoonThemeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
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
                    onPressed: () => _showMarkdownExport(context, _stats()),
                  ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          if (service.calls.isEmpty) {
            return Center(child: _muted(context, 'No data available'));
          }

          final stats = _stats();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _Headline(stats: stats),
              const SizedBox(height: 28),
              _section(context, 'Status'),
              _StatusBar(stats: stats),
              const SizedBox(height: 28),
              _section(context, 'Slowest endpoints', trailing: 'by total time'),
              for (final endpoint in stats.endpoints.take(8))
                _EndpointRow(stat: endpoint),
              if (stats.endpoints.isEmpty)
                _muted(context, 'No completed requests'),
              const SizedBox(height: 28),
              _section(
                context,
                'Needs attention',
                trailing: stats.attention.isEmpty
                    ? null
                    : '${stats.attention.length}',
              ),
              for (final entry in stats.attention.take(20))
                _AttentionRow(entry: entry),
              if (stats.attention.isEmpty)
                _muted(context, 'No failed or slow requests'),
              if (stats.attention.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _muted(
                    context,
                    '+ ${stats.attention.length - 20} more in the call list',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Reuses the Discord slow-call threshold so one number defines "slow"
  /// everywhere; falls back to 500 ms when alerts are off.
  RaccoonStats _stats() => RaccoonStats.from(
    service.calls,
    slowThreshold: service.slowCallThreshold > 0
        ? service.slowCallThreshold
        : defaultSlowThreshold,
  );

  static Widget _section(
    BuildContext context,
    String title, {
    String? trailing,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: onSurface.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _muted(BuildContext context, String message) => Text(
    message,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
    ),
  );

  void _showMarkdownExport(BuildContext context, RaccoonStats stats) {
    final md = stats.toMarkdown();
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
                      showRaccoonSnackBar(context, 'Copied to clipboard');
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
}

/// Two lines: what happened, and how long it took.
class _Headline extends StatelessWidget {
  const _Headline({required this.stats});

  final RaccoonStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final failureColor = RaccoonFormatHelpers.tone(
      Colors.red,
      theme.brightness,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: theme.textTheme.titleMedium,
            children: [
              TextSpan(text: '${stats.total} calls'),
              const TextSpan(text: '  ·  '),
              TextSpan(
                text: '${stats.failed} failed',
                style: TextStyle(color: stats.failed > 0 ? failureColor : null),
              ),
              if (stats.failed > 0)
                TextSpan(
                  text: ' (${stats.failureRate.toStringAsFixed(1)}%)',
                  style: TextStyle(color: failureColor, fontSize: 13),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'p50 ${_ms(stats.p50)}  ·  p95 ${_ms(stats.p95)}  ·  '
          'max ${_ms(stats.maxDuration)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '↑ ${RaccoonFormatHelpers.formatBytes(stats.bytesSent)}   '
          '↓ ${RaccoonFormatHelpers.formatBytes(stats.bytesReceived)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

/// One stacked bar for the status mix, with the method counts under it.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.stats});

  final RaccoonStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final entries = stats.statusClasses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final counted = entries.fold(0, (sum, entry) => sum + entry.value);

    if (counted == 0) {
      return RaccoonStatsView._muted(context, 'No completed requests');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              for (final entry in entries)
                Expanded(
                  flex: entry.value,
                  child: Container(
                    height: 6,
                    color: _colorFor(entry.key, theme.brightness),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final entry in entries)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: entry.key,
                      style: TextStyle(
                        color: _colorFor(entry.key, theme.brightness),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' ${entry.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          stats.methods.entries
              .map((entry) => '${entry.key} ${entry.value}')
              .join('  ·  '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  static Color _colorFor(String statusClass, Brightness brightness) {
    final color = switch (statusClass) {
      '2xx' => Colors.green,
      '3xx' => Colors.blue,
      '4xx' => Colors.orange,
      '5xx' => Colors.red,
      _ => Colors.grey,
    };
    return RaccoonFormatHelpers.tone(color, brightness);
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.stat});

  final RaccoonEndpointStat stat;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _MethodText(method: stat.method),
          Expanded(
            child: Text(
              stat.endpoint,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${stat.count}×',
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: Text(
              '${_ms(stat.p95)} p95',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Text(
              _ms(stat.totalDuration),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.entry});

  final RaccoonAttentionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final call = entry.call;
    final status = call.response?.status;
    final failed = entry.reason == RaccoonAttention.failed;
    final color = RaccoonFormatHelpers.statusCodeColor(
      status,
      brightness: theme.brightness,
    );

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RaccoonDetailView(call: call)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                status == null || status == -1 ? 'ERR' : '$status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _MethodText(method: call.method),
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
                  if (failed && call.error != null)
                    Text(
                      call.error!.error.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              failed ? _ms(call.duration) : '${_ms(call.duration)} slow',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: RaccoonFormatHelpers.methodColor(
            method,
            brightness: Theme.of(context).brightness,
          ),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Milliseconds under a second, seconds above — `1.2 s` reads faster than
/// `1204 ms` when scanning a column.
String _ms(int milliseconds) => milliseconds >= 1000
    ? '${(milliseconds / 1000).toStringAsFixed(1)} s'
    : '$milliseconds ms';
