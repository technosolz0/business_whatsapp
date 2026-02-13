import 'package:adminpanel/app/data/models/interactive_model.dart';

class TemplateModels {
  final String id;
  final String name;
  final String language;
  final String? category;
  final String status;
  final String userCategory;

  final String? headerText; // optional TEXT header
  final String headerFormat; // TEXT | IMAGE | VIDEO | DOCUMENT | ""

  final List<String> headerVariables;

  final String body;
  final String? footer; // NOW NULLABLE

  final String type;

  final List<String> variables;
  final DateTime? createdAt;
  final List<InteractiveButton> buttons;
  TemplateModels({
    required this.id,
    required this.name,
    required this.language,
    required this.category,
    this.userCategory = '',
    required this.status,
    required this.headerText,
    // required this.headerImage,
    required this.headerFormat,
    required this.body,
    this.footer, // nullable
    required this.type,
    required this.variables,
    required this.headerVariables,
    required this.buttons,
    this.createdAt,
  });

  // --------------------------
  // FROM JSON
  // --------------------------
  factory TemplateModels.fromJson(Map<String, dynamic> json) {
    String? headerText;
    String headerFormat = "";

    String body = "";
    String? footer;
    List<String> variables = [];
    List<String> headerVars = [];
    List<InteractiveButton> buttons = [];
    final components = json["components"] ?? [];

    for (final comp in components) {
      switch (comp["type"]) {
        case "HEADER":
          headerFormat = comp["format"]?.toString() ?? "";

          if (headerFormat != "TEXT") {
            // headerImage = handles.first.toString();
          } else {
            headerText = comp["text"]?.toString();
          }

          // Header variables
          if (comp["example"]?["header_text"] != null) {
            headerVars = List<String>.from(
              comp["example"]["header_text"] ?? [],
            );
          }

          break;

        case "BODY":
          body = comp["text"] ?? "";
          if (comp["example"]?["body_text"] != null) {
            variables = List<String>.from(
              comp["example"]["body_text"][0] ?? [],
            );
          }
          break;

        case "FOOTER":
          footer = comp["text"]?.toString();
          break;

        case "BUTTONS":
          if (comp["buttons"] is List) {
            buttons = comp["buttons"]
                .map<InteractiveButton>(
                  (btn) => InteractiveButton.fromJson(btn),
                )
                .toList();
          }
          break;
      }
    }

    final type = _detectType(components);

    return TemplateModels(
      id: json["id"].toString(),
      name: json["name"] ?? "",
      language: json["language"] ?? "",
      category: _normalizeCategory(json["category"]),
      status: _normalizeStatus(json["status"]),
      headerText: headerText,
      // headerImage: headerImage,
      headerFormat: headerFormat,
      body: body,
      footer: footer,
      type: type,
      variables: variables,
      headerVariables: headerVars,
      userCategory: json["userCategory"] ?? "",
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
      buttons: buttons,
    );
  }

  factory TemplateModels.fromFirestore(Map<String, dynamic> json) {
    String? headerText;
    String headerFormat = "";
    List<String> headerVars = [];

    String body = "";
    String? footer;
    List<String> variables = [];
    List<InteractiveButton> buttons = [];
    final components = json["components"] ?? [];

    for (final comp in components) {
      switch (comp["type"]) {
        case "HEADER":
          headerFormat = comp["format"]?.toString() ?? "";

          if (headerFormat == "TEXT") {
            headerText = comp["text"]?.toString();

            if (comp["example"]?["header_text"] != null) {
              headerVars = List<String>.from(
                comp["example"]["header_text"] ?? [],
              );
            }
          } else {
            headerText = null; // for media header
            headerVars = [];
          }
          break;

        case "BODY":
          body = comp["text"] ?? "";

          if (comp["example"]?["body_text"] != null) {
            variables = List<String>.from(comp["example"]["body_text"] ?? []);
          }
          break;

        case "FOOTER":
          footer = comp["text"]?.toString();
          break;

        case "BUTTONS":
          if (comp["buttons"] is List) {
            buttons = comp["buttons"]
                .map<InteractiveButton>(
                  (btn) => InteractiveButton.fromJson(btn),
                )
                .toList();
          }
          break;
      }
    }

    return TemplateModels(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      language: json["language"] ?? "",
      category: json["category"],
      status: json["status"] ?? "",
      userCategory: json["userCategory"] ?? "",
      headerText: headerText,
      headerFormat: headerFormat,
      headerVariables: headerVars,
      body: body,
      footer: footer,
      type: json["type"] ?? "",
      variables: variables,
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
      buttons: buttons,
    );
  }

  // --------------------------
  // DETECTION HELPERS
  // --------------------------
  static String _detectType(List components) {
    bool hasButtons = components.any((c) => c["type"] == "BUTTONS");
    bool hasMediaHeader = components.any(
      (c) => c["type"] == "HEADER" && (c["format"] ?? "") != "TEXT",
    );

    if (hasButtons) return "Interactive";
    if (hasMediaHeader) return "Text & Media";
    return "Text";
  }

  static String _normalizeStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case "APPROVED":
        return "Approved";
      case "PENDING":
        return "Pending";
      case "REJECTED":
        return "Rejected";
    }
    return raw ?? "";
  }

  static String _normalizeCategory(String? raw) {
    switch (raw?.toUpperCase()) {
      case "MARKETING":
        return "Marketing";
      case "UTILITY":
        return "Utility";
    }
    return raw ?? "";
  }

  // --------------------------
  // TO JSON (Firebase Save / Interakt Create)
  // --------------------------
  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> components = [];

    // HEADER (optional)
    if (headerFormat.isNotEmpty && headerFormat.toUpperCase() != "TEXT") {
      // MEDIA HEADER (DOCUMENT, IMAGE, VIDEO)
      components.add({
        "type": "HEADER",
        "format": headerFormat.toUpperCase(),
        "example": {"header_handle": []},
      });
    } else {
      // TEXT HEADER
      final Map<String, dynamic> headerMap = {
        "type": "HEADER",
        "format": "TEXT",
        "text": headerText,
      };

      // ADD EXAMPLE ONLY IF variables exist
      if (headerVariables.isNotEmpty) {
        headerMap["example"] = {"header_text": headerVariables};
      }
      components.add(headerMap);
    }

    // BODY (required)
    components.add({
      "type": "BODY",
      "text": body,
      if (variables.isNotEmpty) "example": {"body_text": variables},
    });

    components.add({"type": "FOOTER", "text": footer});
    if (type == 'Interactive') {
      components.add({
        "type": "BUTTONS",
        "buttons": buttons.map((b) => b.toJson()).toList(),
      });
    }
    return {
      "id": id,
      "name": name,
      "language": language,
      "category": category,
      "userCategory": userCategory,
      "status": status,
      "body": body,

      "type": type,
      "createdAt": createdAt?.toIso8601String(),
      "components": components,
    };
  }
}
