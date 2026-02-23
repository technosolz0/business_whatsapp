// // ============================================================
// // 📁 lib/app/modules/chats/models/message_model.dart
// // ============================================================
// import 'package:cloud_firestore/cloud_firestore.dart';

// enum MessageStatus { sending, sent, delivered, read, failed }

// enum MessageType { text, image, document, video, audio }

// class MessageModel {
//   final String id;
//   final String content;
//   final DateTime timestamp;
//   final bool isFromMe;
//   final MessageStatus status;
//   final String? senderName;
//   final String? senderAvatar;
//   final String? whatsappMessageId;
//   final MessageType messageType;
//   final String? mediaUrl;
//   final String? fileName;
//   final String? caption;

//   MessageModel({
//     required this.id,
//     required this.content,
//     required this.timestamp,
//     required this.isFromMe,
//     this.senderName,
//     this.senderAvatar,
//     this.status = MessageStatus.sending,
//     this.whatsappMessageId,
//     this.messageType = MessageType.text,
//     this.mediaUrl,
//     this.fileName,
//     this.caption,
//   });

//   factory MessageModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     MessageType msgType = MessageType.text;
//     try {
//       msgType = MessageType.values.firstWhere(
//         (x) => x.name == (data['messageType'] ?? 'text'),
//         orElse: () => MessageType.text,
//       );
//     } catch (e) {
//       msgType = MessageType.text;
//     }

//     return MessageModel(
//       id: doc.id,
//       content: data['content'] ?? '',
//       timestamp: (data['timestamp'] as Timestamp).toDate(),
//       isFromMe: data['isFromMe'] ?? false,
//       senderName: data['senderName'],
//       senderAvatar: data['senderAvatar'],
//       whatsappMessageId: data['whatsappMessageId'],
//       messageType: msgType,
//       mediaUrl: data['mediaUrl'],
//       fileName: data['fileName'],
//       caption: data['caption'],
//       status: MessageStatus.values.firstWhere(
//         (x) => x.name == (data['status'] ?? 'sent'),
//         orElse: () => MessageStatus.sent,
//       ),
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'content': content,
//       'timestamp': Timestamp.fromDate(timestamp),
//       'isFromMe': isFromMe,
//       'senderName': senderName,
//       'senderAvatar': senderAvatar,
//       'status': status.name,
//       'whatsappMessageId': whatsappMessageId,
//       'messageType': messageType.name,
//       'mediaUrl': mediaUrl,
//       'fileName': fileName,
//       'caption': caption,
//     };
//   }

//   MessageModel copyWith({
//     String? id,
//     String? content,
//     DateTime? timestamp,
//     bool? isFromMe,
//     MessageStatus? status,
//     String? senderName,
//     String? senderAvatar,
//     String? whatsappMessageId,
//     MessageType? messageType,
//     String? mediaUrl,
//     String? fileName,
//     String? caption,
//   }) {
//     return MessageModel(
//       id: id ?? this.id,
//       content: content ?? this.content,
//       timestamp: timestamp ?? this.timestamp,
//       isFromMe: isFromMe ?? this.isFromMe,
//       status: status ?? this.status,
//       senderName: senderName ?? this.senderName,
//       senderAvatar: senderAvatar ?? this.senderAvatar,
//       whatsappMessageId: whatsappMessageId ?? this.whatsappMessageId,
//       messageType: messageType ?? this.messageType,
//       mediaUrl: mediaUrl ?? this.mediaUrl,
//       fileName: fileName ?? this.fileName,
//       caption: caption ?? this.caption,
//     );
//   }

//   // Helper getters
//   bool get isMediaMessage => messageType != MessageType.text;
//   bool get isImage => messageType == MessageType.image;
//   bool get isDocument => messageType == MessageType.document;
//   bool get isVideo => messageType == MessageType.video;
//   bool get isAudio => messageType == MessageType.audio;
// }

// ============================================================
// 📁 lib/app/modules/chats/models/message_model.dart
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  sending,
  invocationSucceeded,
  sent,
  delivered,
  read,
  failed,
}

enum MessageType { text, image, document, video, audio, interactive }

// Button model for interactive messages
class InteractiveButton {
  final String text;
  final String type; // QUICK_REPLY, URL, PHONE_NUMBER, COPY_CODE
  final String? url;
  final String? phoneNumber;
  final String? payload;

  InteractiveButton({
    required this.text,
    required this.type,
    this.url,
    this.phoneNumber,
    this.payload,
  });

