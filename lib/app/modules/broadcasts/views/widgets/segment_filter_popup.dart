import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_broadcast_controller.dart';

class SegmentFilterPopup extends StatefulWidget {
  final CreateBroadcastController controller;

  const SegmentFilterPopup({super.key, required this.controller});

  @override
  State<SegmentFilterPopup> createState() => _SegmentFilterPopupState();
}

class _SegmentFilterPopupState extends State<SegmentFilterPopup> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user scrolls near the bottom (200 pixels from bottom)
      widget.controller.loadMoreContacts();
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
                  Icons.segment_rounded,
                  size: 28,
                  color: isDark ? Colors.blue.shade300 : Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  "Custom Segment",
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
                    widget.controller.showSegmentPopup.value = false;
                    widget.controller.selectedTags.clear();
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
                onChanged: widget.controller.updateSearch,
                style: TextStyle(color: primaryText),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                  hintText: "Search contacts...",
                  hintStyle: TextStyle(color: secondaryText),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ---------------- TAGS ROW ----------------
            Obx(() {
              final tagsWithContacts = widget.controller.availableTags
                  .where((tag) => !widget.controller.tagHasNoContacts(tag))
                  .toList();

              if (tagsWithContacts.isEmpty) {
                return SizedBox(
                  height: 45,
                  child: Center(
                    child: Text(
                      "No tags available",
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: tagsWithContacts.map((tag) {
                      final isSelected = widget.controller.selectedTags
                          .contains(tag);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isSelected
                              ? (isDark
                                    ? Colors.blue.shade900.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.blue.shade100)
                              : cardColor,
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                      ? Colors.blue.shade300
                                      : Colors.blueAccent)
                                : borderColor,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => widget.controller.toggleTag(tag),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 14,
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? (isDark
                                          ? Colors.blue.shade300
                                          : Colors.blueAccent)
                                    : primaryText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),

            const SizedBox(height: 15),

            // ---------------- CONTACT LIST ----------------
            Expanded(
              child: Obx(() {
                final list = widget.controller.filteredContacts;

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      "No contacts found",
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
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final c = list[index];

                    String f = c.fName!.trim();
                    String l = c.lName!.trim();
                    String fullName = "$f $l".trim();
                    if (fullName.isEmpty) fullName = "Unknown User";
                    String initial = f.isNotEmpty ? f[0].toUpperCase() : "U";

                    return Obx(() {
                      final isChecked = widget.controller.segmentContacts.any(
                        (x) => x.id == c.id,
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? Colors.blue.shade900
                              : Colors.blue.shade100,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.blue.shade200
                                  : Colors.blueAccent,
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
                          c.phoneNumber,
                          style: TextStyle(color: secondaryText),
                        ),
                        trailing: Checkbox(
                          value: isChecked,
                          activeColor: isDark
                              ? Colors.blue.shade300
                              : Colors.blueAccent,
                          checkColor: Colors.white,
                          onChanged: (_) => widget.controller.toggleContact(c),
                        ),
                        onTap: () => widget.controller.toggleContact(c),
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
                  onPressed: () {
                    widget.controller.selectedAudience.value = "custom";
                    widget.controller.segmentContacts.refresh();
                    // Update contact details for popup after segment selection
                    widget.controller.calculateEstimatedRecipientsCount();
                    widget.controller.showSegmentPopup.value = false;
                    widget.controller.selectedTags.clear();
                    Navigator.of(context).pop();
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
                  label: const Text(
                    "Apply Filters",
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.3,
                      color: Colors.white,
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
