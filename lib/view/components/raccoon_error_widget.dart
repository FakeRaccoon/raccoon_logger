import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';

/// Error tab: shows a call's error as selectable text, or a placeholder when
/// there is none.
class RaccoonErrorWidget extends StatelessWidget {
  const RaccoonErrorWidget({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  Widget build(BuildContext context) {
    if (call.error == null) {
      return const Center(child: Text("There is no error"));
    }
    // Scrollable: a DioException with a stack trace is far taller than the tab.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: SelectableText("${call.error?.error}"),
      ),
    );
  }
}
