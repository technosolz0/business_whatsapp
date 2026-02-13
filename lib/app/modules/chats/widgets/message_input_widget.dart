import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chats_controller.dart';

class MessageInputWidget extends GetView<ChatsController> {
  const MessageInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final messageController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // WhatsApp Colors from AppColors
    final backgroundColor = isDark
        ? AppColors.waHeaderDark
        : AppColors.waHeaderLight;
    final inputBgColor = isDark
        ? AppColors.waDividerDark
        : Colors.white; // Using divider dark as input bg
    final iconColor = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;
    final textColor = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ------------------ Upload Progress ------------------
          Obx(() {
            if (controller.uploadProgress.value > 0 &&
                controller.uploadProgress.value < 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: LinearProgressIndicator(
                  value: controller.uploadProgress.value,
                  color: const Color(0xFF00A884),
                  backgroundColor: isDark
                      ? const Color(0xFF2A3942)
                      : Colors.white,
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // ------------------ Input Row ------------------
          Row(
            children: [
              // Attachment Button
              IconButton(
                onPressed: controller.canSendMessage
                    ? () => controller.showMediaOptions()
                    : null,
                icon: const Icon(Icons.add),
                color: iconColor,
              ),
              SizedBox(width: 10),
              // ------------------ Text Input ------------------
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: messageController,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFF8696A0)
                            : const Color(0xFF667781),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    maxLines: 5,
                    minLines: 1,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty &&
                          controller.canSendMessage) {
                        controller.sendMessage(value);
                        messageController.clear();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 5),

              // ------------------ Send/Mic Button ------------------
              Obx(() {
                // For now, only Send button logic is here,
                // but WhatsApp alternates between Mic and Send.
                return IconButton(
                  onPressed: controller.canSendMessage
                      ? () {
                          if (messageController.text.trim().isNotEmpty) {
                            controller.sendMessage(messageController.text);
                            messageController.clear();
                          }
                        }
                      : null,
                  icon: const Icon(Icons.send),
                  color: iconColor,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
