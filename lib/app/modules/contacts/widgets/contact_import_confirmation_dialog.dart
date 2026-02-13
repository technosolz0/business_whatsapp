import 'package:adminpanel/app/common%20widgets/custom_button.dart';
import 'package:adminpanel/app/Utilities/responsive.dart';
import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImportConfirmationDialog {
  static void show({
    required List<List<dynamic>> csvData,
    bool requireNames = false,
    required Function(List<List<dynamic>>) processImport,
  }) async {
    // Normalize headers: remove spaces + punctuation, lowercase everything
    String normalize(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final rawHeaders = csvData[0];
    final headers = rawHeaders.map((e) => normalize(e.toString())).toList();
    final rows = csvData.sublist(1);

    int valid = 0;
    int duplicateInsideFile = 0;
    int invalidNames = 0;
    int invalidPhoneOrCode = 0;
    int invalidCountryCode = 0;

    // Identify correct index
    final firstNameIndex = headers.indexOf("firstname");
    final lastNameIndex = headers.indexOf("lastname");
    final phoneIndex = headers.indexOf("phonenumber");

    // Improve ISO code index detection (avoiding overlap with calling code)
    int isoCodeIndex = headers.indexOf("countrycode");
    if (isoCodeIndex == -1) isoCodeIndex = headers.indexOf("isocode");

    // Improve Calling Code index detection
    int callingCodeIndex = -1;
    if (headers.contains("callingcode")) {
      callingCodeIndex = headers.indexOf("callingcode");
    } else if (headers.contains("countrycallingcode")) {
      callingCodeIndex = headers.indexOf("countrycallingcode");
    } else if (headers.contains("dialcode")) {
      callingCodeIndex = headers.indexOf("dialcode");
    }

    // If we only have "countrycode" and no separate calling code column,
    // we might have to use countrycode for both or hope it's the dial code.
    if (callingCodeIndex == -1 && isoCodeIndex != -1) {
      callingCodeIndex = isoCodeIndex;
    }

    if (phoneIndex == -1 || callingCodeIndex == -1 || isoCodeIndex == -1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.overlayContext != null) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            "CSV must contain Phone Number, Calling Code & Country Code columns",
          );
        }
      });
      return;
    }

    final map = <String, int>{}; // key = countrycode-phonenumber

    // Check duplicates inside file and validate data
    for (final row in rows) {
      final fName = firstNameIndex != -1 && row.length > firstNameIndex
          ? row[firstNameIndex].toString().trim()
          : "";
      final lName = lastNameIndex != -1 && row.length > lastNameIndex
          ? row[lastNameIndex].toString().trim()
          : "";
      final phone = phoneIndex != -1 && row.length > phoneIndex
          ? row[phoneIndex].toString().trim()
          : "";
      var callingCode = callingCodeIndex != -1 && row.length > callingCodeIndex
          ? row[callingCodeIndex].toString().trim()
          : "";
      final iso = isoCodeIndex != -1 && row.length > isoCodeIndex
          ? row[isoCodeIndex].toString().trim()
          : "";

      // Validate required names (conditional)
      if (requireNames && (fName.isEmpty || lName.isEmpty)) {
        invalidNames++;
        continue;
      }

      // Validate phone and calling code existence
      if (phone.isEmpty || callingCode.isEmpty) {
        invalidPhoneOrCode++;
        continue;
      }

      // Validate ISO Country Code (e.g., 'IN', 'US')
      if (iso.isEmpty || iso.length != 2) {
        invalidCountryCode++;
        continue;
      }

      // Ensure country code has + prefix for comparison
      if (!callingCode.startsWith('+')) {
        callingCode = '+$callingCode';
      }

      // Skip non-numeric dial codes (like '+IN' if indices overlapped incorrectly)
      if (!RegExp(r'^\+[0-9]+$').hasMatch(callingCode)) {
        invalidPhoneOrCode++;
        continue;
      }

      // Validate Phone number format (numeric only)
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        invalidPhoneOrCode++;
        continue;
      }

      valid++;

      final key = "$callingCode-$phone";
      map[key] = (map[key] ?? 0) + 1;
    }

    // Count total duplicate rows inside file
    duplicateInsideFile = map.values
        .where((count) => count > 1)
        .map((count) => count - 1)
        .fold(0, (sum, dups) => sum + dups);

    // Check in Firestore (only check unique numbers)
    // for (final key in map.keys) {
    //   final parts = key.split("-");
    //   final cc = parts.first;
    //   final phone = parts.last;

    //   if (await checkNumberExists(cc, phone)) {
    //     duplicateInDB++;
    //   }
    // }

    final willImport = valid - duplicateInsideFile;
    print("willImport: $willImport");

    // Show modern popup
    Get.dialog(
      Builder(
        builder: (context) {
          final isMobile = Responsive.isMobile(context);
          final isTablet = Responsive.isTablet(context);

          // Responsive sizing
          final dialogWidth = isMobile
              ? MediaQuery.of(context).size.width * 0.9
              : (isTablet ? 500.0 : 480.0);
          final padding = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
          final titleSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
          final subtitleSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
          final iconSize = isMobile ? 24.0 : (isTablet ? 26.0 : 28.0);
          final bannerValueSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
          final bannerIconSize = isMobile ? 28.0 : (isTablet ? 30.0 : 32.0);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.blue.shade50.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.upload_file_rounded,
                            color: Colors.blue.shade700,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Import Numbers",
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Review your import summary",
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 20 : 28),

                    // Stats Cards
                    _buildStatCard(
                      context: context,
                      icon: Icons.description_outlined,
                      label: "Total Rows",
                      value: rows.length.toString(),
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),

                    _buildStatCard(
                      context: context,
                      icon: Icons.check_circle_outline,
                      label: "Valid Numbers",
                      value: valid.toString(),
                      color: Colors.green,
                    ),
                    SizedBox(height: 12),

                    _buildStatCard(
                      context: context,
                      icon: Icons.content_copy_outlined,
                      label: "Duplicates contacts in File",
                      value: duplicateInsideFile.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    if (requireNames) ...[
                      _buildStatCard(
                        context: context,
                        icon: Icons.person_off_outlined,
                        label: "Missing Names",
                        value: invalidNames.toString(),
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildStatCard(
                      context: context,
                      icon: Icons.phone_disabled_outlined,
                      label: "Invalid Numbers",
                      value: invalidPhoneOrCode.toString(),
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),

                    _buildStatCard(
                      context: context,
                      icon: Icons.public_off_outlined,
                      label: "Invalid Country Codes",
                      value: invalidCountryCode.toString(),
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),

                    // _buildStatCard(
                    //   context: context,
                    //   icon: Icons.location_off_outlined,
                    //   label: "Non +91 Contacts",
                    //   value: invalidCou.toString(),
                    //   color: Colors.red,
                    // ),
                    SizedBox(height: 12),

                    SizedBox(height: isMobile ? 20 : 24),

                    // Summary Banner
                    Container(
                      padding: EdgeInsets.all(isMobile ? 14 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade500],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_circle_down_rounded,
                            color: Colors.white,
                            size: bannerIconSize,
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Will Import",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: subtitleSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "$willImport numbers",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: bannerValueSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 16 : 20),

                    // Info note
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.amber.shade800,
                            size: isMobile ? 18 : 20,
                          ),
                          SizedBox(width: isMobile ? 10 : 12),
                          Expanded(
                            child: Text(
                              ((requireNames && invalidNames > 0) ||
                                      invalidPhoneOrCode > 0 ||
                                      invalidCountryCode > 0)
                                  ? "Invalid or incomplete rows will be skipped automatically."
                                  : "Duplicate numbers will be skipped automatically.",
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: subtitleSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 20 : 28),

                    // Action Buttons using CustomButton
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomButton(
                                label: "Import Now",
                                icon: Icons.download_rounded,
                                type: ButtonType.primary,
                                isFullWidth: true,
                                isDisabled: willImport == 0,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  processImport(csvData);
                                },
                              ),
                              SizedBox(height: 10),
                              CustomButton(
                                label: "Cancel",
                                type: ButtonType.secondary,
                                isFullWidth: true,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CustomButton(
                                label: "Cancel",
                                type: ButtonType.secondary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 24,
                                  vertical: 12,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              SizedBox(width: 12),
                              CustomButton(
                                label: "Import Now",
                                icon: Icons.download_rounded,
                                type: ButtonType.primary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 28 : 32,
                                  vertical: 12,
                                ),
                                isDisabled: willImport == 0,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  processImport(csvData);
                                },
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    final cardPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final iconPadding = isMobile ? 6.0 : 8.0;
    final iconSize = isMobile ? 18.0 : 20.0;
    final labelSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final valueSize = isMobile ? 18.0 : (isTablet ? 19.0 : 20.0);

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color.shade700, size: iconSize),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
