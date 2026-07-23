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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:business_whatsapp/main.dart';


class TemplatesController extends GetxController {
  final RxBool isCreatingTemplate = false.obs;
  final templates = <TemplateModels>[].obs;

  // Pagination details
  String? nextCursor;
  String? prevCursor;
  final RxInt pageSize = 10.obs;
  final List<int> availablePageSizes = [10, 25, 50, 100];
  final RxInt currentPage = 1.obs;

  // Pagination display helpers
  int get startItem => ((currentPage.value - 1) * pageSize.value) + 1;
  int get endItem => (startItem - 1) + templates.length;

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
  final RxBool isNextLoading = false.obs;
  final RxBool isPrevLoading = false.obs;

  static TemplatesController get instance => Get.find<TemplatesController>();

  @override
  void onInit() {
    super.onInit();
    loadInitialTemplates();
  }

  Future<void> loadInitialTemplates() async {
    currentPage.value = 1;
    nextCursor = null;
    prevCursor = null;
    templates.clear(); // Clear existing data to trigger shimmer/loading state
    await fetchTemplates(limit: pageSize.value);
  }

  void setLanguageFilter(String name) {
    selectedLanguageName.value = name;

    if (name == 'All') {
      selectedLanguageCode.value = 'All';
    } else {
      selectedLanguageCode.value = LanguageCodes.languageCodeMap[name]!;
    }
    loadInitialTemplates();
  }

  // ---------------------------------------------------------------------------
  // Reusable API: Fetch templates with pagination
  // ---------------------------------------------------------------------------
  Future<void> fetchTemplates({
    int? limit,
    String? after,
    String? before,
    bool showMainLoader = true,
  }) async {
    try {
      if (showMainLoader) isLoading.value = true;

      final result = await TemplateService.instance.getInteraktTemplates(
        limit: limit ?? pageSize.value,
        after: after,
        before: before,
        status: selectedStatus.value,
        category: selectedCategory.value,
        language: selectedLanguageCode.value,
      );

      if (!result["success"]) {
        Utilities.showSnackbar(SnackType.ERROR, "Failed to load templates");
        return;
      }

      final response = result["data"];
      final list = response?["data"]?["data"] ?? [];

      if (list is! List) {
        return;
      }

      final parsed = list
          .map((json) => TemplateModels.fromJson(json))
          .toList()
          .cast<TemplateModels>();

      if (parsed.isEmpty && (after != null || before != null)) {
        Utilities.showSnackbar(SnackType.INFO, "No more templates found on this page.");
        // Don't update templates or cursors so the user stays on the current valid page
        return;
      }

      templates.assignAll(parsed);

      // Update cursors
      final paging = response?["data"]?["paging"]?["cursors"];
      nextCursor = paging?["after"];
      prevCursor = paging?["before"];

      // Update page number only if we actually moved
      if (after != null) {
        currentPage.value++;
      } else if (before != null && currentPage.value > 1) {
        currentPage.value--;
      }
    } catch (e) {
      //print("GET ERROR — $e");
      Utilities.showSnackbar(SnackType.ERROR, "Unable to fetch templates");
    } finally {
      isLoading.value = false;
      isNextLoading.value = false;
      isPrevLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (nextCursor == null || isNextLoading.value) return;
    isNextLoading.value = true;
    await fetchTemplates(
      limit: pageSize.value,
      after: nextCursor,
      showMainLoader: false,
    );
  }

  Future<void> loadPreviousPage() async {
    if (prevCursor == null || isPrevLoading.value) return;
    isPrevLoading.value = true;
    await fetchTemplates(
      limit: pageSize.value,
      before: prevCursor,
      showMainLoader: false,
    );
  }

  void updatePageSize(int newSize) {
    pageSize.value = newSize;
    loadInitialTemplates();
  }

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
    Utilities.showSnackbar(SnackType.SUCCESS, "Template deleted successfully.");

    loadInitialTemplates();
  }

  void onTemplateAction(TemplateModels template, String action) {
    switch (action) {
      case 'view':
        _viewTemplate(template);
        break;
      case 'copy':
        _copyTemplate(template);
        break;
      case 'delete':
        _confirmDelete(template);
        break;
    }
  }

  Future<void> _viewTemplate(TemplateModels template) async {
    try {
      Utilities.showOverlayLoadingDialog();

      final doc = await FirebaseFirestore.instance
          .collection('templates')
          .doc(clientID)
          .collection('data')
          .doc(template.id.toString())
          .get();

      Utilities.hideCustomLoader(Get.context!);

      if (!doc.exists) {
        Utilities.showSnackbar(SnackType.ERROR, "Template data not found in database.");
        return;
      }

      final fullTemplate = TemplateModels.fromFirestore(doc.data()!);

      final c = Get.find<CreateTemplateController>();
      c.loadTemplateForView(fullTemplate);
      Get.toNamed(Routes.CREATE_TEMPLATE);

      // Update navigation controller state for mobile compatibility
      final navController = Get.find<NavigationController>();
      navController.currentRoute.value = Routes.CREATE_TEMPLATE;
      navController.selectedIndex.value = 4; // Templates index
      navController.routeTrigger.value++;
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(SnackType.ERROR, "Failed to load template data: $e");
    }
  }

  Future<void> _copyTemplate(TemplateModels template) async {
    try {
      Utilities.showOverlayLoadingDialog();

      final doc = await FirebaseFirestore.instance
          .collection('templates')
          .doc(clientID)
          .collection('data')
          .doc(template.id.toString())
          .get();

      Utilities.hideCustomLoader(Get.context!);

      if (!doc.exists) {
        Utilities.showSnackbar(SnackType.ERROR, "Template data not found in database.");
        return;
      }

      final fullTemplate = TemplateModels.fromFirestore(doc.data()!);

      final c = Get.find<CreateTemplateController>();
      c.loadTemplateForCopy(fullTemplate);
      Get.toNamed(Routes.CREATE_TEMPLATE);

      // Update navigation controller state for mobile compatibility
      final navController = Get.find<NavigationController>();
      navController.currentRoute.value = Routes.CREATE_TEMPLATE;
      navController.selectedIndex.value = 4; // Templates index
      navController.routeTrigger.value++;
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(SnackType.ERROR, "Failed to load template data: $e");
    }
  }

  void _confirmDelete(TemplateModels template) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: "Delete Template",
        content: "Are you sure you want to delete '${template.name}'?",
        onConfirm: () async {
          Get.back();
          await deleteTemplate(template);
        },
      ),
    );
  }

  void createTemplate() {
    final createController = Get.find<CreateTemplateController>();
    createController.resetForm();
    // TemplateFirestoreService.instance.insertStaticTemplates();
    createController.isEditMode.value = false;
    createController.isCopyMode.value = false;
    createController.isViewMode.value = false;
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
  void setStatusFilter(String v) {
    selectedStatus.value = v;
    loadInitialTemplates();
  }

  void setCategoryFilter(String v) {
    selectedCategory.value = v;
    loadInitialTemplates();
  }
}
