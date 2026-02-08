import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../Utilities/responsive.dart';

class BroadcastStepIndicator extends StatelessWidget {
  final int currentStep;
  final Function(int) getStepTitle;

  const BroadcastStepIndicator({
    super.key,
    required this.currentStep,
    required this.getStepTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Responsive(
            mobile: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF1E293B),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Step ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: '${currentStep + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(
                        text: ' of 3: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: getStepTitle(currentStep),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            tablet: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Step ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '${currentStep + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const TextSpan(
                          text: ' of 3: ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: getStepTitle(currentStep),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      Text(
                        '1. Select Audience',
                        style: TextStyle(
                          fontSize: 13,
                          color: currentStep == 0
                              ? AppColors.primary
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          fontWeight: currentStep == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '2. Content',
                        style: TextStyle(
                          fontSize: 13,
                          color: currentStep == 1
                              ? AppColors.primary
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          fontWeight: currentStep == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '3. Schedule & Send',
                        style: TextStyle(
                          fontSize: 13,
                          color: currentStep == 2
                              ? AppColors.primary
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          fontWeight: currentStep == 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            desktop: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF1E293B),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Step ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: '${currentStep + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(
                        text: ' of 3: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: getStepTitle(currentStep),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '1. Select Audience',
                      style: TextStyle(
                        fontSize: 14,
                        color: currentStep == 0
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        fontWeight: currentStep == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '2. Content',
                      style: TextStyle(
                        fontSize: 14,
                        color: currentStep == 1
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        fontWeight: currentStep == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '3. Schedule & Send',
                      style: TextStyle(
                        fontSize: 14,
                        color: currentStep == 2
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        fontWeight: currentStep == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 3,
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
