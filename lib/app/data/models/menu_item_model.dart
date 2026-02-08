import 'package:flutter/material.dart';

class MenuItem {
  final Widget name;
  final Widget icon;
  final String route;
  final String? addRoute;
  final List<String>? otherRoutes;
  bool canView;
  bool canEdit;
  bool canDelete;
  Widget? selectedIcon;
  Color? selectedTextColor;

  MenuItem({
    required this.name,
    required this.icon,
    required this.route,
    this.addRoute,
    this.selectedIcon,
    this.selectedTextColor,
    this.canView = false,
    this.canEdit = false,
    this.canDelete = false,
    this.otherRoutes,
  });
}

class MenuItemGroup {
  final Widget name;
  final Widget icon;
  List<MenuItem> items;

  MenuItemGroup({
    required this.name,
    required this.icon,
    required this.items,
  });
}
