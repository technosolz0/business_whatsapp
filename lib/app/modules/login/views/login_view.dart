import 'package:flutter/material.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';

import 'package:get/get.dart';
import 'package:adminpanel/app/modules/login/widgets/desktop_login_screen.dart';
import 'package:adminpanel/app/modules/login/widgets/phone_login_screen.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetResponsiveView<LoginController> {
  LoginView({super.key});

  @override
  Widget desktop() {
    return Scaffold(
      backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: DesktopLoginScreen(),
    );
  }

  @override
  Widget tablet() {
    return Scaffold(
      backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: PhoneLoginScreen(),
    );
  }

  @override
  Widget phone() {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: PhoneLoginScreen(),
      ),
    );
  }
}
