import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../main.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../common widgets/custom_button.dart';
import '../../../routes/app_pages.dart';
import '../controllers/automation_controller.dart';
import '../widgets/automation_table.dart';

class AutomationView extends GetView<AutomationController> {
  const AutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StandardPageLayout(
      title: 'WhatsApp Automation',
      subtitle:
          'Create keyword triggers, decision trees, interactive menus, and auto-replies.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Quota & Stats Header
          _buildStatsRow(isDark),
          const SizedBox(height: 20),

          // 2. Search Bar & Create Button
          Row(
            children: [
              Expanded(child: _buildSearchBar(isDark)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh list',
                onPressed: () => controller.loadAutomationsFromFirebase(),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final isQuotaExceeded =
                    controller.total.value >= automationQuota.value;

                return CustomButton(
                  label: 'Create Flow',
                  icon: Icons.add,
                  type: isQuotaExceeded
                      ? ButtonType.secondary
                      : ButtonType.primary,
                  onPressed: () {
                    if (isQuotaExceeded) {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Quota Limit Reached'),
                          content: const Text(
                            'You have reached your maximum allowed automation flows. Please contact support to increase your quota.',
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
                      Get.toNamed(Routes.CREATE_AUTOMATION);
                    }
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Automation Table
          Expanded(child: AutomationTable(controller: controller)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _buildStatCard(
              title: 'Active Flows',
              value: controller.automations
                  .where((a) => a.isActive.value)
                  .length
                  .toString(),
              subtitle: 'Currently responding to users',
              icon: Icons.bolt,
              color: Colors.green,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => _buildStatCard(
              title: 'Total Flows',
              value: controller.total.value.toString(),
              subtitle: 'Configured workflows',
              icon: Icons.account_tree_outlined,
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => _buildStatCard(
              title: 'Flow Quota',
              value: '${controller.total.value} / ${automationQuota.value}',
              subtitle: 'Available workflow slots',
              icon: Icons.speed,
              color: Colors.orange,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
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
        hintText: 'Search automations by name...',
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
}
