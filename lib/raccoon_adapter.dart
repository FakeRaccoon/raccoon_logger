import 'package:get/get.dart';
import 'package:raccoon/raccoon_service.dart';

mixin RaccoonAdapter {
  RaccoonService get service => Get.find<RaccoonService>();
}
