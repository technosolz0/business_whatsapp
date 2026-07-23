import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'interactive_model.dart';

class CarouselCard {
  final RxString body = ''.obs;
  final RxString originalBody = ''.obs; // Store original template text
  final RxList<String> appliedValues =
      <String>[].obs; // 🔥 New: For highlighting
  final RxString mediaType = 'Image'.obs;
  final Rx<Uint8List?> fileBytes = Rx<Uint8List?>(null);
  final RxString fileName = ''.obs;
  final RxString mediaHandleId = ''.obs;
  final RxString attachmentId = ''.obs;
  final RxList<InteractiveButton> buttons = <InteractiveButton>[].obs;
  final RxList<String> countryCodes =
      <String>[].obs; // 🔥 New: For phone buttons
  final RxList<String> buttonTextErrors = <String>[].obs;
  final RxList<String> buttonValueErrors = <String>[].obs;
  final RxList<TextEditingController> variableControllers =
      <TextEditingController>[].obs;
  final RxList<String> variableExamples =
      <String>[].obs; // 🔥 New: For sample values
  final RxList<String> sampleValueErrors = <String>[].obs;

  final RxBool isUploading = false.obs;
  final RxString uploadError = ''.obs;

  CarouselCard();

  void dispose() {
    for (var c in variableControllers) {
      c.dispose();
    }
  }
}
