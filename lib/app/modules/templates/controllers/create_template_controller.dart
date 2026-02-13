import 'dart:typed_data';

import 'package:adminpanel/app/Utilities/media_utils.dart';
import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/controllers/navigation_controller.dart';
import 'package:adminpanel/app/data/models/interactive_model.dart';
// import 'package:adminpanel/app/core/utils/utilities.dart';
import 'package:adminpanel/app/data/models/template_model.dart';
import 'package:adminpanel/app/data/services/template_firebase_service.dart';
import 'package:adminpanel/app/data/services/template_service.dart';
import 'package:adminpanel/app/modules/templates/controllers/templates_controller.dart';
import 'package:adminpanel/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common widgets/common_snackbar.dart';

class CreateTemplateController extends GetxController {
  // ===========================================================================
  // 🟦 FORM CONTROLLERS
  // ===========================================================================
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController formatCtrl = TextEditingController();
  final TextEditingController headerCtrl = TextEditingController();
  final TextEditingController footerCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode formatFocus = FocusNode();
  final FocusNode headerFocus = FocusNode();
  final FocusNode footerFocus = FocusNode();

  // ===========================================================================
  // 🟦 RX FORM VALUES
  // ===========================================================================
  final RxString templateCategory = ''.obs;
  final RxString templateLanguage = ''.obs;
  final RxString templateType = ''.obs;

  final RxString templateName = ''.obs;
  final RxString templateFormat = ''.obs;
  final RxString templateHeader = ''.obs;
  final RxString templateFooter = ''.obs;

  final RxInt previewRefresh = 0.obs;

  // ===========================================================================
  // 🟦 MEDIA (Upload, Validation)
  // ===========================================================================
  final RxString selectedMediaType = ''.obs;
  final List<String> mediaOptions = ['Image', 'Video', 'Document'];

  final RxString selectedFileName = ''.obs;
  final RxString selectedFileError = ''.obs;
  final Rx<Uint8List?> selectedFileBytes = Rx<Uint8List?>(null);

  final RxString mediaHandleId = "".obs;
  final RxBool isUploadingMedia = false.obs;
  RxString phoneCountryCode = "+91".obs;

  // ===========================================================================
  // 🟦 MODES (Edit / Copy)
  // ===========================================================================
  final RxBool isEditMode = false.obs;
  final RxBool isCopyMode = false.obs;
  TemplateModels? editingTemplate;

  // ===========================================================================
  // 🟦 ACTION COUNTERS
  // ===========================================================================
  final RxString interactiveAction = 'all'.obs;
  final RxInt quickRepliesCount = 10.obs;
  final RxInt urlCount = 2.obs;
  final RxInt phoneNumberCount = 1.obs;
  final RxInt copyCodeCount = 1.obs;
  RxList<InteractiveButton> buttons = <InteractiveButton>[].obs;

  RxList<TextEditingController> btnTextCtrls = <TextEditingController>[].obs;
  RxList<TextEditingController> btnValueCtrls =
      <TextEditingController>[].obs; // URL / Phone / Copy
  RxList<String> urlType = <String>[].obs;
  RxList<TextEditingController> dynamicValueCtrl =
      <TextEditingController>[].obs;

  RxList<String> btnTextErrors = <String>[].obs;
  RxList<String> btnValueErrors = <String>[].obs;

  // ===========================================================================
  // 🟦 ERRORS
  // ===========================================================================
  final RxString nameError = ''.obs;
  final RxString languageError = ''.obs;
  final RxString formatError = ''.obs;
  final RxString headerError = ''.obs;
  final RxString footerError = ''.obs;
  final RxBool isCheckingName = false.obs;
  final RxBool isSubmitting = false.obs;

  // ===========================================================================
  // 🟦 VARIABLE SAMPLE VALUE FIELDS
  // ===========================================================================
  RxList<TextEditingController> variableControllers =
      <TextEditingController>[].obs;
  RxList<String> sampleValueErrors = <String>[].obs;

  // ===========================================================================
  // 🟦 LIMITS
  // ===========================================================================
  final RxInt formatCharCount = 0.obs;
  final int maxFormatChars = 1024;
  final int maxFooterChars = 60;

  // ===========================================================================
  // 🟦 DROPDOWNS
  // ===========================================================================
  final List<String> categoryOptions = [
    'Select message categories',
    'Marketing',
    'Utility',
  ];

  final List<String> typeOptions = ['Text', 'Text & Media', 'Interactive'];

  final Map<String, List<String>> allowedExtensions = {
    "Image": ["jpg", "jpeg", "png"],
    "Video": ["mp4", "3gp"],
    "Document": ["txt", "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx"],
  };

