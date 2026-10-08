import 'package:get/get.dart';
import '../controllers/create_template_controller.dart';

class CreateTemplateBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CreateTemplateController>()) {
      Get.put<CreateTemplateController>(CreateTemplateController(),
          permanent: true);
    }
  }
}
