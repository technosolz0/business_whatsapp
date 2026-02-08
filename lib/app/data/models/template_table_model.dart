class TemplateTableModel {
  final String? hsmId;
  final String templateName;
  final String category;
  final String status;
  final String language;
  final String lastUpdated;

  TemplateTableModel({
    required this.hsmId,
    required this.templateName,
    required this.category,
    required this.status,
    required this.language,
    required this.lastUpdated,
  });
}
