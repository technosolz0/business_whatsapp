import 'package:business_whatsapp/app/data/services/subscription_service.dart';
import 'package:business_whatsapp/app/utilities/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';
import '../controllers/settings_controller.dart';
import '../../../Utilities/subscription_guard.dart';
import '../../../controllers/theme_controller.dart';
import '../../../data/services/contact_service.dart';
import 'package:intl/intl.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isPremiumEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.instance.isPremiumEnabled();
    if (mounted) {
      setState(() {
        _isPremiumEnabled = isPremium;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.waChatBgDark
        : AppColors.waChatBgLight;
    final textPrimary = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;
    final textSecondary = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            // Header
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your preferences & account settings",
              style: TextStyle(fontSize: 15, color: textSecondary),
            ),
            const SizedBox(height: 28),
            // Subscription Card
            Obx(() {
              final sub = controller.subscription.value;
              if (sub == null) return const SizedBox.shrink();

              final daysRemaining = sub.expiryDate
                  .difference(DateTime.now())
                  .inDays;

              return _SettingsCard(
                title: "Subscription",
                badge: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sub.isActive
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub.status.capitalizeFirst!,
                    style: TextStyle(
                      color: sub.isActive ? Colors.blue : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                isDark: isDark,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "End Date",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(sub.expiryDate),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Days Remaining",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "$daysRemaining ",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: "days",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // // Appearance Card

            // Broadcast stats
            _SettingsCard(
              title: "Broadcast",
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => _StatTile(
                      label: "Daily message quota",
                      value:
                          "${controller.usedQuota.value}/${AppConstants.dailyLimit}",
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _StatTile(
                      label: "Active Broadcasts",
                      value:
                          "${controller.activeBroadcastCount.value}/${AppConstants.activeBroadcastLimit}",
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Appearance Card - Only show if premium is enabled
            if (_isPremiumEnabled) ...[
              _SettingsCard(
                title: "Appearance",
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Theme",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Choose your preferred theme",
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ThemeToggle(isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Chat Bot Card
            // if (_isPremiumEnabled) ...[
            //   _SettingsCard(
            //     title: "Chat Bot",
            //     isDark: isDark,
            //     child: Column(
            //       children: [
            //         _LinkTile(
            //           label: "Activate Bot",
            //           subtext:
            //               "Enable automated responses for incoming messages",
            //           isDark: isDark,
            //           trailing: Switch(
            //             value: false,
            //             onChanged: (v) {},
            //             activeThumbColor: Colors.blue,
            //           ),
            //         ),
            //         const Divider(height: 32),
            //         _LinkTile(
            //           label: "Questions",
            //           subtext: "Configure questions, answers and logic flow",
            //           isDark: isDark,
            //           onTap: () {},
            //         ),
            //       ],
            //     ),
            //   ),

            //   const SizedBox(height: 16),
            // ],

            // Account Card
            _SettingsCard(
              title: "Account",
              isDark: isDark,
              child: Obx(() {
                final canEdit = SubscriptionGuard.canEdit();
                return _LinkTile(
                  label: "Business Profile",
                  subtext: "Manage your business WhatsApp profile",
                  isDark: isDark,
                  onTap: canEdit
                      ? () {
                          Get.toNamed(Routes.BUSINESS_PROFILE);
                          final navController =
                              Get.find<NavigationController>();
                          navController.currentRoute.value =
                              Routes.BUSINESS_PROFILE;
                          navController.updateRoute();
                        }
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!canEdit)
                        const Icon(Icons.lock, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------
//        CARD WRAPPER
// -------------------------------------
class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  final Widget? badge;

  const _SettingsCard({
    required this.title,
    required this.child,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark
        ? AppColors.waDividerDark
        : AppColors.waDividerLight;
    final titleColor = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              if (badge != null) badge!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// -------------------------------------
//         STAT TILE
// -------------------------------------
class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  const _ThemeToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final toggleBg = isDark ? AppColors.waHeaderDark : AppColors.gray100;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: toggleBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            icon: Icons.wb_sunny_rounded,
            label: "Light",
            isSelected: !isDark,
            isDark: isDark,
            onTap: () => Get.find<ThemeController>().setTheme(false),
          ),
          _ToggleOption(
            icon: Icons.nightlight_round,
            label: "Dark",
            isSelected: isDark,
            isDark: isDark,
            onTap: () => Get.find<ThemeController>().setTheme(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? AppColors.waChatBgDark : Colors.white;
    final activeText = AppColors.primary;
    final inactiveText = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? activeText : inactiveText),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : inactiveText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  final String subtext;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _LinkTile({
    required this.label,
    required this.subtext,
    required this.isDark,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;
    final textSecondary = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? AppColors.gray400 : AppColors.gray600,
              ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
