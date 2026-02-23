import 'dart:async';
import 'package:business_whatsapp/app/data/models/subscription_model.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SubscriptionService extends GetxService {
  static SubscriptionService get instance => Get.find();

  final Rxn<Subscription> subscription = Rxn<Subscription>();
  StreamSubscription? _subscriptionListener;

  Future<SubscriptionService> init() async {
    startListening();
    return this;
  }

  void startListening() {
    // Always cancel existing listener first
    _subscriptionListener?.cancel();

    if (clientID.isEmpty) {
      subscription.value = null; // Reset subscription if clientID is empty
      return;
    }

    _subscriptionListener = FirebaseFirestore.instance
        .collection('profile')
        .doc(clientID)
        .collection('data')
        .doc('subscriptions')
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists && doc.data() != null) {
             final sub = Subscription.fromFirestore(doc.data()!);
              subscription.value = sub;
              validateSubscription(sub);
            } else {
              subscription.value = null;
            }
          },
          onError: (e) {
            print('Error listening to subscription: $e');
          },
        );
  }

  // Deprecated: Use startListening or observe 'subscription' variable instead.
  Future<void> fetchSubscription() async {
    if (_subscriptionListener == null) {
      startListening();
    }
  }

  Future<void> validateSubscription(Subscription sub) async {
    // Only update if it's currently active but expired
    if (DateTime.now().isAfter(sub.expiryDate) && sub.status == 'active') {
      try {
        await FirebaseFirestore.instance
            .collection('profile')
            .doc(clientID)
            .collection('data')
            .doc('subscriptions')
            .update({'status': 'expired'});
      } catch (e) {
        print('Error updating subscription status: $e');
      }
    }
  }

  Future<void> renewSubscription() async {
    if (clientID.isEmpty) return;

    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 365));

    await FirebaseFirestore.instance
        .collection('profile')
        .doc(clientID)
        .collection('data')
        .doc('subscriptions')
        .update({
          'startDate': now,
          'expiryDate': expiry,
          'validityDays': 365,
          'status': 'active',
          'lastRenewedAt': now,
        });
  }

  bool shouldShowRenewalWarning() {
    if (subscription.value == null) return false;
    final now = DateTime.now();
    final daysLeft = subscription.value!.expiryDate.difference(now).inDays;
    return daysLeft <= 6 && daysLeft >= 0;
  }

  @override
  void onClose() {
    _subscriptionListener?.cancel();
    super.onClose();
  }
}

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  static PremiumService get instance => _instance;

  PremiumService._internal();

  Future<bool> isPremiumEnabled() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profile')
          .doc(clientID)
          .collection('data')
          .doc('premium')
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['status'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Reactive stream for premium status
  Stream<bool> premiumStatusStream() {
    return FirebaseFirestore.instance
        .collection('profile')
        .doc(clientID)
        .collection('data')
        .doc('premium')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data();
            return data?['status'] == true;
          }
          return false;
        });
  }
}
