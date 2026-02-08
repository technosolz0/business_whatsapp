import 'package:get/get.dart';
import '../../../Utilities/subscription_guard.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_status.dart';

import '../../../data/models/broadcast_table_model.dart';
import '../../../common widgets/custom_chip.dart';

class BroadcastCard extends StatelessWidget {
  final BroadcastTableModel broadcast;
  final VoidCallback onActionTap;
  final VoidCallback onDeleteTap;
  const BroadcastCard({
    super.key,
    required this.broadcast,
    required this.onActionTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    BroadcastStatus status = broadcast.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  broadcast.broadcastName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              CustomChip(
                label: status.label,
                style: _getChipStyle(broadcast.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(
                context: context,
                label: 'Sent',
                value: broadcast.sent.toString(),
              ),
              _StatColumn(
                context: context,
                label: 'Delivered',
                value: broadcast.delivered.toString(),
              ),
              _StatColumn(
                context: context,
                label: 'Read',
                value: broadcast.read.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: SubscriptionGuard.canEdit() ? onActionTap : null,
                  child: Text(
                    broadcast.actionLabel, // View / Edit
                    style: TextStyle(
                      color: SubscriptionGuard.canEdit()
                          ? AppColors.primary
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: SubscriptionGuard.canEdit() ? onDeleteTap : null,
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: SubscriptionGuard.canEdit()
                          ? AppColors.error
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ChipStyle _getChipStyle(BroadcastStatus status) {
    switch (status) {
      case BroadcastStatus.sent:
        return ChipStyle.success; // Green

      case BroadcastStatus.sending:
        return ChipStyle.info; // Orange-ish (or your custom info color)

      case BroadcastStatus.failed:
        return ChipStyle.error; // Red

      case BroadcastStatus.pending:
        return ChipStyle.warning; // Cyan/Info substitute

      case BroadcastStatus.scheduled:
        return ChipStyle.info; // Purple-ish (closest)

      case BroadcastStatus.draft:
        return ChipStyle.secondary; // Gray
    }
  }
}

class _StatColumn extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;

  const _StatColumn({
    required this.context,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
