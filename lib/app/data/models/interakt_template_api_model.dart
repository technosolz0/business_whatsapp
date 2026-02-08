// class InteraktTemplate {
//   final String id;
//   final String name;
//   final String language;
//   final String category;
//   final String status;

//   final String headerText; // Only for TEXT headers
//   final String headerImage; // URL OR handle id for MEDIA headers
//   final String headerFormat; // TEXT | IMAGE | VIDEO | DOCUMENT | ""

//   final String body;
//   final String footer;
//   final String type;
//   final List<String> variables;

//   InteraktTemplate({
//     required this.id,
//     required this.name,
//     required this.language,
//     required this.category,
//     required this.status,
//     required this.headerText,
//     required this.headerImage,
//     required this.headerFormat,
//     required this.body,
//     required this.footer,
//     required this.type,
//     required this.variables,
//   });

//   factory InteraktTemplate.fromJson(Map<String, dynamic> json) {
//     String headerText = "";
//     String headerImage = "";
//     String headerFormat = "";

//     String body = "";
//     String footer = "";
//     List<String> variables = [];

//     final components = json["components"] ?? [];

//     for (final comp in components) {
//       switch (comp["type"]) {
//         case "HEADER":
//           headerFormat = comp["format"]?.toString() ?? "";

//           // Case: MEDIA HEADER (Image / Video / Document)
//           if (headerFormat != "TEXT") {
//             final handles = comp["example"]?["header_handle"];
//             if (handles is List && handles.isNotEmpty) {
//               headerImage = handles.first.toString(); // URL or handle id
//              //print("headerImage----------------> $headerImage");
//             }
//           }
//           // Case: TEXT HEADER
//           else {
//             headerText = comp["text"] ?? "";
//           }
//           break;

//         case "BODY":
//           body = comp["text"] ?? "";
//           if (comp["example"]?["body_text"] != null) {
//             variables = List<String>.from(
//               comp["example"]["body_text"][0] ?? [],
//             );
//           }
//           break;

//         case "FOOTER":
//           footer = comp["text"] ?? "";
//           break;
//       }
//     }

//     // Detect Template Type
//     final type = _detectType(components);

//     return InteraktTemplate(
//       id: json["id"].toString(),
//       name: json["name"] ?? "",
//       language: json["language"] ?? "",
//       category: _normalizeCategory(json["category"]),
//       status: _normalizeStatus(json["status"]),
//       headerText: headerText,
//       headerImage: headerImage,
//       headerFormat: headerFormat,
//       body: body,
//       footer: footer,
//       type: type,
//       variables: variables,
//     );
//   }

//   // --------------------------
//   // Detection Helpers
//   // --------------------------
//   static String _detectType(List components) {
//     bool hasButtons = components.any((c) => c["type"] == "BUTTONS");
//     bool hasMediaHeader = components.any(
//       (c) => c["type"] == "HEADER" && (c["format"] ?? "") != "TEXT",
//     );

//     if (hasButtons) return "Interactive";
//     if (hasMediaHeader) return "Text & Media";
//     return "Text";
//   }

//   static String _normalizeStatus(String? raw) {
//     switch (raw?.toUpperCase()) {
//       case "APPROVED":
//         return "Approved";
//       case "PENDING":
//         return "Pending";
//       case "REJECTED":
//         return "Rejected";
//     }
//     return raw ?? "";
//   }

//   static String _normalizeCategory(String? raw) {
//     switch (raw?.toUpperCase()) {
//       case "MARKETING":
//         return "Marketing";
//       case "UTILITY":
//         return "Utility";
//     }
//     return raw ?? "";
//   }

//   // --------------------------
//   // TO JSON (For Creating Template)
//   // --------------------------
//   Map<String, dynamic> toJson() {
//     final List<Map<String, dynamic>> components = [];

//     // HEADER
//     if (headerImage.isNotEmpty) {
//       components.add({
//         "type": "HEADER",
//         "format": headerFormat,
//         "example": {
//           "header_handle": [headerImage],
//         },
//       });
//     } else if (headerText.isNotEmpty) {
//       components.add({
//         "type": "HEADER",
//         "format": "TEXT",
//         "text": headerText,
//         "example": {
//           "header_text": [headerText],
//         },
//       });
//     }

//     // BODY
//     components.add({
//       "type": "BODY",
//       "text": body,
//       "example": variables.isNotEmpty
//           ? {
//               "body_text": [variables],
//             }
//           : null,
//     });

//     // FOOTER
//     if (footer.isNotEmpty) {
//       components.add({"type": "FOOTER", "text": footer});
//     }

//     return {
//       "id": id,
//       "name": name,
//       "language": language,
//       "category": category,
//       "status": status,
//       "headerText": headerText,
//       "headerImage": headerImage,
//       "headerFormat": headerFormat,
//       "body": body,
//       "footer": footer,
//       "type": type,
//       "variables": variables,
//       "components": components,
//     };
//   }
// }
