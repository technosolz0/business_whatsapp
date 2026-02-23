// Removed Firestore import

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
  bool isCRMEnabled;
  bool isPremium;
  DateTime? subscriptionExpiry;
  double walletBalance;
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
    this.isCRMEnabled = false,
    this.isPremium = true,
    this.subscriptionExpiry,
    this.walletBalance = 0.0,
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
      isCRMEnabled: json['isCRMEnabled'] == true,
      isPremium: json['is_premium'] ?? true,
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.tryParse(json['subscription_expiry'])
          : null,
      walletBalance: (json['wallet_balance'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
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
      'isCRMEnabled': isCRMEnabled,
      'is_premium': isPremium,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'wallet_balance': walletBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    bool? isCRMEnabled,
    bool? isPremium,
    DateTime? subscriptionExpiry,
    double? walletBalance,
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
      isCRMEnabled: isCRMEnabled ?? this.isCRMEnabled,
      isPremium: isPremium ?? this.isPremium,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
