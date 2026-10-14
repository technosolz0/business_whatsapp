import 'package:get/get.dart';
import '../controllers/automation_controller.dart';

class AutomationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AutomationController>()) {
      Get.put<AutomationController>(
        AutomationController(),
        permanent: true,
      );
    }
  }
}