  final Map<String, List<String>> allowedMimeTypes = {
    "Image": ["image/jpeg", "image/png"],
    "Video": ["video/mp4", "video/3gpp"],
    "Document": [
      "text/plain",
      "application/pdf",
      "application/msword",
      "application/vnd.ms-excel",
      "application/vnd.ms-powerpoint"
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ],
  };

  // ===========================================================================
  // 🟦 INIT
  // ===========================================================================
  @override
  void onInit() {
    super.onInit();

    // Sync text → Rx
    nameCtrl.addListener(() => templateName.value = nameCtrl.text);
    formatCtrl.addListener(() => updateTemplateFormat(formatCtrl.text));
    headerCtrl.addListener(() => templateHeader.value = headerCtrl.text);
    footerCtrl.addListener(() => templateFooter.value = footerCtrl.text);

    // Focus lost validations
    nameFocus.addListener(() {
      if (!nameFocus.hasFocus) validateTemplateName();
    });

    headerFocus.addListener(() {
      if (!headerFocus.hasFocus) validateHeader();
    });

    footerFocus.addListener(() {
      if (!footerFocus.hasFocus) validateFooter();
    });
  }

  // ===========================================================================
  // 🟦 MEDIA HANDLING
  // ===========================================================================\

  // ===========================================================================
  // 🟦 MEDIA HANDLING (Unified)
  // ===========================================================================
  void updateMediaType(String? type) {
    if (type == null) return;

    if (selectedMediaType.value != type) {
      selectedMediaType.value = type;
      headerCtrl.clear();
      templateHeader.value = ''; // Force clear reactive variable
      selectedFileError.value = "";
      selectedFileBytes.value = null;
      selectedFileName.value = "";
      mediaHandleId.value = "";
    }
  }

  TextEditingController getTextCtrl(int index) {
    if (index >= btnTextCtrls.length) return TextEditingController();
    return btnTextCtrls[index];
  }

  TextEditingController getValueCtrl(int index) {
    if (index >= btnValueCtrls.length) return TextEditingController();
    return btnValueCtrls[index];
  }

  Future<void> pickFile() async {
    if (selectedMediaType.value.isEmpty) {
      selectedFileError.value = "Please select a media type first.";
      return;
    }

    final result = await MediaUtils.pickAndValidateFile(
      mediaType: selectedMediaType.value,
      maxSizeMB: 10,
    );

    if (!result.success) {
      selectedFileError.value = result.error!;
      return;
    }

    selectedFileBytes.value = result.bytes;
    selectedFileName.value = result.fileName!;
    final mime = result.mimeType!;

    await uploadToInterakt(mime);
  }

  Future<void> uploadToInterakt(String mime) async {
    if (selectedFileBytes.value == null) return;

    isUploadingMedia.value = true;

    final result = await TemplateService.instance.uploadMediaToInterakt(
      fileBytes: selectedFileBytes.value!,
      fileName: selectedFileName.value,
      mimeType: mime,
    );

    isUploadingMedia.value = false;

    if (result["success"] == true) {
      mediaHandleId.value = result["media_handle_id"];
    } else {
      selectedFileError.value = "Failed to upload media.";
    }
  }

  void handleDroppedFile(Uint8List bytes, String fileName) async {
    if (selectedMediaType.value.isEmpty) {
      selectedFileError.value = "Please select a media type first.";
      return;
    }

    final result = MediaUtils.validateFile(
      bytes: bytes,
      extension: fileName.split('.').last.toLowerCase(),
      maxSizeMB: 10,
      allowedExtensions: allowedExtensions[selectedMediaType.value]!,
    );

    if (!result.success) {
      selectedFileError.value = result.error!;
      return;
    }

    selectedFileBytes.value = bytes;
    selectedFileName.value = fileName;

    final mime = MediaUtils.getMimeFromExtension(fileName.split('.').last);

    await uploadToInterakt(mime);
  }

  // void updateMediaType(String? type) {
  //   if (type == null) return;

  //   // Only reset if media type TRULY changed
  //   if (selectedMediaType.value != type) {
  //     selectedMediaType.value = type;
  //     headerCtrl.text = '';
  //     selectedFileError.value = "";
  //     selectedFileBytes.value = null;
  //     selectedFileName.value = "";
  //     mediaHandleId.value = "";
  //   }
  // }

  // Future<void> pickFile() async {
  //   if (selectedMediaType.value.isEmpty) {
  //     selectedFileError.value = "Please select a media type first.";
  //     return;
  //   }

  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: allowedExtensions[selectedMediaType.value],
  //     withData: true,
  //   );

  //   if (result == null) return;

  //   final file = result.files.first;
  //   _validateAndSaveFile(file.bytes!, file.extension!.toLowerCase(), file.name);
  // }

