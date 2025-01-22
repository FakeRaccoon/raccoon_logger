import 'package:get/get.dart';
import 'package:raccoon/model/raccoon_http_call.dart';

import 'raccoon_service.dart';

class Raccoon {
  late final RaccoonService _service;

  Raccoon() {
    _service = Get.put(RaccoonService());
  }

  RxList<RaccoonHttpCall> get calls => _service.calls;

  void showInspector() => _service.navigateToCallListScreen();

  RxBool get isInspectorOpened => _service.isInspectorOpened;
}
