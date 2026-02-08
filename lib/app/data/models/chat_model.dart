class ChatModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String? campaignName;
  final bool isOnline;

  ChatModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.campaignName,
    this.isOnline = false,
  });
}

class MessageModel {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFromMe;
  final MessageStatus status;
  final String? senderName;
  final String? senderAvatar;

  MessageModel({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFromMe,
    this.status = MessageStatus.sent,
    this.senderName,
    this.senderAvatar,
  });
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
