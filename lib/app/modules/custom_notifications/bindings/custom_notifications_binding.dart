import 'package:get/get.dart';
import '../controllers/custom_notifications_controller.dart';

class CustomNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomNotificationsController>(
      () => CustomNotificationsController(),
    );
  }
}
