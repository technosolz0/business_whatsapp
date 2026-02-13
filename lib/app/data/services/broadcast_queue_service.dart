import 'package:adminpanel/app/Utilities/network_utilities.dart';
import 'package:adminpanel/main.dart';
import 'package:dio/dio.dart';

class BroadcastQueueService {
  static final Dio _dio = NetworkUtilities.getDioClient();
  static String url = "https://pubmessagestotopic-d3b4t36f7q-uc.a.run.app";

  /// 🔥 POST: Trigger message queue
  static Future<Map<String, dynamic>> queueBroadcast({
    required String broadcastId,
    required bool isScheduled,
    required DateTime scheduledTimestamp,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: {
          "broadcastId": broadcastId,
          "isScheduled": isScheduled,
          "scheduledTimestamp": scheduledTimestamp.toUtc().toIso8601String(),
          "clientId": clientID,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          "success": false,
          "message": "Unexpected response ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: ${e.toString()}"};
    }
  }
}
