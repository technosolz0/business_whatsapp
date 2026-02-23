import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/data/services/template_service.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart' show Utilities;
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:business_whatsapp/app/data/models/template_params.dart';
import 'package:business_whatsapp/app/data/services/template_firebase_service.dart';
import 'package:business_whatsapp/app/data/models/milestone_element.dart';
import 'package:business_whatsapp/app/modules/milestone_templates/controllers/milestone_schedulars_controller.dart';

class CreateMilestoneSchedularController extends GetxController {
  // ===========================================================================
  // 🟦 FORM FIELDS
  // ===========================================================================
  final TextEditingController nameCtrl = TextEditingController();
  final FocusNode nameFocus = FocusNode();

  final RxString schedularName = ''.obs;
  final RxString schedularType =
      'birthday'.obs; // birthday, anniversary, workAnniversary
  final RxString schedularCategory = 'Marketing'.obs;
  final RxString scheduleTime = '10:00 AM'.obs;
  final RxString schedularLanguage = 'English'.obs;
  final RxString nameError = ''.obs;
  final RxString formatError = ''.obs;

  // Schedular selection
  final RxList<TemplateParamModel> schedularList = <TemplateParamModel>[].obs;
  final RxString selectedTemplateId = ''.obs;
  final RxString originalSchedularBody = ''.obs;
  final Rx<TemplateParamModel?> selectedSchedularParams =
      Rx<TemplateParamModel?>(null);

  final Map<String, TextEditingController> paramControllers = {};
  final Map<String, RxString> paramErrors = {};
  final Map<String, Map<String, String>> variableValues = {};

  final RxList<String> availableChips = [
    "First Name",
    "Last Name",
    "Email",
    "Company",
    "Birth Date",
    "Anniversary",
    "Work Anniversary",
  ].obs;

  // Schedular message
  final TextEditingController messageCtrl = TextEditingController();
  final FocusNode messageFocus = FocusNode();
  final RxString schedularMessage = ''.obs;
  final RxList<TextEditingController> variableControllers =
      <TextEditingController>[].obs;
  final RxList<String> sampleValueErrors = <String>[].obs;
  final RxInt previewRefresh = 0.obs;

