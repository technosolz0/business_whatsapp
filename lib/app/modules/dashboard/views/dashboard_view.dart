import 'package:business_whatsapp/app/modules/dashboard/widgets/recent_broadcast_table.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../../Utilities/responsive.dart';
import '../../../Utilities/subscription_guard.dart';
import '../../../data/services/subscription_service.dart';
import '../controllers/dashboard_controller.dart';

import 'package:business_whatsapp/app/core/constants/app_assets.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildSubscriptionInfo(context),
            const SizedBox(height: 12),
            _buildCustomNotificationsSection(context),

            const SizedBox(height: 32),
            _buildStatsGrid(context),
            const SizedBox(height: 32),
            _buildChartsSection(context),
            const SizedBox(height: 32),
            _buildRecentBroadcastsSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 32, // Increased size
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8), // Increased spacing
                  Text(
                    'Here\'s a summary of your messaging activity.',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18, // Increased size
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              Obx(
                () => Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedTimeRange.value,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      onChanged: (String? newValue) async {
                        if (newValue != null) {
                          if (newValue == 'Custom Date Range') {
                            await _showDateRangePicker(context);
                          } else {
                            controller.updateTimeRange(newValue);
                          }
                        }
                      },
                      items:
                          <String>[
                            'Today',
                            'This Month',
                            'Last Month',
                            'Last 6 Months',
                            'Custom Date Range',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: SubscriptionGuard.canEdit()
                      ? () => controller.createCampaign()
                      : null,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create New Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedTimeRange.value,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            if (newValue == 'Custom Date Range') {
                              await _showDateRangePicker(context);
                            } else {
                              controller.updateTimeRange(newValue);
                            }
                          }
                        },
                        items:
                            <String>[
                              'Today',
                              'This Month',
                              'Last Month',
                              'Last 6 Months',
                              'Custom Date Range',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: SubscriptionGuard.canEdit()
                      ? () => controller.createCampaign()
                      : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontSize: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubscriptionInfo(BuildContext context) {
    return Obx(() {
      final subService = SubscriptionService.instance;
      final sub = subService.subscription.value;

      if (sub == null || !subService.shouldShowRenewalWarning()) {
        return const SizedBox.shrink();
      }

      final expiryDate = sub.expiryDate;
      final textColor = const Color(0xFF854D0E);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCE8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCF1A6), width: 1.5),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              AppAssets.dangerTriangleAltSvg,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your subscription plan is set to expire on ${DateFormat('dd MMM, yyyy').format(expiryDate)}. Please ensure timely renewal to avoid service interruption.',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCustomNotificationsSection(BuildContext context) {
    return Obx(() {
      if (controller.customNotifications.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: controller.customNotifications.map((notification) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildCustomNotificationItem(context, notification),
          );
        }).toList(),
      );
    });
  }

  Widget _buildCustomNotificationItem(
    BuildContext context,
    notification, // Using dynamic type or imported type if available in view
  ) {
    Color bgColor;
    Color strokeColor;
    Color textColor;
    Widget iconWidget;

    switch (notification.type.toLowerCase()) {
      case 'important':
        bgColor = const Color(0xFFFFFBEB);
        strokeColor = const Color(0xFFF0DC93);
        textColor = const Color(0xFFD97604);
        iconWidget = SvgPicture.asset(
          AppAssets.dangerTriangleSvg,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        );
        break;
      case 'critical':
        bgColor = const Color(0xFFFFF1F0);
        strokeColor = const Color(0xFFFFBBB7);
        textColor = const Color(0xFFDC3545);
        iconWidget = SvgPicture.asset(
          AppAssets.dangerSvg,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        );
        break;
      case 'info':
      default:
        bgColor = const Color(0xFFEFF6FF);
        strokeColor = const Color(0xFFB8D7FF);
        textColor = const Color(0xFF287DE8);
        iconWidget = SvgPicture.asset(
          AppAssets.infoCircleSvg,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        );
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: strokeColor, width: 1.5),
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Expiry info
          GestureDetector(
            onTap: () {
              controller.hideNotification(notification.id!);
            },
            child: Icon(Icons.close, color: textColor, size: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF137FEC),
              onPrimary: Colors.white,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Update controller with custom date range
      controller.updateCustomDateRange(picked.start, picked.end);
    }
  }

  // Update the _buildStatsGrid method in your DashboardView

  Widget _buildStatsGrid(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // Determine grid layout based on screen size - keep web design unchanged
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    final width = MediaQuery.of(context).size.width;

    if (isMobile) {
      // Mobile: Single column for better readability
      crossAxisCount = 1;
      childAspectRatio = 1.2; // Taller cards for mobile (was 1.4)
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (isTablet) {
      // Tablet: 2 columns
      crossAxisCount = 2;
      childAspectRatio = 1.35; // Taller (was 1.5)
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else if (width < 1500) {
      // Small Desktop / Laptop: 3 columns (2 rows)
      crossAxisCount = 3;
      childAspectRatio = 1.45; // Taller (was 1.6)
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else {
      // Large Desktop: Keep original 6-column layout
      crossAxisCount = 6;
      childAspectRatio = 0.75; // Taller (was 0.85)
      crossAxisSpacing = 12;
      mainAxisSpacing = 16;
    }

    return Obx(() {
      // Get dynamic data from controller (always available)
      final freeMessages = controller.freeMessagesData;
      final paidMessages = controller.paidMessagesData;
      final totalCharges = controller.totalChargesData;

      final statsData = [
        {
          'title': 'All Messages',
          'value': controller.allMessagesData['total'].toString(),
          'icon': 'assets/dashboard_icons/all_messages.svg',
          'bgColor': const Color(0xFFDFEDFF),
          'items':
              (controller.allMessagesData['breakdown'] as List<dynamic>?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              <Map<String, dynamic>>[],
        },

        {
          'title': 'Free Messages',
          'value': freeMessages['total'].toString(),
          'icon': 'assets/dashboard_icons/free_messages.svg',
          'bgColor': const Color(0xFFFFE2FF),
          'items': (freeMessages['breakdown'] as List).map((item) {
            return {'label': item['label'], 'value': item['value'].toString()};
          }).toList(),
        },
        {
          'title': 'Paid Messages',
          'value': paidMessages['total'].toString(),
          'icon': 'assets/dashboard_icons/paid_messages.svg',
          'bgColor': const Color(0xFFF6EBFF),
          'items': (paidMessages['breakdown'] as List).map((item) {
            return {'label': item['label'], 'value': item['value'].toString()};
          }).toList(),
        },
        {
          'title': 'Total Charges',
          'value': '${totalCharges['currency']} ${totalCharges['total']}',
          'icon': 'assets/dashboard_icons/rupee_waves.svg',
          'bgColor': const Color(0xFFFFF8E5),
          'items': (totalCharges['breakdown'] as List).map((item) {
            return {'label': item['label'], 'value': '₹ ${item['value']}'};
          }).toList(),
        },
        {
          'title': 'Active Broadcast',
          'value': controller.activeBroadcastsCount.value.toString(),
          'icon': 'assets/dashboard_icons/active_broadcasts.svg',
          'bgColor': const Color(0xFFFFE5E5),
          'items': [
            {
              'label': 'Pending',
              'value': controller.pendingBroadcastsCount.toString(),
            },
            {
              'label': 'Sending',
              'value': controller.sendingBroadcastsCount.toString(),
            },
            {
              'label': 'Scheduled',
              'value': controller.scheduledBroadcastsCount.toString(),
            },
            {
              'label': 'Total',
              'value': controller.activeBroadcastsCount.toString(),
            },
          ],
        },
        {
          'title': 'Wallet Balance',
          'value':
              '${totalCharges['currency']} ${controller.walletBalance.value.toStringAsFixed(2)}',
          'icon': 'assets/dashboard_icons/wallet_money.svg',
          'bgColor': const Color(0xFFDFFEFB),
          'items': [
            {
              'label': 'Last Recharge Amt',
              'value':
                  '${totalCharges['currency']} ${controller.lastRechargeAmt.value}',
            },
            {
              'label': 'Last Recharge Date',
              'value': controller.lastRechargeDate.value,
            },
          ],
        },
      ];

      // Show loading state
      if (controller.isLoadingAnalytics.value) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: statsData.length,
          itemBuilder: (context, index) {
            return const _ShimmerStatCard();
          },
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: statsData.length,
        itemBuilder: (context, index) {
          return _StatCard(
            title: statsData[index]['title'] as String,
            value: statsData[index]['value'] as String,
            icon: statsData[index]['icon'] as String,
            bgColor: statsData[index]['bgColor'] as Color,
            items: statsData[index]['items'] as List<Map<String, dynamic>>,
            isMobile: isMobile,
          );
        },
      );
    });
  }

  Widget _buildChartsSection(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            height: 320, // Increased height for mobile
            child: _MessagePerformanceChart(isMobile: true),
          ),
          const SizedBox(height: 24), // Increased spacing
          SizedBox(
            height: 320, // Increased height for mobile
            child: _DailyMessageLimitChart(isMobile: true),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isTablet ? 1 : 2, child: _MessagePerformanceChart()),
        SizedBox(width: isMobile ? 20 : 32),
        Expanded(flex: 1, child: _DailyMessageLimitChart()),
      ],
    );
  }

  Widget _buildRecentBroadcastsSection(bool isDark) {
    return Obx(() {
      if (controller.recentBroadcasts.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Get.theme.dividerColor),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: Get.theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent broadcasts',
                  style: TextStyle(
                    fontSize: 16,
                    color: Get.theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first broadcast to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Get.theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return RecentBroadcastsTable(
        broadcasts: controller.recentBroadcasts,
        onActionTap: (item) {},
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color bgColor;
  final List<Map<String, dynamic>> items;
  final bool isMobile;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.items,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: isMobile
                    ? MediaQuery.of(context).size.height * 0.03
                    : 45,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(child: _buildIconWidget(icon)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isMobile
              ? Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
          const SizedBox(height: 8),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            thickness: 1,
          ),
          const SizedBox(height: 8),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getItemColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['label']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((item['value']?.toString() ?? '').isNotEmpty)
                      Text(
                        item['value']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemColor(int index) {
    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  Widget _buildIconWidget(String iconPath) {
    return SvgPicture.asset(iconPath, width: 25, height: 25);
  }
}

class _MessagePerformanceChart extends GetView<DashboardController> {
  final bool isMobile;

  const _MessagePerformanceChart({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final chartData = controller.performanceChartData.map((data) {
        return _PerformanceData(
          data['date'] as String,
          (data['sent'] as num).toDouble(),
          (data['delivered'] as num).toDouble(),
        );
      }).toList();

      return Container(
        height: isMobile ? 320 : 400,
        padding: EdgeInsets.only(
          left: isMobile ? 12 : 16,
          right: isMobile ? 12 : 16,
          top: isMobile ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
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
                    'Message Performance Analysis',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (!isMobile)
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildLegend('Sent', const Color(0xFF8B5CF6), isDark),
                      _buildLegend(
                        'Delivered',
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                    ],
                  ),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend('Sent', const Color(0xFF8B5CF6), isDark),
                  const SizedBox(width: 16),
                  _buildLegend('Delivered', const Color(0xFFF59E0B), isDark),
                ],
              ),
            ],
            SizedBox(height: isMobile ? 16 : 24),
            SizedBox(
              height: isMobile ? 200 : 300,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                  labelStyle: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),
                primaryYAxis: NumericAxis(
                  minimum: controller.chartMinimum - 2,
                  maximum:
                      controller.chartMaximum +
                      2, // Dynamic maximum (rounded up)
                  majorGridLines: MajorGridLines(
                    width: 1,
                    dashArray: [5, 5],
                    color: isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.3)
                        : Colors.grey[300]!.withValues(alpha: 0.5),
                  ),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                  labelStyle: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: isMobile ? 10 : 12,
                  ),
                  numberFormat: NumberFormat('#,##0'),
                  interval: controller.chartInterval,
                  axisLabelFormatter: (AxisLabelRenderDetails args) {
                    if (args.value < 0) {
                      return ChartAxisLabel('', args.textStyle);
                    }
                    return ChartAxisLabel(args.text, args.textStyle);
                  },
                ),
                series: <CartesianSeries<_PerformanceData, String>>[
                  SplineSeries<_PerformanceData, String>(
                    name: 'Sent',
                    dataSource: chartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.sent,
                    color: const Color(0xFF8B5CF6),
                    width: 2,
                  ),
                  SplineSeries<_PerformanceData, String>(
                    name: 'Delivered',
                    dataSource: chartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.delivered,
                    color: const Color(0xFFF59E0B),
                    width: 2,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : point.y',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLegend(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _PerformanceData {
  final String date;
  final double sent;
  final double delivered;

  _PerformanceData(this.date, this.sent, this.delivered);
}

class _DailyMessageLimitChart extends GetView<DashboardController> {
  final bool isMobile;

  const _DailyMessageLimitChart({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final List<_PieData> chartData = [
        _PieData(
          'Used',
          controller.usedQuota.value.toDouble(),
          const Color(0xFF137FEC),
        ),
        _PieData(
          'Available',
          controller.availableQuota.value.toDouble(),
          const Color(0xFFE5E7EB),
        ),
      ];

      return Container(
        height: isMobile ? 300 : 400,
        padding: EdgeInsets.only(
          top: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
          bottom: isMobile ? 16 : 24,
          left: isMobile ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Message Limit',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              // Mobile layout: Chart and legend stacked
              Center(
                child: SizedBox(
                  height: 160, // Reduced height for better fit
                  width: 160, // Fixed width to prevent overflow
                  child: SfCircularChart(
                    series: <CircularSeries>[
                      PieSeries<_PieData, String>(
                        dataSource: chartData,
                        xValueMapper: (data, _) => data.category,
                        yValueMapper: (data, _) => data.value,
                        pointColorMapper: (data, _) => data.color,
                        radius: '100%', // Reduced from 100% to prevent overflow
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: false,
                        ),
                        animationDuration: 1000,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    'Used',
                    '(${controller.usedQuota.value})',
                    AppColors.primary,
                    isDark,
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    'Available',
                    '(${controller.availableQuota.value})',
                    AppColors.gray300,
                    isDark,
                  ),
                ],
              ),
            ] else ...[
              // Desktop/Tablet layout: Chart and legend side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: SfCircularChart(
                        series: <CircularSeries>[
                          PieSeries<_PieData, String>(
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.category,
                            yValueMapper: (data, _) => data.value,
                            pointColorMapper: (data, _) => data.color,
                            radius: '100%',
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: false,
                            ),
                            animationDuration: 1000,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          'Used Messages',
                          '(${controller.usedQuota.value})',
                          const Color(0xFF137FEC),
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                          'Available Messages',
                          '(${controller.availableQuota.value})',
                          const Color(0xFFE5E7EB),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (isMobile) ...[
              // Mobile: Total messages in column
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total Messages',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                    Text(
                      '${controller.totalQuota.value} Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Desktop: Total messages in row
              Container(
                margin: const EdgeInsets.only(top: 65),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Messages : ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                    Text(
                      ' ${controller.totalQuota.value} Messages',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildLegendItem(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label $value',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _PieData {
  final String category;
  final double value;
  final Color color;

  _PieData(this.category, this.value, this.color);
}

class _ShimmerStatCard extends StatelessWidget {
  const _ShimmerStatCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF242424) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF4B5563) : Colors.grey[100]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 16,
                    color: Colors.white,
                    margin: const EdgeInsets.only(right: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: 120, height: 40, color: Colors.white),
            const SizedBox(height: 8),
            Divider(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Column(
                children: List.generate(
                  2,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 14,
                            color: Colors.white,
                            margin: const EdgeInsets.only(right: 40),
                          ),
                        ),
                        Container(width: 40, height: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
