import 'package:adminpanel/app/common widgets/common_pagination.dart';
import 'package:adminpanel/app/common widgets/no_data_found.dart';
import 'package:adminpanel/app/data/models/template_model.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/custom_chip.dart';
import '../../../Utilities/subscription_guard.dart';
import 'package:get/get.dart';

class TemplatesTable extends StatelessWidget {
  final List<TemplateModels> templates;
  final Function(TemplateModels, String) onActionTap;

  // Cursor-based pagination
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  const TemplatesTable({
    super.key,
    required this.templates,
    required this.onActionTap,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.onNextPage,
    required this.onPreviousPage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (templates.isEmpty) {
      return Expanded(
        child: NoDataFound(
          icon: Icons.description_outlined,
          label: 'No Templates Found',
          isDark: isDark,
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
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
            // Table Header
            _buildHeader(isDark),

            // Scrollable Rows
            Expanded(
              child: ListView.separated(
                itemCount: templates.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _buildRow(template, isDark);
                },
              ),
            ),

            // Pagination (INSIDE the card)
            _buildPaginationControls(isDark),
          ],
        ),
      ),
    );
  }

  // ------------------- HEADER -------------------
  Widget _buildHeader(bool isDark) {
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
          _headerText(isDark, "TEMPLATE NAME", flex: 3),
          _headerText(isDark, "CATEGORY", flex: 2),
          _headerText(isDark, "STATUS", flex: 2),
          _headerText(isDark, "LANGUAGE", flex: 2),
          _headerText(isDark, "ACTIONS", flex: 1),
        ],
      ),
    );
  }

  Widget _headerText(bool isDark, String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.gray300 : const Color(0xFF6b7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ------------------- ROW -------------------
  Widget _buildRow(TemplateModels template, bool isDark) {
    return InkWell(
      onTap: () => onActionTap(template, 'view'),
      hoverColor: isDark
          ? AppColors.gray800.withValues(alpha: 0.5)
          : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Template Name
            Expanded(
              flex: 3,
              child: Text(
                template.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Category
            Expanded(
              flex: 2,
              child: Text(
                template.category ?? '-',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: CustomChip(
                label: template.status,
                style: _getChipStyle(template.status),
              ),
            ),

            // Language
            Expanded(
              flex: 2,
              child: Text(
                template.language,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Actions
            Expanded(
              flex: 1,
              child: Obx(() {
                final canEdit = SubscriptionGuard.canEdit();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: canEdit
                          ? () => onActionTap(template, 'copy')
                          : null,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Copy Template',
                      color: canEdit
                          ? (isDark ? AppColors.gray400 : Colors.grey[600])
                          : Colors.grey,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: canEdit
                            ? (isDark ? AppColors.errorDark : AppColors.error)
                            : Colors.grey,
                      ),
                      onPressed: canEdit
                          ? () => onActionTap(template, 'delete')
                          : null,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Template',
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- PAGINATION -------------------
  Widget _buildPaginationControls(bool isDark) {
    return CommonPagination(
      currentPage: 1, // Templates uses cursor-based pagination
      totalPages: hasNextPage ? 2 : 1,
      showingText: 'Showing ${templates.length} templates',
      onPageChanged: (page) {
        if (page > 1 && hasNextPage) {
          onNextPage();
        } else if (page < 1 && hasPreviousPage) {
          onPreviousPage();
        }
      },
    );
  }

  // ------------------- Helpers -------------------
  ChipStyle _getChipStyle(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return ChipStyle.success;
      case 'PENDING':
        return ChipStyle.warning;
      case 'REJECTED':
        return ChipStyle.error;
      default:
        return ChipStyle.secondary;
    }
  }
}
