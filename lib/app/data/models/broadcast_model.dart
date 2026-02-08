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

  /// Total cost of the broadcast
  final double? totalCost;

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
    this.templateVariables,
    this.mediaId,
    this.attachmentId,
    this.deliveryType,
    this.deliveryTimestamp,
    this.adminName,
    this.totalCost,
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
      totalCost: (data['totalCost'] as num?)?.toDouble(),
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
      'templateId': templateId,
      'templateVariables': templateVariables,
      'mediaId': mediaId,
      'attachmentId': attachmentId,

      'contactIds': contactIds,

      'deliveryTime': {'type': deliveryType, 'timestamp': deliveryTimestamp},
      'totalCost': totalCost,

      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
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
      // Timestamps
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
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
    List<dynamic>? templateVariables,
    String? mediaId,
    String? attachmentId,
    List<String>? contactIds,
    int? deliveryType,
    DateTime? deliveryTimestamp,
    String? adminName,
    double? totalCost,
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
      templateVariables: templateVariables ?? this.templateVariables,

      mediaId: mediaId ?? this.mediaId,
      attachmentId: attachmentId ?? this.attachmentId,

      contactIds: contactIds ?? this.contactIds,

      deliveryType: deliveryType ?? this.deliveryType,
      deliveryTimestamp: deliveryTimestamp ?? this.deliveryTimestamp,
      completedAt: null,
      adminName: adminName ?? this.adminName,
      totalCost: totalCost ?? this.totalCost,
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
