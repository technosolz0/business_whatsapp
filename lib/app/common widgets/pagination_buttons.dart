import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  const PaginationButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled
            ? (isDark ? AppColors.cardDark : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: enabled
            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
            : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
      ),
    );
  }
}
