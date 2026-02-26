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
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      phoneNumberId: json['phone_number_id'] ?? json['phoneNumberId'] ?? '',
      wabaId: json['waba_id'] ?? json['wabaId'] ?? '',
      webhookVerifyToken:
          json['webhook_verify_token'] ?? json['webhookVerifyToken'] ?? '',
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      status: json['status'] ?? 'Pending',
      adminLimit: json['admin_limit'] ?? json['adminLimit'] ?? 2,
      isCRMEnabled:
          json['is_crm_enabled'] == true || json['isCRMEnabled'] == true,
      isPremium: json['is_premium'] ?? json['isPremium'] ?? true,
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.tryParse(json['subscription_expiry'])
          : json['subscription_expiry_date'] != null
          ? DateTime.tryParse(json['subscription_expiry_date'])
          : null,
      walletBalance: (json['wallet_balance'] ?? json['walletBalance'] ?? 0.0)
          .toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'phone_number_id': phoneNumberId,
      'waba_id': wabaId,
      'webhook_verify_token': webhookVerifyToken,
      'logo_url': logoUrl,
      'status': status,
      'admin_limit': adminLimit,
      'is_crm_enabled': isCRMEnabled,
      'is_premium': isPremium,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'wallet_balance': walletBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
