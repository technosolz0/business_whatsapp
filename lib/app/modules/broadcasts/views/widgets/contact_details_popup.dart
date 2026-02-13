import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_broadcast_controller.dart';

class ContactDetailsPopup extends StatelessWidget {
  final CreateBroadcastController controller;

  const ContactDetailsPopup({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: EdgeInsets.all(28),
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E).withValues(alpha: 0.98)
          : Colors.white.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 720,
        height: 620,
        padding: EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- HEADER ----------------
            Row(
              children: [
                Text(
                  "Contact Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    controller.showSegmentPopup.value = false;
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 18),

            // ---------------- SEARCH BAR ----------------
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: TextField(
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                onChanged: controller.updateDetailSearch,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                  hintText: "Search contacts...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.black54,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            SizedBox(height: 18),

            // ---------------- CONTACT LIST ----------------
            Expanded(
              child: Obx(() {
                final list = controller.contactDetails;

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      "No contacts found",
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey.shade400 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final c = list[index];

                    String f = (c.fName ?? "").trim();
                    String l = (c.lName ?? "").trim();
                    String fullName = "$f $l".trim();
                    if (fullName.isEmpty) fullName = "Unknown User";

                    String initial = f.isNotEmpty ? f[0].toUpperCase() : "U";

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
                        controller.selectedAudience.value == "import"
                            ? c.phoneNumber
                            : fullName,
                        // fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: controller.selectedAudience.value == "import"
                          ? null
                          : Text(
                              c.phoneNumber,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.black54,
                              ),
                            ),
                    );
                  },
                );
              }),
            ),

            SizedBox(height: 10),

            // ---------------- APPLY BUTTON ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.blue.shade400
                        : Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Close",
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
