// ignore_for_file: must_be_immutable

import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/common_filled_button.dart';
import 'package:adminpanel/app/common%20widgets/common_textfield.dart';
import 'package:adminpanel/app/common%20widgets/common_white_bg_button.dart';
import 'package:adminpanel/app/utilities/webutils.dart';
import 'package:adminpanel/app/core/constants/app_assets.dart'; // Added this import

/// This File is to handle if we have to show the upper contents of table or not

class CustomTableContents extends StatelessWidget {
  // Important :- This handle if we have to show the content or not
  final bool showTableContents;

  final TextEditingController? searchController;

  final Function()? onClickedAdd;

  /// List of boolean to indicate which columns will be included in the export sheet.
  /// Must include index based bool to indicate which column should be exportable.
  List<bool>? exportable;

  /// To change the name of list in these
  final String? listInfo;

  /// void function to handle on clicked search button
  final Function()? onClickedSearch;

  // For searching just after enter is tapped in search textfield
  final Function(String)? onFieldSubmitted;

  /// void function to handle on clicked export button
  final Function()? onClickedExport;

  bool showFilter;

  final Function()? onClickedFilter;

  String? addButtonLabel;
  CustomTableContents({
    super.key,
    required this.showTableContents,
    required this.searchController,
    required this.addButtonLabel,
    required this.onClickedSearch,
    required this.listInfo,
    required this.onFieldSubmitted,
    required this.onClickedAdd,
    this.onClickedExport,
    required this.exportable,
    required this.showFilter,
    this.onClickedFilter,
  });

  @override
  Widget build(BuildContext context) {
    bool isPhone = context.width < WebUtils.tabletBreakpoint + 270;
    bool isSmallPhone = context.width < WebUtils.phoneBreakpoint + 80;
    return showTableContents == true
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isPhone)
                Row(
                  children: [
                    Text(
                      "$listInfo List",
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                    Spacer(),
                    SizedBox(
                      width: context.width * 0.2,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return CommonTextfield(
                            controller: searchController,
                            hintText: "Search",
                            suffixIcon: searchController!.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      searchController!.clear();
                                      setState(() {});
                                      if (onFieldSubmitted != null) {
                                        onFieldSubmitted!('');
                                      }
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      AppAssets.searchIcon,
                                      height: 18,
                                      width: 18,
                                    ),
                                  ),
                            onChanged: (value) {
                              setState(() {});
                              if (onFieldSubmitted != null) {
                                onFieldSubmitted!(value);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    if (showFilter) SizedBox(width: 20),
                    if (showFilter)
                      IconButton(
                        onPressed: () {
                          if (onClickedFilter != null) {
                            onClickedFilter!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(5),
                          ),
                          backgroundColor: Color(
                            0xFF1A2B9B,
                          ).withValues(alpha: 0.09),
                        ),
                        icon: Image.asset(
                          AppAssets.filterIcon,
                          height: 20,
                          width: 20,
                        ),
                      ),
                    SizedBox(width: 20),
                    SizedBox(
                      height: 44,
                      child: CommonWhiteBgButton(
                        onPressed: () {
                          if (onClickedExport != null) {
                            onClickedExport!();
                          }
                        },
                        borderColor: Color(0xFF27AE60),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/excel_icon.png',
                              height: 18,
                              width: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Export",
                              style: GoogleFonts.publicSans(
                                color: Color(0xFF27AE60),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      height: 44,
                      child: CommonFilledButton(
                        onPressed: () {
                          if (onClickedAdd != null) {
                            onClickedAdd!();
                          }
                        },
                        backgroundColor: AppColors.primary,
                        child: Row(
                          children: [
                            Text(
                              "Add $addButtonLabel",
                              style: GoogleFonts.publicSans(
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (isPhone)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$listInfo List",
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextfield(
                            controller: searchController,
                            hintText: "Search",
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/icons/search_icon.png',
                                height: 18,
                                width: 14,
                              ),
                            ),
                          ),
                        ),
                        if (showFilter) SizedBox(width: 8),
                        if (showFilter)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (onClickedFilter != null) {
                                  onClickedFilter!();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                backgroundColor: Color(
                                  0xFF1A2B9B,
                                ).withValues(alpha: 0.09),
                              ),
                              icon: Image.asset(
                                'assets/icons/filter_icon.png',
                                height: 20,
                                width: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    isSmallPhone
                        ? Column(
                            children: [
                              SizedBox(
                                height: 40,
                                child: CommonWhiteBgButton(
                                  onPressed: () {
                                    if (onClickedExport != null) {
                                      onClickedExport!();
                                    }
                                  },
                                  borderColor: Color(0xFF27AE60),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icons/excel_icon.png',
                                          height: 18,
                                          width: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Export",
                                          style: GoogleFonts.publicSans(
                                            color: Color(0xFF27AE60),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                height: 40,
                                child: CommonFilledButton(
                                  onPressed: () {
                                    if (onClickedAdd != null) {
                                      onClickedAdd!();
                                    }
                                  },
                                  backgroundColor: AppColors.primary,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Add $addButtonLabel",
                                          style: GoogleFonts.publicSans(
                                            color: Color(0xFFFFFFFF),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: CommonWhiteBgButton(
                                    onPressed: () {
                                      if (onClickedExport != null) {
                                        onClickedExport!();
                                      }
                                    },
                                    borderColor: Color(0xFF27AE60),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/icons/excel_icon.png',
                                            height: 18,
                                            width: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "Export",
                                            style: GoogleFonts.publicSans(
                                              color: Color(0xFF27AE60),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12), // Reduced spacing
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: CommonFilledButton(
                                    onPressed: () {
                                      if (onClickedAdd != null) {
                                        onClickedAdd!();
                                      }
                                    },
                                    backgroundColor: AppColors.primary,
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Add $addButtonLabel",
                                            style: GoogleFonts.publicSans(
                                              color: Color(0xFFFFFFFF),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
            ],
          )
        : const SizedBox.shrink();
  }
}
