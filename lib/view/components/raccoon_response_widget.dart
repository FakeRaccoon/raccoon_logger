import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/utils/raccoon_formatter.dart';

class RaccoonResponseWidget extends StatefulWidget {
  const RaccoonResponseWidget({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  State<RaccoonResponseWidget> createState() => _RaccoonResponseWidgetState();
}

class _RaccoonResponseWidgetState extends State<RaccoonResponseWidget> {
  bool _showFormatted = true;

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
              // Content type indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getContentTypeColor(contentType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getContentTypeColor(contentType),
                  ),
                ),
                child: Text(
                  contentType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getContentTypeColor(contentType),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Format toggle (only for JSON/XML)
              if (contentType == 'json' || contentType == 'xml') ...[
                Text(
                  'Format:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Formatted', style: TextStyle(fontSize: 12)),
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
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Content
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
      return SelectableText(
        body.toString(),
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
    return SelectableText(
      body.toString(),
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
