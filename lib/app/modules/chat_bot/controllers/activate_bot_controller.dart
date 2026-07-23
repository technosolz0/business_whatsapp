import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:business_whatsapp/app/modules/chat_bot/services/chat_bot_service.dart';
import 'package:business_whatsapp/app/data/models/chat_bot_document.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ActivateBotController extends GetxController {
  final _service = Get.find<ChatBotService>();

  final count = 0.obs;
  var isLoading = false.obs;
  var isDeleting = false.obs;

  // Selected files for upload
  var selectedFiles = <PlatformFile>[].obs;

  // Description field
  final descriptionController = TextEditingController();

  // Search for history
  final historySearchController = TextEditingController();

  // Real upload history data
  var uploadHistory = <ChatBotDocument>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      final response = await _service.listDocuments(isQnA: false);
      final List<dynamic> data = response['data'] ?? [];
      uploadHistory.value = data
          .map((json) => ChatBotDocument.fromJson(json))
          .toList();
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to fetch history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    historySearchController.dispose();
    super.onClose();
  }

  void increment() => count.value++;

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'xls', 'xlsx'],
    );

    if (result != null) {
      selectedFiles.addAll(result.files);
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  Future<void> submit() async {
    if (isLoading.value || isDeleting.value) return;

    if (selectedFiles.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please select at least one file',
      );

      return;
    }

    try {
      isLoading.value = true;

      List<dio.MultipartFile> multipartFiles = [];
      for (var file in selectedFiles) {
        if (kIsWeb) {
          if (file.bytes != null) {
            multipartFiles.add(
              dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
            );
          }
        } else {
          if (file.path != null) {
            multipartFiles.add(
              await dio.MultipartFile.fromFile(file.path!, filename: file.name),
            );
          }
        }
      }

      if (multipartFiles.isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Could not process files for upload',
        );

        return;
      }

      await _service.uploadDocuments(
        isQnA: false,
        files: multipartFiles,
        description: descriptionController.text.trim(),
      );

      Utilities.showSnackbar(SnackType.SUCCESS, 'Files uploaded successfully');

      // Clear form
      selectedFiles.clear();
      descriptionController.clear();

      // Refresh history
      await fetchHistory();
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Upload failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteHistoryItem(int index) async {
    try {
      final doc = uploadHistory[index];
      isDeleting.value = true;
      isLoading.value = true;
      await _service.deleteDocument(id: doc.id);
      uploadHistory.removeAt(index);
      Utilities.showSnackbar(SnackType.SUCCESS, 'Document deleted');
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Delete failed: $e');
    } finally {
      isDeleting.value = false;
      isLoading.value = false;
    }
  }
}
