import 'dart:convert';
import 'dart:developer';

import 'package:business_whatsapp/app/modules/chats/models/chat_model.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/modules/roles/models/roles_model.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart';
import 'package:business_whatsapp/app/data/models/client_model.dart';
import 'package:business_whatsapp/app/data/services/clients_service.dart';
import 'package:business_whatsapp/app/modules/add_admins/widgets/admin_contact_assignment_popup.dart';

class AddAdminsController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  RxBool showAdminDetails = false.obs;
  RxList<RolesModel> allRoles = <RolesModel>[].obs;
  RxString selectedRole = ''.obs;
  String originalEmail = '';

  // Client-related state
  final ClientsService _clientsService = ClientsService();
  RxList<ClientModel> clients = <ClientModel>[].obs;
  Rx<String?> selectedClientId = Rx<String?>(null);
  RxBool isLoadingClients = false.obs;

  // Super user state
  RxBool isSuperUserChecked = false.obs;
  RxBool isAllChats = false.obs;

  final obscurePassword = true.obs;
  final isLoading = false.obs;
  String adminID = '';
  String editingPassword = '';
  bool isEditing = false;
  String createdDate = '';
  String lastLoggedIn = '';

  @override
  void onReady() {
    super.onReady();
    // Clear any existing data first
    final clientIdToUse = selectedClientId.value ?? clientID;
    clearForm();
    // Fetch clients only if super user
    if (isSuperUser.value) {
      fetchClients();
    }

    getAllRoles(clientIdToUse);
    try {
      String paramId = Get.parameters['id'] ?? '';
      if (paramId.isNotEmpty) {
        // URL decode first, then base64 decode
        String decodedParam = Uri.decodeComponent(paramId);
        adminID = utf8.decode(base64Decode(decodedParam));
        fetchAdminDetails(adminID);
        if (adminID.isNotEmpty) {
          isEditing = true;
        }
      }
    } catch (e) {
      Utilities.dPrint('--->parsing id: $e');
    }
    // log("adminID : $adminID and $isEditing");
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    roleController.clear();
    passwordController.clear();
    selectedRole.value = '';
    selectedClientId.value = null;
    isSuperUserChecked.value = false;
    originalEmail = '';
    adminID = '';
    editingPassword = '';
    isEditing = false;
    createdDate = '';
    lastLoggedIn = '';
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
    // Prevent clearing if we are currently loading admin details
    if (showAdminDetails.value) return;

    // If client changes, we should clear previous input to avoid mixing data
    if (selectedClientId.value != clientId) {
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      roleController.clear();
      passwordController.clear();
      selectedRole.value = '';
      segmentContacts
          .clear(); // Clear assigned contacts as they belong to previous client
    }

    selectedClientId.value = clientId;
    if (clientId != null && clientId.isNotEmpty) {
      getAllRoles(clientId);
    }
  }

  /// Handle super user checkbox
  void toggleSuperUser(bool? value) {
    isSuperUserChecked.value = value ?? false;
  }

  /// Validate client selection before role selection
  bool validateClientSelection() {
    if (!isSuperUser.value) return true;
    if (selectedClientId.value == null || selectedClientId.value!.isEmpty) {
      Utilities.showSnackbar(SnackType.ERROR, 'Select client first');
      return false;
    }
    return true;
  }

  Future<void> getAllRoles(String clientIdToUse) async {
    showAdminDetails.value = true;

    try {
      final snapshot = await firestore
          .collection('roles')
          .doc(clientIdToUse)
          .collection('data')
          .get();

      allRoles.value = snapshot.docs
          .map((doc) => RolesModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      if (!isEditing) showAdminDetails.value = false;
    } catch (e) {
      if (!isEditing) showAdminDetails.value = false;
      log("Error fetching roles: $e");
    }
  }

  Future<void> fetchAdminDetails(String id) async {
    try {
      showAdminDetails.value = true;

      final docSnapshot = await firestore.collection('admins').doc(id).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        // Populate basic fields
        firstNameController.text = data['first_name'] ?? '';
        lastNameController.text = data['last_name'] ?? '';
        emailController.text = data['email'] ?? '';
        final cId = data['client_id']?.toString();
        selectedClientId.value = cId;
        isSuperUserChecked.value = data['isSuperUser'] ?? false;
        editingPassword = data['password'] ?? '';
        createdDate = data['created_at'] ?? '';
        lastLoggedIn = data['last_logged_in'] ?? '';
        originalEmail = emailController.text.trim().toLowerCase();
        isAllChats.value = data['isAllChats'] ?? false;

        // Fetch roles for this client so the dropdown has valid items
        if (cId != null && cId.isNotEmpty) {
          await getAllRoles(cId);
        }

        // Set role AFTER fetching roles
        selectedRole.value = data['role'] ?? '';

        // Load assigned contacts (IDs only for selection state)
        if (data['assigned_contacts'] != null) {
          List<dynamic> ids = data['assigned_contacts'];
          segmentContacts.assignAll(
            ids
                .map((id) => ChatModel(id: id, name: id, phoneNumber: ''))
                .toList(),
          );
        }
      } else {
        Utilities.showSnackbar(SnackType.ERROR, "Admin not found");
        // Only go back on mobile, on web keep the form for user to navigate
        if (GetPlatform.isMobile) {
          Get.back();
        }
        return;
      }
    } catch (e) {
      log("Error fetching admin details: $e");
      Utilities.showSnackbar(SnackType.ERROR, "Failed to fetch admin details");
      // Only go back on mobile, on web keep the form for user to navigate
      if (GetPlatform.isMobile) {
        Get.back();
      }
      return;
    } finally {
      showAdminDetails.value = false;
    }
  }

  Future<void> addNewAdmin() async {
    try {
      isLoading.value = true;

      if (selectedRole.value.isEmpty) {
        Utilities.showSnackbar(SnackType.ERROR, "Please select a role");
        isLoading.value = false;
        return;
      }

      String enteredEmail = emailController.text.trim().toLowerCase();

      // Check only if email is changed OR it's a new admin
      if (!isEditing || isEmailChanged()) {
        // === Check if email exists in admins (excluding current admin) ===
        final adminQuery = await firestore
            .collection('admins')
            // .where(
            //   'client_id',
            //   isEqualTo: isSuperUserChecked.value
            //       ? selectedClientId.value
            //       : clientID,
            // )
            .where('email', isEqualTo: enteredEmail)
            .get();

        bool emailExistsInAdmins = adminQuery.docs.any(
          (doc) => doc.id != adminID,
        );

        if (emailExistsInAdmins) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            "Email already exists in the system.",
          );
          return;
        }
      }

      final String id = adminID.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : adminID;

      String plainPassword = passwordController.text.trim();
      String hashedPassword = sha256
          .convert(utf8.encode(plainPassword))
          .toString();

      if (passwordController.text.trim().isNotEmpty) {
        editingPassword = '';
      }
      List<AssignedPages>? assignedPages = <AssignedPages>[];

      if (allRoles.isNotEmpty && selectedRole.isNotEmpty) {
        allRoles.map((e) {
          if (e.roleName == selectedRole.value) {
            assignedPages = e.assignedPages;
          }
        }).toList();
      }

      // Use selected client ID if super user, otherwise use cookie client ID
      final clientIdToUse = isSuperUser.value
          ? selectedClientId.value
          : clientID;

      isAllChats.value = isSuperUser.value ? true : false;

      Map<String, dynamic> adminData = {
        'id': id,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'password': editingPassword.isEmpty ? hashedPassword : editingPassword,
        'email': emailController.text.trim().toLowerCase(),
        'role': selectedRole.value,
        'client_id': clientIdToUse,
        'isSuperUser': isSuperUserChecked.value,
        'isAllChats': isAllChats.value,
        'assigned_contacts': segmentContacts.map((e) => e.id).toList(),
        'assigned_pages': assignedPages?.map((e) => e.toJson()).toList() ?? [],
        'created_at': createdDate.isEmpty
            ? DateTime.now().toIso8601String()
            : createdDate,
        'updated_at': adminID.isEmpty ? '' : DateTime.now().toIso8601String(),
        'last_logged_in': adminID.isEmpty ? '' : lastLoggedIn,
      };

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(id)
          .set(adminData);

      Get.offNamed(Routes.ADMINS);

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        isEditing ? "Admin updated successfully" : "Admin added successfully",
      );

      // Optionally clear fields
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      roleController.clear();
      passwordController.clear();
    } catch (e) {
      log("$e");
      Utilities.showSnackbar(SnackType.ERROR, "Failed to add admin: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool isEmailChanged() {
    return isEditing &&
        emailController.text.trim().toLowerCase() !=
            originalEmail.toLowerCase();
  }

  Future<void> updateAssignedContacts() async {
    // Only update immediately if we are editing an existing admin
    if (isEditing && adminID.isNotEmpty) {
      try {
        Utilities.showOverlayLoadingDialog();
        await firestore.collection('admins').doc(adminID).update({
          'assigned_contacts': segmentContacts.map((e) => e.id).toList(),
        });
        Utilities.hideCustomLoader(Get.context!);
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          "Contacts updated successfully",
        );
      } catch (e) {
        Utilities.hideCustomLoader(Get.context!);
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Failed to update contacts: $e",
        );
      }
    }
  }

  bool validateAdminSelection() {
    if (selectedClientId.value == null || selectedClientId.value!.isEmpty) {
      if (!isSuperUser.value) {
        // Normal admin doesn't select client, so it's fine
        return true;
      }
      Utilities.showSnackbar(SnackType.ERROR, "Please select a client first");
      return false;
    }
    return true;
  }

  void assignContacts() {
    if (!validateAdminSelection()) return;

    // TODO: Open dialog to assign contacts
    // Logic similar to Broadcast Segment Popup but context-aware for Admin Assignment
    // For now, showing a placeholder or reusing if applicable
    // Since the requirement is: "open dialog box same like open on click custom segment button in broadcast screen"
    // We can reuse SegmentFilterPopup if we adapt it or create a similar one.
    // However, SegmentFilterPopup is tightly coupled with CreateBroadcastController.
    // Creating a dedicated popup for Admin Contact Assignment is safer.

    // For this implementation, I will create a method to show a dialog
    // that mimics the behavior but uses a controller adapted for this context.
    // Or I'll add the necessary properties to this controller to support a similar popup.

    // Adding properties to support contact selection:
    // filteredContacts, segmentContacts, toggleContact, loadMoreContacts...

    Get.dialog(
      AdminContactAssignmentPopup(controller: this), // Custom popup
      barrierDismissible: false,
    );
  }

  // Contact Assignment Logic Helpers
  RxString contactSearch = "".obs;
  RxList<ChatModel> allContacts = <ChatModel>[].obs;
  RxList<ChatModel> segmentContacts = <ChatModel>[].obs; // assigned contacts
  RxList<String> availableTags = <String>[].obs;
  RxList<String> selectedTags = <String>[].obs;

  // Pagination for contacts
  RxBool isLoadingContacts = false.obs;
  RxBool hasMoreContacts = true.obs;
  RxBool isLoadingMoreContacts = false.obs;
  int currentContactsPage = 1;
  static const int contactsPageSize = 20;

  String get _targetClientId {
    if (isSuperUser.value &&
        selectedClientId.value != null &&
        selectedClientId.value!.isNotEmpty) {
      return selectedClientId.value!;
    }
    return clientID;
  }

  void updateSearch(String value) {
    contactSearch.value = value;
  }

  bool tagHasNoContacts(String tag) {
    // Since we are paginating, we can't reliably know if a tag has contacts locally.
    // Better to show all tags than to hide valid ones.
    return false;
  }

  List<ChatModel> get filteredContacts {
    List<ChatModel> list = allContacts;

    // Filter by Search
    if (contactSearch.value.isNotEmpty) {
      final query = contactSearch.value.toLowerCase();
      list = list.where((c) {
        final name = c.name.toLowerCase();
        final phone = c.phoneNumber;
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    return list;
  }

  void toggleContact(ChatModel contact) {
    if (segmentContacts.any((c) => c.id == contact.id)) {
      segmentContacts.removeWhere((c) => c.id == contact.id);
    } else {
      segmentContacts.add(contact);
    }
  }

  Future<void> loadContactsForAssignment() async {
    isLoadingContacts.value = true;
    allContacts.clear();
    currentContactsPage = 1;

    try {
      // 1. Fetch Tags
      final tagSnap = await firestore
          .collection("tags")
          .doc(_targetClientId)
          .collection("data")
          .get();
      availableTags.assignAll(
        tagSnap.docs.map((e) => e["name"] as String).toList(),
      );

      // 2. Fetch First Page of Contacts
      await _fetchContactsPage();
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to load contacts: $e");
    } finally {
      isLoadingContacts.value = false;
    }
  }

  Future<void> loadMoreContacts() async {
    if (!hasMoreContacts.value || isLoadingMoreContacts.value) return;
    isLoadingMoreContacts.value = true;
    try {
      await _fetchContactsPage();
    } finally {
      isLoadingMoreContacts.value = false;
    }
  }

  Future<void> _fetchContactsPage() async {
    final query = await firestore
        .collection('chats')
        .doc(clientID)
        .collection('data')
        .where('assigned_admin', arrayContains: adminID)
        .get();

    if (query.docs.isNotEmpty) {
      allContacts.assignAll(
        query.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
      );
      // For viewing purposes, we treat all fetched contacts as the segment
      segmentContacts.assignAll(allContacts);
    }
  }
}
