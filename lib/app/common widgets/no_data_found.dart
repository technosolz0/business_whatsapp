import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class NoDataFound extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData icon; // optional

  const NoDataFound({
    super.key,
    required this.label,
    required this.isDark,
    this.icon = Icons.sms_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark ? AppColors.gray400 : AppColors.gray500,
          ),
          const SizedBox(height: 12),
          Text(
            label, // 🔥 dynamic text
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
