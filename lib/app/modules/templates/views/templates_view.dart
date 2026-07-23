import 'package:business_whatsapp/app/core/constants/language_codes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/Utilities/responsive.dart';
import 'package:business_whatsapp/app/utilities/constants/app_constants.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../Utilities/subscription_guard.dart';
import '../controllers/create_template_controller.dart';
import '../controllers/templates_controller.dart';
import '../widgets/templates_table.dart';
import 'create_template_view.dart';

class TemplatesView extends GetView<TemplatesController> {
  const TemplatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final createController = Get.find<CreateTemplateController>();
    return Obx(() {
      if (controller.isCreatingTemplate.value) {
        return StandardPageLayout(
          title: createController.isEditMode.value
              ? 'Edit Template'
              : 'Create New Template',
          subtitle:
              'Design a new WhatsApp message template for your campaigns.',
          showBackButton: true,
          onBack: controller.cancelCreation,
          isContentScrollable: true,
          child:  CreateTemplateView(),
        );
      }

      final bool useScrollableLayout = Responsive.isMobile(context) || MediaQuery.of(context).size.height < 700;

      return StandardPageLayout(
        title: 'Templates',
        subtitle: 'Create and manage your WhatsApp message templates.',
        isContentScrollable: useScrollableLayout,
        headerActions: [
          CustomButton(
            label: 'Create Template',
            onPressed: controller.createTemplate,
            isDisabled: !SubscriptionGuard.canEdit(),
            icon: Icons.add,
            type: ButtonType.primary,
          ),
        ],
        toolbarWidgets: [
          Expanded(child: _buildSearchField()),
          if (!Responsive.isMobile(context)) const SizedBox(width: 16),
          _buildFilters(context),
        ],
        child: Obx(() {
          // Show shimmer only on initial load (empty list + main loader active)
          if (controller.isLoading.value && controller.templates.isEmpty) {
            return const TableShimmer(rows: 10, columns: 5);
          }

          return TemplatesTable(
            templates: controller.filteredTemplates,
            onActionTap: (template, action) {
              controller.onTemplateAction(template, action);
            },
            currentPage: controller.currentPage.value,
            hasNextPage: controller.nextCursor != null,
            hasPreviousPage:
                controller.currentPage.value > 1 && controller.prevCursor != null,
            isLoading: controller.isLoading.value ||
                controller.isNextLoading.value ||
                controller.isPrevLoading.value,
            isNextLoading: controller.isNextLoading.value,
            isPrevLoading: controller.isPrevLoading.value,
            onNextPage: controller.loadNextPage,
            onPreviousPage: controller.loadPreviousPage,
            pageSize: controller.pageSize.value,
            availablePageSizes: controller.availablePageSizes,
            onPageSizeChanged: controller.updatePageSize,
            startItem: controller.startItem,
            endItem: controller.endItem,
          );
        }),
      );
    });
  }

  Widget _buildSearchField() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return TextField(
      onChanged: controller.setSearchQuery,
      maxLength: 50,
      controller: TextEditingController(text: controller.searchQuery.value)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: controller.searchQuery.value.length),
        ),
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: 'Search by template name...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.gray500 : Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? AppColors.gray500 : Colors.grey[400],
          size: 20,
        ),
        suffixIcon: Obx(
          () => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => controller.setSearchQuery(''),
                  color: isDark ? AppColors.gray500 : Colors.grey[400],
                )
              : const SizedBox.shrink(),
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

  Widget _buildFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: AppConstants.formSpacingMobile,
      children: [
        _buildFilterDropdown(
          label: 'Status',
          items: ['All', 'Approved', 'Pending', 'Rejected'],
          selectedValue: controller.selectedStatus,
          onChanged: controller.setStatusFilter,
        ),
        _buildFilterDropdown(
          label: 'Category',
          items: ['All', 'Marketing', 'Utility'],
          selectedValue: controller.selectedCategory,
          onChanged: controller.setCategoryFilter,
        ),
        _buildFilterDropdown(
          label: 'Language',
          items: ['All', ...LanguageCodes.languageList],
          selectedValue: controller.selectedLanguageName,
          onChanged: controller.setLanguageFilter,
        ),
      ],
    );
  }

  
  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required RxString selectedValue,
    required Function(String) onChanged,
  }) {
    return Obx(() {
      final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
      final isMobile = Responsive.isMobile(Get.context!);

      return SizedBox(
        height: 48,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: isMobile,
              value: selectedValue.value,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 14,
              ),
              dropdownColor: isDark ? AppColors.cardDark : Colors.white,
              hint: Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 14,
                ),
              ),
              selectedItemBuilder: (BuildContext context) {
                return items.map((String value) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value == 'All' ? label : '$label: $value',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      );
    });
  }
}
