import 'dart:convert';
import 'dart:developer';

import 'package:business_whatsapp/app/Utilities/webutils.dart';
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:business_whatsapp/app/controllers/theme_controller.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:business_whatsapp/app/common%20widgets/webmenu.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/main.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';

import '../common widgets/common_snackbar.dart';

import 'package:business_whatsapp/app/modules/add_admins/controllers/add_admins_controller.dart';
import 'package:business_whatsapp/app/modules/add_client/controllers/add_client_controller.dart';
import 'package:business_whatsapp/app/modules/add_roles/controllers/add_roles_controller.dart';
import 'package:business_whatsapp/app/modules/admins/controllers/admins_controller.dart';
import 'package:business_whatsapp/app/modules/broadcasts/controllers/broadcasts_controller.dart';
import 'package:business_whatsapp/app/modules/broadcasts/controllers/create_broadcast_controller.dart';
import 'package:business_whatsapp/app/modules/business_profile/controllers/business_profile_controller.dart';
import 'package:business_whatsapp/app/modules/chats/controllers/chats_controller.dart';
import 'package:business_whatsapp/app/modules/clients/controllers/clients_controller.dart';
import 'package:business_whatsapp/app/modules/contacts/controllers/contacts_controller.dart';
import 'package:business_whatsapp/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:business_whatsapp/app/modules/login/controllers/login_controller.dart';
import 'package:business_whatsapp/app/modules/milestone_templates/controllers/milestone_schedulars_controller.dart';
import 'package:business_whatsapp/app/modules/roles/controllers/roles_controller.dart';
import 'package:business_whatsapp/app/modules/settings/controllers/settings_controller.dart';
import 'package:business_whatsapp/app/modules/templates/controllers/create_template_controller.dart';
import 'package:business_whatsapp/app/modules/templates/controllers/templates_controller.dart';

class Utilities {
  static void dPrint(dynamic data) {
    if (kDebugMode) {
      //print(data);
    }
  }

  /// To log on console only for debug mode
  static void dLog(var data) {
    if (kDebugMode) {
      log(data.toString());
    }
  }

  /// To log with json formatted
  static void dLogJSON(var data) {
    if (kDebugMode) {
      log(JsonEncoder.withIndent('  ').convert(data));
    }
  }

  /// To hide any Snackbar which is currently being displayed
  static void hideCurrentSnackbar() {
    ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
  }

  /// To show a Snackbar. Pass String `title` and String `message`
  static void showSnackbar(SnackType type, String message) {
    hideCurrentSnackbar();
    CustomSnackbar.show(
      context: Get.overlayContext!,
      message: message,
      type: type,
      alignment: SnackAlignment.TOP,
      rightAligned: true,
    );
  }

  /// To logout user
  static void logout() async {
    // 1. Reset Global Variables
    gJwtToken = '';
    adminName.value = '';
    adminID = '';
    clientID = '';
    isSuperUser.value = false;
    isAllChats.value = false;
    clientName.value = '';
    clientLogo.value = '';
    isCRMEnabled.value = false;

    // 2. Clear Local Storage & Cookies
    await GetStorage().erase();
    WebUtils.deleteCookies();
    menu.clear();

    // 3. Reset Theme
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());
    themeController.setTheme(false);

    // 4. Navigate primarily to remove views that depend on controllers
    Get.offAllNamed(Routes.LOGIN);

    // 5. Cleanup Controllers (After navigation to avoid "Controller not found")
    // Use a small delay to ensure views are disposed
    Future.delayed(const Duration(milliseconds: 500), () {
      // Clear ChatsController (Permanent)
      try {
        if (Get.isRegistered<ChatsController>()) {
          Get.delete<ChatsController>(force: true);
        }
      } catch (e) {
        debugPrint("Error deleting ChatsController: $e");
      }

      // Reset NavigationController (Singleton)
      try {
        if (Get.isRegistered<NavigationController>()) {
          Get.find<NavigationController>().reset();
        }
      } catch (e) {
        debugPrint("Error resetting NavigationController: $e");
      }

      // Force delete others just in case
      final controllersToDelete = [
        () => Get.delete<DashboardController>(force: true),
        () => Get.delete<TemplatesController>(force: true),
        () => Get.delete<BroadcastsController>(force: true),
        () => Get.delete<CreateBroadcastController>(force: true),
        () => Get.delete<CreateTemplateController>(force: true),
        () => Get.delete<SettingsController>(force: true),
        () => Get.delete<BusinessProfileController>(force: true),
        () => Get.delete<ContactsController>(force: true),
        () => Get.delete<AdminsController>(force: true),
        () => Get.delete<RolesController>(force: true),
        () => Get.delete<ClientsController>(force: true),
        () => Get.delete<MilestoneSchedularsController>(force: true),
        () => Get.delete<AddClientController>(force: true),
        () => Get.delete<LoginController>(force: true),
        () => Get.delete<AddAdminsController>(force: true),
        () => Get.delete<AddRolesController>(force: true),
      ];

      for (var deleteFunc in controllersToDelete) {
        try {
          deleteFunc();
        } catch (e) {
          // Ignore
        }
      }
    });
  }

  static String getInitials(String name) {
    if (name.trim().isEmpty) return "";

    final parts = name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }

  /// Creates a new excel file and download to user's device
  /// Pass List of String `columns`, List of List of String `data`, List of bool exportableColumns
  /// and String `fileName`
  /// data in these is coming Locally
  static void createAndDownloadExcelFileLocal({
    required List<String> columns,
    required List<List<String>> data,
    required List<bool> exportableColumns,
    required String fileName,
  }) async {
    if (columns.length != exportableColumns.length) return;

    for (int i = 0; i < exportableColumns.length; i++) {
      if (!exportableColumns[i]) {
        columns[i] = "";
      }
    }

    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
        if (!exportableColumns[j]) {
          data[i][j] = "";
        }
      }
    }

    columns.removeWhere((e) => e.isEmpty);
    for (int i = 0; i < data.length; i++) {
      data[i].removeWhere((e) => e.isEmpty);
    }

    Excel excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    var headerCell = sheet.cell(CellIndex.indexByString('A1'));
    headerCell.cellStyle = CellStyle(bold: true);

    // Saving columns
    for (int i = 0; i < columns.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        columns[i],
      );
    }

    // Saving data
    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            .value = TextCellValue(
          data[i][j],
        );
      }
    }

    // Download files
    excel.save(fileName: '$fileName.xlsx');
  }

  /// function to show a overlay loading dialog on the screen
  static void showOverlayLoadingDialog({Color color = Colors.black}) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            color: Colors.black.withValues(alpha: 0.1),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(Get.context!).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleShimmer(size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void hideCustomLoader(BuildContext context) {
    Get.back();
  }

  /// function to hide any active overlay loading dialog
  static void hideOverlayLoadingDialog() {
    // Navigator.of(Get.overlayContext!).pop();
    Get.back();
  }
}
