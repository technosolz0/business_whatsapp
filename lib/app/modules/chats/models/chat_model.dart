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
  final List<String>? assignedAdmin;
  final String? leadRecordId;
  final bool isLeadGenerated;

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
    this.assignedAdmin,
    this.leadRecordId,
    this.isLeadGenerated = false,
  }) : _isFavourite = isFavourite;

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      lastMessage: json['last_message'] ?? json['lastMessage'] ?? '',
      lastMessageTime: json['last_message_time'] != null
          ? (json['last_message_time'] is String
                ? json['last_message_time']
                : DateFormat('h:mm a').format(
                    DateTime.parse(json['last_message_time'].toString()),
                  ))
          : '',
      campaignName: json['campaign_name'] ?? json['campaignName'],
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      unRead: json['un_read'] ?? json['unRead'] == true,
      isActive: json['is_active'] ?? json['isActive'] == true,
      isFavourite: json['isFavourite'] == true || json['is_favourite'] == true,
      userLastMessageTime: json['user_last_message_time'] != null
          ? DateTime.parse(json['user_last_message_time'].toString())
          : (json['userLastMessageTime'] != null
                ? DateTime.tryParse(json['userLastMessageTime'].toString())
                : null),
      assignedAdmin: json['assigned_admin'] != null
          ? List<String>.from(json['assigned_admin'])
          : (json['assigned_admins'] != null
                ? List<String>.from(json['assigned_admins'])
                : null),
      leadRecordId: json['leadRecordId'],
      isLeadGenerated: json['isLeadGenerated'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'last_message': lastMessage,
      'last_message_time': userLastMessageTime?.toIso8601String(),
      'campaign_name': campaignName,
      'is_online': isOnline,
      'un_read': unRead,
      'is_active': isActive,
      'is_favourite': isFavourite,
      'user_last_message_time': userLastMessageTime?.toIso8601String(),
      'assigned_admin': assignedAdmin,
      'leadRecordId': leadRecordId,
      'isLeadGenerated': isLeadGenerated,
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
    List<String>? assignedAdmin,
    String? leadRecordId,
    bool? isLeadGenerated,
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
      assignedAdmin: assignedAdmin ?? this.assignedAdmin,
      leadRecordId: leadRecordId ?? this.leadRecordId,
      isLeadGenerated: isLeadGenerated ?? this.isLeadGenerated,
    );
  }
}
