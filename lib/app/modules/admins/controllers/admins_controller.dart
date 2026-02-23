import 'dart:convert';
import 'dart:developer';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/data/models/admins_model.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart';

class AdminsController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();

  final RxList<AdminsModel> allAdmins = <AdminsModel>[].obs;
  final RxList<AdminsModel> filteredAdmins = <AdminsModel>[].obs;
  final RxList<List<String>> rowData = <List<String>>[].obs;
  final List<String> tableColumns = ["Name", "Email", "Role", "Last Logged In"];

  final RxBool showLoading = false.obs;
  final RxBool isAddingAdmin = false.obs;

  DocumentSnapshot? lastDocument;
  DocumentSnapshot? firstDocument;
  bool hasMore = true;

  // Pagination
  final RxInt pageSize = 10.obs;
  final List<int> availablePageSizes = [10, 25, 50, 100];
  final RxInt currentPage = 1.obs;
  int totalPages = 1;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedRole = 'All'.obs;
  final List<String> allRoles = [
    'All',
    'Super Admin',
    'Admin',
    'Manager',
    'User',
  ];

  // Selection
  final Rx<AdminsModel?> selectedAdmin = Rx<AdminsModel?>(null);

  // Just track which field is sorted, no ascending/descending
  final RxString sortField = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getAllAdmins();

    // Add listener for live search
    searchController.addListener(() {
      searchAdmins(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// 🔤 Sort alphabetically (A → Z)
  void sortAdminsByField(String field) {
    sortField.value = field;

    RxList<AdminsModel> sortedList = List<AdminsModel>.from(filteredAdmins).obs;

    sortedList.sort((a, b) {
      String valA = '';
      String valB = '';

      switch (field) {
        case 'name':
          valA = a.fullName.toLowerCase(); // Use fullName
          valB = b.fullName.toLowerCase(); // Use fullName
          break;
        case 'email':
          valA = a.email?.toLowerCase() ?? '';
          valB = b.email?.toLowerCase() ?? '';
          break;
        case 'role':
          valA = a.role?.toLowerCase() ?? '';
          valB = b.role?.toLowerCase() ?? '';
          break;
      }

      return valA.compareTo(valB);
    });

    filteredAdmins.assignAll(sortedList);
    currentPage.value = 1;
    updatePageRows();
  }

  void sortAdminsByDate() {
    // Sort by last logged in date (latest first)
    RxList<AdminsModel> sortedList = List<AdminsModel>.from(filteredAdmins).obs;

    sortedList.sort((a, b) {
      DateTime? dateA = a.lastLoggedIn;
      DateTime? dateB = b.lastLoggedIn;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // nulls go last
      if (dateB == null) return -1;

      // Latest date first (descending)
      return dateB.compareTo(dateA);
    });

    filteredAdmins.assignAll(sortedList);
    currentPage.value = 1;
    updatePageRows();
  }

  Future<void> getAllAdmins({bool isNextPage = false, int? newPageSize}) async {
    showLoading.value = true;

    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getAdmins,
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List adminsData = response.data['data'];
        allAdmins.value = adminsData
            .map((data) => AdminsModel.fromJson({'id': data['id'], ...data}))
            .toList();

        // Search locally for now as simpler (can be improved later)
        if (searchQuery.value.isNotEmpty) {
          searchAdmins(searchQuery.value);
        } else {
          filteredAdmins.assignAll(allAdmins);
        }

        hasMore =
            false; // Backend doesn't support pagination yet in this endpoint
        updatePageRows();
      }
      showLoading.value = false;
    } catch (e) {
      log("Error fetching admins: $e");
      showLoading.value = false;
    }
  }

  /// 🔍 Filter admins by search text
  void searchAdmins(String query) {
    if (query.trim().isEmpty) {
      filteredAdmins.assignAll(allAdmins);
    } else {
      String lowerQuery = query.toLowerCase();
      filteredAdmins.assignAll(
        allAdmins.where((admin) {
          String name = admin.fullName.toLowerCase(); // Use fullName
          String email = (admin.email ?? '').toLowerCase();
          String role = (admin.role ?? '').toLowerCase();

          return name.contains(lowerQuery) ||
              email.contains(lowerQuery) ||
              role.contains(lowerQuery);
        }).toList(),
      );
    }

    // Reset pagination when new search happens
    currentPage.value = 1;
    totalPages = (filteredAdmins.length / pageSize.value).ceil();
    updatePageRows();
  }

  void updatePageRows() {
    RxList<AdminsModel> listToUse = filteredAdmins;
    if (listToUse.isEmpty) {
      rowData.clear();
      return;
    }

    rowData.value = filteredAdmins.map((d) {
      return [
        d.fullName, // Use fullName instead of username
        d.email ?? "-",
        d.role ?? "-",
        d.lastLoggedIn == null
            ? '-'
            : DateFormat('dd MMM yyyy').format(d.lastLoggedIn!).toString(),
        jsonEncode(d.toJson()),
      ];
    }).toList();
  }

  Future<void> nextPage() async {
    if (hasMore) {
      await getAllAdmins(isNextPage: true);
    }
  }

  Future<void> prevPage() async {
    showLoading.value = true;
    hasMore = true;
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('admins')
          .orderBy('created_at')
          .endBeforeDocument(firstDocument!)
          .limitToLast(pageSize.value);

      final snapshot = await query.get();

      allAdmins.value = snapshot.docs
          .map((doc) => AdminsModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      filteredAdmins.assignAll(allAdmins);

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
        firstDocument = snapshot.docs.first;
      }

      if (allAdmins.isNotEmpty) {
        currentPage.value--;
      }

      updatePageRows();

      showLoading.value = false;
    } catch (e) {
      log('-----> ERROR IN FETCHING');
    }
    showLoading.value = false;
  }

  void updatePageSize(int newSize) {
    searchController.clear();
    currentPage.value = 1;
    getAllAdmins(newPageSize: newSize);
  }

  Future<bool> deleteAdmin(String id) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.delete(
        ApiEndpoints.deleteAdmin,
        queryParameters: {'adminId': id},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        Utilities.showSnackbar(SnackType.SUCCESS, "Admin deleted successfully");
        await getAllAdmins();
        return true;
      }
      return false;
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to delete admin: $e");
      return false;
    }
  }

  void exportAdminsExcel() {
    if (filteredAdmins.isEmpty) {
      Utilities.showSnackbar(SnackType.INFO, "No data available to export");
      return;
    }

    // Prepare column export flags (true = export)
    List<bool> exportableColumns = List.filled(tableColumns.length, true);

    // Convert filteredAdmins into List<List<String>>
    List<List<String>> exportData = filteredAdmins.map((admin) {
      return [
        admin.username ?? "-",
        admin.email ?? "-",
        admin.role ?? "-",
        admin.lastLoggedIn == null
            ? "-"
            : DateFormat('dd MMM yyyy').format(admin.lastLoggedIn!),
      ];
    }).toList();

    // Call Utilities excel creator
    Utilities.createAndDownloadExcelFileLocal(
      columns: List<String>.from(tableColumns),
      data: exportData,
      exportableColumns: exportableColumns,
      fileName: "admins_data",
    );
  }

  // Additional methods needed by the view
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    searchAdmins(query);
  }

  void updateRoleFilter(String role) {
    selectedRole.value = role;
    if (role == 'All') {
      filteredAdmins.assignAll(allAdmins);
    } else {
      filteredAdmins.assignAll(
        allAdmins.where((admin) => admin.role == role).toList(),
      );
    }
    currentPage.value = 1;
    updatePageRows();
  }

  void selectAdmin(AdminsModel admin) {
    selectedAdmin.value = admin;
  }

  void clearSelection() {
    selectedAdmin.value = null;
  }

  // Getters for pagination display
  int get startItem => ((currentPage.value - 1) * pageSize.value) + 1;
  int get endItem => (startItem - 1) + filteredAdmins.length;

  // Getter for paginated admins (for now just return filtered)
  List<AdminsModel> get paginatedAdmins => filteredAdmins;

  // Loading state getter (already exists as showLoading)
  bool get isLoading => showLoading.value;

  Future<bool> canAddMoreAdmins() async {
    try {
      if (isSuperUser.value) return true;
      if (clientID.isEmpty) return false;

      final dio = NetworkUtilities.getDioClient();

      // 1. Fetch Client Details to get limit
      final clientResponse = await dio.get(
        ApiEndpoints.getClientDetails,
        queryParameters: {'clientId': clientID},
      );

      if (clientResponse.statusCode != 200) return false;

      int limit = clientResponse.data['adminLimit'] ?? 0;

      // 2. Count total admins for this client
      final adminsResponse = await dio.get(
        ApiEndpoints.getAdmins,
        queryParameters: {'clientId': clientID},
      );

      if (adminsResponse.statusCode != 200) return false;

      int totalAdmins = (adminsResponse.data['data'] as List).length;

      if (totalAdmins >= limit) {
        return false;
      }

      return true;
    } catch (e) {
      log("Error checking admin limit: $e");
      return false; // Block on error
    }
  }
}
