import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/view/components/raccoon_row_widget.dart';
import 'package:raccoon/view/components/raccoon_summary_header.dart';

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
    var requestHeader = call.request!.headers.entries
        .map((entry) => {entry.key: entry.value})
        .toList();

    var responseHeader = call.response!.headers.entries
        .map((entry) => {entry.key: entry.value})
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Header
          RaccoonSummaryHeader(
            call: call,
            onReplay: onReplay,
            isReplaying: isReplaying,
          ),
          // Rest of the content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                ExpandablePanel(
                  controller: ExpandableController(initialExpanded: true),
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                  ),
                  header: const Text(
                    "General",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  collapsed: const SizedBox.shrink(),
                  expanded: Column(
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
                const SizedBox(height: 8),
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                  ),
                  header: const Text(
                    "Request Headers",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  collapsed: const SizedBox.shrink(),
                  expanded: ListView.separated(
                    primary: false,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: requestHeader.length,
                    itemBuilder: (context, index) {
                      var map = requestHeader[index];
                      return RaccoonRowWidget(
                        title: map.keys.first,
                        body: map.values.first,
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 4);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                  ),
                  header: const Text(
                    "Response Headers",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  collapsed: const SizedBox.shrink(),
                  expanded: ListView.separated(
                    primary: false,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: responseHeader.length,
                    itemBuilder: (context, index) {
                      var map = responseHeader[index];
                      return RaccoonRowWidget(
                        title: map.keys.first,
                        body: map.values.first,
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 4);
                    },
                  ),
                ),
                if (_shouldShowRequestBody()) ...[
                  const SizedBox(height: 8),
                  ExpandablePanel(
                    theme: const ExpandableThemeData(
                      headerAlignment: ExpandablePanelHeaderAlignment.center,
                    ),
                    header: const Text(
                      "Request Body",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    collapsed: const SizedBox.shrink(),
                    expanded: SelectableText(_formatRequestBody()),
                  ),
                ],
                if ((call.request?.formDataFields ?? []).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpandablePanel(
                    theme: const ExpandableThemeData(
                      headerAlignment: ExpandablePanelHeaderAlignment.center,
                    ),
                    header: const Text(
                      "Form Data Field",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    collapsed: const SizedBox.shrink(),
                    expanded: ListView.separated(
                      primary: false,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: call.request!.formDataFields!.length,
                      itemBuilder: (context, index) {
                        var map = call.request!.formDataFields![index];
                        return RaccoonRowWidget(
                          title: map.name,
                          body: map.value,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 4);
                      },
                    ),
                  ),
                ],
                if ((call.request?.formDataFiles ?? []).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpandablePanel(
                    theme: const ExpandableThemeData(
                      headerAlignment: ExpandablePanelHeaderAlignment.center,
                    ),
                    header: const Text(
                      "Form Data Files",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    collapsed: const SizedBox.shrink(),
                    expanded: ListView.separated(
                      primary: false,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: call.request!.formDataFiles!.length,
                      itemBuilder: (context, index) {
                        var map = call.request!.formDataFiles![index];
                        return RaccoonRowWidget(
                          title: map.fileName ?? "",
                          body: map.contentType,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 4);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
