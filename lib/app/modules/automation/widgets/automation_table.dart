import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';
import '../../../common widgets/common_pagination.dart';
import '../../../common widgets/no_data_found.dart';
import '../../../common widgets/shimmer_widgets.dart';
import '../../../core/theme/app_colors.dart';
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
        return const TableShimmer(
          key: ValueKey('table_shimmer'),
          rows: 10,
          columns: 4,
        );
      }

      if (controller.automations.isEmpty) {
        return NoDataFound(
          key: const ValueKey('table_empty'),
          icon: Icons.auto_mode,
          label: 'No Automations Found',
          isDark: isDark,
        );
      }

      return Container(
        key: const ValueKey('table_content'),
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
          _header("Flow Name", isDark, flex: 4),
          _header("Status", isDark, flex: 2),
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.gray300 : const Color(0xFF6b7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    AutomationFlowModel flow,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {},
      enableFeedback: false,
      hoverColor: isDark
          ? AppColors.gray800.withValues(alpha: 0.5)
          : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                flow.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Obx(
                () => Text(
                  flow.isActive.value ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: flow.isActive.value
                        ? (isDark ? Colors.greenAccent : Colors.green)
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Edit",
                    enableFeedback: false,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.gray400
                          : AppColors.textPrimaryLight,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      Future.microtask(
                        () => controller.loadAutomationForEdit(flow),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: "Delete",
                    enableFeedback: false,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
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
            'Showing ${controller.startItem}-${controller.endItem} of ${controller.totalRecords} results',
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
