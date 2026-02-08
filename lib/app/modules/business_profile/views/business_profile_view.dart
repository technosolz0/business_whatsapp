import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Utilities/subscription_guard.dart';
import '../../../Utilities/validations.dart';
import '../controllers/business_profile_controller.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';

class BusinessProfileView extends GetView<BusinessProfileController> {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = MediaQuery.of(context).size.width > 900;

    final backgroundColor = isDark
        ? AppColors.waChatBgDark
        : AppColors.waChatBgLight;
    final headerColor = isDark
        ? AppColors.waHeaderDark
        : AppColors.waHeaderLight;
    final textPrimary = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;
    final textSecondary = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Get.offNamed(Routes.SETTINGS),
        ),
        title: Text(
          'Business Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 32.0 : 16.0),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const BusinessProfileShimmer();
            }

            final leftColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Obx(() {
                            if (controller.profilePictureUrl.isNotEmpty) {
                              return Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.waDividerDark
                                        : AppColors.waDividerLight,
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      controller.profilePictureUrl.value,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? AppColors.waHeaderDark
                                      : AppColors.waHeaderLight,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.waDividerDark
                                        : AppColors.waDividerLight,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.business_rounded,
                                    size: 70,
                                    color: textSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            }
                          }),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: InkWell(
                              onTap: SubscriptionGuard.canEdit()
                                  ? controller.changePhoto
                                  : null,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SubscriptionGuard.canEdit()
                                      ? AppColors.primary
                                      : Colors.grey,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.waChatBgDark
                                        : Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: SubscriptionGuard.canEdit()
                            ? controller.changePhoto
                            : null,
                        child: Text(
                          'Change Photo',
                          style: TextStyle(
                            color: SubscriptionGuard.canEdit()
                                ? AppColors.primary
                                : textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                _buildLabel('About', isDark),
                _buildInputContainer(
                  isDark: isDark,
                  child: TextFormField(
                    controller: controller.aboutController,
                    maxLines: 2,
                    maxLength: 139,
                    validator: Validations.aboutVerification,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: _getInputDecoration(
                      hint: 'Short tagline or status',
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('Vertical', isDark),
                _buildDropdown(isDark),
                const SizedBox(height: 32),

                _buildLabel('Description', isDark),
                _buildInputContainer(
                  isDark: isDark,
                  child: TextFormField(
                    controller: controller.descriptionController,
                    maxLines: 6,
                    maxLength: 512,
                    validator: Validations.descriptionVerification,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: _getInputDecoration(
                      hint: 'Tell us more about your business...',
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            );

            final rightColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Email Address', isDark),
                _buildInputContainer(
                  isDark: isDark,
                  child: TextFormField(
                    controller: controller.emailController,
                    maxLength: 128,
                    validator: Validations.emailVerificationMeta,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: _getInputDecoration(
                      hint: 'business@example.com',
                      isDark: isDark,
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('Address', isDark),
                _buildInputContainer(
                  isDark: isDark,
                  child: TextFormField(
                    controller: controller.addressController,
                    maxLength: 256,
                    maxLines: 4,
                    validator: Validations.addressVerificationMeta,
                    style: TextStyle(color: textPrimary, fontSize: 15),
                    decoration: _getInputDecoration(
                      hint: 'Street address, city, state, postal code',
                      isDark: isDark,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('Websites', isDark),
                Obx(
                  () => Column(
                    children: [
                      ...controller.websiteControllers.asMap().entries.map((
                        entry,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildInputContainer(
                            isDark: isDark,
                            child: TextFormField(
                              controller: entry.value,
                              validator: Validations.websiteVerification,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                              ),
                              decoration: _getInputDecoration(
                                hint: 'https://example.com',
                                isDark: isDark,
                                prefixIcon: Icons.language,
                                suffixIcon: Icons.close_rounded,
                                onSuffixTap: () =>
                                    controller.removeWebsite(entry.key),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Obx(
                  () =>
                      (controller.websiteControllers.length < 2 &&
                          SubscriptionGuard.canEdit())
                      ? TextButton.icon(
                          onPressed: controller.addWebsite,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add another website'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.all(12),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (controller.isSaving.value ||
                            !SubscriptionGuard.canEdit())
                        ? null
                        : controller.saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (controller.isSaving.value ||
                              !SubscriptionGuard.canEdit())
                          ? Colors.grey
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isSaving.value
                        ? const CircleShimmer(size: 20)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            );

            if (isWeb) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: leftColumn),
                  const SizedBox(width: 60),
                  Expanded(flex: 1, child: rightColumn),
                ],
              );
            } else {
              return Column(
                children: [leftColumn, const SizedBox(height: 32), rightColumn],
              );
            }
          }),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.waTextSecondaryDark
              : AppColors.waTextSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.waHeaderDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.waDividerDark : AppColors.waDividerLight,
        ),
      ),
      child: child,
    );
  }

  InputDecoration _getInputDecoration({
    required String hint,
    required bool isDark,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    final textSecondary = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: textSecondary.withValues(alpha: 0.5),
        fontSize: 15,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: textSecondary.withValues(alpha: 0.7),
              size: 20,
            )
          : null,
      suffixIcon: suffixIcon != null
          ? IconButton(
              icon: Icon(
                suffixIcon,
                color: textSecondary.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: onSuffixTap,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: InputBorder.none,
      counterText: "",
    );
  }

  Widget _buildDropdown(bool isDark) {
    final textPrimary = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;
    final textSecondary = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    return Obx(
      () => _buildInputContainer(
        isDark: isDark,
        child: DropdownButtonFormField<String>(
          initialValue: controller.selectedIndustry.value,
          dropdownColor: isDark ? AppColors.waHeaderDark : Colors.white,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
          items: controller.industries.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          validator: Validations.verticalVerification,
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.selectedIndustry.value = newValue;
            }
          },
        ),
      ),
    );
  }
}
