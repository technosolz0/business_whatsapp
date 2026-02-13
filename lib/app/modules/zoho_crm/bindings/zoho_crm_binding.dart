import 'package:get/get.dart';
import '../controllers/zoho_crm_controller.dart';

class ZohoCrmBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ZohoCrmController>(() => ZohoCrmController());
  }
}
