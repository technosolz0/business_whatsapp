import 'package:business_whatsapp/app/Utilities/constants/app_constants.dart';
import 'package:business_whatsapp/app/controllers/navigation_controller.dart';
import 'package:business_whatsapp/app/data/models/broadcast_status.dart';
import 'package:business_whatsapp/app/data/models/recent_broadcast_model.dart';
import 'package:business_whatsapp/app/data/services/subscription_service.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:business_whatsapp/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:business_whatsapp/app/modules/broadcasts/controllers/create_broadcast_controller.dart';

import 'package:intl/intl.dart';
import '../../../data/models/custom_notification_model.dart';

class DashboardController extends GetxController {
  final RxString selectedTimeRange = 'Today'.obs;
  final navigationController = Get.find<NavigationController>();

  // Analytics data
  final RxMap<String, dynamic> analyticsData = <String, dynamic>{}.obs;
  final RxBool isLoadingAnalytics = true.obs;

  // Custom date range
  DateTime? customStartDate;
  DateTime? customEndDate;
  final RxInt usedQuota = 0.obs;
  final RxInt availableQuota = AppConstants.dailyLimit.obs;
  final RxInt totalQuota = AppConstants.dailyLimit.obs;
  final RxInt activeBroadcastsCount = 0.obs;
  final RxList<Map<String, dynamic>> activeBroadcastsList =
      <Map<String, dynamic>>[].obs;

  // Broadcast status counts
  final RxInt pendingBroadcastsCount = 0.obs;
  final RxInt sendingBroadcastsCount = 0.obs;
  final RxInt scheduledBroadcastsCount = 0.obs;

  // Chart data for performance analysis
  final RxList<Map<String, dynamic>> performanceChartData =
      <Map<String, dynamic>>[].obs;

  // Recent broadcasts
  final RxList<RecentBroadcastModel> recentBroadcasts =
      <RecentBroadcastModel>[].obs;

  // Custom Notifications
  final RxList<CustomNotificationModel> customNotifications =
      <CustomNotificationModel>[].obs;

  // Wallet balance
  final RxDouble walletBalance = 0.0.obs;
  final RxDouble lastRechargeAmt = 0.0.obs;
  final RxString lastRechargeDate = ''.obs;

  // Hidden notifications storage
  GetStorage? _storage;
  RxList<String>? _hiddenNotificationIds;

  // Your Cloud Function URL
  final String analyticsApiUrl = ApiEndpoints.getAnalytics;

  @override
  void onInit() {
    super.onInit();
    _loadHiddenNotifications();
    loadAnalyticsData();
    loadRecentBroadcasts();
    loadDailyQuotaData();
    loadActiveBroadcasts();
    loadWalletBalance();
    loadCustomNotifications();
    loadSubscription();
  }

  void loadSubscription() {
    SubscriptionService.instance.subscription.listen((sub) {
      if (sub != null) {}
    });
  }

  /// Load custom notifications
  void loadCustomNotifications() {
    FirebaseFirestore.instance
        .collection('custom_notifications')
        .snapshots()
        .listen(
          (snapshot) {
            // Ensure initialized
            _hiddenNotificationIds ??= <String>[].obs;

            final now = DateTime.now();
            final notifications = snapshot.docs
                .map(
                  (doc) => CustomNotificationModel.fromJson(doc.data(), doc.id),
                )
                .where((n) {
                  // Filter out expired notifications and hidden ones
                  return n.endDate.isAfter(now) &&
                      !_hiddenNotificationIds!.contains(n.id);
                })
                .toList();

            // Sort by created at descending (newest first)
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            customNotifications.value = notifications;
          },
          onError: (error) {
            print('Error loading custom notifications: $error');
            customNotifications.value = [];
          },
        );
  }

  void _loadHiddenNotifications() {
    try {
      _storage ??= GetStorage();
      _hiddenNotificationIds ??= <String>[].obs;

      final List<dynamic>? storedIds = _storage!.read('hidden_notifications');
      if (storedIds != null) {
        final List<String> stringIds = storedIds
            .map((e) => e.toString())
            .toList();
        _hiddenNotificationIds!.assignAll(stringIds);
      }
    } catch (e) {
      print('Error loading hidden notifications: $e');
      _hiddenNotificationIds!.clear();
    }
  }

