import 'package:cloud_firestore/cloud_firestore.dart';

class CustomNotificationModel {
  String? id;
  String type; // "Info", "Important", "Critical"
  String message;
  String duration; // e.g. "2 days", "5 hours" - storing as string or int?
  // User said "duration like how many days or hours".
  // I'll store it as a string for display, or maybe
  // separate durationValue and durationUnit if we need logic.
  // For now, I'll use String to keep it simple as per request "3 fields".
  // Actually, a simple string "Duration" might be ambiguous.
  // Let's assume user inputs a number and selects Days/Hours?
  // Or just a text field? "textform field for message and 3 one is duration".
  // I will make duration a String to allow "2 Days", "5 Hours" etc.
  DateTime createdAt;
  DateTime updatedAt;
  DateTime endDate;

  CustomNotificationModel({
    this.id,
    required this.type,
    required this.message,
    required this.duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? endDate,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       endDate =
           endDate ?? _calculateEndDate(createdAt ?? DateTime.now(), duration);

  static DateTime _calculateEndDate(DateTime start, String duration) {
    if (duration.isEmpty) return start;
    final parts = duration.split(' ');
    if (parts.length < 2) return start;

    try {
      final value = int.parse(parts[0]);
      final unit = parts[1].toLowerCase();

      if (unit.startsWith('day')) {
        return start.add(Duration(days: value));
      } else if (unit.startsWith('hour')) {
        return start.add(Duration(hours: value));
      }
    } catch (e) {
      // ignore error
    }
    return start;
  }

  factory CustomNotificationModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return CustomNotificationModel(
      id: id,
      type: json['type'] ?? 'Info',
      message: json['message'] ?? '',
      duration: json['duration'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null, // Constructor will recalculate if null, but better to pass null to trigger logic if needed?
      // Wait, if json has it, we use it. If not (old data), we pass null and constructor calculates it.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  CustomNotificationModel copyWith({
    String? id,
    String? type,
    String? message,
    String? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? endDate,
  }) {
    return CustomNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      endDate: endDate ?? this.endDate,
    );
  }
}
