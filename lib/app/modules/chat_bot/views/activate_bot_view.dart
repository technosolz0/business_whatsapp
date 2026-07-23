import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
import 'package:business_whatsapp/app/common%20widgets/dotted_border.dart';
import 'package:business_whatsapp/app/common%20widgets/standard_page_layout.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/modules/chat_bot/controllers/activate_bot_controller.dart';

class ActivateBotView extends GetView<ActivateBotController> {
  const ActivateBotView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StandardPageLayout(
      title: "Activate Bot",
      showBackButton: true,
      isContentScrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProTip(isDark),
          const SizedBox(height: 32),
          _buildUploadSection(context, isDark),
          const SizedBox(height: 48),
          _buildUploadHistory(isDark),
        ],
      ),
    );
  }

  Widget _buildProTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDark.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: isDark ? AppColors.primaryDark : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pro Tip",
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    children: [
                      const TextSpan(text: "Upload files like your "),
                      TextSpan(
                        text: "Service Catalog, Pricing Sheets,",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: " or "),
                      TextSpan(
                        text: "FAQ documents",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            ". Supported formats: PDF, TXT, XCL. This helps your bot answer customer queries accurately.",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            "Upload New Files",
            style: GoogleFonts.publicSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: controller.pickFiles,
            child: DottedBorderWrapper(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Click to upload or drag and drop",
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "PDF, TXT, or Excel files (max. 10MB)",
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Uploaded File",
            style: GoogleFonts.publicSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Column(
              children: List.generate(
                controller.selectedFiles.length,
                (index) => _buildFileItem(index, isDark),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CommonTextfield(
            label: "Short Description",
            isRequired: true,
            hintText: "e.g., Updated pricing list for enterprise clients",
            controller: controller.descriptionController,
          ),
          const SizedBox(height: 32),
          Obx(
            () => CommonFilledButton(
              onPressed: controller.submit,
              isLoading: controller.isLoading.value,
              label: "Submit",
              width: 120,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(int index, bool isDark) {
    final file = controller.selectedFiles[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.5)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file.extension ?? ''),
            size: 20,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              file.name,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => controller.removeFile(index),
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadHistory(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upload History",
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(
              width: 250,
              child: CommonTextfield(
                hintText: "Search files...",
                prefixIcon: const Icon(Icons.search, size: 20),
                controller: controller.historySearchController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              _buildTableHeader(isDark),
              Obx(
                () => controller.isLoading.value && controller.uploadHistory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: List.generate(
                          controller.uploadHistory.length,
                          (index) => _buildTableRow(index, isDark),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.3)
            : AppColors.backgroundLight.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderText("FILE NAME", isDark)),
          Expanded(flex: 3, child: _buildHeaderText("DESCRIPTION", isDark)),
          Expanded(flex: 2, child: _buildHeaderText("DATE UPLOADED", isDark)),
          Expanded(flex: 1, child: _buildHeaderText("ACTIONS", isDark)),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.publicSans(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }

  Widget _buildTableRow(int index, bool isDark) {
    final item = controller.uploadHistory[index];
    final showBorder = index < controller.uploadHistory.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  _getFileIcon(item.fileName.split('.').last),
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.fileName,
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.description ?? '',
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.dateUploaded,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Obx(
                  () => IconButton(
                    icon: controller.isDeleting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        : const Icon(Icons.delete_outline,
                            size: 20, color: Colors.redAccent),
                    onPressed: controller.isDeleting.value
                        ? null
                        : () => controller.deleteHistoryItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xls':
      case 'xlsx':
      case 'excel':
        return Icons.table_chart_outlined;
      case 'txt':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}