import 'dart:convert';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/constants/app_constants.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/Utilities/webutils.dart';
import 'package:dio/dio.dart' as dio;
import 'package:cloud_firestore/cloud_firestore.dart';
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
      final dio = NetworkUtilities.getDioClient();

      final response = await dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data;
        final adminData = data['admin'];
        final adminId = adminData['id'];
        final clientId = data['clientId'];
        final token = data['token'];

        adminName.value =
            "${adminData['first_name']} ${adminData['last_name']}";

        // Update global isSuperUser reactive variable
        isSuperUser.value = adminData['is_super_user'] ?? false;
        isAllChats.value = adminData['is_all_chats'] ?? false;

        // Prepare client-specific data
        Map<String, dynamic> clientSpecificData = {
          "adminId": adminId,
          "adminName": adminName.value,
          "pages": adminData["assigned_pages"],
          "clientId": clientId,
          "isSuperUser": adminData['is_super_user'] ?? false,
          "isAllChats": adminData['is_all_chats'] ?? false,
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
            data: (adminData['is_super_user'] ?? false).toString(),
            secretKey: AppConstants.menuItemsSecret,
          ),
        );
        WebUtils.addCookie(
          key: 'isAllChats_$clientId',
          value: WebUtils.encryptData(
            data: (adminData['is_all_chats'] ?? false).toString(),
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
          final clientResponse = await dio.get(
            ApiEndpoints.getClientDetails,
            queryParameters: {'clientId': clientId},
          );

          if (clientResponse.statusCode == 200) {
            final clientData = clientResponse.data;
            String cName = clientData['name'] ?? 'Messaging Portal';
            String cLogo = clientData['logoUrl'] ?? '';
            bool crmEnabled = clientData['isCRMEnabled'] == true;

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
          }
        } catch (e) {
          print('Error fetching client details: $e');
        }

        // --- Fetch and Store Charges Collection for Local Storage ---
        try {
          final chargesResponse = await dio.get(ApiEndpoints.getCharges);
          if (chargesResponse.statusCode == 200) {
            WebUtils.saveToLocalStorage(
              'charges',
              jsonEncode(chargesResponse.data),
            );
          }
        } catch (e) {
          print('Error fetching or storing charges: $e');
        }
        // -----------------------------------------------------

        showLoading.value = false;

        // Start listening to subscription updates now that we have clientID
        SubscriptionService.instance.startListening();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(Routes.DASHBOARD);
        });
      } else {
        showLoading.value = false;
        Utilities.showSnackbar(
          SnackType.ERROR,
          response.data['detail'] ?? 'Invalid email or password',
        );
      }
    } catch (e) {
      showLoading.value = false;
      if (e is dio.DioException) {
        NetworkUtilities.dioExceptionHandler(e);
      } else {
        Utilities.showSnackbar(SnackType.ERROR, 'Login failed: $e');
      }
    }
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
