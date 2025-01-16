import 'package:flutter/material.dart';
import 'package:raccoon/model/raccoon_http_call.dart';

class RaccoonErrorWidget extends StatelessWidget {
  const RaccoonErrorWidget({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  Widget build(BuildContext context) {
    if (call.error == null) {
      return const Center(
        child: Text("There is no error"),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText("${call.error?.error}"),
    );
  }
}
