import 'package:business_whatsapp/app/data/models/interactive_model.dart';

class TemplateParamModel {
  final String id;
  final String name;
  final String language;
  final int headerVars;
  final int bodyVars;
  final String templateType;
  final String headerFormat; // TEXT | IMAGE | VIDEO | DOCUMENT
  final String category; // MARKETING | UTILITY | etc.

  final String? headerText; // From header
  final List<String> headerExamples;

  final String bodyText;
  final List<String> bodyExamples;

  final List<InteractiveButton>? buttons;

  /// NEW → Count of all {{x}} variables inside button texts + examples
  final int buttonVars;

  TemplateParamModel({
    required this.id,
    required this.language,
    required this.name,
    required this.headerVars,
    required this.bodyVars,
    required this.headerFormat,
    required this.templateType,
    required this.category,
    required this.headerText,
    required this.headerExamples,
    required this.bodyText,
    required this.bodyExamples,
    required this.buttons,

    required this.buttonVars, // NEW FIELD
  });

  int get totalParams => headerVars + bodyVars + buttonVars;

  TemplateParamModel copyWith({
    String? id,
    String? name,
    String? language,
    int? headerVars,
    int? bodyVars,
    String? templateType,
    String? headerFormat,
    String? category,
    String? headerText,
    List<String>? headerExamples,
    String? bodyText,
    List<String>? bodyExamples,
    List<InteractiveButton>? buttons,
    int? buttonVars,
  }) {
    return TemplateParamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      headerVars: headerVars ?? this.headerVars,
      bodyVars: bodyVars ?? this.bodyVars,
      templateType: templateType ?? this.templateType,
      headerFormat: headerFormat ?? this.headerFormat,
      category: category ?? this.category,
      headerText: headerText ?? this.headerText,
      headerExamples: headerExamples ?? this.headerExamples,
      bodyText: bodyText ?? this.bodyText,
      bodyExamples: bodyExamples ?? this.bodyExamples,
      buttons: buttons ?? this.buttons,
      buttonVars: buttonVars ?? this.buttonVars,
    );
  }

  /// ------------------------------------------------------------------
  /// STATIC HELPER TO COUNT VARIABLES INSIDE BUTTON TEXTS + EXAMPLES
  /// ------------------------------------------------------------------
  static int countButtonVars(List<InteractiveButton>? buttons) {
    if (buttons == null) return 0;

    final regex = RegExp(r'{{(\d+)}}');
    int count = 0;

    for (final btn in buttons) {
      // text field
      if (btn.text.isNotEmpty) {
        count += regex.allMatches(btn.text).length;
      }

      // example values (COPY_CODE, URL example etc.)
      if (btn.example != null) {
        for (final ex in btn.example!) {
          count += regex.allMatches(ex).length;
        }
      }
    }

    return count;
  }
}
