import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:adminpanel/main.dart';
import 'package:adminpanel/app/Utilities/network_utilities.dart';
import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';
import 'package:adminpanel/app/Utilities/webutils.dart';
import 'package:adminpanel/app/Utilities/constants/app_constants.dart';

class ZohoCrmController extends GetxController {
  final clientIdController = TextEditingController();
  final clientSecretController = TextEditingController();
  final zohoTokenController = TextEditingController();
  final selectedDataCenter = 'US (.com)'.obs;
  final isLoading = false.obs;
  final statusMessage = "".obs;
  final statusType = Rx<SnackType?>(null);

  final List<String> dataCenters = [
    'US (.com)',
    'EU (.eu)',
    'IN (.in)',
    'CN (.com.cn)',
    'AU (.com.au)',
    'JP (.jp)',
  ];

  @override
  void onInit() {
    super.onInit();
    getZohoCrmData();
  }

  @override
  void onClose() {
    clientIdController.dispose();
    clientSecretController.dispose();
    zohoTokenController.dispose();
    super.onClose();
  }

  void saveSettings() async {
    final zohoClientId = clientIdController.text.trim();
    final clientSecret = clientSecretController.text.trim();
    final grantToken = zohoTokenController.text.trim();
    final dataCenter = selectedDataCenter.value;

    if (zohoClientId.isEmpty || clientSecret.isEmpty || grantToken.isEmpty) {
      statusMessage.value = "All fields are required";
      statusType.value = SnackType.INFO;
      return;
    }

    isLoading.value = true;
    statusMessage.value = "";
    statusType.value = null;

    try {
      // Map display names to Zoho accounts URLs
      String accountsUrl = "https://accounts.zoho.com";
      if (dataCenter.contains(".eu")) {
        accountsUrl = "https://accounts.zoho.eu";
      } else if (dataCenter.contains(".in")) {
        accountsUrl = "https://accounts.zoho.in";
      } else if (dataCenter.contains(".com.cn")) {
        accountsUrl = "https://accounts.zoho.com.cn";
      } else if (dataCenter.contains(".com.au")) {
        accountsUrl = "https://accounts.zoho.com.au";
      } else if (dataCenter.contains(".jp")) {
        accountsUrl = "https://accounts.zoho.jp";
      }

      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        "https://generateZohoAccessAndRefreshToken-d3b4t36f7q-uc.a.run.app",
        data: {
          "clientId": clientID,
          "zohoCrmClientId": zohoClientId,
          "clientSecret": clientSecret,
          "accountsUrl": accountsUrl,
          "grantToken": grantToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data["success"] == true) {
          await getZohoCrmData();
          statusMessage.value = "Successfully connect to Zoho CRM.";
          statusType.value = SnackType.SUCCESS;
        } else {
          await getZohoCrmData();
          statusMessage.value =
              data["message"] ?? "Unable to connect to Zoho CRM.";
          statusType.value = SnackType.ERROR;
        }
      } else {
        await getZohoCrmData();
        statusMessage.value =
            response.data["message"] ?? "Server error: ${response.statusCode}";
        statusType.value = SnackType.ERROR;
      }
    } on DioException catch (e) {
      await getZohoCrmData();
      statusMessage.value = "Network error: ${e.message}";
      statusType.value = SnackType.ERROR;
    } catch (e) {
      await getZohoCrmData();
      statusMessage.value = "An unexpected error occurred: $e";
      statusType.value = SnackType.ERROR;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getZohoCrmData() async {
    try {
      if (clientID.isEmpty) {
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('profile')
          .doc(clientID)
          .collection('integrations')
          .doc('zoho_crm')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        clientIdController.text = data["client_id"] ?? "";
        clientSecretController.text = data["client_secret"] ?? "";
        zohoTokenController.text = data["grant_token"] ?? "";

        // Update global isConnected
        isConnected.value = data["isConnected"] ?? false;

        // Store in Cookies
        _updateIsConnectedCookie(isConnected.value);

        // Map accounts_url to selectedDataCenter
        String accountsUrl =
            data["accounts_url"] ?? "https://accounts.zoho.com";

        if (accountsUrl.contains(".eu")) {
          selectedDataCenter.value = 'EU (.eu)';
        } else if (accountsUrl.contains(".in")) {
          selectedDataCenter.value = 'IN (.in)';
        } else if (accountsUrl.contains(".com.cn")) {
          selectedDataCenter.value = 'CN (.com.cn)';
        } else if (accountsUrl.contains(".com.au")) {
          selectedDataCenter.value = 'AU (.com.au)';
        } else if (accountsUrl.contains(".jp")) {
          selectedDataCenter.value = 'JP (.jp)';
        } else {
          selectedDataCenter.value = 'US (.com)';
        }
      } else {
        isConnected.value = false;
        _updateIsConnectedCookie(false);
      }
    } catch (e, stackTrace) {
      Utilities.dLog("getZohoCrmData: ERROR: $e");
      Utilities.showSnackbar(
        SnackType.ERROR,
        "An unexpected error occurred while fetching Zoho CRM data: $e",
      );
    }
  }

  void _updateIsConnectedCookie(bool connected) {
    if (clientID.isNotEmpty) {
      WebUtils.addCookie(
        key: 'isConnected_$clientID',
        value: WebUtils.encryptData(
          data: connected.toString(),
          secretKey: AppConstants.menuItemsSecret,
        ),
      );
    }
  }
}
