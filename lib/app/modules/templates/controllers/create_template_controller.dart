import 'dart:typed_data';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import 'package:business_whatsapp/app/Utilities/media_utils.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:business_whatsapp/app/data/models/interactive_model.dart';
// import 'package:business_whatsapp/app/core/utils/utilities.dart';
import 'package:business_whatsapp/app/data/models/template_model.dart';
import 'package:business_whatsapp/app/data/services/template_firebase_service.dart';
import 'package:business_whatsapp/app/data/services/template_service.dart';
import 'package:business_whatsapp/app/modules/templates/controllers/templates_controller.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/Utilities/whatsapp_text_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/carousel_card_model.dart';
import '../../../common widgets/common_snackbar.dart';
import '../utils/demo_template_assets.dart';

class CreateTemplateController extends GetxController {
  // MARK: - Properties
  web.EventListener? _beforeUnloadListener;
  // ===========================================================================
  // FORM CONTROLLERS
  // ===========================================================================
  TextEditingController nameCtrl = TextEditingController();
  WhatsAppTextEditingController formatCtrl = WhatsAppTextEditingController();
  TextEditingController headerCtrl = TextEditingController();
  TextEditingController footerCtrl = TextEditingController();
  TextEditingController searchCtrl = TextEditingController();

  FocusNode nameFocus = FocusNode();
  FocusNode formatFocus = FocusNode();
  FocusNode headerFocus = FocusNode();
  FocusNode footerFocus = FocusNode();

  // ===========================================================================
  // RX FORM VALUES
  // ===========================================================================
  final RxString templateCategory = ''.obs;
  final RxString templateLanguage = 'en'.obs;
  final RxString templateType = ''.obs;

  final RxString templateName = ''.obs;
  final RxString templateFormat = ''.obs;
  final RxString templateHeader = ''.obs;
  final RxString templateFooter = ''.obs;

  final RxString templateVersion = 'v2'.obs;
  final RxInt previewRefresh = 0.obs;
  final RxInt q1Selection = (-1).obs;
  final RxInt q2Selection = (-1).obs;

  // ===========================================================================
  // MEDIA (Upload, Validation)
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
  // MODES (Edit / Copy)
  // ===========================================================================
  final RxBool isEditMode = false.obs;
  final RxBool isCopyMode = false.obs;
  final RxBool isViewMode = false.obs;
  TemplateModels? editingTemplate;
  final RxBool ctaUrlLinkTrackingOptedOut = true.obs;

  // ===========================================================================
  // ACTION COUNTERS
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
  // CAROUSEL
  // ===========================================================================
  final RxList<CarouselCard> carouselCards = <CarouselCard>[].obs;
  final RxInt selectedCardIndex = 0.obs;
  WhatsAppTextEditingController cardFormatCtrl =
      WhatsAppTextEditingController();
  ScrollController carouselScrollCtrl = ScrollController();

  // ===========================================================================
  // ERRORS
  // ===========================================================================
  final RxString nameError = ''.obs;
  final RxString languageError = ''.obs;
  final RxString formatError = ''.obs;
  final RxString headerError = ''.obs;
  final RxString footerError = ''.obs;
  final RxBool isCheckingName = false.obs;
  final RxBool isSubmitting = false.obs;

  // ===========================================================================
  // VARIABLE SAMPLE VALUE FIELDS
  // ===========================================================================
  RxList<TextEditingController> variableControllers =
      <TextEditingController>[].obs;
  RxList<String> sampleValueErrors = <String>[].obs;

  // ===========================================================================
  // LIMITS
  // ===========================================================================
  final RxInt formatCharCount = 0.obs;
  final int maxFormatChars = 1024;
  final int maxFooterChars = 60;

  // ===========================================================================
  // DROPDOWNS
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

  // MARK: - Lifecycle
  @override
  void onInit() {
    super.onInit();

    _attachListeners();

    // Initially start with everything unselected and empty

    // Handle browser refresh/close
    if (GetPlatform.isWeb) {
      _beforeUnloadListener = ((web.Event event) {
        if (!isFormBlank) {
          (event as web.BeforeUnloadEvent).returnValue =
              'You have unsaved changes.';
        }
      }).toJS;
      web.window.addEventListener('beforeunload', _beforeUnloadListener);
    }
  }

  void ensureControllersActive() {
    bool anyDisposed = false;
    try {
      void noop() {}
      nameCtrl.addListener(noop);
      nameCtrl.removeListener(noop);
      formatCtrl.addListener(noop);
      formatCtrl.removeListener(noop);
      headerCtrl.addListener(noop);
      headerCtrl.removeListener(noop);
      footerCtrl.addListener(noop);
      footerCtrl.removeListener(noop);
      searchCtrl.addListener(noop);
      searchCtrl.removeListener(noop);
      cardFormatCtrl.addListener(noop);
      cardFormatCtrl.removeListener(noop);
      nameFocus.addListener(noop);
      nameFocus.removeListener(noop);
      formatFocus.addListener(noop);
      formatFocus.removeListener(noop);
      headerFocus.addListener(noop);
      headerFocus.removeListener(noop);
      footerFocus.addListener(noop);
      footerFocus.removeListener(noop);
    } catch (_) {
      anyDisposed = true;
    }

    if (anyDisposed) {
      nameCtrl = TextEditingController();
      formatCtrl = WhatsAppTextEditingController();
      headerCtrl = TextEditingController();
      footerCtrl = TextEditingController();
      searchCtrl = TextEditingController();
      nameFocus = FocusNode();
      formatFocus = FocusNode();
      headerFocus = FocusNode();
      footerFocus = FocusNode();
      cardFormatCtrl = WhatsAppTextEditingController();
      carouselScrollCtrl = ScrollController();
      _attachListeners();
    }
  }

