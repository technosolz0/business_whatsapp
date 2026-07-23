import 'package:business_whatsapp/app/modules/broadcasts/views/widgets/sample_variable_input.dart';
import 'package:business_whatsapp/app/modules/broadcasts/widgets/interactive_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_broadcast_controller.dart';
import 'package:business_whatsapp/app/Utilities/media_utils.dart';
import 'package:business_whatsapp/app/data/services/broadcast_service.dart';
import 'package:business_whatsapp/app/data/models/carousel_card_model.dart';
import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';

class TemplateCardWidget extends StatefulWidget {
  const TemplateCardWidget({super.key});

  @override
  State<TemplateCardWidget> createState() => _TemplateCardWidgetState();
}

class _TemplateCardWidgetState extends State<TemplateCardWidget> {
  final ScrollController _carouselScrollController = ScrollController();

  @override
  void dispose() {
    _carouselScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = Get.find<CreateBroadcastController>();

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
          Text(
            "Select Template",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          /// TEMPLATE DROPDOWN
          _templateDropdown(isDark, ctrl),

          const SizedBox(height: 24),

          Obx(() {
            final param = ctrl.selectedTemplateParams.value;

            // Nothing selected at all
            if (param == null) {
              return const Text("Select a template to load parameters.");
            }

            // Template selected but has ZERO parameters
            final bool isCarousel = param.templateType == "CAROUSEL";
            final bool hasNoParams =
                param.headerVars == 0 && param.bodyVars == 0;

            final bool hasNoButtonsParams =
                (param.buttons == null || param.buttons!.isEmpty);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ONLY SHOW PARAMETER TITLE & CHIPS IF PARAMETERS EXIST
                if (!hasNoParams) ...[
                  Text(
                    "Template Parameters",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// GLOBAL CHIP LIST
                  GlobalChipList(chips: ctrl.availableChips),

                  const SizedBox(height: 12),

                  /// HEADER PARAMS
                  if (param.headerVars > 0) ...[
                    for (int i = 1; i <= param.headerVars; i++)
                      _paramField(
                        num: i,
                        keyName: "header_$i",
                        ctrl: ctrl,
                        sampleValue: param.headerExamples.length >= i
                            ? param.headerExamples[i - 1]
                            : null,
                      ),
                    const SizedBox(height: 20),
                  ],

                  /// BODY PARAMS
                  if (param.bodyVars > 0) ...[
                    for (int i = 1; i <= param.bodyVars; i++)
                      _paramField(
                        num: i,
                        keyName: "body_$i",
                        ctrl: ctrl,
                        sampleValue: param.bodyExamples.length >= i
                            ? param.bodyExamples[i - 1]
                            : null,
                      ),
                  ],

                  const SizedBox(height: 20),
                ],

                /// INTERACTIVE BUTTONS (Always visible if they exist)
                if (!hasNoButtonsParams)
                  BroadcastActionsWidget(isDark: isDark, controller: ctrl),

                /// CAROUSEL CARDS SECTION
                if (param.templateType == "CAROUSEL" &&
                    ctrl.carouselCards.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    "Carousel Cards",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        height: 250, // Height for small card previews
                        child: Scrollbar(
                          controller: _carouselScrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _carouselScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: ctrl.carouselCards.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 20),
                            itemBuilder: (context, index) {
                              final card = ctrl.carouselCards[index];
                              return _smallCarouselCardItem(
                                isDark,
                                ctrl,
                                card,
                                index,
                                context,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _carouselCardItem(
    bool isDark,
    CreateBroadcastController ctrl,
    CarouselCard card,
    int index, {
    double width = 300,
    bool showTitle = true,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              "Card #${index + 1}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
          ],

          /// MEDIA UPLOAD FOR CARD
          _cardMediaUpload(isDark, ctrl, card),

          const SizedBox(height: 16),

          /// CARD BODY PREVIEW
          // Text(
          //   "Body:",
          //   style: TextStyle(
          //     fontSize: 12,
          //     fontWeight: FontWeight.w600,
          //     color: isDark ? Colors.white70 : Colors.black54,
          //   ),
          // ),
          // const SizedBox(height: 4),
          Text(
            card.body.value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          /// CARD PARAMS (BODY)
          if (card.variableControllers.isNotEmpty) ...[
            Text(
              "Body Parameters:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            /// GLOBAL CHIP LIST FOR CARD
            GlobalChipList(chips: ctrl.availableChips),

            const SizedBox(height: 12),

            // Filter for body parameters
            ..._buildCardParamFields(index, ctrl, "body"),
          ],

          const SizedBox(height: 16),

          /// CARD BUTTONS & PARAMS
          if (card.buttons.isNotEmpty) ...[
            Text(
              "Buttons:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            ...card.buttons.map((btn) {
              final btnIndex = card.buttons.indexOf(btn);
              return _cardButtonItem(isDark, btn, btnIndex, index, ctrl);
            }),
          ],
        ],
      ),
    );
  }

  void _showFullCardDialog(
    BuildContext context,
    bool isDark,
    CreateBroadcastController ctrl,
    CarouselCard card,
    int index,
  ) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: 550,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_document,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Card Configuration",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Customizing Carousel Card #${index + 1}",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                      // style: IconButton.styleFrom(
                      //   backgroundColor: isDark ? Colors.white10 : Colors.black,
                      //   hoverColor: Colors.red.withValues(alpha: 0.1),
                      // ),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _carouselCardItem(
                    isDark,
                    ctrl,
                    card,
                    index,
                    width: double.infinity,
                    showTitle: false,
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        "Close",
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallCarouselCardItem(
    bool isDark,
    CreateBroadcastController ctrl,
    CarouselCard card,
    int index,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () => _showFullCardDialog(context, isDark, ctrl, card, index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "CARD ${index + 1}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_square,
                  size: 18,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Media Preview with "Add" overlay if empty
            Expanded(
              child: Obx(() {
                final hasMedia = card.mediaHandleId.value.isNotEmpty;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black,
                    ),
                  ),
                  child: hasMedia
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              card.mediaType.value == "IMAGE" &&
                                      card.fileBytes.value != null
                                  ? Image.memory(
                                      card.fileBytes.value!,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.videocam_rounded,
                                        size: 32,
                                        color: Colors.blue.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  color: Colors.black45,
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              card.mediaType.value == "IMAGE"
                                  ? Icons.add_a_photo
                                  : Icons.video_call,
                              color: isDark ? Colors.white10 : Colors.black,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Required",
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white24 : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Content Summary
            // Obx(() {
            //   final text = card.body.value;
            //   return Text(
            //     text.isEmpty ? "No content defined yet..." : text,
            //     maxLines: 2,
            //     overflow: TextOverflow.ellipsis,
            //     style: TextStyle(
            //       fontSize: 12,
            //       height: 1.4,
            //       color: isDark ? Colors.white70 : Colors.black87,
            //       fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
            //     ),
            //   );
            // }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardParamFields(
    int cardIndex,
    CreateBroadcastController ctrl,
    String type,
  ) {
    final fields = <Widget>[];
    final prefix = "card_${cardIndex}_$type";

    // We need to match the keys we created in the controller
    final keys = ctrl.paramControllers.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    keys.sort(); // Ensure order card_0_body_1, card_0_body_2...

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final num = int.tryParse(key.split('_').last) ?? (i + 1);
      final card = ctrl.carouselCards[cardIndex];
      final sampleValue =
          (type == "body" && card.variableExamples.length >= num)
          ? card.variableExamples[num - 1]
          : null;

      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _paramField(
            num: num,
            keyName: key,
            ctrl: ctrl,
            hintText: type.contains("url") ? "Enter dynamic url" : null,
            sampleValue: sampleValue,
          ),
        ),
      );
    }
    return fields;
  }

  Widget _cardButtonItem(
    bool isDark,
    InteractiveButton btn,
    int btnIndex,
    int cardIndex,
    CreateBroadcastController ctrl,
  ) {
    final prefix = "card_${cardIndex}_btn_${btnIndex}_url";
    final hasDynamicParams = ctrl.paramControllers.keys.any(
      (k) => k.startsWith(prefix),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                btn.type == "URL"
                    ? Icons.link
                    : btn.type == "PHONE_NUMBER"
                    ? Icons.phone
                    : Icons.touch_app,
                size: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  btn.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasDynamicParams) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Column(
              children: _buildCardParamFields(
                cardIndex,
                ctrl,
                "btn_${btnIndex}_url",
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cardMediaUpload(
    bool isDark,
    CreateBroadcastController ctrl,
    CarouselCard card,
  ) {
    return Obx(() {
      final hasMedia = card.mediaHandleId.value.isNotEmpty;
      final isUploading = card.isUploading.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: isUploading
                ? null
                : () async {
                    card.uploadError.value = "";
                    final result = await MediaUtils.pickAndValidateFile(
                      mediaType: card.mediaType.value,
                      maxSizeMB: 10,
                    );

                    if (result.success) {
                      card.isUploading.value = true;
                      try {
                        card.fileBytes.value = result.bytes;
                        card.fileName.value = result.fileName!;

                        final uploadResult = await BroadcastService.instance
                            .uploadBroadcastMedia(
                              fileBytes: card.fileBytes.value!,
                              fileName: card.fileName.value,
                              mimeType: result.mimeType!,
                            );

                        if (uploadResult["success"] == true) {
                          card.mediaHandleId.value = uploadResult["media_id"];
                          Utilities.showSnackbar(
                            SnackType.SUCCESS,
                            "Media uploaded successfully!",
                          );
                        } else {
                          card.uploadError.value = "Upload failed.";
                          Utilities.showSnackbar(
                            SnackType.ERROR,
                            "Could not upload media. Please try again.",
                          );
                        }
                      } catch (e) {
                        card.uploadError.value = "Error: $e";
                        Utilities.showSnackbar(
                          SnackType.ERROR,
                          "An unexpected error occurred.",
                        );
                      } finally {
                        card.isUploading.value = false;
                      }
                    } else if (result.error != "No file selected.") {
                      card.uploadError.value =
                          result.error ?? "Selection failed";
                      Utilities.showSnackbar(
                        SnackType.ERROR,
                        result.error ?? "Invalid file selected",
                      );
                    }
                  },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploading
                      ? Colors.blue
                      : isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  width: isUploading ? 2 : 1,
                  style: hasMedia || isUploading
                      ? BorderStyle.solid
                      : BorderStyle.none,
                ),
              ),
              child: isUploading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 12),
                          Text(
                            "Uploading...",
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                    )
                  : hasMedia
                  ? (card.mediaType.value.toUpperCase() == "IMAGE"
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  card.fileBytes.value!,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    card.fileName.value,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ))
                  : Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            card.mediaType.value.toUpperCase() == "IMAGE"
                                ? Icons.add_photo_alternate_outlined
                                : Icons.video_call_outlined,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Upload ${card.mediaType.value}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (card.uploadError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                card.uploadError.value,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      );
    });
  }

  Widget _templateDropdown(bool isDark, CreateBroadcastController ctrl) {
    return Obx(() {
      final templates = ctrl.templateList;

      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A29) : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: ctrl.selectedTemplateId.value.isEmpty
              ? null
              : ctrl.selectedTemplateId.value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          hint: const Text("Select a template"),
          items: templates
              .map(
                (t) => DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.name} - ${t.category}'),
                ),
              )
              .toList(),
          onChanged: (templateId) {
            if (templateId != null) {
              ctrl.onTemplateSelected(templateId);
            }
          },
        ),
      );
    });
  }

  /// PARAM ROW USING SampleVariableInput
  Widget _paramField({
    required int num,
    required String keyName,
    required CreateBroadcastController ctrl,
    String? hintText,
    String? sampleValue,
  }) {
    ctrl.ensureParamKey(keyName); // make sure controller & error exist

    return SampleVariableInput(
      num: num,
      ctrl: ctrl,
      controller: ctrl.paramControllers[keyName]!,
      errorText: ctrl.paramErrors[keyName]!,
      acceptedChips: ctrl.availableChips,
      hintText: sampleValue != null ? "Example: $sampleValue" : hintText,
      onValueChanged: (type, value) {
        ctrl.variableValues[keyName] = {"type": type, "value": value};
        ctrl.updatePreviewBody();
      },
    );
  }
}
