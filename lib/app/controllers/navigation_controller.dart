import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../modules/contacts/controllers/contacts_controller.dart';
import '../modules/templates/controllers/templates_controller.dart';
import '../modules/broadcasts/controllers/broadcasts_controller.dart';
import '../modules/settings/controllers/settings_controller.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString currentRoute = ''.obs;

  /// Keep this as requested
  final RxInt routeTrigger = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _updateIndexFromRoute();
  }

  void _updateIndexFromRoute() {
    try {
      final fullRoute = Get.currentRoute;
      // Extract route name without parameters
      final route = fullRoute.split('?').first;
      currentRoute.value = route;

      routeTrigger.value++;

      switch (route) {
        case Routes.DASHBOARD:
          selectedIndex.value = 0;
          break;
        case Routes.ADMINS:
        case Routes.ADD_ADMINS:
          selectedIndex.value = 1;
          break;
        case Routes.ROLES:
        case Routes.ADD_ROLES:
          selectedIndex.value = 2;
          break;
        case Routes.CONTACTS:
          selectedIndex.value = 3;
          break;
        case Routes.TEMPLATES:
        case Routes.CREATE_TEMPLATE:
          selectedIndex.value = 4;
          break;
        case Routes.BROADCASTS:
        case Routes.CREATE_BROADCAST:
        case Routes.CREATE_CAMPAIGN_FROM_DASHBOARD:
          // case Routes.BROADCAST_AUDIENCE:
          // case Routes.BROADCAST_CONTENT:
          // case Routes.BROADCAST_SCHEDULE:
          selectedIndex.value = 5;
          break;
        case Routes.CHATS:
          selectedIndex.value = 6;
          break;
        case Routes.SETTINGS:
        case Routes.BUSINESS_PROFILE:
          selectedIndex.value = 7;
          break;
        case Routes.CLIENTS:
        case Routes.ADD_CLIENT:
        case Routes.EDIT_CLIENT:
          selectedIndex.value = 9;
          break;
        case Routes.MILESTONE_SCHEDULARS:
        case Routes.CREATE_MILESTONE_SCHEDULARS:
          selectedIndex.value = 8;
          break;
        default:
          selectedIndex.value = 0;
      }
    } catch (e) {
      // If Get.currentRoute is not available yet, default to dashboard
      currentRoute.value = Routes.DASHBOARD;
      selectedIndex.value = 0;
      routeTrigger.value++;
    }
  }

  // -------------------------------------------------------------------
  // 🔥 Contain your clear/reset logic WITHOUT initializing controllers
  // -------------------------------------------------------------------
  void _applyResetLogic(int index) {
    // CONTACTS RESET
    if (index == 3 && Get.isRegistered<ContactsController>()) {
      final c = Get.find<ContactsController>();
      c.isAddingContact.value = false;
      c.isEditingContact.value = false;
      c.searchQuery.value = "";
      c.searchController.clear();
      c.loadContacts();
    }

    // TEMPLATES RESET
    if (index == 4 && Get.isRegistered<TemplatesController>()) {
      final t = Get.find<TemplatesController>();
      t.isCreatingTemplate.value = false;
    }

    // BROADCAST RESET
    if (index == 5 && Get.isRegistered<BroadcastsController>()) {
      final b = Get.find<BroadcastsController>();
      b.isCreatingBroadcast.value = false;
      b.loadBroadcasts(page: 1);
      b.searchQuery.value = '';
      b.searchController.clear();
      b.selectedFilter.value = 'All';
    }

    // SETTINGS LOAD
    if (index == 7 && Get.isRegistered<SettingsController>()) {
      final s = Get.find<SettingsController>();
      s.getBroadcastData();
    }

    // MILESTONE SCHEDULARS RESET
    // We don't have a direct import for MilestoneSchedularsController here yet,
    // but we can add it if needed. For now let's just use Get.isRegistered
    if (index == 8 && Get.isRegistered<dynamic>()) {
      // Logic if needed
    }
  }

  // -------------------------------------------------------------------

  void changePage(int index) async {
    isLoading.value = true;
    selectedIndex.value = index;

    // 🔥 Apply your clear/reset logic
    _applyResetLogic(index);

    switch (index) {
      case 0:
        Get.toNamed(Routes.DASHBOARD);
        break;
      case 1:
        Get.toNamed(Routes.ADMINS);
        break;
      case 2:
        Get.toNamed(Routes.ROLES);
        break;
      case 3:
        Get.toNamed(Routes.CONTACTS);
        break;
      case 4:
        Get.toNamed(Routes.TEMPLATES);
        break;
      case 5:
        Get.toNamed(Routes.BROADCASTS);
        break;
      case 6:
        Get.toNamed(Routes.CHATS);
        break;
      case 7:
        Get.toNamed(Routes.SETTINGS);
        break;
      case 8:
        Get.toNamed(Routes.MILESTONE_SCHEDULARS);
        break;
      case 9:
        Get.toNamed(Routes.CLIENTS);
        break;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    _updateIndexFromRoute();

    isLoading.value = false;
  }

  void updateRoute() {
    _updateIndexFromRoute();
  }

  // Sidebar shortcuts
  void navigateToDashboard() => changePage(0);
  void navigateToAdmins() => changePage(1);
  void navigateToRoles() => changePage(2);
  void navigateToContacts() => changePage(3);
  void navigateToTemplates() => changePage(4);
  void navigateToBroadcasts() => changePage(5);
  void navigateToChats() => changePage(6);
  void navigateToSettings() => changePage(7);
  void navigateToMilestoneSchedulars() => changePage(8);
  void navigateToClients() => changePage(9);
  void reset() {
    selectedIndex.value = 0;
    isLoading.value = false;
    currentRoute.value = '';
    routeTrigger.value = 0;
  }
}
