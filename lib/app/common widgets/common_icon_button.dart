import 'package:flutter/material.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

class CommonIconButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The icon to display.
  final IconData icon;

  /// Optional icon color. Defaults to Theme primary color.
  final Color? color;

  /// Optional background color. Defaults to transparent.
  final Color? backgroundColor;

  /// Optional icon size. Defaults to 24.
  final double iconSize;

  /// Optional padding. Defaults to 8.
  final EdgeInsetsGeometry? padding;

  /// Optional tooltip text.
  final String? tooltip;

  /// Optional border radius (if using backgroundColor). Defaults to 8.
  final double borderRadius;

  /// Optional flag to show a loading indicator.
  final bool isLoading;

  const CommonIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.iconSize = 24,
    this.padding,
    this.tooltip,
    this.borderRadius = 8,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.iconTheme.color ?? theme.primaryColor;

    if (isLoading) {
      return Center(child: CircleShimmer(size: iconSize));
    }

    Widget button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: iconColor,
      iconSize: iconSize,
      padding: padding,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: backgroundColor != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              )
            : null,
      ),
    );

    if (backgroundColor != null) {
      // If background color is set, ensure it has some shape/padding consistency
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: button,
      );
    }

    return button;
  }
}
