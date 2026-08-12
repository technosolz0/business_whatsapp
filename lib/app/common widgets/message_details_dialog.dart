import 'package:business_whatsapp/main.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:business_whatsapp/app/Utilities/api_endpoints.dart';
import 'package:business_whatsapp/app/Utilities/network_utilities.dart';
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
    if (widget.broadcastId == null) return;
    if ((_isLoading || !_hasMore) && !reset && !isExport) return;

    if (isExport) {
      _exportAllMessages();
      return;
    }

    setState(() {
      _isLoading = true;
      if (reset) {
        _messages.clear();
        _hasMore = true;
      }
    });

    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getBroadcastDetails,
        queryParameters: {'broadcastId': widget.broadcastId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawMessages = response.data['messages'] ?? [];

        List<Map<String, dynamic>> parsedList = [];
        for (var msg in rawMessages) {
          if (msg is Map<String, dynamic>) {
            final payload = msg['payload'] is Map ? msg['payload'] : {};
            final number =
                payload['mobileNo'] ?? msg['mobileNo'] ?? msg['number'] ?? '';
            final status = (msg['status'] ?? 'pending').toString();
            final statusLower = status.toLowerCase();

            dynamic targetDate =
                msg['createdAt'] ?? msg['created_at'] ?? msg['sent_at'];
            if (statusLower == 'sent' && msg['sent_at'] != null) {
              targetDate = msg['sent_at'];
            } else if (statusLower == 'delivered' &&
                msg['delivered_at'] != null) {
              targetDate = msg['delivered_at'];
            } else if (statusLower == 'read' && msg['read_at'] != null) {
              targetDate = msg['read_at'];
            } else if (statusLower == 'failed' && msg['failed_at'] != null) {
              targetDate = msg['failed_at'];
            }

            String dateStr = '';
            if (targetDate != null) {
              try {
                final parsedDate = DateTime.parse(
                  targetDate.toString(),
                ).toLocal();
                dateStr = DateFormat('MMM d, y HH:mm').format(parsedDate);
              } catch (_) {
                dateStr = targetDate.toString();
              }
            }

            if (_selectedStatus != 'All' &&
                statusLower != _selectedStatus.toLowerCase()) {
              continue;
            }

            parsedList.add({
              'id': msg['id'] ?? '',
              'number': number,
              'status': status,
              'date': dateStr,
              'raw': msg,
            });
          }
        }

        setState(() {
          _messages.clear();
          _messages.addAll(parsedList);
          _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
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
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        ApiEndpoints.getBroadcastDetails,
        queryParameters: {'broadcastId': widget.broadcastId},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load messages for export.')),
        );
        return;
      }

      final List<dynamic> rawMessages = response.data['messages'] ?? [];
      if (rawMessages.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No messages to export.')));
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      List<String> headers = ['Number', 'Status', 'Date', 'Message ID'];
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      int count = 0;
      for (var msg in rawMessages) {
        if (msg is Map<String, dynamic>) {
          final payload = msg['payload'] is Map ? msg['payload'] : {};
          final number =
              payload['mobileNo'] ?? msg['mobileNo'] ?? msg['number'] ?? '';
          final status = (msg['status'] ?? 'pending').toString();
          final statusLower = status.toLowerCase();

          if (_selectedStatus != 'All' &&
              statusLower != _selectedStatus.toLowerCase()) {
            continue;
          }

          dynamic targetDate =
              msg['createdAt'] ?? msg['created_at'] ?? msg['sent_at'];
          if (statusLower == 'sent' && msg['sent_at'] != null) {
            targetDate = msg['sent_at'];
          } else if (statusLower == 'delivered' &&
              msg['delivered_at'] != null) {
            targetDate = msg['delivered_at'];
          } else if (statusLower == 'read' && msg['read_at'] != null) {
            targetDate = msg['read_at'];
          } else if (statusLower == 'failed' && msg['failed_at'] != null) {
            targetDate = msg['failed_at'];
          }

          String dateStr = '';
          if (targetDate != null) {
            try {
              final parsedDate = DateTime.parse(
                targetDate.toString(),
              ).toLocal();
              dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
            } catch (_) {
              dateStr = targetDate.toString();
            }
          }

          sheetObject.appendRow([
            TextCellValue(number.toString()),
            TextCellValue(status),
            TextCellValue(dateStr),
            TextCellValue(msg['id']?.toString() ?? ''),
          ]);
          count++;
        }
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        await FileSaver.instance.saveFile(
          name: 'broadcast_messages_${widget.broadcastId}',
          bytes: Uint8List.fromList(fileBytes),
          mimeType: MimeType.microsoftExcel,
        );

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported $count records to Excel successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
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
