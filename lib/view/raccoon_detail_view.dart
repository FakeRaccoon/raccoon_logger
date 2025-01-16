import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/view/components/raccoon_error_widget.dart';
import 'package:raccoon/view/components/raccoon_headers_widget.dart';
import 'package:raccoon/view/components/raccoon_response_widget.dart';

class RaccoonDetailView extends StatelessWidget {
  const RaccoonDetailView({super.key, required this.call});

  final RaccoonHttpCall call;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("HTTP Call Detail"),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: "Headers",
              ),
              Tab(
                text: "Response",
              ),
              Tab(
                text: "Error",
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Clipboard.setData(
            ClipboardData(text: call.request!.curl),
          ),
          child: const Icon(
            Icons.copy,
          ),
        ),
        body: TabBarView(
          children: [
            RaccoonHeadersWidget(call: call),
            RaccoonResponseWidget(call: call),
            RaccoonErrorWidget(call: call),
          ],
        ),
      ),
    );
  }
}
