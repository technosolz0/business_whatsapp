import 'package:get/get.dart';

import '../controllers/admins_controller.dart';

class AdminsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminsController>(
      () => AdminsController(),
    );
  }
}
