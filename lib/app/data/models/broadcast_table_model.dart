import 'broadcast_status.dart';

class BroadcastTableModel {
  final String id;
  final String broadcastName;
  final BroadcastStatus status;
  final DateTime? completedAt;
  final int sent;
  final int delivered;
  final int read;
  final int invocationFailures;
  final int failed;
  final String actionLabel;
  final String? templateId;
  final String? audienceType;

  BroadcastTableModel({
    required this.id,
    required this.broadcastName,
    required this.status,
    required this.sent,
    required this.delivered,
    required this.read,
    required this.failed,
    required this.actionLabel,
    this.templateId,
    required this.completedAt,
    this.audienceType,
    required this.invocationFailures,
  });
}