  // void handleDroppedFile(Uint8List bytes, String fileName) {
  //   final ext = fileName.split('.').last.toLowerCase();
  //   _validateAndSaveFile(bytes, ext, fileName);
  // }

  // void _validateAndSaveFile(Uint8List bytes, String ext, String name) async {
  //   selectedFileError.value = "";

  //   // Size check
  //   if (bytes.lengthInBytes > 10 * 1024 * 1024) {
  //     selectedFileError.value = "File must be under 10 MB.";
  //     return;
  //   }

  //   // Extension check
  //   if (!(allowedExtensions[selectedMediaType.value] ?? []).contains(ext)) {
  //     selectedFileError.value =
  //         "Invalid file format for ${selectedMediaType.value}.";
  //     return;
  //   }

  //   selectedFileBytes.value = bytes;
  //   selectedFileName.value = name;

  //   await _uploadMediaToInterakt();
  // }

  // Future<void> _uploadMediaToInterakt() async {
  //   if (selectedFileBytes.value == null) return;

  //   isUploadingMedia.value = true;
  //   mediaHandleId.value = "";

  //   final mime = _getMimeFromExtension(selectedFileName.value);

  //   final result = await TemplateService.instance.uploadMediaToInterakt(
  //     fileBytes: selectedFileBytes.value!,
  //     fileName: selectedFileName.value,
  //     mimeType: mime,
  //   );

  //   isUploadingMedia.value = false;

  //   if (result["success"] == true) {
  //     mediaHandleId.value = result["media_handle_id"];
  //   } else {
  //     selectedFileError.value = "Failed to upload media.";
  //   }
  // }

  // String _getMimeFromExtension(String fileName) {
  //   final ext = fileName.split('.').last.toLowerCase();
  //   switch (ext) {
  //     case "jpg":
  //     case "jpeg":
  //       return "image/jpeg";
  //     case "png":
  //       return "image/png";
  //     case "mp4":
  //       return "video/mp4";
  //     case "3gp":
  //       return "video/3gpp";
  //     case "txt":
  //       return "text/plain";
  //     case "pdf":
  //       return "application/pdf";
  //     case "doc":
  //       return "application/msword";
  //     case "docx":
  //       return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  //     case "ppt":
  //       return "application/vnd.ms-powerpoint";
  //     case "pptx":
  //       return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
  //     case "xls":
  //       return "application/vnd.ms-excel";
  //     case "xlsx":
  //       return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  //     default:
  //       return "application/octet-stream";
  //   }
  // }

  // ===========================================================================
  // 🟦 NORMALIZE HELPERS
  // ===========================================================================
  String normalizeCategory(String value) {
    switch (value.toLowerCase()) {
      case "marketing":
        return "Marketing";
      case "utility":
        return "Utility";
      default:
        return "";
    }
  }

  String normalizeType(String value) {
    value = value.toLowerCase();
    if (value.contains("interactive")) return "Interactive";
    if (value.contains("media")) return "Text & Media";
    return "Text";
  }

  static String _normalizeHeaderFormat(String? raw) {
    final v = raw?.toUpperCase() ?? "";
    switch (v) {
      case "IMAGE":
        return "Image";
      case "VIDEO":
        return "Video";
      case "DOCUMENT":
        return "Document";
      case "TEXT":
        return "";
      default:
        return "";
    }
  }

