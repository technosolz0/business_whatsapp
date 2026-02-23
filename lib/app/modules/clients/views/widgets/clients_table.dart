import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:business_whatsapp/app/Utilities/responsive.dart';
import '../../../../common widgets/common_pagination.dart';
import '../../../../common widgets/no_data_found.dart';
import '../../../../common widgets/custom_chip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/client_model.dart';

class ClientsTable extends StatelessWidget {
  final List<ClientModel> clients;
  final Function(String) onEdit;
  final Function(String, String) onDelete;

  const ClientsTable({
    super.key,
    required this.clients,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    if (clients.isEmpty) {
      return Expanded(
        child: NoDataFound(
          icon: Icons.group_outlined,
          label: 'No Clients Found',
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
                itemCount: clients.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  return _buildRow(clients[index], isDark, isMobile);
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
          _headerText("CLIENT NAME", flex: 3, isDark: isDark),
          _headerText("PHONE NUMBER", flex: 2, isDark: isDark),
          _headerText("CREATED AT", flex: 2, isDark: isDark),
          _headerText("UPDATED AT", flex: 2, isDark: isDark),
          _headerText("STATUS", flex: 2, isDark: isDark),
          _headerText("ACTIONS", flex: 2, isDark: isDark),
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

  Widget _buildRow(ClientModel client, bool isDark, bool isMobile) {
    if (isMobile) {
      return _buildMobileRow(client, isDark);
    }

    return InkWell(
      onTap: () => onEdit(client.id ?? ''),
      hoverColor: isDark
          ? AppColors.gray800.withValues(alpha: 0.5)
          : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 3,
              child: Text(
                client.name,
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
            // Phone
            Expanded(
              flex: 2,
              child: Text(
                client.phoneNumber,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            // Created At
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM dd, yyyy').format(client.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            // Updated At
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM dd, yyyy').format(client.updatedAt),
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
              flex: 2,
              child: CustomChip(
                label: client.status,
                style: _getChipStyle(client.status),
                fontSize: 12,
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
            // Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => onEdit(client.id ?? ''),
                    color: isDark ? AppColors.gray400 : Colors.grey[600],
                    tooltip: 'Edit',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => onDelete(client.id ?? '', client.name),
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

  Widget _buildMobileRow(ClientModel client, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  client.name,
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
                label: client.status,
                style: _getChipStyle(client.status),
                fontSize: 12,
                borderRadius: 8,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            client.phoneNumber,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.gray400 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created: ${DateFormat('MMM dd, yyyy').format(client.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.gray500 : Colors.grey[500],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => onEdit(client.id ?? ''),
                    color: isDark ? AppColors.gray400 : Colors.grey[600],
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => onDelete(client.id ?? '', client.name),
                    color: AppColors.error,
                    constraints: const BoxConstraints(),
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

  Widget _buildPagination() {
    return CommonPagination(
      currentPage: 1,
      totalPages: 1,
      showingText: 'Showing ${clients.length} clients',
      onPageChanged: (page) {},
    );
  }

  ChipStyle _getChipStyle(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ChipStyle.success;
      case 'inactive':
        return ChipStyle.error;
      case 'pending':
        return ChipStyle.warning;
      default:
        return ChipStyle.secondary;
    }
  }
}
