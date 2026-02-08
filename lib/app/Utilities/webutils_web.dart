import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
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

  /// Adds a cookie
  static Future addCookie({required String key, required String value}) async {
    // Correctly set a single cookie. Browsers handle the merging.
    // Set path=/ to make it available globally. Set a long expiry for persistence.
    // Use proper encoding if necessary, but key/value are usually safe chars here.
    html.document.cookie =
        "$key=$value; path=/; max-age=31536000; SameSite=Lax";
  }

  /// Reads a cookie by key
  static String? readCookie(String key) {
    String? cookies = html.document.cookie;
    if (cookies == null) return null;
    Map<String, dynamic> cookieEntries = {};
    List<String> splittedC = cookies.split("; ");
    for (int i = 0; i < splittedC.length; i++) {
      final List<String> split = splittedC[i].split("=");
      String val = split.sublist(1, split.length).join('=');
      cookieEntries[split[0]] = val;
    }
    return cookieEntries[key];
  }

  /// deletes all cookies
  static void deleteCookies() {
    final cookies = html.document.cookie?.split(';');
    if (cookies != null) {
      for (var cookie in cookies) {
        final cookieName = cookie.split('=')[0].trim();
        html.document.cookie =
            '$cookieName=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
      }
    }
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
