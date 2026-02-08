// ============================================================
// 📁 lib/app/modules/chats/models/chat_model.dart
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? avatarUrl;
  final String lastMessage;
  final String lastMessageTime;
  final String? campaignName;
  final bool isOnline;
  final bool unRead;
  final bool isActive;
  final bool? _isFavourite;
  final DateTime? userLastMessageTime;

  bool get isFavourite => _isFavourite ?? false;

  String get lastMessageTimeFormatted {
    if (userLastMessageTime == null) return lastMessageTime;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      userLastMessageTime!.year,
      userLastMessageTime!.month,
      userLastMessageTime!.day,
    );

    if (messageDate == today) {
      return DateFormat('h:mm a').format(userLastMessageTime!);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(userLastMessageTime!);
    }
  }

  ChatModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.avatarUrl,
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.campaignName,
    this.isOnline = false,
    this.unRead = false,
    this.isActive = false,
    bool? isFavourite,
    this.userLastMessageTime,
  }) : _isFavourite = isFavourite;

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      avatarUrl: data['avatarUrl'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? DateFormat(
              'h:mm a',
            ).format((data['lastMessageTime'] as Timestamp).toDate())
          : '',
      campaignName: data['campaignName'],
      isOnline: data['isOnline'] ?? false,
      unRead: data['unRead'] == true,
      isActive: data['isActive'] == true,
      isFavourite: data['isFavourite'] == true,
      userLastMessageTime: data['userLastMessageTime'] != null
          ? (data['userLastMessageTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'campaignName': campaignName,
      'isOnline': isOnline,
      'unRead': unRead,
      'isActive': isActive,
      'isFavourite': isFavourite,
      'createdAt': FieldValue.serverTimestamp(),
      'userLastMessageTime': userLastMessageTime != null
          ? Timestamp.fromDate(userLastMessageTime!)
          : null,
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? avatarUrl,
    String? lastMessage,
    String? lastMessageTime,
    String? campaignName,
    bool? isOnline,
    bool? unRead,
    bool? isActive,
    bool? isFavourite,
    DateTime? userLastMessageTime,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      campaignName: campaignName ?? this.campaignName,
      isOnline: isOnline ?? this.isOnline,
      unRead: unRead ?? this.unRead,
      isActive: isActive ?? this.isActive,
      isFavourite: isFavourite ?? this.isFavourite,
      userLastMessageTime: userLastMessageTime ?? this.userLastMessageTime,
    );
  }
}
