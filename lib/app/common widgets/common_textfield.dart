// ignore: must_be_immutable
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonTextfield extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool filled;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final EdgeInsetsGeometry? contentPadding;
  final double? labelFontSize;
  final double? hintFontSize;
  final Color? enabledBorderColor;
  final Color? focusedBorderColor;
  final Color? fillColor;
  final List<TextInputFormatter>? inputFormatter;
  final void Function()? onTap;
  final bool readOnly;
  final TextInputAction? textInputAction;

  // 🔥 Dark mode override colors (optional)
  final Color? labelColor;
  final Color? textColor;
  final Color? hintColor;

  const CommonTextfield({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.contentPadding,
    this.labelFontSize = 13,
    this.hintFontSize = 14,
    this.enabledBorderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = AppColors.primary,
    this.fillColor,
    this.filled = false,
    this.isRequired = false,
    this.inputFormatter,
    this.onTap,
    this.readOnly = false,
    this.textInputAction,

    // Dark Mode overrides
    this.labelColor,
    this.textColor,
    this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color effectiveLabelColor =
        labelColor ?? (isDark ? Colors.white : const Color(0xFF1A1A1A));

    final Color effectiveTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black);

    final Color effectiveHintColor =
        hintColor ?? (isDark ? Colors.grey[400]! : const Color(0xFFBDC3C7));

    final Color effectiveFillColor =
        fillColor ?? (isDark ? const Color(0xFF2A2A2A) : Colors.white);

    final Color effectiveEnabledBorder = isDark
        ? Colors.grey[700]!
        : enabledBorderColor!;

    final Color effectiveFocusedBorder = isDark
        ? Colors.blueAccent
        : focusedBorderColor!;

    OutlineInputBorder buildBorder(Color color) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: GoogleFonts.publicSans(
                  fontSize: labelFontSize,
                  color: effectiveLabelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isRequired) const SizedBox(width: 3),
              if (isRequired)
                const Text("*", style: TextStyle(color: Color(0xFFE74C3C))),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // ------------------- INPUT FIELD -------------------
        TextFormField(
          readOnly: readOnly,
          onTap: onTap,
          textInputAction: textInputAction,
          inputFormatters: inputFormatter,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: GoogleFonts.publicSans(
            color: effectiveTextColor,
            fontSize: 15,
          ),

          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            hintStyle: GoogleFonts.publicSans(
              color: effectiveHintColor,
              fontSize: hintFontSize,
            ),
            filled: true,
            fillColor: effectiveFillColor,

            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,

            enabledBorder: buildBorder(effectiveEnabledBorder),
            focusedBorder: buildBorder(effectiveFocusedBorder),
            disabledBorder: buildBorder(
              isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0),
            ),

            errorBorder: buildBorder(const Color.fromARGB(255, 255, 123, 123)),
            focusedErrorBorder: buildBorder(
              const Color.fromARGB(255, 255, 123, 123),
            ),

            errorStyle: GoogleFonts.publicSans(
              color: const Color.fromARGB(255, 255, 80, 80),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
