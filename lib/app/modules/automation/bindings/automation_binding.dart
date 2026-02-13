import 'package:get/get.dart';
import '../controllers/automation_controller.dart';

class AutomationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AutomationController>(() => AutomationController());
  }
}
