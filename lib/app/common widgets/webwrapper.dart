// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import 'package:adminpanel/app/common%20widgets/custom_log_out_verify_button.dart';
import 'package:adminpanel/app/common%20widgets/menu.dart';
import 'package:adminpanel/app/common%20widgets/webmenu.dart';
import 'package:adminpanel/app/core/constants/app_assets.dart';
import 'package:adminpanel/app/data/models/menu_item_model.dart';
import 'package:adminpanel/app/utilities/extensions.dart';
import 'package:adminpanel/app/utilities/utilities.dart';
import 'package:adminpanel/main.dart';

class Webwrapper extends GetResponsiveView {
  final Widget Function(MenuItem item) child;

  Webwrapper({super.key, required this.child});

  RxBool loading = true.obs;

  /// returns current viewing MenuItem. If null, means user has not access
  MenuItem? updateAndGetCurrentItem(BuildContext context) {
    MenuItem? i;
    WebMenu.updateAccessibleItemsFromCookies();
    i = WebMenu.getCurrentItem(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loading.value = false;
    });
    return i;
  }

  @override
  Widget phone() {
    return Builder(
      builder: (context) {
        MenuItem? item = updateAndGetCurrentItem(context);
        return Obx(
          () => loading.value
              ? const Center(child: CircleShimmer(size: 40))
              : SelectionArea(
                  child: Scaffold(
                    backgroundColor: const Color(0xFFFAFAFF),
                    drawer: Menu(menuItems: menu),
                    appBar: mainAppBar(item: item, context: context),
                    body: item == null
                        ? const Center(child: Text('Cannot access this page'))
                        : SingleChildScrollView(
                            // controller: globalScrollController,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: child(item),
                            ),
                          ),
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget tablet() {
    return Builder(
      builder: (context) {
        MenuItem? item = updateAndGetCurrentItem(context);
        return Obx(
          () => loading.value
              ? const Center(child: CircleShimmer(size: 40))
              : SelectionArea(
                  child: Scaffold(
                    backgroundColor: const Color(0xFFFAFAFF),
                    drawer: Menu(menuItems: menu),
                    appBar: mainAppBar(item: item, context: context),
                    body: item == null
                        ? const Center(child: Text('Cannot access this page'))
                        : SingleChildScrollView(
                            // controller: globalScrollController,
                            child: Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: child(item),
                            ),
                          ),
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget desktop() {
    return Builder(
      builder: (context) {
        MenuItem? item = updateAndGetCurrentItem(context);
        return Obx(
          () => loading.value
              ? const Center(child: CircleShimmer(size: 40))
              : SelectionArea(
                  child: Scaffold(
                    backgroundColor: const Color(0xFFFAFAFF),
                    body: Row(
                      children: [
                        Menu(menuItems: menu),
                        Expanded(
                          child: item == null
                              ? const Center(
                                  child: Text('Cannot access this page'),
                                )
                              : Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.only(
                                        top: 40,
                                        right: 40,
                                        left: 40,
                                      ),

                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.09,
                                              ),
                                              blurRadius: 10,
                                              offset: Offset(0, 0),
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: mainAppBar(
                                          item: item,
                                          context: context,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        // controller: globalScrollController,
                                        child: Padding(
                                          padding: const EdgeInsets.all(40.0),
                                          child: child(item),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget mainAppBar({
    MenuItem? item,
    required BuildContext context,
  }) {
    bool isDesktop = context.screenType() == ScreenType.Desktop;
    return AppBar(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
      ),

      title: Padding(
        padding: isDesktop ? const EdgeInsets.only(left: 22) : EdgeInsets.zero,
        child: Text(
          "Welcome, Admin!",
          style: GoogleFonts.publicSans(
            fontSize: 20,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      leadingWidth: context.screenType() == ScreenType.Desktop ? 0 : 56,
      leading: Builder(
        builder: (context) => context.screenType() == ScreenType.Desktop
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu),
              ),
      ),
      centerTitle: false,
      toolbarHeight: 70,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Row(
            children: [
              if (Get.context!.screenType() != ScreenType.Phone)
                Obx(
                  () => Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFD9DEFF),
                        child: Text(
                          Utilities.getInitials(adminName.value),
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            color: const Color(0xFF1A2B9B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 4,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (Get.context!.screenType() != ScreenType.Phone)
                const SizedBox(width: 15),
              if (Get.context!.screenType() != ScreenType.Phone)
                Obx(
                  () => Text(
                    adminName.value,
                    style: GoogleFonts.publicSans(
                      fontSize: 18,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
              if (Get.context!.screenType() != ScreenType.Phone)
                const SizedBox(width: 20),
              Tooltip(
                message: "Log Out",
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return CustomLogOutVerifyButton(
                          onTapYes: () {
                            Utilities.logout();
                          },
                        );
                      },
                    );
                  },
                  child: Image.asset(
                    AppAssets.logOutIcon,
                    height: 27,
                    width: 27,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }
}
