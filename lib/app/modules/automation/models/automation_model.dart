import 'package:get/get.dart';

class AutomationNodeData {
  String label;
  String hint;
  String? content;
  final RxList<String> keywords;
  String operator; // 'contains', 'equals', 'starts_with', 'regex'
  String? conditionValue;
  String actionType; // 'assign_dept', 'add_tag', 'custom'
  String? actionValue;
  final RxMap<String, String> options; // for menu/question

  AutomationNodeData({
    required this.label,
    required this.hint,
    this.content,
    List<String>? keywords,
    this.operator = 'contains',
    this.conditionValue,
    this.actionType = 'assign_dept',
    this.actionValue,
    Map<String, String>? options,
  })  : keywords = (keywords ?? []).obs,
        options = (options ?? {}).obs;

  factory AutomationNodeData.fromJson(Map<String, dynamic> json) {
    return AutomationNodeData(
      label: json['label'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      content: json['content'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)
          ?.map((k) => k.toString())
          .toList(),
      operator: json['operator'] as String? ?? 'contains',
      conditionValue: json['conditionValue'] as String?,
      actionType: json['actionType'] as String? ?? 'assign_dept',
      actionValue: json['actionValue'] as String?,
      options: (json['options'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'hint': hint,
      if (content != null) 'content': content,
      if (keywords.isNotEmpty) 'keywords': keywords.toList(),
      'operator': operator,
      if (conditionValue != null) 'conditionValue': conditionValue,
      'actionType': actionType,
      if (actionValue != null) 'actionValue': actionValue,
      if (options.isNotEmpty) 'options': Map<String, String>.from(options),
    };
  }
}

class AutomationFlowModel {
  final String id;
  final String name;
  final String createdBy;
  RxBool isActive;
  final String? uiFlowJson;
  final List<String> triggerKeywords;
  final String? startNode;
  final Map<String, dynamic>? nodes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AutomationFlowModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required bool isActive,
    this.uiFlowJson,
    this.triggerKeywords = const [],
    this.startNode,
    this.nodes,
    this.createdAt,
    this.updatedAt,
  }) : isActive = isActive.obs;

  factory AutomationFlowModel.fromFirestore(dynamic doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime? parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      try {
        return (val as dynamic)?.toDate();
      } catch (_) {
        return null;
      }
    }

    return AutomationFlowModel(
      id: data['id']?.toString() ?? doc.id,
      name: data['flowName']?.toString() ?? 'Untitled Flow',
      createdBy: data['createdBy']?.toString() ?? '',
      isActive: (data['status']?.toString() ?? '').toLowerCase() == 'active',
      uiFlowJson: data['ui_flow']?.toString(),
      triggerKeywords: (data['trigger_keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startNode: data['start_node']?.toString(),
      nodes: data['nodes'] as Map<String, dynamic>?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  factory AutomationFlowModel.fromJson(Map<String, dynamic> data, {String? id}) {
    DateTime? parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return AutomationFlowModel(
      id: id ?? data['id']?.toString() ?? '',
      name: data['flowName']?.toString() ?? data['name']?.toString() ?? 'Untitled Flow',
      createdBy: data['createdBy']?.toString() ?? '',
      isActive: (data['status']?.toString() ?? '').toLowerCase() == 'active',
      uiFlowJson: data['ui_flow']?.toString(),
      triggerKeywords: (data['trigger_keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (data['triggerKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startNode: data['start_node']?.toString() ?? data['startNode']?.toString(),
      nodes: data['nodes'] as Map<String, dynamic>?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}

