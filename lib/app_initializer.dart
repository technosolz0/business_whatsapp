import 'package:adminpanel/app/Utilities/constants/app_constants.dart';
import 'package:adminpanel/app/Utilities/webutils.dart';
import 'package:adminpanel/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AppInitializer {
  static Future<void> init() async {
    // Read global tokens
    gJwtToken = WebUtils.readCookie('jwt') ?? '';
    String currentCid = WebUtils.readCookie('currentClientId') ?? '';

    // Helper to read scoped or unscoped cookies
    String getCookieValue(String key) {
      if (currentCid.isNotEmpty) {
        final scoped = WebUtils.readCookie('${key}_$currentCid');
        if (scoped != null && scoped.isNotEmpty) return scoped;
      }
      return WebUtils.readCookie(key) ?? '';
    }

    String encryptedName = getCookieValue('name');
    adminName.value = encryptedName.isNotEmpty
        ? WebUtils.decryptData(
            data: encryptedName,
            secretKey: AppConstants.menuItemsSecret,
          )
        : '';

    String encryptedClientId = getCookieValue('clientId');
    clientID = encryptedClientId.isNotEmpty
        ? WebUtils.decryptData(
            data: encryptedClientId,
            secretKey: AppConstants.menuItemsSecret,
          )
        : '';
    // Fallback: use currentCid if clientID is still empty
    if (clientID.isEmpty && currentCid.isNotEmpty) {
      clientID = currentCid;
    }

    String encryptedAdminId = getCookieValue('adminId');
    adminID = encryptedAdminId.isNotEmpty
        ? WebUtils.decryptData(
            data: encryptedAdminId,
            secretKey: AppConstants.menuItemsSecret,
          )
        : '';

    String encryptedIsSuperUser = getCookieValue('isSuperUser');
    isSuperUser.value = encryptedIsSuperUser.isNotEmpty
        ? WebUtils.decryptData(
                data: encryptedIsSuperUser,
                secretKey: AppConstants.menuItemsSecret,
              ) ==
              'true'
        : false;

    String encryptedIsAllChats = getCookieValue('isAllChats');
    isAllChats.value = encryptedIsAllChats.isNotEmpty
        ? WebUtils.decryptData(
                data: encryptedIsAllChats,
                secretKey: AppConstants.menuItemsSecret,
              ) ==
              'true'
        : false;

    String encryptedClientName = getCookieValue('clientName');
    clientName.value = encryptedClientName.isNotEmpty
        ? WebUtils.decryptData(
            data: encryptedClientName,
            secretKey: AppConstants.menuItemsSecret,
          )
        : 'Messaging Portal';

    String encryptedClientLogo = getCookieValue('clientLogo');
    clientLogo.value = encryptedClientLogo.isNotEmpty
        ? WebUtils.decryptData(
            data: encryptedClientLogo,
            secretKey: AppConstants.menuItemsSecret,
          )
        : '';

    String encryptedIsCRMEnabled = getCookieValue('isCRMEnabled');
    isCRMEnabled.value = encryptedIsCRMEnabled.isNotEmpty
        ? WebUtils.decryptData(
                data: encryptedIsCRMEnabled,
                secretKey: AppConstants.menuItemsSecret,
              ) ==
              'true'
        : false;

    String encryptedIsConnected = getCookieValue('isConnected');
    isConnected.value = encryptedIsConnected.isNotEmpty
        ? WebUtils.decryptData(
                data: encryptedIsConnected,
                secretKey: AppConstants.menuItemsSecret,
              ) ==
              'true'
        : false;

    if (gJwtToken.isNotEmpty) {
      try {
        JWT.verify(gJwtToken, SecretKey(AppConstants.menuItemsSecret));
      } catch (e) {
        gJwtToken = '';
        WebUtils.deleteCookies();
      }
    }
  }

  static Future<void> updateLastLogin() async {
    if (gJwtToken.isNotEmpty) {
      try {
        final jwt = JWT.verify(
          gJwtToken,
          SecretKey(AppConstants.menuItemsSecret),
        );

        final adminId = jwt.payload['adminId'];

        if (adminId != null) {
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(adminId)
              .update({"last_logged_in": DateTime.now().toIso8601String()});
        }
      } catch (e) {
        // Token might be expired or invalid, already handled in init
      }
    }
  }
}
