import 'dart:convert';

import 'package:adminpanel/app/common%20widgets/common_filled_button.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/app/core/constants/app_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/modules/login/controllers/login_controller.dart';
import 'package:adminpanel/app/common%20widgets/common_textfield.dart';
import 'package:adminpanel/app/utilities/validations.dart';

class PhoneLoginScreen extends StatelessWidget {
  const PhoneLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    double wt = MediaQuery.sizeOf(context).width;
    bool isMobile = wt < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: controller.loginKey,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isMobile ? wt * 0.9 : 400,
            constraints: BoxConstraints(maxWidth: 450),
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 40,
                vertical: isMobile ? 32 : 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.appLogo,
                    height: isMobile ? 80 : 120,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: isMobile ? 24 : 30),
                  Text(
                    "Welcome Admin!",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: isMobile ? 20 : null,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please enter your credentials to continue",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isMobile ? 12 : null,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextfield(
                        label: "Email Address",
                        hintText: "Enter here",
                        maxLength: 100,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          return Validations.emailVerification(value);
                        },
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: isMobile ? 16 : 20),
                      Obx(
                        () => CommonTextfield(
                          label: "Password",
                          hintText: "• • • • • • •",
                          // maxLength: 10,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            return Validations.passVerification(value);
                          },
                          onFieldSubmitted: (value) {
                            if (!controller.showLoading.value) {
                              String plainPassword = controller
                                  .passwordController
                                  .text
                                  .trim();
                              String hashedPassword = sha256
                                  .convert(utf8.encode(plainPassword))
                                  .toString();

                              controller.login(
                                controller.emailController.text.toLowerCase(),
                                hashedPassword,
                              );
                            }
                          },
                          controller: controller.passwordController,
                          obscureText: controller.obscurePassword.value,
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscurePassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Color(0xFF9E9E9E),
                              size: 20,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: GestureDetector(
                      //     onTap: () {},
                      //     child: Text(
                      //       "Forgot Password ?",
                      //       style: GoogleFonts.publicSans(
                      //         fontSize: 13,
                      //         color: AppColors.primary,
                      //         fontWeight: FontWeight.w600,
                      //         decoration: TextDecoration.underline,
                      //         decorationColor: AppColors.primary,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      SizedBox(height: 5),
                      SizedBox(height: isMobile ? 24 : 32),
                      Obx(
                        () => CommonFilledButton(
                          onPressed: controller.showLoading.value
                              ? null
                              : () {
                                  String plainPassword = controller
                                      .passwordController
                                      .text
                                      .trim();
                                  String hashedPassword = sha256
                                      .convert(utf8.encode(plainPassword))
                                      .toString();

                                  controller.login(
                                    controller.emailController.text
                                        .toLowerCase(),
                                    hashedPassword,
                                  );
                                },
                          label: "Login",
                          backgroundColor: AppColors.primary,
                          isLoading: controller.showLoading.value,
                          width: double.infinity,
                          height: 48,
                          borderRadius: 8,
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Obx(
                          () => controller.version.value.isEmpty
                              ? const SizedBox.shrink()
                              : Text(
                                  "Version ${controller.version.value}",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight,
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
    );
  }
}
