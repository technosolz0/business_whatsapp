import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BroadcastProgressDialog extends StatelessWidget {
  final RxDouble progress; // 0.0 to 1.0

  const BroadcastProgressDialog({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Progress with percentage text in center
                Obx(() {
                  final percent = (progress.value * 100).clamp(0, 100).toInt();
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: progress.value.clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0F52BA),
                          ), // Beautiful blue color
                        ),
                      ),
                      Text(
                        "$percent%",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 28),
                // Title
                Text(
                  "Please wait while we prepare your messages.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFF9FAFB)
                        : const Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Subtitle
                Text(
                  "Please do not refresh or close this tab.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
