import 'package:get/get.dart';
import '../controllers/charges_controller.dart';

class ChargesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChargesController>(() => ChargesController());
  }
}
