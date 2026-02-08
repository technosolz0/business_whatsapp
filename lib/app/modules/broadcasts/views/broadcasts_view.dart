import 'package:business_whatsapp/app/common%20widgets/custom_button.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../Utilities/responsive.dart';
import '../../../routes/app_pages.dart';
import '../../../Utilities/subscription_guard.dart';
import '../controllers/broadcasts_controller.dart';
import '../widgets/broadcasts_table.dart';
import '../widgets/overview_section.dart';
import 'create_broadcast_view.dart';

class BroadcastsView extends GetView<BroadcastsController> {
  const BroadcastsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute.split('?').first;
    final isCreatingRoute = [
      Routes.CREATE_BROADCAST,
      Routes.CREATE_CAMPAIGN_FROM_DASHBOARD,
      Routes.BROADCAST_AUDIENCE,
      Routes.BROADCAST_CONTENT,
      Routes.BROADCAST_SCHEDULE,
    ].contains(currentRoute);

    if (isCreatingRoute) {
      return const CreateBroadcastView();
    }

    return StandardPageLayout(
      title: 'Broadcasts',
      subtitle: 'Manage and schedule your broadcast campaigns.',
      headerActions: [
        Obx(
          () => CustomButton(
            label: 'Create Broadcast',
            onPressed: controller.createBroadcast,
            isDisabled: !SubscriptionGuard.canEdit(),
            icon: Icons.add,
            type: ButtonType.primary,
          ),
        ),
      ],
      toolbarWidgets: [
        Expanded(flex: 3, child: _buildSearchBar()),
        const SizedBox(width: 12),
        SizedBox(width: 200, child: _buildFilterDropdown()),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: BroadcastsTable(
                    controller: controller,
                    onActionTap: (broadcast, action) async {
                      controller.onBroadcastAction(broadcast, action);
                    },
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.selectedBroadcast.value == null ||
                Responsive.isMobile(context) ||
                Responsive.isTablet(context)) {
              return const SizedBox.shrink();
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: 320,
              margin: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: OverviewSection(
                        broadcast: controller.selectedBroadcast.value!,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return TextField(
      controller: controller.searchController,
      onChanged: controller.updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search by broadcast name...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.gray500 : Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? AppColors.gray500 : Colors.grey[400],
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey[200]!,
            ),
          ),
          child: DropdownButtonFormField<String>(
            menuMaxHeight: 300,
            initialValue: controller.selectedFilter.value,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            dropdownColor: isDark ? AppColors.cardDark : Colors.white,
            hint: Text(
              'Filter by Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.gray400 : Colors.black,
              ),
            ),
            items: [
              const DropdownMenuItem(value: 'All', child: Text("All")),
              const DropdownMenuItem(value: 'Draft', child: Text("Draft")),
              const DropdownMenuItem(value: 'Pending', child: Text("Pending")),
              const DropdownMenuItem(
                value: 'Scheduled',
                child: Text("Scheduled"),
              ),
              const DropdownMenuItem(value: 'Sending', child: Text("Sending")),
              const DropdownMenuItem(value: 'Sent', child: Text("Sent")),
              const DropdownMenuItem(value: 'Failed', child: Text("Failed")),
            ],
            onChanged: (value) {
              if (value != null) controller.updateFilter(value);
            },
          ),
        ),
      ),
    );
  }
}
