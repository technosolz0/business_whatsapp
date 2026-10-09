import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/data/services/clients_service.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';

import 'package:business_whatsapp/app/Utilities/webutils.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/Utilities/media_utils.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/data/models/broadcast_model.dart';
import 'package:business_whatsapp/app/data/models/broadcast_payload.dart';
import 'package:business_whatsapp/app/data/models/broadcast_status.dart';
import 'package:business_whatsapp/app/data/models/contact_model.dart';
import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:business_whatsapp/app/data/models/quota_model.dart';
import 'package:business_whatsapp/app/data/models/template_params.dart';
import 'package:business_whatsapp/app/data/services/broadcast_firebase_service.dart';
import 'package:business_whatsapp/app/data/services/broadcast_queue_service.dart';
import 'package:business_whatsapp/app/data/services/broadcast_service.dart';
import 'package:business_whatsapp/app/data/services/contact_service.dart';
import 'package:business_whatsapp/app/data/models/carousel_card_model.dart';

import 'package:business_whatsapp/app/data/services/template_firebase_service.dart';
import 'package:business_whatsapp/app/data/services/upload_file_firebase.dart';
import 'package:business_whatsapp/app/modules/broadcasts/views/widgets/segment_filter_popup.dart';
import 'package:business_whatsapp/app/modules/contacts/services/import_service.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:chips_input_autocomplete/chips_input_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'broadcasts_controller.dart';
import '../../../data/models/broadcast_table_model.dart';
import 'package:business_whatsapp/main.dart';
import 'package:business_whatsapp/app/modules/broadcasts/widgets/broadcast_progress_dialog.dart';

import 'package:intl/intl.dart';

class CreateBroadcastController extends GetxController {
  final RxInt currentStep = 0.obs;
  final RxString selectedTemplate = ''.obs;
  final RxString selectedAudience = ''.obs;
  final nameController = TextEditingController().obs;
  final descriptionController = TextEditingController().obs;
  final RxString editingBroadcastId = ''.obs;
  final RxString draftAdminId = ''.obs;
  final RxString draftAdminName = ''.obs;
  final deliveryOption = 0.obs;
  final RxString selectedFileName = ''.obs;
  final RxString selectedFileError = ''.obs;
  final Rx<Uint8List?> selectedFileBytes = Rx<Uint8List?>(null);
  final RxString templateBody = ''.obs;
  final RxBool isEdit = false.obs;
  final RxString mimeType = ''.obs;
  final RxString templateHeader = ''.obs;
  final RxString mediaHandleId = "".obs;
  final RxBool isUploadingMedia = false.obs;
  final RxBool isImporting = false.obs; // Loading state for import
  final RxBool isSending = false.obs; // Loading state for send broadcast
  final RxDouble broadcastProgress = 0.0.obs;
  final RxString templateName = "".obs;
  String templateLanguage = "";
  List<String> appliedValues = [];
  final RxString templateType = ''.obs;
  final RxList<String> contactIdsList = <String>[].obs;
  final Rx<DateTime> selectedScheduleTime = DateTime.now().obs;
  static CreateBroadcastController get instance =>
      Get.find<CreateBroadcastController>();
  bool isPreview = false;
  RxString estimatedCount = "0".obs;
  final Rx<DateTime?> completedAt = Rx<DateTime?>(null);

  // Retry failed broadcast
  final RxBool enableRetry = false.obs;

  // Wallet balance for cost validation (using double to handle decimal values)
  final RxDouble walletBalance = 0.0.obs;

  // Dynamic charges from Firebase
  final RxDouble marketingCostPerContact = 0.80.obs;
  final RxDouble utilityCostPerContact = 0.20.obs;

  // Template variables for reactive preview
  final RxString headerImageUrl = ''.obs;
  final RxString orderNumber = ''.obs;
  final RxString totalAmount = ''.obs;
  final ChipsAutocompleteController variableController =
      ChipsAutocompleteController();
  RxList<InteractiveButton> buttons = <InteractiveButton>[].obs;
  RxList<TextEditingController> btnTextCtrls = <TextEditingController>[].obs;
  RxList<TextEditingController> btnValueCtrls =
      <TextEditingController>[].obs; // URL / Phone / Copy

  RxList<String> btnValueErrors = <String>[].obs;
  RxList<ContactModel> allContacts = <ContactModel>[].obs;
  RxList<ContactModel> importedContacts = <ContactModel>[].obs;
  RxList<ContactModel> segmentContacts = <ContactModel>[].obs;
  RxList<ContactModel> contactDetails = <ContactModel>[].obs;

  RxList<String> availableTags = <String>[].obs;
  RxList<String> selectedTags = <String>[].obs;
  RxString attachmentType = ''.obs;
  RxBool showSegmentPopup = false.obs;

  // Lazy loading for contacts
  RxBool isLoadingContacts = false.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreContacts = true.obs;
  RxInt currentContactsPage = 1.obs;
  static const int contactsPageSize = 30;
  final RxList<TemplateParamModel> templateList = <TemplateParamModel>[].obs;
  final RxString selectedTemplateId = ''.obs;
  final RxString originalTemplateBody = ''.obs;

  final Rx<TemplateParamModel?> selectedTemplateParams =
      Rx<TemplateParamModel?>(null);
  final RxBool ctaUrlLinkTrackingOptedOut = false.obs;

  final RxList<CarouselCard> carouselCards = <CarouselCard>[].obs;

  Map<String, TextEditingController> paramControllers = {};

  /// Store variable inputs (static/dynamic)
  final Map<String, Map<String, String>> variableValues = {};
  List<TextEditingController> dynamicValueCtrl = [];
  List<String> urlType = []; // Static / Dynamic

  void updatePreviewBody() {
    appliedValues.clear();
    String updatedBody = originalTemplateBody.value;
    String updatedHeader = "";

    // If template has header text, use it as base
    if (selectedTemplateParams.value?.headerText != null) {
      updatedHeader = selectedTemplateParams.value!.headerText!;
    }

    ContactModel? previewContact = finalRecipients.isNotEmpty
        ? finalRecipients.first
        : null;

    // 1. Process Main Template Variables (Body & Header)
    variableValues.forEach((key, data) {
      final type = data["type"] ?? "empty";
      final rawValue = data["value"] ?? "";

      String displayValue = rawValue;
      bool shouldReplace = false;

      if (type == "static") {
        if (rawValue.isNotEmpty) {
          displayValue = rawValue;
          shouldReplace = true;
        }
      } else if (type == "dynamic") {
        String resolved = "";
        if (previewContact != null) {
          resolved = resolveChipValue(previewContact, rawValue);
        }

        if (resolved.isEmpty || resolved == "-") {
          displayValue = rawValue;
        } else {
          displayValue = resolved;
        }
        shouldReplace = true;
      }

      if (key.startsWith("body_")) {
        final index = key.split("_")[1];
        final placeholder = "{{$index}}";
        if (shouldReplace) {
          updatedBody = updatedBody.replaceAll(placeholder, displayValue);
          appliedValues.add(displayValue);
        } else {
          appliedValues.add(placeholder);
        }
      } else if (key.startsWith("header_")) {
        final index = key.split("_")[1];
        final placeholder = "{{$index}}";
        if (shouldReplace) {
          updatedHeader = updatedHeader.replaceAll(placeholder, displayValue);
          appliedValues.add(displayValue);
        } else {
          appliedValues.add(placeholder);
        }
      }
    });

    templateBody.value = updatedBody;
    templateHeader.value = updatedHeader;

    // 2. Process Carousel Cards Body Variables
    for (int i = 0; i < carouselCards.length; i++) {
      final card = carouselCards[i];
      card.appliedValues.clear();
      String cardUpdated = card.originalBody.value;

      variableValues.forEach((key, data) {
        // Match key card_0_body_1
        final prefix = "card_${i}_body_";
        if (!key.startsWith(prefix)) return;

        final index = key.split("_").last;
        final placeholder = "{{$index}}";
        final type = data["type"] ?? "empty";
        final rawValue = data["value"] ?? "";

        String displayValue = rawValue;
        bool shouldReplace = false;

        if (type == "static") {
          if (rawValue.isNotEmpty) {
            displayValue = rawValue;
            shouldReplace = true;
          }
        } else if (type == "dynamic") {
          String resolved = "";
          if (previewContact != null) {
            resolved = resolveChipValue(previewContact, rawValue);
          }

          if (resolved.isEmpty || resolved == "-") {
            displayValue = rawValue;
          } else {
            displayValue = resolved;
          }
          shouldReplace = true;
        }

        if (shouldReplace) {
          cardUpdated = cardUpdated.replaceAll(placeholder, displayValue);
          card.appliedValues.add(displayValue);
        } else {
          card.appliedValues.add(placeholder);
        }
      });

      card.body.value = cardUpdated;
    }
  }

  /// ----------------------------------------------------------------
  ///

  /// Chips to show above fields
  final List<String> _staticChips = [
    "First Name",
    "Last Name",
    "Email",
    "Company",
    "Phone Number",
    "Country Code",
    "Calling Code",
    "Birth Date",
    "Anniversary",
    "Work Anniversary",
  ];

  /// Chips to show above fields
  late RxList<String> availableChips = <String>[..._staticChips].obs;

  void _updateAvailableChips() {
    if (selectedAudience.value == "import") {
      availableChips.assignAll(importedCustomKeys.toList());
    } else {
      availableChips.assignAll(_staticChips);
    }
  }

  final Map<String, RxString> paramErrors = {};

  @override
  void onInit() {
    super.onInit();
    // Re-calculate estimates whenever audience or specific contact list changes
    ever(selectedAudience, (_) {
      calculateEstimatedRecipientsCount();
      _updateAvailableChips();
    });
    ever(contactIdsList, (_) => calculateEstimatedRecipientsCount());

    // Update recipient count when final list changes
    ever(finalRecipients, (_) => updateRecipientCount());

    if (!isEdit.value) {
      resetAll();
    }

    // Ensure accurate initial load for "All Contacts" default
    // If 'all' is default, strict fetch is required to avoid pagination partial load
    if (selectedAudience.value.isEmpty || selectedAudience.value == 'all') {
      selectedAudience.value = 'all'; // Set default explicitly
      selectAudience('all');
    } else {
      loadInitialData(); // Fallback for other states (unlikely for new broadcast)
    }

    loadTemplates();
    loadWalletBalance();
    loadCharges();
  }

  /// ----------------------------------------------------------------
  /// MARK: - TEMPLATE HANDLING
  /// ----------------------------------------------------------------

