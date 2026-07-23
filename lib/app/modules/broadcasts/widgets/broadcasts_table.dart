import 'package:business_whatsapp/app/Utilities/responsive.dart';
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
import 'overview_section.dart';

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

    return Obx(() {
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

      final bool useScrollableLayout =
          Responsive.isMobile(context) ||
          MediaQuery.of(context).size.height < 700;

      return LayoutBuilder(
        builder: (context, constraints) {
          final double tableWidth = useScrollableLayout
              ? 1100
              : (constraints.maxWidth > 1000 ? constraints.maxWidth : 1000);

          return Container(
            height: useScrollableLayout ? null : constraints.maxHeight,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: useScrollableLayout
                  ? const BouncingScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              primary: false,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    // Table Header
                    _buildHeader(context, isDark),

                    // Scrollable Rows
                    useScrollableLayout
                        ? ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.broadcasts.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final broadcast = controller.broadcasts[index];
                              return _buildRow(context, broadcast, isDark);
                            },
                          )
                        : Expanded(
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

                    _buildPaginationControls(isDark),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
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
          _header('SENT & SCHEDULED DATE', isDark, flex: 2),
          _header("STATUS", isDark, flex: 2),
          _header("TOTAL", isDark, flex: 2),
          _header("DELIVERED", isDark, flex: 2),
          _header("FAILED", isDark, flex: 2),
          _header("ACTIONS", isDark, flex: 3),
        ],
      ),
    );
  }

  Widget _header(String text, bool isDark, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
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

    return Obx(() {
      final isSelected = controller.selectedBroadcast.value?.id == broadcast.id;

      return InkWell(
        onTap: () {
          controller.showOverview(broadcast);
          final bool useScrollable =
              Responsive.isMobile(context) ||
              Responsive.isTablet(context) ||
              MediaQuery.of(context).size.height < 700;
          if (useScrollable) {
            _showBroadcastOverviewBottomSheet(context, broadcast);
          }
        },
        hoverColor: isDark
            ? AppColors.gray800.withValues(alpha: 0.5)
            : Colors.grey[50],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: isSelected
              ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.08))
              : null,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
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
                      if (broadcast.enableRetry) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync,
                              size: 14,
                              color: isDark
                                  ? Colors.green[400]
                                  : const Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Auto Retry ",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.green[400]
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              broadcast.retryCampaignStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.green[400]
                                    : broadcast.retryCampaignStatus ==
                                              "Completed" ||
                                          broadcast.retryCampaignStatus ==
                                              "Completed Early"
                                    ? const Color.fromARGB(255, 58, 201, 65)
                                    : broadcast.retryCampaignStatus == "Active"
                                    ? AppColors.primary
                                    : Colors.red[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    (broadcast.status == BroadcastStatus.scheduled
                                ? broadcast.scheduledAt
                                : broadcast.completedAt) !=
                            null
                        ? DateFormat(
                            broadcast.status == BroadcastStatus.scheduled
                                ? 'MMM d, hh:mm a'
                                : 'MMM dd, yyyy',
                          ).format(
                            broadcast.status == BroadcastStatus.scheduled
                                ? broadcast.scheduledAt!
                                : broadcast.completedAt!,
                          )
                        : '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: broadcast.status == BroadcastStatus.scheduled
                          ? AppColors.primary
                          : isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CustomChip(
                    label: broadcast.status.label,
                    style: _getChipStyle(broadcast.status),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
              ),

              // -------------------- ACTION ICONS --------------------
              Expanded(
                flex: 3,
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

                      if (broadcast.retryCampaignStatus == 'Active') ...[
                        if (broadcast.enableRetry) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: "Stop Retry",
                            child: InkWell(
                              onTap: () => onActionTap(broadcast, "stop"),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.stop_circle_outlined,
                                      size: 16,
                                      color: isDark
                                          ? Colors.orange[300]
                                          : Colors.orange[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Stop",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.orange[300]
                                            : Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPaginationControls(bool isDark) {
    return Obx(
      () => CommonPagination(
        currentPage: controller.currentPage.value,
        totalPages: controller.totalPages.value,
        showingText:
            'Showing ${controller.startItem} to ${controller.endItem} of ${controller.totalRecords} results',
        onPageChanged: (page) => controller.loadBroadcasts(page: page),
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

  void _showBroadcastOverviewBottomSheet(
    BuildContext context,
    BroadcastTableModel broadcast,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Register a worker to pop bottom sheet when selectedBroadcast changes to null
    late Worker worker;
    worker = ever(controller.selectedBroadcast, (selected) {
      if (selected == null) {
        Navigator.of(context).pop();
        worker.dispose();
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
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
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: OverviewSection(broadcast: broadcast),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      worker.dispose();
      controller.selectedBroadcast.value = null;
    });
  }
}
