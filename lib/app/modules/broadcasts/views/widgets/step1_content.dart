import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/modules/broadcasts/views/widgets/contact_details_popup.dart';
import 'package:business_whatsapp/app/modules/broadcasts/views/widgets/import_options_dialog.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Utilities/responsive.dart';
import '../../controllers/broadcasts_controller.dart';
import '../../controllers/create_broadcast_controller.dart';
import '../../widgets/audience_card_widget.dart';

class Step1Content extends StatelessWidget {
  final CreateBroadcastController controller;

  const Step1Content({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            // padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Responsive(
                  mobile: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broadcast Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.nameController.value,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'e.g. Q4 Promotion Announcement',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.textSecondaryLight.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.gray100.withValues(alpha: 0.05)
                                  : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purpose / Description (Optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.descriptionController.value,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Enter a short description',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.textSecondaryLight.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.gray100.withValues(alpha: 0.05)
                                  : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  tablet: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcast Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller.nameController.value,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'e.g. Q4 Promotion Announcement',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.textSecondaryLight.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.gray100.withValues(alpha: 0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purpose / Description (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller:
                                  controller.descriptionController.value,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter a short description',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.textSecondaryLight.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.gray100.withValues(alpha: 0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcast Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller.nameController.value,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'e.g. Q4 Promotion Announcement',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.textSecondaryLight.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.gray100.withValues(alpha: 0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purpose / Description (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller:
                                  controller.descriptionController.value,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter a short description',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.textSecondaryLight.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.gray100.withValues(alpha: 0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Who are you sending this to?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                Responsive(
                  mobile: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(
                        () => AudienceCardWidget(
                          title: 'All Contacts',
                          value: 'all',
                          icon: Icons.groups,
                          isSelected:
                              controller.selectedAudience.value == 'all',
                          onTap: () => controller.selectAudience('all'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => AudienceCardWidget(
                          title: 'Import Numbers',
                          value: 'import',
                          icon: Icons.upload_file,
                          isSelected:
                              controller.selectedAudience.value == 'import',
                          onTap: () {
                            Get.dialog(
                              ImportOptionsDialog(controller: controller),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => AudienceCardWidget(
                          title: 'Custom Segment',
                          value: 'custom',
                          icon: Icons.segment,
                          isSelected:
                              controller.selectedAudience.value == 'custom',
                          onTap: () => controller.selectAudience('custom'),
                        ),
                      ),
                    ],
                  ),
                  tablet: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => AudienceCardWidget(
                            title: 'All Contacts',
                            value: 'all',
                            icon: Icons.groups,
                            isSelected:
                                controller.selectedAudience.value == 'all',
                            onTap: () => controller.selectAudience('all'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(
                          () => AudienceCardWidget(
                            title: 'Import Numbers',
                            value: 'import',
                            icon: Icons.upload_file,
                            isSelected:
                                controller.selectedAudience.value == 'import',
                            onTap: () {
                              Get.dialog(
                                ImportOptionsDialog(controller: controller),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(
                          () => AudienceCardWidget(
                            title: 'Custom Segment',
                            value: 'custom',
                            icon: Icons.segment,
                            isSelected:
                                controller.selectedAudience.value == 'custom',
                            onTap: () => controller.selectAudience('custom'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  desktop: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => AudienceCardWidget(
                            title: 'All Contacts',
                            value: 'all',
                            icon: Icons.groups,
                            isSelected:
                                controller.selectedAudience.value == 'all',
                            onTap: () => controller.selectAudience('all'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(
                          () => AudienceCardWidget(
                            title: 'Import Numbers',
                            value: 'import',
                            icon: Icons.upload_file,
                            isSelected:
                                controller.selectedAudience.value == 'import',
                            onTap: () {
                              Get.dialog(
                                ImportOptionsDialog(controller: controller),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(
                          () => AudienceCardWidget(
                            title: 'Custom Segment',
                            value: 'custom',
                            icon: Icons.segment,
                            isSelected:
                                controller.selectedAudience.value == 'custom',
                            // onTap: () => controller.selectAudience('custom'),
                            onTap: () {
                              controller.selectAudience('custom');
                              print('custom segment selected&&&&&&&&');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Estimated Recipients Info Box - Mobile Responsive
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.gray100.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You are sending this broadcast to all subscribed contacts.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estimated Recipients',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () {
                                        Get.dialog(
                                          ContactDetailsPopup(
                                            controller: controller,
                                          ),
                                          barrierDismissible: false,
                                        );
                                      },
                                    );
                                  },
                                  child: Obx(
                                    () => MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Text(
                                        controller.finalRecipientCount.value
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'You are sending this broadcast to all subscribed contacts.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Estimated Recipients',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () {
                                        Get.dialog(
                                          ContactDetailsPopup(
                                            controller: controller,
                                          ),
                                          barrierDismissible: false,
                                        );
                                      },
                                    );
                                  },
                                  child: Obx(
                                    () => MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Text(
                                        controller.finalRecipientCount.value
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),
                // Action Buttons - Mobile Responsive
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: controller.saveAsDraft,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Draft',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: controller.nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => Get.find<BroadcastsController>()
                                .closeCreateForm(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () => Get.find<BroadcastsController>()
                                .closeCreateForm(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: controller.saveAsDraft,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save as Draft',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save & Continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
