import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final Function(String) onSearchChanged;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final TextEditingController controller;
  const SearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by broadcast name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppColors.gray800 : AppColors.gray100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items:
                  [
                        'All',
                        'Draft',
                        'Pending',
                        'Scheduled',
                        'Sending',
                        'Sent',
                        'Failed',
                      ]
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) onFilterChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
