import 'package:get/get.dart';

import '../controllers/templates_controller.dart';
import '../controllers/create_template_controller.dart';

class TemplatesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TemplatesController>(TemplatesController());
    Get.lazyPut<CreateTemplateController>(() => CreateTemplateController());
  }
}
