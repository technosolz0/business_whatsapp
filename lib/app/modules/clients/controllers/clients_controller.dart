import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/client_model.dart';
import '../../../data/services/clients_service.dart';
import '../../../routes/app_pages.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';

class ClientsController extends GetxController {
  final ClientsService _clientsService = ClientsService();

  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxList<ClientModel> filteredClients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadClients();

    // Listen to search query changes
    ever(searchQuery, (_) => filterClients());
  }

  @override
  void onClose() {
    // searchController.dispose();
    super.onClose();
  }

  /// Load all clients from Firestore
  Future<void> loadClients() async {
    try {
      isLoading.value = true;
      final data = await _clientsService.getClients();
      clients.value = data;
      filteredClients.value = data;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load clients: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter clients based on search query
  void filterClients() {
    if (searchQuery.value.isEmpty) {
      filteredClients.value = clients;
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredClients.value = clients.where((client) {
        return client.name.toLowerCase().contains(query) ||
            client.phoneNumber.contains(searchQuery.value);
      }).toList();
    }
  }

  /// Navigate to Add Client page
  void navigateToAddClient() {
    Get.toNamed(Routes.ADD_CLIENT);
  }

  /// Navigate to Edit Client page
  void navigateToEditClient(String clientId) {
    Get.toNamed(Routes.EDIT_CLIENT, parameters: {'id': clientId});
  }

  /// Delete a client
  Future<void> deleteClient(String clientId, String clientName) async {
    Get.dialog(
      CommonAlertDialogDelete(
        title: 'Delete Client',
        content: 'Are you sure you want to delete "$clientName"?',
        onConfirm: () async {
          try {
            isLoading.value = true;
            final success = await _clientsService.deleteClient(clientId);

            if (success) {
              Get.snackbar(
                'Success',
                'Client deleted successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              await loadClients();
            } else {
              Get.snackbar(
                'Error',
                'Failed to delete client',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to delete client: $e',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          } finally {
            isLoading.value = false;
          }
        },
      ),
    );
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }
}
