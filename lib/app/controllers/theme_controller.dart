import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Load saved theme
    final saved = _box.read(_key);
    isDarkMode.value = saved is bool ? saved : false;

    // Apply theme at startup
    _applyTheme(isDarkMode.value);
  }

  /// Toggle between dark & light mode
  void toggleTheme() {
    setTheme(!isDarkMode.value);
  }

  /// Set theme explicitly
  void setTheme(bool darkMode) {
    if (isDarkMode.value == darkMode) return; // No unnecessary update

    isDarkMode.value = darkMode;

    // Save theme state
    _box.write(_key, darkMode);

    _applyTheme(darkMode);
  }

  /// Internal function to apply theme system-wide
  void _applyTheme(bool darkMode) {
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
  }

  /// Public getter
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
