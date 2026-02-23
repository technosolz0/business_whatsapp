import 'package:business_whatsapp/app/data/models/broadcast_table_model.dart';
import 'package:business_whatsapp/app/modules/broadcasts/controllers/broadcasts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/stat_card.dart';

class OverviewSection extends GetView<BroadcastsController> {
  final BroadcastTableModel? broadcast;

  const OverviewSection({super.key, required this.broadcast});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deliveredRate = (broadcast != null && broadcast!.sent > 0)
        ? ((broadcast!.delivered / broadcast!.sent) * 100)
        : 0.0;
    final readRate = (broadcast != null && broadcast!.delivered > 0)
        ? ((broadcast!.read) / (broadcast!.delivered) * 100)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Broadcasts Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () => controller.selectedBroadcast.value = null,
              icon: Icon(Icons.close),
            ),
          ],
        ),

        const SizedBox(height: 12),
        StatCard.broadcast(
          icon: Icons.send,
          iconColor: AppColors.primary,
          title: 'Total Messages',
          value: (broadcast!.sent + broadcast!.failed).toString(),
          broadcastId: broadcast!.id,
          subtitle: '',
          changeColor: AppColors.success,
        ),
        const SizedBox(height: 16),
        StatCard.broadcast(
          icon: Icons.send,
          iconColor: AppColors.primary,
          title: 'Messages Sent',
          value: broadcast?.sent.toString(),

          subtitle: '',
          changeColor: AppColors.success,
        ),
        const SizedBox(height: 16),
        StatCard.broadcast(
          icon: Icons.task_alt,
          iconColor: AppColors.success,
          title: 'Overall Delivery Rate',
          value: '${deliveredRate.toStringAsFixed(2)}%',
          subtitle: '',
          changeColor: isDark ? AppColors.gray400 : AppColors.gray500,
        ),
        const SizedBox(height: 16),
        StatCard.broadcast(
          icon: Icons.visibility,
          iconColor: AppColors.warning,
          title: 'Overall Read Rate',
          value: '${readRate.toStringAsFixed(2)}%',
          subtitle: '',
          changeColor: AppColors.error,
        ),
        const SizedBox(height: 16),

        StatCard.broadcast(
          icon: Icons.visibility,
          iconColor: AppColors.warning,
          title: 'Invocation Failures',
          value: '${broadcast?.invocationFailures}',
          subtitle: '',
          changeColor: AppColors.error,
        ),
        const SizedBox(height: 16),

        StatCard.broadcast(
          icon: Icons.visibility,
          iconColor: AppColors.error,
          title: 'Failed',
          value: '${broadcast?.failed}',
          subtitle: '',
          changeColor: AppColors.error,
        ),
        const SizedBox(height: 16),

        // Keep all your existing StatCards and UI here…
        // (I am not repeating them for brevity)
      ],
    );
  }
}
