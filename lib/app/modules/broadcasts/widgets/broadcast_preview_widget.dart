import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'dart:ui';
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
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.black,
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFF1E293B),
                width: 8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 600,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.4,
                  ),
                  color: isDark
                      ? const Color(0xFF0B141A)
                      : const Color(0xFFE5DDD5),
                ),
                child: Column(
                  children: [
                    // --- STATUS BAR ---
                    _buildStatusBar(isDark),

                    // --- HEADER ---
                    _buildHeaderBar(isDark),

                    // --- CHAT CONTENT ---
                    Expanded(
                      child: Obx(() {
                        final isCarousel =
                            controller.templateType.value == "CAROUSEL";
                        final body = controller.templateBody.value;
                        final header = controller.templateHeader.value;

                        return ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          children: [
                            if (!isCarousel ||
                                body.isNotEmpty ||
                                header.isNotEmpty)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 250,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1F2C34)
                                        : Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: _buildBubbleContent(
                                    controller,
                                    isDark,
                                  ),
                                ),
                              ),
                            SizedBox(height: 8),
                            if (isCarousel)
                              _buildCarouselPreview(isDark, controller),
                          ],
                        );
                      }),
                    ),

                    // --- INPUT BAR SIMULATION ---
                    _buildBottomInputBar(isDark),
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
  // STATUS BAR
  // ------------------------------------------------------
  Widget _buildStatusBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '10:42',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Notch Simulation
          Container(
            width: 60,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Icon(Icons.wifi, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Icon(Icons.battery_full, color: Colors.white, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // BOTTOM INPUT BAR
  // ------------------------------------------------------
  Widget _buildBottomInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Message',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Spacer(),
                  Icon(Icons.attach_file, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Icon(Icons.camera_alt, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00A884),
            child: Icon(Icons.mic, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------
  // HEADER BAR (unchanged)
  // ------------------------------------------------------
  Widget _buildHeaderBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1F2C34) : const Color(0xFF075E54);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(
              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp Business',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'online',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.videocam, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.call, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, color: Colors.white, size: 20),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.attachmentType.value.isNotEmpty) _buildMediaPreview(c, isDark),
        if (c.attachmentType.value.isNotEmpty) const SizedBox(height: 6),

        if (body.isEmpty &&
            header.isEmpty &&
            c.templateType.value != "CAROUSEL")
          const Text(
            "Select a template to preview.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),

        if (header.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildHighlightedPreviewText(
              header,
              c.appliedValues,
              isDark,
              isHeader: true,
            ),
          ),

        _buildHighlightedPreviewText(
          body.isEmpty ? c.originalTemplateBody.value : body,
          c.appliedValues,
          isDark,
        ),

        if (c.templateType.value == "INTERACTIVE") ...[
          const SizedBox(height: 8),
          _buildInteractivePreview(isDark, c),
        ],

        const SizedBox(height: 4),
        Align(
          alignment: Alignment.bottomRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '10:42 AM',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.done_all, size: 14, color: Colors.blue[400]),
            ],
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
    bool isDark, {
    bool isHeader = false,
  }) {
    // ⭐ Normalize dashes so they always have spaces
    text = normalizeDashSpacing(text);

    final defaultColor = isDark ? Colors.white70 : Colors.black87;
    final headerColor = isDark ? Colors.white : Colors.black;
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
                fontSize: isHeader ? 14 : 13,
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
            style: TextStyle(
              color: isHeader ? headerColor : defaultColor,
              fontSize: isHeader ? 14 : 13,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
        index++;
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: isHeader ? 2 : 10,
      overflow: TextOverflow.ellipsis,
    );
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

  Widget _buildCarouselPreview(bool isDark, CreateBroadcastController c) {
    if (c.carouselCards.isEmpty) return const SizedBox.shrink();

    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 380, // Increased height for better visibility
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: c.carouselCards.length,
              padding: const EdgeInsets.only(bottom: 12),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final card = c.carouselCards[index];
                return _buildCarouselCardPreview(isDark, card);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCardPreview(bool isDark, dynamic card) {
    return Obx(() {
      final cardColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;

      return Container(
        width: 240, // More realistic width for WhatsApp cards
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Media
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: _buildCardMediaPreview(card, isDark),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: _buildHighlightedPreviewText(
                card.body.value.isEmpty
                    ? "Card body text goes here..."
                    : card.body.value,
                card.appliedValues,
                isDark,
              ),
            ),

            const Spacer(),

            // Card Buttons
            if (card.buttons.isNotEmpty)
              Column(
                children: card.buttons.map<Widget>((btn) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (btn.type == "URL")
                            const Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Colors.blue,
                            ),
                          if (btn.type == "PHONE_NUMBER")
                            const Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.blue,
                            ),
                          if (btn.type != "URL" && btn.type != "PHONE_NUMBER")
                            const Icon(
                              Icons.reply,
                              size: 14,
                              color: Colors.blue,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            btn.text.isEmpty ? "Button" : btn.text,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Time + Status
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '10:42 AM',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCardMediaPreview(dynamic card, bool isDark) {
    if (card.fileBytes.value == null) {
      return Container(
        height: 140,
        color: isDark ? Colors.black26 : Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                card.mediaType.value == 'IMAGE' ? Icons.image : Icons.videocam,
                color: Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 4),
              const Text(
                "No Media",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (card.mediaType.value == 'IMAGE') {
      return Image.memory(
        card.fileBytes.value!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
      ),
    );
  }
}
