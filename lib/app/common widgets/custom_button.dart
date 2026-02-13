import 'package:flutter/material.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

enum ButtonType { primary, secondary, success, danger, warning }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final double? height;
  final double? width;
  final EdgeInsets? padding;
  final bool isLoading;
  final bool isFullWidth;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.height,
    this.width,
    this.padding,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final isButtonDisabled = isLoading || isDisabled || onPressed == null;

    Widget buttonChild = isLoading
        ? const CircleShimmer(size: 20)
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    return SizedBox(
      height: height ?? 44,
      width: isFullWidth ? double.infinity : width,
      child: ElevatedButton(
        onPressed: isButtonDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonDisabled
              ? Colors.grey.shade300
              : buttonStyle.backgroundColor,
          foregroundColor: isButtonDisabled
              ? Colors.grey.shade500
              : buttonStyle.foregroundColor,
          elevation: 0,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isButtonDisabled
                ? BorderSide(color: Colors.grey.shade300)
                : (buttonStyle.borderSide ?? BorderSide.none),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        child: buttonChild,
      ),
    );
  }

  _ButtonStyle _getButtonStyle() {
    switch (type) {
      case ButtonType.primary:
        return _ButtonStyle(
          backgroundColor: const Color(0xFF0066FF),
          foregroundColor: Colors.white,
        );
      case ButtonType.secondary:
        return _ButtonStyle(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1a1a1a),
          borderSide: BorderSide(color: Colors.grey[300]!),
        );
      case ButtonType.success:
        return _ButtonStyle(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        );
      case ButtonType.danger:
        return _ButtonStyle(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
        );
      case ButtonType.warning:
        return _ButtonStyle(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
        );
    }
  }
}

class _ButtonStyle {
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? borderSide;

  _ButtonStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderSide,
  });
}
