import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

class CommonFilledButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  /// If null, the button will be disabled.
  final VoidCallback? onPressed;

  /// The label text to display.
  final String? label;

  /// Optional widget content (overrides label/icon).
  final Widget? child;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Optional background color. Defaults to Theme primary color.
  final Color? backgroundColor;

  /// Optional text/icon color. Defaults to White.
  final Color? foregroundColor;

  /// Optional fixed width for the button.
  final double? width;

  /// Optional fixed height. Defaults to 48.
  final double? height;

  /// Optional padding. Defaults to symmetric(horizontal: 24, vertical: 12).
  final EdgeInsetsGeometry? padding;

  /// Optional border radius. Defaults to 8.
  final double borderRadius;

  /// Optional flag to show a loading indicator.
  final bool isLoading;

  /// Optional text style to override default.
  final TextStyle? textStyle;

  const CommonFilledButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 48,
    this.padding,
    this.borderRadius = 8,
    this.isLoading = false,
    this.textStyle,
  }) : assert(
         label != null || child != null,
         'Label or child must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    final fgColor = foregroundColor ?? Colors.white;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
          disabledForegroundColor: fgColor.withValues(alpha: 0.7),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircleShimmer(size: 20)
            : child ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      if (label != null)
                        Text(
                          label!,
                          style:
                              textStyle ??
                              GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
