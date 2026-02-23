import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/client_model.dart';
import '../../../data/services/clients_service.dart';
import '../../../routes/app_pages.dart';

class AddClientController extends GetxController {
  final ClientsService _clientsService = ClientsService();

  // Form controllers
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController phoneNumberIdController = TextEditingController();
  // final TextEditingController interaktTokenController = TextEditingController(); // Removed
  final TextEditingController wabaIdController = TextEditingController();
  final TextEditingController webhookVerifyTokenController =
      TextEditingController();
  final TextEditingController walletController = TextEditingController();
  final TextEditingController adminLimitController = TextEditingController();

  // Form key
  // Form key
  GlobalKey<FormState>? formKey;

  // State
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  final Rx<DateTime?> subscriptionEndDate = Rx<DateTime?>(null);
  final RxBool isPremium = false.obs;
  final RxBool isCRMEnabled = false.obs;
  final Rx<File?> logoFile = Rx<File?>(null);
  // final Rx<File?> faviconFile = Rx<File?>(null); // Removed
  final RxString logoFileName = ''.obs;
  // final RxString faviconFileName = ''.obs; // Removed

  final Rx<Uint8List?> logoBytes = Rx<Uint8List?>(null);
  // final Rx<Uint8List?> faviconBytes = Rx<Uint8List?>(null); // Removed

  String? clientId;
  ClientModel? existingClient;

  @override
  void onInit() {
    super.onInit();

    // Check if we're in edit mode
    final params = Get.parameters;
    if (params.containsKey('id')) {
      clientId = params['id'];
      isEditMode.value = true;
      loadClientData();
    }
  }

  @override
  void onClose() {
    // Controllers passed to GetView might be disposed automatically or reused.
    // Explicit disposal causes "used after disposed" errors if the view rebuilds or persists.
    // nameController.dispose();
    // phoneNumberController.dispose();
    // phoneNumberIdController.dispose();
    // wabaIdController.dispose();
    // webhookVerifyTokenController.dispose();
    // walletController.dispose();
    // adminLimitController.dispose();
    super.onClose();
  }

  /// Load client data for editing
  Future<void> loadClientData() async {
    if (clientId == null) return;

    try {
      isLoading.value = true;
      final client = await _clientsService.getClientById(clientId!);

      if (client != null) {
        existingClient = client;
        nameController.text = client.name;
        phoneNumberController.text = client.phoneNumber;
        phoneNumberIdController.text = client.phoneNumberId;
        wabaIdController.text = client.wabaId;
        webhookVerifyTokenController.text = client.webhookVerifyToken;
        adminLimitController.text = client.adminLimit.toString();
        walletController.text = client.walletBalance.toString();
        isCRMEnabled.value = client.isCRMEnabled;
        isPremium.value = client.isPremium;
        subscriptionEndDate.value = client.subscriptionExpiry;

        if (client.logoUrl != null && client.logoUrl!.isNotEmpty) {
          logoFileName.value = 'Current Logo';
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load client data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick logo file
  Future<void> pickLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Needed for Web
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        logoFileName.value = pickedFile.name; // Always set name first

        if (pickedFile.bytes != null) {
          // Web or withData: true
          logoBytes.value = pickedFile.bytes;
          logoFile.value = null; // Clear file if utilizing bytes
        } else if (pickedFile.path != null) {
          // Mobile / Desktop
          logoFile.value = File(pickedFile.path!);
          logoBytes.value = null;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick logo file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // pickFaviconFile removed

  // Firestore based load/save additional data removed as moved to Client table

  /// Save client (add or update)
  Future<void> saveClient() async {
    if (formKey?.currentState == null || !formKey!.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      String? logoUrl = existingClient?.logoUrl;
      // String? faviconUrl = existingClient?.faviconUrl; // Removed

      // Upload logo if new file selected
      if (logoBytes.value != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        logoUrl = await _clientsService.uploadData(
          logoBytes.value!,
          'clients/${phoneNumberIdController.text.trim()}/logos/$timestamp-${logoFileName.value}',
        );
      } else if (logoFile.value != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        logoUrl = await _clientsService.uploadFile(
          logoFile.value!,
          'clients/${phoneNumberIdController.text.trim()}/logos/$timestamp-${logoFileName.value}',
        );
      }

      // Favicon upload logic removed

      final client = ClientModel(
        id: clientId,
        name: nameController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        phoneNumberId: phoneNumberIdController.text.trim(),
        wabaId: wabaIdController.text.trim(),
        webhookVerifyToken: webhookVerifyTokenController.text.trim(),
        logoUrl: logoUrl,
        status: existingClient?.status ?? 'Approved',
        isCRMEnabled: isCRMEnabled.value,
        adminLimit: int.tryParse(adminLimitController.text.trim()) ?? 2,
        isPremium: isPremium.value,
        subscriptionExpiry: subscriptionEndDate.value,
        walletBalance: double.tryParse(walletController.text.trim()) ?? 0.0,
        createdAt: existingClient?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;

      if (isEditMode.value && clientId != null) {
        success = await _clientsService.updateClient(clientId!, client);
      } else {
        final newId = await _clientsService.addClient(client);
        success = newId != null;
      }

      if (success) {
        Get.snackbar(
          'Success',
          'Client saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.CLIENTS);
      } else {
        throw Exception('Failed to save client');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save client: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate back to clients list
  void navigateBack() {
    Get.offAllNamed(Routes.CLIENTS);
  }
}
