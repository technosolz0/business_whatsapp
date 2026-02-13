import 'package:adminpanel/app/common%20widgets/custom_button.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLogOutVerifyButton extends StatelessWidget {
  const CustomLogOutVerifyButton({super.key, required this.onTapYes});
  final VoidCallback onTapYes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Confirm Logout",
                style: GoogleFonts.plusJakartaSans(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                "Are you sure you want to log out? You will need to sign in again to access your account.",
                style: GoogleFonts.plusJakartaSans(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Cancel Button (Outline)
                  Expanded(
                    child: CustomButton(
                      label: "Cancel",
                      onPressed: () {
                        Get.back();
                      },
                      type: ButtonType.secondary,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm Button (Filled)
                  Expanded(
                    child: CustomButton(
                      label: "Logout",
                      onPressed: () {
                        Get.back();
                        onTapYes();
                      },
                      type: ButtonType.danger,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
