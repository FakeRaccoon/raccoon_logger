import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:raccoon/model/raccoon_http_call.dart';
import 'package:raccoon/model/raccoon_http_error.dart';
import 'package:raccoon/model/raccoon_http_response.dart';
import 'package:raccoon/view/raccoon_view.dart';

class RaccoonService extends GetxService {
  RxList<RaccoonHttpCall> calls = <RaccoonHttpCall>[].obs;

  var isInspectorOpened = false.obs;

  void addCall(RaccoonHttpCall call) => calls.add(call);

  /// Add response to existing alice http call
  FutureOr<void> addResponse(RaccoonHttpResponse res, int requestId) async {
    final index = calls.indexWhere((call) => call.id == requestId);

    if (index != -1) {
      var seed = calls[index];
      int duration = res.time.difference(seed.createdTime).inMilliseconds;
      calls[index] = seed.copyWith(response: res, duration: duration);
      calls.refresh();
    } else {
      log("No call found with id $requestId to update the response.");
    }
  }

  /// Add error to existing alice http call
  FutureOr<void> addError(RaccoonHttpError error, int requestId) async {
    final index = calls.indexWhere((call) => call.id == requestId);

    if (index != -1) {
      var seed = calls[index];
      int duration = DateTime.now().difference(seed.createdTime).inMilliseconds;
      calls[index] = seed.copyWith(error: error, duration: duration);
      calls.refresh();
    } else {
      log("No call found with id $requestId to update the response.");
    }
  }

  Future<void> navigateToCallListScreen() async {
    if (!isInspectorOpened.value) {
      isInspectorOpened.value = true;
      await Get.to(() => RaccoonView(service: this));
      isInspectorOpened.value = false;
    }
  }
}
