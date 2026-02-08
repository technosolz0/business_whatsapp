import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_white_bg_button.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/common%20widgets/custom_table_contents.dart';

import 'package:business_whatsapp/app/common%20widgets/common_pagination.dart';
import 'package:business_whatsapp/app/utilities/webutils.dart';

class CustomTable extends StatelessWidget {
  CustomTable({
    super.key,
    this.onFieldSubmitted,
    required this.showTableContents,
    required this.columns,
    required this.rows,
    required this.childrens,
    this.currentPage,
    this.recordsPerPage,
    required this.searchByOptions,
    this.searchController,
    required this.onClickedPrevPage,
    required this.onClickedNextPage,
    required this.listInfo,
    this.onClickedExport,
    this.isFirstPage = false,
    this.isLastPage = false,
    this.onClickedSearch,
    this.onClickedAdd,
    this.onClickedReset,
    this.searchButton,
    this.resetButton,
    this.addButtonLabel,
    this.selectedSearchBy,
    this.onSearchByUpdate,
    this.exportable,
    this.tableFooterTextStyle,
    this.tableRowColor,
    this.tableRowMouseCursor,
    this.border,
    this.columnSpacing,
    this.dataRowMaxHeight,
    this.dataRowMinHeight,
    this.dataTextStyle,
    this.decoration,
    this.dividerThickness,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.showPaginationButtons = true,
    this.showBottomBorder = false,
    this.showAddButton = true,
    this.fromApiExport = true,
    this.pageSize,
    this.availablePageSizes,
    this.onPageSizeChanged,
    required this.showLoading,
    this.onClickedFilter,
    this.showFilter = false,
    this.isStatusTable = false,
    this.isDashBoardTable = false,
    this.isDashboardFooterTable = false,
    this.totalPages,
    this.onPageChanged,

    /// Header icons
    this.headerIcons,
    this.onHeaderIconTap,
  }) : assert(columns.isNotEmpty),
       assert(childrens.isNotEmpty),
       assert(() {
         for (List<dynamic> row in rows) {
           if (row.length != columns.length) return false;
         }
         return true;
       }()),
       assert(columns.length == childrens.length),
       assert(headerIcons == null || headerIcons.length == columns.length),
       assert(
         onHeaderIconTap == null || onHeaderIconTap.length == columns.length,
       ),
       assert(exportable == null || exportable.length == columns.length);

  final int? pageSize;
  RxBool showLoading;
  final List<int>? availablePageSizes;
  final Function(int newSize)? onPageSizeChanged;
  bool isStatusTable;
  bool isDashBoardTable;
  bool isDashboardFooterTable;

  final List<String> columns;
  final List<List<dynamic>> rows;
  final List<Widget Function(dynamic child, int index)> childrens;
  final bool showTableContents;
  final int? currentPage;
  final int? recordsPerPage;
  final String? listInfo;
  bool? showPaginationButtons;
  final TextEditingController? searchController;
  final Function(String value)? onSearchByUpdate;
  String? selectedSearchBy;
  final int? totalPages;
  final ValueChanged<int>? onPageChanged;
  final List<String> searchByOptions;
  final Function()? onClickedSearch;
  final Function()? onClickedReset;
  final Function()? onClickedAdd;
  final Function() onClickedPrevPage;
  final Function() onClickedNextPage;
  bool showFilter;
  Widget? searchButton;
  Widget? resetButton;
  String? addButtonLabel;
  List<bool>? exportable;
  TextStyle? tableFooterTextStyle;
  bool? showAddButton;
  bool isFirstPage;
  bool isLastPage;
  final TableBorder? border;
  final double? columnSpacing;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final TextStyle? dataTextStyle;
  final Decoration? decoration;
  final double? dividerThickness;
  final double? headingRowHeight;
  final TextStyle? headingTextStyle;
  final double? horizontalMargin;
  final bool showBottomBorder;
  WidgetStateProperty<Color?>? Function(int rowIndex)? tableRowColor;
  WidgetStateProperty<MouseCursor?>? Function(int rowIndex)?
  tableRowMouseCursor;
  final Function(String)? onFieldSubmitted;
  bool fromApiExport;
  final Function()? onClickedExport;
  final Function()? onClickedFilter;
  ScrollController tableScrollController = ScrollController();

  /// Header icons
  final List<Widget?>? headerIcons;
  final List<VoidCallback?>? onHeaderIconTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tableBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final rowTextColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    bool isPhone = context.width < WebUtils.phoneBreakpoint + 150;

