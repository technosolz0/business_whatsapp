import 'dart:convert';

import 'package:business_whatsapp/app/data/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:business_whatsapp/app/common%20widgets/common_alert_dialog_delete.dart';
import '../core/theme/app_colors.dart';
import '../controllers/navigation_controller.dart';
import '../utilities/constants/app_constants.dart';
import '../utilities/utilities.dart';
import '../utilities/webutils.dart';
import '../utilities/responsive.dart';
import '../modules/chats/controllers/chats_controller.dart';
import 'package:business_whatsapp/main.dart';

class SidebarWidget extends StatefulWidget {
  final VoidCallback? onItemTap;

  const SidebarWidget({super.key, this.onItemTap});

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Map<String, dynamic>>> _getAccessibleMenuItems(
    bool isSuperUserValue,
  ) async {
    final isPremium = await PremiumService.instance.isPremiumEnabled();

    List<Map<String, dynamic>> menuItems = [
      {
        'type': 'item',
        'icon': Icons.dashboard,
        'label': 'Dashboard',
        'index': 0,
        'route': '/dashboard',
      },
      {
        'type': 'group',
        'icon': Icons.admin_panel_settings,
        'label': 'Admin Master',
        'children': [
          {
            'icon': Icons.person,
            'label': 'Admins',
            'index': 1,
            'route': '/admins',
          },
          {
            'icon': Icons.group,
            'label': 'Roles',
            'index': 2,
            'route': '/roles',
          },
        ],
      },
      {
        'type': 'item',
        'icon': Icons.contacts,
        'label': 'Contacts',
        'index': 3,
        'route': '/contacts',
      },
      {
        'type': 'item',
        'icon': Icons.description,
        'label': 'Templates',
        'index': 4,
        'route': '/templates',
      },
    ];

    // Only add Milestone Schedulars if status is true (show when true, hide when false)
    if (isPremium) {
      menuItems.add({
        'type': 'item',
        'icon': Icons.celebration,
        'label': 'Milestone Schedulars',
        'index': 8,
        'route': '/milestone-schedulars',
      });
    }

    menuItems.addAll([
      {
        'type': 'item',
        'icon': Icons.campaign,
        'label': 'Broadcasts',
        'index': 5,
        'route': '/broadcasts',
      },
      {
        'type': 'item',
        'icon': Icons.chat,
        'label': 'Chats',
        'index': 6,
        'route': '/chats',
        'showUnreadCount': true,
      },
      {
        'type': 'item',
        'icon': Icons.settings,
        'label': 'Settings',
        'index': 7,
        'route': '/settings',
      },
    ]);

    if (isSuperUserValue) {
      menuItems.add({
        'type': 'item',
        'icon': Icons.group,
        'label': 'Clients',
        'index': 9,
        'route': '/clients',
      });
      menuItems.add({
        'type': 'item',
        'icon': Icons.notifications_active,
        'label': 'Custom Notifications',
        'index': 10,
        'route': '/custom-notifications',
      });
    }

    try {
      String? itemsInCookie = WebUtils.readCookie(
        AppConstants.menuItemsCookieKey,
      );
      if (itemsInCookie != null && itemsInCookie.isNotEmpty) {
        String decryptedData = WebUtils.decryptData(
          data: itemsInCookie,
          secretKey: AppConstants.menuItemsSecret,
        );

        Map<String, dynamic> cookieDecrypted = Map<String, dynamic>.from(
          jsonDecode(decryptedData),
        );

        List<Map<String, dynamic>> cookieData = List<Map<String, dynamic>>.from(
          cookieDecrypted["pages"],
        );

        // Filter menu items based on permissions
        List<Map<String, dynamic>> filteredItems = [];

        for (var item in menuItems) {
          if (item['type'] == 'group') {
            List<Map<String, dynamic>> filteredChildren = [];
            for (var child in item['children']) {
              Map<String, dynamic>? permission = cookieData.firstWhere(
                (c) => c['route'] == child['route'],
                orElse: () => {},
              );
              if (permission.isNotEmpty) {
                String accessStr = (permission['ax'] ?? '').toString();
                if (accessStr.isNotEmpty && accessStr[0] == '1') {
                  filteredChildren.add(child);
                }
              }
            }
            if (filteredChildren.isNotEmpty) {
              filteredItems.add({...item, 'children': filteredChildren});
            }
          } else {
            Map<String, dynamic>? permission = cookieData.firstWhere(
              (c) => c['route'] == item['route'],
              orElse: () => {},
            );

            // Always show Dashboard, Milestone Schedulars (if premium enabled), and Clients regardless of permissions
            if (item['route'] == '/dashboard' ||
                item['route'] == '/milestone-schedulars' ||
                item['route'] == '/clients') {
              filteredItems.add(item);
            } else if (permission.isNotEmpty) {
              String accessStr = (permission['ax'] ?? '').toString();
              if (accessStr.isNotEmpty && accessStr[0] == '1') {
                filteredItems.add(item);
              }
            }
          }
        }

        return filteredItems;
      }
    } catch (e) {
      // If error, show all items
    }

    return menuItems;
  }

