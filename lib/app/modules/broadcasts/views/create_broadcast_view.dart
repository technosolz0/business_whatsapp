import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../routes/app_pages.dart';
import '../controllers/create_broadcast_controller.dart';
import '../widgets/broadcast_step_indicator.dart';
import 'widgets/step1_content.dart';
import 'widgets/step2_content.dart';
import 'widgets/step3_content.dart';

class CreateBroadcastView extends GetView<CreateBroadcastController> {
  const CreateBroadcastView({super.key});

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Audience';
      case 1:
        return 'Content';
      case 2:
        return 'Schedule & Send';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute.split('?').first;

    // Set the current step based on the route or preview mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isPreview) {
        controller.currentStep.value = 2;
        return;
      }

      int targetStep = 0;
      switch (currentRoute) {
        case Routes.BROADCAST_AUDIENCE:
          targetStep = 0;
          break;
        case Routes.BROADCAST_CONTENT:
          targetStep = 1;
          break;
        case Routes.BROADCAST_SCHEDULE:
          targetStep = 2;
          break;
        default:
          targetStep = 0;
      }

      if (controller.currentStep.value != targetStep) {
        controller.currentStep.value = targetStep;
      }
    });

    return StandardPageLayout(
      title: 'Create Broadcast',
      subtitle: 'Design and schedule your broadcast message.',
      showBackButton: true,
      onBack: () => Get.offAllNamed(Routes.BROADCASTS),
      isContentScrollable: true,
      headerActions: [
        Obx(() {
          final completedAt = controller.completedAt.value;
          if (controller.isPreview && completedAt != null) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              DateFormat('MMMM d, yyyy h:mm a').format(completedAt),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            );
          }
          return const SizedBox();
        }),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator
          Obx(
            () => BroadcastStepIndicator(
              currentStep: controller.currentStep.value,
              getStepTitle: _getStepTitle,
            ),
          ),
          const SizedBox(height: 32),

          // Content based on current step
          Obx(() {
            switch (controller.currentStep.value) {
              case 0:
                return Step1Content(controller: controller);
              case 1:
                return Step2Content(controller: controller);
              case 2:
                return Step3Content(controller: controller);
              default:
                return const SizedBox();
            }
          }),
        ],
      ),
    );
  }
}
