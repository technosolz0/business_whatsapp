import 'dart:convert';
import 'package:adminpanel/app/modules/contacts/widgets/contact_import_confirmation_dialog.dart';
import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:get/get.dart';

class CsvImportService {
  /// Pick and parse CSV file
  static Future<List<List<dynamic>>?> pickAndParseCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.first.bytes == null) {
        return null;
      }

      final fileBytes = result.files.first.bytes!;
      String csv;
      try {
        csv = utf8.decode(fileBytes);
      } catch (e) {
        try {
          csv = latin1.decode(fileBytes);
        } catch (e) {
          csv = utf8.decode(fileBytes, allowMalformed: true);
        }
      }
      final csvData = const CsvToListConverter().convert(csv);

      if (csvData.isEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.overlayContext != null) {
            Utilities.showSnackbar(SnackType.ERROR, "CSV is empty");
          }
        });
        return null;
      }

      return csvData;
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.overlayContext != null) {
          Utilities.showSnackbar(SnackType.ERROR, "Failed to read CSV: $e");
        }
      });
      return null;
    }
  }

  /// Import contacts from CSV with callbacks
  static Future<void> importContactsFromCsv({
    bool requireNames = false,
    Function(bool isLoading)? onLoadingChanged,
    Function(int imported, int skipped)? onComplete,
    Future<void> Function(List<ContactImportData> contacts)? onContactsParsed,
  }) async {
    // Step 1: Pick and parse CSV
    final csvData = await pickAndParseCsv();
    if (csvData == null) return;

    // Step 2: Show confirmation dialog
    ImportConfirmationDialog.show(
      csvData: csvData,
      requireNames: requireNames,
      processImport: (data) => _processImport(
        csvData: data,
        requireNames: requireNames,
        onLoadingChanged: onLoadingChanged,
        onComplete: onComplete,
        onContactsParsed: onContactsParsed,
      ),
    );
  }

  /// Parse date from string in various formats
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();

    // Try common date formats
    final formats = [
      // ISO format: 2024-12-16
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$'),
      // US format: 12/16/2024 or 12-16-2024
      RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$'),
      // European format: 16/12/2024 or 16-12-2024
      RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$'),
    ];

    try {
      // Try ISO format first (YYYY-MM-DD)
      if (formats[0].hasMatch(trimmed)) {
        return DateTime.parse(trimmed);
      }

      // Try MM/DD/YYYY or MM-DD-YYYY
      final match1 = formats[1].firstMatch(trimmed);
      if (match1 != null) {
        final month = int.parse(match1.group(1)!);
        final day = int.parse(match1.group(2)!);
        final year = int.parse(match1.group(3)!);

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // Try DD/MM/YYYY or DD-MM-YYYY
      final match2 = formats[2].firstMatch(trimmed);
      if (match2 != null) {
        final day = int.parse(match2.group(1)!);
        final month = int.parse(match2.group(2)!);
        final year = int.parse(match2.group(3)!);

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // If no format matched, try DateTime.parse as last resort
      return DateTime.parse(trimmed);
    } catch (e) {
      //print('Failed to parse date: $dateStr - Error: $e');
      return null;
    }
  }

  /// Process the CSV import
  static Future<void> _processImport({
    required List<List<dynamic>> csvData,
    bool requireNames = false,
    Function(bool isLoading)? onLoadingChanged,
    Function(int imported, int skipped)? onComplete,
    Future<void> Function(List<ContactImportData> contacts)? onContactsParsed,
  }) async {
    try {
      onLoadingChanged?.call(true);

      // Normalize headers
      final originalHeaders = csvData[0]
          .map((e) => e.toString().trim())
          .toList();
      final headers = csvData[0]
          .map(
            (e) => e.toString().trim().toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]'),
              '',
            ),
          )
          .toList();

      final rows = csvData.sublist(1);

      // Find header indexes
      final firstNameIndex = headers.indexOf('firstname');
      final lastNameIndex = headers.indexOf('lastname');
      final phoneIndex = headers.indexOf('phonenumber');
      final countryCodeIndex = headers.indexOf('countrycode');
      final emailIndex = headers.indexOf('email');
      final companyIndex = headers.indexOf('company');
      final tagsIndex = headers.indexOf('tags');
      final notesIndex = headers.indexOf('notes');

      // ISO Country Code and Calling Code
      final isoCountryCodeIndex = headers.indexOf('countrycode');
      final callingCodeIndex = headers.contains('callingcode')
          ? headers.indexOf('callingcode')
          : headers.indexOf('dialcode');

      // New date field indexes
      final birthdateIndex = headers.indexOf('birthdate');
      final anniversaryIndex = headers.indexOf('anniversary');
      final workAnniversaryIndex = headers.indexOf('workanniversary');

      // Validate mandatory columns
      if (phoneIndex == -1) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.overlayContext != null) {
            Utilities.showSnackbar(
              SnackType.ERROR,
              'CSV must contain Phone Number column',
            );
          }
        });
        return;
      }

      int imported = 0;
      int skipped = 0;

      // Track duplicates to avoid re-checking
      final Set<String> processedNumbers = {};
      final List<ContactImportData> parsedContacts = [];

      for (final row in rows) {
        try {
          // Skip empty rows
          if (row.length <= phoneIndex ||
              row[phoneIndex].toString().trim().isEmpty) {
            skipped++;
            continue;
          }

          final firstNameRaw =
              (firstNameIndex != -1 && firstNameIndex < row.length)
              ? row[firstNameIndex].toString().trim()
              : '';
          final lastNameRaw =
              (lastNameIndex != -1 && lastNameIndex < row.length)
              ? row[lastNameIndex].toString().trim()
              : '';

          // Skip if names are missing (optional based on requireNames flag)
          if (requireNames && (firstNameRaw.isEmpty || lastNameRaw.isEmpty)) {
            skipped++;
            continue;
          }

          final firstName = firstNameRaw.isNotEmpty ? firstNameRaw : null;
          final lastName = lastNameRaw.isNotEmpty ? lastNameRaw : null;
          final phone = row[phoneIndex].toString().trim();

          // Calling code with fallback to existing countryCode column if callingCode missing
          String countryCallingCode = '';
          if (callingCodeIndex != -1 && callingCodeIndex < row.length) {
            final dc = row[callingCodeIndex].toString().trim();
            if (dc.isNotEmpty) {
              countryCallingCode = dc.startsWith('+') ? dc : '+$dc';
            }
          } else if (countryCodeIndex != -1 && countryCodeIndex < row.length) {
            // Fallback for older CSV format where dial code might be in countryCode column
            final cc = row[countryCodeIndex].toString().trim();
            if (cc.isNotEmpty) {
              countryCallingCode = cc.startsWith('+') ? cc : '+$cc';
            }
          }

          // ISO Country Code
          String? isoCountryCode;
          if (isoCountryCodeIndex != -1 && isoCountryCodeIndex < row.length) {
            final icc = row[isoCountryCodeIndex]
                .toString()
                .trim()
                .toUpperCase();
            if (icc.isNotEmpty) {
              isoCountryCode = icc;
            }
          }

          // Skip if ISO Country Code is invalid (length must be 2)
          if (isoCountryCode == null || isoCountryCode.length != 2) {
            skipped++;
            continue;
          }

          // Skip if Calling Code or Phone is missing
          if (countryCallingCode.isEmpty || phone.isEmpty) {
            skipped++;
            continue;
          }

          // Validate Calling Code format (starts with +, numeric)
          if (!RegExp(r'^\+[0-9]+$').hasMatch(countryCallingCode)) {
            skipped++;
            continue;
          }

          // Validate Phone number format (numeric only)
          if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
            skipped++;
            continue;
          }

          // Check for duplicate in this batch
          final key = '$countryCallingCode-$phone';
          if (processedNumbers.contains(key)) {
            skipped++;
            continue;
          }
          processedNumbers.add(key);

          // Optional email
          String? email;
          if (emailIndex != -1 && emailIndex < row.length) {
            final emailValue = row[emailIndex].toString().trim();
            if (emailValue.isNotEmpty) {
              email = emailValue;
            }
          }

          // Optional company
          String? company;
          if (companyIndex != -1 && companyIndex < row.length) {
            final companyValue = row[companyIndex].toString().trim();
            if (companyValue.isNotEmpty) {
              company = companyValue;
            }
          }

          // Optional tags
          List<String> tags = [];
          if (tagsIndex != -1 && tagsIndex < row.length) {
            final raw = row[tagsIndex].toString().trim();
            if (raw.isNotEmpty) {
              final separator = raw.contains(';') ? ';' : ',';
              tags = raw
                  .split(separator)
                  .map((e) => e.trim().toLowerCase())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          }

          // Optional notes
          String? notes;
          if (notesIndex != -1 && notesIndex < row.length) {
            final notesValue = row[notesIndex].toString().trim();
            if (notesValue.isNotEmpty) {
              notes = notesValue;
            }
          }

          // Parse date fields
          DateTime? birthdate;
          if (birthdateIndex != -1 && birthdateIndex < row.length) {
            birthdate = _parseDate(row[birthdateIndex].toString());
          }

          DateTime? anniversaryDt;
          if (anniversaryIndex != -1 && anniversaryIndex < row.length) {
            anniversaryDt = _parseDate(row[anniversaryIndex].toString());
          }

          DateTime? workAnniversaryDt;
          if (workAnniversaryIndex != -1 && workAnniversaryIndex < row.length) {
            workAnniversaryDt = _parseDate(
              row[workAnniversaryIndex].toString(),
            );
          }

          // Custom Attributes extraction
          final Map<String, dynamic> customAttributes = {};
          final knownIndexes = {
            phoneIndex,
            countryCodeIndex,
            callingCodeIndex,
            isoCountryCodeIndex,
          };

          for (int i = 0; i < row.length; i++) {
            if (knownIndexes.contains(i)) continue;
            // Only process if header exists for this column
            if (i < headers.length) {
              final key = originalHeaders[i];
              final value = row[i]?.toString().trim() ?? '';
              if (value.isNotEmpty) {
                customAttributes[key] = value;
              }
            }
          }

          // Create contact data
          final contactData = ContactImportData(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phone,
            countryCallingCode: countryCallingCode,
            isoCountryCode: isoCountryCode,
            email: email,
            company: company,
            tags: tags,
            notes: notes,
            birthdate: birthdate,
            anniversaryDt: anniversaryDt,
            workAnniversaryDt: workAnniversaryDt,
            customAttributes: customAttributes,
          );

          // Add to parsed list
          parsedContacts.add(contactData);

          imported++;
        } catch (e) {
          //print('Error importing row: $e');
          skipped++;
        }
      }

      // Callback with parsed contacts
      if (onContactsParsed != null) {
        await onContactsParsed(parsedContacts);
      }

      // Show success message
      // Small delay to ensure overlay is available after dialog close
      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.overlayContext != null) {
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          'Import Successful',

          // 'Imported: $imported • Skipped: $skipped',
        );
      }

      onComplete?.call(imported, skipped);
    } catch (e) {
      // Small delay to ensure overlay is available
      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.overlayContext != null) {
        Utilities.showSnackbar(SnackType.ERROR, 'CSV import failed: $e');
      }
    } finally {
      onLoadingChanged?.call(false);
    }
  }
}

