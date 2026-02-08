import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:business_whatsapp/app/modules/add_roles/widgets/desktop_add_roles.dart';
import 'package:business_whatsapp/app/modules/add_roles/widgets/phone_add_roles.dart';

import '../controllers/add_roles_controller.dart';

class AddRolesView extends GetResponsiveView<AddRolesController> {
  AddRolesView({super.key});

  @override
  Widget desktop() {
    return const SafeArea(child: DesktopAddRoles());
  }

  @override
  Widget tablet() {
    return const SafeArea(child: DesktopAddRoles());
  }

  @override
  Widget phone() {
    return const SafeArea(child: PhoneAddRoles());
  }
}
