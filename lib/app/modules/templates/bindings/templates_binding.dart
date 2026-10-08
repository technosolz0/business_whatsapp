import 'package:get/get.dart';
import '../controllers/create_template_controller.dart';
import '../controllers/templates_controller.dart';

class TemplatesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TemplatesController>(TemplatesController());
    if (!Get.isRegistered<CreateTemplateController>()) {
      Get.put<CreateTemplateController>(CreateTemplateController(),
          permanent: true);
    }
  }
}
