import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/no_data_found.dart';
import '../../../common widgets/common_pagination.dart';
import '../../../common widgets/shimmer_widgets.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';
import '../../../routes/app_pages.dart';
import '../controllers/automation_controller.dart';
import '../models/automation_model.dart';

class AutomationTable extends StatelessWidget {
  final AutomationController controller;

  const AutomationTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return const TableShimmer(rows: 8, columns: 4);
      }

      if (controller.automations.isEmpty) {
        return NoDataFound(
          icon: Icons.auto_mode,
          label: 'No Automations Found',
          isDark: isDark,
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: ListView.separated(
                itemCount: controller.automations.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final flow = controller.automations[index];
                  return _buildRow(context, flow, isDark);
                },
              ),
            ),
            _buildPaginationControls(isDark),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.gray100.withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          _header("Flow Name", isDark, flex: 3),
          _header("Trigger Keywords", isDark, flex: 3),
          _header("Status", isDark, flex: 2),
          _header("Created", isDark, flex: 2),
          _header("Actions", isDark, flex: 2),
        ],
      ),
    );
  }

  Widget _header(String text, bool isDark, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.gray300 : const Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AutomationFlowModel flow,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate =
        flow.createdAt != null ? dateFormat.format(flow.createdAt!) : '-';

    return InkWell(
      onTap: () async {
        await controller.loadAutomationForEdit(flow);
        Get.toNamed(Routes.CREATE_AUTOMATION);
      },
      hoverColor: isDark
          ? AppColors.gray800.withValues(alpha: 0.5)
          : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // 1. Flow Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      flow.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Trigger Keywords
            Expanded(
              flex: 3,
              child: flow.triggerKeywords.isEmpty
                  ? Text(
                      'None',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: flow.triggerKeywords.take(3).map((kw) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            kw,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            // 3. Status Switch
            Expanded(
              flex: 2,
              child: Obx(
                () => Row(
                  children: [
                    Switch(
                      value: flow.isActive.value,
                      activeThumbColor: Colors.green,
                      onChanged: (_) =>
                          controller.toggleAutomationStatus(flow),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      flow.isActive.value ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: flow.isActive.value
                            ? Colors.green
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Created Date
            Expanded(
              flex: 2,
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),

            // 5. Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Edit Flow",
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.gray400
                          : AppColors.textPrimaryLight,
                    ),
                    onPressed: () async {
                      await controller.loadAutomationForEdit(flow);
                      Get.toNamed(Routes.CREATE_AUTOMATION);
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: "Delete Flow",
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => Get.dialog(
                      CommonAlertDialogDelete(
                        title: 'Delete Automation',
                        content:
                            'Are you sure you want to delete "${flow.name}"? This action cannot be undone.',
                        onConfirm: () async =>
                            controller.deleteAutomation(flow),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    return Obx(
      () => CommonPagination(
        currentPage: controller.currentPage.value,
        totalPages: controller.totalPages.value,
        showingText:
            'Showing ${controller.startItem}-${controller.endItem} of ${controller.totalRecords} flows',
        onPageChanged: (page) {
          if (page > controller.currentPage.value) {
            controller.goToNextPage();
          } else if (page < controller.currentPage.value) {
            controller.goToPreviousPage();
          }
        },
      ),
    );
  }
}
