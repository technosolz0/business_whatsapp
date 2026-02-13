import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/common_pagination.dart';
import '../../../common widgets/custom_chip.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';
import '../../../common widgets/custom_dropdown.dart';
import '../../../common widgets/no_data_found.dart';
import '../../../core/theme/app_colors.dart';
import '../../../Utilities/responsive.dart';
import '../../../Utilities/subscription_guard.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../modules/roles/models/roles_model.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/navigation_controller.dart';
import '../controllers/roles_controller.dart';

class RolesView extends GetView<RolesController> {
  final MenuItem item;
  const RolesView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Row(
          children: [
            // Main Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Obx(() {
                  // Show Add Role Form or Roles List
                  if (controller.isAddingRole.value) {
                    return const Center(child: Text('Add Role Form'));
                  }

                  // Show normal roles list
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      if (isMobile)
                        _buildTopControls(context)
                      else
                        Row(
                          children: [
                            Expanded(flex: 3, child: _buildSearchBar()),
                            const SizedBox(width: 12),
                            SizedBox(width: 200, child: _buildFilterDropdown()),
                          ],
                        ),
                      const SizedBox(height: 20),
                      _buildRolesTable(context),
                    ],
                  );
                }),
              ),
            ),

            // Right Details Panel (for future use)
            if (!isMobile && !isTablet) const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Roles', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Manage user roles and permissions.',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
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
                      controller.exportRolesExcel();
                    },
                  },
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => CustomButton(
                  label: 'Add Role',
                  icon: Icons.add,
                  onPressed: () {
                    Get.offNamed(Routes.ADD_ROLES);
                    Get.find<NavigationController>().updateRoute();
                  },
                  isDisabled: !SubscriptionGuard.canEdit(),
                  type: ButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTopControls(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        // Action Buttons Row
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
                    controller.exportRolesExcel();
                  },
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(
                () => CustomButton(
                  label: 'Add Role',
                  icon: Icons.add,
                  onPressed: () {
                    Get.offNamed(Routes.ADD_ROLES);
                    Get.find<NavigationController>().updateRoute();
                  },
                  isDisabled: !SubscriptionGuard.canEdit(),
                  type: ButtonType.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search and Filter Row
        Row(
          children: [
            Expanded(flex: isMobile ? 1 : 2, child: _buildSearchBar()),
            const SizedBox(width: 12),
            if (!isMobile) SizedBox(width: 200, child: _buildFilterDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return TextField(
      controller: controller.searchController,
      onChanged: controller.updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search by role name...',
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
            initialValue: controller.selectedStatus.value == 'All'
                ? null
                : controller.selectedStatus.value,
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
              const DropdownMenuItem(value: 'Active', child: Text("Active")),
              const DropdownMenuItem(
                value: 'Inactive',
                child: Text("Inactive"),
              ),
            ],

            onChanged: (value) {
              controller.updateStatusFilter(value ?? 'All');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRolesTable(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Obx(() {
        if (controller.isLoading) {
          return const TableShimmer(rows: 10, columns: 4);
        }
        if (controller.filteredRoles.isEmpty &&
            controller.searchQuery.isNotEmpty) {
          return NoDataFound(
            icon: Icons.admin_panel_settings_outlined,
            label: 'No Role Found',
            isDark: isDark,
          );
        }
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
              // Table Header
              if (!isMobile) _buildTableHeader(),

              // Table Body
              Expanded(
                child: Obx(
                  () => ListView.separated(
                    itemCount: controller.paginatedRoles.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final role = controller.paginatedRoles[index];
                      return _buildTableRow(role, context);
                    },
                  ),
                ),
              ),

              // Pagination Controls
              _buildPaginationControls(isDark),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTableHeader() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

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
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'ROLE NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6b7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'ASSIGNED PAGES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6b7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6b7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6b7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(RolesModel role, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        // Select role for details
        controller.selectRole(role);
        if (isMobile || Responsive.isTablet(context)) {
          _showRoleDetailsBottomSheet(context, role);
        }
      },
      child: Obx(() {
        final selected = controller.selectedRole.value;
        final isSelected = selected != null && selected.id == role.id;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: 16,
          ),
          color: isSelected
              ? isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : const Color.fromARGB(255, 243, 247, 252)
              : Colors.transparent,
          child: isMobile ? _buildMobileRow(role) : _buildDesktopRow(role),
        );
      }),
    );
  }

  Widget _buildMobileRow(RolesModel role) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Row(
      children: [
        _buildAvatar(role.roleName ?? 'Unknown'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.roleName ?? 'Unknown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role.assignedPages?.length.toString() ?? '0',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              CustomChip(
                label: role.status == 1 ? 'Active' : 'Inactive',
                style: role.status == 1
                    ? ChipStyle.success
                    : ChipStyle.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              onPressed: SubscriptionGuard.canEdit()
                  ? () {
                      Get.offNamed(
                        Routes.ADD_ROLES,
                        parameters: {
                          'id': base64Encode(utf8.encode(role.id ?? '')),
                        },
                      );
                      Get.find<NavigationController>().updateRoute();
                    }
                  : null,
              tooltip: 'Edit Role',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.error,
              ),
              onPressed: SubscriptionGuard.canEdit()
                  ? () {
                      _showDeleteConfirmation(role);
                    }
                  : null,
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopRow(RolesModel role) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              _buildAvatar(role.roleName ?? 'Unknown'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  role.roleName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            _formatAssignedPages(role.assignedPages),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.gray400 : Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 1,
          child: CustomChip(
            label: role.status == 1 ? 'Active' : 'Inactive',
            style: role.status == 1 ? ChipStyle.success : ChipStyle.secondary,
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  onPressed: SubscriptionGuard.canEdit()
                      ? () {
                          Get.offNamed(
                            Routes.ADD_ROLES,
                            parameters: {
                              'id': base64Encode(utf8.encode(role.id ?? '')),
                            },
                          );
                          Get.find<NavigationController>().updateRoute();
                        }
                      : null,
                  tooltip: 'Edit Role',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: SubscriptionGuard.canEdit()
                      ? () {
                          _showDeleteConfirmation(role);
                        }
                      : null,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.isEmpty
        ? 'RL'
        : name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatAssignedPages(List<AssignedPages>? pages) {
    if (pages == null || pages.isEmpty) {
      return 'No pages assigned';
    }

    if (pages.length <= 3) {
      return pages.map((p) => p.routeName ?? 'Unknown').join(', ');
    }

    final firstThree = pages
        .take(3)
        .map((p) => p.routeName ?? 'Unknown')
        .join(', ');
    return '$firstThree +${pages.length - 3} more';
  }

  void _showDeleteConfirmation(RolesModel role) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: 'Delete Role',
        content:
            'Are you sure you want to delete ${role.roleName}? This action cannot be undone.',
        onConfirm: () async {
          if (role.id != null) {
            await controller.deleteRole(role.id!);
          }
        },
      ),
    );
  }

  void _showRoleDetailsBottomSheet(BuildContext context, RolesModel role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ScrollController scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, sheetScrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Role Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Color(0xFF1a1a1a),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildRoleDetailsContent(role),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDetailsContent(RolesModel role) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and basic info
        Center(
          child: Column(
            children: [
              _buildLargeAvatar(role.roleName ?? 'Unknown'),
              const SizedBox(height: 16),
              Text(
                role.roleName ?? 'Unknown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF1a1a1a),
                ),
              ),
              const SizedBox(height: 4),
              CustomChip(
                label: role.status == 1 ? 'Active' : 'Inactive',
                style: role.status == 1
                    ? ChipStyle.success
                    : ChipStyle.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Details Section
        _buildSectionTitle('DETAILS'),
        const SizedBox(height: 12),
        _buildDetailRow('Status', role.status == 1 ? 'Active' : 'Inactive'),
        _buildDetailRow(
          'Pages Assigned',
          role.assignedPages?.length.toString() ?? '0',
        ),
        const SizedBox(height: 24),

        // Assigned Pages Section
        _buildSectionTitle('ASSIGNED PAGES'),
        const SizedBox(height: 12),
        if (role.assignedPages != null && role.assignedPages!.isNotEmpty) ...[
          ...role.assignedPages!.map(
            (page) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark.withValues(alpha: 0.5)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.web,
                    size: 20,
                    color: isDark ? AppColors.gray300 : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      page.routeName ?? 'Unknown Page',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    page.route ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.gray400 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark.withValues(alpha: 0.5)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
            ),
            child: Text(
              'No pages assigned to this role.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.gray300 : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLargeAvatar(String name) {
    final initials = name.isEmpty
        ? 'RL'
        : name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
    final colors = [
      const Color(0xFF93C5FD),
      const Color(0xFFA78BFA),
      const Color(0xFFFBBF24),
      const Color(0xFF34D399),
      const Color(0xFFF87171),
    ];
    final color = colors[name.length % colors.length];

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6b7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.gray400 : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    return Obx(
      () => CommonPagination(
        currentPage: controller.currentPage.value,
        totalPages: controller.totalPages,
        showingText:
            'Showing ${controller.startItem} to ${controller.endItem} of ${controller.filteredRoles.length} results',
        onPageChanged: (page) {
          if (page > controller.currentPage.value) {
            controller.nextPage();
          } else if (page < controller.currentPage.value) {
            controller.prevPage();
          }
        },
      ),
    );
  }
}

// import 'dart:convert';

// import 'package:adminpanel/app/core/theme/app_colors.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:adminpanel/app/common%20widgets/common_action_button.dart';
// import 'package:adminpanel/app/common%20widgets/common_alert_dialog_delete.dart';
// import 'package:adminpanel/app/common%20widgets/common_container.dart';
// import 'package:adminpanel/app/common%20widgets/common_table.dart';
// import 'package:adminpanel/app/data/models/menu_item_model.dart';
// import 'package:adminpanel/app/modules/roles/models/roles_model.dart';
// import 'package:adminpanel/app/routes/app_pages.dart';
// import 'package:adminpanel/app/utilities/extensions.dart';

// import '../../../controllers/navigation_controller.dart';
// import '../controllers/roles_controller.dart';

// class RolesView extends GetView<RolesController> {
//   final MenuItem item;
//   const RolesView({super.key, required this.item});
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             if (Get.context!.screenType() != ScreenType.Phone)
//               Row(
//                 spacing: 8,
//                 children: [
//                   Text(
//                     "Home",
//                     style: GoogleFonts.publicSans(
//                       color: Color(0xFF8D8D8F),
//                       fontSize: 15,
//                     ),
//                   ),
//                   Icon(Icons.arrow_forward_ios, size: 16),
//                   Text(
//                     "Admin Master",
//                     style: GoogleFonts.publicSans(
//                       color: Color(0xFF8D8D8F),
//                       fontSize: 15,
//                     ),
//                   ),
//                   Icon(Icons.arrow_forward_ios, size: 18),
//                   Text(
//                     "Manage Roles",
//                     style: GoogleFonts.publicSans(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ],
//               ),
//             if (Get.context!.screenType() != ScreenType.Phone)
//               const SizedBox(height: 30),

//             Obx(
//               () => controller.showLoading.value
//                   ? CommonContainer(
//                       child: SizedBox(
//                         height: context.height * 0.4,
//                         width: context.width,
//                         child: const Center(
//                           child: CircularProgressIndicator(
//                             color: AppColors.primary,
//                           ),
//                         ),
//                       ),
//                     )
//                   : AbsorbPointer(
//                       absorbing: controller.showLoading.value,
//                       child: CommonContainer(
//                         child: FocusTraversalGroup(
//                           child: CustomTable(
//                             showLoading: controller.showLoading,
//                             columns: const ['ROLE', 'ASSIGNED PAGES', 'ACTION'],
//                             addButtonLabel: "Role",
//                             headerIcons: [
//                               Image.asset(
//                                 'assets/icons/sort_icon.png',
//                                 height: 20,
//                                 width: 20,
//                               ),
//                               null,
//                               null,
//                             ],
//                             onHeaderIconTap: [
//                               () => controller.sortRolesByField('role'),
//                               null,
//                               null,
//                             ],
//                             rows: controller.rowData,
//                             columnSpacing:
//                                 context.screenType() == ScreenType.Desktop
//                                 ? context.width * 0.1
//                                 : context.screenType() == ScreenType.Tablet
//                                 ? 40
//                                 : 70,
//                             childrens: [
//                               (child, i) => Text(
//                                 child.toString(),
//                                 style: GoogleFonts.publicSans(
//                                   fontSize: 16,
//                                   color: Color(0xFF656772),
//                                 ),
//                               ),
//                               (child, i) => Text(
//                                 child.toString(),
//                                 style: GoogleFonts.publicSans(
//                                   fontSize: 16,
//                                   color: Color(0xFF656772),
//                                 ),
//                               ),
//                               (child, i) {
//                                 RolesModel data = RolesModel.fromJson(
//                                   jsonDecode(child),
//                                 );
//                                 return Wrap(
//                                   children: [
//                                     CommonActionButton(
//                                       title: "Edit",
//                                       enabled: item.canEdit,
//                                       onPressed: () async {
//                                         Get.offNamed(
//                                           Routes.ADD_ROLES,
//                                           parameters: {
//                                             'id': data.id == null
//                                                 ? ''
//                                                 : base64Encode(
//                                                     utf8.encode(data.id!),
//                                                   ),
//                                           },
//                                         );
//                                         Get.find<NavigationController>()
//                                             .updateRoute();
//                                       },
//                                       asset: "assets/icons/edit_icon.png",
//                                     ),
//                                     CommonActionButton(
//                                       title: "Delete",
//                                       enabled: item.canDelete,
//                                       onPressed: () {
//                                         showDialog(
//                                           context: context,
//                                           builder: (context) {
//                                             return CommonAlertDialogDelete(
//                                               onTapYes: () async {
//                                                 if (data.id != null) {
//                                                   Get.back();
//                                                   controller.showLoading.value =
//                                                       true;
//                                                   await controller.deleteRole(
//                                                     data.id!,
//                                                   );
//                                                 }
//                                               },
//                                             );
//                                           },
//                                         );
//                                       },
//                                       asset: "assets/icons/delete_icon.png",
//                                     ),
//                                   ],
//                                 );
//                               },
//                             ],
//                             currentPage: controller.currentPage.value,
//                             listInfo: "Role Type",
//                             showTableContents: true,
//                             onClickedPrevPage: () {
//                               controller.prevPage();
//                             },
//                             onClickedNextPage: () {
//                               controller.nextPage();
//                             },
//                             onClickedAdd: () {
//                               Get.offNamed(Routes.ADD_ROLES);
//                               Get.find<NavigationController>().updateRoute();
//                             },
//                             pageSize: controller.pageSize.value,
//                             availablePageSizes: controller.availablePageSizes,
//                             onPageSizeChanged: (newSize) {
//                               controller.updatePageSize(newSize);
//                             },
//                             onClickedExport: () {
//                               controller.exportRolesExcel();
//                             },
//                             isFirstPage: controller.currentPage.value == 1,
//                             isLastPage: !controller.hasMore,

//                             searchController: controller.searchController,
//                             onClickedSearch: () {
//                               controller.searchRoles(
//                                 controller.searchController.text,
//                               );
//                             },
//                             onClickedReset: () {
//                               controller.searchController.clear();
//                               controller.searchRoles('');
//                             },
//                             searchByOptions: ["Name", "Email", "Role"],
//                             exportable: const [true, true, true],
//                           ),
//                         ),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
