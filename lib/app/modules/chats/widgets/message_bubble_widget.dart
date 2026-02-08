import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/utilities/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';
import 'package:get/get.dart';
import '../controllers/chats_controller.dart';
import 'send_template_dialog.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';

class MessageBubbleWidget extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onRetry;

  const MessageBubbleWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // WhatsApp Colors from AppColors
    final senderColor = isDark ? AppColors.primary : AppColors.primary;
    // final senderColor = isDark ? AppColors.waGreenDark : AppColors.waGreenLight;
    final receiverColor = isDark
        ? AppColors.waBubbleReceiverDark
        : AppColors.waBubbleReceiverLight;
    final textColor = isMe
        ? (isDark ? AppColors.waTextPrimaryDark : AppColors.waTextPrimaryDark)
        : (isDark ? AppColors.waTextPrimaryDark : AppColors.waTextPrimaryLight);
    final timeColor = isMe
        ? (isDark
              ? AppColors.waTextPrimaryDark
              : AppColors.waTextPrimaryDark.withOpacity(0.9))
        : (isDark
              ? AppColors.waTextSecondaryLight
              : AppColors.waTextSecondaryLight.withOpacity(0.9));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundImage: message.senderAvatar != null
                      ? NetworkImage(message.senderAvatar!)
                      : null,
                  backgroundColor: Colors.grey[400],
                  child: message.senderAvatar == null
                      ? Text(
                          message.senderName?[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPressStart: (details) =>
                          _showMessageMenu(context, details),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: 80,
                          maxWidth: Responsive.isMobile(context)
                              ? MediaQuery.of(context).size.width * 0.75
                              : MediaQuery.of(context).size.width * 0.45,
                        ),
                        padding: const EdgeInsets.all(1), // Border/Tail space
                        decoration: BoxDecoration(
                          color: isMe ? senderColor : receiverColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(8),
                            topRight: const Radius.circular(8),
                            bottomLeft: Radius.circular(isMe ? 8 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                top: 8,
                                bottom: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Interactive/Media/Text Content
                                  if (message.isInteractive)
                                    _buildInteractiveContent(context, isMe)
                                  else if (message.isMediaMessage)
                                    _buildMediaContent(context)
                                  else if (message.content.isNotEmpty)
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Timestamp and Status inside bubble (bottom right)
                            Positioned(
                              bottom: 4,
                              right: 6,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: timeColor,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _buildStatusIcon(message.status, isMe),
                                  ],
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
            ],
          ),

          if (message.status == MessageStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => _showTemplateSelectionDialog(context),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text(
                  'Retry / Send Template',
                  style: TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build Interactive Message Content
  Widget _buildInteractiveContent(BuildContext context, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (if exists)
        if (message.header != null && message.header!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.header!,
              style: TextStyle(
                color: isMe
                    ? AppColors.waTextPrimaryDark
                    : AppColors.waTextPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Media (if exists)
        if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildImageContent(context),
          ),

        // Content Message (moved here - above buttons)
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMe
                    ? AppColors.waTextPrimaryDark
                    : AppColors.waTextPrimaryLight,
                fontSize: 15,
              ),
            ),
          ),

        // Footer (if exists)
        if (message.footer != null && message.footer!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.footer!,
              style: TextStyle(
                color: isMe
                    ? AppColors.waTextSecondaryDark
                    : AppColors.waTextSecondaryLight,
                fontSize: 13,
              ),
            ),
          ),

        // Buttons
        if (message.buttons != null && message.buttons!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: message.buttons!.map((button) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildInteractiveButton(button, isMe, context),
                );
              }).toList(),
            ),
          ),

        // Template Badge
        if (message.isTemplateMessage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 14,
                    color: isMe ? Colors.white70 : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Template Message',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Build Interactive Button (Read-only version - clickable code commented)
  Widget _buildInteractiveButton(
    InteractiveButton button,
    bool isMe,
    BuildContext context,
  ) {
    IconData icon;
    Color iconColor = isMe ? AppColors.waTextPrimaryDark : AppColors.primary;

    switch (button.type) {
      case 'URL':
        icon = Icons.link;
        break;
      case 'PHONE_NUMBER':
        icon = Icons.phone;
        break;
      case 'COPY_CODE':
        icon = Icons.content_copy;
        break;
      case 'QUICK_REPLY':
      default:
        icon = Icons.reply;
    }

    return Container(
      width: Responsive.isMobile(context)
          ? MediaQuery.of(context).size.width * 0.50
          : MediaQuery.of(context).size.width * 0.30,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isMe
              ? AppColors.waTextPrimaryDark.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isMe
            ? AppColors.waTextPrimaryDark.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              button.text,
              style: TextStyle(
                color: isMe ? AppColors.waTextPrimaryDark : AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // ==========================================
    // Mark: CLICKABLE VERSION (UNCOMMENT TO USE)
    // ==========================================
    /*
    return InkWell(
      onTap: () => _handleButtonClick(button, context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isMe ? Colors.white.withValues(alpha:0.5) : Colors.blue.withValues(alpha:0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isMe 
              ? Colors.white.withValues(alpha:0.1)
              : Colors.blue.withValues(alpha:0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                button.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    */
  }

  // Handle Button Click (Uncomment when enabling clickable buttons)
  /*
  void _handleButtonClick(InteractiveButton button, BuildContext context) async {
    switch (button.type) {
      case 'URL':
        if (button.url != null) {
          final uri = Uri.parse(button.url!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      
      case 'PHONE_NUMBER':
        if (button.phoneNumber != null) {
          final uri = Uri.parse('tel:${button.phoneNumber}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
        break;
      
      case 'COPY_CODE':
        if (button.payload != null) {
          await Clipboard.setData(ClipboardData(text: button.payload!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code copied: ${button.payload}'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;
      
      case 'QUICK_REPLY':
        // Handle quick reply - you can trigger a message send here
        print('Quick reply: ${button.text}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quick reply: ${button.text}'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }
  */

  Widget _buildMediaContent(BuildContext context) {
    if (message.messageType == MessageType.image) {
      return _buildImageContent(context);
    } else if (message.messageType == MessageType.document) {
      return _buildDocumentContent(context);
    }
    return SizedBox.shrink();
  }

  Widget _buildImageContent(BuildContext context) {
    if (message.mediaUrl == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: ShimmerWidget.rectangular(height: 200)),
      );
    }

    return GestureDetector(
      onTap: () => _openImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          height: MediaQuery.of(context).size.height * 0.25,
          width: Responsive.isMobile(context)
              ? MediaQuery.of(context).size.width * 0.50
              : MediaQuery.of(context).size.width * 0.30,
          fit: BoxFit.cover,
          httpHeaders: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET',
          },
          placeholder: (context, url) => Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: Responsive.isMobile(context)
                ? MediaQuery.of(context).size.width * 0.50
                : MediaQuery.of(context).size.width * 0.30,
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleShimmer(size: 30),
                  const SizedBox(height: 8),
                  const Text('Loading...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.25,
              width: Responsive.isMobile(context)
                  ? MediaQuery.of(context).size.width * 0.50
                  : MediaQuery.of(context).size.width * 0.30,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Failed to load image', textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(
                    error.toString().length > 50
                        ? '${error.toString().substring(0, 50)}...'
                        : error.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context) {
    final isMe = message.isFromMe;
    return InkWell(
      onTap: message.mediaUrl != null ? () => _openDocument() : null,
      child: Container(
        width: Responsive.isMobile(context)
            ? MediaQuery.of(context).size.width * 0.50
            : MediaQuery.of(context).size.width * 0.30,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.waTextPrimaryDark.withValues(alpha: 0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getDocumentIcon(),
              size: 40,
              color: isMe ? AppColors.waTextPrimaryDark : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isMe
                          ? AppColors.waTextPrimaryDark
                          : AppColors.waTextPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? AppColors.waTextSecondaryDark
                          : AppColors.waTextSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download,
              size: 20,
              color: isMe
                  ? AppColors.waTextPrimaryDark
                  : AppColors.waTextSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    final fileName = message.fileName?.toLowerCase() ?? '';
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    }
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  void _openImage(BuildContext context) {
    if (message.mediaUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDocument() async {
    if (message.mediaUrl == null) return;

    final uri = Uri.parse(message.mediaUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStatusIcon(MessageStatus status, bool isMe) {
    switch (status) {
      case MessageStatus.sending:
        return const CircleShimmer(size: 12);
      case MessageStatus.invocationSucceeded:
        return Icon(
          Icons.watch_later_outlined,
          size: 16,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: isMe
              ? AppColors.waTextSecondaryDark
              : AppColors.waTextSecondaryLight,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 16,
          color: isMe
              ? AppColors.waTextSecondaryDark
              : AppColors.waTextSecondaryLight,
        );

      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 16,
          color: Color(0xFF74F6FF),
        ); // icon color for read
      case MessageStatus.failed:
        return Icon(Icons.close, size: 16, color: Colors.red);
    }
  }

  void _showMessageMenu(
    BuildContext context,
    LongPressStartDetails details,
  ) async {
    if (message.content.isEmpty) return;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx + 1,
        details.globalPosition.dy + 1,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Text'),
            ],
          ),
        ),
      ],
    );

    if (result == 'copy') {
      _copyMessage(context);
    }
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content)).then((_) {
      Utilities.showSnackbar(SnackType.SUCCESS, 'Message copied to clipboard');
    });
  }

  void _showTemplateSelectionDialog(BuildContext context) {
    final chatsController = Get.find<ChatsController>();
    final chat = chatsController.selectedChat.value;

    if (chat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active chat found')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          SendTemplateDialog(chatId: chat.id, phoneNumber: chat.phoneNumber),
    );
  }
}
