import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final DateTime startDate;
  final DateTime expiryDate;
  final int validityDays;
  final String status;
  final DateTime? lastRenewedAt;

  Subscription({
    required this.startDate,
    required this.expiryDate,
    required this.validityDays,
    required this.status,
    this.lastRenewedAt,
  });

  factory Subscription.fromFirestore(Map<String, dynamic> data) {
    return Subscription(
      startDate: (data['startDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      validityDays: data['validityDays'] ?? 0,
      status: data['status'] ?? 'inactive',
      lastRenewedAt: data['lastRenewedAt'] != null
          ? (data['lastRenewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isActive => status == 'active';
}
