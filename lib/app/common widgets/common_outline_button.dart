import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';

class CommonOutlineButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The label text to display.
  final String? label;

  /// Optional widget content (overrides label/icon).
  final Widget? child;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Optional border/text color. Defaults to Theme primary color.
  final Color? color;

  /// Optional background color. Defaults to transparent or Theme background.
  final Color? backgroundColor;

  /// Optional fixed width for the button.
  final double? width;

  /// Optional fixed height. Defaults to 48.
  final double? height;

  /// Optional padding. Defaults to symmetric(horizontal: 24, vertical: 12).
  final EdgeInsetsGeometry? padding;

  /// Optional border radius. Defaults to 8.
  final double borderRadius;

  /// Optional border width. Defaults to 1.5.
  final double borderWidth;

  /// Optional flag to show a loading indicator.
  final bool isLoading;

  /// Optional text style to override default.
  final TextStyle? textStyle;

  const CommonOutlineButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.color,
    this.backgroundColor,
    this.width,
    this.height = 48,
    this.padding,
    this.borderRadius = 8,
    this.borderWidth = 1.5,
    this.isLoading = false,
    this.textStyle,
  }) : assert(
         label != null || child != null,
         'Label or child must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.primaryColor;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: backgroundColor ?? Colors.transparent,
          side: BorderSide(
            color: isLoading ? primaryColor.withOpacity(0.5) : primaryColor,
            width: borderWidth,
          ),
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
                                color: primaryColor,
                              ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
