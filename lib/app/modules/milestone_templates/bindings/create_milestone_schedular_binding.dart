import 'package:get/get.dart';
import '../controllers/create_milestone_schedular_controller.dart';
import '../controllers/milestone_schedulars_controller.dart';

class CreateMilestoneSchedularBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MilestoneSchedularsController>(
      () => MilestoneSchedularsController(),
    );
    Get.lazyPut<CreateMilestoneSchedularController>(
      () => CreateMilestoneSchedularController(),
    );
  }
}
