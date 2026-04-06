import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/view/components/raccoon_error_widget.dart';
import 'package:raccoon/view/components/raccoon_headers_widget.dart';
import 'package:raccoon/view/components/raccoon_response_widget.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Replay not available. Configure Dio instance using Raccoon().setDioInstance(dio)',
          ),
          duration: Duration(seconds: 3),
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Replay failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
              color: error != null ? Colors.red : Colors.green,
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
                    color: Colors.grey[200],
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Response copied to clipboard')),
                );
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("HTTP Call Detail"),
          bottom: const TabBar(
            dividerHeight: 0,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Headers"),
              Tab(text: "Response"),
              Tab(text: "Error"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: widget.call.request!.curl)),
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
