import 'package:adminpanel/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          constraints: const BoxConstraints(
            minHeight: 285, // Matches MessageTrendsCard total height
          ),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Action Items
              ActionTile(
                onTap: () {
                  Get.toNamed(Routes.CONTACTS);
                },
                icon: Icons.campaign_rounded,
                title: "New Broadcast",
              ),

              const SizedBox(height: 30),

              ActionTile(
                onTap: () {
                  Get.toNamed(Routes.TEMPLATES);
                },
                icon: Icons.mail_outline_rounded,
                title: "Manage Templates",
              ),

              const SizedBox(height: 30),

              ActionTile(
                onTap: () {
                  Get.toNamed(Routes.CONTACTS);
                },
                icon: Icons.upload_rounded,
                title: "Manage Contacts",
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reusable row widget
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Callback? onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Row(
      children: [
        /// Circle Icon Background
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),

        const SizedBox(width: 12),

        /// Label
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
