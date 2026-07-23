import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
import 'package:business_whatsapp/app/common%20widgets/standard_page_layout.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/modules/chat_bot/controllers/train_bot_controller.dart';
import 'package:business_whatsapp/app/common%20widgets/dotted_border.dart';
import 'package:business_whatsapp/app/modules/chat_bot/models/service_block.dart';
import 'package:business_whatsapp/app/modules/chat_bot/models/faq_block.dart';
import 'package:shimmer/shimmer.dart';

class TrainBotView extends GetView<TrainBotController> {
  const TrainBotView({super.key});

  TextStyle get _textfieldLabelStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = MediaQuery.of(context).size.width > 900;

    return StandardPageLayout(
      title: "Train Your Bot",
      showBackButton: true,
      isContentScrollable: true,
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmerLoading(context, isDark, isWeb);
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 24.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoreIdentityCard(context, isDark, isWeb),
              const SizedBox(height: 12),
              _buildLeadQualificationCard(context, isDark, isWeb),
              const SizedBox(height: 12),
              _buildProductsServicesCard(context, isDark, isWeb),
              const SizedBox(height: 12),
              _buildPoliciesCard(context, isDark, isWeb),
              const SizedBox(height: 12),
              _buildFaqCard(context, isDark, isWeb),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  CommonFilledButton(
                    isLoading: controller.isSaving.value,
                    onPressed: controller.saveBotSettings,
                    label: "Save Training",
                    width: 200,
                  ),
                  // CommonFilledButton(
                  //   onPressed: controller.downloadProfileMarkdown,
                  //   label: "Download Profile (.md)",
                  //   width: 220,
                  //   backgroundColor: isDark
                  //       ? const Color(0xFF334155)
                  //       : const Color(0xFF64748B),
                  // ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, bool isDark, bool isWeb) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24.0 : 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required BuildContext context,
    required String index,
    required String title,
    required String subtitle,
    required RxBool isExpanded,
    required Widget child,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded.value
                ? (isDark ? Colors.white38 : const Color(0xFF6D7A77))
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isExpanded.value ? 0.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            InkWell(
              onTap: () {
                if (isExpanded.value) {
                  isExpanded.value = false;
                } else {
                  controller.isIdentityExpanded.value = false;
                  controller.isLeadExpanded.value = false;
                  controller.isProductsExpanded.value = false;
                  controller.isPoliciesExpanded.value = false;
                  controller.isFaqExpanded.value = false;
                  isExpanded.value = true;
                }
              },
              borderRadius: isExpanded.value
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isExpanded.value
                            ? AppColors.primary
                            : const Color(0x26137FEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        style: GoogleFonts.inter(
                          color: isExpanded.value
                              ? Colors.white
                              : const Color(0xFF137FEC),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                        child: Text(index),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              height: 24 / 18,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textSecondary,
                              height: 24 / 16,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Animated Body Form Fields
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded.value
                  ? Padding(padding: const EdgeInsets.all(24), child: child)
                  : const SizedBox(height: 0, width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreIdentityCard(BuildContext context, bool isDark, bool isWeb) {
    return _buildCollapsibleCard(
      context: context,
      index: "01",
      title: "Core Company Identity",
      subtitle: "The foundation of your bot's knowledge base.",
      isExpanded: controller.isIdentityExpanded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Business Name & Primary Location
          if (isWeb)
            Row(
              children: [
                Expanded(
                  child: CommonTextfield(
                    controller: controller.businessNameController,
                    label: "Business Name",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "e.g. Acme Corp Solutions",
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CommonTextfield(
                    controller: controller.primaryLocationTopController,
                    label: "Primary Location",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "123 Business Way, Silicon Valley",
                  ),
                ),
              ],
            )
          else ...[
            CommonTextfield(
              controller: controller.businessNameController,
              label: "Business Name",
              labelStyle: _textfieldLabelStyle,
              hintText: "e.g. Acme Corp Solutions",
            ),
            const SizedBox(height: 20),
            CommonTextfield(
              controller: controller.primaryLocationTopController,
              label: "Primary Location",
              labelStyle: _textfieldLabelStyle,
              hintText: "123 Business Way, Silicon Valley",
            ),
          ],
          const SizedBox(height: 20),

          // Row 2: Short Elevator Pitch
          CommonTextfield(
            controller: controller.elevatorPitchController,
            label: "Short Elevator Pitch",
            labelStyle: _textfieldLabelStyle,
            hintText: "Describe what your business does in 2 sentences.",
            maxLines: 3,
            maxLength: 200,
            onChanged: (val) {
              controller.elevatorPitchCharCount.value = val.length;
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(
              () => Text(
                "${controller.elevatorPitchCharCount.value} / 200",
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Row 3: Primary Location (Address)
          CommonTextfield(
            controller: controller.primaryLocationAddressController,
            label: "Primary location",
            labelStyle: _textfieldLabelStyle,
            hintText: "Enter Address Here",
          ),
          const SizedBox(height: 20),

          // Row 4: Phone Number, Email, Operating Hours
          if (isWeb)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CommonTextfield(
                    controller: controller.phoneNumberController,
                    label: "Phone Number",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "Phone, Email for escalations",
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CommonTextfield(
                    controller: controller.emailController,
                    label: "Email",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "Phone, Email for escalations",
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildOperatingHoursTile(
                    context,
                    isDark,
                    isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            )
          else ...[
            CommonTextfield(
              controller: controller.phoneNumberController,
              label: "Phone Number",
              labelStyle: _textfieldLabelStyle,
              hintText: "Phone, Email for escalations",
            ),
            const SizedBox(height: 20),
            CommonTextfield(
              controller: controller.emailController,
              label: "Email",
              labelStyle: _textfieldLabelStyle,
              hintText: "Phone, Email for escalations",
            ),
            const SizedBox(height: 20),
            _buildOperatingHoursTile(
              context,
              isDark,
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeadQualificationCard(
    BuildContext context,
    bool isDark,
    bool isWeb,
  ) {
    return _buildCollapsibleCard(
      context: context,
      index: "02",
      title: "Lead Qualification",
      subtitle: "Define how the bot identifies and routes \"Hot Leads\".",
      isExpanded: controller.isLeadExpanded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Dropdown
          _buildDropdownField(
            context: context,
            label: "What is the primary goal of this WhatsApp bot?",
            value: controller.botGoal.value,
            items: const [
              "Book a consultation",
              "Request a quote",
              "Schedule a site visit",
              "Support routing",
              "Other",
            ],
            onChanged: (val) {
              if (val != null) {
                controller.botGoal.value = val;
              }
            },
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Questions text area
          CommonTextfield(
            controller: controller.buySignalsController,
            label:
                "What specific questions indicate a customer is ready to buy?",
            labelStyle: _textfieldLabelStyle,
            hintText:
                "e.g., Asking for a demo, asking about payment methods, asking for availability next week.",
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isDark = false,
  }) {
    final effectiveLabelColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final effectiveTextColor = isDark ? Colors.white : Colors.black;
    final effectiveFillColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final effectiveBorderColor = isDark
        ? Colors.grey[700]!
        : const Color(0xFFE0E0E0);
    final effectiveFocusedBorderColor = isDark
        ? Colors.blueAccent
        : AppColors.primary;

    OutlineInputBorder buildBorder(Color color) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: effectiveLabelColor,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          style: GoogleFonts.publicSans(
            color: effectiveTextColor,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: effectiveFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: buildBorder(effectiveBorderColor),
            focusedBorder: buildBorder(effectiveFocusedBorderColor),
          ),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: GoogleFonts.publicSans(
                  color: effectiveTextColor,
                  fontSize: 15,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildOperatingHoursTile(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final containerBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : const Color(0xFFE0E0E0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Operating Hours",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: textPrimary,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.showScheduleDialog(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: containerBg,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.operatingHours.value,
                      style: GoogleFonts.publicSans(
                        color:
                            controller.operatingHours.value ==
                                'Edit Your 7-Day Schedule'
                            ? (isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFFBDC3C7))
                            : textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsServicesCard(
    BuildContext context,
    bool isDark,
    bool isWeb,
  ) {
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return _buildCollapsibleCard(
      context: context,
      index: "03",
      title: "Products, Services & Pricing",
      subtitle: "List offerings or upload your catalog for bot reference.",
      isExpanded: controller.isProductsExpanded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Service Descriptions
          Text(
            "Service Descriptions",
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic List of Blocks
          Obx(
            () => Column(
              children: [
                for (int i = 0; i < controller.servicesList.length; i++) ...[
                  _buildServiceRow(
                    context,
                    controller.servicesList[i],
                    i,
                    isWeb,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // "+ Add Service Block" Button
          InkWell(
            onTap: controller.addServiceBlock,
            borderRadius: BorderRadius.circular(12),
            child: DottedBorderWrapper(
              color: const Color(0xFF287DE8),
              borderRadius: 12,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Color(0xFF287DE8), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Add Service Block",
                      style: GoogleFonts.publicSans(
                        color: const Color(0xFF287DE8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section B: Pricing Catalog (CSV Upload)
          Text(
            "Pricing Catalog (CSV Upload)",
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // CSV Upload Area
          Obx(() {
            if (controller.isUploadingCatalog.value) {
              return Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
                  ),
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (controller.uploadedCatalog.isNotEmpty) {
              final fileName =
                  controller.uploadedCatalog['name']?.toString() ??
                  'catalog.csv';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ready to use for bot training",
                            style: GoogleFonts.publicSans(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: controller.deleteCatalog,
                    ),
                  ],
                ),
              );
            }

            // Default Upload Box
            return InkWell(
              onTap: controller.pickAndUploadCatalog,
              borderRadius: BorderRadius.circular(12),
              child: DottedBorderWrapper(
                borderRadius: 12,
                color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1),
                backgroundColor: isDark
                    ? const Color(0xFF1A2333)
                    : const Color(0xFFF3F6FA),
                child: Container(
                  height: 120,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF94A3B8),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            color: textPrimary,
                          ),
                          children: [
                            const TextSpan(
                              text: "Drop your pricing sheet here or ",
                            ),
                            TextSpan(
                              text: "browse files",
                              style: GoogleFonts.publicSans(
                                color: const Color(0xFF287DE8),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Support for CSV files only. Ensure columns: Name, Description, Price, Availability.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceRow(
    BuildContext context,
    ServiceBlock block,
    int index,
    bool isWeb,
    bool isDark,
  ) {
    if (isWeb) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: CommonTextfield(
              controller: block.nameController,
              hintText: "Service Name",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: CommonTextfield(
              controller: block.priceController,
              hintText: "Price Range",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: CommonTextfield(
              controller: block.descController,
              hintText: "Brief Description",
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => controller.removeServiceBlock(index),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Service #${index + 1}",
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () => controller.removeServiceBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CommonTextfield(
            controller: block.nameController,
            hintText: "Service Name",
          ),
          const SizedBox(height: 12),
          CommonTextfield(
            controller: block.priceController,
            hintText: "Price Range",
          ),
          const SizedBox(height: 12),
          CommonTextfield(
            controller: block.descController,
            hintText: "Brief Description",
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesCard(BuildContext context, bool isDark, bool isWeb) {
    return _buildCollapsibleCard(
      context: context,
      index: "04",
      title: "Policies & Operations",
      subtitle: "Define rules for shipping, returns, and payments.",
      isExpanded: controller.isPoliciesExpanded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWeb) ...[
            // Web Layout: 2 Columns side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CommonTextfield(
                    controller: controller.shippingPolicyController,
                    label: "Shipping/Delivery Policy",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "Explain timelines and areas covered...",
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: CommonTextfield(
                    controller: controller.returnPolicyController,
                    label: "Return/Refund Policy",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "Crucial for handling disputes...",
                    maxLines: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CommonTextfield(
                    controller: controller.guaranteesController,
                    label: "Guarantees/Warranties",
                    labelStyle: _textfieldLabelStyle,
                    hintText: "What promises do you offer?",
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Methods Accepted",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          height: 24 / 16,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheckbox("Credit Card", isDark),
                                const SizedBox(height: 4),
                                _buildCheckbox("Bank Transfer", isDark),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheckbox("UPI", isDark),
                                const SizedBox(height: 4),
                                _buildCheckbox("Cash on Delivery", isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mobile Layout: Stacks vertically
            CommonTextfield(
              controller: controller.shippingPolicyController,
              label: "Shipping/Delivery Policy",
              labelStyle: _textfieldLabelStyle,
              hintText: "Explain timelines and areas covered...",
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            CommonTextfield(
              controller: controller.returnPolicyController,
              label: "Return/Refund Policy",
              labelStyle: _textfieldLabelStyle,
              hintText: "Crucial for handling disputes...",
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            CommonTextfield(
              controller: controller.guaranteesController,
              label: "Guarantees/Warranties",
              labelStyle: _textfieldLabelStyle,
              hintText: "What promises do you offer?",
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(
              "Payment Methods Accepted",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                height: 24 / 16,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            _buildCheckbox("Credit Card", isDark),
            _buildCheckbox("Bank Transfer", isDark),
            _buildCheckbox("UPI", isDark),
            _buildCheckbox("Cash on Delivery", isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool isDark) {
    return Obx(() {
      final isChecked = controller.selectedPaymentMethods.contains(label);
      final textPrimary = isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight;

      return InkWell(
        onTap: () => controller.togglePaymentMethod(label),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isChecked
                      ? const Color(0xFF287DE8)
                      : Colors.transparent,
                  border: Border.all(
                    color: isChecked
                        ? const Color(0xFF287DE8)
                        : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFaqCard(BuildContext context, bool isDark, bool isWeb) {
    return _buildCollapsibleCard(
      context: context,
      index: "05",
      title: "The \"Day 1\" FAQ",
      subtitle: "Top questions your team hears daily.",
      isExpanded: controller.isFaqExpanded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.faqList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final block = controller.faqList[index];
                return _buildFAQRow(context, block, index, isDark, isWeb);
              },
            ),
          ),
          const SizedBox(height: 24),
          // "+ Add FAQs" Button
          InkWell(
            onTap: controller.addFAQBlock,
            borderRadius: BorderRadius.circular(12),
            child: DottedBorderWrapper(
              color: AppColors.primary,
              borderRadius: 12,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Add FAQs",
                      style: GoogleFonts.publicSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQRow(
    BuildContext context,
    FAQBlock block,
    int index,
    bool isDark,
    bool isWeb,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label header: QUESTION 1
        Text(
          "QUESTION ${index + 1}",
          style: GoogleFonts.publicSans(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        if (isWeb) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CommonTextfield(
                  controller: block.questionController,
                  hintText: "Question",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CommonTextfield(
                  controller: block.answerController,
                  hintText: "Answer",
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => controller.removeFAQBlock(index),
                ),
              ),
            ],
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextfield(
                controller: block.questionController,
                hintText: "Question",
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CommonTextfield(
                      controller: block.answerController,
                      hintText: "Answer",
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.removeFAQBlock(index),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
