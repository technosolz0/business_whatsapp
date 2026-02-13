import 'package:adminpanel/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard statistics for a specific time range
  Future<DashboardStats> getDashboardStats(String timeRange) async {
    try {
      final dateRange = _getDateRange(timeRange);
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      final startStr = _formatDateOnly(startDate);
      final endStr = _formatDateOnly(endDate);

      int totalSent = 0;
      int totalDelivered = 0;
      int totalRead = 0;

      Map<String, int> weeklyData = {};

      final daysInRange = _getDaysForRange(timeRange);
      for (String day in daysInRange) {
        weeklyData[day] = 0;
      }

      // 🔥 Fetch FROM totalSendMsg (STRING DATE)
      final snapshot = await _firestore
          .collection("totalSendMsg")
          .doc(clientID)
          .collection("data")
          .where("date", isGreaterThanOrEqualTo: startStr)
          .where("date", isLessThanOrEqualTo: endStr)
          .get();

      //print("Documents found: ${snapshot.docs.length}");

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final sent = (data["totalSent"] as num?)?.toInt() ?? 0;
        final delivered = (data["totalDelivered"] as num?)?.toInt() ?? 0;
        final read = (data["totalRead"] as num?)?.toInt() ?? 0;

        totalSent += sent;
        totalDelivered += delivered;
        totalRead += read;

        // Chart grouping
        final dayStr = data["date"];
        final date = DateTime.parse(dayStr);
        final dayKey = _getDayKey(date, timeRange);

        if (weeklyData.containsKey(dayKey)) {
          weeklyData[dayKey] = (weeklyData[dayKey] ?? 0) + sent;
        }
      }

      // Percentages
      final deliveryRate = totalSent > 0
          ? (totalDelivered / totalSent * 100).toStringAsFixed(1)
          : '0.0';

      final readRate = totalDelivered > 0
          ? (totalRead / totalSent * 100).toStringAsFixed(1)
          : '0.0';

      //print(
      //   'Final Stats → Sent: $totalSent, Delivered: $deliveryRate%, Read: $readRate%',
      // );

      return DashboardStats(
        totalSent: totalSent,
        deliveryRate: "$deliveryRate%",
        readRate: "$readRate%",
        weeklyData: weeklyData,
        daysLabels: daysInRange,
      );
    } catch (e) {
      //print("Error in getDashboardStats: $e");
      rethrow;
    }
  }

  String _formatDateOnly(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Get recent broadcasts (last 3, unaffected by filters)
  Stream<List<RecentBroadcast>> getRecentBroadcastsStream() {
    return _firestore
        .collection('broadcasts')
        .doc(clientID)
        .collection('data')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
          //print('Fetched ${snapshot.docs.length} recent broadcasts');

          return snapshot.docs.map((doc) {
            final data = doc.data();
            return RecentBroadcast(
              broadcastName: data['broadcastName'] ?? 'Unnamed Campaign',
              status: _mapStatus(data['status']),
              recipients: data['recipientCount'] ?? 0,
              date: _formatDate(data['createdAt']),
              actionLabel: _getActionLabel(data['status']),
            );
          }).toList();
        })
        .handleError((error) {
          //print('Error fetching recent broadcasts: $error');
          return <RecentBroadcast>[];
        });
  }

  /// Get active broadcasts count
  Stream<int> getActiveBroadcastsStream() {
    return _firestore
        .collection('broadcasts')
        .doc(clientID)
        .collection('data')
        .where('status', whereIn: ['Pending', 'Scheduled', 'InProgress'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          //print('Error fetching active broadcasts: $error');
          return 0;
        });
  }

  /// Get date range based on filter
  Map<String, DateTime> _getDateRange(String timeRange) {
    final now = DateTime.now();
    DateTime startDate;

    switch (timeRange) {
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Last 6 Months':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'Last Year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return {'start': startDate, 'end': now};
  }

  /// Get day labels for the time range
  List<String> _getDaysForRange(String timeRange) {
    switch (timeRange) {
      case 'Last 7 Days':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Last 30 Days':
        return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      case 'Last 3 Months':
        final now = DateTime.now();
        return [
          _getMonthName(now.month - 2),
          _getMonthName(now.month - 1),
          _getMonthName(now.month),
        ];
      case 'Last 6 Months':
        final now = DateTime.now();
        return List.generate(6, (i) => _getMonthName(now.month - (5 - i)));
      case 'Last Year':
        return [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }

  /// Get appropriate key for grouping messages
  String _getDayKey(DateTime timestamp, String timeRange) {
    switch (timeRange) {
      case 'Last 7 Days':
        final weekday = timestamp.weekday;
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
      case 'Last 30 Days':
        final weekNumber = ((timestamp.day - 1) ~/ 7) + 1;
        return 'Week $weekNumber';
      case 'Last 3 Months':
      case 'Last 6 Months':
      case 'Last Year':
        return _getMonthName(timestamp.month);
      default:
        return 'Unknown';
    }
  }

  String _getMonthName(int month) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1) % 12];
  }

  String _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
      case 'completed':
        return 'sent';
      case 'pending':
      case 'scheduled':
      case 'inprogress':
        return 'inprocess';
      case 'failed':
        return 'failed';
      default:
        return 'inprocess';
    }
  }

  String _getActionLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'failed':
        return 'Retry';
      default:
        return 'View';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'N/A';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int totalSent;
  final String deliveryRate;
  final String readRate;
  final Map<String, int> weeklyData;
  final List<String> daysLabels;

  DashboardStats({
    required this.totalSent,
    required this.deliveryRate,
    required this.readRate,
    required this.weeklyData,
    required this.daysLabels,
  });
}

/// Recent broadcast model
class RecentBroadcast {
  final String broadcastName;
  final String status;
  final int recipients;
  final String date;
  final String actionLabel;

  RecentBroadcast({
    required this.broadcastName,
    required this.status,
    required this.recipients,
    required this.date,
    required this.actionLabel,
  });
}
