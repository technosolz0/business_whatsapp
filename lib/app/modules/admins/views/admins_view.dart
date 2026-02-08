import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/custom_dropdown.dart';
import '../../../common widgets/common_textfield.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';
import '../../../core/theme/app_colors.dart';
import '../../../Utilities/responsive.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/models/admins_model.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../Utilities/subscription_guard.dart';
import '../controllers/admins_controller.dart';
import 'widgets/admins_table.dart';

class AdminsView extends GetView<AdminsController> {
  final MenuItem item;
  const AdminsView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, isDark),
              const SizedBox(height: 24),

              // Search & Controls
              _buildControls(context, isMobile, isDark),
              const SizedBox(height: 20),

              // Table
              Obx(
                () => AdminsTable(
                  admins: controller.filteredAdmins,
                  isLoading: controller.isLoading,
                  onEdit: (admin) => _navigateToEdit(admin),
                  onDelete: (admin) => _showDeleteConfirmation(admin),
                  onSelect: (admin) {
                    controller.selectAdmin(admin);
                    if (isMobile) _showAdminDetailsBottomSheet(context, admin);
                  },
                  selectedAdmin: controller.selectedAdmin.value,
                  currentPage: controller.currentPage.value,
                  totalPages: controller.hasMore
                      ? controller.currentPage.value + 1
                      : controller.currentPage.value,
                  onPageChanged: (page) {
                    if (page > controller.currentPage.value) {
                      controller.nextPage();
                    } else if (page < controller.currentPage.value) {
                      controller.prevPage();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admins',
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage administrator accounts',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildAddButton(),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admins', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Manage administrator accounts and permissions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: 180,
              child: CustomDropdown<String>(
                label: null,
                hint: "Export",
                value: null,
                items: const [
                  DropdownMenuItem(
                    value: "excel",
                    child: Text("Export to Excel"),
                  ),
                ],
                actions: {
                  "excel": () {
                    controller.exportAdminsExcel();
                  },
                },
              ),
            ),
            const SizedBox(width: 12),
            _buildAddButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Obx(
      () => CustomButton(
        label: 'Add Admin',
        icon: Icons.add,
        onPressed: () async {
          if (await controller.canAddMoreAdmins()) {
            Get.offNamed(Routes.ADD_ADMINS);
            Get.find<NavigationController>().updateRoute();
          } else {
            _showLimitExceededDialog(Get.context!);
          }
        },
        isDisabled: !SubscriptionGuard.canEdit(),
        type: ButtonType.primary,
        width: Responsive.isMobile(Get.context!) ? null : 160,
      ),
    );
  }

  Widget _buildControls(BuildContext context, bool isMobile, bool isDark) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomDropdown<String>(
                  label: null,
                  hint: "Export",
                  value: null,
                  items: const [
                    DropdownMenuItem(
                      value: "excel",
                      child: Text("📊 Export to Excel"),
                    ),
                  ],
                  actions: {
                    "excel": () {
                      controller.exportAdminsExcel();
                    },
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonTextfield(
            controller: controller.searchController,
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search, size: 20),
            onChanged: controller.updateSearchQuery,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: isMobile ? 1 : 2,
          child: CommonTextfield(
            controller: controller.searchController,
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search, size: 20),
            onChanged: controller.updateSearchQuery,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 200, child: _buildFilterDropdown(isDark)),
      ],
    );
  }

  Widget _buildFilterDropdown(bool isDark) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(8), // Standard radius
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonFormField<String>(
            menuMaxHeight: 300,
            initialValue: controller.selectedRole.value == 'All'
                ? null
                : controller.selectedRole.value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
            dropdownColor: isDark ? AppColors.cardDark : Colors.white,
            hint: Text(
              'Filter by Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.gray400 : Colors.black,
              ),
            ),
            items: [
              const DropdownMenuItem(value: 'All', child: Text("All")),
              ...controller.allRoles
                  .where((role) => role != 'All')
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
            ],
            onChanged: (value) {
              controller.updateRoleFilter(value ?? 'All');
            },
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(AdminsModel admin) {
    Get.offNamed(
      Routes.ADD_ADMINS,
      parameters: {'id': base64Encode(utf8.encode(admin.id ?? ''))},
    );
    Get.find<NavigationController>().updateRoute();
  }

  void _showDeleteConfirmation(AdminsModel admin) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: 'Delete Admin',
        content:
            'Are you sure you want to delete ${admin.fullName}? This action cannot be undone.',
        onConfirm: () async {
          if (admin.id != null) {
            await controller.deleteAdmin(admin.id!);
          }
        },
      ),
    );
  }

  void _showLimitExceededDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Limit Exceeded',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You have reached the maximum number of admins allowed for your plan. Please upgrade your plan to add more admins.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showAdminDetailsBottomSheet(BuildContext context, AdminsModel admin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Admin Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 24),
              _detailRow('Name', admin.fullName, isDark),
              _detailRow('Email', admin.email ?? '-', isDark),
              _detailRow('Role', admin.role ?? '-', isDark),
              _detailRow(
                'Status',
                admin.status == 1 ? 'Active' : 'Inactive',
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.gray500 : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
