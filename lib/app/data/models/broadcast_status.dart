import 'dart:ui';

enum BroadcastStatus { sent, sending, failed, pending, scheduled, draft }

extension BroadcastStatusExtension on BroadcastStatus {
  String get label {
    switch (this) {
      case BroadcastStatus.sent:
        return 'Sent';

      case BroadcastStatus.sending:
        return 'Sending';

      case BroadcastStatus.failed:
        return 'Failed';

      case BroadcastStatus.pending:
        return 'Pending';

      case BroadcastStatus.scheduled:
        return 'Scheduled';

      case BroadcastStatus.draft:
        return 'Draft';
    }
  }
}

extension BroadcastStatusColor on BroadcastStatus {
  Color get color {
    switch (this) {
      case BroadcastStatus.sent:
        return const Color(0xFF28A745); // Green

      case BroadcastStatus.failed:
        return const Color(0xFFDC3545); // Red

      case BroadcastStatus.sending:
        return const Color(0xFFFFA500); // Orange

      case BroadcastStatus.pending:
        return const Color(0xFF17A2B8); // Cyan

      case BroadcastStatus.scheduled:
        return const Color(0xFF6F42C1); // Purple

      case BroadcastStatus.draft:
        return const Color(0xFF6C757D); // Gray
    }
  }
}
