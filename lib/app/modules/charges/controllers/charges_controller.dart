import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/Utilities/webutils.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'dart:typed_data';

class ChargesController extends GetxController {
  final isLoading = false.obs;

  void downloadSampleCharges() {
    // Implement sample download logic
    // Generate a simple CSV/Excel content and download it
    try {
      final String csvContent =
          "Charge Name,Amount,Description\nService Fee,100,Monthly service fee\nSetup Fee,500,One-time setup fee";
      final Uint8List bytes = Uint8List.fromList(csvContent.codeUnits);
      WebUtils.downloadFile(bytes, "sample_charges.csv", "text/csv");
      Utilities.showSnackbar(SnackType.SUCCESS, "Sample charges downloaded");
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to download sample: $e");
    }
  }

  void uploadCharges() {
    // Implement file picking and upload logic
    Utilities.showSnackbar(
      SnackType.INFO,
      "Upload charges functionality to be implemented",
    );
  }

  void downloadCharges() {
    // Implement current charges download logic
    Utilities.showSnackbar(
      SnackType.INFO,
      "Download charges functionality to be implemented",
    );
  }
}
