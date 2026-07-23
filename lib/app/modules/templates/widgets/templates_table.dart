import 'package:business_whatsapp/app/Utilities/responsive.dart';
import 'package:business_whatsapp/app/common widgets/common_pagination.dart';
import 'package:business_whatsapp/app/common widgets/no_data_found.dart';
import 'package:business_whatsapp/app/data/models/template_model.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/custom_chip.dart';
import '../../../Utilities/subscription_guard.dart';
import 'package:get/get.dart';

class TemplatesTable extends StatelessWidget {
  final List<TemplateModels> templates;
  final Function(TemplateModels, String) onActionTap;

  final int currentPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isNextLoading;
  final bool isPrevLoading;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  final bool isLoading;
  final int pageSize;
  final List<int> availablePageSizes;
  final Function(int) onPageSizeChanged;
  final int startItem;
  final int endItem;

  const TemplatesTable({
    super.key,
    required this.templates,
    required this.onActionTap,
    required this.currentPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.isNextLoading = false,
    this.isPrevLoading = false,
    this.isLoading = false,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.pageSize,
    required this.availablePageSizes,
    required this.onPageSizeChanged,
    required this.startItem,
    required this.endItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (templates.isEmpty) {
      return NoDataFound(
        icon: Icons.description_outlined,
        label: 'No Templates Found',
        isDark: isDark,
      );
    }

    final bool useScrollableLayout = Responsive.isMobile(context) || MediaQuery.of(context).size.height < 700;

    return LayoutBuilder(builder: (context, constraints) {
      final double tableWidth = Responsive.isMobile(context)
          ? 1000
          : (constraints.maxWidth > 900 ? constraints.maxWidth : 900);

      return Container(
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
            // Scrollable Table Content (Fixed Header, Scrollable Rows)
            if (useScrollableLayout)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      // Table Header (Fixed at top of vertical scroll)
                      _buildHeader(isDark),

                      if (isLoading)
                        LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.primaryDark : AppColors.primary,
                          ),
                        ),

                      // Scrollable Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: templates.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: isDark ? AppColors.borderDark : Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _buildRow(template, isDark);
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(builder: (context, tableConstraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: Responsive.isMobile(context)
                        ? const BouncingScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      height: tableConstraints.maxHeight,
                      child: Column(
                        children: [
                          // Table Header (Fixed at top of vertical scroll)
                          _buildHeader(isDark),

                          if (isLoading)
                            LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppColors.primaryDark : AppColors.primary,
                              ),
                            ),

                          // Scrollable Rows
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: templates.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, color: isDark ? AppColors.borderDark : Colors.grey[200]),
                                itemBuilder: (context, index) {
                                  final template = templates[index];
                                  return _buildRow(template, isDark);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

            // Pagination (Fixed at bottom)
            _buildPaginationControls(context, isDark),
          ],
        ),
      );
    });
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
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.gray300 : const Color(0xFF6b7280),
            letterSpacing: 0.5,
          ),
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
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
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
            ),

            // Category
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
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
            ),

            // Status
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CustomChip(
                  label: template.status,
                  style: _getChipStyle(template.status),
                ),
              ),
            ),

            // Language
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
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

  Widget _buildPaginationControls(BuildContext context, bool isDark) {
    final int totalPages = currentPage + (hasNextPage ? 1 : 0);

    return CommonPagination(
      currentPage: currentPage,
      totalPages: totalPages,
      isNextLoading: isNextLoading,
      isPrevLoading: isPrevLoading,
      showPageNumbers: false,
      prefixWidget: _buildPageSizeSelector(isDark),
      showingText: 'Showing $startItem to $endItem templates',
      onPageChanged: (page) {
        if (page > currentPage) {
          onNextPage();
        } else if (page < currentPage) {
          onPreviousPage();
        }
      },
    );
  }

  Widget _buildPageSizeSelector(bool isDark) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: pageSize,
          dropdownColor: isDark ? AppColors.cardDark : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isDark ? AppColors.gray400 : AppColors.gray600,
          ),
          items: availablePageSizes
              .map(
                (size) => DropdownMenuItem(
                  value: size,
                  child: Text(
                    "$size / Page",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onPageSizeChanged(value);
          },
        ),
      ),
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
