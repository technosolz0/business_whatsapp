import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';

import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
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

import 'package:business_whatsapp/app/data/services/template_firebase_service.dart';
import 'package:business_whatsapp/app/data/services/upload_file_firebase.dart';
import 'package:business_whatsapp/app/modules/broadcasts/views/widgets/segment_filter_popup.dart';
import 'package:business_whatsapp/app/modules/contacts/services/import_service.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/utilities/constants/app_constants.dart';
import 'package:chips_input_autocomplete/chips_input_autocomplete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'broadcasts_controller.dart';
import '../../../data/models/broadcast_table_model.dart';
import 'package:business_whatsapp/main.dart';

import 'package:intl/intl.dart';

class CreateBroadcastController extends GetxController {
  final RxInt currentStep = 0.obs;
  final RxString selectedTemplate = ''.obs;
  final RxString selectedAudience = ''.obs;
  final nameController = TextEditingController().obs;
  final descriptionController = TextEditingController().obs;
  final RxString editingBroadcastId = ''.obs;
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

  Map<String, TextEditingController> paramControllers = {};

  /// Store variable inputs (static/dynamic)
  final Map<String, Map<String, String>> variableValues = {};
  List<TextEditingController> dynamicValueCtrl = [];
  List<String> urlType = []; // Static / Dynamic

  void updatePreviewBody() {
    appliedValues.clear();
    String updated = originalTemplateBody.value;

    ContactModel? previewContact = finalRecipients.isNotEmpty
        ? finalRecipients.first
        : null;

    variableValues.forEach((key, data) {
      if (!key.startsWith("body_")) return;

      final index = key.split("_")[1];
      final placeholder = "{{$index}}";
      final type = data["type"] ?? "empty";
      final rawValue = data["value"] ?? "";

      String displayValue = rawValue;
      bool shouldReplace = false;

      // --------------------------------------------------
      // STATIC
      // --------------------------------------------------
      if (type == "static") {
        if (rawValue.isNotEmpty) {
          displayValue = rawValue;
          shouldReplace = true;
        } else {
          shouldReplace = false;
        }
      }

      // --------------------------------------------------
      // DYNAMIC
      // --------------------------------------------------
      if (type == "dynamic") {
        String resolved = "";
        if (previewContact != null) {
          resolved = resolveChipValue(previewContact, rawValue);
        }

        // If dynamic resolved to "-" or empty → USE RAW VALUE
        if (resolved.isEmpty || resolved == "-") {
          displayValue = rawValue; // 🔥 show chip name
        } else {
          displayValue = resolved; // dynamic resolved value
        }

        shouldReplace = true; // always replace for dynamic
      }

      // --------------------------------------------------
      // APPLY LOGIC
      // --------------------------------------------------
      if (shouldReplace) {
        updated = updated.replaceAll(placeholder, displayValue);
        appliedValues.add(displayValue);
      } else {
        appliedValues.add(placeholder);
      }
    });

    templateBody.value = updated;
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
    for (final c in paramControllers.values) {
      c.dispose();
    }
    paramControllers.clear();
    paramErrors.clear();
  }

  ///
  /// ------------------------------------------------

  void loadTemplates() async {
    try {
      // Fetch approved templates from the new API
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getApprovedTemplates,
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final apiTemplates = data['data'] as List<dynamic>;

          // Convert API response to TemplateParamModel format
          // Since API only provides name/id, we'll create minimal models
          // and fetch full details from Firebase when template is selected
          final templates = apiTemplates.map((template) {
            return TemplateParamModel(
              id: template['id'].toString(),
              name: template['name'].toString(),
              language: 'en', // Default language
              headerVars: 0,
              bodyVars: 0,
              headerFormat: '',
              templateType: 'Text',
              category: template['category'].toString(),
              headerText: null,
              headerExamples: [],
              bodyText: '',
              bodyExamples: [],
              buttons: null,
              buttonVars: 0,
            );
          }).toList();

          templateList.value = templates;
          // print('✅ Loaded ${templates.length} approved templates from API');
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      print('❌ Error loading templates from API: $e');
      // Fallback to Firebase if API fails
      // print('🔄 Falling back to Firebase templates');
      templateList.value = await TemplateFirestoreService.instance
          .getAllTemplatesForBroadcast();
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
      ),
    );

