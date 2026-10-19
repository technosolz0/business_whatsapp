import 'package:get/get.dart';
import '../controllers/broadcasts_controller.dart';
import '../controllers/create_broadcast_controller.dart';

class BroadcastsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BroadcastsController>()) {
      Get.lazyPut<BroadcastsController>(
        () => BroadcastsController(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateBroadcastController>()) {
      Get.put<CreateBroadcastController>(
        CreateBroadcastController(),
        permanent: true,
      );
    }
  }
}
