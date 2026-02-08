import 'package:business_whatsapp/app/Utilities/subscription_guard.dart';
import 'package:intl/intl.dart';
import 'package:business_whatsapp/app/common widgets/no_data_found.dart';
import 'package:business_whatsapp/app/common widgets/common_pagination.dart';
import 'package:business_whatsapp/app/modules/broadcasts/controllers/broadcasts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_status.dart';
import '../../../data/models/broadcast_table_model.dart';
import '../../../common widgets/custom_chip.dart';

class BroadcastsTable extends StatelessWidget {
  final BroadcastsController controller;
  final Function(BroadcastTableModel, String) onActionTap;

  const BroadcastsTable({
    super.key,
    required this.controller,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Obx(() {
        // Handle loading state
        if (controller.isLoading.value) {
          return const TableShimmer(rows: 10, columns: 7);
        }

        // Handle empty list
        if (controller.broadcasts.isEmpty) {
          return NoDataFound(
            icon: Icons.campaign_outlined,
            label: 'No Broadcasts Found',
            isDark: isDark,
          );
        }

        // Build table with contacts pattern
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
              _buildHeader(context, isDark),

              // Scrollable Rows
              Expanded(
                child: ListView.separated(
                  itemCount: controller.broadcasts.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final broadcast = controller.broadcasts[index];
                    return _buildRow(context, broadcast, isDark);
                  },
                ),
              ),

              // Pagination (INSIDE the card)
              _buildPaginationControls(isDark),
            ],
          ),
        );
      }),
    );
  }

  // -------------------- HEADER --------------------
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
          _header("CAMPAIGN NAME", isDark, flex: 3),
          _header('DATE', isDark, flex: 2),
          _header("STATUS", isDark, flex: 2),
          _header("TOTAL", isDark, flex: 2),
          _header("DELIVERED", isDark, flex: 2),
          _header("FAILED", isDark, flex: 2),
          _header("ACTIONS", isDark, flex: 2),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.gray300 : const Color(0xFF6b7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // -------------------- ROW --------------------
  Widget _buildRow(
    BuildContext context,
    BroadcastTableModel broadcast,
    bool isDark,
  ) {
    bool canDelete = ![
      BroadcastStatus.pending,
      BroadcastStatus.sending,
    ].contains(broadcast.status);

    return InkWell(
      onTap: () => controller.showOverview(broadcast),
      hoverColor: isDark
          ? AppColors.gray800.withValues(alpha: 0.5)
          : Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                broadcast.broadcastName,
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
              child: Text(
                broadcast.completedAt != null
                    ? DateFormat('MMM dd, yyyy').format(broadcast.completedAt!)
                    : '-',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: CustomChip(
                label: broadcast.status.label,
                style: _getChipStyle(broadcast.status),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                (broadcast.sent + broadcast.failed).toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                broadcast.delivered.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                broadcast.failed.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),

            // -------------------- ACTION ICONS --------------------
            Expanded(
              flex: 2,
              child: Obx(
                () => Row(
                  children: [
                    // VIEW
                    IconButton(
                      tooltip:
                          (broadcast.status != BroadcastStatus.draft &&
                              SubscriptionGuard.canEdit())
                          ? "View Details"
                          : "View Details Disabled",
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color:
                            (broadcast.status != BroadcastStatus.draft &&
                                SubscriptionGuard.canEdit())
                            ? (isDark ? AppColors.gray400 : Colors.grey[600])
                            : (isDark
                                  ? AppColors.textSecondaryDark.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.textSecondaryLight.withValues(
                                      alpha: 0.4,
                                    )),
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed:
                          (broadcast.status != BroadcastStatus.draft &&
                              SubscriptionGuard.canEdit())
                          ? () => onActionTap(broadcast, "view")
                          : null,
                    ),

                    // EDIT → Enabled only when STATUS = draft
                    IconButton(
                      tooltip: broadcast.status == BroadcastStatus.draft
                          ? "Edit Broadcast"
                          : "Edit Disabled",
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: broadcast.status == BroadcastStatus.draft
                            ? (isDark ? AppColors.gray400 : Colors.grey[600])
                            : (isDark
                                  ? AppColors.textSecondaryDark.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.textSecondaryLight.withValues(
                                      alpha: 0.4,
                                    )),
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed:
                          (broadcast.status == BroadcastStatus.draft &&
                              SubscriptionGuard.canEdit())
                          ? () => onActionTap(broadcast, "edit")
                          : null,
                    ),

                    // DELETE
                    IconButton(
                      tooltip: canDelete
                          ? "Delete Broadcast"
                          : "Delete Broadcast Disabled",
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: canDelete
                            ? (isDark ? AppColors.errorDark : AppColors.error)
                            : (isDark
                                  ? AppColors.textSecondaryDark.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.textSecondaryLight.withValues(
                                      alpha: 0.4,
                                    )),
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: (canDelete && SubscriptionGuard.canEdit())
                          ? () => onActionTap(broadcast, "delete")
                          : null,
                    ),
                  ],
                ),
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
            'Showing ${controller.startItem} to ${controller.endItem} of ${controller.totalRecords} results',
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

  ChipStyle _getChipStyle(BroadcastStatus status) {
    switch (status) {
      case BroadcastStatus.sent:
        return ChipStyle.success;
      case BroadcastStatus.sending:
        return ChipStyle.info;
      case BroadcastStatus.failed:
        return ChipStyle.error;
      case BroadcastStatus.pending:
        return ChipStyle.warning;
      case BroadcastStatus.scheduled:
        return ChipStyle.info;
      case BroadcastStatus.draft:
        return ChipStyle.secondary;
    }
  }
}
