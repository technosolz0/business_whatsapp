import 'package:get/get.dart';

import '../controllers/add_admins_controller.dart';

class AddAdminsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddAdminsController>(
      () => AddAdminsController(),
    );
  }
}
