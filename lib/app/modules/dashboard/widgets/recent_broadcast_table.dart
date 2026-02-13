import 'package:adminpanel/app/utilities/responsive.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/recent_broadcast_model.dart';
import '../../../data/models/broadcast_status.dart';
import '../../../common widgets/custom_chip.dart';

class RecentBroadcastsTable extends StatelessWidget {
  final List<RecentBroadcastModel> broadcasts;
  final Function(RecentBroadcastModel) onActionTap;

  const RecentBroadcastsTable({
    super.key,
    required this.broadcasts,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Recent Broadcasts',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: (broadcasts.length * 60.0 + 80).clamp(200.0, 500.0),
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(isDark, isMobile, isTablet),

              // Rows
              Expanded(
                child: broadcasts.isEmpty
                    ? Center(
                        child: Text(
                          'No recent broadcasts',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: broadcasts.length,
                        itemBuilder: (context, index) {
                          return _buildRow(
                            context,
                            broadcasts[index],
                            index,
                            isDark,
                            isMobile,
                            isTablet,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.sectionDark : AppColors.sectionLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: isMobile ? 3 : 4,
            child: Text(
              'CAMPAIGN NAME',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          if (!isMobile) ...[
            Expanded(
              flex: 2,
              child: Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'RECIPIENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          Expanded(
            flex: isMobile ? 2 : 2,
            child: Text(
              'DATE',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    RecentBroadcastModel broadcast,
    int index,
    bool isDark,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Campaign Name
          Expanded(
            flex: isMobile ? 3 : 4,
            child: Text(
              broadcast.broadcastName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status (hidden on mobile)
          if (!isMobile)
            Expanded(
              flex: 2,
              child: CustomChip(
                label: broadcast.status.label,
                style: _getChipStyle(broadcast.status),
              ),
            ),

          // Recipients (hidden on mobile)
          if (!isMobile)
            Expanded(
              flex: 2,
              child: Text(
                broadcast.recipients.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Date
          Expanded(
            flex: isMobile ? 2 : 2,
            child: Text(
              broadcast.date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
