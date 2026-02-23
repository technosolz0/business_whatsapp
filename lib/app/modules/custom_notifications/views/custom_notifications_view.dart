import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:intl/intl.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/no_data_found.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utilities/responsive.dart';
import '../controllers/custom_notifications_controller.dart';
import '../../../data/models/custom_notification_model.dart';

class CustomNotificationsView extends GetView<CustomNotificationsController> {
  const CustomNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildNotificationsTable(context),
            ],
          ),
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
              Text(
                'Custom Notifications',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Manage custom notifications for your application.',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!isMobile) ...[const SizedBox(width: 16), _buildAddButton(context)],
        if (isMobile) _buildAddButton(context),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return CustomButton(
      label: 'Add Notification',
      icon: Icons.add,
      onPressed: controller.navigateToCreate,
      type: ButtonType.primary,
    );
  }

  Widget _buildNotificationsTable(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const TableShimmer(rows: 10, columns: 5);
        }
        if (controller.notifications.isEmpty) {
          return NoDataFound(
            icon: Icons.notifications_off_outlined,
            label: 'No Notifications Yet',
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
          ),
          child: Column(
            children: [
              if (!isMobile) _buildTableHeader(context),
              Expanded(
                child: ListView.separated(
                  itemCount: controller.notifications.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return _buildTableRow(notification, context);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Expanded(flex: 2, child: Text('TYPE', style: _headerStyle)),
          Expanded(flex: 4, child: Text('MESSAGE', style: _headerStyle)),
          Expanded(flex: 2, child: Text('DURATION', style: _headerStyle)),
          Expanded(flex: 2, child: Text('CREATED AT', style: _headerStyle)),
          Expanded(flex: 1, child: Text('ACTIONS', style: _headerStyle)),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6b7280),
    letterSpacing: 0.5,
  );

  Widget _buildTableRow(
    CustomNotificationModel notification,
    BuildContext context,
  ) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeBadge(notification.type),
                Text(DateFormat('MMM dd, yyyy').format(notification.createdAt)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: ${notification.duration}',
              style: TextStyle(color: Colors.grey),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => controller.navigateToEdit(notification),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () =>
                      controller.deleteNotification(notification.id!),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildTypeBadge(notification.type)),
          Expanded(
            flex: 4,
            child: Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              notification.duration,
              style: TextStyle(
                color: isDark ? AppColors.gray400 : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(notification.createdAt),
              style: TextStyle(
                color: isDark ? AppColors.gray400 : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
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
                  onPressed: () => controller.navigateToEdit(notification),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: () =>
                      controller.deleteNotification(notification.id!),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = controller.getTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            type,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
