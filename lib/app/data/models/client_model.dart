import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  String? id;
  String name;
  String phoneNumber;
  String phoneNumberId;
  String wabaId;
  String webhookVerifyToken;
  String? logoUrl;
  String status; // "Approved", "Rejected", "Pending"
  int adminLimit;
  DateTime createdAt;
  DateTime updatedAt;

  ClientModel({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.phoneNumberId,
    required this.wabaId,
    required this.webhookVerifyToken,
    this.logoUrl,
    this.status = 'Pending',
    this.adminLimit = 2,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ClientModel.fromJson(Map<String, dynamic> json, String id) {
    return ClientModel(
      id: id,
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      phoneNumberId: json['phoneNumberId'] ?? '',
      wabaId: json['wabaId'] ?? '',
      webhookVerifyToken: json['webhookVerifyToken'] ?? '',
      logoUrl: json['logoUrl'],
      status: json['status'] ?? 'Pending',
      adminLimit: json['admin_limit'] ?? 2,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'phoneNumberId': phoneNumberId,
      'wabaId': wabaId,
      'webhookVerifyToken': webhookVerifyToken,
      'logoUrl': logoUrl,
      'status': status,
      'admin_limit': adminLimit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? phoneNumberId,
    String? wabaId,
    String? webhookVerifyToken,
    String? logoUrl,
    String? status,
    int? adminLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      wabaId: wabaId ?? this.wabaId,
      webhookVerifyToken: webhookVerifyToken ?? this.webhookVerifyToken,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      adminLimit: adminLimit ?? this.adminLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
