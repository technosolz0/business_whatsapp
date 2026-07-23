import 'dart:ui';
import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';
import '../controllers/create_template_controller.dart';
import '../../../data/models/carousel_card_model.dart';

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This is how your message will appear to your customers.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // PHONE MOCKUP
          Center(
            child: Container(
              width: 340, // Realistic phone width
              height: 680, // Realistic phone height
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff0b141a)
                    : const Color(0xffe5ddd5),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark
                      ? const Color(0xff2a2a2a)
                      : const Color(0xff1a1a1a),
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  children: [
                    _buildStatusBar(isDark),
                    _buildWhatsappHeader(isDark),
                    Expanded(
                      child: Stack(
                        children: [
                          // Chat Background Pattern (Subtle)
                          Positioned.fill(
                            child: Opacity(
                              opacity: isDark ? 0.05 : 0.08,
                              child: Image.network(
                                'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(),
                              ),
                            ),
                          ),

                          // Chat Content
                          ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            children: [
                              _buildDateHeader(isDark),
                              const SizedBox(height: 16),
                              if (type != "Carousel")
                                _buildMessageBubble(isDark, c)
                              else
                                _buildCarouselMessage(isDark, c),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildChatInputBar(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ===============================================================
  //                        UI COMPONENTS
  // ===============================================================

  Widget _buildStatusBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: isDark ? const Color(0xff1f2c34) : const Color(0xff075e54),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "9:41",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: const [
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

  Widget _buildWhatsappHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
      color: isDark ? const Color(0xff1f2c34) : const Color(0xff075e54),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.business, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Business",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "online",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.videocam, color: Colors.white, size: 22),
          const SizedBox(width: 16),
          const Icon(Icons.call, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.more_vert, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildDateHeader(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xff182229)
              : const Color(0xffd1d7db).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "TODAY",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(bool isDark, CreateTemplateController c) {
    final bubbleColor = isDark ? const Color(0xff202c33) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPaint(painter: TrianglePainter(isDark: isDark)),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Media Section
                if (c.selectedMediaType.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _buildMediaPreview(isDark, c),
                  ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Text (if no media)
                      if (c.templateHeader.value.isNotEmpty &&
                          c.selectedMediaType.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            c.templateHeader.value,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),

                      // Body text
                      RichText(
                        text: WhatsAppFormatter.format(
                          c.templateFormat.value.isEmpty
                              ? "Your message will appear here"
                              : _applySampleValues(
                                  c.templateFormat.value,
                                  c.variableControllers,
                                ),
                          TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),

                      // Footer text
                      if (c.templateFooter.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            c.templateFooter.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ),

                      // Timestamp
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "09:41",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Buttons Section
                if (c.templateType.value == "Interactive" &&
                    c.buttons.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.5),
                  _buildInteractiveButtons(isDark, c),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 40), // Push bubble to the left
      ],
    );
  }

  Widget _buildInteractiveButtons(bool isDark, CreateTemplateController c) {
    return Column(
      children: c.buttons.map((btn) {
        final index = c.buttons.indexOf(btn);
        return Column(
          children: [
            InkWell(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getButtonIcon(btn.type),
                      size: 16,
                      color: const Color(0xff00a884),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      btn.text.isEmpty ? "Button" : btn.text,
                      style: const TextStyle(
                        color: Color(0xff00a884),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < c.buttons.length - 1)
              const Divider(height: 1, thickness: 0.5),
          ],
        );
      }).toList(),
    );
  }

  IconData _getButtonIcon(String type) {
    switch (type) {
      case "URL":
        return Icons.open_in_new;
      case "PHONE_NUMBER":
        return Icons.phone;
      case "COPY_CODE":
        return Icons.copy;
      default:
        return Icons.touch_app;
    }
  }

  Widget _buildCarouselMessage(bool isDark, CreateTemplateController c) {
    final type = c.templateType.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.templateFormat.value.isNotEmpty) _buildMessageBubble(isDark, c),
        const SizedBox(height: 8),
        SizedBox(
          height: 380,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(Get.context!).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 40),
              itemCount: c.carouselCards.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final card = c.carouselCards[index];
                return _buildCarouselCard(isDark, card);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(bool isDark, CarouselCard card) {
    final cardColor = isDark ? const Color(0xff202c33) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Media
            _buildCardMedia(isDark, card),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    text: WhatsAppFormatter.format(
                      card.body.value.isEmpty
                          ? "Card message"
                          : _applySampleValues(
                              card.body.value,
                              card.variableControllers,
                            ),
                      TextStyle(
                        fontSize: 14,
                        color: textColor,
                        height: 1.4,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Card Buttons
            if (card.buttons.isNotEmpty) ...[
              const Divider(height: 1, thickness: 0.5),
              ...card.buttons.map((btn) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getButtonIcon(btn.type),
                            size: 14,
                            color: const Color(0xff00a884),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            btn.text.isEmpty ? "Button" : btn.text,
                            style: const TextStyle(
                              color: Color(0xff00a884),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (card.buttons.indexOf(btn) < card.buttons.length - 1)
                      const Divider(height: 1, thickness: 0.5),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardMedia(bool isDark, CarouselCard card) {
    if (card.fileBytes.value == null) {
      return Container(
        height: 150,
        color: isDark ? Colors.black26 : Colors.grey[100],
        child: Center(
          child: Icon(
            card.mediaType.value == 'Image' ? Icons.image : Icons.videocam,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    }

    if (card.mediaType.value == 'Image') {
      return Image.memory(
        card.fileBytes.value!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildChatInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff2a3942) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_emotions_outlined,
                    color: isDark ? Colors.white38 : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Message",
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.attach_file,
                    color: isDark ? Colors.white38 : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.camera_alt,
                    color: isDark ? Colors.white38 : Colors.grey,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xff00a884),
            radius: 22,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  //                        MEDIA PREVIEW
  // ===============================================================

  Widget _buildMediaPreview(bool isDark, CreateTemplateController c) {
    final type = c.selectedMediaType.value;

    if (c.selectedFileBytes.value == null) {
      return Container(
        height: 180,
        color: isDark ? Colors.black26 : Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == "Image"
                    ? Icons.image
                    : type == "Video"
                    ? Icons.videocam
                    : Icons.insert_drive_file,
                color: Colors.grey,
                size: 40,
              ),
              const SizedBox(height: 8),
              const Text(
                "Media Preview",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (type == "Image") {
      return Image.memory(
        c.selectedFileBytes.value!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (type == "Video") {
      return Container(
        height: 180,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.black12 : Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.grey, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              c.selectedFileName.value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final bool isDark;
  TrianglePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xff202c33) : Colors.white;
    final path = Path();
    path.moveTo(10, 0);
    path.lineTo(0, 0);
    path.lineTo(10, 10);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Helper class to handle WhatsApp-style text formatting
class WhatsAppFormatter {
  static TextSpan format(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(
      r'(\*.*?\*)|(_.*?_)|(~.*?~)|([^*_~]+)',
      multiLine: true,
      dotAll: true,
    );

    final Iterable<RegExpMatch> matches = exp.allMatches(text);

    for (final RegExpMatch match in matches) {
      String matchText = match.group(0)!;

      if (matchText.startsWith('*') &&
          matchText.endsWith('*') &&
          matchText.length > 1) {
        spans.add(
          TextSpan(
            text: matchText.substring(1, matchText.length - 1),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (matchText.startsWith('_') &&
          matchText.endsWith('_') &&
          matchText.length > 1) {
        spans.add(
          TextSpan(
            text: matchText.substring(1, matchText.length - 1),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (matchText.startsWith('~') &&
          matchText.endsWith('~') &&
          matchText.length > 1) {
        spans.add(
          TextSpan(
            text: matchText.substring(1, matchText.length - 1),
            style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          ),
        );
      } else {
        spans.add(TextSpan(text: matchText, style: baseStyle));
      }
    }

    return TextSpan(children: spans);
  }
}
