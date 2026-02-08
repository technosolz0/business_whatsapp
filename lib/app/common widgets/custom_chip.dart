import 'package:flutter/material.dart';

enum ChipStyle { success, error, warning, info, primary, secondary, custom }

class CustomChip extends StatelessWidget {
  final String label;
  final ChipStyle style;
  final Color? customBackgroundColor;
  final Color? customTextColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final double borderRadius;
  final IconData? icon;

  const CustomChip({
    super.key,
    required this.label,
    this.style = ChipStyle.primary,
    this.customBackgroundColor,
    this.customTextColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    this.borderRadius = 25,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Wrap(
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2, color: colors.textColor),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: colors.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _ChipColors _getColors() {
    if (style == ChipStyle.custom) {
      final baseColor = customTextColor ?? const Color(0xFF242424);
      return _ChipColors(
        backgroundColor:
            customBackgroundColor ?? baseColor.withValues(alpha: 0.1),
        textColor: baseColor,
      );
    }

    switch (style) {
      case ChipStyle.success:
        const textColor = Color(0xFF10B981);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
      case ChipStyle.error:
        const textColor = Color(0xFFEF4444);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
      case ChipStyle.warning:
        const textColor = Color(0xFFF59E0B);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
      case ChipStyle.info:
        const textColor = Color(0xFF3B82F6);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
      case ChipStyle.primary:
        const textColor = Color(0xFF0066FF);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
      case ChipStyle.secondary:
        const textColor = Color(0xFF6B7280);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
      default:
        const textColor = Color(0xFF242424);
        return _ChipColors(
          backgroundColor: textColor.withValues(alpha: 0.1),
          textColor: textColor,
        );
    }
  }
}

class _ChipColors {
  final Color backgroundColor;
  final Color textColor;

  _ChipColors({required this.backgroundColor, required this.textColor});
}
