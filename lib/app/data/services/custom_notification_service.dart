import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/custom_notification_model.dart';

class CustomNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'custom_notifications';

  Future<List<CustomNotificationModel>> getNotifications() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CustomNotificationModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createNotification(CustomNotificationModel notification) async {
    await _firestore.collection(_collection).add(notification.toJson());
  }

  Future<void> updateNotification(CustomNotificationModel notification) async {
    if (notification.id == null) return;
    final data = notification.toJson();
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection(_collection).doc(notification.id).update(data);
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
