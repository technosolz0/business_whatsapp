import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';

class TemplateFormFieldLabel extends StatelessWidget {
  final String label;
  final String? helpText;
  final bool isOptional;

  const TemplateFormFieldLabel({
    super.key,
    required this.label,
    this.helpText,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF242424),
              ),
              children: isOptional
                  ? [
                      TextSpan(
                        text: ' (Optional)',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
          if (helpText != null) ...[
            const SizedBox(height: 6),
            Text(
              helpText!,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      );
    });
  }
}
