import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../common widgets/custom_button.dart';

class BroadcastTermsDialog extends StatefulWidget {
  final VoidCallback onAccepted;

  const BroadcastTermsDialog({super.key, required this.onAccepted});

  @override
  State<BroadcastTermsDialog> createState() => _BroadcastTermsDialogState();
}

class _BroadcastTermsDialogState extends State<BroadcastTermsDialog> {
  final ScrollController _scrollController = ScrollController();
  final bool _isAtBottom = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Use addPostFrameCallback to check if content is smaller than viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScroll();
    });
  }

  void _scrollListener() {
    _checkScroll();
  }

  void _checkScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 10) {
        // if (!_isAtBottom) {
        //   setState(() {
        //     _isAtBottom = true;
        //   });
        // }
      }
    } else {
      // If content is too short to scroll, enable button
      // setState(() {
      //   _isAtBottom = true;
      // });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Important Notice: WhatsApp Marketing Policies",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextContent(context, isDark),
                      if (!_isExpanded)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isExpanded = true;
                                // _isAtBottom =
                                //     false; // Reset bottom check for new content
                              });
                              // Check scroll again after UI update
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _checkScroll();
                              });
                            },
                            child: const Text("Read More"),
                          ),
                        ),
                      if (_isExpanded) ...[
                        const Divider(height: 32),
                        _buildExpandedContent(context, isDark),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // CustomButton(
                //   label: 'Cancel',
                //   onPressed: () => Get.back(),
                //   type: ButtonType.secondary,
                // ),
                // const SizedBox(width: 12),
                CustomButton(
                  label: 'I Understand',
                  onPressed: () {
                    Get.back();
                    widget.onAccepted();
                  },

                  // _isAtBottom
                  //     ? () {
                  //         Get.back();
                  //         widget.onAccepted();
                  //       }
                  //     : null,
                  // isDisabled: !_isAtBottom,
                  type: ButtonType.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WhatsApp may limit the number of marketing template messages a person receives from any business in a given period of time, starting with a small number of conversations that are less likely to be read. Soon, we will also start to deliver fewer marketing conversations to those users who are less likely to engage with them.",
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppColors.gray300 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Official documentation by Meta",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Meta states that since launching frequency capping, they have seen significant improvements in user read rates for WhatsApp messages. This limit is helping WhatsApp users find business messaging more valuable without making them feel like they receive too many business messages.",
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppColors.gray300 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Note: Frequency capping is a per-user limit, not a per-business limit, meaning this limitation only applies to user accounts, not businesses sending these messages.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.gray300 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Best practices to counter Meta's Frequency Capping",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildStep(
          "1. Get Opt-in from new users:",
          "Inform leads before sending them broadcasts on WhatsApp. Mention in all your contact forms that the number the user is sharing might be used to send them notifications on WhatsApp. This ensures that the user can expect messages from your brand, prompting them not to block your contact, increasing your delivery rates.",
          isDark,
        ),
        _buildStep(
          "2. Don't immediately try resending messages to failed contacts:",
          "If messages are failing to send, wait for 24-48 hours before trying to reach them again. It might be that these users have already received their quota of promotional messages from other businesses, leading to failure of your messages.",
          isDark,
        ),
        _buildStep(
          "3. Send broadcasts with a way to unsubscribe:",
          "Always mention in the footer of your message how users can unsubscribe from your WhatsApp notifications. This gives Meta a signal that your broadcasts are genuine, prompting higher delivery rates.",
          isDark,
        ),
        _buildStep(
          "4. Don't schedule too many messages in a short duration:",
          "More messages do not necessarily mean more conversions. On the contrary, this might irritate users causing them to block you.",
          isDark,
        ),
        _buildStep(
          "5. Don't just sell, send content that engages users:",
          "Another thing you can try to achieve higher delivery rates is sending messages that don't just focus on selling, rather they focus on engaging the users. Higher engagement gives Meta a signal that your business is sending quality messages, leading to higher delivery rates.",
          isDark,
        ),
        _buildStep(
          "6. Send limited cold broadcasts on WhatsApp:",
          "Sending a large number of cold broadcasts is the best way to get your number blocked by a mass audience, that not only reduces your quality rating but also gives Meta a signal that you are sending broadcasts without proper opt-in, causing high failure rate.\n\nLimit the number of cold broadcasting you do every month!",
          isDark,
        ),
      ],
    );
  }

  Widget _buildStep(String title, String body, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.gray200 : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? AppColors.gray300 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
