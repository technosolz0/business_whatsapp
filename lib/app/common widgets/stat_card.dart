import 'package:flutter/material.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'message_details_dialog.dart';

enum StatCardType { dashboard, broadcast }

class StatCard extends StatelessWidget {
  // Dashboard style properties
  final String? title;
  final String? value;
  final String? change;
  final Color? changeColor;

  // Broadcast style properties
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;
  final String? broadcastId;

  // Common properties
  final StatCardType type;

  const StatCard.dashboard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.changeColor,
  }) : type = StatCardType.dashboard,
       icon = null,
       iconColor = null,
       subtitle = null,
       broadcastId = null;

  const StatCard.broadcast({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.changeColor,
    this.broadcastId,
  }) : type = StatCardType.broadcast,
       change = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(type == StatCardType.dashboard ? 24 : 16),
      decoration: BoxDecoration(
        color: type == StatCardType.dashboard
            ? (isDark ? AppColors.cardDark : Colors.white)
            : (isDark
                  ? AppColors.gray800.withValues(alpha: 0.5)
                  : AppColors.gray50),
        borderRadius: BorderRadius.circular(12),
        boxShadow: type == StatCardType.dashboard
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: type == StatCardType.dashboard
          ? _buildDashboardContent(context)
          : _buildBroadcastContent(context, isDark),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double titleSize = constraints.maxWidth > 200 ? 16 : 14;
        final double valueSize = constraints.maxWidth > 200 ? 32 : 24;
        final double changeSize = constraints.maxWidth > 200 ? 14 : 12;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.gray400 : const Color(0xFF6B7280),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value!,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF111827),
                    letterSpacing: -1,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              change!,
              style: TextStyle(
                fontSize: changeSize,
                fontWeight: FontWeight.w500,
                color: changeColor!,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBroadcastContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor!.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon!, size: 20, color: iconColor!),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value!,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (title == 'Total Messages') ...[
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        MessageDetailsDialog(broadcastId: broadcastId),
                  );
                },
                child: const Text('View Details'),
              ),
            ],
          ],
        ),

        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: changeColor!,
          ),
        ),
      ],
    );
  }
}