  // ===========================================================================
  // 🟦 LOAD TEMPLATE FOR COPY
  // ===========================================================================
  Future<void> loadTemplateForCopy(TemplateModels template) async {
    isEditMode.value = false;
    isCopyMode.value = true;

    // RESET NAME (user must enter new)
    nameCtrl.text = "";
    templateName.value = "";

    // CATEGORY / LANGUAGE / TYPE
    templateCategory.value = normalizeCategory(template.category!);
    templateLanguage.value = template.language;
    templateType.value = normalizeType(template.type);

    // BODY
    formatCtrl.text = template.body;
    templateFormat.value = template.body;

    // HEADER + FOOTER
    headerCtrl.text = template.headerText ?? "";
    templateHeader.value = template.headerText ?? "";

    footerCtrl.text = template.footer ?? "";
    templateFooter.value = template.footer ?? "";

    // MEDIA TYPE (IMAGE / VIDEO / DOCUMENT)
    selectedMediaType.value = _normalizeHeaderFormat(template.headerFormat);
    // Clear any previous uploaded media
    selectedFileBytes.value = null;
    selectedFileName.value = "";
    mediaHandleId.value = "";

    // APPLY BODY FORMAT → auto-detect variables
    updateTemplateFormat(template.body);

    // COPY SAMPLE VARIABLE VALUES
    if (template.variables.isNotEmpty) {
      for (int i = 0; i < variableControllers.length; i++) {
        if (i < template.variables.length) {
          variableControllers[i].text = template.variables[i];
        }
      }
    }

    // ===============================
    // CLEAR ALL OLD DATA
    // ===============================
    buttons.clear();
    btnTextCtrls.clear();
    btnValueCtrls.clear();
    btnTextErrors.clear();
    btnValueErrors.clear();
    urlType.clear();
    dynamicValueCtrl.clear();

    // ===============================
    // COPY BUTTONS FROM TEMPLATE
    // ===============================
    for (final btn in template.buttons) {
      // ===============================
      // URL BUTTON (STATIC / DYNAMIC)
      // ===============================
      if (btn.type == "URL") {
        final hasExample = btn.example != null && btn.example!.isNotEmpty;
        final hasUrl = btn.url != null && btn.url!.isNotEmpty;

        // 🔥 KEY FIX: Check if URL contains {{1}} placeholder
        final isDynamic = hasUrl && btn.url!.contains("{{1}}");

        if (isDynamic && hasExample) {
          // DYNAMIC URL
          urlType.add("Dynamic");

          // Remove {{1}} from URL to get the pattern
          final urlPattern = btn.url!.replaceAll("{{1}}", "").trim();

          // Extract dynamic value from example
          final example = btn.example!.first;
          String dynamicValue = "";

          if (example.startsWith(urlPattern)) {
            dynamicValue = example.substring(urlPattern.length);
            // Remove leading slash if present
            if (dynamicValue.startsWith("/")) {
              dynamicValue = dynamicValue.substring(1);
            }
          } else if (example.contains("/")) {
            // Fallback: take last part after /
            dynamicValue = example.split("/").last;
          }

          // Add button with correct structure
          buttons.add(
            InteractiveButton(
              type: btn.type,
              text: btn.text,
              url: btn.url, // Keep original URL with {{1}}
              example: [example], // Keep original example
              phoneNumber: '',
            ),
          );

          // Set controllers
          btnTextCtrls.add(TextEditingController(text: btn.text));
          btnValueCtrls.add(TextEditingController(text: urlPattern));
          dynamicValueCtrl.add(TextEditingController(text: dynamicValue));
        } else {
          // STATIC URL
          urlType.add("Static");

          buttons.add(
            InteractiveButton(
              type: btn.type,
              text: btn.text,
              url: btn.url ?? '',
              example: [],
              phoneNumber: '',
            ),
          );

          btnTextCtrls.add(TextEditingController(text: btn.text));
          btnValueCtrls.add(TextEditingController(text: btn.url ?? ""));
          dynamicValueCtrl.add(TextEditingController());
        }

        btnTextErrors.add("");
        btnValueErrors.add("");
      }
      // ===============================
      // PHONE NUMBER
      // ===============================
      else if (btn.type == "PHONE_NUMBER") {
        buttons.add(
          InteractiveButton(
            type: btn.type,
            text: btn.text,
            url: '',
            example: [],
            phoneNumber: btn.phoneNumber ?? '',
          ),
        );

        btnTextCtrls.add(TextEditingController(text: btn.text));
        btnValueCtrls.add(TextEditingController());
        urlType.add(""); // maintain index
        dynamicValueCtrl.add(TextEditingController());
        btnTextErrors.add("");
        btnValueErrors.add("");
      }
      // ===============================
      // COPY CODE
      // ===============================
      else if (btn.type == "COPY_CODE") {
        final copyCodeValue = btn.example?.isNotEmpty == true
            ? btn.example!.first
            : "";

        buttons.add(
          InteractiveButton(
            type: btn.type,
            text: '',
            url: '',
            example: btn.example != null ? List.from(btn.example!) : [],
            phoneNumber: '',
          ),
        );

        btnTextCtrls.add(TextEditingController(text: ''));
        btnValueCtrls.add(TextEditingController(text: copyCodeValue));
        urlType.add("");
        dynamicValueCtrl.add(TextEditingController());
        btnTextErrors.add("");
        btnValueErrors.add("");
      }
      // ===============================
      // QUICK REPLY
      // ===============================
      else if (btn.type == "QUICK_REPLY") {
        buttons.add(
          InteractiveButton(
            type: btn.type,
            text: btn.text,
            url: '',
            example: [],
            phoneNumber: '',
          ),
        );

        btnTextCtrls.add(TextEditingController(text: btn.text));
        btnValueCtrls.add(TextEditingController());
        urlType.add("");
        dynamicValueCtrl.add(TextEditingController());
        btnTextErrors.add("");
        btnValueErrors.add("");
      }
      // ===============================
      // OTHER TYPES
      // ===============================
      else {
        buttons.add(
          InteractiveButton(
            type: btn.type,
            text: btn.text,
            url: '',
            example: [],
            phoneNumber: '',
          ),
        );

        btnTextCtrls.add(TextEditingController(text: btn.text));
        btnValueCtrls.add(TextEditingController());
        urlType.add("");
        dynamicValueCtrl.add(TextEditingController());
        btnTextErrors.add("");
        btnValueErrors.add("");
      }
    }

    // Reset counters properly
    quickRepliesCount.value =
        10 - buttons.where((b) => b.type == "QUICK_REPLY").length;

    urlCount.value = 2 - buttons.where((b) => b.type == "URL").length;

    phoneNumberCount.value =
        1 - buttons.where((b) => b.type == "PHONE_NUMBER").length;

    copyCodeCount.value =
        1 - buttons.where((b) => b.type == "COPY_CODE").length;
  }

