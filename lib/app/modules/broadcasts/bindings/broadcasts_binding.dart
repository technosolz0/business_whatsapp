import 'package:get/get.dart';
import '../controllers/broadcasts_controller.dart';
import '../controllers/create_broadcast_controller.dart';

class BroadcastsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BroadcastsController>(
      () => BroadcastsController(),
    );
    Get.lazyPut<CreateBroadcastController>(
      () => CreateBroadcastController(),
    );
  }
}
