import 'package:flutter/gestures.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class WebUtils {
  static const double desktopBreakpoint = 1200;
  static const double tabletBreakpoint = 600;
  static const double phoneBreakpoint = 300;

  static void getCurrentPageTitle(String pageTitle) {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: pageTitle,
        primaryColor: 0xffaaaaaa,
      ),
    );
  }

  static String getCurrentRoute(BuildContext context) {
    var modalRoute = ModalRoute.of(context);
    String route = "/";
    if (modalRoute != null) {
      route = modalRoute.settings.name ?? route;
    }
    return route.split('?')[0];
  }

  // to go back to the last page based on route and pass route and context
  static void goBackTo(String route, BuildContext context) {
    Get.offNamed(route);
  }

  /// Adds a cookie - no-op on mobile
  static Future addCookie({required String key, required String value}) async {
    // No-op for mobile platforms
  }

  /// Reads a cookie by key - returns null on mobile
  static String? readCookie(String key) {
    return null; // No cookies on mobile
  }

  /// deletes all cookies - no-op on mobile
  static void deleteCookies() {
    // No-op for mobile platforms
  }

  /// Encrypts data using secret key
  static String encryptData({required String data, required String secretKey}) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final iv = encrypt.IV.allZerosOfLength(16);
    return encrypt.Encrypter(encrypt.AES(key)).encrypt(data, iv: iv).base64;
  }

  /// Decrypts data using secret key
  static String decryptData({required String data, required String secretKey}) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final iv = encrypt.IV.allZerosOfLength(16);
    return encrypt.Encrypter(
      encrypt.AES(key),
    ).decrypt(encrypt.Encrypted.fromBase64(data), iv: iv);
  }

  /// Downloads a file - no-op on mobile
  static void downloadFile(Uint8List bytes, String fileName, String mimeType) {
    // No-op for mobile platforms
  }

  /// Saves data to local storage - no-op on mobile
  static void saveToLocalStorage(String key, String value) {
    // No-op for mobile platforms
  }

  /// Reads data from local storage - returns null on mobile
  static String? getFromLocalStorage(String key) {
    return null;
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
