import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class QuestionModel {
  final String id;
  final String? contactId;
  final String question;
  String status; // 'answered', 'pending'
  final String timestamp;
  String? answerText;
  List<String> attachmentNames;
  List<Map<String, dynamic>> attachments;
  final String? whenAnswered;
  var isExpanded = false.obs;

  QuestionModel({
    required this.id,
    this.contactId,
    required this.question,
    required this.status,
    required this.timestamp,
    this.answerText,
    this.attachmentNames = const [],
    this.attachments = const [],
    this.whenAnswered,
  });

  factory QuestionModel.fromFirestore(String id, Map<String, dynamic> data) {
    final dynamic rawTs = data['timestamp'];
    String formattedTs = 'N/A';
    
    if (rawTs != null) {
      if (rawTs is Timestamp) {
        final dt = rawTs.toDate();
        formattedTs = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        formattedTs = rawTs.toString();
      }
    }

    final dynamic rawWhen = data['whenAnswered'];
    String? formattedWhen;
    if (rawWhen != null) {
      if (rawWhen is Timestamp) {
        final dt = rawWhen.toDate();
        formattedWhen = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        formattedWhen = rawWhen.toString();
      }
    }

    String status = (data['status'] ?? 'PENDING').toString().toLowerCase();
    
    // Handle the new 'answer' map structure
    final answerData = data['answer'] as Map<String, dynamic>?;
    String? answerText;
    List<String> attachmentNames = [];
    List<Map<String, dynamic>> attachments = [];

    if (answerData != null) {
      // Always try to get text if available
      answerText = answerData['text'];
      
      if (answerData['type'] == 'files') {
        final filesList = answerData['files'] as List<dynamic>?;
        if (filesList != null) {
          attachments = List<Map<String, dynamic>>.from(filesList);
          attachmentNames = attachments.map((f) => f['name'].toString()).toList();
        }
      }
    } else {
      // Fallback for old format
      answerText = data['answerText'];
      attachmentNames = List<String>.from(data['attachments'] ?? []);
    }
    
    return QuestionModel(
      id: id,
      contactId: data['contactId'],
      question: data['question'] ?? '',
      status: status,
      timestamp: formattedTs,
      answerText: answerText,
      attachmentNames: attachmentNames,
      attachments: attachments,
      whenAnswered: formattedWhen,
    );
  }
}
