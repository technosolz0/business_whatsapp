import 'package:business_whatsapp/app/data/models/menu_item_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../Utilities/responsive.dart';
import '../common widgets/sidebar_widget.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/roles/views/roles_view.dart';
import '../modules/admins/views/admins_view.dart';
import '../modules/add_admins/views/add_admins_view.dart';
import '../modules/add_roles/views/add_roles_view.dart';
import '../modules/broadcasts/views/broadcasts_view.dart';
import '../modules/contacts/views/contacts_view.dart';
import '../modules/chats/views/chats_view.dart';
import '../modules/templates/views/templates_view.dart';
import '../modules/milestone_templates/views/milestone_schedulars_view.dart';
import '../modules/milestone_templates/views/create_milestone_schedular_view.dart';
import '../modules/templates/views/create_template_view.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/business_profile/views/business_profile_view.dart';
import '../modules/clients/views/clients_view.dart';
import '../modules/add_client/views/add_client_view.dart';
import '../modules/custom_notifications/views/custom_notifications_view.dart';
import '../modules/custom_notifications/views/create_custom_notification_view.dart';
import '../modules/charges/views/charges_view.dart';
import '../modules/automation/views/automation_view.dart';
import '../modules/zoho_crm/views/zoho_crm_view.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/templates/controllers/templates_controller.dart';
import '../modules/templates/controllers/create_template_controller.dart';
import '../modules/broadcasts/controllers/broadcasts_controller.dart';
import '../modules/broadcasts/controllers/create_broadcast_controller.dart';
import '../modules/chats/controllers/chats_controller.dart';
import '../modules/settings/controllers/settings_controller.dart';
import '../modules/business_profile/controllers/business_profile_controller.dart';
import '../modules/contacts/controllers/contacts_controller.dart';
import '../modules/admins/controllers/admins_controller.dart';
import '../modules/roles/controllers/roles_controller.dart';
import '../modules/charges/controllers/charges_controller.dart';
import '../routes/app_pages.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initialize all controllers that MainShellView might need
    _initializeControllers();

    // 🔥 Ensure NavigationController is in sync with current route
    // This fixes the issue where sidebar selection persists after logout/login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().updateRoute();
      }
    });
  }

  void _initializeControllers() {
    // Only initialize controllers that are always needed
    // Dashboard Controller (needed for sidebar unread counts)
    if (!Get.isRegistered<DashboardController>()) {
      Get.put<DashboardController>(DashboardController());
    }

    // Templates Controller
    if (!Get.isRegistered<TemplatesController>()) {
      Get.put<TemplatesController>(TemplatesController());
    }

    // Broadcasts Controller
    if (!Get.isRegistered<BroadcastsController>()) {
      Get.put<BroadcastsController>(BroadcastsController());
    }

    // Create Broadcast Controller
    if (!Get.isRegistered<CreateBroadcastController>()) {
      Get.put<CreateBroadcastController>(CreateBroadcastController());
    }

    // Create Template Controller
    if (!Get.isRegistered<CreateTemplateController>()) {
      Get.put<CreateTemplateController>(CreateTemplateController());
    }

    // Chats Controller (needed for sidebar unread counts)
    if (!Get.isRegistered<ChatsController>()) {
      Get.put<ChatsController>(ChatsController(), permanent: true);
    }

    // Settings Controller
    if (!Get.isRegistered<SettingsController>()) {
      Get.put<SettingsController>(SettingsController());
    }

    // Business Profile Controller
    if (!Get.isRegistered<BusinessProfileController>()) {
      Get.put<BusinessProfileController>(BusinessProfileController());
    }

    // Contacts Controller
    if (!Get.isRegistered<ContactsController>()) {
      Get.put<ContactsController>(ContactsController());
    }

    // Admins Controller
    if (!Get.isRegistered<AdminsController>()) {
      Get.put<AdminsController>(AdminsController());
    }

    // Roles Controller
    if (!Get.isRegistered<RolesController>()) {
      Get.put<RolesController>(RolesController());
    }

    // Charges Controller
    if (!Get.isRegistered<ChargesController>()) {
      Get.put<ChargesController>(ChargesController());
    }

    // Let Add controllers be created on demand to avoid conflicts
  }

  @override
  Widget build(BuildContext context) {
    // Get navigation controller (already initialized in main.dart)
    final NavigationController navController = Get.find<NavigationController>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: Responsive.isMobile(context)
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text('Messaging Portal'),
              elevation: 0,
            )
          : null,
      drawer: MediaQuery.of(context).size.width < 768
          ? Drawer(
              child: SidebarWidget(
                onItemTap: () {
                  // Close drawer after navigation on mobile
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Fixed Sidebar for Desktop and Tablet (screens >= 768px)
          if (MediaQuery.of(context).size.width >= 768) const SidebarWidget(),

          // Content Area - Only this part changes
          Expanded(
            child: Builder(
              builder: (context) => Obx(() {
                // Watch for route changes via NavigationController
                final currentRoute = navController.currentRoute.value;

                return AnimatedSwitcher(
                  duration: Responsive.isMobile(context)
                      ? const Duration(milliseconds: 100)
                      : const Duration(milliseconds: 200),
                  child: _getPageFromRoute(currentRoute),
                );
              }),
            ),
          ),
        ],
      ),

      // Loading Overlay
    );
  }

  Widget _getPageFromRoute(String currentRoute) {
    // Use Get.currentRoute directly for more reliable route detection
    final actualRoute = Get.currentRoute
        .split('?')
        .first; // Remove query params

    switch (actualRoute) {
      case Routes.DASHBOARD:
        return DashboardView(key: ValueKey(Routes.DASHBOARD));
      case Routes.ADD_ADMINS:
        return AddAdminsView(key: ValueKey(Routes.ADD_ADMINS));
      case Routes.ADMINS:
        return AdminsView(
          key: ValueKey(Routes.ADMINS),
          item: MenuItem(
            name: Text('Admins'),
            icon: Icon(Icons.admin_panel_settings),
            route: Routes.ADMINS,
            canView: true,
            canEdit: true,
            canDelete: true,
          ),
        );
      case Routes.ADD_ROLES:
        return AddRolesView(key: ValueKey(Routes.ADD_ROLES));
      case Routes.ROLES:
        return RolesView(
          key: ValueKey(Routes.ROLES),
          item: MenuItem(
            name: Text('Roles'),
            icon: Icon(Icons.assignment_ind),
            route: Routes.ROLES,
            canView: true,
            canEdit: true,
            canDelete: true,
          ),
        );
      case Routes.CONTACTS:
        return ContactsView(key: ValueKey(Routes.CONTACTS));
      case Routes.CREATE_TEMPLATE:
        return CreateTemplateView(key: ValueKey(Routes.CREATE_TEMPLATE));
      case Routes.TEMPLATES:
        return TemplatesView(key: ValueKey(Routes.TEMPLATES));
      case Routes.MILESTONE_SCHEDULARS:
        return MilestoneSchedularsView(
          key: ValueKey(Routes.MILESTONE_SCHEDULARS),
        );
      case Routes.CREATE_MILESTONE_SCHEDULARS:
        return CreateMilestoneSchedularView(
          key: ValueKey(Routes.CREATE_MILESTONE_SCHEDULARS),
        );
      case Routes.BROADCASTS:
        return BroadcastsView(key: ValueKey(Routes.BROADCASTS));
      case Routes.CREATE_CAMPAIGN_FROM_DASHBOARD:
        return BroadcastsView(
          key: ValueKey(Routes.CREATE_CAMPAIGN_FROM_DASHBOARD),
        );
      case Routes.CREATE_BROADCAST:
      case Routes.BROADCAST_AUDIENCE:
      case Routes.BROADCAST_CONTENT:
      case Routes.BROADCAST_SCHEDULE:
        return BroadcastsView(key: ValueKey(actualRoute));
      case Routes.CHATS:
        return ChatsView(key: ValueKey(Routes.CHATS));
      case Routes.SETTINGS:
        return SettingsView(key: ValueKey(Routes.SETTINGS));
      case Routes.BUSINESS_PROFILE:
        return BusinessProfileView(key: ValueKey(Routes.BUSINESS_PROFILE));
      case Routes.CLIENTS:
        return ClientsView(key: ValueKey(Routes.CLIENTS));
      case Routes.ADD_CLIENT:
        return AddClientView(key: ValueKey(Routes.ADD_CLIENT));
      case Routes.EDIT_CLIENT:
        return AddClientView(key: ValueKey(Routes.EDIT_CLIENT));
      case Routes.CUSTOM_NOTIFICATIONS:
        return CustomNotificationsView(
          key: ValueKey(Routes.CUSTOM_NOTIFICATIONS),
        );
      case Routes.CREATE_CUSTOM_NOTIFICATION:
        return CreateCustomNotificationView(
          key: ValueKey(Routes.CREATE_CUSTOM_NOTIFICATION),
        );
      case Routes.CHARGES:
        return ChargesView(key: ValueKey(Routes.CHARGES));
      case Routes.AUTOMATION:
        return AutomationView(key: ValueKey(Routes.AUTOMATION));
      case Routes.ZOHO_CRM:
        return ZohoCrmView(key: ValueKey(Routes.ZOHO_CRM));
      default:
        return DashboardView(key: ValueKey(Routes.DASHBOARD));
    }
  }
}
