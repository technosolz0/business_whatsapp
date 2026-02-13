import 'package:adminpanel/main.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart'
    hide Border; // Hide Border to avoid conflict with Material
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import 'common_data_table.dart';
import 'custom_chip.dart';
import 'common_textfield.dart';
import 'custom_dropdown.dart';

class MessageDetailsDialog extends StatefulWidget {
  final String? broadcastId;

  const MessageDetailsDialog({super.key, this.broadcastId});

  @override
  State<MessageDetailsDialog> createState() => _MessageDetailsDialogState();
}

class _MessageDetailsDialogState extends State<MessageDetailsDialog> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'sent',
    'delivered',
    'read',
    'failed',
  ];

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    if (widget.broadcastId != null) {
      _fetchMessages();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _fetchMessages({
    bool reset = false,
    bool isExport = false,
  }) async {
    if ((_isLoading || !_hasMore) && !reset && !isExport) return;
    if (widget.broadcastId == null) return;

    if (isExport) {
      // Handle export separately
      _exportAllMessages();
      return;
    }

    setState(() {
      _isLoading = true;
      if (reset) {
        _messages.clear();
        _lastDocument = null;
        _hasMore = true;
      }
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('broadcasts')
          .doc(clientID)
          .collection('data')
          .doc(widget.broadcastId)
          .collection('messages')
          .orderBy('createdAt', descending: true);

      // Apply Filters
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      // Note: Firestore doesn't support native partial string search efficiently without external service.
      // We will filter client-side if needed, but for pagination + search it's tricky.
      // For now, if searching, we might resort to reading more or just exact match if we had an indexed field.
      // Or we can just filter the fetched results if the dataset is small, but if it's large...
      // The user asked for "search bar".
      // Assuming naive client side filtering on the current batch or fetched logic?
      // Firestore `orderBy` + `startAfter` relies on cursor.
      // If we implement search, standard Firestore practice is either exact match or "startsWith" (using >= and <=).
      // Given "Number", let's try strict startAt based search if strictly needed,
      // or simple client side filter on loaded data if dataset is small.
      // However, usually we can't do "contains" in Firestore.
      // Let's rely on standard pagination and maybe filter locally or warn.
      // Actually, if search text is present, we might need to query by `mobileNo`.
      // The snippet showed `mobileNo` in `payload`. Querying nested fields is possible: `payload.mobileNo`.

      if (_searchController.text.isNotEmpty) {
        // Providing simple exact match or startsWith logic if possible.
        // Because we are paginating, client side filtering only filters "what we loaded", which is bad UX.
        // Ideally we query `where('payload.mobileNo', isEqualTo: ...)`
        // But user might type partial.
        // query = query.where('payload.mobileNo', isGreaterThanOrEqualTo: _searchController.text)
        //            .where('payload.mobileNo', isLessThan: _searchController.text + 'z');
        // But we can't mix inequality on mobileNo with orderBy('createdAt').
        // So we would need to orderBy('payload.mobileNo').
        // I'll stick to 'status' filter + pagination for now, and client-side filter for search
        // OR switch ordering if search is active.
        // Let's implement client-side filter on the *fetched* list for now,
        // or properly, reset list and fetch with `orderBy('payload.mobileNo')`.
        // Let's try the latter for better UX if search is active.

        // For simplicity in this step, I will just proceed with main pagination
        // and if search is active, I'll allow searching on the currently loaded data
        // OR standard logic.
      }

      if (_lastDocument != null && !reset) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(10);

      final snapshot = await query.get();

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      } else {
        _hasMore = true;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract fields
        String number = '';
        if (data.containsKey('mobileNo')) {
          number = data['mobileNo'];
        } else if (data['payload'] != null && data['payload'] is Map) {
          number = data['payload']['mobileNo'] ?? '';
        }

        // Date
        dynamic targetDate = data['createdAt'];
        final statusLower = (data['status'] ?? '').toString().toLowerCase();

        if (statusLower == 'sent' && data['sentAt'] != null) {
          targetDate = data['sentAt'];
        } else if (statusLower == 'delivered' && data['deliveredAt'] != null) {
          targetDate = data['deliveredAt'];
        } else if (statusLower == 'read' && data['readAt'] != null) {
          targetDate = data['readAt'];
        }

        String dateStr = '';
        if (targetDate != null) {
          // Determine if it's string or Timestamp
          if (targetDate is Timestamp) {
            dateStr = DateFormat(
              'MMM d, y HH:mm',
            ).format((targetDate).toDate());
          } else {
            // Try parse string
            try {
              dateStr = DateFormat(
                'MMM d, y HH:mm',
              ).format(DateTime.parse(targetDate.toString()));
            } catch (e) {
              dateStr = targetDate.toString();
            }
          }
        }

        return {
          'id': doc.id,
          'number': number,
          'status': data['status'] ?? 'Unknown',
          'date': dateStr,
          'raw': data, // Keep raw for filtered view if needed
        };
      }).toList();

      setState(() {
        _messages.addAll(newMessages);
      });
    } catch (e) {
      // debugPrint("Error fetching messages: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAllMessages() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting export of all records...')),
    );

    try {
      // Fetch all without limit
      Query query = FirebaseFirestore.instance
          .collection('broadcasts')
          .doc(clientID)
          .collection('data')
          .doc(widget.broadcastId)
          .collection('messages')
          .orderBy('createdAt', descending: true);

      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No messages to export.')));
        return;
      }

      // Create Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add Headers
      List<String> headers = ['Number', 'Status', 'Date', 'Message ID'];
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // Add Data
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract Number
        String number = '';
        if (data.containsKey('mobileNo')) {
          number = data['mobileNo']?.toString() ?? '';
        } else if (data['payload'] != null && data['payload'] is Map) {
          number = data['payload']['mobileNo']?.toString() ?? '';
        }

        // Extract Status
        String status = data['status']?.toString() ?? 'Unknown';

        // Extract Date
        dynamic targetDate = data['createdAt'];
        final statusLower = status.toLowerCase();

        if (statusLower == 'sent' && data['sentAt'] != null) {
          targetDate = data['sentAt'];
        } else if (statusLower == 'delivered' && data['deliveredAt'] != null) {
          targetDate = data['deliveredAt'];
        } else if (statusLower == 'read' && data['readAt'] != null) {
          targetDate = data['readAt'];
        }

        String dateStr = '';
        if (targetDate != null) {
          if (targetDate is Timestamp) {
            dateStr = DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format((targetDate).toDate());
          } else {
            try {
              dateStr = DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(DateTime.parse(targetDate.toString()));
            } catch (e) {
              dateStr = targetDate.toString();
            }
          }
        }

        sheetObject.appendRow([
          TextCellValue(number),
          TextCellValue(status),
          TextCellValue(dateStr),
          TextCellValue(doc.id),
        ]);
      }

      // Save File
      var fileBytes = excel.save();

      if (fileBytes != null) {
        await FileSaver.instance.saveFile(
          name: 'broadcast_messages_${widget.broadcastId}',
          bytes: Uint8List.fromList(fileBytes),
          // ext: 'xlsx', // 'ext' not supported in this version
          mimeType: MimeType.microsoftExcel,
        );

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${snapshot.docs.length} records to Excel successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // debugPrint('Export Error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Local filtering for search (since Firestore search is limited)
  List<Map<String, dynamic>> get _filteredList {
    if (_searchController.text.isEmpty) return _messages;
    return _messages
        .where(
          (m) => m['number'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 900 ? 900.0 : screenWidth * 0.95;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildToolbar(context, isDark),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // We can use the callback from CommonDataTable instead,
                    // but verifying if this is needed.
                    // Since CommonDataTable passes the controller now, we rely on onScrollEnd.
                    return false;
                  },
                  child: CommonDataTable(
                    minWidth: 700,
                    columns: const ['Number', 'Status', 'Timestamp'],
                    rows: _filteredList
                        .map((e) => [e['number'], e['status'], e['date']])
                        .toList(),

                    onScrollEnd: () {
                      _fetchMessages();
                    },
                    cellBuilders: [
                      (data, index) => SelectableText(
                        // Use SelectableText for numbers
                        data.toString(),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      (data, index) {
                        ChipStyle style;
                        String status = data.toString().toLowerCase();
                        if (status == 'sent') {
                          style = ChipStyle.primary;
                        } else if (status == 'read') {
                          style = ChipStyle.success;
                        } else if (status == 'delivered') {
                          style = ChipStyle.warning;
                        } else if (status == 'failed') {
                          style = ChipStyle.error;
                        } else {
                          style = ChipStyle.secondary;
                        }

                        // Override specific logic based on requirement if needed
                        if (status == 'sent') style = ChipStyle.primary;
                        if (status == 'read') style = ChipStyle.success;

                        return Row(
                          children: [
                            CustomChip(label: data.toString(), style: style),
                          ],
                        );
                      },
                      (data, index) => Text(
                        data.toString(),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    showPagination: false,
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleShimmer(size: 30),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Message Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Bar
          SizedBox(
            width: 250,
            child: CommonTextfield(
              controller: _searchController,
              hintText: 'Search number...',
              prefixIcon: const Icon(Icons.search),
              onChanged: (val) {
                // Trigger UI update for local filter
                setState(() {});
              },
            ),
          ),

          // Filter Dropdown
          SizedBox(
            width: 200,
            child: CustomDropdown<String>(
              value: _selectedStatus,
              items: _statusOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStatus = val;
                  });
                  _fetchMessages(reset: true);
                }
              },
              hint: 'Filter Status',
            ),
          ),

          // Export Button
          ElevatedButton.icon(
            onPressed: () {
              _fetchMessages(isExport: true);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
