import 'package:business_whatsapp/app/Utilities/responsive.dart';
import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';
import '../controllers/create_template_controller.dart';

class InteractiveActionsWidget extends StatelessWidget {
  const InteractiveActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final controller = Get.find<CreateTemplateController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF242424),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'In addition to your message, you can send actions with your message. Maximum 25 characters are allowed in CTA button title & Quick Replies.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 16),

          // ADD ACTION BUTTONS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                label: "Quick Replies",
                icon: Icons.add,
                controller: controller,
                onPressed: controller.addQuickReply,
                isDark: isDark,
                count: controller.quickRepliesCount,
              ),
              _buildActionButton(
                label: "URL",
                controller: controller,
                icon: Icons.add,
                onPressed: controller.addUrl,
                isDark: isDark,
                count: controller.urlCount,
              ),
              _buildActionButton(
                label: "Phone Number",
                controller: controller,
                icon: Icons.add,
                onPressed: controller.addPhoneNumber,
                isDark: isDark,
                count: controller.phoneNumberCount,
              ),
              _buildActionButton(
                label: "Copy Code",
                controller: controller,
                icon: Icons.add,
                onPressed: controller.addCopyCode,
                isDark: isDark,
                count: controller.copyCodeCount,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DYNAMIC BUTTON FIELDS
          Obx(() {
            final hasUrlButton = controller.buttons.any(
              (btn) => btn.type == "URL",
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: List.generate(controller.buttons.length, (index) {
                    if (!_safeIndex(controller, index)) {
                      return const SizedBox.shrink();
                    }

                    final btn = controller.buttons[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildResponsiveButtonRow(
                        btn,
                        index,
                        controller,
                        isDark,
                      ),
                    );
                  }),
                ),
                if (hasUrlButton) ...[
                  const SizedBox(height: 12),
                  _buildCommonLinkTrackingCheckbox(controller, isDark),
                ],
              ],
            );
          }),
        ],
      );
    });
  }

  Widget _buildResponsiveButtonRow(
    InteractiveButton btn,
    int index,
    CreateTemplateController controller,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildButtonField(btn, index, controller, isDark)),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _removeButton(controller, index, btn),
          icon: const Icon(Icons.close, color: Colors.red),
        ),
      ],
    );
  }

  void _removeButton(
    CreateTemplateController controller,
    int index,
    InteractiveButton btn,
  ) {
    Future.microtask(() {
      controller.buttons.removeAt(index);
      controller.btnTextCtrls.removeAt(index);
      controller.btnValueCtrls.removeAt(index);
      controller.btnTextErrors.removeAt(index);
      controller.btnValueErrors.removeAt(index);

      if (btn.type == "URL") {
        controller.urlType.removeAt(index);
        controller.dynamicValueCtrl.removeAt(index);
      } else {
        controller.urlType.removeAt(index);
        controller.dynamicValueCtrl.removeAt(index);
      }

      switch (btn.type) {
        case "QUICK_REPLY":
          controller.quickRepliesCount.value++;
          break;
        case "URL":
          controller.urlCount.value++;
          break;
        case "PHONE_NUMBER":
          controller.phoneNumberCount.value++;
          break;
        case "COPY_CODE":
          controller.copyCodeCount.value++;
          break;
      }
    });
  }

  Widget _buildButtonField(
    InteractiveButton btn,
    int index,
    CreateTemplateController controller,
    bool isDark,
  ) {
    switch (btn.type) {
      case "QUICK_REPLY":
        return buildQuickReplyRow(btn, index, controller, isDark);
      case "URL":
      case "PHONE_NUMBER":
      case "COPY_CODE":
        return buildCopyPhoneUrlRow(btn, index, controller, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCommonLinkTrackingCheckbox(
    CreateTemplateController controller,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Obx(
              () => Checkbox(
                side: BorderSide(color: Colors.black),
                value: !controller.ctaUrlLinkTrackingOptedOut.value,
                activeColor: const Color(0xFF137FEC),
                onChanged: (val) {
                  if (val != null) {
                    controller.ctaUrlLinkTrackingOptedOut.value = !val;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "When tracking is enabled, WhatsApp may show a branded link to customers which will redirect to your website",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required RxInt count,
    required CreateTemplateController controller,
  }) {
    return Obx(() {
      final canAddMore = count.value > 0 && controller.buttons.length < 10;

      return OutlinedButton(
        onPressed: canAddMore ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: canAddMore
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              "$label (${count.value})",
              style: TextStyle(
                color: canAddMore
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildLabelBox(String label) {
    return SizedBox(
      width: 80,
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget buildQuickReplyRow(
    InteractiveButton btn,
    int index,
    CreateTemplateController controller,
    bool isDark,
  ) {
    if (!_safeIndex(controller, index)) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(Get.context!);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Reply',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.getTextCtrl(index),
            maxLength: 25,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: (v) {
              final t = v.trim();
              if (t.isEmpty) {
                controller.setTextError(index, "Required");
              } else {
                controller.setTextError(index, "");
              }
              controller.buttons[index] = btn.copyWith(text: t);
            },
            decoration: InputDecoration(
              counterText: "",
              labelText: "Button Text",
              filled: true,
              errorText: controller.btnTextErrors[index].isEmpty
                  ? null
                  : controller.btnTextErrors[index],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF137FEC),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabelBox('Quick Reply'),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: TextField(
            controller: controller.getTextCtrl(index),
            maxLength: 25,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: (v) {
              final t = v.trim();
              if (t.isEmpty) {
                controller.setTextError(index, "Required");
              } else {
                controller.setTextError(index, "");
              }
              controller.buttons[index] = btn.copyWith(text: t);
            },
            decoration: InputDecoration(
              counterText: "",
              labelText: "Button Text",
              filled: true,
              errorText: controller.btnTextErrors[index].isEmpty
                  ? null
                  : controller.btnTextErrors[index],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF137FEC),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCopyPhoneUrlRow(
    InteractiveButton btn,
    int index,
    CreateTemplateController controller,
    bool isDark,
  ) {
    if (!_safeIndex(controller, index)) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(Get.context!);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            btn.type,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          if (btn.type != "COPY_CODE") ...[
            TextField(
              controller: controller.getTextCtrl(index),
              maxLength: 25,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                counterText: "",
                labelText: "Button Text",
                filled: true,
                errorText: controller.btnTextErrors[index].isEmpty
                    ? null
                    : controller.btnTextErrors[index],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF137FEC),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) {
                controller.buttons[index] = btn.copyWith(text: v.trim());
                controller.clearButtonError(index, isText: true);
              },
            ),
            const SizedBox(height: 12),
          ],

          btn.type == "PHONE_NUMBER"
              ? _buildPhoneField(btn, index, controller, isDark)
              : _buildTextValueField(btn, index, controller, isDark),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabelBox(btn.type),
        const SizedBox(width: 8),

        if (btn.type != "COPY_CODE") ...[
          SizedBox(
            width: 180,
            child: TextField(
              controller: controller.getTextCtrl(index),
              maxLength: 25,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                counterText: "",
                labelText: "Button Text",
                filled: true,
                errorText: controller.btnTextErrors[index].isEmpty
                    ? null
                    : controller.btnTextErrors[index],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF137FEC),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) {
                controller.buttons[index] = btn.copyWith(text: v.trim());
                controller.clearButtonError(index, isText: true);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],

        Expanded(
          flex: btn.type != "COPY_CODE" ? 3 : 6,
          child: btn.type == "PHONE_NUMBER"
              ? _buildPhoneField(btn, index, controller, isDark)
              : _buildTextValueField(btn, index, controller, isDark),
        ),
      ],
    );
  }

  Widget _buildPhoneField(
    InteractiveButton btn,
    int index,
    CreateTemplateController controller,
    bool isDark,
  ) {
    return Row(
      children: [
        CountryCodePicker(
          onChanged: (code) {
            controller.phoneCountryCode.value = code.dialCode!;
            controller.buttons[index] = btn.copyWith(
              phoneNumber:
                  "${controller.phoneCountryCode.value}${controller.btnValueCtrls[index].text}",
            );
            controller.clearButtonError(index, isValue: true);
          },
          initialSelection: controller.phoneCountryCode.value,
          favorite: const ["+91", "+1"],
          showDropDownButton: true,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller.getValueCtrl(index),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 15,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              counterText: "",
              labelText: "Phone Number",
              filled: true,
              errorText: controller.btnValueErrors[index].isEmpty
                  ? null
                  : controller.btnValueErrors[index],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF137FEC),
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) {
              final num = v.trim();
              if (num.isEmpty) {
                controller.setValueError(index, "Required");
              } else {
                controller.setValueError(index, "");
              }
              controller.buttons[index] = btn.copyWith(
                phoneNumber: "${controller.phoneCountryCode.value}$num",
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextValueField(
    InteractiveButton btn,
    int index,
    CreateTemplateController controller,
    bool isDark,
  ) {
    final isUrl = btn.type == "URL";
    final currentType = (index < controller.urlType.length)
        ? controller.urlType[index]
        : "Static";
    final urlCtrl = (index < controller.btnValueCtrls.length)
        ? controller.btnValueCtrls[index]
        : TextEditingController();
    final dynamicCtrl = (index < controller.dynamicValueCtrl.length)
        ? controller.dynamicValueCtrl[index]
        : TextEditingController();

    if (btn.type == "COPY_CODE") {
      return TextField(
        controller: controller.getValueCtrl(index),
        maxLength: 15,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        decoration: InputDecoration(
          counterText: "",
          labelText: "Sample Value",
          filled: true,
          errorText: controller.btnValueErrors[index].isEmpty
              ? null
              : "Copy code required",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? Color(0xFF4B5563) : Color(0xFFD1D5DB),
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF137FEC), width: 1.5),
          ),
        ),
        onChanged: (v) {
          final code = v.trim();
          if (code.isEmpty) {
            controller.setValueError(index, "Copy code required");
          } else {
            controller.setValueError(index, "");
          }
          controller.buttons[index] = btn.copyWith(example: [code]);
        },
      );
    }

    if (isUrl &&
        currentType == "Dynamic" &&
        urlCtrl.text.isEmpty &&
        btn.example != null &&
        btn.example!.isNotEmpty) {
      final fullExample = btn.example!.first;
      if (fullExample.contains("/")) {
        final parts = fullExample.split("/");
        final pattern = parts.sublist(0, parts.length - 1).join("/");
        urlCtrl.text = pattern;
      }
    }

    final isMobile = Responsive.isMobile(Get.context!);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUrl) ...[
            _urlTypeDropdown(
              isDark,
              currentType,
              controller,
              index,
              urlCtrl,
              dynamicCtrl,
            ),
            const SizedBox(height: 10),
          ],

          _urlOrValueField(
            isDark,
            btn,
            currentType,
            controller,
            index,
            urlCtrl,
            dynamicCtrl,
          ),

          if (isUrl && currentType == "Dynamic") ...[
            const SizedBox(height: 10),
            _dynamicField(isDark, controller, index, urlCtrl, dynamicCtrl, btn),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUrl)
          SizedBox(
            width: 140,
            child: _urlTypeDropdown(
              isDark,
              currentType,
              controller,
              index,
              urlCtrl,
              dynamicCtrl,
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: _urlOrValueField(
            isDark,
            btn,
            currentType,
            controller,
            index,
            urlCtrl,
            dynamicCtrl,
          ),
        ),
        if (isUrl && currentType == "Dynamic") ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: _dynamicField(
              isDark,
              controller,
              index,
              urlCtrl,
              dynamicCtrl,
              btn,
            ),
          ),
        ],
      ],
    );
  }

  Widget _urlTypeDropdown(
    bool isDark,
    String currentType,
    CreateTemplateController controller,
    int index,
    TextEditingController urlCtrl,
    TextEditingController dynamicCtrl,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentType,
      decoration: InputDecoration(
        labelText: "URL Type",
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xFF4B5563) : Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF137FEC), width: 1.5),
        ),
      ),
      items: [
        "Static",
        "Dynamic",
      ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (value) {
        if (value == null) return;
        controller.urlType[index] = value;
        urlCtrl.clear();
        dynamicCtrl.clear();
        controller.buttons[index] = controller.buttons[index].copyWith(
          url: "",
          example: [],
        );
        controller.clearButtonError(index, isValue: true);
      },
    );
  }

  Widget _urlOrValueField(
    bool isDark,
    InteractiveButton btn,
    String currentType,
    CreateTemplateController controller,
    int index,
    TextEditingController urlCtrl,
    TextEditingController dynamicCtrl,
  ) {
    return TextField(
      controller: urlCtrl,
      maxLength: 2000,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        counterText: "",
        labelText: btn.type == "URL"
            ? (currentType == "Dynamic"
                  ? "URL Pattern (without dynamic part)"
                  : "Complete URL")
            : "Value",
        hintText: btn.type == "URL" && currentType == "Dynamic"
            ? "Enter Domain"
            : null,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xFF4B5563) : Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF137FEC), width: 1.5),
        ),
        errorText: controller.btnValueErrors[index].isEmpty
            ? null
            : controller.btnValueErrors[index],
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      onChanged: (v) {
        final urlPattern = v.trim();

        if (btn.type == "URL" && currentType == "Dynamic") {
          // Store pattern with {{1}} placeholder for WhatsApp API
          controller.buttons[index] = btn.copyWith(
            url: urlPattern.isEmpty ? "" : "$urlPattern{{1}}",
          );

          // Validation
          if (urlPattern.isNotEmpty && !urlPattern.startsWith("https://")) {
            controller.setValueError(index, "URL must start with https://");
          } else {
            controller.clearButtonError(index, isValue: true);
          }

          // If dynamic value exists, update example too
          if (dynamicCtrl.text.isNotEmpty) {
            controller.buttons[index] = controller.buttons[index].copyWith(
              example: ["$urlPattern${dynamicCtrl.text.trim()}"],
            );
          }
        } else {
          // Static URL - use as-is
          controller.buttons[index] = btn.copyWith(url: urlPattern);

          // Validation
          if (btn.type == "URL" &&
              urlPattern.isNotEmpty &&
              !urlPattern.startsWith("https://")) {
            controller.setValueError(index, "URL must start with https://");
          } else {
            controller.clearButtonError(index, isValue: true);
          }
        }
      },
    );
  }

  Widget _dynamicField(
    bool isDark,
    CreateTemplateController controller,
    int index,
    TextEditingController urlCtrl,
    TextEditingController dynamicCtrl,
    InteractiveButton btn,
  ) {
    return TextField(
      controller: dynamicCtrl,
      maxLength: 200,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        counterText: "",
        labelText: "Dynamic Value",
        hintText: "e.g. contact-us",
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xFF4B5563) : Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF137FEC), width: 1.5),
        ),
        errorText: controller.btnValueErrors[index].isEmpty
            ? null
            : controller.btnValueErrors[index],
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      onChanged: (v) {
        final pattern = urlCtrl.text.trim();
        final dyn = v.trim();

        if (dyn.isEmpty || pattern.isEmpty) {
          controller.setValueError(index, "Required");
        } else {
          controller.setValueError(index, "");

          // 🔥 KEY FIX: Set url with {{1}} and example with actual value
          controller.buttons[index] = btn.copyWith(
            url: "$pattern{{1}}", // Template URL with placeholder
            example: ["$pattern$dyn"], // Example showing complete URL
          );
        }
      },
    );
  }

  bool _safeIndex(CreateTemplateController c, int i) {
    final lists = [
      c.buttons,
      c.btnTextCtrls,
      c.btnValueCtrls,
      c.btnTextErrors,
      c.btnValueErrors,
      c.urlType,
      c.dynamicValueCtrl,
    ];
    return lists.every((l) => i >= 0 && i < l.length);
  }
}
