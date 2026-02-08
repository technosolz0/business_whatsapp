import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';

class CommonAlertDialogDelete extends StatelessWidget {
  final VoidCallback onConfirm;
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;

  const CommonAlertDialogDelete({
    super.key,
    required this.onConfirm,
    this.title = 'Delete Record',
    this.content =
        'Are you sure you want to delete this record? This action cannot be undone.',
    this.confirmText = 'Delete',
    this.cancelText = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      title: Text(
        title,
        style: TextStyle(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          fontSize: 14,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Get.back(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? AppColors.borderDark : Colors.grey[300]!,
              width: 1,
            ),
            foregroundColor: isDark ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Get.back(); // Close dialog after confirm
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