    return Container(
      color: tableBgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top filters etc.
          CustomTableContents(
            showTableContents: showTableContents,
            searchController: searchController,
            addButtonLabel: addButtonLabel,
            onClickedExport: onClickedExport,
            onClickedSearch: onClickedSearch,
            listInfo: listInfo,
            onFieldSubmitted: onFieldSubmitted,
            onClickedAdd: onClickedAdd,
            exportable: exportable,
            showFilter: showFilter,
            onClickedFilter: onClickedFilter,
          ),

          if (showTableContents) const SizedBox(height: 20),

          // ------------------ TABLE BODY ------------------
          Obx(
            () => rows.isEmpty || showLoading.value
                ? Center(
                    child: Text(
                      "No data available",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        controller: tableScrollController,
                        thumbVisibility: false,
                        trackVisibility: false,
                        thickness: 10,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SingleChildScrollView(
                            controller: tableScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isStatusTable
                                    ? 1065
                                    : isDashBoardTable
                                    ? 850
                                    : isDashboardFooterTable
                                    ? 700
                                    : constraints.maxWidth,
                              ),
                              child: DataTable(
                                border:
                                    border ??
                                    TableBorder(
                                      horizontalInside: BorderSide(
                                        color: borderColor,
                                        width: 0.6,
                                      ),
                                      bottom: BorderSide(
                                        color: borderColor,
                                        width: 0.8,
                                      ),
                                    ),
                                columnSpacing: columnSpacing,
                                dataRowMaxHeight: dataRowMaxHeight,
                                dataRowMinHeight: dataRowMinHeight,
                                dataTextStyle:
                                    dataTextStyle ??
                                    TextStyle(
                                      fontSize: 14,
                                      color: rowTextColor,
                                    ),
                                decoration: decoration,
                                dividerThickness: dividerThickness ?? 0.5,
                                headingRowHeight: headingRowHeight,
                                headingTextStyle:
                                    headingTextStyle ??
                                    TextStyle(
                                      fontSize: 14,
                                      color: headerColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                horizontalMargin: horizontalMargin,
                                showBottomBorder: true,

                                /// HEADER
                                columns: List.generate(columns.length, (index) {
                                  final title = columns[index];
                                  final icon = headerIcons?[index];
                                  final onTap = onHeaderIconTap?[index];

                                  return DataColumn(
                                    headingRowAlignment:
                                        MainAxisAlignment.start,
                                    label: Row(
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.publicSans(
                                            fontSize: 14,
                                            color: headerColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (icon != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: InkWell(
                                              onTap: onTap,
                                              child: icon,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),

                                /// ROWS
                                rows: List.generate(rows.length, (rowIndex) {
                                  final row = rows[rowIndex];

                                  return DataRow(
                                    color: tableRowColor != null
                                        ? tableRowColor!(rowIndex)
                                        : WidgetStateProperty.all(
                                            isDark
                                                ? const Color(0xFF1F1F1F)
                                                : Colors.white,
                                          ),
                                    mouseCursor: tableRowMouseCursor != null
                                        ? tableRowMouseCursor!(rowIndex)
                                        : null,
                                    cells: List.generate(
                                      row.length,
                                      (cellIndex) => DataCell(
                                        childrens[cellIndex](
                                          row[cellIndex],
                                          rowIndex,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 30),

          // ------------------ PAGINATION ------------------
          if (showPaginationButtons == true)
            !isPhone
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        tableRecordPerPageDecider(isDark),
                        const Spacer(),
                        tablePaginationButtons(isDark),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tableRecordPerPageDecider(isDark),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [tablePaginationButtons(isDark)],
                        ),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }

  // ------------------ PAGE SIZE DROPDOWN ------------------
  Widget tableRecordPerPageDecider(bool isDark) {
    if (availablePageSizes == null || pageSize == null) return const SizedBox();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<int>(
        value: pageSize,
        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        items: availablePageSizes!
            .map(
              (size) => DropdownMenuItem(
                value: size,
                child: Text(
                  "$size / Page",
                  style: GoogleFonts.publicSans(
                    color: isDark ? Colors.white : AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null && onPageSizeChanged != null) {
            onPageSizeChanged!(value);
          }
        },
      ),
    );
  }

  // ------------------ PAGINATION BUTTONS ------------------
  Widget tablePaginationButtons(bool isDark) {
    // If totalPages and onPageChanged are provided, use CommonPagination
    if (totalPages != null && onPageChanged != null && currentPage != null) {
      return CommonPagination(
        currentPage: currentPage!,
        totalPages: totalPages!,
        onPageChanged: onPageChanged!,
      );
    }

    // Fallback to existing manual pagination
    final enabledText = isDark ? Colors.white : Colors.black;
    final disabledText = isDark ? Colors.grey[700] : const Color(0xFFD3D7E0);

    return Row(
      children: [
        Tooltip(
          message: "Previous",
          child: SizedBox(
            height: 40,
            width: 40,
            child: CommonWhiteBgButton(
              onPressed: isFirstPage ? null : onClickedPrevPage,
              borderColor: isFirstPage ? disabledText! : enabledText,
              padding: EdgeInsets.zero,
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_left,
                  size: 30,
                  color: isFirstPage ? disabledText : enabledText,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Current page
        SizedBox(
          height: 40,
          width: 40,
          child: CommonFilledButton(
            onPressed: () {},
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            label: currentPage.toString(),
            textStyle: GoogleFonts.publicSans(color: Colors.white),
          ),
        ),

        const SizedBox(width: 10),

        Tooltip(
          message: "Next",
          child: SizedBox(
            height: 40,
            width: 40,
            child: CommonWhiteBgButton(
              onPressed: isLastPage ? null : onClickedNextPage,
              borderColor: isLastPage ? disabledText! : enabledText,
              padding: EdgeInsets.zero,
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: 30,
                  color: isLastPage ? disabledText : enabledText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
