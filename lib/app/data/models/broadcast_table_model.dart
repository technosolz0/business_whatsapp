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
  final int clicks;
  final int replied;
  final DateTime? scheduledAt;
  final bool enableRetry;
  final String retryCampaignStatus;
  final double? totalCost;

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
    required this.clicks,
    required this.replied,
    this.scheduledAt,
    required this.enableRetry,
    required this.retryCampaignStatus,
    this.totalCost,
    String? adminName,
    String? adminId,
  });
}
