import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';
import '../controllers/create_template_controller.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';

class DragDropUploadBox extends StatelessWidget {
  DragDropUploadBox({super.key});

  final CreateTemplateController controller =
      Get.find<CreateTemplateController>();
  final ThemeController themeController = Get.find<ThemeController>();

  static const Map<String, List<String>> allowedExtensions = {
    "Image": ["jpg", "jpeg", "png"],
    "Video": ["mp4", "3gp"],
    "Document": ["txt", "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx"],
  };

  String _buildSupportedText(String type) {
    // If type is empty/null, default to something generic or empty string
    if (type.isEmpty) return "Add a file to be sent along with your message.";

    final map = allowedExtensions;

    if (!map.containsKey(type) || map[type]!.isEmpty) {
      return "Add a file to be sent along with your message.";
    }

    final exts = map[type]!.map((e) => e.toUpperCase()).join(", ");
    return "Add a file to be sent along with your message. Supported: $exts. Max: 10MB.";
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final isError = controller.selectedFileError.value.isNotEmpty;
      final fileName = controller.selectedFileName.value;
      final isUpload = controller.isUploadingMedia.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPLOAD BOX
          if (fileName.isEmpty || isUpload)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: controller.pickFile,
                child: DragTarget<Uint8List>(
                  onAcceptWithDetails: (details) {
                    controller.handleDroppedFile(
                      details.data,
                      "dropped_file", // fallback, extension is extracted inside controller
                    );
                  },
                  builder: (context, _, __) {
                    return CustomPaint(
                      painter: DashedBorderPainter(
                        color: isError
                            ? Colors.red
                            : (isDark
                                  ? Colors.grey.withValues(alpha: 0.5)
                                  : Colors.grey.withValues(alpha: 0.4)),
                      ),
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.grey.withValues(alpha: 0.05),
                        ),
                        child: isUpload
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircleShimmer(size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Media is Uploading. Please wait for a while",
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: controller.pickFile,
                                    child: Text(
                                      "Choose files on your device",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[400],
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _buildSupportedText(
                                      controller.selectedMediaType.value,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),

          // FILE NAME + REMOVE BUTTON (IF SELECTED)
          if (fileName.isNotEmpty && !isUpload)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: controller.pickFile,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF3F4F6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _fileIcon(controller.selectedMediaType.value),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFFE5E7EB)
                                      : const Color(0xFF1F2937),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          controller.selectedFileBytes.value = null;
                          controller.selectedFileName.value = "";
                          controller.selectedFileError.value = "";
                          controller.mediaHandleId.value = "";
                        },
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                        tooltip: "Remove file",
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ERROR TEXT
          if (isError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                controller.selectedFileError.value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _fileIcon(String type) {
    switch (type) {
      case "Image":
        return const Icon(Icons.image, color: Colors.green, size: 20);
      case "Video":
        return const Icon(Icons.videocam, color: Colors.orange, size: 20);
      case "Document":
        return const Icon(
          Icons.insert_drive_file,
          color: Colors.blue,
          size: 20,
        );
      default:
        return const Icon(Icons.file_present, size: 20);
    }
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;

  DashedBorderPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX + dashWidth, size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }

    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
