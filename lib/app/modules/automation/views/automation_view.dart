import '../../../../main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../common widgets/custom_button.dart';
import '../../../controllers/navigation_controller.dart';
import '../controllers/automation_controller.dart';
import '../widgets/automation_table.dart';
import '../../../routes/app_pages.dart';

class AutomationView extends GetView<AutomationController> {
  const AutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StandardPageLayout(
      title: 'Automation',
      subtitle: 'Manage and create your WhatsApp automation flows.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuotaCard(isDark),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSearchBar(isDark)),
              const SizedBox(width: 12),
              Obx(() {
                final isQuotaExceeded =
                    controller.total.value >= automationQuota.value;

                return CustomButton(
                  label: 'Create Flow',
                  onPressed: () {
                    if (isQuotaExceeded) {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Limit Reached'),
                          content: const Text(
                            'Contact administrator to increase limit.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      controller.resetFlow(clearSearch: false);
                      if (Get.isRegistered<NavigationController>()) {
                        final nav = Get.find<NavigationController>();
                        nav.currentRoute.value = Routes.CREATE_AUTOMATION;
                        nav.selectedIndex.value = 12;
                        nav.routeTrigger.value++;
                      }
                    }
                  },
                  icon: Icons.add,
                  type: isQuotaExceeded
                      ? ButtonType.secondary
                      : ButtonType.primary,
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: AutomationTable(controller: controller)),
        ],
      ),
    );
  }

  Widget _buildQuotaCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Quota',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Obx(
                    () => Text(
                      automationQuota.value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Flows',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: controller.searchController,
      maxLength: 50,
      onChanged: controller.updateSearchQuery,
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Search by flow name...',
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
          borderSide: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
      ),
    );
  }
}
