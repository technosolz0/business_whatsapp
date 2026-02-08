import 'package:business_whatsapp/app/data/models/subscription_model.dart';
import 'package:business_whatsapp/app/data/services/subscription_service.dart';
import 'package:business_whatsapp/app/data/services/broadcast_firebase_service.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  RxInt usedQuota = 0.obs;
  RxInt activeBroadcastCount = 0.obs;
  final Rxn<Subscription> subscription = Rxn<Subscription>();

  @override
  void onInit() {
    super.onInit();
    getBroadcastData();
    // Reactively bind to the global subscription state
    subscription.bindStream(SubscriptionService.instance.subscription.stream);
  }

  void getBroadcastData() async {
    usedQuota.value = await BroadcastFirebaseService.instance.getUsedQuota();
    activeBroadcastCount.value = await BroadcastFirebaseService.instance
        .getActiveBroadcastCount();
  }
}
