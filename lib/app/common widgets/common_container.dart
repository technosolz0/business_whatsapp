// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class CommonContainer extends StatelessWidget {
  Widget child;
  final Color? bgColor; // ✅ Added custom background support

  CommonContainer({
    super.key,
    required this.child,
    this.bgColor, // ✅ Optional override
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background =
        bgColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final Color shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 24, bottom: 24),

      decoration: BoxDecoration(
        color: background, // 🎉 DARK MODE AUTO COLOR
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 0.8,
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),

      child: child,
    );
  }
}
