import 'dart:convert';

import 'package:adminpanel/app/common widgets/common_filled_button.dart';
import 'package:adminpanel/app/common widgets/common_icon_button.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/app/core/constants/app_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/modules/login/controllers/login_controller.dart';
import 'package:adminpanel/app/common widgets/common_textfield.dart';
import 'package:adminpanel/app/utilities/validations.dart';

class DesktopLoginScreen extends StatelessWidget {
  const DesktopLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    double ht = MediaQuery.sizeOf(context).height;
    double wt = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: controller.loginKey,
      child: SizedBox(
        height: ht,
        child: Stack(
          children: [
            // Top left decorative border box
            Positioned(
              top: ht * 0.0405,
              left: wt * 0.33,
              child: Container(
                height: ht * 0.22,
                width: wt * 0.1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Top left decorative filled box
            Positioned(
              top: ht * 0.076,
              left: wt * 0.31,
              child: Container(
                height: ht * 0.21,
                width: wt * 0.1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Bottom right decorative border box
            Positioned(
              bottom: ht * 0.18,
              right: wt * 0.3,
              child: Container(
                height: ht * 0.2,
                width: wt * 0.1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Bottom right decorative filled box
            Positioned(
              bottom: ht * 0.13,
              right: wt * 0.32,
              child: Container(
                height: ht * 0.21,
                width: wt * 0.1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark
                      ? AppColors.sectionDark
                      : AppColors.sectionLight,
                ),
              ),
            ),
            // Main login card
            Center(
              child: Container(
                height: ht * 0.75,
                width: wt * 0.27,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: isDark ? 20 : 24,
                      offset: const Offset(0, 8),
                      spreadRadius: isDark ? 0 : -4,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Logo
                      Image.asset(
                        AppAssets.appLogo,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),

                      // Welcome Title
                      Text(
                        "Welcome Admin!",
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        "Please enter your credentials to continue",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Form Fields
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field
                          CommonTextfield(
                            label: "Email Address",
                            hintText: "Enter your email",
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            maxLength: 100,
                            validator: (value) {
                              return Validations.emailVerification(value);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Obx(
                            () => CommonTextfield(
                              label: "Password",
                              hintText: "Enter your password",
                              controller: controller.passwordController,
                              obscureText: controller.obscurePassword.value,
                              textInputAction: TextInputAction.done,
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
                                    controller.emailController.text
                                        .toLowerCase(),
                                    hashedPassword,
                                  );
                                }
                              },
                              validator: (value) {
                                return Validations.passVerification(value);
                              },
                              suffixIcon: CommonIconButton(
                                onPressed: controller.togglePasswordVisibility,
                                icon: controller.obscurePassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                                iconSize: 20,
                                tooltip: controller.obscurePassword.value
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login Button
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
                              label: "Sign In",
                              backgroundColor: AppColors.primary,
                              isLoading: controller.showLoading.value,
                              width: double.infinity,
                              height: 48,
                              borderRadius: 8,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Version Text
                          Center(
                            child: Obx(
                              () => controller.version.value.isEmpty
                                  ? const SizedBox.shrink()
                                  : Text(
                                      "Version ${controller.version.value}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
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
          ],
        ),
      ),
    );
  }
}
