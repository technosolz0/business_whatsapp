import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/common_container.dart';
import 'package:adminpanel/app/common%20widgets/common_filled_button.dart';
import 'package:adminpanel/app/common%20widgets/common_table.dart';
import 'package:adminpanel/app/common%20widgets/common_textfield.dart';
import 'package:adminpanel/app/common%20widgets/common_white_bg_button.dart';
import 'package:adminpanel/app/common%20widgets/common_dropdown_textfield.dart';
import 'package:adminpanel/app/modules/add_roles/controllers/add_roles_controller.dart';
import 'package:adminpanel/app/routes/app_pages.dart';
import '../../../controllers/navigation_controller.dart';

class PhoneAddRoles extends GetView<AddRolesController> {
  const PhoneAddRoles({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.grey[300] : const Color(0xFF656772);

    return Container(
      color: pageBg,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // --------------------- 🔹 Main Content ---------------------
            Obx(
              () => controller.showRoleDetails.value
                  ? CommonContainer(
                      child: SizedBox(
                        height: context.height * 0.4,
                        width: context.width,
                        child: const Center(child: CircleShimmer(size: 40)),
                      ),
                    )
                  : FocusTraversalGroup(
                      child: CommonContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------------- Title ----------------
                            Text(
                              "${controller.isEditing ? 'Edit' : 'Add'} Role Type",
                              style: GoogleFonts.publicSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                                color: titleColor,
                              ),
                            ),

                            const SizedBox(height: 25),

                            // ---------------- Role Name Field ----------------
                            SizedBox(
                              width: 450,
                              child: CommonTextfield(
                                label: "Role Name",
                                isRequired: true,
                                controller: controller.addRoleNameController,
                                hintText: "Enter Here",
                                maxLength: 45,
                                fillColor: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : Colors.grey[100],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ---------------- Select Client Dropdown (Only for Super User) ----------------
                            if (isSuperUser.value)
                              Column(
                                children: [
                                  SizedBox(
                                    width: 450,
                                    child: Obx(() {
                                      if (controller.isLoadingClients.value) {
                                        return const Center(
                                          child: CircleShimmer(size: 30),
                                        );
                                      }
                                      return CommonDropdownTextfield<String>(
                                        label: "Select Client",
                                        isRequired: false,
                                        hintText: "Choose a client (optional)",
                                        initialValue:
                                            controller.selectedClientId.value,
                                        items: controller.clients.map((client) {
                                          return DropdownMenuItem<String>(
                                            value: client.id,
                                            child: Text(client.name),
                                          );
                                        }).toList(),
                                        onChanged: controller.onClientSelected,
                                        fillColor: isDark
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.grey[100],
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),

                            const SizedBox(height: 30),

                            // ---------------- Roles Table ----------------
                            Obx(
                              () => controller.showRoleDetails.value
                                  ? const SizedBox.shrink()
                                  : CustomTable(
                                      showLoading: controller.showRoleDetails,

                                      // 🔥 Dark mode enabled through table widget
                                      showTableContents: false,
                                      columns: const [
                                        'PAGE NAME',
                                        'VIEW',
                                        'EDIT',
                                        'DELETE',
                                      ],
                                      headerIcons: const [
                                        null,
                                        null,
                                        null,
                                        null,
                                      ],
                                      onHeaderIconTap: const [
                                        null,
                                        null,
                                        null,
                                        null,
                                      ],
                                      showPaginationButtons: false,
                                      rows: controller.rolesTable,

                                      childrens: [
                                        // PAGE NAME
                                        (child, i) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            child.toString(),
                                            style: GoogleFonts.publicSans(
                                              fontSize: 16,
                                              color: labelColor,
                                            ),
                                          ),
                                        ),

                                        // VIEW
                                        (child, i) => Theme(
                                          data: Theme.of(context).copyWith(
                                            checkboxTheme: CheckboxThemeData(
                                              checkColor:
                                                  WidgetStateProperty.all(
                                                    Colors.white,
                                                  ),
                                              fillColor:
                                                  WidgetStateProperty.all(
                                                    isDark
                                                        ? Colors.blue
                                                        : AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                          child: Checkbox(
                                            value:
                                                controller.rolesTable[i][1]
                                                    as bool,
                                            onChanged: (v) => controller
                                                .updateRoleAccess(i, 1, v!),
                                          ),
                                        ),

                                        // EDIT
                                        (child, i) => Theme(
                                          data: Theme.of(context).copyWith(
                                            checkboxTheme: CheckboxThemeData(
                                              checkColor:
                                                  WidgetStateProperty.all(
                                                    Colors.white,
                                                  ),
                                              fillColor:
                                                  WidgetStateProperty.all(
                                                    isDark
                                                        ? Colors.blue
                                                        : AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                          child: Checkbox(
                                            value:
                                                controller.rolesTable[i][2]
                                                    as bool,
                                            onChanged: (v) => controller
                                                .updateRoleAccess(i, 2, v!),
                                          ),
                                        ),

                                        // DELETE
                                        (child, i) => Theme(
                                          data: Theme.of(context).copyWith(
                                            checkboxTheme: CheckboxThemeData(
                                              checkColor:
                                                  WidgetStateProperty.all(
                                                    Colors.white,
                                                  ),
                                              fillColor:
                                                  WidgetStateProperty.all(
                                                    isDark
                                                        ? Colors.blue
                                                        : AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                          child: Checkbox(
                                            value:
                                                controller.rolesTable[i][3]
                                                    as bool,
                                            onChanged: (v) => controller
                                                .updateRoleAccess(i, 3, v!),
                                          ),
                                        ),
                                      ],
                                      searchByOptions: const [],
                                      onClickedPrevPage: () {},
                                      onClickedNextPage: () {},
                                      listInfo: "",
                                    ),
                            ),

                            const SizedBox(height: 30),

                            // ---------------- Back Button ----------------
                            SizedBox(
                              height: 40,
                              width: context.width,
                              child: CommonWhiteBgButton(
                                onPressed: () {
                                  Get.offNamed(Routes.ROLES);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    Get.find<NavigationController>()
                                        .updateRoute();
                                  });
                                },
                                borderColor: AppColors.primary,
                                child: Text(
                                  "Back To Search",
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ---------------- Save Button ----------------
                            SizedBox(
                              height: 40,
                              width: context.width,
                              child: Obx(
                                () => CommonFilledButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.addNewRole,
                                  backgroundColor: AppColors.primary,
                                  child: controller.isLoading.value
                                      ? const CircleShimmer(size: 22)
                                      : Text(
                                          "Save",
                                          style: GoogleFonts.publicSans(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
