import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/view/components/raccoon_row_widget.dart';
import 'package:raccoon/view/components/raccoon_summary_header.dart';

/// Headers tab: general info plus expandable request/response header and
/// form-data sections for a single [RaccoonHttpCall].
class RaccoonHeadersWidget extends StatelessWidget {
  const RaccoonHeadersWidget({
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
    final requestHeaders = call.request?.headers ?? const <String, String>{};
    final responseHeaders = call.response?.headers ?? const <String, String>{};
    final formFields = call.request?.formDataFields ?? const [];
    final formFiles = call.request?.formDataFiles ?? const [];

    return SingleChildScrollView(
      child: Column(
        children: [
          RaccoonSummaryHeader(
            call: call,
            onReplay: onReplay,
            isReplaying: isReplaying,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _section(
                  "General",
                  initiallyExpanded: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RaccoonRowWidget(title: "Request URL", body: call.uri),
                      const SizedBox(height: 8),
                      RaccoonRowWidget(
                        title: "Request Method",
                        body: call.method,
                      ),
                      const SizedBox(height: 8),
                      RaccoonRowWidget(
                        title: "Status Code",
                        body: "${call.response?.status}",
                      ),
                    ],
                  ),
                ),
                if (requestHeaders.isNotEmpty)
                  _section(
                    "Request Headers",
                    child: _headerRows(requestHeaders),
                  ),
                if (responseHeaders.isNotEmpty)
                  _section(
                    "Response Headers",
                    child: _headerRows(responseHeaders),
                  ),
                if (_shouldShowRequestBody())
                  _section(
                    "Request Body",
                    child: SelectableText(_formatRequestBody()),
                  ),
                if (formFields.isNotEmpty)
                  _section(
                    "Form Data Field",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final field in formFields)
                          RaccoonRowWidget(
                            title: field.name,
                            body: field.value,
                          ),
                      ],
                    ),
                  ),
                if (formFiles.isNotEmpty)
                  _section(
                    "Form Data Files",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final file in formFiles)
                          RaccoonRowWidget(
                            title: file.fileName ?? "",
                            body: file.contentType,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One collapsible section. [ExpansionTile] manages its own expansion state,
  /// so there is no controller to dispose.
  Widget _section(
    String title, {
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      // ExpansionTile centres its children by default, which parks the content
      // in the middle of a wide window. Take the full width and let the rows
      // align themselves.
      expandedAlignment: Alignment.centerLeft,
      children: [SizedBox(width: double.infinity, child: child)],
    );
  }

  Widget _headerRows(Map<String, String> headers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in headers.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RaccoonRowWidget(title: entry.key, body: entry.value),
          ),
      ],
    );
  }

  /// Check if request body should be displayed
  /// Show body if it's not empty and not "Form Data" placeholder
  bool _shouldShowRequestBody() {
    final body = call.request?.body;
    if (body == null) return false;

    // Don't show if it's empty
    if (body is String && body.isEmpty) return false;

    // Don't show if it's the "Form Data" placeholder (form data is shown separately)
    if (body is String && body == "Form Data") return false;

    return true;
  }

  /// Format request body for display
  String _formatRequestBody() {
    final body = call.request?.body;
    if (body == null) return 'Empty';

    // If it's already a string, return it
    if (body is String) return body;

    // Otherwise convert to string (for Map, List, etc.)
    return body.toString();
  }
}
