import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/utils/raccoon_format_helpers.dart';
import 'package:raccoon/utils/raccoon_formatter.dart';

class RaccoonResponseWidget extends StatefulWidget {
  const RaccoonResponseWidget({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  State<RaccoonResponseWidget> createState() => _RaccoonResponseWidgetState();
}

class _RaccoonResponseWidgetState extends State<RaccoonResponseWidget> {
  bool _showFormatted = true;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        _totalMatches = 0;
        _currentMatchIndex = 0;
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentMatchIndex = 0;
      // Count matches would happen in the formatter
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.call.response?.body == null) {
      return const Center(
        child: Text("There is no response"),
      );
    }

    final body = widget.call.response!.body;
    final headers = widget.call.response!.headers;
    final contentType = RaccoonFormatter.detectContentType(headers, body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              if (contentType == 'json' || contentType == 'xml') ...[
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label:
                            Text('Formatted', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.code, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Raw', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.text_fields, size: 16),
                      ),
                    ],
                    selected: {_showFormatted},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showFormatted = newSelection.first;
                      });
                    },
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: body.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Response copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                tooltip: 'Copy response',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildContent(contentType, body),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(String contentType, dynamic body) {
    try {
      if (contentType == 'json') {
        return _buildJsonContent(body);
      } else if (contentType == 'xml' || contentType == 'html') {
        return _buildXmlContent(body);
      } else if (contentType == 'image') {
        return _buildImageContent(body);
      } else {
        return _buildTextContent(body);
      }
    } catch (e) {
      return SelectableText(
        body.toString(),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }
  }

  Widget _buildJsonContent(dynamic body) {
    if (_showFormatted) {
      final formatted = RaccoonFormatter.formatJson(body);
      return RaccoonFormatter.buildJsonWidget(formatted);
    } else {
      final raw = body.toString();
      return SelectableText(
        raw,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }
  }

  Widget _buildXmlContent(dynamic body) {
    final bodyStr = body.toString();
    if (_showFormatted) {
      final formatted = RaccoonFormatter.formatXml(bodyStr);
      return RaccoonFormatter.buildXmlWidget(formatted);
    } else {
      return SelectableText(
        bodyStr,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }
  }

  Widget _buildImageContent(dynamic body) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Image preview not yet supported',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Check the Headers tab for image metadata',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(dynamic body) {
    final text = body.toString();
    return SelectableText(
      text,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
    );
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'json':
        return Colors.blue;
      case 'xml':
      case 'html':
        return Colors.orange;
      case 'image':
        return Colors.purple;
      case 'text':
      default:
        return Colors.grey;
    }
  }
}
