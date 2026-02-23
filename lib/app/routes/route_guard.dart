import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthenticatedRoutes extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    return gJwtToken.isEmpty ? const RouteSettings(name: Routes.LOGIN) : null;
  }
}

class LoggedInRoutes extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (gJwtToken.isEmpty) {
      return null;
    } else {
      Get.deleteAll();
      return const RouteSettings(name: Routes.DASHBOARD);
    }
  }
}