  void _attachListeners() {
    nameCtrl.addListener(() => templateName.value = nameCtrl.text);
    formatCtrl.addListener(() => updateTemplateFormat(formatCtrl.text));
    headerCtrl.addListener(() => templateHeader.value = headerCtrl.text);
    footerCtrl.addListener(() => templateFooter.value = footerCtrl.text);

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
  // MEDIA HANDLING
  // ===========================================================================\

  // MARK: - Media & File Handling
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
  // NORMALIZE HELPERS
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
    if (value.contains("carousel")) return "Carousel";
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

  // MARK: - Copy & View Modes
  Future<void> loadTemplateForCopy(TemplateModels template) async {
    ensureControllersActive();
    isEditMode.value = false;
    isCopyMode.value = true;
    isViewMode.value = false;

    // RESET NAME (user must enter new)
    nameCtrl.text = "";
    templateName.value = "";

    // CATEGORY / LANGUAGE / TYPE
    templateCategory.value = normalizeCategory(template.category!);
    templateLanguage.value = template.language;
    templateType.value = normalizeType(template.type);
    templateVersion.value = template.version!;
    ctaUrlLinkTrackingOptedOut.value = template.ctaUrlLinkTrackingOptedOut!;

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

    // APPLY BODY FORMAT -> auto-detect variables
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

        // KEY FIX: Check if URL contains {{1}} placeholder
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

    // ===============================
    // COPY CAROUSEL CARDS
    // ===============================
    carouselCards.clear();
    if (template.type == 'Carousel' && template.cards != null) {
      for (final cardMap in template.cards!) {
        final card = CarouselCard();
        final components = cardMap["components"] as List? ?? [];

        for (final comp in components) {
          final type = comp["type"] as String?;
          if (type == "HEADER") {
            card.mediaType.value = normalizeMediaType(
              comp["format"] ?? "IMAGE",
            );
            // If there's an example handle, we could use it, but usually we just need the format
          } else if (type == "BODY") {
            final text = comp["text"] ?? "";
            card.body.value = text;
            card.originalBody.value = text;
            _updateCardVariableFields(card, text);

            // Populate sample values if present
            if (comp["example"]?["body_text"] != null) {
              final bodyText = comp["example"]["body_text"];
              if (bodyText is List && bodyText.isNotEmpty) {
                final vars = List<String>.from(bodyText[0] ?? []);
                for (int i = 0; i < card.variableControllers.length; i++) {
                  if (i < vars.length) {
                    card.variableControllers[i].text = vars[i];
                  }
                }
              }
            }
          } else if (type == "BUTTONS") {
            final cardButtons = comp["buttons"] as List? ?? [];
            card.buttons.assignAll(
              cardButtons.map((b) => InteractiveButton.fromJson(b)).toList(),
            );
          }
        }
        carouselCards.add(card);
      }
      if (carouselCards.isNotEmpty) {
        selectCarouselCard(0);
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

  Future<void> loadTemplateForView(TemplateModels template) async {
    await loadTemplateForCopy(template);
    isViewMode.value = true;
    isCopyMode.value = false;
    isEditMode.value = false;

    // Restore name since loadTemplateForCopy clears it
    nameCtrl.text = template.name;
    templateName.value = template.name;
  }

  String normalizeMediaType(String format) {
    format = format.toUpperCase();
    if (format == "VIDEO") return "Video";
    if (format == "DOCUMENT") return "Document";
    return "Image";
  }

  // MARK: - Form Validations
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
  // VARIABLE DETECTION
  // ===========================================================================
  // MARK: - Format & Category Sync
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

    // Update supporting lists FIRST (errors) so they are ready when variableControllers changes
    while (sampleValueErrors.length < needed) {
      sampleValueErrors.add("");
    }
    while (sampleValueErrors.length > needed) {
      sampleValueErrors.removeLast();
    }

    // Then update the trigger list
    while (variableControllers.length < needed) {
      final c = TextEditingController();
      c.addListener(() => previewRefresh.value++);
      variableControllers.add(c);
    }

    while (variableControllers.length > needed) {
      variableControllers.removeLast();
    }

    previewRefresh.value++;
  }

  // ===========================================================================
  // DROPDOWN UPDATERS
  // ===========================================================================
  void updateTemplateCategory(String? v) {
    if (v != null) {
      templateCategory.value = v;
      // If category is not Marketing, Carousel is not allowed
      if (v != 'Marketing' && templateType.value == 'Carousel') {
        updateTemplateType('Text');
      }
      if (q1Selection.value != -1) {
        if (v == 'Marketing') {
          q1Selection.value = 1;
        } else if (v == 'Utility') {
          if (q1Selection.value == 1) {
            q1Selection.value = 0;
          }
        }
      }
    }
  }

  void updateTemplateLanguage(String? v) {
    if (v != null) templateLanguage.value = v;
  }

  void updateTemplateType(String? v) {
    if (v == null) return;
    templateType.value = v;

    if (v == 'Carousel') {
      selectedCardIndex.value = 0;
      if (carouselCards.length < 2 ||
          carouselCards.any((c) => c.fileBytes.value == null)) {
        fillDemoCarouselCards();
      }
      if (q2Selection.value != -1) {
        q2Selection.value = 3;
      }
    } else {
      carouselCards.clear();
      selectedCardIndex.value = 0;
      if (carouselScrollCtrl.hasClients) {
        carouselScrollCtrl.dispose();
        carouselScrollCtrl = ScrollController();
      }

      if (v == 'Interactive') {
        selectedMediaType.value = '';
        selectedFileBytes.value = null;
        selectedFileName.value = "";
        mediaHandleId.value = "";
        if (q2Selection.value != -1) {
          q2Selection.value = 2;
        }
      } else if (v == 'Text & Media') {
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
        if (q2Selection.value != -1) {
          q2Selection.value = 1;
        }
      } else if (v == 'Text') {
        selectedMediaType.value = '';
        selectedFileBytes.value = null;
        selectedFileName.value = "";
        mediaHandleId.value = "";
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
        if (q2Selection.value != -1) {
          q2Selection.value = 0;
        }
      }
    }
    previewRefresh.value++;
  }

  // ===========================================================================
  // CAROUSEL METHODS
  // ===========================================================================
  // MARK: - Carousel Support
  void addCarouselCard() {
    if (carouselCards.length >= 10) return;
    final card = CarouselCard();
    card.mediaType.value = 'Image';
    carouselCards.add(card);
    selectedCardIndex.value = carouselCards.length - 1;
    _syncCardToControllers();

    // Auto-scroll to the end
    Future.delayed(const Duration(milliseconds: 100), () {
      if (carouselScrollCtrl.hasClients) {
        carouselScrollCtrl.animateTo(
          carouselScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    previewRefresh.value++;
  }

  void removeCarouselCard(int index) {
    if (carouselCards.length <= 1) return;

    // Adjust selectedCardIndex BEFORE removing so the UI never reads an
    // out-of-bounds position during the reactive rebuild.
    final newIndex = (index < selectedCardIndex.value)
        ? selectedCardIndex.value - 1
        : (selectedCardIndex.value >= carouselCards.length - 1)
        ? (carouselCards.length - 2).clamp(0, 9)
        : selectedCardIndex.value;

    // Temporarily clamp to 0 so no Obx reads an invalid index
    selectedCardIndex.value = 0;
    carouselCards.removeAt(index);
    // Now set the real intended index (list is already shorter)
    selectedCardIndex.value = newIndex.clamp(0, carouselCards.length - 1);
    _syncCardToControllers();
    previewRefresh.value++;
  }

  void selectCarouselCard(int index) {
    selectedCardIndex.value = index;
    _syncCardToControllers();
  }

  void _syncCardToControllers() {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    cardFormatCtrl.text = card.body.value;

    // We can also sync buttons if needed, but the view will handle it via Obx
  }

  void updateCardBody(String value) {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    card.body.value = value;
    _updateCardVariableFields(card, value);
  }

  void _updateCardVariableFields(CarouselCard card, String text) {
    final regex = RegExp(r'{{(\d+)}}');
    final matches = regex.allMatches(text);

    final detectedVars =
        matches.map((e) => int.parse(e.group(1)!)).toSet().toList()..sort();

    final needed = detectedVars.length;

    while (card.variableControllers.length < needed) {
      final c = TextEditingController();
      c.addListener(() => previewRefresh.value++);
      card.variableControllers.add(c);
    }

    while (card.variableControllers.length > needed) {
      card.variableControllers.removeLast();
    }

    while (card.sampleValueErrors.length < needed) {
      card.sampleValueErrors.add("");
    }
    while (card.sampleValueErrors.length > needed) {
      card.sampleValueErrors.removeLast();
    }

    previewRefresh.value++;
  }

  void updateCardMedia(String? type) {
    if (type == null || carouselCards.isEmpty) return;

    if (selectedCardIndex.value == 0) {
      // If we're updating the first card, update ALL cards to have the same media type
      for (var card in carouselCards) {
        if (card.mediaType.value != type) {
          card.mediaType.value = type;
          card.fileBytes.value = null;
          card.fileName.value = '';
          card.mediaHandleId.value = '';
        }
      }
    } else {
      // For other cards, just update the current one (though UI should disable this)
      final card = carouselCards[selectedCardIndex.value];
      if (card.mediaType.value != type) {
        card.mediaType.value = type;
        card.fileBytes.value = null;
        card.fileName.value = '';
        card.mediaHandleId.value = '';
      }
    }
    previewRefresh.value++;
  }

  Future<void> pickCardFile() async {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];

    final result = await MediaUtils.pickAndValidateFile(
      mediaType: card.mediaType.value,
      maxSizeMB: 10,
    );

    if (!result.success) {
      selectedFileError.value = result.error!;
      return;
    }

    card.fileBytes.value = result.bytes;
    card.fileName.value = result.fileName!;
    final mime = result.mimeType!;

    await uploadCardMedia(mime);
  }

  Future<void> uploadCardMedia(String mime) async {
    final card = carouselCards[selectedCardIndex.value];
    if (card.fileBytes.value == null) return;

    isUploadingMedia.value = true;

    final result = await TemplateService.instance.uploadMediaToInterakt(
      fileBytes: card.fileBytes.value!,
      fileName: card.fileName.value,
      mimeType: mime,
    );

    isUploadingMedia.value = false;

    if (result["success"] == true) {
      card.mediaHandleId.value = result["media_handle_id"];
    } else {
      selectedFileError.value = "Failed to upload media.";
    }
  }

  void addCardButton() {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    if (card.buttons.length >= 2) return;
    card.buttons.add(InteractiveButton(type: 'QUICK_REPLY', text: ''));
    card.countryCodes.add("+91");
    card.buttonTextErrors.add("");
    card.buttonValueErrors.add("");
    previewRefresh.value++;
  }

  void removeCardButton(int index) {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    if (index < card.buttons.length) {
      card.buttons.removeAt(index);
      card.countryCodes.removeAt(index);
      if (index < card.buttonTextErrors.length) {
        card.buttonTextErrors.removeAt(index);
      }
      if (index < card.buttonValueErrors.length) {
        card.buttonValueErrors.removeAt(index);
      }
      previewRefresh.value++;
    }
  }

  void updateCardButtonType(int index, String type) {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    if (index < card.buttons.length) {
      card.buttons[index] = card.buttons[index].copyWith(type: type);
      if (index < card.buttonValueErrors.length) {
        card.buttonValueErrors[index] = "";
      }
      previewRefresh.value++;
    }
  }

  void updateCardButtonText(int index, String text) {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    if (index < card.buttons.length) {
      card.buttons[index] = card.buttons[index].copyWith(text: text);
      if (index < card.buttonTextErrors.length) {
        card.buttonTextErrors[index] = "";
      }
      previewRefresh.value++;
    }
  }

  void updateCardButtonValue(int index, String value) {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    if (index < card.buttons.length) {
      final btn = card.buttons[index];
      if (index < card.buttonValueErrors.length) {
        card.buttonValueErrors[index] = "";
      }

      if (btn.type == 'URL') {
        // Real-time URL validation
        if (value.isNotEmpty && !value.startsWith("https://")) {
          if (index < card.buttonValueErrors.length) {
            card.buttonValueErrors[index] = "URL must start with https://";
          }
        }
        card.buttons[index] = btn.copyWith(url: value);
      } else if (btn.type == 'PHONE_NUMBER') {
        while (card.countryCodes.length <= index) {
          card.countryCodes.add("+91");
        }
        final countryCode = card.countryCodes[index];
        card.buttons[index] = btn.copyWith(phoneNumber: "$countryCode$value");
      }
      previewRefresh.value++;
    }
  }

  void updateCardPhoneCountryCode(int index, String code) {
    if (carouselCards.isEmpty) return;
    final card = carouselCards[selectedCardIndex.value];
    if (index < card.buttons.length) {
      while (card.countryCodes.length <= index) {
        card.countryCodes.add("+91");
      }
      final oldCode = card.countryCodes[index];
      card.countryCodes[index] = code;
      final btn = card.buttons[index];
      if (btn.type == 'PHONE_NUMBER') {
        String rawPhone = btn.phoneNumber ?? "";
        if (rawPhone.startsWith(oldCode)) {
          rawPhone = rawPhone.substring(oldCode.length);
        }
        card.buttons[index] = btn.copyWith(phoneNumber: "$code$rawPhone");
      }
      previewRefresh.value++;
    }
  }

  // ===========================================================================
  // API ERROR HANDLER
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
  // SUBMIT FORM
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

    if (templateFormat.value.isEmpty) {
      formatError.value = 'Template format is required.';
      return false;
    }

    if (templateType.value != "Carousel") {
      if (!validateHeader(requestFocus: true)) return false;
      if (!validateFooter(requestFocus: true)) return false;
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

    if (templateType.value == "Carousel") {
      if (!validateCarouselForm()) return false;
    } else {
      if (buttons.isNotEmpty) {
        final isButtonValidate = validateButtons();
        if (!isButtonValidate) return false;
      }
    }

    return true;
  }

  bool validateCarouselForm() {
    // 1. Card count validation
    if (carouselCards.length < 2) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Minimum 2 cards are required for Carousel.",
      );
      return false;
    }
    if (carouselCards.length > 10) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Maximum 10 cards are allowed for Carousel.",
      );
      return false;
    }

    final firstCard = carouselCards.first;
    final firstMediaType = firstCard.mediaType.value;
    final firstButtonsCount = firstCard.buttons.length;
    final firstButtonTypes = firstCard.buttons.map((b) => b.type).toList();

    for (int i = 0; i < carouselCards.length; i++) {
      final card = carouselCards[i];
      final cardNum = i + 1;

      // 2. Media Consistency and Presence
      if (card.mediaType.value != firstMediaType) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          "All cards must have the same media type as the first card ($firstMediaType). Check Card $cardNum.",
        );
        return false;
      }

      if (card.mediaHandleId.value.isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Media upload is required for Card $cardNum.",
        );
        return false;
      }

      // Body validation
      // if (card.body.value.trim().isEmpty) {
      //   Utilities.showSnackbar(
      //     SnackType.ERROR,
      //     "Message content is required for Card $cardNum.",
      //   );
      //   return false;
      // }

      // 3. Button Consistency and Validation
      if (card.buttons.length != firstButtonsCount) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          "All cards must have the same number of buttons. Check Card $cardNum.",
        );
        return false;
      }

      for (int j = 0; j < card.buttons.length; j++) {
        final btn = card.buttons[j];
        if (btn.type != firstButtonTypes[j]) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            "Button types must match across all cards. Check Button ${j + 1} in Card $cardNum.",
          );
          return false;
        }

        // Standard button field validation
        if (btn.type != 'COPY_CODE' && btn.text.trim().isEmpty) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            "Label is required for Button ${j + 1} in Card $cardNum.",
          );
          return false;
        }
        if (btn.type == 'URL') {
          if (btn.url == null || btn.url!.trim().isEmpty) {
            Utilities.showSnackbar(
              SnackType.ERROR,
              "URL is required for Button ${j + 1} in Card $cardNum.",
            );
            return false;
          }
          if (!btn.url!.startsWith("https://")) {
            Utilities.showSnackbar(
              SnackType.ERROR,
              "URL must start with https:// for Button ${j + 1} in Card $cardNum.",
            );
            return false;
          }
        }
        if (btn.type == 'PHONE_NUMBER' &&
            (btn.phoneNumber == null || btn.phoneNumber!.trim().isEmpty)) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            "Phone number is required for Button ${j + 1} in Card $cardNum.",
          );
          return false;
        }
      }

      // 4. Variable Sample Value Validation
      for (int k = 0; k < card.variableControllers.length; k++) {
        if (card.variableControllers[k].text.trim().isEmpty) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            "Sample value is required for variable {{${k + 1}}} in Card $cardNum.",
          );
          return false;
        }
      }
    }

    return true;
  }

  // MARK: - Template Creation & Submit
  void submitTemplate() async {
    final isValid = await validateForm();
    //print("isValid: $isValid");
    if (!isValid) return;

    isSubmitting.value = true;
    try {
      // If unchecked (opted out is true), use version 'v1'. If checked, use version 'v2'.
      templateVersion.value = ctaUrlLinkTrackingOptedOut.value ? 'v1' : 'v2';
      // if (isEditMode.value) {
      //   _updateTemplate();
      // }
      await _createNewTemplate();
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===========================================================================
  // CREATE NEW TEMPLATE
  // ===========================================================================
  Future<void> _createNewTemplate() async {
    final templateController = Get.find<TemplatesController>();
    Utilities.showOverlayLoadingDialog();

    final sampleVals = variableControllers.map((c) => c.text.trim()).toList();

    final apiCards = templateType.value == "Carousel"
        ? carouselCards
              .map(
                (card) => {
                  "mediaType": card.mediaType.value.toLowerCase(),
                  "media_handle_id": card.mediaHandleId.value,
                  "body": card.body.value,
                  "bodyExampleValues": card.variableControllers
                      .map((c) => c.text.trim())
                      .toList(),
                  "buttons": card.buttons.map((b) => b.toJson()).toList(),
                },
              )
              .toList()
        : null;

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
      cards: apiCards,
      version: templateVersion.value,
      ctaUrlLinkTrackingOptedOut: ctaUrlLinkTrackingOptedOut.value,
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
      final cardsJson = templateType.value == "Carousel"
          ? carouselCards
                .map(
                  (card) => {
                    "components": [
                      {
                        "type": "HEADER",
                        "format": card.mediaType.value.toUpperCase(),
                        "example": {
                          "header_handle": [card.mediaHandleId.value],
                        },
                      },
                      {
                        "type": "BODY",
                        "text": card.body.value,
                        "example": {
                          "body_text": card.variableControllers
                              .map((c) => c.text.trim())
                              .toList(),
                        },
                      },
                      {
                        "type": "BUTTONS",
                        "buttons": card.buttons.map((b) => b.toJson()).toList(),
                      },
                    ],
                  },
                )
                .toList()
          : null;

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
        cards: cardsJson,
        version: templateVersion.value,
        ctaUrlLinkTrackingOptedOut: ctaUrlLinkTrackingOptedOut.value,
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
  // UPDATE TEMPLATE (EDIT MODE) - *Commented edit code kept intact*
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
  // RESET FORM & DEMO PREFILL
  // ===========================================================================
  void resetForm({bool fillDemo = false}) {
    ensureControllersActive();

    templateCategory.value = "";
    templateLanguage.value = "en";
    templateType.value = "";
    q1Selection.value = -1;
    q2Selection.value = -1;
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
    templateVersion.value = "v2";
    nameError.value = '';
    languageError.value = '';
    formatError.value = '';
    headerError.value = '';
    footerError.value = '';

    variableControllers.clear();
    sampleValueErrors.clear();

    selectedMediaType.value = "";
    selectedFileName.value = "";
    selectedFileError.value = "";
    selectedFileBytes.value = null;
    mediaHandleId.value = "";
    isUploadingMedia.value = false;
    ctaUrlLinkTrackingOptedOut.value = true;

    // Carousel Reset
    selectedCardIndex.value = 0;
    carouselCards.clear();
    cardFormatCtrl.clear();

    if (fillDemo) {
      fillDemoData();
    }

    previewRefresh.value++;
  }

  void fillDemoButtons() {
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

    // 1. Quick Reply
    buttons.add(InteractiveButton(type: "QUICK_REPLY", text: "Interested"));
    btnTextCtrls.add(TextEditingController(text: "Interested"));
    btnValueCtrls.add(TextEditingController());
    urlType.add("");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    quickRepliesCount.value--;

    // 2. URL (Link)
    buttons.add(
      InteractiveButton(
        type: "URL",
        text: "Visit Website",
        url: "https://example.com/shop",
        example: [],
      ),
    );
    btnTextCtrls.add(TextEditingController(text: "Visit Website"));
    btnValueCtrls.add(TextEditingController(text: "https://example.com/shop"));
    urlType.add("Static");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    urlCount.value--;

    // 3. Phone Number
    phoneCountryCode.value = "+91";
    buttons.add(
      InteractiveButton(
        type: "PHONE_NUMBER",
        text: "Call Support",
        phoneNumber: "+919876543210",
      ),
    );
    btnTextCtrls.add(TextEditingController(text: "Call Support"));
    btnValueCtrls.add(TextEditingController(text: "9876543210"));
    urlType.add("");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    phoneNumberCount.value--;

    // 4. Copy Code
    buttons.add(
      InteractiveButton(
        type: "COPY_CODE",
        text: "Copy Coupon",
        example: ["SALE30"],
      ),
    );
    btnTextCtrls.add(TextEditingController(text: "Copy Coupon"));
    btnValueCtrls.add(TextEditingController(text: "SALE30"));
    urlType.add("");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    copyCodeCount.value--;

    previewRefresh.value++;
  }

  void fillDemoCarouselCards() {
    carouselCards.clear();

    // Card 1
    final card1 = CarouselCard();
    card1.mediaType.value = 'Image';
    card1.fileBytes.value = DemoTemplateAssets.shoesImage;
    card1.fileName.value = 'shoes.png';
    card1.body.value =
        'Explore our Special Offers, Premium sneakers for everyday style. Enjoy exclusive 40% discounts for a limited time!';
    card1.buttons.add(
      InteractiveButton(type: 'QUICK_REPLY', text: 'View Details'),
    );
    card1.countryCodes.add('+91');
    card1.buttonTextErrors.add('');
    card1.buttonValueErrors.add('');

    card1.buttons.add(
      InteractiveButton(
        type: 'URL',
        text: 'Shop Now',
        url: 'https://example.com/mens',
      ),
    );
    card1.countryCodes.add('+91');
    card1.buttonTextErrors.add('');
    card1.buttonValueErrors.add('');
    carouselCards.add(card1);

    // Card 2
    final card2 = CarouselCard();
    card2.mediaType.value = 'Image';
    card2.fileBytes.value = DemoTemplateAssets.bagsImage;
    card2.fileName.value = 'bags.png';
    card2.body.value =
        'Explore our Special Offers, Stylish and durable for work & travel.. Enjoy exclusive 40% discounts for a limited time!';
    card2.buttons.add(
      InteractiveButton(type: 'QUICK_REPLY', text: 'More Info'),
    );
    card2.countryCodes.add('+91');
    card2.buttonTextErrors.add('');
    card2.buttonValueErrors.add('');

    card2.buttons.add(
      InteractiveButton(
        type: 'URL',
        text: 'Order Now',
        url: 'https://example.com/womens',
      ),
    );
    card2.countryCodes.add('+91');
    card2.buttonTextErrors.add('');
    card2.buttonValueErrors.add('');
    carouselCards.add(card2);

    selectedCardIndex.value = 0;
    _syncCardToControllers();
    previewRefresh.value++;
  }

  void fillDemoMedia() {
    selectedMediaType.value = 'Image';
    selectedFileName.value = 'img_sale.png';
    selectedFileBytes.value = DemoTemplateAssets.saleImage;
    selectedFileError.value = '';
    previewRefresh.value++;

    DemoTemplateAssets.loadAssetBytes(DemoTemplateAssets.saleImagePath)
        .then((bytes) {
          selectedFileBytes.value = bytes;
          previewRefresh.value++;
        })
        .catchError((_) {});
  }

  void fillDemoData({String? forcedType}) {
    ensureControllersActive();

    templateCategory.value = 'Marketing';
    templateLanguage.value = 'en';

    templateName.value = 'demo_special_offer';
    nameCtrl.text = 'demo_special_offer';

    templateHeader.value = '';
    headerCtrl.clear();

    templateFooter.value = '';
    footerCtrl.clear();

    final demoBody =
        'Hello {{1}}, we are excited to share our exclusive {{2}} discount on all new arrivals! Grab your favorites before stock runs out.';
    formatCtrl.text = demoBody;
    updateTemplateFormat(demoBody);

    if (variableControllers.isNotEmpty) {
      variableControllers[0].text = 'John Doe';
    }
    if (variableControllers.length >= 2) {
      variableControllers[1].text = '70% OFF';
    }

    final targetType =
        forcedType ??
        (templateType.value.isNotEmpty ? templateType.value : 'Interactive');
    templateType.value = targetType;

    if (targetType == 'Carousel') {
      fillDemoCarouselCards();
      q2Selection.value = 3;
    } else if (targetType == 'Text & Media') {
      fillDemoMedia();
      buttons.clear();
      q2Selection.value = 1;
    } else if (targetType == 'Text') {
      selectedMediaType.value = '';
      selectedFileBytes.value = null;
      selectedFileName.value = '';
      buttons.clear();
      q2Selection.value = 0;
    } else {
      // Interactive
      fillDemoButtons();
      q2Selection.value = 2;
    }

    q1Selection.value = 1;
    nameError.value = '';
    languageError.value = '';
    formatError.value = '';
    headerError.value = '';
    footerError.value = '';
    previewRefresh.value++;
  }

  void fillNoOfferButtons() {
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

    // 1. Quick Reply (Informational)
    buttons.add(InteractiveButton(type: "QUICK_REPLY", text: "Acknowledge"));
    btnTextCtrls.add(TextEditingController(text: "Acknowledge"));
    btnValueCtrls.add(TextEditingController());
    urlType.add("");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    quickRepliesCount.value--;

    // 2. URL (Support / Status Link)
    buttons.add(
      InteractiveButton(
        type: "URL",
        text: "View Status",
        url: "https://example.com/status",
        example: [],
      ),
    );
    btnTextCtrls.add(TextEditingController(text: "View Status"));
    btnValueCtrls.add(
      TextEditingController(text: "https://example.com/status"),
    );
    urlType.add("Static");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    urlCount.value--;

    // 3. Phone Number (Helpdesk)
    phoneCountryCode.value = "+91";
    buttons.add(
      InteractiveButton(
        type: "PHONE_NUMBER",
        text: "Call Support",
        phoneNumber: "+919876543210",
      ),
    );
    btnTextCtrls.add(TextEditingController(text: "Call Support"));
    btnValueCtrls.add(TextEditingController(text: "9876543210"));
    urlType.add("");
    dynamicValueCtrl.add(TextEditingController());
    btnTextErrors.add("");
    btnValueErrors.add("");
    phoneNumberCount.value--;

    previewRefresh.value++;
  }

  void fillNoOfferDemoData({String? forcedType}) {
    ensureControllersActive();

    templateCategory.value = 'Utility';
    templateLanguage.value = 'en';

    templateName.value = 'service_update_notice';
    nameCtrl.text = 'service_update_notice';

    templateHeader.value = 'Important Account Update';
    headerCtrl.text = 'Important Account Update';

    templateFooter.value = 'For assistance, reply HELP';
    footerCtrl.text = 'For assistance, reply HELP';

    final demoBody =
        "Hi {{1}}, there is an update regarding your service request {{2}}.\nStatus: {{3}}\nWe will notify you when there is another update.";
    formatCtrl.text = demoBody;
    updateTemplateFormat(demoBody);

    if (variableControllers.isNotEmpty) {
      variableControllers[0].text = 'Rahul';
    }
    if (variableControllers.length >= 2) {
      variableControllers[1].text = 'SR123456';
    }

    if (variableControllers.length >= 3) {
      variableControllers[2].text = 'In Progress';
    }

    // Carousel is not allowed for Utility category
    carouselCards.clear();

    final targetType =
        forcedType ??
        (templateType.value.isNotEmpty && templateType.value != 'Carousel'
            ? templateType.value
            : 'Interactive');
    templateType.value = targetType;

    if (targetType == 'Text & Media') {
      fillDemoMedia();
      buttons.clear();
      q2Selection.value = 1;
    } else if (targetType == 'Text') {
      selectedMediaType.value = '';
      selectedFileBytes.value = null;
      selectedFileName.value = '';
      buttons.clear();
      q2Selection.value = 0;
    } else {
      fillNoOfferButtons();
      q2Selection.value = 2;
    }

    q1Selection.value = 2;
    nameError.value = '';
    languageError.value = '';
    formatError.value = '';
    headerError.value = '';
    footerError.value = '';
    previewRefresh.value++;
  }

  void autoFillFromQuestions() {
    if (q1Selection.value == -1 || q2Selection.value == -1) return;

    final q1 = q1Selection.value;
    final q2 = q2Selection.value;

    String targetType = 'Text';
    if (q2 == 0) {
      targetType = 'Text';
    } else if (q2 == 1) {
      targetType = 'Text & Media';
    } else if (q2 == 2) {
      targetType = 'Interactive';
    } else if (q2 == 3) {
      targetType = 'Carousel';
    }

    if (q1 == 1 || targetType == 'Carousel') {
      fillDemoData(forcedType: targetType);
      q1Selection.value = 1;
      q2Selection.value = q2;
    } else {
      fillNoOfferDemoData(forcedType: targetType);
      q1Selection.value = q1;
      q2Selection.value = q2;
    }
  }

  // ===========================================================================
  // INTERACTIVE TEMPLATE ACTIONS
  // ===========================================================================
  void updateInteractiveAction(String value) => interactiveAction.value = value;

  // MARK: - Interactive Buttons
  void addQuickReply() {
    if (quickRepliesCount.value > 0) {
      // Update supporting lists first
      btnTextCtrls.add(TextEditingController());
      btnValueCtrls.add(TextEditingController());
      urlType.add(""); // KEEP INDEX ALIGNMENT
      dynamicValueCtrl.add(TextEditingController());
      btnTextErrors.add("");
      btnValueErrors.add("");

      // Then update the trigger list
      buttons.add(InteractiveButton(type: "QUICK_REPLY", text: ""));

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
      // Update supporting lists first
      btnTextCtrls.add(TextEditingController());
      btnValueCtrls.add(TextEditingController());
      urlType.add(""); // Important
      dynamicValueCtrl.add(TextEditingController());
      btnTextErrors.add("");
      btnValueErrors.add("");

      // Then update the trigger list
      buttons.add(InteractiveButton(type: "COPY_CODE", text: "", example: []));

      copyCodeCount.value--;
    }
  }

  void setTextError(int index, String message) {
    if (index < btnTextErrors.length) btnTextErrors[index] = message;
    btnTextErrors.refresh(); // REQUIRED
  }

  void setValueError(int index, String msg) {
    if (index < btnValueErrors.length) btnValueErrors[index] = msg;
    btnValueErrors.refresh();
  }

  // ===========================================================================
  // CANCEL CREATION
  // ===========================================================================
  bool get isFormBlank {
    // Disable beforeunload warning if the user is not actively on the template creation page
    final currentRoute = Get.currentRoute.split('?').first;
    if (currentRoute != Routes.CREATE_TEMPLATE) {
      return true;
    }

    if (isViewMode.value) return true;

    // If it's prefilled with default demo data, allow leaving without confirmation dialog
    if ((nameCtrl.text.trim() == 'demo_special_offer' &&
            templateName.value == 'demo_special_offer') ||
        (nameCtrl.text.trim() == 'service_update_notice' &&
            templateName.value == 'service_update_notice')) {
      return true;
    }

    // Check if basic fields are empty
    bool isBasicBlank =
        nameCtrl.text.trim().isEmpty &&
        formatCtrl.text.trim().isEmpty &&
        headerCtrl.text.trim().isEmpty &&
        footerCtrl.text.trim().isEmpty &&
        (templateCategory.value.isEmpty ||
            templateCategory.value == 'Select message categories') &&
        (templateLanguage.value.isEmpty || templateLanguage.value == 'en') &&
        (templateType.value.isEmpty ||
            templateType.value == 'Select message type') &&
        selectedMediaType.value.isEmpty &&
        selectedFileName.value.isEmpty &&
        buttons.isEmpty;

    // If it's a carousel, check cards
    if (templateType.value == 'Carousel') {
      if (carouselCards.isEmpty) return isBasicBlank;

      bool anyCardHasContent = carouselCards.any(
        (card) =>
            card.body.value.isNotEmpty ||
            card.fileName.value.isNotEmpty ||
            card.buttons.isNotEmpty,
      );
      return isBasicBlank && !anyCardHasContent;
    }

    return isBasicBlank;
  }

  void cancelCreation() async {
    if (isFormBlank || isViewMode.value) {
      _performBackNavigation();
      return;
    }

    final shouldPop = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Template?'),
        content: const Text(
          'You have unsaved changes in your template. Are you sure you want to leave? Your progress will be lost.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      _performBackNavigation();
    }
  }

  void _performBackNavigation() {
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
        } else if (!btn.url!.startsWith("https://")) {
          setValueError(i, "URL must start with https://");
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
      btnTextErrors.refresh(); //
    }
    if (isValue) {
      btnValueErrors[index] = "";
      btnValueErrors.refresh(); //
    }
  }

  @override
  void onClose() {
    // Note: Do not manually dispose TextEditingControllers and FocusNodes here.
    // In MainShellView, controllers persist across route switches or can be reused.
    // Explicit disposal causes "used after disposed" assertion errors when navigating back.
    if (_beforeUnloadListener != null) {
      web.window.removeEventListener('beforeunload', _beforeUnloadListener);
    }

    super.onClose();
  }

  String sanitizeUrl(String url) {
    // Keep https:// intact
    return url.replaceAllMapped(RegExp(r'(?<!:)//+'), (match) => '/');
  }
}
