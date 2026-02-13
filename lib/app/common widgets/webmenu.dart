import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';
import 'package:adminpanel/app/core/constants/app_assets.dart';
import 'package:adminpanel/app/data/models/menu_item_model.dart';
import 'package:adminpanel/app/routes/app_pages.dart';
import 'package:adminpanel/app/utilities/constants/app_constants.dart';
import 'package:adminpanel/app/utilities/utilities.dart';
import 'package:adminpanel/app/utilities/webutils.dart';
import 'package:adminpanel/main.dart';

/// Global variable to handle accessible menu
List<dynamic> menu = [];

class WebMenu {
  static List<dynamic> menuItems = [
    MenuItem(
      name: Text("Dashboard", style: GoogleFonts.publicSans(fontSize: 18)),
      icon: Image.asset(AppAssets.dashboardLogo, height: 24, width: 24),
      route: Routes.HOME,
      selectedIcon: Image.asset(
        AppAssets.dashboardSelectedLogo,
        height: 24,
        width: 24,
      ),
    ),
    MenuItemGroup(
      name: Text("Admin Master", style: GoogleFonts.publicSans(fontSize: 20)),
      icon: Image.asset(AppAssets.adminMasterLogo, height: 24, width: 24),
      items: [
        MenuItem(
          name: Text("Admins", style: GoogleFonts.publicSans(fontSize: 18)),
          icon: Image.asset(AppAssets.arrowRight, height: 24, width: 24),
          route: Routes.ADMINS,
          addRoute: Routes.ADD_ADMINS,
          selectedIcon: Image.asset(
            AppAssets.arrowRightSelected,
            height: 24,
            width: 24,
            color: Colors.white,
          ),
        ),
        MenuItem(
          name: Text(
            "Manage Roles",
            style: GoogleFonts.publicSans(fontSize: 18),
          ),
          icon: Image.asset(AppAssets.arrowRight, height: 24, width: 24),
          route: Routes.ROLES,
          addRoute: Routes.ADD_ROLES,
          selectedIcon: Image.asset(
            AppAssets.arrowRightSelected,
            height: 24,
            width: 24,
            color: Colors.white,
          ),
        ),
      ],
    ),
  ];

  /// Returns current MenuItem based on the route
  /// If it is an add route, returns the root route which it belongs to
  static MenuItem? getCurrentItem(BuildContext context) {
    String route = WebUtils.getCurrentRoute(context);
    for (var e in menu) {
      if (e is MenuItem &&
          ((e.route == route && e.canView) ||
              (e.addRoute == route && e.canEdit) ||
              (e.otherRoutes != null && e.otherRoutes!.contains(route)))) {
        return e;
      } else if (e is MenuItemGroup) {
        for (MenuItem eG in e.items) {
          if ((eG.route == route && eG.canView) ||
              (eG.addRoute == route && eG.canEdit) ||
              (eG.otherRoutes != null && eG.otherRoutes!.contains(route))) {
            return eG;
          }
        }
      }
    }
    return null;
  }

  /// This function reads menu items data from cookies, then decrypts it and updates
  /// the global list based on view access
  static Future updateAccessibleItemsFromCookies() async {
    List<dynamic> menuItems = [...WebMenu.menuItems];
    menu = [];
    List<Map<String, dynamic>> cookieData = [];
    bool error = true;
    try {
      String? itemsInCookie = WebUtils.readCookie(
        AppConstants.menuItemsCookieKey,
      );
      if (itemsInCookie != null && itemsInCookie.isNotEmpty) {
        Utilities.dPrint(
          '--->${AppConstants.menuItemsCookieKey} cookie: $itemsInCookie',
        );
        String decryptedData = WebUtils.decryptData(
          data: itemsInCookie,
          secretKey: AppConstants.menuItemsSecret,
        );

        Map<String, dynamic> cookieDecrypted = Map<String, dynamic>.from(
          jsonDecode(decryptedData),
        );

        cookieData = List<Map<String, dynamic>>.from(cookieDecrypted["pages"]);

        adminID = cookieDecrypted["adminId"];
        adminName.value = cookieDecrypted["adminName"];
        clientID = cookieDecrypted["clientId"];
        error = false;
      }
    } catch (e) {
      Utilities.dPrint('--->error in reading cookies: $e');
    }
    Utilities.dPrint('--->decrypted page access:\n$cookieData');
    if (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (gJwtToken.isNotEmpty) {
          Utilities.showSnackbar(
            SnackType.ERROR,
            'Error in validating your session. Please login again!',
          );
        }
        // Utilities.logout();
      });
      return;
    }

    Map<String, dynamic>? existsInCookiesData(MenuItem m) {
      for (Map<String, dynamic> cD in cookieData) {
        String route = cD['route'];

        if (route == m.route) {
          String accessStr = (cD['ax'] ?? '').toString();
          if (accessStr.isEmpty || accessStr.length != 3) accessStr = '000';
          bool canView = accessStr[0] == '1';
          bool canEdit = accessStr[1] == '1';
          bool canDelete = accessStr[2] == '1';
          Map<String, dynamic> cookieMap = {
            'view': canView,
            'edit': canEdit,
            'delete': canDelete,
          };
          if (canView) {
            return cookieMap;
          } else {
            return null;
          }
        }
      }
      return null;
    }

    for (int i = 0; i < menuItems.length; i++) {
      dynamic e = menuItems[i];
      if (e is MenuItem) {
        Map<String, dynamic>? existData = existsInCookiesData(e);
        if (existData == null) {
          menuItems[i] = null;
        } else {
          menuItems[i].canView = existData['view'];
          menuItems[i].canEdit = existData['edit'];
          menuItems[i].canDelete = existData['delete'];
        }
      } else if (e is MenuItemGroup) {
        MenuItemGroup mG = MenuItemGroup(
          name: e.name,
          icon: e.icon,
          items: e.items,
        );
        for (int j = 0; j < mG.items.length; j++) {
          MenuItem eG = mG.items[j];
          Map<String, dynamic>? existData = existsInCookiesData(eG);
          if (existData == null) {
            mG.items[j] = MenuItem(name: eG.name, icon: eG.icon, route: '');
          } else {
            mG.items[j].canView = existData['view'];
            mG.items[j].canEdit = existData['edit'];
            mG.items[j].canDelete = existData['delete'];
          }
        }
      }
    }

    for (int i = 0; i < menuItems.length; i++) {
      if (menuItems[i] is MenuItemGroup) {
        (menuItems[i] as MenuItemGroup).items.removeWhere(
          (a) => a.route.isEmpty,
        );
        if ((menuItems[i] as MenuItemGroup).items.isEmpty) {
          menuItems[i] = null;
        }
      }
    }
    menu = menuItems;
  }
}
