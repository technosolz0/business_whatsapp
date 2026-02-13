import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import '../controllers/chats_controller.dart';
import '../models/chat_model.dart';

class ChatListWidget extends GetView<ChatsController> {
  const ChatListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // WhatsApp Colors & Styles from AppColors
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.waChatBgDark : Colors.white;
    final headerColor = isDark
        ? AppColors.waHeaderDark
        : AppColors.waHeaderLight;
    final borderRightColor = isDark
        ? AppColors.waDividerDark
        : AppColors.waDividerLight;
    final titleColor = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;
    final subTitleColor = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? double.infinity : 380, // Slightly wider sidebar
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(
            color: isMobile ? Colors.transparent : borderRightColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Header Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            color: headerColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chats',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Bar & Filters
          Container(
            color: backgroundColor,
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12,
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.waTextPrimaryDark : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search or start new chat',
                    hintStyle: TextStyle(fontSize: 14, color: subTitleColor),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, size: 20, color: subTitleColor),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.waHeaderDark
                        : AppColors.waHeaderLight,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                    ), // Centers text vertically
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: controller.updateSearchQuery,
                ),

                const SizedBox(height: 10),

                // Filter Chips (All, Unread, Favourites)
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip(
                          label: 'All',
                          value: 'all',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip(
                          label: 'Unread',
                          value: 'unRead',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip(
                          label: 'Favourites',
                          value: 'isFavourite',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderRightColor),

          // 3. Chat List
          Expanded(
            child: Obx(() {
              final chats = controller.filteredChats;
              final isLoading = controller.isLoadingMoreChats.value;

              if (chats.isEmpty && isLoading) {
                return const ListShimmer();
              }

              if (chats.isEmpty && !isLoading) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No chats found',
                        style: TextStyle(color: subTitleColor, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                key: const PageStorageKey('chat_list_view'),
                physics: const AlwaysScrollableScrollPhysics(),
                controller: controller.chatListScrollController,
                itemCount: chats.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chats.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          ShimmerWidget.circular(width: 50, height: 50),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerWidget.rectangular(
                                  height: 16,
                                  width: 150,
                                ),
                                SizedBox(height: 8),
                                ShimmerWidget.rectangular(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final chat = chats[index];
                  return Obx(
                    () => ChatListItem(
                      chat: chat,
                      onTap: () => controller.selectChat(chat),
                      isSelected: controller.selectedChat.value?.id == chat.id,
                      onFavouriteToggle: () =>
                          controller.updateChatFavouriteStatus(
                            chat.id,
                            !chat.isFavourite,
                          ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isActive = controller.activeFilter.value == value;

    final activeGreen = AppColors.primary;
    final activeBg = activeGreen.withOpacity(0.15);
    final activeText = activeGreen;

    final subTitleColor = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;
    final inactiveBg = isDark
        ? AppColors.waHeaderDark
        : AppColors.waDividerLight;
    final inactiveText = subTitleColor;

    return InkWell(
      onTap: () => controller.updateFilter(value),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeText : inactiveText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final bool isSelected;
  final VoidCallback onFavouriteToggle;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.isSelected,
    required this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // WhatsApp Colors from AppColors
    final hoverColor = isDark
        ? AppColors.waHeaderDark
        : const Color(0xFFF5F6F6);
    final selectedColor = isDark
        ? AppColors.waDividerDark
        : AppColors.waDividerLight;
    final borderRightColor = isDark
        ? AppColors.waDividerDark
        : AppColors.waDividerLight;
    final timeColor = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;
    final messageColor = isDark
        ? AppColors.waTextSecondaryDark
        : AppColors.waTextSecondaryLight;
    final titleColor = isDark
        ? AppColors.waTextPrimaryDark
        : AppColors.waTextPrimaryLight;

    final name = chat.name.trim();
    final displayName = name.isNotEmpty ? name : "Unknown User";

    String initial = "U";
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length > 1) {
        initial = '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        initial = parts.first[0].toUpperCase();
      }
    }

    return InkWell(
      onTap: onTap,
      hoverColor: hoverColor,
      child: Container(
        color: isSelected ? selectedColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: const BoxConstraints(minHeight: 72),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary,
              backgroundImage: chat.avatarUrl != null
                  ? NetworkImage(chat.avatarUrl!)
                  : null,
              child: chat.avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 15),

            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderRightColor, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Name + Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          chat.lastMessageTimeFormatted,
                          style: TextStyle(
                            color: chat.unRead ? AppColors.primary : timeColor,
                            fontSize: 12,
                            fontWeight: chat.unRead
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Bottom Row: Message + Icons/Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: TextStyle(color: messageColor, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Star Icon (Interactive)
                        GestureDetector(
                          onTap: onFavouriteToggle,
                          child: Icon(
                            chat.isFavourite ? Icons.star : Icons.star_outline,
                            size: 18,
                            color: chat.isFavourite
                                ? Colors.amber
                                : timeColor.withOpacity(0.5),
                          ),
                        ),

                        if (chat.unRead) const SizedBox(width: 8),

                        if (chat.unRead)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.brightness_1, size: 0.25),
                          ),
                      ],
                    ),
                    if (chat.assignedAdmin != null &&
                        chat.assignedAdmin!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "Assigned to ${chat.assignedAdmin!.length} Admin",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