  /// Helper method to check if a route is active
  /// Handles special cases like milestone schedulars where create route should also highlight the main tab
  bool _isRouteActive(String currentRoute, String itemRoute) {
    // Exact match
    if (currentRoute == itemRoute) {
      return true;
    }

    // Special case: milestone schedulars
    // Both /milestone-schedulars and /create-milestone-schedulars should highlight the milestone tab
    if (itemRoute == '/milestone-schedulars' &&
        currentRoute == '/create-milestone-schedulars') {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final NavigationController navController = Get.find<NavigationController>();

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.5)
            : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Obx(() {
            String displayLogo = clientLogo.value.isNotEmpty
                ? clientLogo.value
                : "assets/app_logo.png";
            String displayName = clientName.value.isNotEmpty
                ? clientName.value
                : 'Messaging Portal';
            bool isNetworkImage = clientLogo.value.isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                top: Responsive.isMobile(context) ? 80 : 16,
                right: 16,
                left: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 20,
                    backgroundImage: isNetworkImage
                        ? NetworkImage(displayLogo)
                        : AssetImage(displayLogo) as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Business Account',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(thickness: 0.08),
          // Navigation Items
          Expanded(
            child: Obx(
              () => FutureBuilder<List<Map<String, dynamic>>>(
                future: _getAccessibleMenuItems(isSuperUser.value),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SidebarShimmer();
                  }

                  final accessibleItems = snapshot.data ?? [];

                  // Nested Obx is redundant for the list view inside, but let's keep it clean
                  // Actually the outer Obx rebuilds the FutureBuilder, which fetches new items.
                  // The inner Obx (lines 275-327) was handling navController changes?
                  // Yes, navController.selectedIndex and currentRoute.
                  // So we keep the inner Obx or rely on this outer one?
                  // The outer Obx triggers when isSuperUser changes.
                  // The inner Obx triggers when navigation changes.
                  // So we need both?
                  // If outer rebuilds, inner is recreated. That is fine.
                  return Obx(() {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: accessibleItems.map((item) {
                        if (item['type'] == 'group') {
                          final children =
                              item['children'] as List<Map<String, dynamic>>;
                          return _NavGroup(
                            icon: item['icon'],
                            label: item['label'],
                            isExpanded: children.any(
                              (child) =>
                                  navController.selectedIndex.value ==
                                  child['index'],
                            ),
                            children: children
                                .map(
                                  (child) => _NavItem(
                                    icon: child['icon'],
                                    label: child['label'],
                                    isActive:
                                        navController.currentRoute.value ==
                                        child['route'],
                                    onTap: () async {
                                      // Close drawer first
                                      widget.onItemTap?.call();
                                      navController.currentRoute.value =
                                          child['route'];
                                      await Get.toNamed(child['route']);
                                    },
                                    isSubItem: true,
                                  ),
                                )
                                .toList(),
                          );
                        } else {
                          return _NavItem(
                            icon: item['icon'],
                            label: item['label'],
                            isActive: _isRouteActive(
                              navController.currentRoute.value,
                              item['route'],
                            ),
                            onTap: () async {
                              // Close drawer first
                              widget.onItemTap?.call();
                              navController.currentRoute.value = item['route'];
                              await Get.toNamed(item['route']);
                            },
                            showUnreadCount: item['showUnreadCount'] ?? false,
                          );
                        }
                      }).toList(),
                    );
                  });
                },
              ),
            ),
          ),

          // Bottom Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logout button directly (not in a group)
                _NavItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  isActive: false,
                  onTap: () {
                    Get.dialog(
                      CommonAlertDialogDelete(
                        title: 'Logout',
                        content: 'Are you sure you want to logout?',
                        confirmText: 'Logout',
                        onConfirm: () => Utilities.logout(),
                      ),
                    );
                  },
                  isSubItem: false,
                  isLogout: true,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final List<Widget> children;

  const _NavGroup({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Remove divider lines
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          leading: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.gray300 : AppColors.gray700,
          ),
          title: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.only(left: 24),
          children: children,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSubItem;
  final bool showUnreadCount;
  final bool isLogout;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isSubItem = false,
    this.showUnreadCount = false,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSubItem ? 16 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: isSubItem ? 18 : 20,
                  color: isLogout
                      ? Colors.red
                      : (isActive
                            ? Colors.white
                            : (isDark ? AppColors.gray300 : AppColors.gray700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isLogout
                          ? Colors.red
                          : (isActive
                                ? AppColors.textPrimaryDark
                                : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)),
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (showUnreadCount) ...[
                  const SizedBox(width: 8),
                  Obx(() {
                    final chatsController = Get.find<ChatsController>();
                    final unreadCount = chatsController.unreadChatsCount;
                    if (unreadCount > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
