import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:business_whatsapp/app/data/models/template_params.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/template_model.dart';

class TemplateFirestoreService {
  TemplateFirestoreService._();
  static final instance = TemplateFirestoreService._();

  CollectionReference<Map<String, dynamic>> get _collection => FirebaseFirestore
      .instance
      .collection("templates")
      .doc(clientID)
      .collection("data");

  Future<void> saveTemplate(TemplateModels template) async {
    await _collection.doc(template.id).set(template.toJson());
  }

  // Future<void> insertStaticTemplates() async {
  //   List<Map<String, dynamic>> staticTemplates = [
  //     {
  //       "id": "1357114749176649",
  //       "name": "v1_bni_success_msg",
  //       "language": "en",
  //       "category": "UTILITY",
  //       "status": "APPROVED",
  //       "userCategory": "",
  //       "components": [
  //         {
  //           "type": "BODY",
  //           "text":
  //               "Hi {{1}}, Thank you for your payment of ₹{{2}} on {{3}} for the month of {{4}}. Your payment has been successfully recorded, and your account is now up to date for this period. Best regards, Jatin Doshi Secretary Treasurer Team Magic BNI Exponential",
  //           "example": {
  //             "body_text": [
  //               ["Ajit Satam", "1000", "25-04-2025", "April 2025"],
  //             ],
  //           },
  //         },
  //       ],
  //       "createdAt": DateTime.now().toIso8601String(),
  //       "type": "Text",
  //     },

  //     // ADD MORE STATIC TEMPLATES HERE IF NEEDED
  //   ];

  //   for (final json in staticTemplates) {
  //     final model = TemplateModels.fromJson(json);
  //     await TemplateFirestoreService.instance.saveTemplate(model);
  //    //print("INSERTED TEMPLATE → ${model.name}");
  //   }

  //  //print("✅ Static templates inserted successfully.");
  // }
  /// -------------------------------------------------------------
  /// GET TEMPLATE BY ID (FULL TEMPLATE DETAILS)
  /// -------------------------------------------------------------
  Future<TemplateParamModel?> getTemplateById(String templateId) async {
    try {
      final doc = await _collection.doc(templateId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Reuse your existing parser
      return parseTemplate(data);
    } catch (e) {
      //print("❌ Error fetching template by ID: $e");
      return null;
    }
  }

  Future<List<TemplateParamModel>> getAllTemplatesForBroadcast() async {
    final snapshot = await _collection
        .where("status", isEqualTo: "APPROVED")
        .get();

    return snapshot.docs.map((doc) => parseTemplate(doc.data())).toList();
  }

  /// -------------------------------------------------------------
  /// PARSE TEMPLATE → Extract only simple fields required by UI
  /// -------------------------------------------------------------
  TemplateParamModel parseTemplate(Map<String, dynamic> json) {
    int headerVars = 0;
    int bodyVars = 0;
    int buttonsVar = 0;
    String language = json["language"] ?? "";
    String headerFormat = "";
    String? headerText;
    List<String> headerExamples = [];

    String bodyText = "";
    List<String> bodyExamples = [];

    // NEW → Buttons list
    List<InteractiveButton> buttons = [];

    final components = json["components"] ?? [];
    final regex = RegExp(r'\{\{[0-9]+\}\}');

    for (final comp in components) {
      final type = comp["type"] ?? "";

      switch (type) {
        case "HEADER":
          headerFormat = comp["format"] ?? "";

          // Save text if header is TEXT
          if (headerFormat == "TEXT") {
            headerText = comp["text"] ?? "";
            // Robust Count
            headerVars = regex.allMatches(headerText!).length;

            // Header examples
            var rawEx = comp["example"]?["header_text"];
            if (rawEx is List && rawEx.isNotEmpty && rawEx.first is List) {
              rawEx = rawEx.first;
            }
            if (rawEx is List) {
              headerExamples = List<String>.from(
                rawEx.map((e) => e.toString()),
              );
            }
          } else {
            // IMAGE / VIDEO / DOCUMENT
            // Usually 1 variable (the media handle)
            headerVars = 1;

            var rawEx = comp["example"]?["header_handle"];
            if (rawEx is List && rawEx.isNotEmpty && rawEx.first is List) {
              rawEx = rawEx.first;
            }
            if (rawEx is List) {
              headerExamples = List<String>.from(
                rawEx.map((e) => e.toString()),
              );
            }
          }
          break;

        case "BODY":
          // Main message body text
          bodyText = comp["text"] ?? "";
          // Robust Count
          bodyVars = regex.allMatches(bodyText).length;

          // BODY example values
          var rawEx = comp["example"]?["body_text"];
          if (rawEx is List && rawEx.isNotEmpty && rawEx.first is List) {
            rawEx = rawEx.first;
          }
          if (rawEx is List) {
            bodyExamples = List<String>.from(rawEx.map((e) => e.toString()));
          }
          break;

        // 🔥 NEW BUTTON HANDLING
        case "BUTTONS":
          if (comp["buttons"] is List) {
            buttons = comp["buttons"]
                .map<InteractiveButton>((b) => InteractiveButton.fromJson(b))
                .toList();
            // Use static helper to count regex matches in buttons if needed,
            // or just length if that's what we want.
            // Using logic from similar controller:
            buttonsVar = TemplateParamModel.countButtonVars(buttons);
          }
          break;
      }
    }

    return TemplateParamModel(
      id: json["id"] ?? "",
      language: language,
      name: json["name"] ?? "",
      templateType: json["type"] ?? "",
      category:
          json["category"] ?? "UTILITY", // Default to UTILITY if not specified
      headerVars: headerVars,
      bodyVars: bodyVars,
      headerFormat: headerFormat,

      headerText: headerText,
      headerExamples: headerExamples,

      bodyText: bodyText,
      bodyExamples: bodyExamples,

      // NEW → add buttons here
      buttons: buttons,
      buttonVars: buttonsVar,
    );
  }

  Future<String> getTemplateName(String templateId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('templates')
          .doc(clientID)
          .collection('data')
          .doc(templateId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? '';
      } else {
        return '';
      }
    } catch (e) {
      //print("Error while fetching template name: $e");
      return '';
    }
  }
}
