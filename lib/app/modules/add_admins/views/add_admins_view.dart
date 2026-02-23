import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:business_whatsapp/app/modules/add_admins/widgets/add_admin_desktop.dart';
import 'package:business_whatsapp/app/modules/add_admins/widgets/add_admin_phone.dart';

import '../controllers/add_admins_controller.dart';

class AddAdminsView extends GetResponsiveView<AddAdminsController> {
  AddAdminsView({super.key});

  @override
  Widget desktop() {
    return const SafeArea(child: AddAdminDesktop());
  }

  @override
  Widget tablet() {
    return const SafeArea(child: AddAdminDesktop());
  }

  @override
  Widget phone() {
    return const SafeArea(child: AddAdminPhone());
  }
}