  // ===========================================================================
  // 🟦 VALIDATIONS
  // ===========================================================================
  Future<bool> validateTemplateName({bool requestFocus = false}) async {
    final name = nameCtrl.text.trim();

    if (name.isEmpty) {
      nameError.value = "Template name is required";
      if (requestFocus) nameFocus.requestFocus();
      return false;
    }

    final regex = RegExp(r'^[a-z0-9_]+$');
    if (!regex.hasMatch(name)) {
      nameError.value = "Only lowercase letters, numbers & underscores allowed";
      if (requestFocus) nameFocus.requestFocus();
      return false;
    }

    nameError.value = "";
    return true;
  }

  bool validateHeader({bool requestFocus = false}) {
    final value = headerCtrl.text.trim();
    if (value.length > maxFooterChars) {
      headerError.value = "Header must be under 60 characters";
      if (requestFocus) headerFocus.requestFocus();
      return false;
    }
    headerError.value = "";
    return true;
  }

  bool validateFooter({bool requestFocus = false}) {
    final value = footerCtrl.text.trim();
    if (value.length > maxFooterChars) {
      footerError.value = "Footer must be under 60 characters";
      if (requestFocus) footerFocus.requestFocus();
      return false;
    }
    footerError.value = "";
    return true;
  }

  // ===========================================================================
  // 🟦 VARIABLE DETECTION
  // ===========================================================================
  void updateTemplateFormat(String value) {
    templateFormat.value = value;
    formatCharCount.value = value.length;
    _updateVariableFields(value);
  }

  void _updateVariableFields(String text) {
    final regex = RegExp(r'{{(\d+)}}');
    final matches = regex.allMatches(text);

    final detectedVars =
        matches.map((e) => int.parse(e.group(1)!)).toSet().toList()..sort();

    final needed = detectedVars.length;

    while (variableControllers.length < needed) {
      final c = TextEditingController();
      c.addListener(() => previewRefresh.value++);
      variableControllers.add(c);
    }

    while (variableControllers.length > needed) {
      variableControllers.removeLast().dispose();
    }

    while (sampleValueErrors.length < needed) sampleValueErrors.add("");
    while (sampleValueErrors.length > needed) sampleValueErrors.removeLast();

    previewRefresh.value++;
  }

  // ===========================================================================
  // 🟦 DROPDOWN UPDATERS
  // ===========================================================================
  void updateTemplateCategory(String? v) {
    if (v != null) templateCategory.value = v;
  }

  void updateTemplateLanguage(String? v) {
    if (v != null) templateLanguage.value = v;
  }

  void updateTemplateType(String? v) {
    if (v != null) templateType.value = v;
    headerCtrl.clear();
    templateHeader.value = '';
    selectedFileBytes.value = null;
    selectedFileName.value = "";
    mediaHandleId.value = "";
    buttons.value = [];
    quickRepliesCount.value = 10;
    urlCount.value = 2;
    phoneNumberCount.value = 1;
    copyCodeCount.value = 1;
    buttons.clear();
    btnTextCtrls.clear();
    btnValueCtrls.clear();
    btnTextErrors.clear();
    btnValueErrors.clear();
    urlType.clear();
    dynamicValueCtrl.clear();
  }

  // ===========================================================================
  // 🟦 API ERROR HANDLER
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
        // formatError.value =
        //     'Template format is required. Please enter a message in the template format field.';
        // Utilities.showSnackbar(SnackType.ERROR, formatError.value);

        break;
      case 2388050:
        // BUTTON MISSING FIELDS ERROR
        _handleButtonMissingFields(errorMsg);
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

        // if (!isEditMode.value && !isCopyMode.value) {
        //   languageError.value =
        //       "A template with this name already exists in this language.\nPlease choose a different language.";
        // } else {
        //   languageError.value = errorMsg;
        // }
        nameError.value =
            "A template with this name already exists. Please change template name.";

