import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CommonPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int visiblePageCount;
  final String? showingText; // e.g., "Showing 1 to 10 of 50 results"

  const CommonPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.visiblePageCount = 5,
    this.showingText,
  });

  @override
  Widget build(BuildContext context) {
    // If no pages to show, but we might still want to show the "Showing X of Y" text if provided?
    // Usually if totalPages <= 1 we might hide pagination buttons but maybe keep text.
    // However, existing logic was to return SizedBox.shrink() if <= 1.
    // Let's stick to showing at least the text if provided, or hide all if truly empty/single page?
    // But typically if we have a list, we might want to see "Showing 5 of 5 results" even if 1 page.
    // For now, let's keep it simple: if totalPages <= 1 and no text, hide.

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Showing text
          if (showingText != null)
            Text(
              showingText!,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          else
            const SizedBox.shrink(),

          // Pagination Buttons
          if (totalPages > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous Page (<)
                _PaginationButton(
                  icon: Icons.chevron_left,
                  enabled: currentPage > 1,
                  onTap: () => onPageChanged(currentPage - 1),
                ),
                const SizedBox(width: 10),

                // Next Page (>)
                _PaginationButton(
                  icon: Icons.chevron_right,
                  enabled: currentPage < totalPages,
                  onTap: () => onPageChanged(currentPage + 1),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled
                ? (isDark ? AppColors.cardDark : Colors.white)
                : Colors.transparent,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
