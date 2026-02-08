import 'dart:typed_data';
import 'package:business_whatsapp/main.dart';

import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class BroadcastService {
  BroadcastService._();
  static final instance = BroadcastService._();

  final String cloudFunctionUrl = "https://uploadbroadcastmedia ";
  final String sendTemplateUrl = "https://sendwhatsapptemplatemessage ";
  final _dio = NetworkUtilities.getDioClient();

  /// ------------------------------------------------------------------
  /// 🔥 Upload Media to Firebase Cloud Function → Interakt (DIO)
  /// ------------------------------------------------------------------
  Future<Map<String, dynamic>> uploadBroadcastMedia({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      // --------------------------------------------------
      // Build Multipart Form Data
      // --------------------------------------------------
      final formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
        "clientId": clientID,
      });

      // --------------------------------------------------
      // Send POST request to Cloud Function
      // --------------------------------------------------
      final response = await _dio.post(
        cloudFunctionUrl,
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
          headers: {"Accept": "application/json"},
        ),
      );

      final data = response.data;

      if (response.statusCode == 200 && data["success"] == true) {
        return {"success": true, "media_id": data["media_id"]};
      }

      return {"success": false, "message": data};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendTemplateMessage({
    required String templateName,
    required String language,
    required String type,
    required String mobileNo,
    required List<String> bodyVariables,
    String? headerType,
    String? headerVar,
    String? mediaId,
    String? fileName,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "template": templateName,
        "language": language,
        "type": type,
        "mobileNo": mobileNo,
        "bodyVariables": bodyVariables,
        "clientId": clientID,
      };

      /// Add headerVariables ONLY when type == MEDIA
      ///
      switch (type.toUpperCase()) {
        case "TEXT":
          // No headerVariables needed
          if (headerVar != null) {
            payload["headerVariables"] = {"type": type, "text": headerVar};
          }
          break;
        case "MEDIA":
          payload["headerVariables"] = {
            "type": headerType ?? "",
            "data": {"mediaId": mediaId ?? "", "fileName": fileName ?? ""},
          };
          break;
        default:
          // Handle other types if necessary
          break;
      }
      // if (type.toUpperCase() == "MEDIA") {
      //   payload["headerVariables"] = {
      //     "type": headerType ?? "",
      //     "data": mediaId ?? "",
      //     "fileName": fileName ?? "",
      //   };
      // }

      final response = await _dio.post(sendTemplateUrl, data: payload);

      final data = response.data;

      return {
        "success": data["success"] ?? false,
        "data": data["data"],
        "message": data["message"],
      };
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