  /// ensure a key exists (safety)
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
    final controllersToDispose = List<TextEditingController>.from(
      paramControllers.values,
    );
    paramControllers.clear();
    paramErrors.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in controllersToDispose) {
        c.dispose();
      }
    });
  }

  ///
  /// ------------------------------------------------

  void loadTemplates() async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getApprovedTemplates,
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final apiTemplates =
              (data['data'] is Map ? data['data']['data'] : data['data'])
                  as List<dynamic>;
          final templates = apiTemplates.map((template) {
            return TemplateFirestoreService.instance.parseTemplate(
              Map<String, dynamic>.from(template),
            );
          }).toList();
          templateList.value = templates;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      print('❌ Error loading templates from API: $e');
      try {
        templateList.value = await TemplateFirestoreService.instance
            .getAllTemplatesForBroadcast();
      } catch (fbError) {
        debugPrint('❌ Error loading templates from fallback: $fbError');
      }
    }
  }

  void onTemplateSelected(String templateId) {
    selectedTemplateId.value = templateId;

    // First, find the basic template info from our API-loaded list
    final basicTemplate = templateList.firstWhere(
      (t) => t.id == templateId,
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
        version: ctaUrlLinkTrackingOptedOut.value == false ? 'v1' : 'v2',
        ctaUrlLinkTrackingOptedOut: ctaUrlLinkTrackingOptedOut.value,
      ),
    );

    // Set basic template info immediately for UI responsiveness
    selectedTemplateParams.value = basicTemplate;
    ctaUrlLinkTrackingOptedOut.value = basicTemplate.ctaUrlLinkTrackingOptedOut;
    templateName.value = basicTemplate.name;
    templateLanguage = basicTemplate.language;
    attachmentType.value = _normalizeHeaderFormat(basicTemplate.headerFormat);
    originalTemplateBody.value = basicTemplate.bodyText;
    templateHeader.value = basicTemplate.headerText ?? "";
    templateType.value = basicTemplate.templateType;

    // Use helper to reset state
    _resetTemplateState();

    updatePreviewBody();

    // Now fetch the full template details from Firebase asynchronously
    _loadFullTemplateDetails(templateId);
  }

  Future<void> _loadFullTemplateDetails(String templateId) async {
    try {
      final fullTemplate = await TemplateFirestoreService.instance
          .getTemplateById(templateId);

      if (fullTemplate != null) {
        final category = selectedTemplateParams.value?.category.toUpperCase();
        // Update with full template data from Firebase
        selectedTemplateParams.value = category != null
            ? fullTemplate.copyWith(category: category)
            : fullTemplate;
        ctaUrlLinkTrackingOptedOut.value =
            fullTemplate.ctaUrlLinkTrackingOptedOut;
        templateName.value = fullTemplate.name;
        templateLanguage = fullTemplate.language;
        attachmentType.value = _normalizeHeaderFormat(
          fullTemplate.headerFormat,
        );
        originalTemplateBody.value = fullTemplate.bodyText;
        templateHeader.value = fullTemplate.headerText ?? "";
        templateType.value = fullTemplate.templateType;

        // Initialize button errors for UI (avoids index error)
        _resetTemplateState(); // Clear everything before applying new full details

        if (fullTemplate.buttons != null) {
          _initializeButtonControllers(fullTemplate.buttons!);
        }

        /// CLEAR OLD VALUES
        variableValues.clear();

        /// Create keys: header_1, header_2, body_1, body_2...
        for (int i = 1; i <= fullTemplate.headerVars; i++) {
          variableValues["header_$i"] = {"type": "empty", "value": ""};
        }
        for (int i = 1; i <= fullTemplate.bodyVars; i++) {
          variableValues["body_$i"] = {"type": "empty", "value": ""};
        }
        _disposeParamStates();

        /// CAROUSEL HANDLING
        _initializeCarouselCards(fullTemplate);
        updatePreviewBody();
      }
    } catch (e) {
      print('❌ Error loading full template details: $e');
      // Keep the basic template info that was already set
    }
  }

  void _initializeCarouselCards(TemplateParamModel template) {
    carouselCards.clear();
    if (template.templateType == "CAROUSEL" && template.cards != null) {
      for (var i = 0; i < template.cards!.length; i++) {
        final cardData = template.cards![i];
        final card = CarouselCard();

        // Extract card components
        final cardComponents = cardData["components"] as List? ?? [];
        for (var comp in cardComponents) {
          final type = comp["type"] ?? "";
          if (type == "BODY") {
            card.body.value = comp["text"] ?? "";
            card.originalBody.value = comp["text"] ?? "";
            final regex = RegExp(r'\{\{[0-9]+\}\}');
            final matches = regex.allMatches(card.body.value);

            // Extract examples if available
            List<String> examples = [];
            if (comp["example"] != null &&
                comp["example"] is Map &&
                comp["example"]["body_text"] is List) {
              final bodyExs = comp["example"]["body_text"] as List;
              if (bodyExs.isNotEmpty && bodyExs[0] is List) {
                examples = (bodyExs[0] as List)
                    .map((e) => e.toString())
                    .toList();
              }
            }

            for (int j = 1; j <= matches.length; j++) {
              final key = "card_${i}_body_$j";
              ensureParamKey(key);
              final ctrl = paramControllers[key]!;
              card.variableControllers.add(ctrl);

              // Store example for this specific variable
              if (examples.length >= j) {
                card.variableExamples.add(examples[j - 1]);
              } else {
                card.variableExamples.add("");
              }
            }
          } else if (type == "HEADER") {
            card.mediaType.value = (comp["format"] ?? "IMAGE")
                .toString()
                .toUpperCase();
          } else if (type == "BUTTONS") {
            if (comp["buttons"] is List) {
              final btns = (comp["buttons"] as List)
                  .map((b) => InteractiveButton.fromJson(b))
                  .toList();
              card.buttons.assignAll(btns);

              // Detect variables in buttons (e.g. dynamic URL)
              final regex = RegExp(r'\{\{[0-9]+\}\}');
              for (var btnIndex = 0; btnIndex < btns.length; btnIndex++) {
                final btn = btns[btnIndex];

                // Check URL for variables
                if (btn.url != null && regex.hasMatch(btn.url!)) {
                  final matches = regex.allMatches(btn.url!);
                  for (int j = 1; j <= matches.length; j++) {
                    final key = "card_${i}_btn_${btnIndex}_url_$j";
                    ensureParamKey(key);
                    final ctrl = paramControllers[key]!;
                    card.variableControllers.add(ctrl);
                  }
                }
              }
            }
          }
        }
        carouselCards.add(card);
      }
    }
  }

  bool tagHasNoContacts(String tagName) {
    return allContacts.where((c) => c.tags.contains(tagName)).isEmpty;
  }

  TextEditingController getTextCtrl(int index) {
    if (btnTextCtrls.length <= index) {
      btnTextCtrls.insert(index, TextEditingController());
    }
    return btnTextCtrls[index];
  }

  TextEditingController getValueCtrl(int index) {
    if (btnValueCtrls.length <= index) {
      btnValueCtrls.insert(index, TextEditingController());
    }
    return btnValueCtrls[index];
  }

  /// ----------------------------------------------------------------
  /// MARK: - AUDIENCE & CONTACTS
  /// ----------------------------------------------------------------

  Future<void> loadInitialData() async {
    isLoadingContacts.value = true;
    try {
      // Load first page of contacts (30 contacts)
      await loadContactsPage(1);
      availableTags.assignAll(await ContactsService.instance.getAllTags());
    } finally {
      isLoadingContacts.value = false;
    }
  }

  Future<void> loadContactsPage(int page) async {
    try {
      isLoadingMore.value = true;
      final newContacts = await ContactsService.instance.getContactsPage(
        page: page,
        pageSize: contactsPageSize,
      );

      if (page == 1) {
        allContacts.assignAll(newContacts);
      } else {
        allContacts.addAll(newContacts);
      }

      currentContactsPage.value = page;
      hasMoreContacts.value = newContacts.length == contactsPageSize;

      // Default selection for first page
      if (selectedAudience.value == "all" && page == 1) {
        segmentContacts.assignAll(allContacts);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreContacts() async {
    if (!hasMoreContacts.value || isLoadingMore.value) return;

    await loadContactsPage(currentContactsPage.value + 1);
  }

  Future<void> selectAudience(String mode) async {
    selectedAudience.value = mode;

    if (mode == "all") {
      importedContacts.clear(); // optional clean
      segmentContacts.clear(); // FIXED

      // Ensure we have ALL contacts, not just the first page
      isLoadingContacts.value = true;
      try {
        final contacts = await ContactsService.instance.getAllContacts();
        allContacts.assignAll(contacts);
        hasMoreContacts.value =
            false; // Disable pagination as we have everything
        await calculateEstimatedRecipientsCount();
      } catch (e) {
        print("Error fetching all contacts: $e");
      } finally {
        isLoadingContacts.value = false;
      }
    } else if (mode == "import") {
      allContacts.clear();
      segmentContacts.clear();

      importContacts();
    } else if (mode == "custom") {
      allContacts.clear();
      importedContacts.clear();

      showSegmentPopup.value = true;

      refreshContactsForSegmentPopup();
      Future.delayed(const Duration(milliseconds: 50), () {
        Get.dialog(
          SegmentFilterPopup(controller: this),
          barrierDismissible: false,
        );
      });
    }
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

  /// ----------------------------------------------------------------
  /// 📥 DOWNLOAD SAMPLE CSV
  /// ----------------------------------------------------------------
  void downloadSampleCsv() async {
    final rows = [
      [
        "Country Code",
        "Calling Code",
        "Phone Number",
        "First Name",
        "Last Name",
        "Email (optional)",
        "Company (optional)",
        "Tags (optional)",
        "Notes (optional)",
        "Birthdate (optional)",
        "Anniversary (optional)",
        "Work Anniversary (optional)",
        "Birthdate Month (optional)",
        "Anniversary Month (optional)",
        "Work Anniversary Month (optional)",
      ],
      [
        "IN",
        "+91",
        "9876543210",
        "Ritika",
        "Sharma",
        "ritika.sharma@test.com",
        "BlueBridge",
        "new",
        "Lead",
        "1995-04-18",
        "2020-02-10",
        "2021-05-01",
        "18 04",
        "10 02",
        "01 05",
      ],
      [
        "IN",
        "+91",
        "9123456789",
        "Amit",
        "Verma",
        "amit.verma@test.com",
        "UrbanEdge",
        "priority",
        "Follow-up",
        "1992-09-07",
        "",
        "2019-08-15",
        "07 09",
        "",
        "15 08",
      ],
      [
        "US",
        "+1",
        "123456789",
        "John",
        "Doe",
        "john.doe@test.com",
        "UrbanEdge",
        "priority",
        "Follow-up",
        "1992-09-07",
        "",
        "2019-08-15",
        "07 09",
        "",
        "15 08",
      ],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);

    await FileSaver.instance.saveFile(
      name: "sample_contacts",
      bytes: bytes,
      fileExtension: "csv",
      mimeType: MimeType.csv,
    );
  }

  /// ----------------------------------------------------------------
  /// 📥 CSV IMPORT INTEGRATION
  /// ----------------------------------------------------------------
  Future<void> importContacts() async {
    await CsvImportService.importContactsFromCsv(
      requireNames: false,
      onLoadingChanged: (loading) => isImporting.value = loading,
      onContactsParsed: (contacts) async {
        // Collect custom keys
        importedCustomKeys.clear();
        for (var c in contacts) {
          importedCustomKeys.addAll(c.customAttributes.keys);
        }

        // Refresh available chips
        _updateAvailableChips();

        // Convert ContactImportData to ContactModel and add to importedContacts
        final contactModels = contacts
            .map(
              (data) => ContactModel(
                id: '', // Will be assigned by Firestore
                fName: data.firstName ?? '',
                lName: data.lastName ?? '',
                phoneNumber: data.phoneNumber,
                countryCallingCode: data.countryCallingCode,
                isoCountryCode: data.isoCountryCode,
                email: data.email ?? '',
                company: data.company ?? '',
                tags: data.tags,
                notes: data.notes ?? '',
                status: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                customAttributes: data.customAttributes,
              ),
            )
            .toList();

        importedContacts.assignAll(
          contactModels.where((c) => c.status != 0).toList(),
        );

        // Update contact details and count for popup after import is complete
        calculateEstimatedRecipientsCount();
        updateRecipientCount();
      },
      onComplete: (imported, skipped) {
        // Refresh tags list after import
        _refreshAvailableTags();
      },
    );
  }

  /// Refresh available tags after import
  Future<void> _refreshAvailableTags() async {
    availableTags.assignAll(await ContactsService.instance.getAllTags());
    allContacts.assignAll((await ContactsService.instance.getAllContacts()));
  }

  // Tag selection
  void toggleTag(String tagName) {
    // Toggle tag ON/OFF
    if (selectedTags.contains(tagName)) {
      selectedTags.remove(tagName);

      // Remove ONLY contacts belonging to this tag (unless manually added)
      segmentContacts.removeWhere((c) {
        final belongsToThisTag = c.tags.contains(tagName);
        final stillMatchesOtherTags = c.tags.any(
          (t) => selectedTags.contains(t),
        );
        return belongsToThisTag && !stillMatchesOtherTags;
      });
    } else {
      selectedTags.add(tagName);

      // Add all contacts belonging to this tag
      final contactsOfTag = allContacts
          .where((c) => c.tags.contains(tagName) && c.status != 0)
          .toList();

      for (var c in contactsOfTag) {
        if (!segmentContacts.any((x) => x.id == c.id)) {
          segmentContacts.add(c);
        }
      }
    }

    // Auto-remove any tags that now have no contacts selected
    _autoRemoveEmptyTags();
  }

  RxString contactSearch = "".obs;
  RxString contactDetailsSearch = "".obs;

  /// ----------------------------------------------------------------
  /// MARK: - MEDIA HANDLING
  /// ----------------------------------------------------------------
  Future<void> pickFile() async {
    //print("Picking file for media type: ${attachmentType.value}");
    if (attachmentType.value.isEmpty) {
      selectedFileError.value = "Please select a media type first.";
      return;
    }

    final result = await MediaUtils.pickAndValidateFile(
      mediaType: attachmentType.value,
      maxSizeMB: 10,
    );

    if (!result.success) {
      if (mediaHandleId.value.isEmpty) {
        (selectedFileError.value = result.error!);
      }
      return;
    }

    selectedFileBytes.value = result.bytes;
    selectedFileName.value = result.fileName!;

    mimeType.value = result.mimeType!;

    await uploadToInterakt(mimeType.value);
  }

  Future<void> uploadToInterakt(String mime) async {
    //print("Uploading file to Interakt with MIME: $mime");
    if (selectedFileBytes.value == null) return;

    isUploadingMedia.value = true;

    final result = await BroadcastService.instance.uploadBroadcastMedia(
      fileBytes: selectedFileBytes.value!,
      fileName: selectedFileName.value,
      mimeType: mime,
    );

    isUploadingMedia.value = false;
    if (result["success"] == true) {
      mediaHandleId.value = result["media_id"] ?? "";
      selectedFileError.value = "";
    } else {
      final err = result["message"]?.toString() ?? "Failed to upload media.";
      selectedFileError.value = err;
      Utilities.showSnackbar(SnackType.ERROR, "Upload error: $err");
    }
  }

  void updateSearch(String value) {
    contactSearch.value = value;
  }

  void updateDetailSearch(String value) {
    contactDetailsSearch.value = value;
  }

  List<ContactModel> get filteredContacts {
    final query = contactSearch.value.toLowerCase();

    if (query.isEmpty) return allContacts;

    return allContacts.where((c) {
      final name = "${c.fName ?? ''} ${c.lName ?? ''}".toLowerCase().trim();
      return name.contains(query) || c.phoneNumber.contains(query);
    }).toList();
  }

  List<ContactModel> get filteredDetailsContacts {
    final query = contactDetailsSearch.value.toLowerCase();

    if (query.isEmpty) return contactDetails;

    return contactDetails.where((c) {
      final name = "${c.fName ?? ''} ${c.lName ?? ''}".toLowerCase().trim();
      return name.contains(query) || c.phoneNumber.contains(query);
    }).toList();
  }

  // Checkbox toggle
  void toggleContact(ContactModel contact) {
    final isSelected = segmentContacts.any((e) => e.id == contact.id);

    if (isSelected) {
      // REMOVE contact
      segmentContacts.removeWhere((e) => e.id == contact.id);
    } else {
      // ADD contact manually
      if (contact.status == 0) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Cannot select Opted-out contact.',
        );
        return;
      }
      segmentContacts.add(contact);
    }

    // Auto remove tags whose contacts are now fully deselected
    _autoRemoveEmptyTags();
  }

  RxList<ContactModel> get finalRecipients {
    if (isPreview) return contactDetails;

    if (selectedAudience.value == "all") {
      // Return a temporary filtered list for "all" mode
      // Note: This matches the old behavior while allow allContacts to hold everyone
      return allContacts.where((c) => c.status != 0).toList().obs;
    } else if (selectedAudience.value == "import") {
      return importedContacts;
    } else {
      return segmentContacts;
    }
  }

  RxInt finalRecipientCount = 0.obs;

  void updateRecipientCount() {
    // print("Updating recipient count: ${finalRecipients.length}");
    finalRecipientCount.value = finalRecipients.length;
  }

  /// ----------------------------------------------------------------
  /// 🔥 GLOBAL CHIP LIST (Dynamic)
  /// ----------------------------------------------------------------

  /// ----------------------------------------------------------------
  /// 🔥 UNIQUE CHIP ASSIGNMENT MAP
  /// ----------------------------------------------------------------
  RxMap<String, String?> assignedChips = {"header": null, "footer": null}.obs;

  /// Imported custom keys from CSV
  final RxSet<String> importedCustomKeys = <String>{}.obs;

  /// ----------------------------------------------------------------
  /// 🔥 VARIABLE COUNT BASED ON {{n}}
  /// ----------------------------------------------------------------
  RxInt variableCount = 0.obs;

  /// Dynamic storage for values
  RxMap bodyVarValues = {}.obs;
  RxMap bodyVarTypes = {}.obs;

  /// ----------------------------------------------------------------
  /// 🔍 Count the variables in template text
  /// ----------------------------------------------------------------
  int extractVariableCount(String text) {
    final regex = RegExp(r'{{\d+}}');
    return regex.allMatches(text).length;
  }

  /// ----------------------------------------------------------------
  /// 🔥 Initialize fields based on template
  /// ----------------------------------------------------------------
  void initializeBodyFields(int count) {
    bodyVarValues.clear();
    bodyVarTypes.clear();

    assignedChips["header"] = null;
    assignedChips["footer"] = null;

    /// Reset available chips (optional design choice)
    _updateAvailableChips();

    for (int i = 1; i <= count; i++) {
      bodyVarValues["body$i"] = null;
      bodyVarTypes["body$i"] = "empty";
      assignedChips["body$i"] = null;
    }
  }

  final List<String> sampleFields = [
    "Name",
    "Country Code",
    "Phone Number",
    "Email",
    "Company",
  ];

  void refreshVariableValuesFromControllers() {
    variableValues.forEach((key, map) {
      if (!key.startsWith("body_")) return;

      final index = key.split("_")[1];
      final controller = paramControllers["body_$index"];

      if (controller != null) {
        final value = controller.text.trim();

        // 🔥 KEEP existing type
        final oldType = map["type"] ?? "empty";

        variableValues[key] = {
          "type": (oldType == "dynamic")
              ? "dynamic" // do NOT convert dynamic to static
              : (value.isEmpty ? "empty" : "static"),
          "value": value,
        };
      }
    });
  }

  /// ----------------------------------------------------------------
  /// MARK: - STEP NAVIGATION & VALIDATION
  /// ----------------------------------------------------------------

  /// Advances to the next step if validation passes
  void nextStep() {
    final step = currentStep.value;

    // -----------------------------
    // STEP 0 → Audience Validation
    // -----------------------------
    if (step == 0) {
      if (!_validateAudienceStep()) return;

      // Load templates if validation passes
      loadTemplates();
    }

    // -----------------------------
    // STEP 1 → Template Validation
    // -----------------------------
    if (step == 1) {
      if (!_validateContentStep()) return;
    }

    // -----------------------------
    // Navigate to next step route
    // -----------------------------
    if (currentStep.value < 2) {
      currentStep.value++;
      _navigateToStep(currentStep.value);
    }
  }

  /// ----------------------------------------------------------------
  /// ✅ VALIDATION HELPERS
  /// ----------------------------------------------------------------

  /// Validates Step 0 (Audience Selection)
  bool _validateAudienceStep() {
    if (nameController.value.text.trim().isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please enter a broadcast name to continue',
      );
      return false;
    }
    if (selectedAudience.value.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please select an audience to continue',
      );
      return false;
    }

    if (selectedAudience.value == "custom" && segmentContacts.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please select at least 1 contact',
      );
      return false;
    }

    if (selectedAudience.value == "import" && importedContacts.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please upload a CSV to continue',
      );
      return false;
    }

    // 🔥 NEW: Validate contacts details (Phone, Calling Code, ISO)
    final recipients = finalRecipients;
    for (var contact in recipients) {
      if (contact.phoneNumber.trim().isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Some contacts are missing phone numbers.',
        );
        return false;
      }
      if (contact.countryCallingCode == null ||
          contact.countryCallingCode!.trim().isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Contact ${contact.phoneNumber} is missing a calling code (e.g. +91).',
        );
        return false;
      }
      if (contact.isoCountryCode == null ||
          contact.isoCountryCode!.trim().isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Contact ${contact.phoneNumber} is missing a country code (e.g. IN).',
        );
        return false;
      }
    }

    return true;
  }

  /// Validates Step 1 (Content & Template)
  bool _validateContentStep() {
    // 1️⃣ Validate Buttons if any
    if (buttons.isNotEmpty) {
      if (!_validateInteractiveButtons()) return false;
    }

    // 2️⃣ Validate Template Selection
    if (selectedTemplateId.value.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please select a template to continue',
      );
      return false;
    }

    // 3️⃣ Refresh & Validate Variable Fields
    refreshVariableValuesFromControllers();

    bool missingValue = false;
    variableValues.forEach((key, map) {
      if (key.startsWith("body_")) {
        final val = (map["value"] ?? "").trim();
        if (val.isEmpty) {
          missingValue = true;
        }
      }
    });

    if (missingValue) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please fill all template variable fields.',
      );
      return false;
    }

    // 4️⃣ Validate Media Attachment
    if (attachmentType.value.isNotEmpty) {
      // CASE A: Upload still in progress
      if (isUploadingMedia.value) {
        Utilities.showSnackbar(
          SnackType.INFO,
          'Please wait while your ${attachmentType.value} is uploading.',
        );
        return false;
      }

      // CASE B: No media uploaded yet
      if (mediaHandleId.value.isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Please upload a ${attachmentType.value} to continue.',
        );
        return false;
      }
    }

    return true;
  }

  /// Validates Interactive Buttons inputs
  bool _validateInteractiveButtons() {
    btnValueErrors.value = List.generate(buttons.length, (_) => "");

    bool hasButtonError = false;
    String? firstErrorMessage;

    for (int i = 0; i < buttons.length; i++) {
      final btn = buttons[i];
      final value = btnValueCtrls[i].text.trim();

      // URL validation
      if (btn.type == "URL" && value.isEmpty) {
        btnValueErrors[i] = "URL cannot be empty";
        firstErrorMessage ??= btnValueErrors[i];
        hasButtonError = true;
      }

      // PHONE NUMBER validation
      if (btn.type == "PHONE_NUMBER" && value.isEmpty) {
        btnValueErrors[i] = "Phone number is required";
        firstErrorMessage ??= btnValueErrors[i];
        hasButtonError = true;
      }

      // COPY CODE validation
      if (btn.type == "COPY_CODE" && value.isEmpty) {
        btnValueErrors[i] = "Copy Code cannot be blank";
        firstErrorMessage ??= btnValueErrors[i];
        hasButtonError = true;
      }

      // Dynamic URL extra validation
      if (btn.type == "URL" &&
          urlType.length > i &&
          urlType[i] == "Dynamic" &&
          dynamicValueCtrl[i].text.trim().isEmpty) {
        btnValueErrors[i] = "Url parameter is required";
        firstErrorMessage ??= btnValueErrors[i];
        hasButtonError = true;
      }
    }

    // If ANY button error exists → show ORIGINAL message
    if (hasButtonError) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        firstErrorMessage ?? "Please fix the button fields",
      );
      return false;
    }
    return true;
  }

  /// ----------------------------------------------------------------
  /// 🛠 STATE MANAGEMENT HELPERS
  /// ----------------------------------------------------------------

  /// Resets all template-related state (buttons, vars, media)
  void _resetTemplateState() {
    buttons.clear();
    btnTextCtrls.clear();
    btnValueCtrls.clear();
    btnValueErrors.clear();
    btnValueErrors.value = List.generate(buttons.length, (_) => "");
    variableValues.clear();
    _disposeParamStates();

    // Reset Media
    selectedFileBytes.value = null;
    selectedFileName.value = "";
    selectedFileError.value = "";
    mediaHandleId.value = "";
    isUploadingMedia.value = false;
    ctaUrlLinkTrackingOptedOut.value = false;
  }

  /// Initializes controllers for interactive buttons
  void _initializeButtonControllers(List<InteractiveButton> buttonList) {
    urlType.clear(); // Reset dynamic tracking
    dynamicValueCtrl.clear();

    for (var i = 0; i < buttonList.length; i++) {
      final btn = buttonList[i];
      buttons.add(btn);

      // Text Controller
      btnTextCtrls.add(TextEditingController(text: btn.text));

      // Value Controller
      if (btn.type == "URL") {
        btnValueCtrls.add(TextEditingController(text: btn.url));

        // Handle Dynamic URLs
        if (btn.example != null &&
            btn.example!.isNotEmpty &&
            btn.example!.first.isNotEmpty &&
            btn.example!.first.contains("/")) {
          urlType.add("Dynamic");
          final example = btn.example!.first;
          final dynamicValue = example.split("/").last;
          dynamicValueCtrl.add(TextEditingController(text: dynamicValue));
        } else {
          urlType.add("Static");
          dynamicValueCtrl.add(TextEditingController());
        }
      } else if (btn.type == "PHONE_NUMBER") {
        btnValueCtrls.add(TextEditingController(text: btn.phoneNumber));
      } else if (btn.type == "COPY_CODE") {
        btnValueCtrls.add(
          TextEditingController(
            text: btn.example?.isNotEmpty == true ? btn.example!.first : "",
          ),
        );
      } else if (btn.type == "QUICK_REPLY") {
        btnValueCtrls.add(TextEditingController(text: btn.text));
      } else {
        btnValueCtrls.add(TextEditingController());
      }
    }

    // Initialize Error List
    btnValueErrors.value = List.generate(buttons.length, (_) => "");
  }

  void previousStep() {
    if (isPreview) {
      Get.offAllNamed(Routes.BROADCASTS);
      return;
    }
    if (currentStep.value > 0) {
      if (Get.previousRoute.isNotEmpty) {
        Get.back();
      } else {
        currentStep.value--;
        _navigateToStep(currentStep.value);
      }
    }
  }

  void _navigateToStep(int step) {
    String route;
    switch (step) {
      case 0:
        route = Routes.BROADCAST_AUDIENCE;
        break;
      case 1:
        route = Routes.BROADCAST_CONTENT;
        break;
      case 2:
        route = Routes.BROADCAST_SCHEDULE;
        break;
      default:
        route = Routes.CREATE_BROADCAST;
    }

    Get.toNamed(route)?.then((_) {
      if (currentStep.value > 0) {
        currentStep.value--;
      }
    });
  }

  void selectTemplate(String templateId) {
    selectedTemplate.value = templateId;
  }

  String getSelectedAudienceName() {
    switch (selectedAudience.value) {
      case 'all':
        return 'All Contacts';
      case 'active':
        return 'Active Users';
      case 'import':
        return 'Imported Contacts';
      case 'custom':
        return 'Custom Selection';
      default:
        return 'Not selected';
    }
  }

  Future<void> calculateEstimatedRecipientsCount() async {
    contactDetails.clear();

    if (isPreview && contactIdsList.isNotEmpty) {
      //  IMPORTANT to avoid duplicates
      estimatedCount.value = contactIdsList.length.toString();

      if (selectedAudience.value == "import") {
        for (String phone in contactIdsList) {
          // Since we now store phone numbers, create a model with the phone number
          final c = ContactModel(
            id: '',
            fName: '',
            lName: '',
            phoneNumber: phone,
            countryCallingCode: '',
            email: '',
            company: '',
            tags: [],
            notes: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          contactDetails.add(c);
        }
      } else {
        // Fetch real contacts by ID
        final fetched = await ContactsService.instance.getContactsByIds(
          contactIdsList,
        );
        contactDetails.assignAll(fetched);
      }
      return;
    }

    // Populate contactDetails for the popup based on selected audience
    // Note: Don't clear segmentContacts here as it contains user selections
    if (selectedAudience.value == "all") {
      contactDetails.assignAll(allContacts);
    } else if (selectedAudience.value == "import") {
      contactDetails.assignAll(importedContacts);
    } else if (selectedAudience.value == "custom") {
      contactDetails.assignAll(segmentContacts);
    }
  }

  void _autoRemoveEmptyTags() {
    final tagsToRemove = <String>[];

    for (String tag in selectedTags) {
      final hasAnyContactSelected = segmentContacts.any(
        (c) => c.tags.contains(tag),
      );

      if (!hasAnyContactSelected) {
        tagsToRemove.add(tag);
      }
    }

    // Remove tags that have 0 corresponding contacts selected
    for (String tag in tagsToRemove) {
      selectedTags.remove(tag);
    }
  }

  void loadDraft(BroadcastTableModel draftTableModel) async {
    //  Fetch full Firestore model using ID
    final BroadcastModel? draft = await BroadcastFirebaseService.instance
        .getBroadcast(draftTableModel.id);

    if (draft == null) {
      Utilities.showSnackbar(SnackType.ERROR, 'Draft could not be loaded.');
      return;
    }

    //  Load name + description
    nameController.value.text = draft.broadcastName;
    descriptionController.value.text = draft.description;
    editingBroadcastId.value = draft.id!;
    enableRetry.value = draft.enableRetry ?? true;
    draftAdminId.value = draft.adminId ?? '';
    draftAdminName.value = draft.adminName ?? '';

    //  Load template
    selectedTemplate.value = draft.templateId ?? "";

    //  Convert audienceType (0/1/2 → string)
    switch (draft.audienceType) {
      case 0:
        selectedAudience.value = "all";
        break;
      case 1:
        selectedAudience.value = "import";
        break;
      case 2:
        selectedAudience.value = "custom";
        break;
      default:
        selectedAudience.value = "all";
    }

    // 5️⃣ Clear any existing contacts
    segmentContacts.clear();
    importedContacts.clear();

    // 6️⃣ Load selected contacts based on draft.contactIds
    if (draft.contactIds.isNotEmpty) {
      if (selectedAudience.value == "import") {
        for (String phone in draft.contactIds) {
          final ContactModel c = ContactModel(
            id: '',
            fName: '',
            lName: '',
            phoneNumber: phone,
            countryCallingCode: '',
            email: '',
            company: '',
            tags: [],
            notes: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          importedContacts.add(c);
        }
      } else {
        // Fetch real contacts for "all" or "custom"
        final fetched = await ContactsService.instance.getContactsByIds(
          draft.contactIds,
        );
        segmentContacts.assignAll(fetched);
      }
    } else {
      // Case B: Draft saved WITHOUT contactIds

      if (selectedAudience.value == "all") {
        // IMPORTANT FIX:
        // 🚫 Do NOT auto-fill all contacts
        // keep empty because user didn't select any contacts earlier
        segmentContacts.clear();
      }

      if (selectedAudience.value == "import") {
        // No imported contacts saved
        importedContacts.clear();
      }

      if (selectedAudience.value == "custom") {
        // No custom contacts saved
        segmentContacts.clear();
      }
    }

    // 7️⃣ Move to UI step 0
    currentStep.value = 0;

    // 8️⃣ Make UI form visible
    Get.find<BroadcastsController>().isCreatingBroadcast.value = true;

    Utilities.showSnackbar(SnackType.SUCCESS, 'Draft loaded successfully.');
  }

  /// ----------------------------------------------------------------
  /// MARK: - PREVIEW & VIEWING
  /// ----------------------------------------------------------------
  Future<void> viewBroadcast(BroadcastTableModel broadcastModel) async {
    try {
      isPreview = true;

      // Ensure loader is shown
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Utilities.showOverlayLoadingDialog();
      });

      // ----------------------------------------------------
      // 1️⃣ GET FULL BROADCAST MODEL
      // ----------------------------------------------------
      final BroadcastModel? broadcast = await BroadcastFirebaseService.instance
          .getBroadcast(broadcastModel.id);

      if (broadcast == null) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Broadcast could not be loaded.',
        );
        Utilities.hideCustomLoader(Get.context!);
        return;
      }

      // print("🔄 VIEWING BROADCAST: ${broadcast.broadcastName}");
      completedAt.value = broadcast.completedAt;
      enableRetry.value = broadcast.enableRetry ?? true;

      // ----------------------------------------------------
      // 2️⃣ LOAD TEMPLATE FROM TEMPLATE ID
      // ----------------------------------------------------
      final template = await TemplateFirestoreService.instance.getTemplateById(
        broadcast.templateId!,
      );

      deliveryOption.value = broadcast.deliveryType!;
      selectedScheduleTime.value = broadcast.deliveryTimestamp!;

      if (template == null) {
        Utilities.showSnackbar(SnackType.ERROR, 'Failed to load template.');
        Utilities.hideCustomLoader(Get.context!);
        return;
      }

      // Clear existing state before applying new template
      _resetTemplateState();

      templateType.value = template.templateType;

      // Template meta
      templateName.value = template.name;
      selectedTemplateId.value = template.id;
      templateHeader.value = template.headerText ?? "";
      originalTemplateBody.value = template.bodyText;
      templateBody.value = template.bodyText;

      // Detect header media type (IMAGE / VIDEO / DOCUMENT / TEXT)
      attachmentType.value = CreateBroadcastController._normalizeHeaderFormat(
        template.headerFormat,
      );

      // --- CAROUSEL INITIALIZATION ---
      if (template.templateType == "CAROUSEL") {
        _initializeCarouselCards(template);
      }

      // print("📎 Attachment Type from template: ${attachmentType.value}");

      // ----------------------------------------------------
      // 3️⃣ LOAD TEMPLATE VARIABLES FROM BROADCAST
      // ----------------------------------------------------
      // ----------------------------------------------------
      // 3️⃣ LOAD TEMPLATE VARIABLES FROM BROADCAST
      // ----------------------------------------------------
      if (template.buttons != null) {
        _initializeButtonControllers(template.buttons!);
      }

      if (broadcast.templateVariables != null) {
        for (int i = 0; i < broadcast.templateVariables!.length; i++) {
          final key = "body_${i + 1}";
          variableValues[key] = {
            "type": "static",
            "value": broadcast.templateVariables![i],
          };
          if (paramControllers.containsKey(key)) {
            paramControllers[key]!.text = broadcast.templateVariables![i];
          }
        }
      }

      // RESTORE CARD VARIABLES
      if (broadcast.cardVariables != null) {
        for (int i = 0; i < broadcast.cardVariables!.length; i++) {
          final cardData = broadcast.cardVariables![i];
          final bodyVars = cardData["bodyVariables"] as List?;
          if (bodyVars != null) {
            for (int j = 0; j < bodyVars.length; j++) {
              final key = "card_${i}_body_${j + 1}";
              variableValues[key] = {
                "type": "static",
                "value": bodyVars[j].toString(),
              };
              if (paramControllers.containsKey(key)) {
                paramControllers[key]!.text = bodyVars[j].toString();
              }
            }
          }
        }
      }

      // ----------------------------------------------------
      // 4️ RESTORE MEDIA PREVIEW (from Firebase Storage)
      // ----------------------------------------------------

      if (broadcast.attachmentId != null &&
          broadcast.attachmentId!.isNotEmpty) {
        final media = await BroadcastFirebaseService.instance.getBroadcastMedia(
          broadcast.attachmentId!,
        );

        if (media != null) {
          selectedFileBytes.value = media.bytes;
          selectedFileName.value = media.name;
        } else {
          debugPrint("❌ Media is NULL - failed to load from Firebase");
        }
      } else {
        debugPrint("⚠️ No attachment ID found in broadcast");
      }

      // ----------------------------------------------------
      // 5️⃣ RESTORE CAROUSEL MEDIA PREVIEW (from Firebase)
      // ----------------------------------------------------
      if (broadcast.cardAttachmentIds != null &&
          broadcast.cardAttachmentIds!.isNotEmpty) {
        for (int i = 0; i < broadcast.cardAttachmentIds!.length; i++) {
          if (i < carouselCards.length) {
            final attachmentId = broadcast.cardAttachmentIds![i];
            carouselCards[i].attachmentId.value = attachmentId;

            // Fetch actual media bytes for carousel cards
            if (attachmentId.isNotEmpty) {
              final media = await BroadcastFirebaseService.instance
                  .getBroadcastMedia(attachmentId);
              if (media != null) {
                carouselCards[i].fileBytes.value = media.bytes;
                carouselCards[i].fileName.value = media.name;
              }
            }
          }
        }
      }

      // ----------------------------------------------------
      // 6️⃣ RESTORE NAME FIELD
      // ----------------------------------------------------
      nameController.update((c) {
        c?.text = broadcast.broadcastName;
      });

      // ----------------------------------------------------
      // 6️⃣ RESTORE AUDIENCE TYPE
      // ----------------------------------------------------
      switch (broadcast.audienceType) {
        case 0:
          selectedAudience.value = "all";
          break;
        case 1:
          selectedAudience.value = "import";
          break;
        case 2:
          selectedAudience.value = "custom";
          break;
        default:
          selectedAudience.value = "all";
      }

      // ----------------------------------------------------
      // 7️⃣ RESTORE CONTACTS
      // ----------------------------------------------------
      contactIdsList.value = broadcast.contactIds;

      // print("👥 Contact Count: ${contactIdsList.length}");

      // ----------------------------------------------------
      // 8️⃣ REBUILD PREVIEW BUBBLE
      // ----------------------------------------------------
      updatePreviewBody(); // 🔥 IMPORTANT

      // print('Broadcast data loaded successfully for viewing');
    } catch (e, stackTrace) {
      print("ERROR in viewBroadcast(): $e");
      print("Stack trace: $stackTrace");
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Something went wrong while loading broadcast.',
      );
    } finally {
      // Ensure loader is hidden after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          if (Get.isDialogOpen == true) {
            Get.back(); // Close the dialog
            // print('Loader hidden after viewBroadcast');
          }
        } catch (e) {
          print('Error hiding loader: $e');
          // Fallback: try to close any open dialogs
          try {
            if (Get.context != null) {
              Navigator.of(Get.context!, rootNavigator: true).pop();
              // print('Fallback loader hidden');
            }
          } catch (e2) {
            print('Fallback loader hide failed: $e2');
          }
        }
      });
    }
  }

  /// ----------------------------------------------------------------
  /// MARK: - DRAFTS & SAVING
  /// ----------------------------------------------------------------
  void saveAsDraft() async {
    // Validate name
    if (selectedAudience.isEmpty) {
      Utilities.showSnackbar(SnackType.ERROR, 'Please select audience.');
      return;
    }
    final name = nameController.value.text.trim().isNotEmpty
        ? nameController.value.text.trim()
        : "Untitled Draft";

    // Convert audience → 0/1/2
    final int audienceInt = getAudienceTypeValue();

    // Convert contacts → list of IDs
    contactIdsList.value = audienceInt == 1
        ? finalRecipients
              .map(
                (c) =>
                    "${c.countryCallingCode!.startsWith('+') ? '' : '+'}${c.countryCallingCode}${c.phoneNumber}",
              )
              .toList()
        : finalRecipients
              .map((c) => c.id)
              .where((id) => id.isNotEmpty)
              .toList();
    // If editing existing draft → use that same ID
    final String docId = editingBroadcastId.value.isNotEmpty
        ? editingBroadcastId.value
        : "";
    // Create model
    final draft = BroadcastModel(
      id: docId,
      broadcastName: name,
      description: descriptionController.value.text.trim(),
      audienceType: audienceInt,
      status: "draft",
      contactIds: contactIdsList,
      completedAt: null,
      adminName: adminName.value.isNotEmpty
          ? adminName.value
          : (draftAdminName.value.isNotEmpty ? draftAdminName.value : 'Admin'),
      adminId: adminID.isNotEmpty
          ? adminID
          : (draftAdminId.value.isNotEmpty ? draftAdminId.value : null),
      enableRetry: enableRetry.value,
    );

    // Save to Firebase
    await BroadcastFirebaseService.instance.saveDraft(draft);
    Utilities.showSnackbar(SnackType.SUCCESS, 'Draft saved successfully.');

    // Reset & close form
    Future.delayed(const Duration(milliseconds: 800), () {
      currentStep.value = 0;
      nameController.value.clear();
      selectedTemplate.value = "";
      selectedAudience.value = "";
      importedContacts.clear();
      segmentContacts.clear();
      final broadcastsController = Get.find<BroadcastsController>();
      broadcastsController.closeCreateForm();
    });
  }

  int getAudienceTypeValue() {
    switch (selectedAudience.value) {
      case "all":
        return 0;
      case "import":
        return 1;
      case "custom":
        return 2;
      default:
        return 0;
    }
  }

  /// ----------------------------------------------------------------
  /// MARK: - UTILITIES & HELPERS
  /// ----------------------------------------------------------------
  bool validateSchedule() {
    if (deliveryOption.value == 1) {
      final now = DateTime.now().add(const Duration(seconds: 30));

      if (!selectedScheduleTime.value.isAfter(now)) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Scheduled time must be at least 1 minute in the future',
        );
        return false;
      }
    }
    return true;
  }

  /// Load wallet balance from Backend Client Details
  Future<void> loadWalletBalance() async {
    try {
      final client = await ClientsService().getClientById(clientID);
      if (client != null) {
        walletBalance.value = client.walletBalance;
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
    }
  }

  /// Map to store charges data loaded from local storage
  RxMap<String, dynamic> chargesData = <String, dynamic>{}.obs;

  /// Load dynamic charges from local storage
  void loadCharges() {
    try {
      final String? chargesJson = WebUtils.getFromLocalStorage('charges');
      if (chargesJson != null && chargesJson.isNotEmpty) {
        final Map<String, dynamic> decodedData = jsonDecode(chargesJson);
        chargesData.assignAll(decodedData);
        print('Loaded ${chargesData.length} charges from local storage');

        // Fallback or specific default for 'OTHER' or '(default)'
        if (chargesData.containsKey('OTHER')) {
          final dataOther = chargesData['OTHER'];
          marketingCostPerContact.value =
              (dataOther['marketing'] as num?)?.toDouble() ?? 0.80;
          utilityCostPerContact.value =
              (dataOther['utility'] as num?)?.toDouble() ?? 0.20;
        } else if (chargesData.containsKey('91')) {
          final data91 = chargesData['91'];
          marketingCostPerContact.value =
              (data91['marketing'] as num?)?.toDouble() ?? 0.80;
          utilityCostPerContact.value =
              (data91['utility'] as num?)?.toDouble() ?? 0.20;
        }
      } else {
        print('No charges found in local storage, using hardcoded defaults');
        marketingCostPerContact.value = 0.80;
        utilityCostPerContact.value = 0.20;
      }
    } catch (e) {
      print('Error loading charges from local storage: $e');
      marketingCostPerContact.value = 0.80;
      utilityCostPerContact.value = 0.20;
    }
  }

  /// Helper to lookup cost for a specific country and category
  double getCostForCountry(ContactModel contact, String category) {
    double markup = 0.0;

    // 0. Try Client ID
    if (chargesData.containsKey(clientID)) {
      final data = chargesData[clientID];
      if (category.toUpperCase() == 'MARKETING') {
        markup = (data['marketing'] as num?)?.toDouble() ?? 0.80;
      } else {
        markup = (data['utility'] as num?)?.toDouble() ?? 0.20;
      }
    }

    // 1. Try ISO Country Code (e.g., 'AE', 'AF')
    if (contact.isoCountryCode != null && contact.isoCountryCode!.isNotEmpty) {
      String isoCode = contact.isoCountryCode!.toUpperCase();
      if (chargesData.containsKey(isoCode)) {
        final data = chargesData[isoCode];
        if (category.toUpperCase() == 'MARKETING') {
          return ((data['marketing'] as num?)?.toDouble() ?? 0.80) *
              (1 + markup / 100);
        } else {
          return ((data['utility'] as num?)?.toDouble() ?? 0.20) *
              (1 + markup / 100);
        }
      }
    }

    // 2. Try Dial Code (e.g., '91', '44')
    String callingCode = contact.countryCallingCode!.replaceAll('+', '').trim();
    if (chargesData.containsKey(callingCode)) {
      final data = chargesData[callingCode];
      if (category.toUpperCase() == 'MARKETING') {
        return ((data['marketing'] as num?)?.toDouble() ?? 0.80) *
            (1 + markup / 100);
      } else {
        return ((data['utility'] as num?)?.toDouble() ?? 0.20) *
            (1 + markup / 100);
      }
    }

    // 3. Try "OTHER" or "(default)"
    if (chargesData.containsKey('OTHER')) {
      final data = chargesData['OTHER'];
      if (category.toUpperCase() == 'MARKETING') {
        return ((data['marketing'] as num?)?.toDouble() ?? 0.80) *
            (1 + markup / 100);
      } else {
        return ((data['utility'] as num?)?.toDouble() ?? 0.20) *
            (1 + markup / 100);
      }
    }

    if (chargesData.containsKey('(default)')) {
      final data = chargesData['(default)'];
      if (category.toUpperCase() == 'MARKETING') {
        return ((data['marketing'] as num?)?.toDouble() ?? 0.80) *
            (1 + markup / 100);
      } else {
        return ((data['utility'] as num?)?.toDouble() ?? 0.20) *
            (1 + markup / 100);
      }
    }

    // Default to '91' if specific country not found
    if (chargesData.containsKey('91')) {
      final data91 = chargesData['91'];
      if (category.toUpperCase() == 'MARKETING') {
        return ((data91['marketing'] as num?)?.toDouble() ?? 0.80) *
            (1 + markup / 100);
      } else {
        return ((data91['utility'] as num?)?.toDouble() ?? 0.20) *
            (1 + markup / 100);
      }
    }

    // Final hardcoded fallback
    return (category.toUpperCase() == 'MARKETING' ? 0.80 : 0.20) *
        (1 + markup / 100);
  }

  double calculateBroadcastCost() {
    // Get category from selected template
    final category =
        selectedTemplateParams.value?.category.toUpperCase() ?? 'UTILITY';

    double totalCost = 0.0;

    // Iterate through all recipients and calculate cost based on their country
    for (final contact in finalRecipients) {
      // Use ContactModel to determine country cost (checks ISO code then Dial code)
      final cost = getCostForCountry(contact, category);
      // print('   Cost for ${contact.phoneNumber}: ₹$cost');
      totalCost += cost;
    }

    return totalCost;
  }

  /// Show insufficient balance popup
  void showInsufficientBalancePopup(double requiredAmount) {
    // Use Get.dialog with proper delay to ensure it shows
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.dialog(
        AlertDialog(
          title: Center(
            child: const Text(
              'Insufficient Balance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Your current wallet balance is '),
                    TextSpan(
                      text: '₹${walletBalance.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  children: [
                    const TextSpan(text: 'You need '),
                    TextSpan(
                      text: '₹${requiredAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const TextSpan(text: ' to send this broadcast.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Shortfall: ₹${(requiredAmount - walletBalance.value).toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }
                Utilities.showSnackbar(
                  SnackType.INFO,
                  'Please contact admin to top up your wallet',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Top Up Wallet'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    });
  }

  Future<void> sendBroadcast() async {
    final stopwatch = Stopwatch()..start();
    try {
      isSending.value = true;
      // ----------------------------
      //  STEP 1: VALIDATION
      // ----------------------------
      if (selectedTemplateId.value.isEmpty || selectedAudience.value.isEmpty) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Please complete all steps before sending',
        );
        return;
      }
      bool isValidDt = validateSchedule();
      if (isValidDt) {
        final int messageCount = finalRecipients.length;

        // ----------------------------
        //  STEP 2: CHECK QUOTA BEFORE ANY UPLOAD/SAVE
        // ----------------------------
        final String date = (deliveryOption.value == 1)
            ? selectedScheduleTime.value.toIso8601String().split('T')[0]
            : DateTime.now().toIso8601String().split('T')[0];

        // ----------------------------
        //  STEP 2.5: CHECK WALLET BALANCE
        // ----------------------------
        final double totalCost = calculateBroadcastCost();

        if (totalCost > walletBalance.value) {
          isSending.value = false;
          showInsufficientBalancePopup(totalCost);
          return;
        }

        broadcastProgress.value = 0.0;
        Get.dialog(
          BroadcastProgressDialog(progress: broadcastProgress),
          barrierDismissible: false,
        );

        // ----------------------------
        //  STEP 3: PRE-GENERATE CLIENT-SIDE BROADCAST ID
        // ----------------------------
        final String broadcastId = editingBroadcastId.value.isNotEmpty
            ? editingBroadcastId.value
            : "bc_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(99999)}";

        // ----------------------------
        //  STEP 4: CAPTURE/BUILD BROADCAST MODEL
        // ----------------------------
        List<String> bodyVars = [];
        final sortedKeys =
            variableValues.keys.where((key) => key.startsWith("body_")).toList()
              ..sort((a, b) {
                int ai = int.parse(a.split("_")[1]);
                int bi = int.parse(b.split("_")[1]);
                return ai.compareTo(bi);
              });

        for (final key in sortedKeys) {
          bodyVars.add(variableValues[key]!["value"] ?? "");
        }

        BroadcastStatus pendingStatus = BroadcastStatus.pending;
        BroadcastStatus scheduledStatus = BroadcastStatus.scheduled;

        final broadcast = BroadcastModel(
          id: broadcastId,
          broadcastName: nameController.value.text.trim(),
          description: descriptionController.value.text.trim(),
          audienceType: getAudienceTypeValue(),
          status: deliveryOption.value == 0
              ? pendingStatus.label
              : scheduledStatus.label,
          contactIds: getAudienceTypeValue() == 1
              ? finalRecipients
                    .map(
                      (c) =>
                          "${c.countryCallingCode!.startsWith('+') ? '' : '+'}${c.countryCallingCode}${c.phoneNumber}",
                    )
                    .toList()
              : finalRecipients.map((c) => c.id).toList(),
          templateId: selectedTemplateId.value,
          templateVariables: bodyVars,
          cardVariables: templateType.value == "CAROUSEL"
              ? List.generate(carouselCards.length, (i) {
                  List<String> cardBodyVars = [];
                  final prefix = "card_${i}_body_";
                  final keys =
                      variableValues.keys
                          .where((k) => k.startsWith(prefix))
                          .toList()
                        ..sort(
                          (a, b) => int.parse(
                            a.split("_").last,
                          ).compareTo(int.parse(b.split("_").last)),
                        );
                  for (final k in keys) {
                    cardBodyVars.add(variableValues[k]!["value"] ?? "");
                  }
                  return {"bodyVariables": cardBodyVars};
                })
              : null,
          mediaId: mediaHandleId.value,
          attachmentId: null, // will be updated in background
          cardAttachmentIds: null, // will be updated in background
          deliveryType: deliveryOption.value,
          deliveryTimestamp: deliveryOption.value == 1
              ? selectedScheduleTime.value
              : DateTime.now(),
          completedAt: null,
          adminName: adminName.value.isNotEmpty
              ? adminName.value
              : (draftAdminName.value.isNotEmpty
                    ? draftAdminName.value
                    : 'Admin'),
          adminId: adminID.isNotEmpty
              ? adminID
              : (draftAdminId.value.isNotEmpty ? draftAdminId.value : null),
          totalCost: totalCost,
          enableRetry: enableRetry.value,
        );

        // ----------------------------
        //  STEP 5: PRE-GENERATE MESSAGE PAYLOADS & REFS
        // ----------------------------
        final String messageType =
            (templateType.value.toUpperCase() == 'TEXT & MEDIA')
            ? 'MEDIA'
            : templateType.value.toUpperCase();

        final List<String> messageIds = [];
        final List<Map<String, dynamic>> payloadJsons = [];
        int msgSeq = 0;

        for (final contact in finalRecipients) {
          final messageId =
              "msg_${DateTime.now().microsecondsSinceEpoch}_${msgSeq++}";

          // Build dynamic variables for THIS contact
          final bodyVars = buildBodyVarsForContact(contact);

          final phone = "${contact.countryCallingCode}${contact.phoneNumber}";
          Map<String, dynamic>? headerVars;

          final templateTypeUpper = templateType.value.toUpperCase();

          if (templateTypeUpper == "TEXT") {
            if (attachmentType.value.isNotEmpty) {
              headerVars = {"type": "TEXT", "text": attachmentType.value};
            }
          }

          if (templateTypeUpper == "INTERACTIVE" ||
              templateTypeUpper == "TEXT & MEDIA") {
            headerVars = mediaHandleId.value.isEmpty
                ? null
                : {
                    "type": attachmentType.value,
                    "data": {
                      "mediaId": mediaHandleId.value,
                      "fileName": selectedFileName.value,
                    },
                  };
          }

          final category =
              selectedTemplateParams.value?.category.toUpperCase() ?? 'UTILITY';
          final double costPerContactValue = getCostForCountry(
            contact,
            category,
          );

          final version = selectedTemplateParams.value?.version ?? 'v1';

          List<BroadcastCard>? cardVars;
          if (templateType.value.toUpperCase() == "CAROUSEL") {
            cardVars = buildCardVariablesForContact(contact);
            for (final card in cardVars) {
              final btnList = card.buttonVariable;
              if (btnList == null) continue;
              for (int bi = 0; bi < btnList.length; bi++) {
                final btn = btnList[bi];
                if (btn.payload == "__QUICK_REPLY_PLACEHOLDER__") {
                  btnList[bi] = BroadcastButton(
                    type: btn.type,
                    payload: "$broadcastId|$messageId",
                  );
                }
              }
            }
          }

          final payload = BroadcastMessagePayload(
            broadcastId: broadcastId,
            messageId: messageId,
            payload: Payload(
              templateName: templateName.value,
              language: templateLanguage,
              type: messageType,
              mobileNo: phone,
              bodyVariables: bodyVars,
              headerVariables: headerVars,
              buttonVariable: buildButtonVariables(
                version,
                broadcastId: broadcastId,
                messageId: messageId,
              ),
              cardVariables: cardVars,
              category: category,
              version: version,
            ),
            status: null,
            createdAt: DateTime.now(),
            cost: costPerContactValue,
          );

          messageIds.add(messageId);
          payloadJsons.add(payload.toJson());
        }

        final quota = QuotaModel(
          usedQuota: messageCount,
          broadcasts: [
            BroadcastHistory(
              broadcastId: broadcastId,
              messageCount: messageCount,
            ),
          ],
        );

        // ----------------------------
        //  STEP 6: CAPTURE UPLOAD & CARD CONFIGS
        // ----------------------------
        final Uint8List? mainFileBytes =
            mediaHandleId.value.isNotEmpty &&
                selectedFileBytes.value != null &&
                selectedFileName.value.isNotEmpty
            ? selectedFileBytes.value
            : null;
        final String mainFileName = selectedFileName.value;
        final String mainMimeType = mimeType.value;

        final List<CarouselCardUploadData> carouselUploads =
            templateType.value.toUpperCase() == "CAROUSEL"
            ? carouselCards.map((c) {
                return CarouselCardUploadData(
                  fileBytes: c.fileBytes.value,
                  fileName: c.fileName.value,
                  mediaType: c.mediaType.value,
                  mediaHandleId: c.mediaHandleId.value,
                  attachmentId: c.attachmentId.value,
                );
              }).toList()
            : [];

        // ----------------------------
        //  STEP 7: START COMPLETE BACKGROUND PROCESSING
        // ----------------------------
        final isScheduled = deliveryOption.value == 1;
        final scheduledTime = selectedScheduleTime.value;
        final isEditing = editingBroadcastId.value.isNotEmpty;

        await _sendBroadcastInBackground(
          broadcastId: broadcastId,
          broadcast: broadcast,
          messageIds: messageIds,
          payloadJsons: payloadJsons,
          quota: quota,
          quotaDate: date,
          isScheduled: isScheduled,
          scheduledTimestamp: scheduledTime,
          isEditing: isEditing,
          mainFileBytes: mainFileBytes,
          mainFileName: mainFileName,
          mainMimeType: mainMimeType,
          carouselUploads: carouselUploads,
        );

        // Allow UI to show 100% complete for a moment
        await Future.delayed(const Duration(milliseconds: 500));
        _closeBroadcastProgressDialog();

        // Show immediate user feedback
        if (isScheduled) {
          Utilities.showSnackbar(
            SnackType.SUCCESS,
            'Broadcast scheduled successfully!',
          );
        } else {
          Utilities.showSnackbar(
            SnackType.SUCCESS,
            'Broadcast has been initiated.',
          );
        }

        print(
          "sendBroadcast() processing thread completed in: ${stopwatch.elapsedMilliseconds}ms",
        );

        // ----------------------------
        //  STEP 8: RESET UI IMMEDIATELY
        // ----------------------------
        resetAll();

        final broadcastsController = Get.find<BroadcastsController>();

        broadcastsController.closeCreateForm();
      }
    } catch (e) {
      print("Broadcast error: $e");
      _closeBroadcastProgressDialog();
      Utilities.showSnackbar(SnackType.ERROR, "Failed to send broadcast: $e");
    } finally {
      isSending.value = false;
      _closeBroadcastProgressDialog();
      print(
        "sendBroadcast() total execution time: ${stopwatch.elapsedMilliseconds}ms",
      );
    }
  }

  void _closeBroadcastProgressDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    } else if (Get.overlayContext != null &&
        Navigator.of(Get.overlayContext!).canPop()) {
      Navigator.of(Get.overlayContext!).pop();
    }
  }

  final DateFormat uiDateFormat = DateFormat('dd MMM yyyy');

  String resolveChipValue(ContactModel contact, String chip) {
    if (selectedAudience.value == "import") {
      // Check custom attributes
      if (contact.customAttributes.containsKey(chip)) {
        final val = contact.customAttributes[chip];
        return (val != null && val.toString().trim().isNotEmpty)
            ? val.toString()
            : "-";
      }
      return "-";
    }

    switch (chip) {
      case "First Name":
        return (contact.fName != null && contact.fName!.trim().isNotEmpty)
            ? contact.fName!
            : "-";
      case "Last Name":
        return (contact.lName != null && contact.lName!.trim().isNotEmpty)
            ? contact.lName!
            : "-";
      case "Email":
        return (contact.email != null && contact.email!.trim().isNotEmpty)
            ? contact.email!
            : "-";
      case "Company":
        return (contact.company != null && contact.company!.trim().isNotEmpty)
            ? contact.company!
            : "-";
      case "Phone Number":
        return contact.phoneNumber;
      case "Country Code":
        return contact.isoCountryCode ?? "-";
      case "Calling Code":
        return contact.countryCallingCode ?? "-";

      case "Birth Date":
        return contact.birthdate != null
            ? uiDateFormat.format(contact.birthdate!)
            : "-";

      case "Anniversary":
        return contact.anniversaryDt != null
            ? uiDateFormat.format(contact.anniversaryDt!)
            : "-";

      case "Work Anniversary":
        return contact.workAnniversaryDt != null
            ? uiDateFormat.format(contact.workAnniversaryDt!)
            : "-";
    }
    return "-";
  }

  List<BroadcastCard> buildCardVariablesForContact(ContactModel contact) {
    List<BroadcastCard> cards = [];

    for (int i = 0; i < carouselCards.length; i++) {
      final card = carouselCards[i];

      // 1. Build Header Variables
      Map<String, dynamic>? headerVars;
      if (card.mediaHandleId.value.isNotEmpty) {
        headerVars = {
          "type": card.mediaType.value.toLowerCase(), // image / video
          "data": {
            "mediaId": card.mediaHandleId.value,
            "fileName": card.fileName.value,
            "attachmentId": card.attachmentId.value,
          },
        };
      }

      // 2. Build Body Variables
      List<String> bodyVars = [];
      final bodyPrefix = "card_${i}_body_";
      final bodyKeys =
          variableValues.keys.where((k) => k.startsWith(bodyPrefix)).toList()
            ..sort((a, b) {
              int ai = int.parse(a.split("_").last);
              int bi = int.parse(b.split("_").last);
              return ai.compareTo(bi);
            });

      for (final key in bodyKeys) {
        final map = variableValues[key] ?? {};
        final type = map["type"] ?? "static";
        final value = map["value"] ?? "";

        if (type == "dynamic") {
          bodyVars.add(resolveChipValue(contact, value));
        } else {
          bodyVars.add(value);
        }
      }

      // 3. Build Button Variables
      List<BroadcastButton> buttons = [];
      for (int btnIndex = 0; btnIndex < card.buttons.length; btnIndex++) {
        final btn = card.buttons[btnIndex];
        if (btn.type.toUpperCase() == "URL") {
          final btnPrefix = "card_${i}_btn_${btnIndex}_url_";
          final btnKeys =
              variableValues.keys.where((k) => k.startsWith(btnPrefix)).toList()
                ..sort((a, b) {
                  int ai = int.parse(a.split("_").last);
                  int bi = int.parse(b.split("_").last);
                  return ai.compareTo(bi);
                });

          String? payloadValue;
          if (btnKeys.isNotEmpty) {
            final key = btnKeys.first;
            final map = variableValues[key] ?? {};
            final type = map["type"] ?? "static";
            final value = map["value"] ?? "";
            payloadValue = (type == "dynamic")
                ? resolveChipValue(contact, value)
                : value;
          }

          buttons.add(
            BroadcastButton(
              type: "url",
              payload: payloadValue ?? "",
              url: btn.url,
            ),
          );
        } else if (btn.type.toUpperCase() == "QUICK_REPLY") {
          // payload will be injected with broadcastId|messageId when saving
          buttons.add(
            BroadcastButton(
              type: "quick_reply",
              payload: "__QUICK_REPLY_PLACEHOLDER__",
            ),
          );
        }
      }

      cards.add(
        BroadcastCard(
          headerVariables: headerVars,
          bodyVariables: bodyVars,
          buttonVariable: buttons,
        ),
      );
    }

    return cards;
  }

  List<String> buildBodyVarsForContact(ContactModel contact) {
    List<String> vars = [];

    final sortedKeys =
        variableValues.keys.where((key) => key.startsWith("body_")).toList()
          ..sort((a, b) {
            int ai = int.parse(a.split("_")[1]);
            int bi = int.parse(b.split("_")[1]);
            return ai.compareTo(bi);
          });

    for (final key in sortedKeys) {
      final map = variableValues[key] ?? {};
      final type = map["type"] ?? "static";
      final value = map["value"] ?? "";

      if (type == "dynamic") {
        final resolved = resolveChipValue(contact, value);
        vars.add(resolved);
      } else {
        vars.add(value);
      }
    }

    return vars;
  }

  Future<void> _sendBroadcastInBackground({
    required String broadcastId,
    required BroadcastModel broadcast,
    required List<String> messageIds,
    required List<Map<String, dynamic>> payloadJsons,
    required QuotaModel quota,
    required String quotaDate,
    required bool isScheduled,
    required DateTime scheduledTimestamp,
    required bool isEditing,
    required Uint8List? mainFileBytes,
    required String mainFileName,
    required String mainMimeType,
    required List<CarouselCardUploadData> carouselUploads,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Initial progress
      broadcastProgress.value = 0.05;

      // 1. Upload files in parallel (if any)
      String? attachmentId;
      List<String> cardAttachmentIds = [];
      final List<Future<dynamic>> uploadFutures = [];

      final int totalUploads =
          (mainFileBytes != null && mainFileName.isNotEmpty ? 1 : 0) +
          carouselUploads
              .where(
                (card) =>
                    card.fileBytes != null &&
                    card.fileName.isNotEmpty &&
                    card.attachmentId.isEmpty,
              )
              .length;
      int completedUploads = 0;

      Future<UploadResult?>? mainUploadFuture;
      if (mainFileBytes != null && mainFileName.isNotEmpty) {
        mainUploadFuture =
            uploadFileToFirebase(
                  fileBytes: mainFileBytes,
                  fileName: mainFileName,
                  folder: 'broadcasts_media/$clientID',
                  mimeType: mainMimeType,
                )
                .timeout(
                  const Duration(seconds: 8),
                  onTimeout: () {
                    print(
                      "Firebase Storage upload timed out; skipping storage backup",
                    );
                    return UploadResult(
                      id: '',
                      url: '',
                      fileName: mainFileName,
                    );
                  },
                )
                .catchError((e) {
                  print(
                    "Firebase Storage upload error: $e; skipping storage backup",
                  );
                  return UploadResult(id: '', url: '', fileName: mainFileName);
                })
                .then((res) {
                  completedUploads++;
                  broadcastProgress.value =
                      0.05 + 0.25 * (completedUploads / totalUploads);
                  return res;
                });
        uploadFutures.add(mainUploadFuture);
      }

      final List<Future<UploadResult>> carouselUploadFutures = [];
      if (carouselUploads.isNotEmpty) {
        for (var card in carouselUploads) {
          if (card.fileBytes != null &&
              card.fileName.isNotEmpty &&
              card.attachmentId.isEmpty) {
            final fut =
                uploadFileToFirebase(
                      fileBytes: card.fileBytes!,
                      fileName: card.fileName,
                      folder: 'broadcasts_media/$clientID',
                      mimeType: card.mediaType.toUpperCase() == "IMAGE"
                          ? "image/jpeg"
                          : "video/mp4",
                    )
                    .timeout(
                      const Duration(seconds: 8),
                      onTimeout: () {
                        print(
                          "Carousel Firebase upload timed out; skipping storage backup",
                        );
                        return UploadResult(
                          id: '',
                          url: '',
                          fileName: card.fileName,
                        );
                      },
                    )
                    .catchError((e) {
                      print(
                        "Carousel Firebase upload error: $e; skipping storage backup",
                      );
                      return UploadResult(
                        id: '',
                        url: '',
                        fileName: card.fileName,
                      );
                    })
                    .then((res) {
                      completedUploads++;
                      broadcastProgress.value =
                          0.05 + 0.25 * (completedUploads / totalUploads);
                      return res;
                    });
            carouselUploadFutures.add(fut);
            uploadFutures.add(fut);
          }
        }
      }

      if (uploadFutures.isNotEmpty) {
        await Future.wait(uploadFutures);

        if (mainUploadFuture != null) {
          final mainUploadResult = await mainUploadFuture;
          if (mainUploadResult != null && mainUploadResult.id.isNotEmpty) {
            attachmentId = mainUploadResult.id;
          }
        }

        for (int i = 0; i < carouselUploadFutures.length; i++) {
          final result = await carouselUploadFutures[i];
          if (result.id.isNotEmpty) {
            cardAttachmentIds.add(result.id);
            carouselUploads[i].attachmentId = result.id;
          }
        }
      } else {
        broadcastProgress.value = 0.30;
      }

      // Add pre-existing attachment IDs from carousel uploads
      for (var card in carouselUploads) {
        if (card.attachmentId.isNotEmpty) {
          cardAttachmentIds.add(card.attachmentId);
        }
      }

      // Update the broadcast model with the attachment IDs
      final updatedBroadcast = BroadcastModel(
        id: broadcast.id,
        broadcastName: broadcast.broadcastName,
        description: broadcast.description,
        audienceType: broadcast.audienceType,
        status: broadcast.status,
        contactIds: broadcast.contactIds,
        templateId: broadcast.templateId,
        templateName: broadcast.templateName ?? templateName.value,
        language: broadcast.language ?? templateLanguage,
        templateVariables: broadcast.templateVariables,
        cardVariables: broadcast.cardVariables,
        mediaId: broadcast.mediaId,
        attachmentId: attachmentId ?? broadcast.attachmentId,
        cardAttachmentIds: cardAttachmentIds.isNotEmpty
            ? cardAttachmentIds
            : null,
        deliveryType: broadcast.deliveryType,
        deliveryTimestamp: broadcast.deliveryTimestamp,
        completedAt: broadcast.completedAt,
        adminName: broadcast.adminName,
        adminId:
            broadcast.adminId ??
            (adminID.isNotEmpty
                ? adminID
                : (draftAdminId.value.isNotEmpty ? draftAdminId.value : null)),
        totalCost: broadcast.totalCost,
        enableRetry: broadcast.enableRetry,
      );

      broadcastProgress.value = 0.35;

      // Prepare contacts payload
      final List<Map<String, dynamic>> contactsPayload = [];
      for (int i = 0; i < messageIds.length; i++) {
        final Map<String, dynamic> payloadJson = payloadJsons[i];
        final payloadData = payloadJson["payload"] ?? {};

        // If it is a carousel, update card attachmentIds with background uploads
        if (cardAttachmentIds.isNotEmpty &&
            payloadJson.containsKey("payload") &&
            payloadJson["payload"] != null) {
          final List<dynamic>? cards = payloadData["cardVariables"];
          if (cards != null) {
            for (int ci = 0; ci < cards.length; ci++) {
              if (ci < carouselUploads.length) {
                final card = cards[ci];
                if (card is Map &&
                    card.containsKey("headerVariables") &&
                    card["headerVariables"] != null) {
                  final header = card["headerVariables"];
                  if (header is Map &&
                      header.containsKey("data") &&
                      header["data"] != null) {
                    final data = header["data"];
                    if (data is Map &&
                        data.containsKey("attachmentId") &&
                        (data["attachmentId"] == null ||
                            data["attachmentId"].toString().isEmpty)) {
                      data["attachmentId"] = carouselUploads[ci].attachmentId;
                    }
                  }
                }
              }
            }
          }
        }

        contactsPayload.add({
          "mobileNo": payloadData["mobileNo"] ?? "",
          "bodyVariables": payloadData["bodyVariables"] ?? [],
        });
      }

      broadcastProgress.value = 0.50;
      await BroadcastFirebaseService.instance.saveBroadcast(
        updatedBroadcast,
        contacts: contactsPayload,
      );

      broadcastProgress.value = 0.85;

      // 4. Queue Broadcast
      await BroadcastQueueService.queueBroadcast(
        broadcastId: broadcastId,
        isScheduled: isScheduled,
        scheduledTimestamp: scheduledTimestamp,
      );
      broadcastProgress.value = 1.0;

      print(
        "Background broadcast processing completed successfully for: $broadcastId",
      );
      stopwatch.stop();
      print(
        "Background broadcast processing completed successfully for: $broadcastId in ${stopwatch.elapsedMilliseconds}ms",
      );
    } catch (e) {
      print("Error in background broadcast processing: $e");
      rethrow;
    }
  }

  List<BroadcastButton> buildButtonVariables(
    // String category,
    String version, {
    required String broadcastId,
    required String messageId,
  }) {
    List<BroadcastButton> list = [];

    for (int i = 0; i < buttons.length; i++) {
      final btn = buttons[i];
      final baseUrl = btnValueCtrls[i].text.trim();
      final isDynamic =
          btn.type == "URL" && urlType.length > i && urlType[i] == "Dynamic";

      String? btnUrl;
      // String? btnCategory;

      if (version == 'v2') {
        // btnCategory = category;
        if (btn.type == "URL") {
          btnUrl = baseUrl;
        }
      }

      // COPY_CODE → payload = example code
      if (btn.type == "COPY_CODE") {
        list.add(
          BroadcastButton(
            type: btn.type,
            payload: baseUrl,
            url: btnUrl,
            // category: btnCategory,
          ),
        );
      }
      // URL
      else if (btn.type == "URL") {
        String finalUrl = "";

        if (isDynamic) {
          final dynamicPart = dynamicValueCtrl[i].text.trim();

          if (dynamicPart.isNotEmpty) {
            // Remove leading slash from dynamic value
            String cleanDynamic = dynamicPart.replaceAll(RegExp(r'^\/+'), '');
            finalUrl = cleanDynamic;
          } else {
            finalUrl = baseUrl; // if dynamic empty, fallback to base URL
          }
        } else {
          // Static URLs → payload stays empty
          finalUrl = "";
        }

        // Reconstruct the full URL if dynamic replacement is needed
        String? reconstructedUrl = btnUrl;
        if (isDynamic &&
            finalUrl.isNotEmpty &&
            reconstructedUrl != null &&
            reconstructedUrl.contains("{{1}}")) {
          reconstructedUrl = reconstructedUrl.replaceAll("{{1}}", finalUrl);
        }

        list.add(
          BroadcastButton(
            type: btn.type,
            payload: finalUrl,
            url: reconstructedUrl,
            // category: btnCategory,
          ),
        );
      }
      // PHONE_NUMBER
      else if (btn.type == "PHONE_NUMBER") {
        list.add(
          BroadcastButton(
            type: btn.type,
            payload: baseUrl,
            url: btnUrl,
            // category: btnCategory,
          ),
        );
      }
      // QUICK_REPLY → payload = broadcastId|messageId
      else if (btn.type == "QUICK_REPLY") {
        list.add(
          BroadcastButton(
            type: btn.type,
            payload: "$broadcastId|$messageId",
            url: btnUrl,
            // category: btnCategory,
          ),
        );
      }
      // Fallback
      else {
        list.add(
          BroadcastButton(
            type: btn.type,
            payload: baseUrl,
            url: btnUrl,
            // category: btnCategory,
          ),
        );
      }
    }

    return list;
  }

  Future<String> sendBroadcastToFirebase(
    String? attachmentId,
    List<String> cardAttachmentIds,
  ) async {
    String broadcastId = "";
    List<String> bodyVars = [];

    final sortedKeys =
        variableValues.keys.where((key) => key.startsWith("body_")).toList()
          ..sort((a, b) {
            int ai = int.parse(a.split("_")[1]);
            int bi = int.parse(b.split("_")[1]);
            return ai.compareTo(bi);
          });

    for (final key in sortedKeys) {
      bodyVars.add(variableValues[key]!["value"] ?? "");
    }
    BroadcastStatus pendingStatus = BroadcastStatus.pending;
    BroadcastStatus scheduledStatus = BroadcastStatus.scheduled;

    // Calculate total cost for this broadcast
    final double totalCost = calculateBroadcastCost();

    final broadcast = BroadcastModel(
      id: editingBroadcastId.value.isNotEmpty ? editingBroadcastId.value : "",
      broadcastName: nameController.value.text.trim(),
      description: descriptionController.value.text.trim(),
      audienceType: getAudienceTypeValue(),
      status: deliveryOption.value == 0
          ? pendingStatus.label
          : scheduledStatus.label,
      contactIds: getAudienceTypeValue() == 1
          ? finalRecipients
                .map(
                  (c) =>
                      "${c.countryCallingCode!.startsWith('+') ? '' : '+'}${c.countryCallingCode}${c.phoneNumber}",
                )
                .toList()
          : finalRecipients.map((c) => c.id).toList(),
      templateId: selectedTemplateId.value,
      templateName: templateName.value,
      language: templateLanguage,
      templateVariables: bodyVars,
      cardVariables: templateType.value == "CAROUSEL"
          ? List.generate(carouselCards.length, (i) {
              List<String> cardBodyVars = [];
              final prefix = "card_${i}_body_";
              final keys =
                  variableValues.keys
                      .where((k) => k.startsWith(prefix))
                      .toList()
                    ..sort(
                      (a, b) => int.parse(
                        a.split("_").last,
                      ).compareTo(int.parse(b.split("_").last)),
                    );
              for (final k in keys) {
                cardBodyVars.add(variableValues[k]!["value"] ?? "");
              }
              return {"bodyVariables": cardBodyVars};
            })
          : null,
      mediaId: mediaHandleId.value,
      attachmentId: attachmentId,
      cardAttachmentIds: cardAttachmentIds.isNotEmpty
          ? cardAttachmentIds
          : null,
      deliveryType: deliveryOption.value,
      deliveryTimestamp: deliveryOption.value == 1
          ? selectedScheduleTime.value
          : DateTime.now(),
      completedAt: null,
      adminName: adminName.value.isNotEmpty ? adminName.value : 'Admin',
      totalCost: totalCost,
      enableRetry: enableRetry.value,
    );
    // broadcastId = await BroadcastFirebaseService.instance.saveBroadcast(
    //   broadcast,
    // );
    if (editingBroadcastId.value.isNotEmpty) {
      //print("🔥 Updating draft with STATUS: ${broadcast.status}");

      broadcastId = editingBroadcastId.value;
      await BroadcastFirebaseService.instance.updateDraft(
        editingBroadcastId.value,
        broadcast,
      );
    } else {
      //print("🔥 Saving broadcast with STATUS: ${broadcast.status}");

      broadcastId = await BroadcastFirebaseService.instance.saveBroadcast(
        broadcast,
      );
    }

    if (broadcastId.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Failed to create broadcast. Please try again.",
      );
    } else {
      //print("Broadcast created with ID: $broadcastId");
    }
    return broadcastId;
  }

  Future<void> sendFinalBroadcast() async {
    if (selectedTemplateId.value.isEmpty) {
      Utilities.showSnackbar(SnackType.ERROR, "Please select a template");
      return;
    }

    // 👉 Collect body variables in correct sorted order
    List<String> bodyVars = [];

    final sortedKeys =
        variableValues.keys.where((key) => key.startsWith("body_")).toList()
          ..sort((a, b) {
            int ai = int.parse(a.split("_")[1]);
            int bi = int.parse(b.split("_")[1]);
            return ai.compareTo(bi);
          });

    for (final key in sortedKeys) {
      bodyVars.add(variableValues[key]!["value"] ?? "");
    }

    final String messageType = attachmentType.value.isEmpty ? "TEXT" : "MEDIA";

    // 👉 Loop through all contacts & send template message
    for (final contact in finalRecipients) {
      final String phone =
          "${contact.countryCallingCode}${contact.phoneNumber}";

      await BroadcastService.instance.sendTemplateMessage(
        templateName: templateName.value,
        language: templateLanguage,
        type: messageType,
        mobileNo: phone,
        bodyVariables: bodyVars,
        headerType: attachmentType.value,
        mediaId: mediaHandleId.value,
        fileName: selectedFileName.value,
      );
    }
  }

  void resetAll() {
    // Step
    currentStep.value = 0;
    nameController.value.clear();
    descriptionController.value.clear();
    // Audience
    selectedAudience.value = "";
    segmentContacts.clear();
    importedContacts.clear();
    templateLanguage = "";
    // Template
    selectedTemplateId.value = "";
    selectedTemplate.value = "";
    templateName.value = "";
    selectedTemplateParams.value = null;
    ctaUrlLinkTrackingOptedOut.value = false;

    // Template fields
    originalTemplateBody.value = "";
    templateBody.value = "";
    templateHeader.value = "";

    // Variables
    variableValues.clear();
    paramControllers.clear();
    paramErrors.clear();
    btnValueErrors.clear();
    dynamicValueCtrl.clear();
    urlType.clear();
    // Media
    attachmentType.value = "";
    selectedFileBytes.value = null;
    selectedFileName.value = "";
    selectedFileError.value = "";
    mediaHandleId.value = "";
    isUploadingMedia.value = false;

    // Contacts
    selectedTags.clear();
    contactSearch.value = "";
    estimatedCount.value = "0";
    finalRecipientCount.value = 0;
    contactDetails.clear();

    // UI states
    showSegmentPopup.value = false;
    isEdit.value = false;
    editingBroadcastId.value = "";
    completedAt.value = null;
    isPreview = false;
    enableRetry.value = false;

    // Rebuild empty preview
    updatePreviewBody();
  }

  // 🔥 ALWAYS fetch latest contacts when opening segment popup
  Future<void> refreshContactsForSegmentPopup() async {
    try {
      // Fetch latest contacts from API
      final fetchedContacts = await ContactsService.instance.getAllContacts();
      allContacts.assignAll(fetchedContacts);

      // Fetch latest tags from API
      final dbTags = await ContactsService.instance.getAllTags();

      // Collect tags explicitly from contacts to ensure we don't miss any 'orphan' tags
      final contactTags = <String>{};
      for (var c in fetchedContacts) {
        contactTags.addAll(c.tags);
      }

      // Merge and sort unique tags
      final mergedTags = <String>{...dbTags, ...contactTags}.toList();
      mergedTags.sort();

      availableTags.assignAll(mergedTags);

      // Re-apply selected tags filter if any
      if (selectedTags.isNotEmpty) {
        segmentContacts.clear();

        for (String tag in selectedTags) {
          final contactsOfTag = allContacts
              .where((c) => c.tags.contains(tag) && c.status != 0)
              .toList();

          for (var c in contactsOfTag) {
            if (!segmentContacts.any((x) => x.id == c.id)) {
              segmentContacts.add(c);
            }
          }
        }
      }

      // Re-apply search filter
      if (contactSearch.value.isNotEmpty) {
        updateSearch(contactSearch.value);
      }
    } catch (e) {
      //print("❌ Error refreshing contacts for segment popup: $e");
    }
  }
}

class CarouselCardUploadData {
  final Uint8List? fileBytes;
  final String fileName;
  final String mediaType;
  final String mediaHandleId;
  String attachmentId;

  CarouselCardUploadData({
    required this.fileBytes,
    required this.fileName,
    required this.mediaType,
    required this.mediaHandleId,
    required this.attachmentId,
  });
}
