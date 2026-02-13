import 'package:adminpanel/app/common%20widgets/common_filled_button.dart';
import 'package:adminpanel/app/common%20widgets/common_outline_button.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/app/Utilities/responsive.dart';
import 'package:adminpanel/app/modules/chats/models/message_model.dart';
import 'package:adminpanel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../controllers/chats_controller.dart';
import 'message_bubble_widget.dart';
import 'message_input_widget.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import 'export_to_zoho_dialog.dart';

class ConversationWidget extends GetView<ChatsController> {
  const ConversationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isMobile = Responsive.isMobile(Get.context!);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final chat = controller.selectedChat.value;

      // WhatsApp Colors from AppColors
      final headerColor = isDark
          ? AppColors.waHeaderDark
          : AppColors.waHeaderLight;
      final bodyColor = isDark
          ? AppColors.waChatBgDark
          : AppColors.waChatBgLight;
      final titleColor = isDark
          ? AppColors.waTextPrimaryDark
          : AppColors.waTextPrimaryLight;
      final subTitleColor = isDark
          ? AppColors.waTextSecondaryDark
          : AppColors.waTextSecondaryLight;
      final dividerColor = isDark
          ? AppColors.waDividerDark
          : AppColors.waDividerLight;

      if (chat == null) {
        return Container(
          color: isDark ? AppColors.waHeaderDark : AppColors.waHeaderLight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Larger Placeholder similar to WA Web start screen
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 64,
                    color: subTitleColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'WhatsApp Web',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Select a chat to start messaging.\nSend and receive messages without keeping your phone online.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: subTitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        color: bodyColor,
        child: Column(
          children: [
            // ------------------ HEADER ------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(bottom: BorderSide(color: dividerColor)),
              ),
              child: Row(
                children: [
                  if (isMobile)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          controller.showConversation.value = false,
                      icon: Icon(Icons.arrow_back, color: subTitleColor),
                    ),

                  if (isMobile) const SizedBox(width: 8),

                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: chat.avatarUrl != null
                        ? NetworkImage(chat.avatarUrl!)
                        : null,
                    backgroundColor: Colors.grey[400],
                    child: chat.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          chat.isOnline ? 'online' : chat.phoneNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.isOnline
                                ? const Color(0xFF00A884)
                                : subTitleColor,
                            fontWeight: chat.isOnline
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (chat.assignedAdmin != null &&
                      chat.assignedAdmin!.isNotEmpty) ...[
                    isAllChats.value == true
                        ? CommonFilledButton(
                            onPressed: () {
                              controller.assignContacts();
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/icons/chats/assigned.svg",
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 5),
                                const Text("Assigned"),
                              ],
                            ),
                          )
                        : const SizedBox(),
                  ] else ...[
                    isAllChats.value == true
                        ? CommonOutlineButton(
                            onPressed: () {
                              controller.assignContacts();
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/icons/chats/unassigned.svg",
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 5),
                                const Text("Assign"),
                              ],
                            ),
                          )
                        : const SizedBox(),
                  ],

                  const SizedBox(width: 10),

                  if (isConnected.value == true) ...[
                    if (chat.leadRecordId != null &&
                        chat.leadRecordId!.isNotEmpty) ...[
                      CommonFilledButton(
                        onPressed: () {
                          Get.dialog(ExportToZohoDialog(chatId: chat.id));
                        },

                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/chats/uploaded.svg",
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 5),
                            const Text('Export'),
                          ],
                        ),
                      ),
                    ] else ...[
                      CommonOutlineButton(
                        onPressed: () {
                          Get.dialog(ExportToZohoDialog(chatId: chat.id));
                        },

                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/chats/upload.svg",
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 5),
                            const Text('Export'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // ------------------ MESSAGES LIST ------------------
            Expanded(
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.waBubbleReceiverDark
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Messages are end-to-end encrypted',
                        style: TextStyle(fontSize: 12, color: subTitleColor),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  key: ValueKey(chat.id),
                  reverse: true,
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  itemCount:
                      controller.messagesWithDateSeparators.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (controller.isLoadingMore.value &&
                        index == controller.messagesWithDateSeparators.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircleShimmer(size: 20)),
                      );
                    }

                    if (index >= controller.messagesWithDateSeparators.length) {
                      return const SizedBox.shrink();
                    }

                    final item = controller.messagesWithDateSeparators[index];

                    if (item is MessageModel) {
                      return MessageBubbleWidget(
                        message: item,
                        onRetry: item.status == MessageStatus.failed
                            ? () => controller.retryMessage(item)
                            : null,
                      );
                    } else if (item is DateSeparator) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.waBubbleReceiverDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            item.displayText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subTitleColor,
                            ),
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                );
              }),
            ),

            // ------------------ INPUT FIELD ------------------
            const MessageInputWidget(),
          ],
        ),
      );
    });
  }
}