/// Contact data transfer object for imports
class ContactImportData {
  final String? firstName;
  final String? lastName;
  final String phoneNumber;
  final String countryCallingCode;
  final String? isoCountryCode;
  final String? email;
  final String? company;
  final List<String> tags;
  final String? notes;
  final DateTime? birthdate;
  final DateTime? anniversaryDt;
  final DateTime? workAnniversaryDt;
  final Map<String, dynamic> customAttributes;

  ContactImportData({
    this.firstName,
    this.lastName,
    required this.phoneNumber,
    required this.countryCallingCode,
    this.isoCountryCode,
    this.email,
    this.company,
    required this.tags,
    this.notes,
    this.birthdate,
    this.anniversaryDt,
    this.workAnniversaryDt,
    this.customAttributes = const {},
  });

  /// Convert to your ContactModel
  Map<String, dynamic> toContactModel() {
    return {
      'fName': firstName,
      'lName': lastName,
      'phoneNumber': phoneNumber,
      'countryCallingCode': countryCallingCode,
      'country_code': isoCountryCode,
      'email': email,
      'company': company,
      'tags': tags,
      'notes': notes,
      'status': null,
      'birthdate': birthdate,
      'anniversaryDt': anniversaryDt,
      'workAnniversaryDt': workAnniversaryDt,
      'customAttributes': customAttributes,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
}
