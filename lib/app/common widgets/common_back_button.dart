import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';

class CommonBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const CommonBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = color ?? (isDark ? Colors.white : AppColors.gray700);

    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onPressed ?? () => Get.back(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Icon(
            Icons.arrow_back,
            color: buttonColor,
            size: size ?? 20,
          ),
        ),
      ),
    );
  }
}
