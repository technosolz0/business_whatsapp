import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastModel {
  String? id;
  final String broadcastName;
  final String description;

  /// 0 = All, 1 = Import, 2 = Custom
  final int audienceType;
  final int? invocationFailures;
  final int? failed;
  final String status;
  final DateTime? completedAt;
  final int? delivered;
  final int? sent;
  final int? read;

  final String? templateId;
  final String? templateName;
  final String? language;
  final List<dynamic>? templateVariables;

  final String? mediaId;
  final String? attachmentId;

  /// Contact IDs selected
  final List<String> contactIds;

  /// deliveryTime => { type: 0/1/null , timestamp: null }
  final int? deliveryType; // null = not scheduled yet
  final DateTime? deliveryTimestamp;

  /// Admin who created the broadcast
  final String? adminName;
  final String? adminId;

  /// Total cost of the broadcast
  final double? totalCost;

  final int? clicks;
  final int? replied;
  final bool? enableRetry;
  final String? retryCampaignStatus;
  final List<dynamic>? cardVariables;
  final List<String>? cardAttachmentIds;

  BroadcastModel({
    required this.id,
    required this.broadcastName,
    required this.description,
    required this.audienceType,
    required this.status,
    required this.contactIds,
    required this.completedAt,
    this.delivered,
    this.sent,
    this.read,
    this.invocationFailures,
    this.failed,
    this.templateId,
    this.templateName,
    this.language,
    this.templateVariables,
    this.mediaId,
    this.attachmentId,
    this.deliveryType,
    this.deliveryTimestamp,
    this.adminName,
    this.adminId,
    this.totalCost,
    this.clicks,
    this.replied,
    this.enableRetry,
    this.retryCampaignStatus,
    this.cardVariables,
    this.cardAttachmentIds,
  });

  /// -------------------------------
  /// Firestore → Model
  /// -------------------------------
  factory BroadcastModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final deliveryData = data['deliveryTime'];

    return BroadcastModel(
      id: doc.id,
      broadcastName: data['broadcastName'] ?? '',
      description: data['description'] ?? '',
      audienceType: data['audienceType'] ?? 0,
      status: data['status'] ?? 'draft',

      delivered: data['delivered'],
      sent: data['sent'],
      read: data['read'],
      invocationFailures: data['invocationFailures'],
      failed: data['failed'],
      templateId: data['templateId'],
      templateName: data['templateName'] ?? data['template_name'],
      language: data['language'],
      templateVariables: data['templateVariables'] != null
          ? List<dynamic>.from(data['templateVariables'])
          : null,

      mediaId: data['mediaId'],
      attachmentId: data['attachmentId'],

      contactIds: data['contactIds'] != null
          ? List<String>.from(data['contactIds'])
          : [],

      deliveryType: deliveryData?['type'],
      deliveryTimestamp: (deliveryData?['timestamp'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      adminName: data['adminName'],
      adminId: data['adminId'],
      totalCost: (data['totalCost'] as num?)?.toDouble(),

      clicks: data['clicks'],
      replied: data['replied'],
      enableRetry: data['enableRetry'],
      retryCampaignStatus: data['retryCampaignStatus'],
      cardVariables: data['cardVariables'] != null
          ? List<dynamic>.from(data['cardVariables'])
          : null,
      cardAttachmentIds: data['cardAttachmentIds'] != null
          ? List<String>.from(data['cardAttachmentIds'])
          : null,
    );
  }

  /// -------------------------------
  /// JSON (API) → Model
  /// -------------------------------
  factory BroadcastModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final deliveryData = json['deliveryTime'];

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    return BroadcastModel(
      id: id ?? json['id']?.toString() ?? json['broadcastId']?.toString(),
      broadcastName: json['broadcastName'] ?? json['broadcast_name'] ?? '',
      description: json['description'] ?? '',
      audienceType: json['audienceType'] ?? json['audience_type'] ?? 0,
      status: json['status'] ?? 'draft',

      delivered: json['delivered'],
      sent: json['sent'],
      read: json['read'],
      invocationFailures: json['invocationFailures'] ?? json['invocation_failures'],
      failed: json['failed'],
      templateId: json['templateId'] ?? json['template_id'],
      templateName: json['templateName'] ?? json['template_name'],
      language: json['language'],
      templateVariables: json['templateVariables'] ?? json['template_variables'],

      mediaId: json['mediaId'] ?? json['media_id'],
      attachmentId: json['attachmentId'] ?? json['attachment_id'],

      contactIds: json['contactIds'] != null
          ? List<String>.from(json['contactIds'])
          : json['contact_ids'] != null
          ? List<String>.from(json['contact_ids'])
          : [],

      deliveryType: deliveryData is Map ? deliveryData['type'] : json['delivery_type'],
      deliveryTimestamp: parseDateTime(deliveryData is Map ? deliveryData['timestamp'] : (json['delivery_timestamp'] ?? json['delivery_time'])),
      completedAt: parseDateTime(json['completedAt'] ?? json['completed_at']),
      adminName: json['adminName'] ?? json['admin_name'],
      adminId: json['adminId'] ?? json['admin_id'],
      totalCost: (json['totalCost'] ?? json['total_cost'] ?? 0.0) as double?,

      clicks: json['clicks'],
      replied: json['replied'],
      enableRetry: json['enableRetry'] ?? json['enable_retry'],
      retryCampaignStatus: json['retryCampaignStatus'] ?? json['retry_campaign_status'],
      cardVariables: json['cardVariables'] ?? json['card_variables'],
      cardAttachmentIds: json['cardAttachmentIds'] != null
          ? List<String>.from(json['cardAttachmentIds'])
          : json['card_attachment_ids'] != null
          ? List<String>.from(json['card_attachment_ids'])
          : null,
    );
  }

  /// -------------------------------
  /// Model → Firestore
  /// -------------------------------
  Map<String, dynamic> toFirestore() {
    return {
      'broadcastName': broadcastName,
      'description': description,
      'audienceType': audienceType,
      'status': status,

      'delivered': delivered,
      'sent': sent,
      'read': read,
      'adminName': adminName,
      'adminId': adminId,
      'templateId': templateId,
      'templateName': templateName,
      'language': language,
      'templateVariables': templateVariables,
      'mediaId': mediaId,
      'attachmentId': attachmentId,

      'contactIds': contactIds,

      'deliveryTime': {'type': deliveryType, 'timestamp': deliveryTimestamp},
      'totalCost': totalCost,

      'clicks': clicks,
      'replied': replied,
      'enableRetry': enableRetry,
      'retryCampaignStatus': retryCampaignStatus,
      'cardVariables': cardVariables,
      'cardAttachmentIds': cardAttachmentIds,

      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// -------------------------------
  /// JSON for HTTP REST API
  /// -------------------------------
  Map<String, dynamic> toApiJson() {
    return {
      'broadcastName': broadcastName,
      'description': description,
      'audienceType': audienceType,
      'status': status,

      'delivered': delivered,
      'sent': sent,
      'read': read,
      'adminName': adminName,
      'adminId': adminId,
      'templateId': templateId,
      'templateName': templateName,
      'language': language,
      'templateVariables': templateVariables,
      'mediaId': mediaId,
      'attachmentId': attachmentId,

      'contactIds': contactIds,

      'deliveryTime': {
        'type': deliveryType,
        'timestamp': deliveryTimestamp?.toUtc().toIso8601String(),
      },
      'deliveryType': deliveryType,
      'deliveryTimestamp': deliveryTimestamp?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'totalCost': totalCost,

      'clicks': clicks,
      'replied': replied,
      'enableRetry': enableRetry,
      'retryCampaignStatus': retryCampaignStatus,
      'cardVariables': cardVariables,
      'cardAttachmentIds': cardAttachmentIds,

      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// -------------------------------
  /// Minimal JSON for saving a DRAFT
  /// -------------------------------
  Map<String, dynamic> toDraftJson() {
    return {
      "broadcastName": broadcastName,
      "description": description,
      "audienceType": audienceType, // 0 = All, 1 = Import, 2 = Custom
      "status": status, // "draft"
      "contactIds": contactIds, // List<String>
      'adminName': adminName,
      'adminId': adminId,
      // Timestamps
      "createdAt": DateTime.now().toUtc().toIso8601String(),
      "updatedAt": DateTime.now().toUtc().toIso8601String(),
    };
  }

  BroadcastModel copyWith({
    String? id,
    String? broadcastName,
    String? description,
    int? audienceType,
    String? status,
    int? delivered,
    int? sent,
    int? read,
    String? templateId,
    String? templateName,
    String? language,
    List<dynamic>? templateVariables,
    String? mediaId,
    String? attachmentId,
    List<String>? contactIds,
    int? deliveryType,
    DateTime? deliveryTimestamp,
    String? adminName,
    String? adminId,
    double? totalCost,
    int? clicks,
    int? replied,
    bool? enableRetry,
    String? retryCampaignStatus,
    List<dynamic>? cardVariables,
    List<String>? cardAttachmentIds,
  }) {
    return BroadcastModel(
      id: id ?? this.id,
      broadcastName: broadcastName ?? this.broadcastName,
      description: description ?? this.description,
      audienceType: audienceType ?? this.audienceType,
      status: status ?? this.status,

      delivered: delivered ?? this.delivered,
      sent: sent ?? this.sent,
      read: read ?? this.read,

      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      language: language ?? this.language,
      templateVariables: templateVariables ?? this.templateVariables,

      mediaId: mediaId ?? this.mediaId,
      attachmentId: attachmentId ?? this.attachmentId,

      contactIds: contactIds ?? this.contactIds,

      deliveryType: deliveryType ?? this.deliveryType,
      deliveryTimestamp: deliveryTimestamp ?? this.deliveryTimestamp,
      completedAt: null,
      adminName: adminName ?? this.adminName,
      adminId: adminId ?? this.adminId,
      totalCost: totalCost ?? this.totalCost,

      clicks: clicks ?? this.clicks,
      replied: replied ?? this.replied,
      enableRetry: enableRetry ?? this.enableRetry,
      retryCampaignStatus: retryCampaignStatus ?? this.retryCampaignStatus,
      cardVariables: cardVariables ?? this.cardVariables,
      cardAttachmentIds: cardAttachmentIds ?? this.cardAttachmentIds,
    );
  }

  //Normalization Methods
  // Inside BroadcastModel class
  static String normalizeAudienceType(int? type) {
    switch (type) {
      case 0:
        return "All Contacts";
      case 1:
        return "Imported Contacts";
      case 2:
        return "Custom Contacts";
      default:
        return "Unknown Audience";
    }
  }

  static String normalizeDeliveryType(int? type) {
    switch (type) {
      case 0:
        return "Immediate";
      case 1:
        return "Scheduled";
      default:
        return "Not Set";
    }
  }

  static String normalizeStatus(String? status) {
    switch ((status ?? "").toLowerCase()) {
      case "draft":
        return "Draft";
      case "scheduled":
        return "Scheduled";
      case "pending":
        return "Pending";
      case "sent":
        return "Sent";
      case "completed":
        return "Completed";
      case "failed":
        return "Failed";
      default:
        return "Unknown";
    }
  }
}
