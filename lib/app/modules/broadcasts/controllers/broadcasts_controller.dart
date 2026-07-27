import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/data/models/broadcast_model.dart';
import 'package:business_whatsapp/app/data/services/broadcast_firebase_service.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/main.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';
import '../../../common widgets/custom_button.dart';
import '../../../data/models/broadcast_status.dart';
import '../../../data/models/broadcast_table_model.dart';
import 'create_broadcast_controller.dart';

class BroadcastsController extends GetxController {
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'All'.obs;
  final service = BroadcastFirebaseService.instance;
  final RxBool isCreatingBroadcast = false.obs;
  final Rx<BroadcastTableModel?> selectedBroadcast = Rx<BroadcastTableModel?>(
    null,
  );
  final searchController = TextEditingController();
  RxBool isLoading = false.obs;

  Future<void> showOverview(BroadcastTableModel broadcast) async {
    selectedBroadcast.value = broadcast;
  }

  // pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalRecords = 0.obs;
  final int pageSize = 10;

  @override
  void onInit() {
    super.onInit();
    loadBroadcasts(page: 1);
  }

  // 🔥 FIXED PAGINATED LOADER
  Future<void> loadBroadcasts({required int page}) async {
    try {
      isLoading.value = true;

      // Get total count first (for pagination calculation)
      final int total = await service.getBroadcastsCount();

      // If no broadcasts, reset everything
      if (total == 0) {
        broadcasts.clear();
        totalRecords.value = 0;
        totalPages.value = 1;
        currentPage.value = 1;
        isLoading.value = false;
        return;
      }

      // Calculate total pages based on ALL records
      totalPages.value = (total / pageSize).ceil();

      // Ensure page is within valid range
      final validPage = page.clamp(1, totalPages.value);
      currentPage.value = validPage;

      // Fetch paginated data
      final List<BroadcastModel> data = await service.getBroadcastsPaginated(
        page: validPage,
        pageSize: pageSize,
      );
      // // debugPrint('✅ Fetched ${data.length} broadcasts from Firebase');

      // // Debug: Print first broadcast if available
      // if (data.isNotEmpty) {
      //   // debugPrint(
      //     '📌 First broadcast: ${data.first.broadcastName} (Status: ${data.first.status})',
      //   );
      // }

      List<BroadcastTableModel> tableData = data.map(mapToTableModel).toList();

      // SEARCH (current page only)
      if (searchQuery.value.isNotEmpty) {
        tableData = tableData
            .where(
              (b) => b.broadcastName.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            )
            .toList();
      }

      // FILTER (current page only)
      if (selectedFilter.value != 'All') {
        tableData = tableData
            .where((b) => b.status.label == selectedFilter.value)
            .toList();
        // // debugPrint(
        //   '   Results: $beforeFilter → ${tableData.length} broadcasts',
        // );
      } else {
        // // debugPrint('🎯 No status filter applied (showing All)');
      }

      broadcasts.assignAll(tableData);

      // Set total records
      totalRecords.value = total;
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to load broadcasts. Please try again.',
      );
      broadcasts.clear();
      totalRecords.value = 0;
      totalPages.value = 1;
      currentPage.value = 1;

      // // debugPrint('⚠️  State reset due to error');
    } finally {
      isLoading.value = false;
    }
  }

  // pagination actions
  Future<void> goToNextPage() async {
    if (currentPage.value < totalPages.value) {
      await loadBroadcasts(page: currentPage.value + 1);
    }
  }

  Future<void> goToPreviousPage() async {
    if (currentPage.value > 1) {
      await loadBroadcasts(page: currentPage.value - 1);
    }
  }

  // helpers for UI text
  int get startItem =>
      totalRecords.value == 0 ? 0 : ((currentPage.value - 1) * pageSize) + 1;

  int get endItem {
    if (totalRecords.value == 0) return 0;
    final end = currentPage.value * pageSize;
    return end > totalRecords.value ? totalRecords.value : end;
  }

  final RxList<BroadcastTableModel> broadcasts = <BroadcastTableModel>[].obs;

  void onBroadcastAction(BroadcastTableModel broadcast, String action) async {
    switch (action) {
      case 'view':
        viewBroadcast(broadcast);
        break;
      case 'edit':
        editDraft(broadcast);
        break;
      case 'delete':
        confirmDelete(broadcast);
        break;
      case 'stop':
        confirmStopRetry(broadcast);
        break;
    }
  }

  void confirmDelete(BroadcastTableModel broadcast) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: "Delete Broadcast",
        content:
            "Are you sure you want to delete '${broadcast.broadcastName}'?",
        onConfirm: () async {
          // ✅ FIXED: Corrected logic - allow deletion if NOT pending or sending
          BroadcastStatus pendingStatus = BroadcastStatus.pending;
          BroadcastStatus sendingStatus = BroadcastStatus.sending;

          if (broadcast.status.label != pendingStatus.label &&
              broadcast.status.label != sendingStatus.label) {
            deleteBroadcast(
              id: broadcast.id,
              name: broadcast.broadcastName,
              createdAt: broadcast.completedAt,
              sent: broadcast.sent,
              delivered: broadcast.delivered,
              read: broadcast.read,
              scheduled: broadcast.status.label == "Scheduled" ? 1 : 0,
            );
          } else {
            Utilities.showSnackbar(
              SnackType.ERROR,
              "You can't delete a broadcast that is pending or sending",
            );
          }
        },
      ),
    );
  }

  void confirmStopRetry(BroadcastTableModel broadcast) {
    Get.dialog(
      StopRetryDialog(
        onConfirm: () async {
          try {
            await service.stopBroadcastRetry(broadcast.id);
            Utilities.showSnackbar(
              SnackType.SUCCESS,
              "Auto retry stopped for '${broadcast.broadcastName}'",
            );
            await loadBroadcasts(page: currentPage.value);
          } catch (e) {
            Utilities.showSnackbar(
              SnackType.ERROR,
              "Failed to stop auto retry",
            );
          }
        },
      ),
    );
  }

  Future<void> deleteBroadcast({
    String? id,
    String? name,
    DateTime? createdAt,
    int? sent,
    int? delivered,
    int? read,
    int? scheduled,
  }) async {
    try {
      Utilities.showOverlayLoadingDialog();

      await BroadcastFirebaseService.instance.deleteBroadcast(
        id!,
        createdAt,
        sent,
        delivered,
        read,
        scheduled,
      );
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        '$name is deleted successfully!',
      );
      Utilities.hideOverlayLoadingDialog();

      await loadBroadcasts(page: currentPage.value);
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to delete broadcast');
      // // debugPrint('Error deleting broadcast: $e');
    }
  }

  BroadcastTableModel mapToTableModel(BroadcastModel model) {
    return BroadcastTableModel(
      id: model.id!,
      broadcastName: model.broadcastName,
      status: _convertStatus(model.status),
      sent: model.sent ?? 0,
      delivered: model.delivered ?? 0,
      read: model.read ?? 0,
      clicks: model.clicks ?? 0,
      replied: model.replied ?? 0,
      failed: model.failed ?? 0,
      actionLabel: model.status == "draft" ? "Edit" : "View",
      templateId: model.templateId,
      audienceType: model.audienceType.toString(),
      invocationFailures: model.invocationFailures ?? 0,
      completedAt: model.completedAt,
      scheduledAt: model.deliveryTimestamp,
      enableRetry: model.enableRetry ?? false,
      retryCampaignStatus: model.retryCampaignStatus ?? '',
      totalCost: model.totalCost,
    );
  }

  /// Fetches the chargeable_amount (actual spent) for a given broadcast
  Future<double?> fetchChargeableAmount(String broadcastId) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getBroadcastChargeableAmount,
        queryParameters: {
          'broadcastId': broadcastId,
          'clientId': clientID,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final val = response.data['chargeable_amount'];
        if (val == null) return null;
        if (val is num) return val.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  BroadcastStatus _convertStatus(String status) {
    switch (status.toLowerCase()) {
      case "sent":
        return BroadcastStatus.sent;
      case "pending":
        return BroadcastStatus.pending;
      case "sending":
        return BroadcastStatus.sending;
      case "scheduled":
        return BroadcastStatus.scheduled;
      case "failed":
        return BroadcastStatus.failed;
      case "draft":
        return BroadcastStatus.draft;
      default:
        return BroadcastStatus.draft;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    loadBroadcasts(page: currentPage.value); // Reset to page 1 when searching
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
    loadBroadcasts(page: currentPage.value); // Reset to page 1 when filtering
  }

  Future<void> createBroadcast() async {
    final isExceeded = await BroadcastFirebaseService.instance
        .isBrodcastCreationLimitExceeded();
    if (!isExceeded) {
      isCreatingBroadcast.value = true;
      final createController = Get.find<CreateBroadcastController>();

      createController.isEdit.value = false;
      createController.resetAll();

      // Navigate to create broadcast route
      Get.offNamedUntil(
        Routes.CREATE_BROADCAST,
        ModalRoute.withName(Routes.BROADCASTS),
      );

      // Update navigation controller state after route change
      Future.delayed(const Duration(milliseconds: 50), () {
        final navController = Get.find<NavigationController>();
        navController.currentRoute.value = Routes.CREATE_BROADCAST;
        navController.selectedIndex.value = 5; // Broadcasts index
        navController.routeTrigger.value++;
      });
    } else {
      Utilities.showSnackbar(SnackType.ERROR, 'Your quota has been exceeded.');
      Future.delayed(const Duration(seconds: 3), () {
        Utilities.showSnackbar(SnackType.ERROR, 'Please try again later.');
      });
    }
  }

  void handleAction(BroadcastTableModel broadcast) async {
    // Check if it's a draft with Edit action
    if (broadcast.actionLabel == 'View') {
      viewBroadcast(broadcast);
      return;
    } else if (broadcast.status == BroadcastStatus.draft &&
        broadcast.actionLabel == 'Edit') {
      editDraft(broadcast);
      return;
    } else {
      Utilities.showSnackbar(
        SnackType.INFO,
        'Action on ${broadcast.broadcastName}',
      );
    }
  }

  void editDraft(BroadcastTableModel draft) {
    // Load draft data into CreateBroadcastController
    final createController = Get.find<CreateBroadcastController>();
    createController.isEdit.value = true;
    createController.loadDraft(draft);
    // Navigate to the create broadcast route
    Get.toNamed(Routes.CREATE_BROADCAST);

    // Update navigation controller state after route change
    Future.delayed(const Duration(milliseconds: 50), () {
      final navController = Get.find<NavigationController>();
      navController.currentRoute.value = Routes.CREATE_BROADCAST;
      navController.selectedIndex.value = 5; // Broadcasts index
      navController.routeTrigger.value++;
    });
  }

  void viewBroadcast(BroadcastTableModel broadcast) async {
    try {
      print(
        '🎯 Viewing broadcast: ${broadcast.broadcastName} (ID: ${broadcast.id})',
      );

      final createController = Get.find<CreateBroadcastController>();
      createController.isEdit.value = false; // Set to false for viewing
      createController.isPreview = true; // Enable preview mode
      createController.currentStep.value = 2;

      // print('🔄 Set controller step to: ${createController.currentStep.value}');

      // Show loading indicator
      Utilities.showOverlayLoadingDialog();

      // Load the broadcast data asynchronously
      await createController.viewBroadcast(broadcast);

      // Ensure step is set before navigation
      createController.currentStep.value = 2;
      // print(
      //   '🔄 Final controller step before navigation: ${createController.currentStep.value}',
      // );

      // Navigate to the create broadcast view (preview mode will force step 2)
      Get.offNamed(Routes.CREATE_BROADCAST);

      // Update navigation controller state after route change
      Future.delayed(const Duration(milliseconds: 100), () {
        final navController = Get.find<NavigationController>();
        navController.currentRoute.value = Routes.CREATE_BROADCAST;
        navController.selectedIndex.value = 5; // Broadcasts index
        navController.routeTrigger.value++;
      });
    } catch (e, stackTrace) {
      print('❌ Error viewing broadcast: $e');
      print('Stack trace: $stackTrace');
      // Ensure loader is dismissed on error
      try {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (e) {
        print('Error dismissing loader on error: $e');
      }
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to view broadcast. Please try again.',
      );
    }
  }

  void closeCreateForm() async {
    isCreatingBroadcast.value = false;

    // 1. Reset pagination and filters to ensure new broadcast is visible on top
    currentPage.value = 1;
    selectedFilter.value = 'All';
    searchQuery.value = '';
    searchController.clear();

    // 2. Load the latest broadcasts (page 1)
    await loadBroadcasts(page: 1);

    // 3. Update navigation controller state BEFORE navigation
    final navController = Get.find<NavigationController>();
    navController.currentRoute.value = Routes.BROADCASTS;
    navController.selectedIndex.value = 5; // Broadcasts index
    navController.routeTrigger.value++;

    // 4. Navigate back to broadcasts list
    // offAllNamed ensures a clean state and avoids history issues on web
    Get.offAllNamed(Routes.BROADCASTS);
  }

  @override
  void onClose() {
    super.onClose();
  }
}

class StopRetryDialog extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const StopRetryDialog({super.key, required this.onConfirm});

  @override
  State<StopRetryDialog> createState() => _StopRetryDialogState();
}

class _StopRetryDialogState extends State<StopRetryDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Row
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFC62828),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Stop Auto Retry?",
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content text
                  Text(
                    "Stopping auto-retries will prevent any further delivery attempts for these messages. Are you sure you want to proceed?",
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Footer Section
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.sectionDark : const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1F2937),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFD1D5DB),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              Get.closeAllSnackbars();
                              await widget.onConfirm();
                              if (context.mounted) {
                                final route = ModalRoute.of(context);
                                if (route != null && route.isCurrent) {
                                  Navigator.of(context).pop();
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            "Stop Retries",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
