import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_broadcast_controller.dart';

class BroadcastPreviewWidget extends StatelessWidget {
  const BroadcastPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<CreateBroadcastController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------------
        // PHONE FRAME (UNCHANGED)
        // ------------------------------------------------------
        Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 4,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 500,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuB-FjsI-viOsQXQtxdTTE_pz9iM1HPLIWqQpEGsvzR3Y0H7QdRDjmTadalkSNPTM4frUNS30xcqPOiEoNczaCl4qp-N4pqwOeC1_CuwVhYXCvSzQ060IeaM86ea8DpkZjsUqdcYJEDMsQJangWVnvY-lIoZftvjaddQihedFblo6ZgcNN7UoXNbbtYJbrcZyAPu3BLXL1CK0b-8ixXJjORMWkXAeBjktf8gnk81rqBEcySmA4djg1KD84DyITEwl9P5jbY1THnPzz0',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeaderBar(),

                    // ------------------------------------------------------
                    // CHAT BUBBLE (DYNAMIC CONTENT)
                    // ------------------------------------------------------
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 270),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),

                            // 🌟 DYNAMIC CONTENT INSIDE BUBBLE
                            child: SingleChildScrollView(
                              child: Obx(() {
                                return _buildBubbleContent(controller, isDark);
                              }),
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
        ),
      ],
    );
  }

  // ------------------------------------------------------
  // HEADER BAR (unchanged)
  // ------------------------------------------------------
  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2)),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.grey[300]),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'online',
                  style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // CHAT BUBBLE DYNAMIC CONTENT
  // ------------------------------------------------------
  Widget _buildBubbleContent(CreateBroadcastController c, bool isDark) {
    final body = c.templateBody.value;
    final header = c.templateHeader.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.attachmentType.value.isNotEmpty) _buildMediaPreview(c, isDark),
        const SizedBox(height: 8),
        if (body.isEmpty) Text("Please select a template to see preview."),

        if (header.isNotEmpty)
          Text(
            header,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

        if (header.isNotEmpty) const SizedBox(height: 6),

        _buildHighlightedPreviewText(
          body.isEmpty ? c.originalTemplateBody.value : body,
          c.appliedValues,
          isDark,
        ),
        if (c.templateType == "Interactive") ...[
          const SizedBox(height: 12),
          _buildInteractivePreview(isDark, c),
        ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            '10:42 AM',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  String normalizeDashSpacing(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'(?<! )-(?! )'), // dash with no spaces around
          (m) => ' - ',
        )
        .replaceAll(RegExp(r'\s+'), ' ') // clean multiple spaces
        .trim();
  }

  Widget _buildHighlightedPreviewText(
    String text,
    List<String> appliedValues,
    bool isDark,
  ) {
    // ⭐ Normalize dashes so they always have spaces
    text = normalizeDashSpacing(text);

    final defaultColor = isDark ? Colors.white70 : Colors.black87;
    final highlightColor = Colors.blue;

    final spans = <TextSpan>[];
    int index = 0;

    // Extract placeholders {{n}}
    final placeholderRegex = RegExp(r"\{\{\d+\}\}");

    // Merge placeholders + applied values (all highlighted)
    final highlightTargets = <String>[
      ...placeholderRegex.allMatches(text).map((m) => m.group(0)!),
      ...appliedValues,
    ];

    // Sort by longest first
    highlightTargets.sort((a, b) => b.length.compareTo(a.length));

    while (index < text.length) {
      bool matched = false;

      for (final target in highlightTargets) {
        if (target.isEmpty) continue;

        if (text.startsWith(target, index)) {
          spans.add(
            TextSpan(
              text: target,
              style: TextStyle(
                color: highlightColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
          index += target.length;
          matched = true;
          break;
        }
      }

      if (!matched) {
        spans.add(
          TextSpan(
            text: text[index],
            style: TextStyle(color: defaultColor, fontSize: 14),
          ),
        );
        index++;
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  // ------------------------------------------------------
  // MEDIA PREVIEW (Image / Video / Document)
  // ------------------------------------------------------
  Widget _buildMediaPreview(CreateBroadcastController c, bool isDark) {
    final bytes = c.selectedFileBytes.value;
    final type = c.attachmentType.value;

    if (bytes == null) {
      return _mediaIcon(isDark, Icons.image_outlined, "No File Attached.");
    }

    // IMAGE
    if (type == "Image") {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 250),
          child: Image.memory(
            bytes,
            // height: 120,
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
      );
    }

    // VIDEO
    if (type == "Video") {
      return _mediaIcon(isDark, Icons.play_circle_outline, "Video Attached");
    }

    // DOCUMENT
    return _mediaIcon(
      isDark,
      Icons.insert_drive_file_outlined,
      c.selectedFileName.value,
    );
  }

  Widget _mediaIcon(bool isDark, IconData icon, String label) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractivePreview(bool isDark, CreateBroadcastController c) {
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
