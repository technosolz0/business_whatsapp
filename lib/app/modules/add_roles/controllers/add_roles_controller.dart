import 'dart:convert';
import 'dart:developer';

import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart' as dio;
import 'package:business_whatsapp/app/data/models/client_model.dart';
import 'package:business_whatsapp/app/data/services/clients_service.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart';

class AddRolesController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Form controllers
  TextEditingController addRoleNameController = TextEditingController();

  /// Reactive state
  RxBool showRoleDetails = false.obs;
  RxBool isLoading = false.obs;

  /// Client-related state
  final ClientsService _clientsService = ClientsService();
  RxList<ClientModel> clients = <ClientModel>[].obs;
  Rx<String?> selectedClientId = Rx<String?>(null);
  RxBool isLoadingClients = false.obs;

  /// Edit mode handling
  String roleID = '';
  bool isEditing = false;
  String createdDate = '';

  /// Table data: [Page Name, View, Edit, Delete]
  RxList<List<dynamic>> rolesTable = <List<dynamic>>[
    ['Dashboard', false, false, false],
    ['Admin', false, false, false],
    ['Manage Roles', false, false, false],
    ['contacts', false, false, false],
    ['templates', false, false, false],
    ['broadcast', false, false, false],
    ['chat', false, false, false],
    ['settings', false, false, false],
  ].obs;

  /// Map of Page → Route
  final Map<String, String> routeMap = {
    'Dashboard': '/dashboard',
    'Admin': '/admins',
    'Manage Roles': '/roles',
    'contacts': '/contacts',
    'templates': '/templates',
    'broadcast': '/broadcasts',
    'chat': '/chats',
    'settings': '/settings',
  };

  @override
  void onReady() {
    super.onReady();
    fetchClients();
    try {
      String paramId = Get.parameters['id'] ?? '';
      if (paramId.isNotEmpty) {
        // URL decode first, then base64 decode
        String decodedParam = Uri.decodeComponent(paramId);
        roleID = utf8.decode(base64Decode(decodedParam));
        fetchRoleDetails(roleID);
        if (roleID.isNotEmpty) {
          isEditing = true;
        }
      }
    } catch (e) {
      Utilities.dPrint('--->parsing id: $e');
    }
    // log("roleID : $roleID and isEditing: $isEditing");
  }

  /// Fetch all clients from Firestore
  Future<void> fetchClients() async {
    try {
      isLoadingClients.value = true;
      final clientsList = await _clientsService.getClients();
      clients.value = clientsList;
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to load clients: $e');
    } finally {
      isLoadingClients.value = false;
    }
  }

  /// Handle client selection
  void onClientSelected(String? clientId) {
    selectedClientId.value = clientId;
  }

  /// 🔹 Fetch existing role details (for edit mode)
  Future<void> fetchRoleDetails(String id) async {
    try {
      showRoleDetails.value = true;

      final _dio = NetworkUtilities.getDioClient();
      final response = await _dio.get(
        ApiEndpoints.getRoles,
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List roles = response.data['data'];
        final data = roles.firstWhere((r) => r['id'] == id, orElse: () => null);

        if (data != null) {
          addRoleNameController.text = data['role_name'] ?? '';
          createdDate = data['created_at'] ?? '';
          selectedClientId.value = data['client_id'];

          if (data['assigned_pages'] != null) {
            final List assignedPages = data['assigned_pages'];
            for (var i = 0; i < rolesTable.length; i++) {
              final route = routeMap[rolesTable[i][0]];
              final match = assignedPages.firstWhere(
                (e) => e['route'] == route,
                orElse: () => null,
              );
              if (match != null) {
                final ax = match['ax'].toString().padLeft(3, '0');
                rolesTable[i][1] = ax[0] == '1';
                rolesTable[i][2] = ax[1] == '1';
                rolesTable[i][3] = ax[2] == '1';
              }
            }
            rolesTable.refresh();
          }
        } else {
          Utilities.showSnackbar(SnackType.ERROR, "Role not found");
          if (GetPlatform.isMobile) Get.back();
        }
      }
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to fetch role details");
      if (GetPlatform.isMobile) Get.back();
    } finally {
      showRoleDetails.value = false;
    }
  }

  /// 🔹 Add or update role in Firestore
  Future<void> addNewRole() async {
    final roleName = addRoleNameController.text.trim();
    if (roleName.isEmpty) {
      Utilities.showSnackbar(SnackType.ERROR, "Please enter a role name");
      return;
    }

    final clientIdToUse = isSuperUser.value ? selectedClientId.value : clientID;

    try {
      isLoading.value = true;

      List<Map<String, dynamic>> assignedPages = [];
      for (var row in rolesTable) {
        String pageName = row[0];
        bool view = row[1] as bool;
        bool edit = row[2] as bool;
        bool delete = row[3] as bool;

        final ax = '${view ? 1 : 0}${edit ? 1 : 0}${delete ? 1 : 0}';
        assignedPages.add({
          'route': routeMap[pageName] ?? '',
          'ax': int.parse(ax),
          'name': pageName,
        });
      }

      final String id = roleID.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : roleID;

      final Map<String, dynamic> roleData = {
        'id': id,
        'role_name': roleName,
        'client_id': clientIdToUse,
        'assigned_pages': assignedPages,
      };

      final _dio = NetworkUtilities.getDioClient();
      final response = await _dio.patch(
        isEditing ? ApiEndpoints.patchRole : ApiEndpoints.addRole,
        queryParameters: isEditing ? {'roleId': id} : null,
        data: roleData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.offNamed(Routes.ROLES);
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          isEditing ? "Role updated successfully" : "Role saved successfully",
        );
      } else {
        Utilities.showSnackbar(
          SnackType.ERROR,
          response.data['detail'] ?? "Failed to save role",
        );
      }
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to save role: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateRoleAccess(int rowIndex, int colIndex, bool value) {
    // Prevent unchecking View when Edit/Delete is true
    if (colIndex == 1 && !value) {
      bool hasEditOrDelete =
          rolesTable[rowIndex][2] == true || rolesTable[rowIndex][3] == true;
      if (hasEditOrDelete) return; // Don't allow turning off view
    }

    rolesTable[rowIndex][colIndex] = value;

    // If Edit/Delete enabled → View must be true
    if ((colIndex == 2 || colIndex == 3) && value == true) {
      rolesTable[rowIndex][1] = true;
    }

    rolesTable.refresh();
  }
}
