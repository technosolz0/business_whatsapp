import 'dart:convert';
import 'dart:developer';
import 'package:business_whatsapp/app/Utilities/utilities.dart' show Utilities;
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/modules/roles/models/roles_model.dart';

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
      if (newPageSize != null) {
        pageSize.value = newPageSize;
        lastDocument = null;
        currentPage.value = 1;
        hasMore = true;
      }

      if (!isNextPage) {
        allRoles.clear();
      }

      Query<Map<String, dynamic>> query = firestore
          .collection('roles')
          .doc(clientID)
          .collection('data')
          .orderBy('created_at')
          .limit(pageSize.value + 1);

      if (isNextPage && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

      // ✅ Check if next exists
      if (docs.length > pageSize.value) {
        hasMore = true;
        docs = docs.sublist(0, pageSize.value);
      } else {
        hasMore = false;
      }

      allRoles.value = docs
          .map((doc) => RolesModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      filteredRoles.assignAll(allRoles);

      if (docs.isNotEmpty) {
        firstDocument = docs.first;
        lastDocument = docs.last;
      }

      if (isNextPage) currentPage.value++;
      updatePageRows();
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
      final roleRef = firestore
          .collection('roles')
          .doc(clientID)
          .collection('data')
          .doc(id);
      final roleDoc = await roleRef.get();

      if (!roleDoc.exists) {
        Utilities.showSnackbar(SnackType.ERROR, "Role not found");
        return false;
      }

      final deletedRoleName = roleDoc.data()?["role_name"] ?? "";
      if (deletedRoleName.isEmpty) {
        Utilities.showSnackbar(SnackType.ERROR, "Invalid role data");
        return false;
      }

      // -------------------------------
      // 1️⃣ Move role → deleted_roles
      // -------------------------------
      await firestore.collection('deleted_roles').doc(id).set({
        ...roleDoc.data()!,
        'deleted_at': DateTime.now().toIso8601String(),
      });

      // -------------------------------
      // 2️⃣ Delete role from main table
      // -------------------------------
      await roleRef.delete();

      // -------------------------------
      // 3️⃣ Remove role from all admins
      // -------------------------------
      final adminSnap = await firestore
          .collection("admins")
          .where("role", isEqualTo: deletedRoleName)
          .get();

      for (var admin in adminSnap.docs) {
        await admin.reference.update({
          "role": null,
          "assigned_pages": [], // remove all permissions
          "updated_at": DateTime.now().toIso8601String(),
        });
      }

      // -------------------------------
      // 4️⃣ UI + reload
      // -------------------------------
      Utilities.showSnackbar(SnackType.SUCCESS, "Role deleted successfully");

      lastDocument = null;
      currentPage.value = 1;
      hasMore = true;
      await getAllRoles(newPageSize: pageSize.value);

      return true;
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
