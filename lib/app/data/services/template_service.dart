import 'dart:typed_data';
import 'package:adminpanel/app/data/models/interactive_model.dart';
import 'package:adminpanel/main.dart';
import 'package:http_parser/http_parser.dart';

import 'package:adminpanel/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateService {
  static final TemplateService instance = TemplateService._internal();
  TemplateService._internal();

  final Dio _dio = NetworkUtilities.getDioClient();

  /// Cloud Function URLs
  final String createUrl =
      "https://createinterakttemplate-d3b4t36f7q-uc.a.run.app";
  final String getUrl = "https://getinterakttemplates-d3b4t36f7q-uc.a.run.app";
  final String deleteUrl =
      "https://deleteinterakttemplate-d3b4t36f7q-uc.a.run.app";

  final String uploadMediaUrl =
      'https://uploadmediatointerakt-d3b4t36f7q-uc.a.run.app';

  Future<Map<String, dynamic>> createInteraktTemplate({
    required String name,
    required String language,
    required String category,
    required String body,
    required List<String> bodyExampleValues,
    required String templateType, // 🔥 NEW (Text | Text & Media | Interactive)

    String? header,
    String? footer,
    bool isTextMedia = false,
    String? mediaHandleId, // 🔥 only used for Text & Media
    String? mediaType, // 🔥 IMAGE | VIDEO | DOCUMENT

    List<InteractiveButton>? buttons, // 🔥 Interactive buttons
  }) async {
    try {
      final payload = {
        "clientId": clientID,
        "name": name,
        "language": language,
        "category": category,
        "body": body,
        "bodyExampleValues": bodyExampleValues,
        "isTextMedia": isTextMedia,
        // Header/Footer (optional)
        "header": header,
        "footer": footer,

        // Media header fields
        "media_handle_id": mediaHandleId,
        "mediaType": mediaType,

        // 🔥 NEW: Tell Cloud Function template type
        "templateType": templateType,

        // Buttons (convert objects → maps)
        "buttons": buttons?.map((e) => e.toJson()).toList(),
      };

      final response = await _dio.post(createUrl, data: payload);
      return response.data;
    } on DioException catch (e) {
      return e.response?.data ?? {"success": false, "message": e.message};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getInteraktTemplates({
    int limit = 10,
    String? after,
    String? before,
  }) async {
    try {
      final response = await _dio.get(
        getUrl,
        queryParameters: {
          "limit": limit,
          if (after != null) "after": after,
          if (before != null) "before": before,
          "clientId": clientID,
        },
      );

      return {"success": true, "data": response.data};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data ?? e.message};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ====================================================
  /// ❌ DELETE INTERAKT TEMPLATE (BY NAME)
  /// ====================================================
  Future<Map<String, dynamic>> deleteInteraktTemplate({
    required String templateName,
  }) async {
    try {
      // 1️⃣ DELETE FROM INTERAKT (Cloud Function)
      final response = await _dio.post(
        deleteUrl,
        queryParameters: {"name": templateName, "clientId": clientID},
      );

      // If Interakt deletion failed → stop
      if (response.data["success"] != true) {
        return {"success": false, "message": "Failed to delete from Interakt"};
      }

      // 2️⃣ DELETE FROM FIRESTORE
      await FirebaseFirestore.instance
          .collection("templates")
          .doc(clientID)
          .collection("data")
          .where("name", isEqualTo: templateName)
          .limit(1)
          .get()
          .then((snap) async {
            if (snap.docs.isNotEmpty) {
              await snap.docs.first.reference.delete();
            }
          });

      return {"success": true, "message": "Deleted from Interakt & Firestore"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadMediaToInterakt({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
        "type": mimeType, // Only need this
        "clientId": clientID,
      });

      final response = await _dio.post(
        uploadMediaUrl,
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      return response.data;
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data ?? e.message};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
