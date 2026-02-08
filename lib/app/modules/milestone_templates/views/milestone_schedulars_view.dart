import 'package:business_whatsapp/app/common%20widgets/custom_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
import 'package:business_whatsapp/app/common%20widgets/custom_dropdown.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/common%20widgets/standard_page_layout.dart';
import '../../../Utilities/subscription_guard.dart';
import '../controllers/milestone_schedulars_controller.dart';
import 'widgets/milestone_schedulars_table.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';

class MilestoneSchedularsView extends GetView<MilestoneSchedularsController> {
  const MilestoneSchedularsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'Milestone Schedulars',
      subtitle: 'Manage your milestone message schedulars',
      headerActions: [
        CustomButton(
          label: 'Create Milestone Schedular',
          onPressed: controller.createSchedular,
          isDisabled: !SubscriptionGuard.canEdit(),
          icon: Icons.add,
          type: ButtonType.primary,
        ),
      ],
      toolbarWidgets: [
        Expanded(flex: 3, child: _buildSearchField()),
        const SizedBox(width: 16),
        _buildStatusFilter(context),
        const SizedBox(width: 12),
        _buildCategoryFilter(context),
      ],
      child: Obx(() {
        if (controller.isLoading.value) {
          return const TableShimmer(rows: 10, columns: 4);
        }

        return MilestoneSchedularsTable(
          schedulars: controller.filteredSchedulars,
          onActionTap: (schedular, action) {
            controller.onSchedularAction(schedular, action);
          },
        );
      }),
    );
  }

  Widget _buildSearchField() {
    return CommonTextfield(
      hintText: 'Search schedulars...',
      prefixIcon: const Icon(Icons.search, size: 20),
      onChanged: controller.setSearchQuery,
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200, minWidth: 120),
      child: Obx(
        () => CustomDropdown<String>(
          value: controller.selectedStatus.value,
          items: ['All', 'active', 'paused']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.capitalizeFirst!,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => controller.setStatusFilter(val ?? 'All'),
          hint: 'Status',
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200, minWidth: 150),
      child: Obx(
        () => CustomDropdown<String>(
          value: controller.selectedCategory.value,
          items: ['All', 'birthday', 'anniversary', 'payment_due', 'custom']
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.replaceAll('_', ' ').capitalizeFirst!,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => controller.setCategoryFilter(val ?? 'All'),
          hint: 'Type',
        ),
      ),
    );
  }
}
