import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:intl/intl.dart';

import '../../../../Utilities/responsive.dart';
import '../../../../common widgets/common_pagination.dart';
import '../../../../common widgets/custom_chip.dart';
import '../../../../common widgets/no_data_found.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admins_model.dart';
import '../../../../Utilities/subscription_guard.dart';

class AdminsTable extends StatelessWidget {
  final List<AdminsModel> admins;
  final bool isLoading;
  final Function(AdminsModel) onEdit;
  final Function(AdminsModel) onDelete;
  final Function(AdminsModel) onSelect;
  final AdminsModel? selectedAdmin;

  // Pagination props
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final int totalRecords; // Optional for showing "Showing X of Y"

  const AdminsTable({
    super.key,
    required this.admins,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    this.selectedAdmin,
    this.currentPage = 1,
    this.totalPages = 1,
    required this.onPageChanged,
    this.totalRecords = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    if (isLoading) {
      return const Expanded(child: TableShimmer(rows: 10, columns: 6));
    }

    if (admins.isEmpty) {
      return Expanded(
        child: NoDataFound(
          icon: Icons.admin_panel_settings_outlined,
          label: 'No Admins Found',
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
            // Header (Desktop only)
            if (!isMobile) _buildHeader(isDark),

            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: admins.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  return _buildRow(context, admins[index], isDark, isMobile);
                },
              ),
            ),

            // Pagination
            _buildPagination(),
          ],
        ),
      ),
    );
  }

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
          _headerText("NAME", flex: 3, isDark: isDark), // Combined Avatar+Name
          _headerText("EMAIL", flex: 2, isDark: isDark),
          _headerText("ROLE", flex: 2, isDark: isDark),
          _headerText("STATUS", flex: 1, isDark: isDark),
          _headerText("LAST LOGIN", flex: 1, isDark: isDark),
          _headerText("ACTIONS", flex: 1, isDark: isDark),
        ],
      ),
    );
  }

  Widget _headerText(String text, {required int flex, required bool isDark}) {
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

  Widget _buildRow(
    BuildContext context,
    AdminsModel admin,
    bool isDark,
    bool isMobile,
  ) {
    if (isMobile) {
      return _buildMobileRow(context, admin, isDark);
    }

    final isSelected = selectedAdmin?.id == admin.id;

    return InkWell(
      onTap: () => onSelect(admin),
      hoverColor: isDark
          ? AppColors.gray800.withValues(alpha: 0.5)
          : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isSelected
            ? (isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : const Color.fromARGB(255, 243, 247, 252))
            : Colors.transparent,
        child: Row(
          children: [
            // Name + Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _buildAvatar(admin.fullName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      admin.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
            // Email
            Expanded(
              flex: 2,
              child: Text(
                admin.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Role
            Expanded(
              flex: 2,
              child: Text(
                admin.role ?? 'Unknown',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: CustomChip(
                label: admin.status == 1 ? 'Active' : 'Inactive',
                style: admin.status == 1
                    ? ChipStyle.success
                    : ChipStyle.secondary,
                fontSize: 12,
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            // Last Login
            Expanded(
              flex: 1,
              child: Text(
                admin.lastLoggedIn != null
                    ? DateFormat('dd MMM yyyy').format(admin.lastLoggedIn!)
                    : 'Never',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: SubscriptionGuard.canEdit()
                        ? () => onEdit(admin)
                        : null,
                    color: isDark ? AppColors.gray400 : Colors.grey[600],
                    tooltip: 'Edit',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: SubscriptionGuard.canEdit()
                        ? () => onDelete(admin)
                        : null,
                    color: AppColors.error,
                    tooltip: 'Delete',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
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

  Widget _buildMobileRow(BuildContext context, AdminsModel admin, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(admin.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            admin.fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        CustomChip(
                          label: admin.status == 1 ? 'Active' : 'Inactive',
                          style: admin.status == 1
                              ? ChipStyle.success
                              : ChipStyle.secondary,
                          fontSize: 12,
                          borderRadius: 6,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      admin.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.gray400 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Role',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.gray500 : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    admin.role ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: SubscriptionGuard.canEdit()
                        ? () => onEdit(admin)
                        : null,
                    color: isDark ? AppColors.gray400 : Colors.grey[600],
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: SubscriptionGuard.canEdit()
                        ? () => onDelete(admin)
                        : null,
                    color: AppColors.error,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.isEmpty
        ? 'AD'
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

  Widget _buildPagination() {
    return CommonPagination(
      currentPage: currentPage,
      totalPages: totalPages > 0 ? totalPages : 1,
      showingText:
          'Showing ${admins.length} ${totalRecords > 0 ? 'of $totalRecords' : ''} admins',
      onPageChanged: onPageChanged,
    );
  }
}
