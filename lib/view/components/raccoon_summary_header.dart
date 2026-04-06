import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';

class RaccoonSummaryHeader extends StatelessWidget {
  const RaccoonSummaryHeader({
    super.key,
    required this.call,
    this.onReplay,
    this.isReplaying = false,
  });

  final RaccoonHttpCall call;
  final VoidCallback? onReplay;
  final bool isReplaying;

  @override
  Widget build(BuildContext context) {
    final statusCode = call.response?.status ?? -1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status and Method
          Text(
            '${statusCode == -1 ? 'ERROR' : statusCode} • ${call.method}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(statusCode),
            ),
          ),
          const SizedBox(width: 12),
          // Endpoint
          Expanded(
            child: Text(
              call.endpoint,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Quick Actions
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy URL
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: call.uri));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('URL copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Copy URL',
          visualDensity: VisualDensity.compact,
        ),
        // Replay (if available)
        if (onReplay != null)
          IconButton(
            onPressed: isReplaying ? null : onReplay,
            icon: isReplaying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.replay, size: 20),
            tooltip: 'Replay Request',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null || statusCode == -1) return Colors.red;
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.blue;
    if (statusCode >= 400 && statusCode < 500) return Colors.orange;
    if (statusCode >= 500) return Colors.red;
    return Colors.grey;
  }
}
