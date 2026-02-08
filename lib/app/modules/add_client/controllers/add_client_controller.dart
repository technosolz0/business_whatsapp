import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/client_model.dart';
import '../../../data/services/clients_service.dart';
import '../../../routes/app_pages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        // interaktTokenController.text = client.interaktToken; // Removed
        wabaIdController.text = client.wabaId;
        webhookVerifyTokenController.text = client.webhookVerifyToken;
        adminLimitController.text = client.adminLimit.toString();

        // Load additional data (Premium, Subscriptions, Wallet)
        _loadAdditionalData(clientId!);

        if (client.logoUrl != null && client.logoUrl!.isNotEmpty) {
          logoFileName.value = 'Current Logo';
        }
        // if (client.faviconUrl != null && client.faviconUrl!.isNotEmpty) {
        //   faviconFileName.value = 'Current Favicon';
        // } // Removed
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

  Future<void> _loadAdditionalData(String clientId) async {
    try {
      final dataCollection = FirebaseFirestore.instance
          .collection('profile')
          .doc(clientId)
          .collection('data');

      // Load Premium
      final premiumDoc = await dataCollection.doc('premium').get();
      if (premiumDoc.exists) {
        isPremium.value = premiumDoc.data()?['status'] ?? true;
      }

      // Load Wallet
      final walletDoc = await dataCollection.doc('wallet').get();
      if (walletDoc.exists) {
        walletController.text = (walletDoc.data()?['balance'] ?? 0).toString();
      }

      // Load Subscriptions
      final subDoc = await dataCollection.doc('subscriptions').get();
      if (subDoc.exists) {
        final data = subDoc.data();
        if (data != null && data['expiryDate'] != null) {
          subscriptionEndDate.value = (data['expiryDate'] as Timestamp)
              .toDate();
        }
      }
    } catch (e) {
      // debugPrint('Error loading additional data: $e');
    }
  }

  Future<void> _saveAdditionalData(String clientId) async {
    try {
      final dataCollection = FirebaseFirestore.instance
          .collection('profile')
          .doc(clientId)
          .collection('data');

      // Save Premium
      await dataCollection.doc('premium').set({'status': isPremium.value});

      // Save Wallet
      final balance = double.tryParse(walletController.text) ?? 0.0;
      await dataCollection.doc('wallet').set({'balance': balance});

      // Save Subscriptions
      if (subscriptionEndDate.value != null) {
        final now = DateTime.now();
        final startDate = now;
        final expiryDate = subscriptionEndDate.value!;
        final difference = expiryDate.difference(startDate).inDays;

        await dataCollection.doc('subscriptions').set({
          'expiryDate': Timestamp.fromDate(expiryDate),
          'lastRenewedAt': Timestamp.fromDate(now),
          'startDate': Timestamp.fromDate(startDate),
          'status': 'active',
          'validityDays': difference > 0 ? difference : 0,
        });
      }
    } catch (e) {
      // debugPrint('Error saving additional data: $e');
      rethrow; // Rethrow to be caught by saveClient
    }
  }

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
        // interaktToken: interaktTokenController.text.trim(), // Removed
        wabaId: wabaIdController.text.trim(),
        webhookVerifyToken: webhookVerifyTokenController.text.trim(),
        logoUrl: logoUrl,
        // faviconUrl: faviconUrl, // Removed
        status: existingClient?.status ?? 'Active',
        adminLimit: int.tryParse(adminLimitController.text.trim()) ?? 2,
        createdAt: existingClient?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String? targetClientId;

      if (isEditMode.value && clientId != null) {
        // Update existing client
        targetClientId = clientId;
        final success = await _clientsService.updateClient(clientId!, client);
        if (!success) {
          throw Exception('Failed to update client');
        }
      } else {
        // Add new client
        targetClientId = await _clientsService.addClient(client);
        if (targetClientId == null) {
          throw Exception('Failed to add client');
        }
      }

      if (targetClientId != null) {
        await _saveAdditionalData(targetClientId);

        Get.snackbar(
          'Success',
          'Client saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.CLIENTS);
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
