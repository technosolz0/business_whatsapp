import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:business_whatsapp/app/data/models/interactive_model.dart';
import 'package:business_whatsapp/app/data/models/template_model.dart';
import 'package:business_whatsapp/app/data/models/template_params.dart';
import 'package:business_whatsapp/main.dart';
import 'package:dio/dio.dart';

class TemplateFirestoreService {
  TemplateFirestoreService._();
  static final instance = TemplateFirestoreService._();

  final Dio _dio = NetworkUtilities.getDioClient();

  /// -------------------------------------------------------------
  /// SAVE TEMPLATE TO BACKEND DATABASE
  /// -------------------------------------------------------------
  Future<void> saveTemplate(TemplateModels template) async {
    try {
      final payload = {...template.toJson(), 'clientId': clientID};
      await _dio.post('${ApiEndpoints.serverUrl}/saveTemplate', data: payload);
    } catch (e) {
      print("❌ Error saving template to backend: $e");
    }
  }

  /// -------------------------------------------------------------
  /// GET TEMPLATE BY ID (FULL TEMPLATE DETAILS)
  /// -------------------------------------------------------------
  Future<TemplateParamModel?> getTemplateById(String templateId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.serverUrl}/getTemplateDetails',
        queryParameters: {'clientId': clientID, 'templateId': templateId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          return parseTemplate(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      print("❌ Error fetching template by ID from getTemplateDetails: $e");
    }

    try {
      final templates = await getAllTemplatesForBroadcast();
      for (final t in templates) {
        if (t.id == templateId) {
          return t;
        }
      }
    } catch (e) {
      print("❌ Error fetching template by ID fallback: $e");
    }
    return null;
  }

  /// -------------------------------------------------------------
  /// GET RAW TEMPLATE MODEL FOR VIEW / COPY
  /// -------------------------------------------------------------
  Future<TemplateModels?> getTemplateModelById(String templateId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.serverUrl}/getTemplateDetails',
        queryParameters: {'clientId': clientID, 'templateId': templateId},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          return TemplateModels.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      print("❌ Error fetching template model for view/copy: $e");
    }
    return null;
  }

  Future<List<TemplateParamModel>> getAllTemplatesForBroadcast() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getApprovedTemplates,
        queryParameters: {'clientId': clientID},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data']['data'] ?? [];
        return list.map((item) => parseTemplate(item)).toList();
      }
    } catch (e) {
      print("❌ Error fetching templates for broadcast: $e");
    }
    return [];
  }

  /// -------------------------------------------------------------
  /// PARSE TEMPLATE → Extract simple and carousel fields required by UI
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

    List<InteractiveButton> buttons = [];
    List<Map<String, dynamic>>? cards;

    final components = json["components"] ?? [];
    final regex = RegExp(r'\{\{[0-9]+\}\}');

    for (final comp in components) {
      final type = comp["type"] ?? "";

      switch (type) {
        case "HEADER":
          headerFormat = comp["format"] ?? "";

          if (headerFormat == "TEXT") {
            headerText = comp["text"] ?? "";
            headerVars = regex.allMatches(headerText!).length;

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
            headerVars = 0;

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
          bodyText = comp["text"] ?? "";
          bodyVars = regex.allMatches(bodyText).length;

          var rawEx = comp["example"]?["body_text"];
          if (rawEx is List && rawEx.isNotEmpty && rawEx.first is List) {
            rawEx = rawEx.first;
          }
          if (rawEx is List) {
            bodyExamples = List<String>.from(rawEx.map((e) => e.toString()));
          }
          break;

        case "BUTTONS":
          if (comp["buttons"] is List) {
            buttons = comp["buttons"]
                .map<InteractiveButton>((b) => InteractiveButton.fromJson(b))
                .toList();
            buttonsVar = TemplateParamModel.countButtonVars(buttons);
          }
          break;

        case "CAROUSEL":
        case "CARDS":
        case "Cards":
          if (comp["cards"] is List) {
            cards = List<Map<String, dynamic>>.from(comp["cards"]);
          }
          break;
        default:
          if (comp["cards"] is List) {
            cards = List<Map<String, dynamic>>.from(comp["cards"]);
          }
          break;
      }
    }

    if (cards == null && json["cards"] is List) {
      cards = List<Map<String, dynamic>>.from(json["cards"]);
    }

    String computedType = (json["type"] ?? "").toString().toUpperCase();
    if (computedType.isEmpty) {
      if (cards != null && cards.isNotEmpty) {
        computedType = "CAROUSEL";
      } else if (buttons.isNotEmpty) {
        computedType = "INTERACTIVE";
      } else if (headerFormat == "IMAGE" ||
          headerFormat == "VIDEO" ||
          headerFormat == "DOCUMENT") {
        computedType = "TEXT & MEDIA";
      } else {
        computedType = "TEXT";
      }
    }

    return TemplateParamModel(
      id: json["id"]?.toString() ?? "",
      language: language,
      name: json["name"] ?? "",
      templateType: computedType,
      category: json["category"] ?? "UTILITY",
      headerVars: headerVars,
      bodyVars: bodyVars,
      headerFormat: headerFormat,
      headerText: headerText,
      headerExamples: headerExamples,
      bodyText: bodyText,
      bodyExamples: bodyExamples,
      buttons: buttons,
      buttonVars: buttonsVar,
      cards: cards,
      version: json["version"] ?? "v1",
      ctaUrlLinkTrackingOptedOut:
          json["cta_url_link_tracking_opted_out"] ?? false,
    );
  }

  Future<String> getTemplateName(String templateId) async {
    try {
      final t = await getTemplateById(templateId);
      return t?.name ?? '';
    } catch (e) {
      print("Error while fetching template name: $e");
      return '';
    }
  }
}
