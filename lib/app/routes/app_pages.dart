import 'package:adminpanel/app/modules/add_roles/bindings/add_roles_binding.dart';
import 'package:adminpanel/app/modules/admins/bindings/admins_binding.dart';
import 'package:adminpanel/app/modules/broadcasts/bindings/broadcasts_binding.dart';
import 'package:adminpanel/app/modules/chats/bindings/chats_binding.dart';
import 'package:adminpanel/app/modules/contacts/bindings/contacts_binding.dart';
import 'package:adminpanel/app/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:adminpanel/app/modules/login/bindings/login_binding.dart';
import 'package:adminpanel/app/modules/login/views/login_view.dart';
import 'package:adminpanel/app/modules/roles/bindings/roles_binding.dart';
import 'package:adminpanel/app/modules/add_admins/bindings/add_admins_binding.dart';
import 'package:adminpanel/app/modules/settings/bindings/settings_binding.dart';
import 'package:adminpanel/app/modules/business_profile/bindings/business_profile_binding.dart';
import 'package:adminpanel/app/modules/templates/bindings/create_template_binding.dart';
import 'package:adminpanel/app/modules/templates/bindings/templates_binding.dart';
import 'package:adminpanel/app/modules/milestone_templates/bindings/milestone_schedulars_binding.dart';
import 'package:adminpanel/app/modules/clients/bindings/clients_binding.dart';
import 'package:adminpanel/app/modules/add_client/bindings/add_client_binding.dart';
import 'package:adminpanel/app/modules/custom_notifications/bindings/custom_notifications_binding.dart';
import 'package:adminpanel/app/modules/charges/bindings/charges_binding.dart';
import 'package:adminpanel/app/modules/automation/bindings/automation_binding.dart';
import 'package:adminpanel/app/modules/zoho_crm/bindings/zoho_crm_binding.dart';
import 'package:adminpanel/app/routes/route_guard.dart';
import 'package:adminpanel/app/views/main_shell_view.dart';

import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => MainShellView(),
      binding: DashboardBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
      // middlewares: [LoggedInRoutes()],
    ),
    GetPage(
      name: _Paths.ADD_ADMINS,
      page: () => MainShellView(),
      binding: AddAdminsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.ADD_ROLES,
      page: () => MainShellView(),
      binding: AddRolesBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.ROLES,
      page: () => MainShellView(),
      binding: RolesBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CONTACTS,
      page: () => MainShellView(),
      binding: ContactsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.BROADCASTS,
      page: () => MainShellView(),
      binding: BroadcastsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CREATE_CAMPAIGN_FROM_DASHBOARD,
      page: () => MainShellView(),
      binding: BroadcastsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CREATE_BROADCAST,
      page: () => MainShellView(),
      binding: BroadcastsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.BROADCAST_AUDIENCE,
      page: () => MainShellView(),
      binding: BroadcastsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.BROADCAST_CONTENT,
      page: () => MainShellView(),
      binding: BroadcastsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.BROADCAST_SCHEDULE,
      page: () => MainShellView(),
      binding: BroadcastsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CHATS,
      page: () => MainShellView(),
      binding: ChatsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.TEMPLATES,
      page: () => MainShellView(),
      binding: TemplatesBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.MILESTONE_SCHEDULARS,
      page: () => MainShellView(),
      binding: MilestoneSchedularsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CREATE_MILESTONE_SCHEDULARS,
      page: () => MainShellView(),
      binding: MilestoneSchedularsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CREATE_TEMPLATE,
      page: () => MainShellView(),
      binding: CreateTemplateBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => MainShellView(),
      binding: SettingsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.BUSINESS_PROFILE,
      page: () => MainShellView(),
      binding: BusinessProfileBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CLIENTS,
      page: () => MainShellView(),
      binding: ClientsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.ADD_CLIENT,
      page: () => MainShellView(),
      binding: AddClientBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.EDIT_CLIENT,
      page: () => MainShellView(),
      binding: AddClientBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.ADMINS,
      page: () => MainShellView(),
      binding: AdminsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CUSTOM_NOTIFICATIONS,
      page: () => MainShellView(),
      binding: CustomNotificationsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CREATE_CUSTOM_NOTIFICATION,
      page: () => MainShellView(),
      binding: CustomNotificationsBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.CHARGES,
      page: () => MainShellView(),
      binding: ChargesBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.AUTOMATION,
      page: () => MainShellView(),
      binding: AutomationBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
    GetPage(
      name: _Paths.ZOHO_CRM,
      page: () => MainShellView(),
      binding: ZohoCrmBinding(),
      middlewares: [AuthenticatedRoutes()],
    ),
  ];
}