        Utilities.showSnackbar(SnackType.ERROR, "Template name already exist.");
        break;

      default:
        Utilities.showSnackbar(SnackType.ERROR, errorMsg);
    }
  }

  void _handleButtonMissingFields(String errorMsg) {
    // Clear old errors
    btnTextErrors.value = List.generate(buttons.length, (_) => "");
    btnValueErrors.value = List.generate(buttons.length, (_) => "");

    for (int i = 0; i < buttons.length; i++) {
      final btn = buttons[i];
      final text = btnTextCtrls[i].text.trim();
      final value = btnValueCtrls[i].text.trim();

      if (btn.type == "URL") {
        if (text.isEmpty) {
          btnTextErrors[i] = "Button text is required";
        }
        if (value.isEmpty) {
          btnValueErrors[i] = "URL is required";
        }
      }

      if (btn.type == "PHONE_NUMBER") {
        if (text.isEmpty) {
          btnTextErrors[i] = "Button text is required";
        }
        if (value.isEmpty) {
          btnValueErrors[i] = "Phone number is required";
        }
      }

      if (btn.type == "COPY_CODE") {
        // value = code is required
        if (value.isEmpty) {
          btnValueErrors[i] = "Code value is required";
        }
      }

      if (btn.type == "QUICK_REPLY") {
        // only text required
        if (text.isEmpty) {
          btnTextErrors[i] = "Button text is required";
        }
      }
    }

    Utilities.showSnackbar(
      SnackType.ERROR,
      "Some buttons are missing required fields.",
    );
  }

  // ===========================================================================
  // 🟦 SUBMIT FORM
  // ===========================================================================
  Future<bool> validateForm() async {
    if (templateCategory.value.isEmpty ||
        templateCategory.value == "Select message categories") {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Please select a template category",
      );
      return false;
    }

    if (templateLanguage.value.isEmpty ||
        templateLanguage.value == "Select message language") {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Please select a template language",
      );
      return false;
    }

    if (!await validateTemplateName(requestFocus: true)) return false;
    if (templateType.value.isEmpty) {
      Utilities.showSnackbar(SnackType.ERROR, "Please select a template type");
      return false;
    }

    if (!validateHeader(requestFocus: true)) return false;
    if (!validateFooter(requestFocus: true)) return false;

    if (templateFormat.value.isEmpty) {
      formatError.value = 'Template format is required.';
      return false;
    }

    // Media validations
    if (templateType.value == "Text & Media") {
      if (selectedMediaType.value.isEmpty) {
        Utilities.showSnackbar(SnackType.ERROR, "Please select a media type");
        return false;
      }

      if (selectedFileBytes.value != null && mediaHandleId.value.isEmpty) {
        Utilities.showSnackbar(
          SnackType.INFO,
          "Wait... Upload is still in progress",
        );
        return false;
      }

      if (selectedFileBytes.value == null && mediaHandleId.value.isEmpty) {
        selectedFileError.value = "Please upload a media file";
        Utilities.showSnackbar(SnackType.ERROR, "Please upload a media file");
        return false;
      }
    }
    if (templateType.value == "Interactive" &&
        selectedMediaType.value.isNotEmpty) {
      if (selectedFileBytes.value != null && mediaHandleId.value.isEmpty) {
        Utilities.showSnackbar(
          SnackType.INFO,
          "Wait... Upload is still in progress",
        );
        return false;
      }

      if (selectedFileBytes.value == null && mediaHandleId.value.isEmpty) {
        selectedFileError.value = "Please upload a media file";
        Utilities.showSnackbar(SnackType.ERROR, "Please upload a media file");
        return false;
      }
    }
    if (buttons.isNotEmpty) {
      final isButtonValidate = validateButtons();
      //print('isButtonValidate: $isButtonValidate');
      if (!isButtonValidate) return false;
    }
    return true;
  }

  void submitTemplate() async {
    final isValid = await validateForm();
    //print("isValid: $isValid");
    if (!isValid) return;

    isSubmitting.value = true;
    try {
      // if (isEditMode.value) {
      //   _updateTemplate();
      // }
      await _createNewTemplate();
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===========================================================================
  // 🟦 CREATE NEW TEMPLATE
  // ===========================================================================
  Future<void> _createNewTemplate() async {
    final templateController = Get.find<TemplatesController>();
    Utilities.showOverlayLoadingDialog();

    final sampleVals = variableControllers.map((c) => c.text.trim()).toList();
   

    final response = await TemplateService.instance.createInteraktTemplate(
      name: nameCtrl.text.trim(),
      language: templateLanguage.value,
      category: templateCategory.value,
      body: formatCtrl.text.trim(),
      bodyExampleValues: sampleVals,
      header: headerCtrl.text.trim(),
      footer: footerCtrl.text.trim(),
      templateType: templateType.value,
      isTextMedia: templateType.value == typeOptions[1],
      mediaHandleId: mediaHandleId.value,
      mediaType: selectedMediaType.value,
      buttons: buttons,
    );

    if (response["success"] == true) {
      final data = response["data"];
      if (data['status'] == "REJECTED") {
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Your template was rejected by Meta.",
        );
      } else if (data['status'] == "APPROVED") {
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          "Template Approved Successfully",
        );
      } else {
        Utilities.showSnackbar(SnackType.INFO, "Template Submitted for Review");
      }
      final template = TemplateModels(
        id: data["id"].toString(),
        name: nameCtrl.text.trim(),
        category: data["category"] ?? "",
        language: templateLanguage.value,
        type: templateType.value,
        userCategory: templateCategory.value,
        status: data["status"] ?? "",
        headerText:
            (selectedMediaType.value.isNotEmpty && headerCtrl.text.isEmpty)
            ? null
            : headerCtrl.text.trim(),
        body: formatCtrl.text.trim(),
        footer: footerCtrl.text.isEmpty ? null : footerCtrl.text.trim(),
        variables: sampleVals,
        createdAt: DateTime.now(),
        // headerImage: '',
        headerFormat: selectedMediaType.value,
        headerVariables: [],
        buttons: buttons,
      );

      await TemplateFirestoreService.instance.saveTemplate(template);

      resetForm();
      Utilities.hideCustomLoader(Get.context!);

      Get.offNamed(Routes.TEMPLATES);

      // Update navigation controller state for mobile compatibility
      final navController = Get.find<NavigationController>();
      navController.currentRoute.value = Routes.TEMPLATES;
      navController.selectedIndex.value = 3; // Templates index
      navController.routeTrigger.value++;

      templateController.loadInitialTemplates();
    } else {
      Utilities.hideCustomLoader(Get.context!);
      handleApiError(response["message"]["error"]);
    }
  }

  // ===========================================================================
  // 🟦 UPDATE TEMPLATE (EDIT MODE) — *Commented edit code kept intact*
  // ===========================================================================
  /*
  void loadTemplateForEdit(TemplateModels template) {
    isEditMode.value = true;
    isCopyMode.value = false;
    editingTemplate = template;

    nameCtrl.text = template.name;
    templateCategory.value = normalizeCategory(template.category);
    templateLanguage.value = template.language;
    templateType.value = normalizeType(template.type);

    formatCtrl.text = template.body;
    templateFormat.value = template.body;

    headerCtrl.text = template.header;
    templateHeader.value = template.header;

    footerCtrl.text = template.footer;
    templateFooter.value = template.footer;

    updateTemplateFormat(template.body);

    if (template.variables.isNotEmpty) {
      for (int i = 0; i < variableControllers.length; i++) {
        if (i < template.variables.length) {
          variableControllers[i].text = template.variables[i];
        }
      }
    }
  }
  */

  // Placeholder for future update logic
  // Future<void> _updateTemplate() async { ... }

  // ===========================================================================
  // 🟦 RESET FORM
  // ===========================================================================
  void resetForm() {
    templateCategory.value = "";
    templateLanguage.value = "";
    templateType.value = "";

    nameCtrl.clear();
    headerCtrl.clear();
    footerCtrl.clear();
    formatCtrl.clear();
    buttons.clear();
    btnTextCtrls.clear();
    btnValueCtrls.clear();
    btnTextErrors.clear();
    btnValueErrors.clear();
    urlType.clear();
    dynamicValueCtrl.clear();
    quickRepliesCount.value = 10;
    urlCount.value = 2;
    phoneNumberCount.value = 1;
    copyCodeCount.value = 1;
    templateName.value = "";
    templateHeader.value = "";
    templateFooter.value = "";
    templateFormat.value = "";
    nameError.value = '';
    languageError.value = '';
    formatError.value = '';
    headerError.value = '';
    footerError.value = '';

    for (var c in variableControllers) c.dispose();
    variableControllers.clear();
    sampleValueErrors.clear();
    previewRefresh.value++;

    selectedMediaType.value = "";
    selectedFileName.value = "";
    selectedFileError.value = "";
    selectedFileBytes.value = null;
    mediaHandleId.value = "";
    isUploadingMedia.value = false;
  }

  // ===========================================================================
  // 🟦 INTERACTIVE TEMPLATE ACTIONS
  // ===========================================================================
  void updateInteractiveAction(String value) => interactiveAction.value = value;

  void addQuickReply() {
    if (quickRepliesCount.value > 0) {
      buttons.add(InteractiveButton(type: "QUICK_REPLY", text: ""));
      btnTextCtrls.add(TextEditingController());
      btnValueCtrls.add(TextEditingController());

      urlType.add(""); // KEEP INDEX ALIGNMENT
      dynamicValueCtrl.add(TextEditingController());

      btnTextErrors.add("");
      btnValueErrors.add("");

      quickRepliesCount.value--;
    }
  }

  void addUrl() {
    if (urlCount.value > 0) {
      buttons.add(
        InteractiveButton(
          type: "URL",
          text: "",
          url: "",
          example: [], // will be updated later
        ),
      );

      btnTextCtrls.add(TextEditingController());
      btnValueCtrls.add(TextEditingController());

      urlType.add("Static");
      dynamicValueCtrl.add(TextEditingController());

      btnTextErrors.add("");
      btnValueErrors.add("");

      urlCount.value--;
    }
  }

  void addPhoneNumber() {
    if (phoneNumberCount.value > 0) {
      buttons.add(
        InteractiveButton(type: "PHONE_NUMBER", text: "", phoneNumber: ""),
      );

      btnTextCtrls.add(TextEditingController());
      btnValueCtrls.add(TextEditingController());

      urlType.add(""); // Maintain index
      dynamicValueCtrl.add(TextEditingController());

      btnTextErrors.add("");
      btnValueErrors.add("");

      phoneNumberCount.value--;
    }
  }

  void addCopyCode() {
    if (copyCodeCount.value > 0) {
      buttons.add(InteractiveButton(type: "COPY_CODE", text: "", example: []));

      btnTextCtrls.add(TextEditingController());
      btnValueCtrls.add(TextEditingController());

      urlType.add(""); // Important
      dynamicValueCtrl.add(TextEditingController());

      btnTextErrors.add("");
      btnValueErrors.add("");

      copyCodeCount.value--;
    }
  }

  void setTextError(int index, String message) {
    if (index < btnTextErrors.length) btnTextErrors[index] = message;
    btnTextErrors.refresh(); // 🔥 REQUIRED
  }

  void setValueError(int index, String msg) {
    if (index < btnValueErrors.length) btnValueErrors[index] = msg;
    btnValueErrors.refresh();
  }

  // ===========================================================================
  // 🟦 CANCEL CREATION
  // ===========================================================================
  void cancelCreation() {
    //print("Previous Route: ${Get.previousRoute}");
    Get.offNamed(Routes.TEMPLATES);

    // Update navigation controller state for mobile compatibility
    final navController = Get.find<NavigationController>();
    navController.currentRoute.value = Routes.TEMPLATES;
    navController.selectedIndex.value = 3; // Templates index
    navController.routeTrigger.value++;
  }

  bool validateButtons() {
    bool valid = true;

    for (int i = 0; i < buttons.length; i++) {
      final btn = buttons[i];

      // ---------------------------------------
      // URL VALIDATION
      // ---------------------------------------
      if (btn.type == "URL") {
        if (btn.url == null || btn.url!.trim().isEmpty) {
          setValueError(i, "Required");
          valid = false;
        }

        if (urlType[i] == "Dynamic") {
          if (btn.example == null || btn.example!.isEmpty) {
            setValueError(i, "Dynamic value required");
            valid = false;
          }
        }
      }

      // ---------------------------------------
      // PHONE VALIDATION
      // ---------------------------------------
      if (btn.type == "PHONE_NUMBER") {
        if (btn.phoneNumber == null || btn.phoneNumber!.trim().isEmpty) {
          setValueError(i, "Required");
          valid = false;
        }
      }

      // ---------------------------------------
      // COPY_CODE VALIDATION
      // ---------------------------------------
      if (btn.type == "COPY_CODE") {
        if (btn.example == null ||
            btn.example!.isEmpty ||
            btn.example!.first.trim().isEmpty) {
          setValueError(i, "Required");
          valid = false;
        }
      }

      // ---------------------------------------
      // TEXT VALIDATION (SKIP for COPY_CODE)
      // ---------------------------------------
      if (btn.type != "COPY_CODE") {
        if (btn.text.trim().isEmpty) {
          setTextError(i, "Required");
          valid = false;
        }
      }
    }

    return valid;
  }

  void clearButtonError(
    int index, {
    bool isText = false,
    bool isValue = false,
  }) {
    if (isText) {
      btnTextErrors[index] = "";
      btnTextErrors.refresh(); // 🔥
    }
    if (isValue) {
      btnValueErrors[index] = "";
      btnValueErrors.refresh(); // 🔥
    }
  }

  String sanitizeUrl(String url) {
    // Keep https:// intact
    return url.replaceAllMapped(RegExp(r'(?<!:)//+'), (match) => '/');
  }
}
