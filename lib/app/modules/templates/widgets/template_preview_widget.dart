import 'package:adminpanel/app/data/models/interactive_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';
import '../controllers/create_template_controller.dart';

// ===============================================================
//                  TEMPLATE PREVIEW WIDGET
// ===============================================================

class TemplatePreviewWidget extends StatelessWidget {
  const TemplatePreviewWidget({super.key});

  String _applySampleValues(
    String text,
    List<TextEditingController> controllers,
  ) {
    String result = text;

    for (int i = 0; i < controllers.length; i++) {
      final varNum = i + 1;
      final sampleValue = controllers[i].text.trim();

      result = result.replaceAll(
        "{{$varNum}}",
        sampleValue.isEmpty ? "{{$varNum}}" : sampleValue,
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final c = Get.find<CreateTemplateController>();

    return Obx(() {
      c.previewRefresh.value;

      final isDark = theme.isDarkMode.value;
      final type = c.templateType.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'This is just a graphical representation of the message.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
              // Icon(Icons.play_arrow),
            ],
          ),

          // PHONE-LIKE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1d1d1d) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 12),

                // SPEECH BUBBLE
                Container(
                  margin: const EdgeInsets.only(left: 40),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff2c2c2c)
                        : const Color(0xfff1f2f4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (type == "Text & Media" ||
                          (type == "Interactive" &&
                              c.selectedMediaType.isNotEmpty))
                        _buildMediaPreview(isDark, c),

                      const SizedBox(height: 8),

                      _buildTextPreview(isDark, c),

                      if (type == "Interactive") ...[
                        const SizedBox(height: 12),
                        _buildInteractivePreview(isDark, c),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ===============================================================
  //                        HEADER (Business name)
  // ===============================================================

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xff25D366),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          "Your Business",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  //                        MEDIA PREVIEW (WA Style)
  // ===============================================================

  Widget _buildMediaPreview(bool isDark, CreateTemplateController c) {
    final type = c.selectedMediaType.value;

    final borderColor = isDark
        ? const Color(0xff444444)
        : const Color(0xffD1D5DB);

    // NOTHING SELECTED
    if (c.selectedFileBytes.value == null) {
      return _buildPlaceholder(isDark, type);
    }

    // IMAGE
    if (type == "Image") {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: borderColor)),
          child: Image.memory(c.selectedFileBytes.value!, fit: BoxFit.cover),
        ),
      );
    }

    // VIDEO (thumbnail with play icon)
    if (type == "Video") {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.black12 : Colors.grey.shade200,
              border: Border.all(color: borderColor),
            ),
          ),
          Icon(
            Icons.play_circle_fill,
            size: 48,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ],
      );
    }

    // DOCUMENT preview like WhatsApp
    return Container(
      padding: const EdgeInsets.all(12),
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.black12 : Colors.grey.shade100,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.grey, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              c.selectedFileName.value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, String type) {
    if (type == "Image") {
      return _buildFileTypeIcon(
        isDark,
        Icons.photo_size_select_actual_outlined,
        "Upload an image for preview",
      );
    }
    if (type == "Video") {
      return _buildFileTypeIcon(
        isDark,
        Icons.play_circle_outline_outlined,
        "Upload a video for preview",
      );
    }
    if (type == "Document") {
      return _buildFileTypeIcon(
        isDark,
        Icons.insert_drive_file_outlined,
        "Upload a document for preview",
      );
    }

    return _buildEmptyMediaBox(isDark);
  }

  Widget _buildEmptyMediaBox(bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),

        // // ✅ Dotted Border
        // border: Border.all(
        //   color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFFC7CCD1),
        //   width: 1.5,
        //   style: BorderStyle.solid, // <-- Flutter does NOT support dotted here
        // ),
      ),
      child: DottedBorderWrapper(
        child: const Center(
          child: Text(
            "Media preview will appear here",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon(bool isDark, IconData icon, String label) {
    return DottedBorderWrapper(
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
        ),
        // decoration: BoxDecoration(
        //   color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
        //   borderRadius: BorderRadius.circular(6),
        //   border: Border.all(
        //     color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
        //     width: 2,
        //   ),
        // ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  //                         TEXT PREVIEW
  // ===============================================================

  Widget _buildTextPreview(bool isDark, CreateTemplateController c) {
    final header = c.templateHeader.value;
    final body = _applySampleValues(
      c.templateFormat.value,
      c.variableControllers,
    );
    final footer = c.templateFooter.value;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty && c.selectedMediaType.value.isEmpty)
            Text(
              header,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

          if (header.isNotEmpty && c.selectedMediaType.value.isEmpty)
            const SizedBox(height: 6),

          Text(
            body.isEmpty ? "Your message will appear here" : body,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),

          if (footer.isNotEmpty) const SizedBox(height: 6),

          if (footer.isNotEmpty)
            Text(
              footer,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  // ===============================================================
  //                     INTERACTIVE PREVIEW (WhatsApp Style)
  // ===============================================================
  Widget _buildInteractivePreview(bool isDark, CreateTemplateController c) {
    final list = c.buttons;

    if (list.isEmpty) return const SizedBox.shrink();

    // If 3 or fewer, show all buttons normally
    if (list.length <= 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.map((b) => _ctaButton(b)).toList(),
      );
    }

    // More than 3 → show first 2 + "All Options" button
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ctaButton(list[0]),
        _ctaButton(list[1]),
        _allOptionsButton(list),
      ],
    );
  }

  Widget _allOptionsButton(List<InteractiveButton> fullList) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffe3f2fd),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.menu, size: 20, color: Colors.blue),
          SizedBox(width: 6),
          Text(
            "All Options",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  //               CTA BUTTON (URL / PHONE / COPY)
  // ===============================================================

  Widget _ctaButton(InteractiveButton b) {
    IconData icon;
    String label;

    switch (b.type) {
      case "URL":
        icon = Icons.link;
        label = b.text.isNotEmpty ? b.text : "Open Link";
        break;

      case "PHONE_NUMBER":
        icon = Icons.phone;
        label = b.text.isNotEmpty ? b.text : "Call";
        break;

      case "COPY_CODE":
        icon = Icons.copy;
        label = b.text.isNotEmpty ? b.text : "Copy Code";
        break;

      case "QUICK_REPLY":
        icon = Icons.touch_app; // Or chat_bubble_outline
        label = b.text.isNotEmpty ? b.text : "Reply";
        break;

      default:
        icon = Icons.touch_app;
        label = b.text.isNotEmpty ? b.text : "Button";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffe3f2fd), // Light blue (same as others)
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DottedBorderWrapper extends StatelessWidget {
  final Widget child;
  const DottedBorderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: DottedBorderPainter())),
            child,
          ],
        );
      },
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 5;
    const double dashSpace = 3;
    final paint = Paint()
      ..color = const Color(0xFFC7CCD1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw dashed rectangle
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    final dashPath = Path();

    double distance = 0.0;
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