  String get displayMessage {
    String message = originalSchedularBody.value;
    if (message.isEmpty) return schedularMessage.value;

    final regex = RegExp(r'{{(\d+)}}');
    final matches = regex.allMatches(message).toList();

    // Replace from end to start to maintain indices
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final indexStr = match.group(1)!;
      final keyName = "body_$indexStr";

      if (variableValues.containsKey(keyName)) {
        final data = variableValues[keyName]!;
        final type = data["type"] ?? "empty";
        final rawValue = data["value"] ?? "";

        String displayValue = rawValue;
        if (type == "dynamic") {
          // In milestone preview, we just show the chip name for simplicity
          // or we could resolve it if we had a sample contact
          displayValue = rawValue;
        }

        if (displayValue.isNotEmpty) {
          message = message.replaceRange(match.start, match.end, displayValue);
        }
      }
    }
    return message;
  }

  // ===========================================================================
  // 🟦 BACKGROUND IMAGE
  // ===========================================================================
  final Rx<Uint8List?> backgroundBytes = Rx<Uint8List?>(null);
  final RxString backgroundFileName = ''.obs;
  final RxString backgroundError = ''.obs;
  final RxBool isUploadingBackground = false.obs;

  // Background scaling

  // Image dimensions
  final RxDouble imageWidth = 574.0.obs;
  final RxDouble imageHeight = 700.0.obs;
  final RxDouble containerWidth = 574.0.obs;
  final RxDouble containerHeight = 700.0.obs;

  final RxString selectedMediaType = ''.obs;
  final RxString mediaHandleId = "".obs;
  final RxBool isUploadingMedia = false.obs;

  // ===========================================================================
  // 🟦 MILESTONE ELEMENTS (Draggable Blocks)
  // ===========================================================================
  final RxList<MilestoneElement> milestoneElements = <MilestoneElement>[].obs;
  final Rx<MilestoneElement?> selectedElement = Rx<MilestoneElement?>(null);

  // ===========================================================================
  // 🟦 EDIT/COPY MODE
  // ===========================================================================
  final RxBool isEditMode = false.obs;
  final RxBool isCopyMode = false.obs;
  dynamic editingSchedular;
  String? editingDocId;

  // ===========================================================================
  // 🟦 EXISTING TYPES
  // ===========================================================================
  final RxSet<String> existingTypes = <String>{}.obs;

  List<DropdownMenuItem<String>> get availableTypes {
    const allTypes = [
      DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
      DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
      DropdownMenuItem(
        value: 'workAnniversary',
        child: Text('Work Anniversary'),
      ),
    ];

    if (isEditMode.value) {
      return allTypes;
    } else {
      return allTypes
          .where((item) => !existingTypes.contains(item.value))
          .toList();
    }
  }

  // ===========================================================================
  // 🟦 LIFECYCLE
  // ===========================================================================
  @override
  void onInit() {
    super.onInit();
    nameCtrl.addListener(() => schedularName.value = nameCtrl.text);
    nameFocus.addListener(() {
      if (!nameFocus.hasFocus) validateSchedularName();
    });
    messageCtrl.addListener(() {
      schedularMessage.value = messageCtrl.text;
      _updateVariableFields(messageCtrl.text);
    });
    loadSchedulars();
    loadExistingTypes();
  }

  @override
  void onClose() {
    // nameFocus.dispose(); // Commented out to prevent "FocusNode used after disposed" error during navigation
    messageCtrl.dispose();
    // messageFocus.dispose(); // Commented out to prevent "FocusNode used after disposed" error during navigation
    for (var controller in variableControllers) {
      controller.dispose();
    }
    _disposeParamStates();
    super.onClose();
  }

  void loadSchedulars() async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getApprovedMediaTemplates,
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final apiTemplates = data['data'] as List<dynamic>;
          final templates = apiTemplates.map((template) {
            return TemplateParamModel(
              id: template['id'].toString(),
              name: template['name'].toString(),
              language: 'en',
              headerVars: 0,
              bodyVars: 0,
              headerFormat: '',
              templateType: 'Text',
              category: 'UTILITY',
              headerText: null,
              headerExamples: [],
              bodyText: '',
              bodyExamples: [],
              buttons: null,
              buttonVars: 0,
            );
          }).toList();

          schedularList.value = templates;
        }
      }
    } catch (e) {
      print('Error loading schedulars: $e');
      schedularList.value = await TemplateFirestoreService.instance
          .getAllTemplatesForBroadcast();
    }
  }

  Future<void> loadExistingTypes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('milestone_schedulars')
          .doc(clientID)
          .collection('data')
          .get();
      final types = snapshot.docs
          .map((doc) => doc.data()['type'] as String?)
          .where((type) => type != null)
          .cast<String>()
          .toSet();
      existingTypes.assignAll(types);
    } catch (e) {
      print('Error loading existing types: $e');
    }
  }

  void onSchedularSelected(String schedularId) {
    selectedTemplateId.value = schedularId;
    final basicSchedular = schedularList.firstWhere(
      (t) => t.id == schedularId,
      orElse: () => TemplateParamModel(
        id: "",
        language: "",
        templateType: "",
        category: "UTILITY",
        name: "",
        headerVars: 0,
        bodyVars: 0,
        headerFormat: "",
        headerText: "",
        headerExamples: [],
        bodyText: "",
        bodyExamples: [],
        buttons: [],
        buttonVars: 0,
      ),
    );

    selectedSchedularParams.value = basicSchedular;
    schedularCategory.value = basicSchedular.category;
    schedularLanguage.value = basicSchedular.language;
    originalSchedularBody.value = basicSchedular.bodyText;
    schedularMessage.value = basicSchedular.bodyText;

    variableValues.clear();
    _disposeParamStates();

    _loadFullSchedularDetails(schedularId);
  }

  Future<void> _loadFullSchedularDetails(String schedularId) async {
    try {
      final fullSchedular = await TemplateFirestoreService.instance
          .getTemplateById(schedularId);

      if (fullSchedular != null) {
        selectedSchedularParams.value = fullSchedular;
        schedularCategory.value = fullSchedular.category;
        schedularLanguage.value = fullSchedular.language;
        originalSchedularBody.value = fullSchedular.bodyText;
        schedularMessage.value = fullSchedular.bodyText;

        variableValues.clear();
        for (int i = 1; i <= fullSchedular.headerVars; i++) {
          variableValues["header_$i"] = {"type": "empty", "value": ""};
        }
        for (int i = 1; i <= fullSchedular.bodyVars; i++) {
          variableValues["body_$i"] = {"type": "empty", "value": ""};
        }
        _disposeParamStates();
        previewRefresh.value++;
      }
    } catch (e) {
      print('Error loading full schedular details: $e');
    }
  }

  void ensureParamKey(String key) {
    if (!paramControllers.containsKey(key)) {
      paramControllers[key] = TextEditingController();
    }
    if (!paramErrors.containsKey(key)) {
      paramErrors[key] = ''.obs;
    }
    if (!variableValues.containsKey(key)) {
      variableValues[key] = {"type": "empty", "value": ""};
    }
  }

  void _disposeParamStates() {
    for (final c in paramControllers.values) {
      c.dispose();
    }
    paramControllers.clear();
    paramErrors.clear();
  }

  // ===========================================================================
  // 🟦 BACKGROUND IMAGE HANDLING
  // ===========================================================================

  Future<void> pickBackgroundImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          backgroundBytes.value = file.bytes;
          backgroundFileName.value = file.name;
          backgroundError.value = '';

          // Calculate image dimensions
          await _calculateImageDimensions(file.bytes!);
        }
      }
    } catch (e) {
      backgroundError.value = 'Failed to pick image: $e';
    }
  }

  Future<void> handleDroppedBackgroundFile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      backgroundBytes.value = bytes;
      backgroundFileName.value = fileName;
      backgroundError.value = '';

      // Calculate image dimensions
      await _calculateImageDimensions(bytes);
    } catch (e) {
      backgroundError.value = 'Failed to load image: $e';
    }
  }

  Future<void> _calculateImageDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      imageWidth.value = image.width.toDouble();
      imageHeight.value = image.height.toDouble();

      _updateContainerDimensions();
    } catch (e) {
      print('Error calculating image dimensions: $e');
    }
  }

  void _updateContainerDimensions() {
    // Auto-calculate container size to fit maximum dimensions while maintaining aspect ratio
    // Max dimensions: 574x700
    const maxWidth = 574.0;
    const maxHeight = 700.0;

    if (imageWidth.value == 0 || imageHeight.value == 0) return;

    double aspectRatio = imageWidth.value / imageHeight.value;

    if (aspectRatio > (maxWidth / maxHeight)) {
      // Width is the limiting factor
      containerWidth.value = maxWidth;
      containerHeight.value = maxWidth / aspectRatio;
    } else {
      // Height is the limiting factor
      containerHeight.value = maxHeight;
      containerWidth.value = maxHeight * aspectRatio;
    }
  }

  // ===========================================================================
  // 🟦 ELEMENT MANAGEMENT
  // ===========================================================================

  void addTextBlock() {
    final newElement = MilestoneElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'text',
      initialPosition: const Offset(100, 100),
      initialSize: const Size(200, 50),
      initialContent: 'Name',
      initialFont: 'Roboto',
      initialFontSize: 16,
      initialColor: Colors.black,
      initialTextAlign: 'left',
      initialIsBold: false,
      initialIsItalic: false,
    );

    milestoneElements.add(newElement);
    selectedElement.value = newElement;
  }

  void addImageBlock() {
    final newElement = MilestoneElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'image',
      initialPosition: const Offset(100, 100),
      initialSize: const Size(150, 150),
    );

    milestoneElements.add(newElement);
    selectedElement.value = newElement;
  }

  void selectElement(MilestoneElement element) {
    selectedElement.value = element;
  }

  void deselectElement() {
    selectedElement.value = null;
  }

  void removeSelectedElement() {
    if (selectedElement.value != null) {
      milestoneElements.remove(selectedElement.value);
      selectedElement.value = null;
    }
  }

  void updateElementPosition(MilestoneElement element, Offset newPosition) {
    element.position.value = newPosition;
  }

  void updateElementSize(MilestoneElement element, Size newSize) {
    element.size.value = newSize;
  }

  Map<String, double> getCalculatedPosition(MilestoneElement element) {
    double scale = 1.0;
    if (imageWidth.value > 0) {
      scale = containerWidth.value / imageWidth.value;
    }
    return {
      'dx': element.position.value.dx / scale,
      'dy': element.position.value.dy / scale,
    };
  }

  Map<String, double> getCalculatedSize(MilestoneElement element) {
    double scale = 1.0;
    if (imageWidth.value > 0) {
      scale = containerWidth.value / imageWidth.value;
    }
    return {
      'width': element.size.value.width / scale,
      'height': element.size.value.height / scale,
    };
  }

  void _updateVariableFields(String text) {
    final regex = RegExp(r'{{(\d+)}}');
    final matches = regex.allMatches(text);

    final detectedVars =
        matches.map((e) => int.parse(e.group(1)!)).toSet().toList()..sort();

    final needed = detectedVars.isEmpty ? 0 : detectedVars.last;

    while (variableControllers.length < needed) {
      final c = TextEditingController();
      c.addListener(() => previewRefresh.value++);
      variableControllers.add(c);
    }

    while (variableControllers.length > needed) {
      variableControllers.removeLast().dispose();
    }

    while (sampleValueErrors.length < needed) {
      sampleValueErrors.add("");
    }
    while (sampleValueErrors.length > needed) {
      sampleValueErrors.removeLast();
    }

    previewRefresh.value++;
  }

  // ===========================================================================
  // 🟦 INTERAKT MEDIA UPLOAD
  // ===========================================================================

  void handleApiError(Map<String, dynamic> error) {
    final errorCode = error["error_subcode"];
    final errorMsg = error["error_user_msg"] ?? "Something went wrong.";

    switch (errorCode) {
      case 2388023:
        final deleteLanguageMessage =
            "New Albanian content can't be added while the existing Albanian content is being deleted.";

        final retryMessage =
            "Try again in less than 1 minute or consider creating a new message template.";

        Utilities.showSnackbar(SnackType.ERROR, deleteLanguageMessage);
        Utilities.showSnackbar(SnackType.ERROR, retryMessage);
        break;

      case 2388043:
        if (variableControllers.isNotEmpty) {
          for (int i = 0; i < sampleValueErrors.length; i++) {
            sampleValueErrors[i] = errorMsg;
          }
        }
        break;

      case 2388040:
      case 2388047:
      case 2388072:
      case 2388073:
      case 2388293:
      case 2388299:
        formatError.value = errorMsg;
        Utilities.showSnackbar(SnackType.ERROR, errorMsg);
        break;

      case 2388025:
        nameError.value =
            "This template is currently being removed. Please use a different name.";
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Please use a different template name.",
        );
        break;

      case 2388024:
        nameError.value =
            "A schedular with this name already exists. Please change schedular name.";
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Schedular name already exist.",
        );
        break;

      default:
        Utilities.showSnackbar(SnackType.ERROR, errorMsg);
    }
  }

  // ===========================================================================
  // 🟦 TEXT STYLING
  // ===========================================================================

  void updateTextFont(String font) {
    if (selectedElement.value?.type == 'text') {
      selectedElement.value!.font.value = font;
    }
  }

  void updateTextSize(int size) {
    if (selectedElement.value?.type == 'text') {
      selectedElement.value!.fontSize.value = size;
    }
  }

  void updateTextColor(Color color) {
    if (selectedElement.value?.type == 'text') {
      selectedElement.value!.color.value = color;
    }
  }

  void toggleBold() {
    if (selectedElement.value?.type == 'text') {
      selectedElement.value!.isBold.value =
          !selectedElement.value!.isBold.value;
    }
  }

  void toggleItalic() {
    if (selectedElement.value?.type == 'text') {
      selectedElement.value!.isItalic.value =
          !selectedElement.value!.isItalic.value;
    }
  }

  void updateTextAlign(String align) {
    if (selectedElement.value?.type == 'text') {
      selectedElement.value!.textAlign.value = align;
    }
  }

  Future<void> pickImageForElement(MilestoneElement element) async {
    if (element.type != 'image') return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          element.imageBytes.value = file.bytes;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  // ===========================================================================
  // 🟦 VALIDATION
  // ===========================================================================

  bool validateSchedularName({bool requestFocus = false}) {
    final name = nameCtrl.text.trim();

    if (name.isEmpty) {
      nameError.value = 'Schedular name is required';
      if (requestFocus) nameFocus.requestFocus();
      return false;
    }

    // Check for valid format (lowercase, alphanumeric, underscores)
    final validPattern = RegExp(r'^[a-z0-9_]+$');
    if (!validPattern.hasMatch(name)) {
      nameError.value =
          'Only lowercase letters, numbers, and underscores allowed';
      if (requestFocus) nameFocus.requestFocus();
      return false;
    }

    nameError.value = '';
    return true;
  }

  bool validateForm() {
    bool isValid = true;

    // 1. Schedular Name
    if (!validateSchedularName(requestFocus: true)) {
      isValid = false;
    }

    // 2. Background Image
    if (backgroundBytes.value == null) {
      backgroundError.value = 'Please upload a background image';
      isValid = false;
    }

    // 3. Select Template
    if (selectedTemplateId.value.isEmpty) {
      Get.snackbar('Validation Error', 'Please select a template');
      isValid = false;
    }

    // 4. Schedular Parameters
    final param = selectedSchedularParams.value;
    if (param != null) {
      // Validate header vars
      for (int i = 1; i <= param.headerVars; i++) {
        final key = "header_$i";
        ensureParamKey(key);
        if (paramControllers[key]?.text.trim().isEmpty ?? true) {
          paramErrors[key]?.value = "Required";
          isValid = false;
        } else {
          paramErrors[key]?.value = "";
        }
      }
      // Validate body vars
      for (int i = 1; i <= param.bodyVars; i++) {
        final key = "body_$i";
        ensureParamKey(key);
        if (paramControllers[key]?.text.trim().isEmpty ?? true) {
          paramErrors[key]?.value = "Required";
          isValid = false;
        } else {
          paramErrors[key]?.value = "";
        }
      }
    }

    // 5. Milestone Elements
    if (milestoneElements.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please add at least one element to the design',
      );
      isValid = false;
    }

    return isValid;
  }

  // ===========================================================================
  // 🟦 SAVE TO FIREBASE
  // ===========================================================================

  Future<void> saveMilestoneSchedular() async {
    if (!validateForm()) {
      if (nameCtrl.text.trim().isEmpty) {
        Utilities.showSnackbar(SnackType.ERROR, "Schedular name is required");
      } else {
        Get.snackbar('Validation Error', 'Please fix the errors before saving');
      }
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircleShimmer(size: 40)),
        barrierDismissible: false,
      );

      // 1. Upload background image to Firebase Storage
      final backgroundUrl = await _uploadBackgroundToFirebase();

      // 2. Calculate effective scale
      double effectiveScale = 1.0;
      if (imageWidth.value > 0) {
        effectiveScale = containerWidth.value / imageWidth.value;
      }

      // 3. Prepare elements data
      final elementsData = milestoneElements.map((element) {
        return {
          'id': element.id,
          'type': element.type,
          'position': getCalculatedPosition(element),
          'size': getCalculatedSize(element),
          if (element.type == 'text') ...{
            'content': element.content.value,
            'textAlign': element.textAlign.value,
            'font': element.font.value,
            'fontSize': (element.fontSize.value / effectiveScale).toInt(),
            'color': element.color.value.value, // ARGB int
            'isBold': element.isBold.value,
            'isItalic': element.isItalic.value,
          },
          // Note: Image bytes are not stored in Firestore, only in elements during editing
        };
      }).toList();

      // 4. Prepare Variable Values
      final List<String> sampleVals = [];
      if (selectedTemplateId.value.isNotEmpty &&
          selectedSchedularParams.value != null) {
        final params = selectedSchedularParams.value!;
        // Collect body variables
        for (int i = 1; i <= params.bodyVars; i++) {
          final key = "body_$i";
          final val = paramControllers[key]?.text.trim() ?? "";
          sampleVals.add(val);

          // Also ensure variableValues map is up to date
          variableValues[key] = {
            "type": variableValues[key]?["type"] ?? "static",
            "value": val,
          };
        }
        // Handle header variables if needed
        for (int i = 1; i <= params.headerVars; i++) {
          final key = "header_$i";
          final val = paramControllers[key]?.text.trim() ?? "";
          variableValues[key] = {
            "type": variableValues[key]?["type"] ?? "static",
            "value": val,
          };
        }
      } else {
        // Fallback or custom message logic
        for (var c in variableControllers) {
          sampleVals.add(c.text.trim());
        }
      }

      // 5. Save to Firestore

      final schedularData = {
        'name': nameCtrl.text.trim(),
        'type': schedularType.value,
        'category': schedularCategory.value,
        'scheduleTime': scheduleTime.value,
        'language': schedularLanguage.value,
        'schedularMessage': schedularMessage.value,
        'templateMessageVariables': sampleVals,
        'selectedTemplateId': selectedTemplateId.value,
        'selectedTemplateName': selectedSchedularParams.value?.name ?? '',
        'variableValues': variableValues,
        'backgroundUrl': backgroundUrl,
        'backgroundScale': effectiveScale,
        'imageWidth': imageWidth.value,
        'imageHeight': imageHeight.value,
        'containerWidth': containerWidth.value,
        'containerHeight': containerHeight.value,
        'elements': elementsData,
        if (!isEditMode.value) 'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      String schedulerId;
      if (isEditMode.value && editingDocId != null) {
        // Update existing document
        await FirebaseFirestore.instance
            .collection('milestone_schedulars')
            .doc(clientID)
            .collection('data')
            .doc(editingDocId)
            .update(schedularData);
        schedulerId = editingDocId!;
        // Call update milestone cron job API if needed
        await _updateMilestoneCronJob(schedulerId, scheduleTime.value);
      } else {
        // Add new document
        final docRef = await FirebaseFirestore.instance
            .collection('milestone_schedulars')
            .doc(clientID)
            .collection('data')
            .add(schedularData);
        schedulerId = docRef.id;
        // Call create milestone cron job API
        await _createMilestoneCronJob(schedulerId, scheduleTime.value);
      }

      if (Get.isDialogOpen ?? false) Get.back(); // Close loading dialog
      Get.offNamed(Routes.MILESTONE_SCHEDULARS);
      Get.snackbar('Success', 'Milestone schedular saved successfully');

      // Update navigation controller state for main shell and mobile compatibility
      final navController = Get.find<NavigationController>();
      navController.currentRoute.value = Routes.MILESTONE_SCHEDULARS;
      navController.selectedIndex.value = 8; // Schedulars index
      navController.routeTrigger.value++;

      // Navigate back and refresh list
      Get.back();
      final milestoneController = Get.find<MilestoneSchedularsController>();
      milestoneController.loadSchedulars();
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar('Error', 'Failed to save template: $e');
    }
  }

  Future<String> _uploadBackgroundToFirebase() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${nameCtrl.text.trim()}_bg_$timestamp.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'milestone_schedulars/$clientID/backgrounds/$fileName',
      );

      final uploadTask = ref.putData(
        backgroundBytes.value!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload background image: $e');
    }
  }

  Future<void> loadSchedularForCopy(Map<String, dynamic> schedular) async {
    resetForm();
    editingSchedular = schedular;
    editingDocId = schedular['id'];
    isEditMode.value = true;

    nameCtrl.text = schedular['name'] ?? '';
    schedularName.value = schedular['name'] ?? '';
    schedularType.value = schedular['type'] ?? 'birthday';
    schedularCategory.value = schedular['category'] ?? 'Marketing';
    scheduleTime.value = schedular['scheduleTime'] ?? '10:00 AM';
    schedularLanguage.value = schedular['language'] ?? 'English';
    selectedTemplateId.value = schedular['selectedTemplateId'] ?? '';
    schedularMessage.value = schedular['schedularMessage'] ?? '';
    messageCtrl.text = schedular['schedularMessage'] ?? '';

    // Load Variables
    if (schedular['variableValues'] != null) {
      final Map<String, dynamic> rawVars = Map<String, dynamic>.from(
        schedular['variableValues'],
      );
      rawVars.forEach((key, val) {
        if (val is Map) {
          variableValues[key] = {
            'type': (val['type'] ?? 'static').toString(),
            'value': (val['value'] ?? '').toString(),
          };
        }
      });
      _updateVariableControllers();
    }

    // Load Background
    if (schedular['backgroundUrl'] != null &&
        schedular['backgroundUrl'].isNotEmpty) {
      imageWidth.value = (schedular['imageWidth'] ?? 574.0).toDouble();
      imageHeight.value = (schedular['imageHeight'] ?? 700.0).toDouble();
      _updateContainerDimensions();
      _loadBackgroundImageFromUrl(schedular['backgroundUrl']);
    }

    // Load Elements
    if (schedular['elements'] != null) {
      _loadElementsFromData(
        List<Map<String, dynamic>>.from(schedular['elements']),
      );
    }
  }

  void _updateVariableControllers() {
    _disposeParamStates();
    variableControllers.clear();

    // Sort variableValues keys to maintain order for variableControllers
    final sortedKeys = variableValues.keys.toList()..sort();

    for (var key in sortedKeys) {
      final data = variableValues[key];
      if (data != null && data['value'] != null) {
        final val = data['value'].toString();

        if (key.startsWith('body_') || key.startsWith('header_')) {
          // It's a template parameter
          paramControllers[key] = TextEditingController(text: val);
          paramErrors[key] = ''.obs;
        } else {
          // It's a custom message variable {{n}}
          final ctrl = TextEditingController(text: val);
          variableControllers.add(ctrl);
        }
      }
    }
  }

  Future<void> _loadBackgroundImageFromUrl(String url) async {
    try {
      isUploadingBackground.value = true;
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200) {
        backgroundBytes.value = Uint8List.fromList(response.data);
        backgroundFileName.value = "background_image.png";
      }
    } catch (e) {
      print('Error loading background image: $e');
    } finally {
      isUploadingBackground.value = false;
    }
  }

  void _loadElementsFromData(List<Map<String, dynamic>> elementsData) {
    milestoneElements.clear();

    double scale = 1.0;
    if (imageWidth.value > 0) {
      scale = containerWidth.value / imageWidth.value;
    }

    for (var data in elementsData) {
      final pos = data['position'] ?? {'dx': 0.0, 'dy': 0.0};
      final sz = data['size'] ?? {'width': 100.0, 'height': 50.0};

      final element = MilestoneElement(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: data['type'] ?? 'text',
        initialPosition: Offset(
          (pos['dx'] ?? 0.0).toDouble() * scale,
          (pos['dy'] ?? 0.0).toDouble() * scale,
        ),
        initialSize: Size(
          (sz['width'] ?? 100.0).toDouble() * scale,
          (sz['height'] ?? 50.0).toDouble() * scale,
        ),
        initialContent: data['content'] ?? '',
        initialFont: data['font'] ?? 'Roboto',
        initialFontSize: ((data['fontSize'] ?? 16).toDouble() * scale).toInt(),
        initialColor: Color(data['color'] ?? 0xFF000000),
        initialTextAlign: data['textAlign'] ?? 'left',
        initialIsBold: data['isBold'] ?? false,
        initialIsItalic: data['isItalic'] ?? false,
      );
      milestoneElements.add(element);
    }
  }

  // ===========================================================================
  // 🟦 RESET & CANCEL
  // ===========================================================================

  void resetForm() {
    nameCtrl.clear();
    schedularName.value = '';
    schedularType.value = 'birthday';
    schedularCategory.value = 'Marketing';
    scheduleTime.value = '10:00 AM';
    schedularLanguage.value = 'English';
    nameError.value = '';

    messageCtrl.clear();
    schedularMessage.value = '';

    backgroundBytes.value = null;
    backgroundFileName.value = '';
    backgroundError.value = '';

    milestoneElements.clear();
    selectedElement.value = null;

    for (var controller in variableControllers) {
      controller.dispose();
    }
    variableControllers.clear();
    sampleValueErrors.clear();

    imageWidth.value = 574.0;
    imageHeight.value = 700.0;
    containerWidth.value = 574.0;
    containerHeight.value = 700.0;

    mediaHandleId.value = '';
    selectedMediaType.value = '';
    isUploadingMedia.value = false;
    formatError.value = '';

    isEditMode.value = false;
    isCopyMode.value = false;
    editingSchedular = null;
    editingDocId = null;
  }

  // ===========================================================================
  // 🟦 MILESTONE CRON JOB API CALLS
  // ===========================================================================

  Future<void> _createMilestoneCronJob(
    String schedulerId,
    String scheduleTime,
  ) async {
    try {
      final scheduleTime =
          "${DateTime.now().year}-01-01 ${this.scheduleTime.value}:00";

      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.createMilestone,
        data: {
          'clientId': clientID,
          'schedulerId': schedulerId,
          'scheduleTime': scheduleTime,
        },
      );

      if (response.statusCode == 200) {
        Get.back(); // close dialog
        Get.find<MilestoneSchedularsController>().fetchSchedulars();
        Get.back(); // go back to list
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          "Schedular created successfully",
        );
      } else {
        Get.back();
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Failed to start schedular: ${response.data}",
        );
      }
    } catch (e) {
      print('❌ Error creating milestone cron job: $e');
    }
  }

  Future<void> _updateMilestoneCronJob(
    String schedulerId,
    String scheduleTime,
  ) async {
    try {
      final scheduleTime =
          "${DateTime.now().year}-01-01 ${this.scheduleTime.value}:00";

      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.updateMilestone,
        data: {
          'clientId': clientID,
          'schedulerId': schedulerId,
          'scheduleTime': scheduleTime,
        },
      );

      if (response.statusCode == 200) {
        Get.back(); // close dialog
        Get.find<MilestoneSchedularsController>().fetchSchedulars();
        Get.back(); // go back to list
        Get.snackbar("Success", "Schedular updated successfully");
      } else {
        Get.back();
        Get.snackbar("Error", "Failed to update schedular: ${response.data}");
      }
    } catch (e) {
      print('❌ Error updating milestone cron job: $e');
    }
  }
}
