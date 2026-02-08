import 'package:get/get.dart';
import '../controllers/create_template_controller.dart';

class CreateTemplateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateTemplateController>(
      () => CreateTemplateController(),
    );
  }
}
