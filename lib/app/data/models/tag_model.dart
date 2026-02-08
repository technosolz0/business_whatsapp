import 'package:cloud_firestore/cloud_firestore.dart';

class TagModel {
  final String id;
  final String name;
  final String? clientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TagModel({
    required this.id,
    required this.name,
    this.clientId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TagModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TagModel(
      id: doc.id,
      name: data['name'],
      clientId: data['clientId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'clientId': clientId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
