import 'package:business_whatsapp/app/common%20widgets/common_pagination.dart';
import 'package:business_whatsapp/app/common%20widgets/no_data_found.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../common widgets/custom_chip.dart';
import '../../../../Utilities/subscription_guard.dart';

class MilestoneSchedularsTable extends StatelessWidget {
  final List<Map<String, dynamic>> schedulars;
  final Function(Map<String, dynamic>, String) onActionTap;

  const MilestoneSchedularsTable({
    super.key,
    required this.schedulars,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (schedulars.isEmpty) {
      return NoDataFound(
        icon: Icons.calendar_month_outlined,
        label: 'No Schedulars Found',
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
          _buildHeader(isDark),

          // Scrollable Rows
          Expanded(
            child: ListView.separated(
              itemCount: schedulars.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final schedular = schedulars[index];
                return _buildRow(schedular, isDark);
              },
            ),
          ),

          // Pagination (Inside Card)
          _buildPaginationControls(isDark),
        ],
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
          _headerText(isDark, "SCHEDULAR NAME", flex: 3),
          _headerText(isDark, "SCHEDULE TYPE", flex: 2),
          _headerText(isDark, "STATUS", flex: 2),
          _headerText(isDark, "SCHEDULE TIME", flex: 2),
          _headerText(isDark, "LAST RUN", flex: 2),
          _headerText(isDark, "ACTIONS", flex: 3),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> schedular, bool isDark) {
    final status = (schedular['status'] ?? 'active').toString();
    final isActive = status == 'active';

    String lastRunText = 'N/A';
    final lastRunVal = schedular['lastRun'];
    if (lastRunVal != null) {
      if (lastRunVal is Timestamp) {
        lastRunText = DateFormat('MMM d, y h:mm a').format(lastRunVal.toDate());
      } else if (lastRunVal is String) {
        lastRunText = lastRunVal;
      }
    }

    return InkWell(
      onTap: () => onActionTap(schedular, 'edit'),
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
                schedular['name'] ?? 'N/A',
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

            // Type
            Expanded(
              flex: 2,
              child: Text(
                schedular['type'] ?? 'N/A',
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
                label: status,
                style: status == 'active'
                    ? ChipStyle.success
                    : ChipStyle.warning,
              ),
            ),

            // Schedule Time
            Expanded(
              flex: 2,
              child: Text(
                schedular['scheduleTime'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Last Run
            Expanded(
              flex: 2,
              child: Text(
                lastRunText,
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
              flex: 3,
              child: Obx(() {
                final canEdit = SubscriptionGuard.canEdit();
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: canEdit
                          ? () => onActionTap(schedular, 'edit')
                          : null,
                      tooltip: 'Edit',
                      color: isDark ? AppColors.gray400 : Colors.grey[600],
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 18,
                      ),
                      color: canEdit
                          ? (isActive ? Colors.orange : Colors.green)
                          : Colors.grey,
                      onPressed: canEdit
                          ? () => onActionTap(schedular, 'toggle')
                          : null,
                      tooltip: isActive ? 'Pause' : 'Play',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: (canEdit && !isActive)
                          ? AppColors.error
                          : Colors.grey,
                      onPressed: (canEdit && !isActive)
                          ? () => onActionTap(schedular, 'delete')
                          : null,
                      tooltip: isActive ? 'Stop/Pause to delete' : 'Delete',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
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

  Widget _buildPaginationControls(bool isDark) {
    // Note: Controller currently fetches all items, so we just show 1 page
    return CommonPagination(
      currentPage: 1,
      totalPages: 1,
      showingText: 'Showing ${schedulars.length} schedulars',
      onPageChanged: (page) {},
    );
  }
}
