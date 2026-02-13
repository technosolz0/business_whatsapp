import 'package:adminpanel/app_initializer.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_strategy/url_strategy.dart';
import 'firebase_options.dart';

import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/navigation_controller.dart';
import 'app/data/services/subscription_service.dart';
import 'app/modules/maintenance/views/under_maintenance_screen.dart';

// Web URL strategy function
void configureUrlStrategy() {
  if (kIsWeb) {
    // Configure Flutter web to use path-based URLs instead of hash-based URLs
    // This removes the # from URLs like localhost:8080/#/contacts → localhost:8080/contacts
    setPathUrlStrategy();
  }
}

/// Global variables
///
String gJwtToken = '';
RxString adminName = ''.obs;
String adminID = '';
String clientID = '';
RxBool isSuperUser = false.obs;
RxBool isAllChats = false.obs;
RxString clientName = ''.obs;
RxString clientLogo = ''.obs;
RxBool isCRMEnabled = false.obs;
RxBool isConnected = false.obs;

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppInitializer.init();

  // Initialize controllers
  Get.put(ThemeController());
  Get.put(NavigationController()); // Add NavigationController
  await Get.putAsync(() => SubscriptionService().init());

  await AppInitializer.updateLastLogin();

  // Set path URL strategy for web builds to remove # from URLs
  configureUrlStrategy();

  bool isUnderMaintenance = false;
  try {
    // Initialize Remote Config
    final remoteConfig = FirebaseRemoteConfig.instance;

    // Set configuration settings (e.g., fetch interval)
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        // Set to 0 for development to ensure instant updates.
        // For production, increase this (e.g., 12 hours) to avoid rate limits.
        minimumFetchInterval: const Duration(seconds: 0),
      ),
    );

    // Set default values
    await remoteConfig.setDefaults(const {"is_under_maintenance": false});

    // Fetch and activate
    await remoteConfig.fetchAndActivate();

    // Get the value
    isUnderMaintenance = remoteConfig.getBool('is_under_maintenance');
    // print('Remote Config Maintenance Check: $isUnderMaintenance');
  } catch (e) {
    print('Error using Remote Config for maintenance check: $e');
  }

  if (isUnderMaintenance) {
    runApp(const UnderMaintenanceScreen());
    return;
  }

  final themeController = Get.find<ThemeController>();

  runApp(
    GetMaterialApp(
      title: "WhatsApp Campaigns Dashboard",
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.noTransition,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
