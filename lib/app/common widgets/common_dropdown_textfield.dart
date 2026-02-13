import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonDropdownTextfield<T> extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final double? labelFontSize;
  final bool isRequired;
  final List<DropdownMenuItem<T>>? items;
  final void Function(T?)? onChanged;
  final double? hintFontSize;
  final bool? filled;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? enabledBorderColor;
  final Color? focusedBorderColor;
  final T? initialValue;
  final T? value;
  final String? hintText;
  final bool enabled;

  const CommonDropdownTextfield({
    super.key,
    this.controller,
    this.label,
    this.isRequired = false,
    this.labelFontSize,
    required this.items,
    required this.onChanged,
    this.hintFontSize,
    this.filled,
    this.fillColor,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.enabledBorderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = AppColors.primary,
    this.initialValue,
    this.value,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color effectiveLabelColor = isDark
        ? Colors.white
        : const Color(0xFF1A1A1A);

    final Color effectiveTextColor = isDark ? Colors.white : Colors.black;

    final Color effectiveHintColor = isDark
        ? Colors.grey[400]!
        : const Color(0xFFBDC3C7);

    final Color effectiveFillColor =
        fillColor ?? (isDark ? const Color(0xFF2A2A2A) : Colors.white);

    final Color effectiveEnabledBorder = isDark
        ? Colors.grey[700]!
        : enabledBorderColor!;

    final Color effectiveFocusedBorder = isDark
        ? Colors.blueAccent
        : focusedBorderColor!;

    final Color dropdownBgColor = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.white;

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

        // 🔽 Dropdown
        AbsorbPointer(
          absorbing: !enabled,
          child: DropdownButtonFormField<T>(
            menuMaxHeight: 400,
            initialValue: value ?? initialValue,
            dropdownColor: dropdownBgColor, // 🌙 Dark mode dropdown menu
            isExpanded: true,

            icon: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.keyboard_arrow_down),
            ),

            items: items?.map((item) {
              return DropdownMenuItem<T>(
                value: item.value,
                child: DefaultTextStyle(
                  style: GoogleFonts.publicSans(
                    color: effectiveTextColor,
                    fontSize: 15,
                  ),
                  child: item.child,
                ),
              );
            }).toList(),

            onChanged: onChanged,

            decoration: InputDecoration(
              hintText: hintText == null || hintText!.isEmpty
                  ? "Select One"
                  : hintText,
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

              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: effectiveEnabledBorder, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),

              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: effectiveFocusedBorder, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),

              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
