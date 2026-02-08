import 'package:get/get.dart';

import '../controllers/add_roles_controller.dart';

class AddRolesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddRolesController>(
      () => AddRolesController(),
    );
  }
}
