import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/modules/milestone_templates/controllers/create_milestone_schedular_controller.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Utilities/utilities.dart' show Utilities;
import 'package:business_whatsapp/app/common%20widgets/common_alert_dialog_delete.dart';

class MilestoneSchedularsController extends GetxController {
  // ---------------------------------------------------------------------------
  // 🟢 Reactive UI Controls
  // ---------------------------------------------------------------------------
  final RxList<Map<String, dynamic>> schedulars = <Map<String, dynamic>>[].obs;

  // Filters
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final selectedCategory = 'All'.obs;
  // Language filter removed

  // Search controller
  final searchController = TextEditingController();

  // Form fields
  final RxString schedularName = ''.obs;
  final RxString schedularType = 'birthday'.obs;
  final RxString schedularContent = ''.obs;
  final RxBool isLoading = false.obs;

  static MilestoneSchedularsController get instance =>
      Get.find<MilestoneSchedularsController>();

  // ---------------------------------------------------------------------------
  // 🟢 INIT
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    loadInitialSchedulars();
  }

  // ---------------------------------------------------------------------------
  // 🟦 1) Load first page
  // ---------------------------------------------------------------------------
  Future<void> loadInitialSchedulars() async {
    await fetchSchedulars();
  }

  // Alias for loadInitialSchedulars (used by create controller)
  Future<void> loadSchedulars() async {
    await loadInitialSchedulars();
  }

  // ---------------------------------------------------------------------------
  // 🟦 Reusable API: Fetch schedulars with pagination
  // ---------------------------------------------------------------------------
  Future<void> fetchSchedulars() async {
    try {
      isLoading.value = true;

      final snapshot = await FirebaseFirestore.instance
          .collection('milestone_schedulars')
          .doc(clientID)
          .collection('data')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      schedulars.assignAll(list);
      isLoading.value = false;
    } catch (e) {
      print("GET ERROR — $e");
      isLoading.value = false;
      Utilities.showSnackbar(SnackType.ERROR, "Unable to fetch schedulars");
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 2) NEXT page logic
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // 🟥 Delete Schedular
  // ---------------------------------------------------------------------------
  Future<void> deleteSchedular(String id) async {
    Utilities.showOverlayLoadingDialog();

    try {
      await FirebaseFirestore.instance
          .collection('milestone_schedulars')
          .doc(clientID)
          .collection('data')
          .doc(id)
          .delete();

      // Call API to delete cron job
      await _deleteMilestoneCronJob(id);

      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        "Schedular deleted successfully.",
      );
      fetchSchedulars();
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(SnackType.ERROR, "Delete failed. Try again.");
    }
  }

  Future<void> toggleSchedularStatus(String id, String currentStatus) async {
    Utilities.showOverlayLoadingDialog();
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';

    try {
      await FirebaseFirestore.instance
          .collection('milestone_schedulars')
          .doc(clientID)
          .collection('data')
          .doc(id)
          .update({'status': newStatus});

      // Call API to pause/resume cron job
      if (newStatus == 'paused') {
        await _pauseMilestoneCronJob(id);
      } else if (newStatus == 'active') {
        await _resumeMilestoneCronJob(id);
      }

      // Update local state instead of fetching everything again
      final index = schedulars.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        schedulars[index]['status'] = newStatus;
        schedulars.refresh(); // Trigger UI update
      }

      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        "Schedular ${newStatus == 'active' ? 'activated' : 'paused'} successfully.",
      );
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(SnackType.ERROR, "Update failed. Try again.");
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 Schedular Actions
  // ---------------------------------------------------------------------------
  void onSchedularAction(Map<String, dynamic> schedular, String action) {
    switch (action) {
      case 'edit':
        _editSchedular(schedular);
        break;
      case 'toggle':
        toggleSchedularStatus(schedular['id'], schedular['status'] ?? 'active');
        break;
      case 'delete':
        _confirmDelete(schedular);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // 🟦 COPY Schedular
  // ---------------------------------------------------------------------------
  void _editSchedular(Map<String, dynamic> schedular) {
    // Bind the create controller if not already bound
    if (!Get.isRegistered<CreateMilestoneSchedularController>()) {
      Get.lazyPut<CreateMilestoneSchedularController>(
        () => CreateMilestoneSchedularController(),
      );
    }

    final c = Get.find<CreateMilestoneSchedularController>();
    c.loadSchedularForCopy(schedular);
    c.isEditMode.value = true;
    c.isCopyMode.value = false;

    // Navigate to create route
    Get.toNamed(Routes.CREATE_MILESTONE_SCHEDULARS);

    // Update navigation controller to keep sidebar active
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().updateRoute();
    }
  }

  // ---------------------------------------------------------------------------
  // 🟥 Confirm Delete Popup
  // ---------------------------------------------------------------------------
  void _confirmDelete(Map<String, dynamic> schedular) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: "Delete Schedular",
        content: "Are you sure you want to delete '${schedular['name']}'?",
        onConfirm: () async {
          await deleteSchedular(schedular['id']);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟦 Create Schedular
  // ---------------------------------------------------------------------------
  void createSchedular() {
    // Bind the create controller if not already bound
    if (!Get.isRegistered<CreateMilestoneSchedularController>()) {
      Get.lazyPut<CreateMilestoneSchedularController>(
        () => CreateMilestoneSchedularController(),
      );
    }

    final createController = Get.find<CreateMilestoneSchedularController>();
    createController.resetForm();
    createController.isEditMode.value = false;
    createController.isCopyMode.value = false;
    createController.editingSchedular = null;

    _resetForm();

    // Navigate to create route
    Get.toNamed(Routes.CREATE_MILESTONE_SCHEDULARS);

    // Update navigation controller to keep sidebar active
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().updateRoute();
    }
  }

  void _resetForm() {
    schedularName.value = '';
    schedularType.value = 'birthday';
    schedularContent.value = '';
  }

  // ---------------------------------------------------------------------------
  // 🟦 FILTERS
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredSchedulars {
    return schedulars.where((schedular) {
      final matchesSearch = (schedular['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(searchQuery.value.toLowerCase());

      final matchesStatus =
          selectedStatus.value == 'All' ||
          (schedular['status'] ?? '').toString().toLowerCase() ==
              selectedStatus.value.toLowerCase();

      final matchesCategory =
          selectedCategory.value == 'All' ||
          (schedular['type'] ?? '').toString().toLowerCase() ==
              selectedCategory.value.toLowerCase();

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String q) => searchQuery.value = q;
  void setStatusFilter(String v) => selectedStatus.value = v;
  void setCategoryFilter(String v) => selectedCategory.value = v;

  // ===========================================================================
  // 🟦 MILESTONE CRON JOB API CALLS
  // ===========================================================================

  Future<void> _pauseMilestoneCronJob(String schedulerId) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.pauseMilestone,
        data: {'clientId': clientID, 'schedulerId': schedulerId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
        } else {
          print('❌ Failed to pause milestone cron job: ${data['message']}');
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error pausing milestone cron job: $e');
    }
  }

  Future<void> _resumeMilestoneCronJob(String schedulerId) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.resumeMilestone,
        data: {'clientId': clientID, 'schedulerId': schedulerId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
        } else {
          print('❌ Failed to resume milestone cron job: ${data['message']}');
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error resuming milestone cron job: $e');
    }
  }

  Future<void> _deleteMilestoneCronJob(String schedulerId) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        ApiEndpoints.deleteMilestone,
        data: {'clientId': clientID, 'schedulerId': schedulerId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
        } else {
          print('❌ Failed to delete milestone cron job: ${data['message']}');
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting milestone cron job: $e');
    }
  }
}
