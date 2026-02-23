import 'dart:convert';
import 'dart:developer';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart' as dio;
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/modules/roles/models/roles_model.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart' show Utilities;

class RolesController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();

  final RxList<RolesModel> allRoles = <RolesModel>[].obs;
  final RxList<RolesModel> filteredRoles = <RolesModel>[].obs;
  final RxList<List<String>> rowData = <List<String>>[].obs;

  final List<String> tableColumns = ["Role Name", "Assigned Pages"];
  final RxBool showLoading = false.obs;
  final RxBool isAddingRole = false.obs;

  // Pagination
  final RxInt pageSize = 10.obs;
  final RxInt currentPage = 1.obs;
  final List<int> availablePageSizes = [10, 25, 50, 100];

  DocumentSnapshot? lastDocument;
  DocumentSnapshot? firstDocument;
  bool hasMore = true;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'All'.obs;

  // Selection
  final Rx<RolesModel?> selectedRole = Rx<RolesModel?>(null);

  // Sorting
  final RxString sortField = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getAllRoles();

    searchController.addListener(() {
      searchRoles(searchController.text);
    });
  }

  // ✅ PAGINATED FETCH
  Future<void> getAllRoles({bool isNextPage = false, int? newPageSize}) async {
    showLoading.value = true;

    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getRoles,
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List rolesData = response.data['data'];
        allRoles.value = rolesData
            .map((data) => RolesModel.fromJson({'id': data['id'], ...data}))
            .toList();

        if (searchQuery.value.isNotEmpty) {
          searchRoles(searchQuery.value);
        } else {
          filteredRoles.assignAll(allRoles);
        }

        hasMore = false; // Backend pagination not implemented yet
        updatePageRows();
      }
    } catch (e) {
      log("Error fetching roles: $e");
    }

    showLoading.value = false;
  }

  // ✅ NEXT PAGE
  Future<void> nextPage() async {
    if (hasMore) await getAllRoles(isNextPage: true);
  }

  // ✅ PREVIOUS PAGE
  Future<void> prevPage() async {
    showLoading.value = true;
    hasMore = true;

    try {
      if (firstDocument == null) return;

      Query<Map<String, dynamic>> query = firestore
          .collection('roles')
          .doc(clientID)
          .collection('data')
          .orderBy('created_at')
          .endBeforeDocument(firstDocument!)
          .limitToLast(pageSize.value);

      final snapshot = await query.get();

      allRoles.value = snapshot.docs
          .map((doc) => RolesModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      filteredRoles.assignAll(allRoles);

      if (snapshot.docs.isNotEmpty) {
        firstDocument = snapshot.docs.first;
        lastDocument = snapshot.docs.last;
      }

      if (currentPage.value > 1) currentPage.value--;
      updatePageRows();

      showLoading.value = false;
    } catch (e) {
      log("ERROR IN PREV PAGE: $e");
    }

    showLoading.value = false;
  }

  void searchRoles(String query) {
    if (query.trim().isEmpty) {
      filteredRoles.assignAll(allRoles);
    } else {
      final keywords = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((k) => k.isNotEmpty)
          .toList();
      filteredRoles.assignAll(
        allRoles.where((role) {
          final roleName = (role.roleName ?? '').toLowerCase();
          final assignedPageNames = (role.assignedPages ?? [])
              .where((page) {
                final ax = page.ax?.toString() ?? '';
                return ax.isNotEmpty && ax[0] == '1';
              })
              .map((page) => (page.routeName ?? '').toLowerCase())
              .join(', ');
          final searchableText = '$roleName $assignedPageNames';
          return keywords.every((word) => searchableText.contains(word));
        }).toList(),
      );
    }
    // Reset pagination when new search happens
    currentPage.value = 1;
    updatePageRows();
  }

  void sortRolesByField(String field) {
    sortField.value = field;

    List<RolesModel> sorted = List.from(filteredRoles);

    sorted.sort((a, b) {
      String valA = '';
      String valB = '';

      if (field == 'role') {
        valA = a.roleName?.toLowerCase() ?? '';
        valB = b.roleName?.toLowerCase() ?? '';
      }

      return valA.compareTo(valB);
    });

    filteredRoles.assignAll(sorted);

    currentPage.value = 1;
    updatePageRows();
  }

  // ✅ PREPARE TABLE ROWS
  void updatePageRows() {
    if (filteredRoles.isEmpty) {
      rowData.clear();
      return;
    }

    rowData.value = filteredRoles.map((role) {
      final assignedRoutes = (role.assignedPages ?? [])
          .where((p) => p.ax?.toString().startsWith("1") ?? false)
          .map((p) => p.routeName ?? '')
          .where((r) => r.isNotEmpty)
          .join(', ');

      return [
        role.roleName ?? "-",
        assignedRoutes.isNotEmpty ? assignedRoutes : "No Pages Assigned",
        jsonEncode(role.toJson()),
      ];
    }).toList();
  }

  // ✅ PAGE SIZE CHANGE
  void updatePageSize(int newSize) {
    searchController.clear();
    currentPage.value = 1;
    getAllRoles(newPageSize: newSize);
  }

  // ✅ DELETE
  Future<bool> deleteRole(String id) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.delete(
        ApiEndpoints.deleteRole,
        queryParameters: {'roleId': id},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        Utilities.showSnackbar(SnackType.SUCCESS, "Role deleted successfully");
        await getAllRoles();
        return true;
      }
      return false;
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to delete role: $e");
      return false;
    }
  }

  // ✅ EXPORT EXCEL
  void exportRolesExcel() {
    if (filteredRoles.isEmpty) {
      Utilities.showSnackbar(SnackType.INFO, "No data available to export");
      return;
    }

    List<List<String>> exportData = filteredRoles.map((r) {
      final assignedRoutes = (r.assignedPages ?? [])
          .where((p) => p.ax?.toString().startsWith("1") ?? false)
          .map((p) => p.routeName ?? '')
          .join(', ');

      return [
        r.roleName ?? "-",
        assignedRoutes.isNotEmpty ? assignedRoutes : "No Pages Assigned",
      ];
    }).toList();

    Utilities.createAndDownloadExcelFileLocal(
      columns: List<String>.from(tableColumns),
      data: exportData,
      exportableColumns: List.filled(tableColumns.length, true),
      fileName: "roles_data",
    );

    Utilities.showSnackbar(SnackType.SUCCESS, "Roles exported successfully");
  }

  // Additional methods needed by the view
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    searchRoles(query);
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    if (status == 'All') {
      filteredRoles.assignAll(allRoles);
    } else {
      final statusValue = status == 'Active' ? 1 : 0;
      filteredRoles.assignAll(
        allRoles.where((role) => role.status == statusValue).toList(),
      );
    }
    currentPage.value = 1;
    updatePageRows();
  }

  void selectRole(RolesModel role) {
    selectedRole.value = role;
  }

  void clearSelection() {
    selectedRole.value = null;
  }

  // Getters for pagination display
  int get startItem => ((currentPage.value - 1) * pageSize.value) + 1;
  int get endItem => (startItem - 1) + filteredRoles.length;

  // Getter for paginated roles (for now just return filtered)
  List<RolesModel> get paginatedRoles => filteredRoles;

  // Getter for total pages
  int get totalPages => (filteredRoles.length / pageSize.value).ceil();

  // Loading state getter
  bool get isLoading => showLoading.value;
}
