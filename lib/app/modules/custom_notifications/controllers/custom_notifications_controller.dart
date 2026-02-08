import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/custom_notification_model.dart';
import '../../../data/services/custom_notification_service.dart';
import '../../../routes/app_pages.dart';

import '../../../Utilities/utilities.dart';
import '../../../common widgets/common_snackbar.dart';

import '../../../common widgets/common_alert_dialog_delete.dart';

class CustomNotificationsController extends GetxController {
  final CustomNotificationService _service = CustomNotificationService();

  final RxList<CustomNotificationModel> notifications =
      <CustomNotificationModel>[].obs;
  final RxBool isLoading = false.obs;

  // Form Controllers
  // formKey is now managed by the View to prevent GlobalKey duplication issues
  final RxString selectedType = 'Info'.obs;
  final TextEditingController messageController = TextEditingController();
  final TextEditingController durationController =
      TextEditingController(); // Or separate for value/unit
  final RxString selectedDurationUnit = 'Days'.obs; // Adding unit for better UX

  // For Edit
  final RxString editingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      notifications.value = await _service.getNotifications();
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to load notifications: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToCreate() {
    clearForm();
    Get.toNamed(Routes.CREATE_CUSTOM_NOTIFICATION);
  }

  void navigateToEdit(CustomNotificationModel notification) {
    clearForm();
    editingId.value = notification.id!;
    selectedType.value = notification.type;
    messageController.text = notification.message;
    // Parse duration if possible, or just set text
    // Assuming format "X Days" or "X Hours"
    List<String> parts = notification.duration.split(' ');
    if (parts.length >= 2) {
      durationController.text = parts[0];
      selectedDurationUnit.value = parts[1];
    } else {
      durationController.text = notification.duration;
    }

    Get.toNamed(Routes.CREATE_CUSTOM_NOTIFICATION);
  }

  void clearForm() {
    // formKey = GlobalKey<FormState>(); // Managed by View now
    editingId.value = '';
    selectedType.value = 'Info';
    messageController.clear();
    durationController.clear();
    selectedDurationUnit.value = 'Days';
  }

  Future<void> saveNotification(GlobalKey<FormState> formKey) async {
    if (formKey.currentState == null || !formKey.currentState!.validate())
      return;

    try {
      isLoading.value = true;
      String duration =
          '${durationController.text} ${selectedDurationUnit.value}';

      final notification = CustomNotificationModel(
        id: editingId.value.isNotEmpty ? editingId.value : null,
        type: selectedType.value,
        message: messageController.text,
        duration: duration,
      );

      if (editingId.value.isNotEmpty) {
        await _service.updateNotification(notification);
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          'Notification updated successfully',
        );
      } else {
        await _service.createNotification(notification);
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          'Notification created successfully',
        );
      }

      await loadNotifications();
      Get.offNamed(Routes.CUSTOM_NOTIFICATIONS); // Go back to list
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to save notification: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNotification(String id) async {
    Get.dialog(
      CommonAlertDialogDelete(
        title: 'Delete Notification',
        content: 'Are you sure you want to delete this notification?',
        onConfirm: () async {
          try {
            isLoading.value = true;
            await _service.deleteNotification(id);
            await loadNotifications();
            Utilities.showSnackbar(
              SnackType.SUCCESS,
              'Notification deleted successfully',
            );
          } catch (e) {
            Utilities.showSnackbar(
              SnackType.ERROR,
              'Failed to delete notification: $e',
            );
          } finally {
            isLoading.value = false;
          }
        },
      ),
    );
  }

  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'important':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