  void hideNotification(String id) {
    try {
      _storage ??= GetStorage();
      _hiddenNotificationIds ??= <String>[].obs;

      // Use toList() to create a safe copy for checking existence
      // This avoids potential issues with RxList proxying in some runtimes
      final currentHidden = _hiddenNotificationIds!.toList();

      if (!currentHidden.contains(id)) {
        _hiddenNotificationIds!.add(id);
        _storage!.write(
          'hidden_notifications',
          _hiddenNotificationIds!.toList(),
        );

        // Update customNotifications safely
        final currentNotifications = customNotifications.toList();
        currentNotifications.removeWhere((n) => n.id == id);
        customNotifications.assignAll(currentNotifications);
      }
    } catch (e) {
      print('Error hiding notification: $e');
    }
  }

  /// Load active broadcasts (sending, pending, scheduled)
  void loadActiveBroadcasts() {
    FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(clientID)
        .collection('data')
        .snapshots()
        .listen(
          (snapshot) {
            int pendingCount = 0;
            int sendingCount = 0;
            int scheduledCount = 0;
            final activeBroadcasts = <Map<String, dynamic>>[];

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final status = data['status'] as String?;

              // Count by status
              if (status == 'Pending') {
                pendingCount++;
              } else if (status == 'Sending') {
                sendingCount++;
              } else if (status == 'Scheduled') {
                scheduledCount++;
              }

              // Collect active broadcasts (sending, pending, scheduled)
              if (status == 'Sending' ||
                  status == 'Pending' ||
                  status == 'Scheduled') {
                activeBroadcasts.add({
                  'id': doc.id,
                  'broadcastName': data['broadcastName'] ?? 'Unknown Broadcast',
                  'status': status ?? 'pending',
                  'sent': (data['sent'] as num?)?.toInt() ?? 0,
                  'delivered': (data['delivered'] as num?)?.toInt() ?? 0,
                  'createdAt': data['createdAt'] as Timestamp?,
                });
              }
            }

            // Update individual counts
            pendingBroadcastsCount.value = pendingCount;
            sendingBroadcastsCount.value = sendingCount;
            scheduledBroadcastsCount.value = scheduledCount;

            // Update total active count and list
            activeBroadcastsCount.value = activeBroadcasts.length;
            activeBroadcastsList.value = activeBroadcasts.take(3).toList();
          },
          onError: (error) {
            print('Error loading active broadcasts: $error');
            activeBroadcastsCount.value = 0;
            activeBroadcastsList.value = [];
            pendingBroadcastsCount.value = 0;
            sendingBroadcastsCount.value = 0;
            scheduledBroadcastsCount.value = 0;
          },
        );
  }

  /// Load conversation analytics from API
  Future<void> loadAnalyticsData() async {
    try {
      isLoadingAnalytics.value = true;

      // Build query parameters
      final queryParams = {
        'clientId': clientID,
        'filter': selectedTimeRange.value,
      };

      // Add custom date range if selected
      if (selectedTimeRange.value == 'Custom Date Range' &&
          customStartDate != null &&
          customEndDate != null) {
        queryParams['customStart'] =
            (customStartDate!.millisecondsSinceEpoch ~/ 1000).toString();
        queryParams['customEnd'] =
            (customEndDate!.millisecondsSinceEpoch ~/ 1000).toString();
      }

      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        analyticsApiUrl,
        queryParameters: queryParams,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          analyticsData.assignAll(data['metrics']);
          _generatePerformanceChartData();
          // print('Analytics loaded successfully: $analyticsData');
        } else {
          throw Exception(data['error'] ?? 'Failed to load analytics');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      print('Error loading analytics: $e');
      Get.snackbar(
        'Error',
        'Failed to load analytics data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingAnalytics.value = false;
    }
  }

  /// Load recent broadcasts
  void loadRecentBroadcasts() {
    FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(clientID)
        .collection('data')
        .orderBy('deliveryTime.timestamp', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
          recentBroadcasts.value = snapshot.docs.map((doc) {
            final data = doc.data();
            return RecentBroadcastModel(
              broadcastName: data['broadcastName'] ?? 'Unknown',
              status: _convertStatus(data['status'] ?? 'pending'),
              recipients: data['totalContacts'] ?? 0,
              date: _formatDate(
                (data['deliveryTime']?['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              ),
              actionLabel: 'View',
            );
          }).toList();
        });
  }

  void updateTimeRange(String range) {
    selectedTimeRange.value = range;

    // Clear custom dates if switching away from custom range
    if (range != 'Custom Date Range') {
      customStartDate = null;
      customEndDate = null;
    }

    loadAnalyticsData();
  }

  void updateCustomDateRange(DateTime start, DateTime end) {
    selectedTimeRange.value = 'Custom Date Range';
    customStartDate = start;
    customEndDate = end;
    loadAnalyticsData();

    Get.snackbar(
      'Custom Date Range Selected',
      'From ${_formatDate(start)} to ${_formatDate(end)}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void createCampaign() {
    // Reset wizard state if controller exists
    if (Get.isRegistered<CreateBroadcastController>()) {
      Get.find<CreateBroadcastController>().resetAll();
    }

    Get.toNamed(Routes.CREATE_BROADCAST);

    // Update navigation controller state for mobile compatibility
    final navController = Get.find<NavigationController>();
    navController.currentRoute.value = Routes.CREATE_BROADCAST;
    navController.selectedIndex.value = 5; // Broadcasts index
    navController.routeTrigger.value++;
  }

  // Getters for card data
  Map<String, dynamic> get allMessagesData {
    // print(
    //   'All Messages Data: ${analyticsData['allMessages'] ?? {'total': 0, 'breakdown': []}}',
    // );
    return analyticsData['allMessages'] ?? {'total': 0, 'breakdown': []};
  }

  Map<String, dynamic> get messagesDeliveredData {
    return analyticsData['messagesDelivered'] ?? {'total': 0, 'breakdown': []};
  }

  Map<String, dynamic> get freeMessagesData {
    return analyticsData['freeMessages'] ?? {'total': 0, 'breakdown': []};
  }

  Map<String, dynamic> get paidMessagesData {
    return analyticsData['paidMessages'] ?? {'total': 0, 'breakdown': []};
  }

  Map<String, dynamic> get totalChargesData {
    return analyticsData['totalCharges'] ??
        {'total': '0.00', 'currency': '₹', 'breakdown': []};
  }

  // Get dynamic chart minimum value (rounded down to nearest 10)
  double get chartMinimum {
    if (performanceChartData.isEmpty) return 0.0; // fallback

    // Find min value across all chart data points
    double minValue = double.infinity;

    for (final data in performanceChartData) {
      final sent = (data['sent'] as num?)?.toDouble() ?? 0.0;
      final delivered = (data['delivered'] as num?)?.toDouble() ?? 0.0;

      if (sent < minValue) minValue = sent;
      if (delivered < minValue) minValue = delivered;
    }

    if (minValue == double.infinity) return 0.0;

    // Round down to nearest 10
    return (minValue / 10).floorToDouble() * 10;
  }

  // Get dynamic chart maximum value (rounded up to nearest 10)
  double get chartMaximum {
    if (performanceChartData.isEmpty) return 50.0; // fallback

    // Find max value across all chart data points
    double maxValue = double.negativeInfinity;

    for (final data in performanceChartData) {
      final sent = (data['sent'] as num?)?.toDouble() ?? 0.0;
      final delivered = (data['delivered'] as num?)?.toDouble() ?? 0.0;

      if (sent > maxValue) maxValue = sent;
      if (delivered > maxValue) maxValue = delivered;
    }

    if (maxValue == double.negativeInfinity) return 50.0;

    // Round up to nearest 10
    return (maxValue / 10).ceilToDouble() * 10;
  }

  // Get dynamic chart interval (range / 5)
  double get chartInterval {
    final range = chartMaximum - chartMinimum;
    if (range <= 0) return 5.0;

    // Divide range across 5 intervals
    final interval = range / 5.0;

    return interval;
  }

  // Generate performance chart data based on allMessages breakdown
  void _generatePerformanceChartData() {
    final breakdown =
        analyticsData['allMessages']?['breakdown'] as List<dynamic>?;

    if (breakdown == null || breakdown.isEmpty) {
      performanceChartData.value = [];
      return;
    }

    // Get number of days based on selected time range
    int days = 7; // default
    List<String> dateLabels = [];

    switch (selectedTimeRange.value) {
      case 'Today':
        days = 7;
        final now = DateTime.now();
        dateLabels = List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          return DateFormat('E').format(date);
        });
        break;
      case 'This Month':
        final now = DateTime.now();
        days = now.day;
        dateLabels = List.generate(days, (i) {
          final date = DateTime(now.year, now.month, i + 1);
          return _formatDate(date).replaceAll('-', ' ');
        });
        break;
      case 'Last Month':
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0).day;
        days = lastDayOfLastMonth;
        dateLabels = List.generate(days, (i) {
          final date = DateTime(lastMonth.year, lastMonth.month, i + 1);
          return _formatDate(date).replaceAll('-', ' ');
        });
        break;
      case 'Last 6 Months':
        days = 6;
        final now = DateTime.now();
        dateLabels = List.generate(6, (i) {
          final date = DateTime(now.year, now.month - (5 - i), 1);
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
          return months[date.month - 1];
        });
        break;
      case 'Custom Date Range':
        if (customStartDate != null && customEndDate != null) {
          days = customEndDate!.difference(customStartDate!).inDays + 1;
          dateLabels = List.generate(days, (i) {
            final date = customStartDate!.add(Duration(days: i));
            return _formatDate(date).replaceAll('-', ' ');
          });
        } else {
          days = 7;
          dateLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        }
        break;
      default:
        days = 7;
        dateLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }

    // Extract sent and delivered values from breakdown
    final sentData = breakdown.firstWhere(
      (item) => (item['label'] as String?)?.toLowerCase() == 'sent',
      orElse: () => {'value': 0},
    );
    final deliveredData = breakdown.firstWhere(
      (item) => (item['label'] as String?)?.toLowerCase() == 'delivered',
      orElse: () => {'value': 0},
    );

    final totalSent = (sentData['value'] as num?)?.toInt() ?? 0;
    final totalDelivered = (deliveredData['value'] as num?)?.toInt() ?? 0;

    // Generate chart data distributed across the time period
    final chartData = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < days; i++) {
      // Distribute sent messages across days with some variation
      final sentBase = totalSent > 0 ? (totalSent / days).round() : 0;
      final sentVariation = ((random + i * 31) % 20) - 10; // -10 to +10
      final sent = (sentBase + sentVariation).clamp(0, double.infinity).toInt();

      // Distribute delivered messages proportionally
      final deliveredBase = totalDelivered > 0
          ? (totalDelivered / days).round()
          : (sent * 0.9).toInt();
      final deliveredVariation = ((random + i * 17) % 15) - 7; // -7 to +7
      final delivered = (deliveredBase + deliveredVariation)
          .clamp(0, sent.toDouble())
          .toInt();

      chartData.add({
        'date': dateLabels[i % dateLabels.length],
        'sent': sent.toDouble(),
        'delivered': delivered.toDouble(),
      });
    }

    performanceChartData.value = chartData;
  }

  /// Load daily quota data from Firebase
  void loadDailyQuotaData() {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    FirebaseFirestore.instance
        .collection('quota')
        .doc(clientID)
        .collection('data')
        .doc(todayString)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              final used = (data['usedQuota'] as num?)?.toInt() ?? 0;
              usedQuota.value = used;
              availableQuota.value = totalQuota.value - used;
            } else {
              print('Quota document does not exist, setting defaults');
              // If today's document doesn't exist, set defaults
              usedQuota.value = 0;
              availableQuota.value = totalQuota.value;
            }
          },
          onError: (error) {
            print('Error loading quota data: $error');
            usedQuota.value = 0;
            availableQuota.value = totalQuota.value;
          },
        );
  }

  /// Load wallet balance from Firebase
  void loadWalletBalance() {
    print('Loading wallet balance from Firebase');

    FirebaseFirestore.instance
        .collection('profile')
        .doc(clientID)
        .collection('data')
        .doc('wallet')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;

              // Parse balance as int
              final balance = (data['balance']) ?? 0;
              walletBalance.value = balance;

              // Parse last recharge amount as int
              final lastRechargeAmtValue = (data['last_recharge_amt']) ?? 0;
              lastRechargeAmt.value = lastRechargeAmtValue;

              // Parse last recharge date as formatted string
              final timestamp = data['last_recharge_date'] as Timestamp?;
              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                final formattedDate = _formatDate(dateTime);
                lastRechargeDate.value = formattedDate;
              } else {
                lastRechargeDate.value = '';
              }
            } else {
              walletBalance.value = 0;
              lastRechargeAmt.value = 0;
              lastRechargeDate.value = '';
            }
          },
          onError: (error) {
            print('Error loading wallet balance: $error');
            walletBalance.value = 0;
            lastRechargeAmt.value = 0;
            lastRechargeDate.value = '';
          },
        );
  }

  // Helper methods
  String _formatDate(DateTime date) {
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
    return '${date.day}-${months[date.month - 1]}';
  }

  BroadcastStatus _convertStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return BroadcastStatus.sent;
      case 'failed':
        return BroadcastStatus.failed;
      default:
        return BroadcastStatus.pending;
    }
  }
}
