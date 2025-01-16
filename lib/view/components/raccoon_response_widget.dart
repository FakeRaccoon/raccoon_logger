import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/utils/raccoon_parser.dart';

class RaccoonResponseWidget extends StatelessWidget {
  const RaccoonResponseWidget({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  Widget build(BuildContext context) {
    if (call.response == null) {
      return const Center(
        child: Text("There is no response"),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        RaccoonParser.formatJson(call.response?.body),
      ),
    );
  }
}
