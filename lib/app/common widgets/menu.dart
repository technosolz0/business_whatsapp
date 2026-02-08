import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/data/models/menu_item_model.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/utilities/webutils.dart';

// Made For the UI of Menu

class Menu extends StatelessWidget {
  final List<dynamic> menuItems;
  const Menu({super.key, required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const LinearBorder(),
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 11, left: 19, right: 19),
              child: InkWell(
                onTap: () {
                  Get.offNamed(Routes.HOME);
                },
                child: Row(
                  children: [
                    Image.asset(
                      "assets/app_logo_menu.png",
                      height: 50,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              itemBuilder: (context, i) {
                var menu = menuItems[i];
                if (menu is MenuItem) {
                  return MenuItemTile(item: menu);
                } else if (menu is MenuItemGroup) {
                  return MenuItemGroupTile(
                    title: menu.name,
                    icon: menu.icon,
                    items: menu.items,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Made when we have only one item in menuItem

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  const MenuItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    String currentRoute = WebUtils.getCurrentRoute(context);
    bool isSelected =
        currentRoute == item.route ||
        currentRoute == item.addRoute ||
        (item.otherRoutes != null && item.otherRoutes!.contains(currentRoute));

    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 7),
      child: ListTile(
        title: DefaultTextStyle.merge(
          style: GoogleFonts.publicSans(
            color: isSelected
                ? item.selectedTextColor ?? const Color(0xFFFFFFFF)
                : const Color(0xFF000000),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
          child: item.name,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
        selectedTileColor: AppColors.primary,
        selected: isSelected,
        onTap: () {
          Get.offNamed(item.route, preventDuplicates: true);
        },
      ),
    );
  }
}

// Made when we have two or more item in menuItems

class MenuItemGroupTile extends StatelessWidget {
  final Widget title;
  final Widget icon;
  final List<MenuItem> items;

  const MenuItemGroupTile({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    String route = WebUtils.getCurrentRoute(context);

    bool isExpanded = items.any(
      (e) =>
          e.route == route ||
          e.addRoute == route ||
          (e.otherRoutes != null && e.otherRoutes!.contains(route)),
    );

    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 7),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        collapsedIconColor: const Color(0xFF030320),
        iconColor: const Color(0xFF030320),
        title: title,
        leading: icon,
        children: items
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(left: 30),
                child: MenuItemTile(item: value),
              ),
            )
            .toList(),
      ),
    );
  }
}
