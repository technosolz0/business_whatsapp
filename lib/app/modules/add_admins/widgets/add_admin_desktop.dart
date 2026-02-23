import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/common%20widgets/common_container.dart';
import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
import 'package:business_whatsapp/app/common%20widgets/common_white_bg_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_dropdown_textfield.dart';
import 'package:business_whatsapp/app/modules/add_admins/controllers/add_admins_controller.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/app/utilities/validations.dart';
import '../../../controllers/navigation_controller.dart';

class AddAdminDesktop extends GetView<AddAdminsController> {
  const AddAdminDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          SizedBox(height: 30),

          Obx(
            () => controller.showAdminDetails.value
                ? CommonContainer(
                    child: SizedBox(
                      height: context.height * 0.4,
                      width: context.width,
                      child: const Center(child: CircleShimmer(size: 40)),
                    ),
                  )
                : CommonContainer(
                    child: Form(
                      key: formKey,
                      child: FocusTraversalGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${controller.isEditing ? 'Edit' : 'Add'} Admin",
                              style: GoogleFonts.publicSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: CommonTextfield(
                                    controller: controller.firstNameController,
                                    label: "First Name",
                                    labelFontSize: 13,
                                    maxLength: 50,
                                    textInputAction: TextInputAction.next,
                                    hintText: "Enter Here",
                                    isRequired: true,
                                    validator: (value) {
                                      return Validations.emptyVerification(
                                        "First Name",
                                        value,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 20),
                                Flexible(
                                  child: CommonTextfield(
                                    controller: controller.lastNameController,
                                    label: "Last Name",
                                    labelFontSize: 13,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 50,
                                    hintText: "Enter Here",
                                    isRequired: true,
                                    validator: (value) {
                                      return Validations.emptyVerification(
                                        "Last Name",
                                        value,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 20),
                                Flexible(
                                  child: CommonTextfield(
                                    label: "Email Address",
                                    textInputAction: TextInputAction.next,
                                    labelFontSize: 13,
                                    maxLength: 100,
                                    controller: controller.emailController,
                                    hintText: "Enter Here",
                                    isRequired: true,
                                    validator: (value) {
                                      return Validations.emailVerification(
                                        value,
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(width: 20),
                                Flexible(
                                  child: Obx(
                                    () => CommonTextfield(
                                      label: "Choose Password",
                                      hintText: "Enter Here",
                                      isRequired: true,

                                      // maxLength: 10,
                                      validator: (value) {
                                        if (controller.adminID.isNotEmpty) {
                                          return null;
                                        }
                                        return Validations.passVerification(
                                          value,
                                        );
                                      },
                                      controller: controller.passwordController,
                                      obscureText:
                                          controller.obscurePassword.value,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.obscurePassword.value
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Color(0xFF9E9E9E),
                                          size: 20,
                                        ),
                                        onPressed:
                                            controller.togglePasswordVisibility,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Client Dropdown (Only for Super User)
                                if (isSuperUser.value)
                                  Flexible(
                                    child: Obx(() {
                                      if (controller.isLoadingClients.value) {
                                        return const Center(
                                          child: CircleShimmer(size: 30),
                                        );
                                      }
                                      return CommonDropdownTextfield<String>(
                                        label: "Select Client",
                                        isRequired: true,
                                        hintText: "Choose a client",
                                        initialValue:
                                            controller.selectedClientId.value,
                                        items: controller.clients.map((client) {
                                          return DropdownMenuItem<String>(
                                            value: client.id,
                                            child: Text(client.name),
                                          );
                                        }).toList(),
                                        onChanged: controller.onClientSelected,
                                      );
                                    }),
                                  ),
                                if (isSuperUser.value) SizedBox(width: 20),

                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Role",
                                            style: GoogleFonts.publicSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? const Color(0xFFD1D5DB)
                                                  : const Color(0xFF242424),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Text(
                                            "*",
                                            style: TextStyle(
                                              color: Color(0xFFE74C3C),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Obx(
                                        () => SizedBox(
                                          height: 48,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1F2937)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF242424)
                                                    : const Color(0xFFD1D5DB),
                                              ),
                                            ),
                                            child: DropdownButtonFormField<String>(
                                              initialValue:
                                                  controller
                                                      .selectedRole
                                                      .value
                                                      .isEmpty
                                                  ? null
                                                  : controller
                                                        .selectedRole
                                                        .value,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                border: InputBorder.none,
                                              ),
                                              dropdownColor: isDark
                                                  ? const Color(0xFF1F2937)
                                                  : Colors.white,
                                              hint: Text(
                                                'Select Role',
                                                style: GoogleFonts.publicSans(
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? const Color(0xFF9CA3AF)
                                                      : const Color(0xFF9CA3AF),
                                                ),
                                              ),
                                              items: controller.allRoles
                                                  .map(
                                                    (e) => DropdownMenuItem(
                                                      value: e.roleName ?? '',
                                                      child: Text(
                                                        e.roleName ?? '',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                // Check if client is selected first
                                                if (!controller
                                                    .validateClientSelection()) {
                                                  return;
                                                }
                                                if (val != null) {
                                                  controller
                                                          .selectedRole
                                                          .value =
                                                      val;
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Super User Checkbox (Only for Super User)
                                if (isSuperUser.value)
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Super User",
                                          style: GoogleFonts.publicSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFFD1D5DB)
                                                : const Color(0xFF242424),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Obx(
                                          () => CheckboxListTile(
                                            value: controller
                                                .isSuperUserChecked
                                                .value,
                                            onChanged:
                                                controller.toggleSuperUser,
                                            title: Text(
                                              "Grant super user privileges",
                                              style: GoogleFonts.publicSans(
                                                fontSize: 14,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                controller.isAllChats.value == false
                                    ? Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 35.0,
                                            left: 16.0,
                                          ),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              controller.assignContacts();
                                            },
                                            child: Text("View Contacts"),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                            // SizedBox(height: 20),

                            // // Client Dropdown and Super User Checkbox Row
                            // Row(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     // Client Dropdown

                            //   ],
                            // ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                SizedBox(
                                  height: 40,
                                  width: 160,
                                  child: CommonWhiteBgButton(
                                    onPressed: () {
                                      Get.offNamed(Routes.ADMINS);
                                      controller.clearForm();
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            Get.find<NavigationController>()
                                                .updateRoute();
                                          });
                                    },
                                    borderColor: AppColors.primary,
                                    child: Text(
                                      "Back To Search",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                SizedBox(
                                  height: 40,
                                  width: 130,
                                  child: CommonFilledButton(
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        controller.isLoading.value
                                            ? null
                                            : controller.addNewAdmin();
                                      }
                                    },
                                    backgroundColor: AppColors.primary,
                                    child: Obx(
                                      () => controller.isLoading.value
                                          ? const Padding(
                                              padding: EdgeInsets.zero,
                                              child: CircleShimmer(size: 20),
                                            )
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
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
