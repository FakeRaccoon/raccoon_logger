import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/raccoon_theme.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';
import 'package:raccoon/view/components/raccoon_error_widget.dart';
import 'package:raccoon/view/components/raccoon_headers_widget.dart';
import 'package:raccoon/view/components/raccoon_response_widget.dart';

/// Detail screen for a single call: Headers, Response and Error tabs, with
/// copy-cURL and request-replay actions.
class RaccoonDetailView extends StatefulWidget {
  const RaccoonDetailView({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  State<RaccoonDetailView> createState() => _RaccoonDetailViewState();
}

class _RaccoonDetailViewState extends State<RaccoonDetailView> {
  bool _isReplaying = false;

  Future<void> _handleReplay() async {
    final service = RaccoonService();

    if (service.dioInstance == null) {
      if (!mounted) return;
      showRaccoonSnackBar(
        context,
        'Replay not available. Configure Dio instance using '
        'Raccoon().setDioInstance(dio)',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isReplaying = true;
    });

    try {
      final response = await service.replayRequest(widget.call);

      if (!mounted) return;

      setState(() {
        _isReplaying = false;
      });

      _showReplayResult(response, null);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isReplaying = false;
      });

      if (e is DioException) {
        _showReplayResult(e.response, e);
      } else {
        showRaccoonSnackBar(
          context,
          'Replay failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showReplayResult(Response? response, DioException? error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              error != null ? Icons.error : Icons.check_circle,
              color: RaccoonFormatHelpers.tone(
                error != null ? Colors.red : Colors.green,
                Theme.of(context).brightness,
              ),
            ),
            const SizedBox(width: 8),
            Text(error != null ? 'Replay Failed' : 'Replay Successful'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (response != null) ...[
                _buildResultRow(
                  'Status',
                  response.statusCode?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _buildResultRow(
                  'Status Message',
                  response.statusMessage ?? 'N/A',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Response Body:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    response.data?.toString() ?? 'Empty',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ] else if (error != null) ...[
                Text('Error: ${error.message}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (response != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: response.data?.toString() ?? ''),
                );
                showRaccoonSnackBar(context, 'Response copied to clipboard');
              },
              child: const Text('Copy Response'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RaccoonThemeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    // Colour the tabs against the app bar they sit in, rather than leaving it to
    // the host app's theme. A Material 2 host defaults TabBar labels to
    // `primaryTextTheme` — the colour meant for text ON `primaryColor` — so an
    // app with a dark primary and a white app bar (a common pairing) renders
    // these labels white on white, leaving a bar with nothing but its indicator.
    final theme = Theme.of(context);
    final onAppBar =
        theme.appBarTheme.foregroundColor ??
        theme.appBarTheme.titleTextStyle?.color ??
        theme.colorScheme.onSurface;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("HTTP Call Detail"),
          bottom: TabBar(
            dividerHeight: 0,
            labelColor: onAppBar,
            unselectedLabelColor: onAppBar.withValues(alpha: 0.6),
            indicatorColor: onAppBar,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Headers"),
              Tab(text: "Response"),
              Tab(text: "Error"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Clipboard.setData(
            ClipboardData(text: widget.call.request?.curl ?? ''),
          ),
          child: const Icon(Icons.copy),
        ),
        body: TabBarView(
          children: [
            RaccoonHeadersWidget(
              call: widget.call,
              onReplay: RaccoonService().dioInstance != null
                  ? _handleReplay
                  : null,
              isReplaying: _isReplaying,
            ),
            RaccoonResponseWidget(call: widget.call),
            RaccoonErrorWidget(call: widget.call),
          ],
        ),
      ),
    );
  }
}
