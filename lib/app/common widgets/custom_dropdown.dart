import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String? label; // ⬅ label is optional now
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool required;
  final String? hint;

  /// Optional: Action items (e.g. Add New)
  final Map<T?, VoidCallback>? actions;

  const CustomDropdown({
    super.key,
    required this.items,
    this.label,
    this.value,
    this.onChanged,
    this.required = false,
    this.hint,
    this.actions, // ⬅ map of special values → action callback
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ Label is now optional ⭐
        if (label != null)
          RichText(
            text: TextSpan(
              text: label!,

              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF1a1a1a),
              ),
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ]
                  : [],
            ),
          ),

        if (label != null) const SizedBox(height: 8),

        DropdownButtonFormField<T>(
          isExpanded: true,
          initialValue: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: item.child,
              // ⬅ Flutter won't call onTap automatically for MenuItems,
              // so action handling occurs in onChanged override below.
            );
          }).toList(),
          onChanged: (selectedValue) {
            // If this selected value has an action, run it
            if (actions != null && actions!.containsKey(selectedValue)) {
              actions![selectedValue]!();
              return;
            }

            // Normal selection
            if (onChanged != null) {
              onChanged!(selectedValue);
            }
          },
          dropdownColor: isDark ? AppColors.gray800 : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black, // Always black text
          ),
          hint: hint != null
              ? Text(
                  hint!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.gray400 : Colors.black,
                  ),
                )
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.gray800.withValues(alpha: 0.5)
                : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
