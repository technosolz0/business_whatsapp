import 'package:get/get.dart';

import '../controllers/milestone_schedulars_controller.dart';
import '../controllers/create_milestone_schedular_controller.dart';

class MilestoneSchedularsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MilestoneSchedularsController>(MilestoneSchedularsController());
    Get.lazyPut<CreateMilestoneSchedularController>(
      () => CreateMilestoneSchedularController(),
    );
  }
}
