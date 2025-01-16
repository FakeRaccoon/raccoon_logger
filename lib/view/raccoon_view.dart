import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:raccoon/raccoon.dart';
import 'package:raccoon/raccoon_service.dart';
import 'package:raccoon/view/raccoon_detail_view.dart';

class RaccoonView extends StatelessWidget {
  const RaccoonView({super.key, required this.service});

  final RaccoonService service;

  @override
  Widget build(BuildContext context) {
    final raccoon = Raccoon();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raccoon View'),
      ),
      body: Obx(
        () {
          final calls = raccoon.calls.reversed.toList();
          return ListView.separated(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              return ListTile(
                title: Text(
                  "${call.method} ${call.endpoint}",
                  style: TextStyle(
                    color: call.error != null ? Colors.red : null,
                  ),
                ),
                isThreeLine: true,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(call.server),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${call.createdTime}"),
                        Text("${call.duration} ms"),
                      ],
                    ),
                  ],
                ),
                trailing: call.response?.status == null
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : Text(
                        "${call.response?.status}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: call.error != null ? Colors.red : Colors.green,
                        ),
                      ),
                onTap: () => Get.to(
                  () => RaccoonDetailView(call: call),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider();
            },
          );
        },
      ),
    );
  }
}
