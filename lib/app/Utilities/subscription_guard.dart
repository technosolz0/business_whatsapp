import 'package:business_whatsapp/app/data/services/subscription_service.dart';

class SubscriptionGuard {
  static bool canEdit() {
    final sub = SubscriptionService.instance.subscription.value;
    if (sub == null) return false;
    return sub.isActive && DateTime.now().isBefore(sub.expiryDate);
  }
}
