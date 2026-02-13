import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import '../../../../Utilities/responsive.dart';
import '../../controllers/create_broadcast_controller.dart';
import '../../widgets/template_card_widget.dart';
import '../../widgets/attachments_card_widget.dart';
import '../../widgets/broadcast_preview_widget.dart';

class Step2Content extends StatelessWidget {
  final CreateBroadcastController controller;

  const Step2Content({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => Column(
        children: [
          Responsive(
            mobile: Column(
              children: [
                TemplateCardWidget(),
                SizedBox(height: 32),
                if (controller.attachmentType.isNotEmpty)
                  AttachmentsCardWidget(controller: controller),
                SizedBox(height: 32),
                BroadcastPreviewWidget(),
              ],
            ),
            tablet: Column(
              children: [
                TemplateCardWidget(),
                SizedBox(height: 32),
                if (controller.attachmentType.isNotEmpty)
                  AttachmentsCardWidget(controller: controller),

                SizedBox(height: 32),
                BroadcastPreviewWidget(),
              ],
            ),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Template & Attachments (2/3 width)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TemplateCardWidget(),
                      SizedBox(height: 32),
                      if (controller.attachmentType.isNotEmpty)
                        AttachmentsCardWidget(controller: controller),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right side - Preview (1/3 width)
                const Expanded(flex: 1, child: BroadcastPreviewWidget()),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: controller.previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: controller.nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next Step',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
