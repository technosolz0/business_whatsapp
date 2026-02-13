import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/app/modules/broadcasts/controllers/create_broadcast_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

class AttachmentsCardWidget extends StatelessWidget {
  final CreateBroadcastController controller;

  const AttachmentsCardWidget({super.key, required this.controller});
  static Map<String, List<String>> allowedExtensions = {
    "Image": ["jpg", "jpeg", "png"],
    "Video": ["mp4", "3gp"],
    "Document": ["txt", "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx"],
  };

  String _buildSupportedText(String type) {
    final map = allowedExtensions;

    if (!map.containsKey(type) || map[type]!.isEmpty) {
      return "Add a file to be sent along with your message.";
    }

    final exts = map[type]!.map((e) => e.toUpperCase()).join(", ");
    return "Add a file to be sent along with your message. Supported: $exts. Max: 10MB.";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final fileName = controller.selectedFileName.value;
      final error = controller.selectedFileError.value;
      final isUploading = controller.isUploadingMedia.value;
      final handleId = controller.mediaHandleId.value;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // Title
            // ---------------------------------------------------------
            Text(
              'Attachments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _buildSupportedText(controller.attachmentType.value),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------------------------------------------------
            // Upload Button Area (changes dynamically)
            // ---------------------------------------------------------
            if (isUploading)
              _buildUploadingState()
            else if (handleId.isNotEmpty)
              _buildUploadedState(fileName)
            else
              _buildInitialUploadBox(context, isDark),

            // ---------------------------------------------------------
            // Error message
            // ---------------------------------------------------------
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------
  // UI → Initial State (Tap to Upload)
  // ---------------------------------------------------------
  Widget _buildInitialUploadBox(BuildContext context, bool isDark) {
    return InkWell(
      onTap: controller.pickFile,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A29) : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 48,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
                children: [
                  TextSpan(
                    text: 'Click to upload',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Image / Document',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UI → Uploading State
  // ---------------------------------------------------------
  Widget _buildUploadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircleShimmer(size: 40),
          SizedBox(height: 12),
          Text("Uploading media...", style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // UI → Uploaded Successfully
  // ---------------------------------------------------------
  Widget _buildUploadedState(String fileName) {
    return InkWell(
      onTap: controller.pickFile,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.blue[50], // Light blue background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue[400]!, // Main blue border
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.blue[400], // Blue success check
              size: 28,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                fileName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700], // Darker blue text
                ),
              ),
            ),

            IconButton(
              onPressed: () {
                controller.selectedFileBytes.value = null;
                controller.selectedFileName.value = "";
                controller.mediaHandleId.value = "";
              },
              icon: Icon(
                Icons.close,
                color: Colors.blue[700], // Dark blue close icon
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
