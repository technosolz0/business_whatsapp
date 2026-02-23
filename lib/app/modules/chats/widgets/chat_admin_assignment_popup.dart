import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import '../controllers/chats_controller.dart';

class ChatAdminAssignmentPopup extends StatefulWidget {
  final ChatsController controller;

  const ChatAdminAssignmentPopup({super.key, required this.controller});

  @override
  State<ChatAdminAssignmentPopup> createState() =>
      _ChatAdminAssignmentPopupState();
}

class _ChatAdminAssignmentPopupState extends State<ChatAdminAssignmentPopup> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial admins when popup opens
    widget.controller.loadAdminsForAssignment();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.controller.loadMoreAdmins();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Dialog(
      insetPadding: const EdgeInsets.all(28),
      backgroundColor: bgColor.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 720,
        height: 620,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bgColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- HEADER ----------------
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 28,
                  color: isDark ? Colors.blue.shade300 : Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  "Assign Admin to Chat",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: primaryText,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ---------------- SEARCH BAR ----------------
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                onChanged: widget.controller.updateAdminSearch,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                  hintText: "Search admins...",
                  hintStyle: TextStyle(color: secondaryText),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ---------------- ADMIN LIST ----------------
            Expanded(
              child: Obx(() {
                if (widget.controller.isLoadingAdmins.value &&
                    widget.controller.allAdmins.isEmpty) {
                  return const Center(child: CircleShimmer(size: 40));
                }

                final list = widget.controller.filteredAdmins;

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      "No admins found",
                      style: TextStyle(
                        fontSize: 15,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  itemCount:
                      list.length +
                      (widget.controller.isLoadingMoreAdmins.value ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircleShimmer(size: 20)),
                      );
                    }
                    final admin = list[index];

                    String fullName = admin.fullName;
                    if (fullName.isEmpty || fullName == 'Unknown') {
                      fullName = admin.email ?? "Unknown Admin";
                    }
                    String initial = fullName.isNotEmpty
                        ? fullName[0].toUpperCase()
                        : "A";

                    return Obx(() {
                      final isChecked = widget.controller.selectedChatAdmins
                          .any((a) => a.id == admin.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? Colors.green.shade900
                              : Colors.green.shade100,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.green.shade200
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: primaryText,
                          ),
                        ),
                        subtitle: Text(
                          "${admin.email ?? ''} • ${admin.role ?? ''}",
                          style: TextStyle(color: secondaryText),
                        ),
                        trailing: Checkbox(
                          value: isChecked,
                          activeColor: isDark
                              ? Colors.blue.shade300
                              : Colors.blueAccent,
                          checkColor: Colors.white,
                          onChanged: (_) =>
                              widget.controller.toggleAdminSelection(admin),
                        ),
                        onTap: () =>
                            widget.controller.toggleAdminSelection(admin),
                      );
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 10),

            // ---------------- APPLY BUTTON ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await widget.controller.updateChatAdmins();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.blue.shade400
                        : Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Obx(
                    () => Text(
                      "Done (${widget.controller.selectedChatAdmins.length} Selected)",
                      style: const TextStyle(
                        fontSize: 15,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
