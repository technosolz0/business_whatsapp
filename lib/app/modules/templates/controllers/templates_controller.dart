import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:business_whatsapp/app/core/constants/language_codes.dart';
// import 'package:business_whatsapp/app/core/utils/utilities.dart';
import 'package:business_whatsapp/app/data/models/template_model.dart';
import 'package:business_whatsapp/app/modules/templates/controllers/create_template_controller.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Utilities/utilities.dart' show Utilities;
import '../../../data/services/template_service.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';

class TemplatesController extends GetxController {
  // ---------------------------------------------------------------------------
  // 🟢 Reactive UI Controls
  // ---------------------------------------------------------------------------
  final RxBool isCreatingTemplate = false.obs;
  final templates = <TemplateModels>[].obs;

  // Pagination details
  String? nextCursor;
  String? prevCursor;
  int limit = 10;

  // Filters
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final selectedCategory = 'All'.obs;
  RxString selectedLanguageName = 'All'.obs;
  RxString selectedLanguageCode = 'All'.obs;

  // Form fields
  final RxString templateName = ''.obs;
  final RxString templateType = 'Marketing'.obs;
  final RxString templateContent = ''.obs;
  final RxBool isLoading = false.obs;

  static TemplatesController get instance => Get.find<TemplatesController>();

  // ---------------------------------------------------------------------------
  // 🟢 INIT
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    loadInitialTemplates();
  }

  // ---------------------------------------------------------------------------
  // 🟦 1) Load first page
  // ---------------------------------------------------------------------------
  Future<void> loadInitialTemplates() async {
    await fetchTemplates(limit: limit);
  }

  void setLanguageFilter(String name) {
    selectedLanguageName.value = name;

    if (name == 'All') {
      selectedLanguageCode.value = 'All';
    } else {
      selectedLanguageCode.value = LanguageCodes.languageCodeMap[name]!;
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 Reusable API: Fetch templates with pagination
  // ---------------------------------------------------------------------------
  Future<void> fetchTemplates({
    int? limit,
    String? after,
    String? before,
  }) async {
    try {
      isLoading.value = true;

      final result = await TemplateService.instance.getInteraktTemplates(
        limit: limit ?? this.limit,
        after: after,
        before: before,
      );

      if (!result["success"]) {
        Utilities.showSnackbar(SnackType.ERROR, "Failed to load templates");
        return;
      } else {
        isLoading.value = false;
      }

      final response = result["data"];
      final list = response?["data"]?["data"] ?? [];

      if (list is! List) {
        //print("❌ Unexpected API format: ${list.runtimeType}");
        return;
      }

      final parsed = list
          .map((json) => TemplateModels.fromJson(json))
          .toList()
          .cast<TemplateModels>();

      templates.assignAll(parsed);

      // Update cursors
      final paging = response?["data"]?["paging"]?["cursors"];
      nextCursor = paging?["after"];
      prevCursor = paging?["before"];
    } catch (e) {
      //print("GET ERROR — $e");
      Utilities.showSnackbar(SnackType.ERROR, "Unable to fetch templates");
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 2) NEXT page logic
  // ---------------------------------------------------------------------------
  Future<void> loadNextPage() async {
    if (nextCursor == null) return;

    final result = await TemplateService.instance.getInteraktTemplates(
      limit: limit,
      after: nextCursor,
    );

    final data = result["data"]?["data"]?["data"] ?? [];

    // No more data
    if (data.isEmpty) {
      nextCursor = null;
      Utilities.showSnackbar(SnackType.INFO, "No more templates available");
      return;
    }

    await fetchTemplates(limit: limit, after: nextCursor);
  }

  // ---------------------------------------------------------------------------
  // 🟦 3) PREVIOUS page logic
  // ---------------------------------------------------------------------------
  Future<void> loadPreviousPage() async {
    if (prevCursor == null) {
      Utilities.showSnackbar(
        SnackType.INFO,
        "You’re already on the first page.",
      );
      return;
    }

    final result = await TemplateService.instance.getInteraktTemplates(
      limit: limit,
      before: prevCursor,
    );

    final data = result["data"]?["data"]?["data"] ?? [];

    if (data.isEmpty) {
      prevCursor = null;
      Utilities.showSnackbar(
        SnackType.ERROR,
        "No previous templates available",
      );
      return;
    }

    await fetchTemplates(limit: limit, before: prevCursor);
  }

  // ---------------------------------------------------------------------------
  // 🟥 Delete Template
  // ---------------------------------------------------------------------------
  Future<void> deleteTemplate(TemplateModels template) async {
    if (template.name.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Template name missing. Unable to delete.",
      );
      return;
    }

    Utilities.showOverlayLoadingDialog();

    final result = await TemplateService.instance.deleteInteraktTemplate(
      templateName: template.name,
    );

    Utilities.hideCustomLoader(Get.context!);

    if (!result["success"]) {
      Utilities.showSnackbar(SnackType.ERROR, "Delete failed. Try again.");
      return;
    }
    Utilities.showSnackbar(SnackType.ERROR, "Template deleted successfully.");

    loadInitialTemplates();
  }

  // ---------------------------------------------------------------------------
  // 🟦 Template Actions
  // ---------------------------------------------------------------------------
  void onTemplateAction(TemplateModels template, String action) {
    switch (action) {
      case 'copy':
        _copyTemplate(template);
        break;
      case 'delete':
        _confirmDelete(template);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 COPY Template
  // ---------------------------------------------------------------------------
  void _copyTemplate(TemplateModels template) {
    final c = Get.find<CreateTemplateController>();

    final base = TemplateModels(
      id: template.id.toString(),
      name: template.name,
      status: template.status,
      category: template.category,
      language: template.language,
      type: template.type,
      headerText: template.headerText ?? '',
      body: template.body,
      footer: template.footer ?? '',
      headerFormat: template.headerFormat,
      variables: template.variables,
      // headerImage: template.headerImage,
      headerVariables: template.headerVariables,
      buttons: template.buttons,
    );

    c.loadTemplateForCopy(base);
    Get.toNamed(Routes.CREATE_TEMPLATE);

    // Update navigation controller state for mobile compatibility
    final navController = Get.find<NavigationController>();
    navController.currentRoute.value = Routes.CREATE_TEMPLATE;
    navController.selectedIndex.value = 4; // Templates index
    navController.routeTrigger.value++;
  }

  // ---------------------------------------------------------------------------
  // 🟥 Confirm Delete Popup
  // ---------------------------------------------------------------------------
  void _confirmDelete(TemplateModels template) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: "Delete Template",
        content: "Are you sure you want to delete '${template.name}'?",
        onConfirm: () async {
          await deleteTemplate(template);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟦 Create Template
  // ---------------------------------------------------------------------------
  void createTemplate() {
    final createController = Get.find<CreateTemplateController>();
    createController.resetForm();
    // TemplateFirestoreService.instance.insertStaticTemplates();
    createController.isEditMode.value = false;
    createController.isCopyMode.value = false;
    createController.editingTemplate = null;

    Get.offNamedUntil(
      Routes.CREATE_TEMPLATE,
      ModalRoute.withName(Routes.TEMPLATES),
    );

    // Update navigation controller state for mobile compatibility
    final navController = Get.find<NavigationController>();
    navController.currentRoute.value = Routes.CREATE_TEMPLATE;
    navController.selectedIndex.value = 4; // Templates index
    navController.routeTrigger.value++;

    _resetForm();
  }

  void cancelCreation() {
    isCreatingTemplate.value = false;
    _resetForm();
  }

  void _resetForm() {
    templateName.value = '';
    templateType.value = 'Marketing';
    templateContent.value = '';
  }

  // ---------------------------------------------------------------------------
  // 🟦 FILTERS
  // ---------------------------------------------------------------------------
  List<TemplateModels> get filteredTemplates {
    return templates.where((template) {
      final matchesSearch = template.name.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );

      return matchesSearch &&
          (selectedStatus.value == 'All' ||
              template.status == selectedStatus.value) &&
          (selectedCategory.value == 'All' ||
              template.category == selectedCategory.value) &&
          (selectedLanguageCode.value == 'All' ||
              template.language == selectedLanguageCode.value);
    }).toList();
  }

  void setSearchQuery(String q) => searchQuery.value = q;
  void setStatusFilter(String v) => selectedStatus.value = v;
  void setCategoryFilter(String v) => selectedCategory.value = v;
}
