import 'package:business_whatsapp/app/modules/broadcasts/controllers/create_broadcast_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/interactive_model.dart';

class BroadcastActionsWidget extends StatelessWidget {
  final bool isDark;
  final CreateBroadcastController controller;

  const BroadcastActionsWidget({
    super.key,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Interactive Parameters",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(controller.buttons.length, (index) {
              final btn = controller.buttons[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBroadcastField(btn, index),
              );
            }),
          );
        }),
      ],
    );
  }

  // ------------------------------------------------------
  // FIELD SELECTOR
  // ------------------------------------------------------
  Widget _buildBroadcastField(InteractiveButton btn, int index) {
    switch (btn.type) {
      case "QUICK_REPLY":
        return _broadcastQuickReply(btn, index);

      case "URL":
      case "PHONE_NUMBER":
      case "COPY_CODE":
        return _broadcastCopyPhoneUrl(btn, index);

      default:
        return const SizedBox.shrink();
    }
  }

  // ------------------------------------------------------
  // LABEL
  // ------------------------------------------------------
  Widget _label(String text) {
    return SizedBox(
      width: 80,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ------------------------------------------------------
  // QUICK REPLY (TEXT DISABLED + VALUE FIELD)
  // ------------------------------------------------------
  Widget _broadcastQuickReply(InteractiveButton btn, int index) {
    return Row(
      children: [
        _label("Quick Reply"),

        const SizedBox(width: 12),

        // DISABLED TEXT FIELD
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller.getTextCtrl(index),
            enabled: false,
            decoration: _disabledInput("Button Text"),
          ),
        ),

        const SizedBox(width: 12),

        // VALUE FIELD (ENABLED)
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller.getValueCtrl(index),
            decoration: _enabledInput(
              "Value",
              errorText:
                  controller.btnValueErrors.length > index &&
                      controller.btnValueErrors[index].isNotEmpty
                  ? controller.btnValueErrors[index]
                  : null,
            ),
            onChanged: (v) {
              controller.buttons[index] = controller.buttons[index].copyWith(
                example: [v],
              );

              // 🔥 Add validation
              if (v.trim().isEmpty) {
                controller.btnValueErrors[index] = "Value is required";
              } else {
                controller.btnValueErrors[index] = "";
              }
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------
  // URL / PHONE / COPY CODE (ALL DISABLED)
  // ------------------------------------------------------
  // Widget _broadcastCopyPhoneUrl(InteractiveButton btn, int index) {
  //   final isCopy = btn.type == "COPY_CODE";

  //   return Row(
  //     children: [
  //       _label(btn.type),
  //       const SizedBox(width: 12),

  //       // TEXT FIELD (ALWAYS DISABLED)
  //       Expanded(
  //         flex: 3,
  //         child: TextField(
  //           controller: controller.getTextCtrl(index),
  //           enabled: false,
  //           decoration: _disabledInput("Button Text"),
  //         ),
  //       ),

  //       const SizedBox(width: 12),

  //       // VALUE FIELD
  //       Expanded(
  //         flex: 3,
  //         child: TextField(
  //           controller: controller.getValueCtrl(index),
  //           enabled: isCopy, // ONLY COPY_CODE IS EDITABLE
  //           decoration: isCopy
  //               ? _enabledInput(
  //                   "Value",
  //                   errorText:
  //                       controller.btnValueErrors.length > index &&
  //                           controller.btnValueErrors[index].isNotEmpty
  //                       ? controller.btnValueErrors[index]
  //                       : null,
  //                 )
  //               : _disabledInput(
  //                   btn.type == "URL"
  //                       ? "URL"
  //                       : btn.type == "PHONE_NUMBER"
  //                       ? "Phone Number"
  //                       : "Value",
  //                 ),

  //           onChanged: (v) {
  //             // ✨ Only CopyCode is editable
  //             if (!isCopy) return;

  //             controller.buttons[index] = controller.buttons[index].copyWith(
  //               example: [v],
  //             );

  //             // Live validation
  //             if (v.trim().isEmpty) {
  //               controller.btnValueErrors[index] = "Value cannot be empty";
  //             } else {
  //               controller.btnValueErrors[index] = "";
  //             }
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _broadcastCopyPhoneUrl(InteractiveButton btn, int index) {
    final isCopy = btn.type == "COPY_CODE";
    final isDynamicUrl =
        btn.type == "URL" &&
        controller.urlType.length > index &&
        controller.urlType[index] == "Dynamic";

    return Row(
      children: [
        _label(btn.type),
        const SizedBox(width: 12),

        // TEXT FIELD (BUTTON LABEL)
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller.getTextCtrl(index),
            enabled: false,
            decoration: _disabledInput("Button Text"),
          ),
        ),

        const SizedBox(width: 12),

        // VALUE FIELD (URL / Phone / Copy Value)
        Expanded(
          flex: isDynamicUrl ? 2 : 3,
          child: TextField(
            controller: controller.getValueCtrl(index),

            enabled: isCopy, // 🔥 COPY_CODE should be editable
            decoration: isCopy
                ? _enabledInput(
                    "Value",
                    errorText:
                        controller.btnValueErrors.length > index &&
                            controller.btnValueErrors[index].isNotEmpty
                        ? controller.btnValueErrors[index]
                        : null,
                  )
                : _disabledInput(
                    btn.type == "URL"
                        ? "Base URL"
                        : btn.type == "PHONE_NUMBER"
                        ? "Phone Number"
                        : "Value",
                  ),
            onChanged: (v) {
              if (!isCopy) return;

              controller.buttons[index] = controller.buttons[index].copyWith(
                example: [v],
              );

              // 🔥 COPY_CODE validation
              if (btn.type == "COPY_CODE") {
                final trimmedValue = v.trim();
                String errorMessage = "";

                if (trimmedValue.isEmpty) {
                  errorMessage = "Coupon code is required";
                } else if (v.contains(' ')) {
                  errorMessage = "Spaces are not allowed in coupon code";
                } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmedValue)) {
                  errorMessage = "Only alphanumeric characters allowed";
                } else if (trimmedValue.length > 20) {
                  errorMessage = "Maximum 20 characters allowed";
                }

                // Ensure list has enough capacity
                while (controller.btnValueErrors.length <= index) {
                  controller.btnValueErrors.add("");
                }

                controller.btnValueErrors[index] = errorMessage;
          
              } else {
                // Original validation for other types
                String errorMessage = "";
                if (v.trim().isEmpty) {
                  errorMessage = "Value cannot be empty";
                } else if (v.contains(' ')) {
                  errorMessage = "Spaces are not allowed in coupon code";
                }

                // Ensure list has enough capacity
                while (controller.btnValueErrors.length <= index) {
                  controller.btnValueErrors.add("");
                }

                controller.btnValueErrors[index] = errorMessage;
              }

              // 🔥 Force UI update
              controller.btnValueErrors.refresh();
            },
          ),
        ),

        // 🔥 SHOW DYNAMIC FIELD ONLY FOR DYNAMIC URL
        if (isDynamicUrl) ...[
          const SizedBox(width: 12),

          Expanded(
            flex: 1,
            child: TextField(
              controller: controller.dynamicValueCtrl[index],
              enabled: true,

              decoration: _enabledInput(
                "Param",
                errorText: null,
                hintText: "{{1}}",
              ),
              onChanged: (value) {
                controller.buttons[index] = controller.buttons[index].copyWith(
                  example: [value],
                );

                // 🔥 Added validation
                if (value.trim().isEmpty) {
                  controller.btnValueErrors[index] = "Param is required";
                } else {
                  controller.btnValueErrors[index] = "";
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------
  // INPUT DECORATIONS
  // ------------------------------------------------------
  InputDecoration _disabledInput(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
    );
  }

  InputDecoration _enabledInput(
    String label, {
    String? errorText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      errorText: errorText, // 🔥 NEW
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF137FEC), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
