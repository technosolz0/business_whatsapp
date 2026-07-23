import 'package:business_whatsapp/app/modules/chat_bot/controllers/activate_bot_controller.dart';
import 'package:business_whatsapp/app/modules/chat_bot/controllers/bot_question_controller.dart'
    show BotQuestionController;
import 'package:business_whatsapp/app/modules/chat_bot/controllers/train_bot_controller.dart';
import 'package:business_whatsapp/app/modules/chat_bot/services/chat_bot_service.dart';
import 'package:get/get.dart';

class ChatBotBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatBotService>(() => ChatBotService());
    Get.lazyPut<ActivateBotController>(() => ActivateBotController());
    Get.lazyPut<BotQuestionController>(() => BotQuestionController());
    Get.lazyPut<TrainBotController>(() => TrainBotController());
  }
}
