import 'package:business_whatsapp/app/data/models/broadcast_status.dart';

class RecentBroadcastModel {
  final String broadcastName;
  final BroadcastStatus status;
  final int recipients;
  final String date;
  final String actionLabel;

  RecentBroadcastModel({
    required this.broadcastName,
    required this.status,
    required this.recipients,
    required this.date,
    required this.actionLabel,
  });
}
