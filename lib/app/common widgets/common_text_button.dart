import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

class CommonTextButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The label text to display.
  final String label;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Optional text/icon color. Defaults to Theme primary color.
  final Color? color;

  /// Whether to underline the text. Defaults to true.
  final bool isUnderlined;

  /// Optional text style to override default.
  final TextStyle? textStyle;

  /// Optional padding. Defaults to standard TextButton padding.
  final EdgeInsetsGeometry? padding;

  /// Optional flag to show a loading indicator.
  final bool isLoading;

  const CommonTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.color,
    this.isUnderlined = true,
    this.textStyle,
    this.padding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.primaryColor;

    TextStyle finalTextStyle =
        textStyle ??
        GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: primaryColor,
        );

    if (isUnderlined) {
      finalTextStyle = finalTextStyle.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: primaryColor,
      );
    }

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: padding,
        textStyle: finalTextStyle,
      ),
      child: isLoading
          ? SizedBox(height: 20, width: 20, child: CircleShimmer(size: 20))
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: primaryColor),
                  const SizedBox(width: 8),
                ],
                Text(label, style: finalTextStyle),
              ],
            ),
    );
  }
}
