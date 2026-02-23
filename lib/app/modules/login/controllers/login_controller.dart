import 'dart:convert';
import 'dart:developer';

import 'package:business_whatsapp/app/Utilities/constants/app_constants.dart';
import 'package:business_whatsapp/app/Utilities/webutils.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart';
import 'package:business_whatsapp/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:business_whatsapp/app/data/services/subscription_service.dart';

class LoginController extends GetxController {
  GlobalKey<FormState> loginKey = GlobalKey<FormState>();

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  RxBool showLoading = false.obs;
  final version = "".obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  Future<void> login(String email, String password) async {
    if (!loginKey.currentState!.validate()) {
      return;
    }

    try {
      showLoading.value = true;
      final querySnapshot = await firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final adminDoc = querySnapshot.docs.first;
        final adminData = adminDoc.data();
        final adminId = adminDoc.id;
        final clientId = adminData['client_id'] ?? adminId;

        adminName.value =
            "${adminData['first_name']} ${adminData['last_name']}";

        // Update global isSuperUser reactive variable
        isSuperUser.value = adminData['isSuperUser'] ?? false;
        isAllChats.value = adminData['isAllChats'] ?? false;

        final token = generateJwt(
          adminId,
          clientId,
          adminData['email'],
          adminData['password'],
        );

        // Prepare client-specific data
        Map<String, dynamic> clientSpecificData = {
          "adminId": adminId,
          "adminName": "${adminData['first_name']} ${adminData['last_name']}",
          "pages": adminData["assigned_pages"],
          "clientId": clientId,
          "isSuperUser": adminData['isSuperUser'] ?? false,
          "isAllChats": adminData['isAllChats'] ?? false,
        };

        String encryptedClientData = WebUtils.encryptData(
          data: jsonEncode(clientSpecificData),
          secretKey: AppConstants.menuItemsSecret,
        );

        // Store cookies with client ID isolation
        WebUtils.addCookie(
          key: '${AppConstants.menuItemsCookieKey}_$clientId',
          value: encryptedClientData,
        );

        WebUtils.addCookie(key: 'jwt', value: token);
        WebUtils.addCookie(key: 'currentClientId', value: clientId);

        gJwtToken = token;
        adminID = adminId;
        clientID = clientId;

        String fname = adminData['first_name'];
        String lname = adminData['last_name'];
        adminName.value = "$fname $lname";

        // Store admin credentials with client ID prefix
        WebUtils.addCookie(
          key: 'name_$clientId',
          value: WebUtils.encryptData(
            data: adminName.value,
            secretKey: AppConstants.menuItemsSecret,
          ),
        );
        WebUtils.addCookie(
          key: 'adminId_$clientId',
          value: WebUtils.encryptData(
            data: adminId,
            secretKey: AppConstants.menuItemsSecret,
          ),
        );
        WebUtils.addCookie(
          key: 'clientId_$clientId',
          value: WebUtils.encryptData(
            data: clientId,
            secretKey: AppConstants.menuItemsSecret,
          ),
        );
        WebUtils.addCookie(
          key: 'isSuperUser_$clientId',
          value: WebUtils.encryptData(
            data: (adminData['isSuperUser'] ?? false).toString(),
            secretKey: AppConstants.menuItemsSecret,
          ),
        );
        WebUtils.addCookie(
          key: 'isAllChats_$clientId',
          value: WebUtils.encryptData(
            data: (adminData['isAllChats'] ?? false).toString(),
            secretKey: AppConstants.menuItemsSecret,
          ),
        );

        if (rememberMe.value) {
          WebUtils.addCookie(
            key: 'email_$clientId',
            value: WebUtils.encryptData(
              data: email,
              secretKey: AppConstants.menuItemsSecret,
            ),
          );
          WebUtils.addCookie(
            key: 'password_$clientId',
            value: WebUtils.encryptData(
              data: password,
              secretKey: AppConstants.menuItemsSecret,
            ),
          );
        }

        // --- Fetch and Store Client Info for Fixed Sidebar ---
        try {
          final clientDoc = await firestore
              .collection('clients')
              .doc(clientId)
              .get();
          String cName = 'Messaging Portal';
          String cLogo = '';
          bool crmEnabled = false;

          if (clientDoc.exists && clientDoc.data() != null) {
            final data = clientDoc.data()!;
            if (data['name'] != null) cName = data['name'];
            if (data['logoUrl'] != null) cLogo = data['logoUrl'];
            crmEnabled = data['isCRMEnabled'] == true;
          }

          // Update Globals
          clientName.value = cName;
          clientLogo.value = cLogo;
          isCRMEnabled.value = crmEnabled;

          // Store in Cookies
          WebUtils.addCookie(
            key: 'clientName_$clientId',
            value: WebUtils.encryptData(
              data: cName,
              secretKey: AppConstants.menuItemsSecret,
            ),
          );
          WebUtils.addCookie(
            key: 'clientLogo_$clientId',
            value: WebUtils.encryptData(
              data: cLogo,
              secretKey: AppConstants.menuItemsSecret,
            ),
          );
          WebUtils.addCookie(
            key: 'isCRMEnabled_$clientId',
            value: WebUtils.encryptData(
              data: crmEnabled.toString(),
              secretKey: AppConstants.menuItemsSecret,
            ),
          );
        } catch (e) {
          print('Error fetching client details: $e');
        }

        // --- Fetch and Store Charges Collection for Local Storage ---
        try {
          final chargesSnapshot = await firestore.collection('charges').get();
          Map<String, dynamic> chargesData = {};
          for (var doc in chargesSnapshot.docs) {
            chargesData[doc.id] = doc.data();
          }
          WebUtils.saveToLocalStorage('charges', jsonEncode(chargesData));
          // print('Charges data stored in local storage');
          // print('chargesData: ******************************  $chargesData');
        } catch (e) {
          print('Error fetching or storing charges: $e');
        }
        // -----------------------------------------------------

        // print('Login successful for Client ID: $clientId');
        // print('Admin ID: $adminId');
        // print('Admin Name: ${adminName.value}');
        // print('Admin Email: ${adminData['email']}');

        try {
          await firestore.collection('admins').doc(adminId).update({
            "last_logged_in": DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('Firestore update failed: $e');
        }

        showLoading.value = false;

        // Start listening to subscription updates now that we have clientID
        SubscriptionService.instance.startListening();

        // print('Navigating to dashboard...');

        // Use WidgetsBinding to ensure navigation happens after the current frame
        // This prevents the TextEditingController disposal error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(Routes.DASHBOARD);
        });
      } else {
        showLoading.value = false;
        Utilities.showSnackbar(SnackType.ERROR, 'Invalid email or password');
      }
    } catch (e) {
      showLoading.value = false;
      // log('$e');
    }
  }

  String generateJwt(
    String adminId,
    String clientId,
    String email,
    String password,
  ) {
    final jwt = JWT({
      'adminId': adminId,
      'clientId': clientId,
      'email': email,
      'password': password,
      'exp':
          DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/
          1000,
    });

    final token = jwt.sign(SecretKey(AppConstants.menuItemsSecret));
    return token;
  }

  // Helper method to get client-specific cookie value
  String? getClientCookie(String key, String clientId) {
    String encryptedValue = WebUtils.readCookie('${key}_$clientId') ?? '';
    if (encryptedValue.isEmpty) return null;
    try {
      return WebUtils.decryptData(
        data: encryptedValue,
        secretKey: AppConstants.menuItemsSecret,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _getVersion();
    String currentClientId = WebUtils.readCookie('currentClientId') ?? '';

    String encryptedEmail = WebUtils.readCookie('email_$currentClientId') ?? '';
    String encryptedPassword =
        WebUtils.readCookie('password_$currentClientId') ?? '';

    if (encryptedEmail.isNotEmpty && encryptedPassword.isNotEmpty) {
      try {
        String email = WebUtils.decryptData(
          data: encryptedEmail,
          secretKey: AppConstants.menuItemsSecret,
        );
        String password = WebUtils.decryptData(
          data: encryptedPassword,
          secretKey: AppConstants.menuItemsSecret,
        );
        emailController.text = email;
        passwordController.text = password;
        rememberMe.value = true;
      } catch (e) {
        // Ignore decryption errors
      }
    }
  }

  @override
  void onClose() {
    // emailController.dispose();
    // passwordController.dispose();
    super.onClose();
  }

  Future<void> _getVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      version.value = packageInfo.version;
    } catch (e) {
      print("Error fetching version: $e");
      version.value = "1.0.1";
    }
  }
}