  factory InteractiveButton.fromMap(Map<String, dynamic> map) {
    return InteractiveButton(
      text: map['text'] ?? '',
      type: map['type'] ?? 'QUICK_REPLY',
      url: map['url'],
      phoneNumber: map['phoneNumber'],
      payload: map['payload'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type,
      'url': url,
      'phoneNumber': phoneNumber,
      'payload': payload,
    };
  }
}

class MessageModel {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFromMe;
  final MessageStatus status;
  final String? senderName;
  final String? senderAvatar;
  final String? whatsappMessageId;
  final MessageType messageType;
  final String? mediaUrl;
  final String? fileName;
  final String? caption;
  final String? errorDescription;

  // Interactive message fields
  final List<InteractiveButton>? buttons;
  final String? header;
  final String? footer;
  final bool isTemplateMessage;

  MessageModel({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFromMe,
    this.senderName,
    this.senderAvatar,
    this.status = MessageStatus.sending,
    this.whatsappMessageId,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.caption,
    this.buttons,
    this.header,
    this.footer,
    this.isTemplateMessage = false,
    this.errorDescription,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    MessageType msgType = MessageType.text;
    try {
      msgType = MessageType.values.firstWhere(
        (x) =>
            x.name == (json['message_type'] ?? json['messageType'] ?? 'text'),
        orElse: () => MessageType.text,
      );
    } catch (e) {
      msgType = MessageType.text;
    }

    List<InteractiveButton>? buttons;
    if (json['buttons'] != null && json['buttons'] is List) {
      buttons = (json['buttons'] as List)
          .map((btn) => InteractiveButton.fromMap(btn as Map<String, dynamic>))
          .toList();
    }

    return MessageModel(
      id: (json['id'] ?? '').toString(),
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is String
                ? DateTime.parse(json['timestamp'])
                : (json['timestamp'] as Timestamp).toDate())
          : DateTime.now(),
      isFromMe: json['is_from_me'] ?? json['isFromMe'] ?? false,
      senderName: json['sender_name'] ?? json['senderName'],
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'],
      whatsappMessageId:
          json['whatsapp_message_id'] ?? json['whatsappMessageId'],
      messageType: msgType,
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      fileName: json['file_name'] ?? json['fileName'],
      caption: json['caption'],
      buttons: buttons,
      header: json['header'],
      footer: json['footer'],
      isTemplateMessage:
          json['is_template_message'] ?? json['isTemplateMessage'] ?? false,
      status: MessageStatus.values.firstWhere(
        (x) => x.name == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      errorDescription: json['error_description'] ?? json['errorDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_from_me': isFromMe,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'status': status.name,
      'whatsapp_message_id': whatsappMessageId,
      'message_type': messageType.name,
      'media_url': mediaUrl,
      'file_name': fileName,
      'caption': caption,
      'buttons': buttons?.map((btn) => btn.toMap()).toList(),
      'header': header,
      'footer': footer,
      'is_template_message': isTemplateMessage,
      'error_description': errorDescription,
    };
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    return MessageModel.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isFromMe': isFromMe,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'status': status.name,
      'whatsappMessageId': whatsappMessageId,
      'messageType': messageType.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'caption': caption,
      'buttons': buttons?.map((btn) => btn.toMap()).toList(),
      'header': header,
      'footer': footer,
      'isTemplateMessage': isTemplateMessage,
      'errorDescription': errorDescription,
    };
  }

  MessageModel copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isFromMe,
    MessageStatus? status,
    String? senderName,
    String? senderAvatar,
    String? whatsappMessageId,
    MessageType? messageType,
    String? mediaUrl,
    String? fileName,
    String? caption,
    List<InteractiveButton>? buttons,
    String? header,
    String? footer,
    bool? isTemplateMessage,
    String? errorDescription,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      status: status ?? this.status,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      whatsappMessageId: whatsappMessageId ?? this.whatsappMessageId,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      caption: caption ?? this.caption,
      buttons: buttons ?? this.buttons,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      isTemplateMessage: isTemplateMessage ?? this.isTemplateMessage,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  // Helper getters
  bool get isMediaMessage => messageType != MessageType.text;
  bool get isImage => messageType == MessageType.image;
  bool get isDocument => messageType == MessageType.document;
  bool get isVideo => messageType == MessageType.video;
  bool get isAudio => messageType == MessageType.audio;
  bool get isInteractive => messageType == MessageType.interactive;
}

// Date separator class for chat messages
class DateSeparator {
  final DateTime date;

  DateSeparator(this.date);

  String get displayText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "Dec 25, 2023" or similar
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
