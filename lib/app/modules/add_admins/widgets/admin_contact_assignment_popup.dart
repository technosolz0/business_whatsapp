import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import '../controllers/add_admins_controller.dart';

class AdminContactAssignmentPopup extends StatefulWidget {
  final AddAdminsController controller;

  const AdminContactAssignmentPopup({super.key, required this.controller});

  @override
  State<AdminContactAssignmentPopup> createState() =>
      _AdminContactAssignmentPopupState();
}

class _AdminContactAssignmentPopupState
    extends State<AdminContactAssignmentPopup> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial contacts when popup opens
    widget.controller.loadContactsForAssignment();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
                  Icons.person_add_alt_1_rounded,
                  size: 28,
                  color: isDark ? Colors.blue.shade300 : Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  "Assigned Contacts",
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

            // ---------------- CONTACT LIST ----------------
            Expanded(
              child: Obx(() {
                if (widget.controller.isLoadingContacts.value &&
                    widget.controller.allContacts.isEmpty) {
                  return const Center(child: CircleShimmer(size: 40));
                }

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
                  itemCount:
                      list.length +
                      (widget.controller.isLoadingContacts.value ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircleShimmer(size: 20)),
                      );
                    }
                    final c = list[index];

                    String fullName = c.name.trim();
                    if (fullName.isEmpty) fullName = "Unknown User";
                    String initial = fullName.isNotEmpty
                        ? fullName[0].toUpperCase()
                        : "U";

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
                        // trailing: Checkbox(
                        //   value: isChecked,
                        //   activeColor: isDark
                        //       ? Colors.blue.shade300
                        //       : Colors.blueAccent,
                        //   checkColor: Colors.white,
                        //   onChanged: (_) => widget.controller.toggleContact(c),
                        // ),
                        // onTap: () => widget.controller.toggleContact(c),
                      );
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 10),

            // // ---------------- APPLY BUTTON ----------------
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     ElevatedButton.icon(
            //       onPressed: () async {
            //         // Save to assigned_contacts if editing
            //         await widget.controller.updateAssignedContacts();
            //         if (context.mounted) {
            //           Navigator.of(context).pop();
            //         }
            //       },
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: isDark
            //             ? Colors.blue.shade400
            //             : Colors.blueAccent,
            //         padding: const EdgeInsets.symmetric(
            //           horizontal: 20,
            //           vertical: 12,
            //         ),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       icon: const Icon(
            //         Icons.check_circle_outline,
            //         size: 20,
            //         color: Colors.white,
            //       ),
            //       label: Obx(
            //         () => Text(
            //           "Done (${widget.controller.segmentContacts.length} Selected)",
            //           style: const TextStyle(
            //             fontSize: 15,
            //             letterSpacing: 0.3,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
