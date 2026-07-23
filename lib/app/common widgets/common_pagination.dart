import 'package:flutter/material.dart';
import '../Utilities/responsive.dart';
import '../core/theme/app_colors.dart';

class CommonPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int visiblePageCount;
  final String? showingText; // e.g., "Showing 1 to 10 of 50 results"
  final Widget? prefixWidget; // New: Optional widget for the left side

  final bool isPrevLoading;
  final bool isNextLoading;
  final bool showPageNumbers;

  const CommonPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.visiblePageCount = 5,
    this.showingText,
    this.prefixWidget,
    this.isPrevLoading = false,
    this.isNextLoading = false,
    this.showPageNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isMobile(context) ? 12 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
      ),
      child: Responsive.isMobile(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prefixWidget != null) ...[
                  prefixWidget!,
                  const SizedBox(height: 12),
                ],
                if (showingText != null) ...[
                  Text(
                    showingText!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (totalPages > 1) _buildPaginationButtons(currentPage, totalPages, isPrevLoading, isNextLoading, showPageNumbers, isDark),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Prefix Widget + Showing text
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefixWidget != null) ...[
                      prefixWidget!,
                      if (showingText != null) const SizedBox(width: 20),
                    ],
                    if (showingText != null)
                      Text(
                        showingText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),

                // Pagination Buttons
                if (totalPages > 1) _buildPaginationButtons(currentPage, totalPages, isPrevLoading, isNextLoading, showPageNumbers, isDark),
              ],
            ),
    );
  }

  List<Widget> _buildPageNumbers(bool isDark) {
    List<Widget> widgets = [];
    const int sidePages = 3; // Show 3 pages at start and 3 at end

    if (totalPages <= (sidePages * 2 + 1)) {
      // If total pages are small, show all of them
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i));
      }
    } else {
      // Otherwise, show first 3, ellipsis, (current if middle), ellipsis, last 3
      // 1. First 3 pages
      for (int i = 1; i <= sidePages; i++) {
        widgets.add(_buildPageButton(i));
      }

      // 2. Middle part
      bool isCurrentInFirst3 = currentPage <= sidePages;
      bool isCurrentInLast3 = currentPage > totalPages - sidePages;

      if (!isCurrentInFirst3 && !isCurrentInLast3) {
        // Current page is in the middle
        if (currentPage > sidePages + 1) {
          widgets.add(_buildEllipsis(isDark));
        }
        widgets.add(_buildPageButton(currentPage));
        if (currentPage < totalPages - sidePages) {
          widgets.add(_buildEllipsis(isDark));
        }
      } else {
        // Current is in first or last 3, just one ellipsis in middle
        widgets.add(_buildEllipsis(isDark));
      }

      // 3. Last 3 pages
      for (int i = totalPages - sidePages + 1; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i));
      }
    }

    // Add spacing between widgets
    List<Widget> spacedWidgets = [];
    for (int i = 0; i < widgets.length; i++) {
      spacedWidgets.add(widgets[i]);
      if (i < widgets.length - 1) {
        spacedWidgets.add(const SizedBox(width: 8));
      }
    }
    return spacedWidgets;
  }

  Widget _buildPageButton(int page) {
    return _PaginationButton(
      text: page.toString(),
      enabled: true,
      isSelected: currentPage == page,
      onTap: () => onPageChanged(page),
    );
  }

  Widget _buildEllipsis(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaginationButtons(int currentPage, int totalPages,
      bool isPrevLoading, bool isNextLoading, bool showPageNumbers, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous Page (<)
        _PaginationButton(
          icon: Icons.chevron_left,
          enabled: currentPage > 1 && !isPrevLoading,
          isLoading: isPrevLoading,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 12),

        // Page Numbers
        if (showPageNumbers) ..._buildPageNumbers(isDark),

        const SizedBox(width: 12),

        // Next Page (>)
        _PaginationButton(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages && !isNextLoading,
          isLoading: isNextLoading,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool enabled;
  final bool isLoading;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaginationButton({
    this.icon,
    this.text,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    Color color;
    if (isSelected) {
      color = Colors.white;
    } else if (enabled) {
      color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    } else {
      color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    }

    final bgColor = isSelected
        ? primaryColor
        : (enabled
            ? (isDark ? AppColors.cardDark : Colors.white)
            : Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (enabled && !isLoading && !isSelected) ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : icon != null
                  ? Icon(
                      icon,
                      size: 20,
                      color: color,
                    )
                  : Text(
                      text!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: color,
                      ),
                    ),
        ),
      ),
    );
  }
}