    // Set basic template info immediately for UI responsiveness
    selectedTemplateParams.value = basicTemplate;
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
        updatePreviewBody();
      }
    } catch (e) {
      print('❌ Error loading full template details: $e');
      // Keep the basic template info that was already set
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
        "Email",
        "Company",
        "Tags",
        "Notes",
        "Birthdate",
        "Anniversary",
        "Work Anniversary",
        "Birthdate Month",
        "Anniversary Month",
        "Work Anniversary Month",
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

        importedContacts.assignAll(contactModels);

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
    allContacts.assignAll(await ContactsService.instance.getAllContacts());
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
          .where((c) => c.tags.contains(tagName))
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
      mediaHandleId.value = result["media_id"];
    } else {
      selectedFileError.value = "Failed to upload media.";
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
      segmentContacts.add(contact);
    }

    // Auto remove tags whose contacts are now fully deselected
    _autoRemoveEmptyTags();
  }

  RxList<ContactModel> get finalRecipients {
    if (isPreview) return contactDetails;

    if (selectedAudience.value == "all") {
      return allContacts;
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

      // QUICK REPLY validation
      if (btn.type == "QUICK_REPLY" && value.isEmpty) {
        btnValueErrors[i] = "Quick reply text is missing";
        firstErrorMessage ??= btnValueErrors[i];
        hasButtonError = true;
      }

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
      currentStep.value--;
      _navigateToStep(currentStep.value);
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

    Get.toNamed(route);
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
      // 🔥 IMPORTANT to avoid duplicates
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
    // 1️⃣ Fetch full Firestore model using ID
    final BroadcastModel? draft = await BroadcastFirebaseService.instance
        .getBroadcast(draftTableModel.id);

    if (draft == null) {
      Utilities.showSnackbar(SnackType.ERROR, 'Draft could not be loaded.');
      return;
    }

    // 2️⃣ Load name + description
    nameController.value.text = draft.broadcastName;
    descriptionController.value.text = draft.description;
    editingBroadcastId.value = draft.id!;

    // 3️⃣ Load template
    selectedTemplate.value = draft.templateId ?? "";

    // 4️⃣ Convert audienceType (0/1/2 → string)
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
          variableValues["body_${i + 1}"] = {
            "type": "static",
            "value": broadcast.templateVariables![i],
          };
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
          print("❌ Media is NULL - failed to load from Firebase");
        }
      } else {
        print("⚠️ No attachment ID found in broadcast");
      }

      // ----------------------------------------------------
      // 5️⃣ RESTORE NAME FIELD
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

  /// Load wallet balance from Firebase
  void loadWalletBalance() {
    FirebaseFirestore.instance
        .collection('profile')
        .doc(clientID)
        .collection('data')
        .doc('wallet')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
              walletBalance.value = balance;
            } else {
              walletBalance.value = 0.0;
            }
          },
          onError: (error) {
            print('Error loading wallet balance: $error');
            walletBalance.value = 0.0;
          },
        );
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
    // 1. Try ISO Country Code (e.g., 'AE', 'AF')
    if (contact.isoCountryCode != null && contact.isoCountryCode!.isNotEmpty) {
      String isoCode = contact.isoCountryCode!.toUpperCase();
      if (chargesData.containsKey(isoCode)) {
        final data = chargesData[isoCode];
        if (category.toUpperCase() == 'MARKETING') {
          return (data['marketing'] as num?)?.toDouble() ?? 0.80;
        } else {
          return (data['utility'] as num?)?.toDouble() ?? 0.20;
        }
      }
    }

    // 2. Try Dial Code (e.g., '91', '44')
    String callingCode = contact.countryCallingCode!.replaceAll('+', '').trim();
    if (chargesData.containsKey(callingCode)) {
      final data = chargesData[callingCode];
      if (category.toUpperCase() == 'MARKETING') {
        return (data['marketing'] as num?)?.toDouble() ?? 0.80;
      } else {
        return (data['utility'] as num?)?.toDouble() ?? 0.20;
      }
    }

    // 3. Try "OTHER" or "(default)"
    if (chargesData.containsKey('OTHER')) {
      final data = chargesData['OTHER'];
      if (category.toUpperCase() == 'MARKETING') {
        return (data['marketing'] as num?)?.toDouble() ?? 0.80;
      } else {
        return (data['utility'] as num?)?.toDouble() ?? 0.20;
      }
    }

    if (chargesData.containsKey('(default)')) {
      final data = chargesData['(default)'];
      if (category.toUpperCase() == 'MARKETING') {
        return (data['marketing'] as num?)?.toDouble() ?? 0.80;
      } else {
        return (data['utility'] as num?)?.toDouble() ?? 0.20;
      }
    }

    // Default to '91' if specific country not found
    if (chargesData.containsKey('91')) {
      final data91 = chargesData['91'];
      if (category.toUpperCase() == 'MARKETING') {
        return (data91['marketing'] as num?)?.toDouble() ?? 0.80;
      } else {
        return (data91['utility'] as num?)?.toDouble() ?? 0.20;
      }
    }

    // Final hardcoded fallback
    return category.toUpperCase() == 'MARKETING' ? 0.80 : 0.20;
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

  void sendBroadcast() async {
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

        final bool exceed = await BroadcastFirebaseService.instance
            .willExceedQuota(messageCount, date);

        if (exceed) {
          Future.delayed(const Duration(milliseconds: 30), () {
            Utilities.showSnackbar(
              SnackType.ERROR,
              "You have reached the daily limit of ${AppConstants.dailyLimit}.",
            );
          });
          return;
        }

        // ----------------------------
        //  STEP 2.5: CHECK WALLET BALANCE
        // ----------------------------
        final double totalCost = calculateBroadcastCost();

        if (totalCost > walletBalance.value) {
          isSending.value = false;
          showInsufficientBalancePopup(totalCost);
          return;
        }

        Utilities.showOverlayLoadingDialog();

        //  STEP 3: UPLOAD FILE IF ANY
        // ----------------------------
        String? attachmentId;

        if (mediaHandleId.value.isNotEmpty &&
            selectedFileBytes.value != null &&
            selectedFileName.value.isNotEmpty) {
          final upload = await uploadFileToFirebase(
            fileBytes: selectedFileBytes.value!,
            fileName: selectedFileName.value,
            folder: 'broadcasts_media/$clientID',
            mimeType: mimeType.value,
          );
          attachmentId = upload.id;
        }

        // ----------------------------
        //  STEP 4: SAVE BROADCAST IN FIREBASE
        // ----------------------------
        final String broadcastId = await sendBroadcastToFirebase(attachmentId);

        // ----------------------------
        //  STEP 5: SAVE QUOTA
        // ----------------------------
        final quota = QuotaModel(
          usedQuota: messageCount,
          broadcasts: [
            BroadcastHistory(
              broadcastId: broadcastId,
              messageCount: messageCount,
            ),
          ],
        );

        await BroadcastFirebaseService.instance.saveQuota(quota, date);

        // ----------------------------
        //  STEP 6: SAVE PAYLOAD
        // ----------------------------
        await savePayloadInBroadcast(broadcastId);

        // ----------------------------
        //  STEP 7: RESET UI
        // ----------------------------
        resetAll();

        final broadcastsController = Get.find<BroadcastsController>();

        broadcastsController.closeCreateForm();
      }
    } catch (e) {
      //print("Broadcast error: $e");
    } finally {
      isSending.value = false;
      Utilities.hideCustomLoader(Get.context!);
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

  Future<void> savePayloadInBroadcast(String broadcastId) async {
    if (selectedTemplateId.value.isEmpty) {
      Utilities.showSnackbar(SnackType.ERROR, "Please select a template");
      return;
    }

    final String messageType = (templateType.value == 'Text & Media')
        ? 'MEDIA'
        : templateType.value.toUpperCase();

    for (final contact in finalRecipients) {
      // 👉 Build dynamic variables for THIS contact
      final bodyVars = buildBodyVarsForContact(contact);

      final phone = "${contact.countryCallingCode}${contact.phoneNumber}";
      Map<String, dynamic>? headerVars;

      if (messageType == "TEXT") {
        // If there is a text header variable
        if (attachmentType.value.isNotEmpty) {
          headerVars = {"type": "TEXT", "text": attachmentType.value};
        }
      }

      if (templateType.value == "Interactive" ||
          templateType.value == "Text & Media") {
        headerVars = mediaHandleId.isEmpty
            ? null
            : {
                "type": attachmentType.value, // IMAGE / VIDEO / DOCUMENT
                "data": {
                  "mediaId": mediaHandleId.value,
                  "fileName": selectedFileName.value,
                },
              };
      }

      // Get cost per contact based on template category and this specific contact's data
      final category =
          selectedTemplateParams.value?.category.toUpperCase() ?? 'UTILITY';
      final double costPerContactValue = getCostForCountry(contact, category);

      final payload = BroadcastMessagePayload(
        broadcastId: broadcastId,
        messageId: null, // will be auto-set by Firestore
        payload: Payload(
          templateName: templateName.value,
          language: templateLanguage,
          type: messageType,
          mobileNo: phone,
          bodyVariables: bodyVars,
          headerVariables: headerVars,
          buttonVariable: buildButtonVariables(),
        ),
        status: null,
        createdAt: DateTime.now(),
        cost: costPerContactValue,
      );

      await BroadcastFirebaseService.instance.addBroadcastMessage(
        broadcastId,
        payload,
      );
    }

    await BroadcastQueueService.queueBroadcast(
      broadcastId: broadcastId,
      isScheduled: deliveryOption.value == 0 ? false : true,
      scheduledTimestamp: selectedScheduleTime.value,
    );

    if (deliveryOption.value == 1) {
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
  }

  List<BroadcastButton> buildButtonVariables() {
    List<BroadcastButton> list = [];

    for (int i = 0; i < buttons.length; i++) {
      final btn = buttons[i];
      final baseUrl = btnValueCtrls[i].text.trim();
      final isDynamic =
          btn.type == "URL" && urlType.length > i && urlType[i] == "Dynamic";

      // COPY_CODE → payload = example code
      if (btn.type == "COPY_CODE") {
        list.add(BroadcastButton(type: btn.type, payload: baseUrl));
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

        list.add(BroadcastButton(type: btn.type, payload: finalUrl));
      }
      // PHONE_NUMBER
      else if (btn.type == "PHONE_NUMBER") {
        list.add(BroadcastButton(type: btn.type, payload: baseUrl));
      }
      // QUICK_REPLY → payload = button text
      else if (btn.type == "QUICK_REPLY") {
        list.add(BroadcastButton(type: btn.type, payload: btn.text.trim()));
      }
      // Fallback
      else {
        list.add(BroadcastButton(type: btn.type, payload: baseUrl));
      }
    }

    return list;
  }

  // List<BroadcastButton> buildButtonVariables() {
  //   List<BroadcastButton> list = [];

  //   for (int i = 0; i < buttons.length; i++) {
  //     final btn = buttons[i];
  //     final valueCtrl = btnValueCtrls[i];

  //     // COPY_CODE → payload = code (example)
  //     if (btn.type == "COPY_CODE") {
  //       list.add(
  //         BroadcastButton(
  //           type: btn.type,
  //           payload: valueCtrl.text.trim(), // coupon/promo code
  //         ),
  //       );
  //     }
  //     // URL → payload = final URL
  //     else if (btn.type == "URL") {
  //       list.add(
  //         BroadcastButton(
  //           type: btn.type,
  //           payload: "",
  //           // payload: valueCtrl.text.trim(), // final URL
  //         ),
  //       );
  //     }
  //     // PHONE_NUMBER → payload = number
  //     else if (btn.type == "PHONE_NUMBER") {
  //       list.add(
  //         BroadcastButton(
  //           type: btn.type,
  //           payload: valueCtrl.text.trim(), // phone number
  //         ),
  //       );
  //     }
  //     // QUICK_REPLY → payload = button title
  //     else if (btn.type == "QUICK_REPLY") {
  //       list.add(
  //         BroadcastButton(
  //           type: btn.type,
  //           payload: btn.text.trim(), // button label works as payload
  //         ),
  //       );
  //     }
  //     // Unknown button type (safe fallback)
  //     else {
  //       list.add(
  //         BroadcastButton(type: btn.type, payload: valueCtrl.text.trim()),
  //       );
  //     }
  //   }

  //   return list;
  // }

  Future<String> sendBroadcastToFirebase(String? attactmentId) async {
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
      templateVariables: bodyVars,
      mediaId: mediaHandleId.value,
      attachmentId: attactmentId,
      deliveryType: deliveryOption.value,
      deliveryTimestamp: deliveryOption.value == 1
          ? selectedScheduleTime.value
          : DateTime.now(),
      completedAt: null,
      adminName: adminName.value.isNotEmpty ? adminName.value : 'Admin',
      totalCost: totalCost,
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
              .where((c) => c.tags.contains(tag))
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
