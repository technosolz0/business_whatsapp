import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/app/Utilities/responsive.dart';
import 'package:adminpanel/app/modules/broadcasts/widgets/broadcast_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import '../../controllers/create_broadcast_controller.dart';
import '../../widgets/broadcast_review_card_widget.dart';
import '../../widgets/delivery_time_card_widget.dart';

class Step3Content extends StatelessWidget {
  final CreateBroadcastController controller;

  const Step3Content({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Grid Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = Responsive.isDesktop(context);

            if (isDesktop) {
              // Desktop: 2-column layout (2/3 left, 1/3 right)
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Delivery Time & Review
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        DeliveryTimeCardWidget(controller: controller),
                        const SizedBox(height: 32),
                        BroadcastReviewCardWidget(controller: controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Column: Message Preview
                  const Expanded(flex: 1, child: BroadcastPreviewWidget()),
                ],
              );
            } else {
              // Mobile/Tablet: Stacked layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DeliveryTimeCardWidget(controller: controller),
                  const SizedBox(height: 24),
                  BroadcastReviewCardWidget(controller: controller),
                  const SizedBox(height: 24),
                  const BroadcastPreviewWidget(),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 40),
        // Action Buttons
        Container(
          padding: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          child: Row(
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
                        ? const Color(0xFF242424)
                        : const Color(0xFFD1D5DB),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF242424),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!controller.isPreview)
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSending.value
                        ? null
                        : controller.sendBroadcast,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isSending.value
                          ? Colors.grey
                          : AppColors.primary,
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
                    child: controller.isSending.value
                        ? const CircleShimmer(size: 16)
                        : const Text(
                            'Confirm and Send',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
