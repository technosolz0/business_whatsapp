class BroadcastMessagePayload {
  String broadcastId;
  String? messageId; // <--- now nullable
  final Payload payload;
  final String? status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorCode;
  final String? wamId;
  final double? cost; // Cost per contact for this message

  BroadcastMessagePayload({
    required this.broadcastId,
    this.messageId, // <--- not required
    required this.payload,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorCode,
    this.wamId,
    this.cost,
  });

  Map<String, dynamic> toJson() {
    return {
      'broadcastId': broadcastId,
      'messageId': messageId,
      'payload': payload.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'errorCode': errorCode,
      'wamId': wamId,
      'cost': cost,
    };
  }
}

class Payload {
  final String templateName;
  final String? language;
  final String? type;
  final String? mobileNo;
  final List<String>? bodyVariables;
  final List<BroadcastButton>? buttonVariable;

  // ⭐ New structured headerVariables map
  final Map<String, dynamic>? headerVariables;

  Payload({
    required this.templateName,
    required this.language,
    required this.type,
    required this.mobileNo,
    required this.bodyVariables,
    this.headerVariables,
    this.buttonVariable,
  });

  Map<String, dynamic> toJson() {
    return {
      "template": templateName,
      "language": language,
      "type": type,
      "mobileNo": mobileNo,
      "bodyVariables": bodyVariables,
      "headerVariables": headerVariables,
      "buttonVariables": buttonVariable
          ?.map((btn) => btn.toJson())
          .toList(), // ✅ FIX: Convert objects to JSON
    };
  }
}

class BroadcastButton {
  final String type;
  String? payload;

  BroadcastButton({required this.type, this.payload});

  Map<String, dynamic> toJson() {
    return {"type": type, "payload": payload};
  }
}
