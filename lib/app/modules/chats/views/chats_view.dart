import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Utilities/responsive.dart';
import '../controllers/chats_controller.dart';
import '../widgets/chat_list_widget.dart';
import '../widgets/conversation_widget.dart';

class ChatsView extends GetView<ChatsController> {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clear selected chat when building the view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedChat.value = null;
      controller.messages.clear();
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.waChatBgDark
          : AppColors.waChatBgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (Responsive.isDesktop(context)) {
              // Desktop: Show both chat list and conversation side by side
              return Row(
                children: [
                  const ChatListWidget(),
                  const Expanded(child: ConversationWidget()),
                ],
              );
            } else if (Responsive.isTablet(context)) {
              // Tablet: Similar to desktop but adjust widths
              return Row(
                children: [
                  const ChatListWidget(),
                  const Expanded(child: ConversationWidget()),
                ],
              );
            } else {
              // Mobile: Show chat list or conversation based on selection
              return Obx(() {
                return (!controller.showConversation.value)
                    ? ChatListWidget()
                    : const SizedBox.expand(child: ConversationWidget());
              });
            }
          },
        ),
      ),
    );
  }
}
