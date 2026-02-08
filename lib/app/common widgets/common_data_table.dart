import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../utilities/responsive.dart';
import 'custom_chip.dart';

class CommonDataTable extends StatefulWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final List<Widget Function(dynamic data, int rowIndex)> cellBuilders;
  final Function(int rowIndex, String action)? onActionTap;
  final List<String>? actionButtons; // e.g., ['copy', 'delete']
  final bool showPagination;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final String? listInfo;
  final double? tableHeight;
  final VoidCallback? onScrollEnd;
  final ScrollController? verticalScrollController;
  final double? minWidth;

  const CommonDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cellBuilders,
    this.onActionTap,
    this.actionButtons,
    this.showPagination = true,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.onNextPage,
    this.onPreviousPage,
    this.listInfo,
    this.tableHeight,
    this.onScrollEnd,
    this.verticalScrollController,
    this.minWidth,
  });

  @override
  State<CommonDataTable> createState() => _CommonDataTableState();
}

class _CommonDataTableState extends State<CommonDataTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  late final ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController =
        widget.verticalScrollController ?? ScrollController();
    _verticalScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_verticalScrollController.position.pixels >=
            _verticalScrollController.position.maxScrollExtent &&
        widget.onScrollEnd != null) {
      widget.onScrollEnd!();
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    if (widget.verticalScrollController == null) {
      _verticalScrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Column(
      children: [
        // Conditional scrollbar
        Expanded(
          child: isMobile
              ? _buildMobileView(isDark)
              : isTablet
              ? _buildTabletView(isDark)
              : _buildDesktopView(isDark),
        ),

        // Pagination
        if (widget.showPagination) _buildPaginationControls(isDark),
      ],
    );
  }

  Widget _buildMobileView(bool isDark) {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: _buildTableContent(isDark, true),
      ),
    );
  }

  Widget _buildTabletView(bool isDark) {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: _buildTableContent(isDark, false),
      ),
    );
  }

  Widget _buildDesktopView(bool isDark) {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: _buildTableContent(isDark, false),
      ),
    );
  }

  Widget _buildTableContent(bool isDark, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use minWidth as exact width if provided, otherwise perform responsive calculation
    final tableWidth =
        widget.minWidth ?? (screenWidth < 1000.0 ? 1000.0 : screenWidth - 48);

    return Container(
      width: tableWidth,
      height: widget.tableHeight,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Header (Fixed at top)
          _buildHeader(isDark, isMobile),
          // Rows (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: Column(
                children: widget.rows
                    .asMap()
                    .entries
                    .map(
                      (entry) =>
                          _buildRow(entry.value, entry.key, isDark, isMobile),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray900 : AppColors.gray50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: widget.columns.asMap().entries.map((entry) {
          final isLastColumn = entry.key == widget.columns.length - 1;
          final flex = isLastColumn && widget.actionButtons != null
              ? (isMobile ? 2 : 3)
              : (isMobile ? 4 : 3);

          return Expanded(
            flex: flex,
            child: Text(
              entry.value.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.gray300 : AppColors.gray600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(
    List<dynamic> rowData,
    int rowIndex,
    bool isDark,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 10 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: List.generate(widget.columns.length, (colIndex) {
          final isLastColumn = colIndex == widget.columns.length - 1;
          final flex = isLastColumn && widget.actionButtons != null
              ? (isMobile ? 2 : 3)
              : (isMobile ? 4 : 3);

          return Expanded(
            flex: flex,
            child: colIndex < widget.cellBuilders.length
                ? widget.cellBuilders[colIndex](rowData[colIndex], rowIndex)
                : _buildDefaultCell(rowData[colIndex], isDark),
          );
        }),
      ),
    );
  }

  Widget _buildDefaultCell(dynamic data, bool isDark) {
    return Text(
      data?.toString() ?? '',
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white70 : AppColors.gray800,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    if (!widget.showPagination) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Previous button
          InkWell(
            onTap: widget.hasPreviousPage ? widget.onPreviousPage : null,
            child: PaginationButton(
              icon: Icons.chevron_left,
              enabled: widget.hasPreviousPage,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          // Next button
          InkWell(
            onTap: widget.hasNextPage ? widget.onNextPage : null,
            child: PaginationButton(
              icon: Icons.chevron_right,
              enabled: widget.hasNextPage,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

// Pagination Button Widget
class PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;

  const PaginationButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: Container(
        decoration: BoxDecoration(
          color: enabled
              ? (isDark ? AppColors.cardDark : Colors.white)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? (isDark ? AppColors.borderDark : Colors.grey[300]!)
                : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 30,
          color: enabled
              ? (isDark ? Colors.white : Colors.black)
              : Colors.grey.shade500,
        ),
      ),
    );
  }
}

// Helper function to get chip style for status
ChipStyle getChipStyleForStatus(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
    case 'ACTIVE':
    case 'SUCCESS':
    case 'SENT':
      return ChipStyle.success;
    case 'PENDING':
    case 'SCHEDULED':
      return ChipStyle.warning;
    case 'REJECTED':
    case 'FAILED':
    case 'ERROR':
      return ChipStyle.error;
    default:
      return ChipStyle.secondary;
  }
}
