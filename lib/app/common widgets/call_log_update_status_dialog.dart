// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_dropdown_textfield.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_table.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
// import 'package:business_whatsapp/app/modules/call_log/controllers/call_log_controller.dart';
// import 'package:business_whatsapp/app/modules/call_log/models/call_log_models.dart';
// import 'package:business_whatsapp/app/utilities/extensions.dart';

// class CallLogUpdateStatusDialog extends StatelessWidget {
//   CallLogUpdateStatusDialog({
//     super.key,
//     required this.onTapSubmit,
//     required this.callLog,
//   });
//   final VoidCallback onTapSubmit;
//   final CallLogModel callLog;

//   CallLogController controller = Get.find<CallLogController>();
//   RxBool loading = false.obs;

//   @override
//   Widget build(BuildContext context) {
//     // Auto-select latest status from history
//     if (callLog.statusHistory != null && callLog.statusHistory!.isNotEmpty) {
//       // Sort descending by updatedDate
//       List<StatusHistory> sorted = callLog.statusHistory!.toList()
//         ..sort((a, b) {
//           DateTime? da = a.updatedDate;
//           DateTime? db = b.updatedDate;

//           if (da == null && db == null) return 0;
//           if (da == null) return 1;
//           if (db == null) return -1;
//           return db.compareTo(da);
//         });

//       // Take most recent
//       final latest = sorted.first;
//       controller.selectedStatusForUpdate.value = latest.statusType ?? "";
//     }

//     final List<List<dynamic>> historyRows = callLog.statusHistory != null
//         ? (callLog.statusHistory!.toList()..sort((a, b) {
//                 DateTime? da = a.updatedDate;
//                 DateTime? db = b.updatedDate;

//                 if (da == null && db == null) return 0;
//                 if (da == null) return 1; // null = older → bottom
//                 if (db == null) return -1;

//                 return db.compareTo(da); // ✅ latest first
//               }))
//               .map<List<dynamic>>((item) {
//                 return [
//                   item.updatedDate == null
//                       ? '--'
//                       : DateFormat('dd-MMM-yyyy').format(item.updatedDate!),
//                   item.statusType == null || item.statusType!.isEmpty
//                       ? '--'
//                       : item.statusType,
//                   item.engineerRemarks == null || item.engineerRemarks!.isEmpty
//                       ? '--'
//                       : item.engineerRemarks,
//                   item.clientRemarks == null || item.clientRemarks!.isEmpty
//                       ? '--'
//                       : item.clientRemarks,
//                 ];
//               })
//               .toList()
//         : <List<dynamic>>[];

//     return Dialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: Get.context!.screenType() == ScreenType.Desktop
//               ? 1100
//               : Get.context!.screenType() == ScreenType.Tablet
//               ? 650
//               : 300,
//           maxHeight: context.height * 0.8,
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Get.context!.screenType() == ScreenType.Desktop
//                 ? Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Title
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Update Status",
//                             style: GoogleFonts.publicSans(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w600,
//                               color: const Color(0xFF000000),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close, color: Colors.red),
//                             onPressed: () => Navigator.of(context).pop(),
//                           ),
//                         ],
//                       ),
//                       const Divider(height: 20), SizedBox(height: 15),
//                       Row(
//                         children: [
//                           Flexible(
//                             child: CommonDropdownTextfield<String>(
//                               label: "Status",
//                               isRequired: true,
//                               items: controller.allStatuses
//                                   .map(
//                                     (e) => DropdownMenuItem<String>(
//                                       value: e,
//                                       child: Text(e),
//                                     ),
//                                   )
//                                   .toList(),
//                               initialValue:
//                                   controller
//                                       .selectedStatusForUpdate
//                                       .value
//                                       .isEmpty
//                                   ? null
//                                   : controller.selectedStatusForUpdate.value,
//                               onChanged: (value) {
//                                 controller.selectedStatusForUpdate.value =
//                                     value ?? '';
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(
//                             flex: 3,
//                             child: CommonTextfield(
//                               label: "Remarks",
//                               isRequired: true,
//                               hintText: "Enter Here",
//                               controller: controller.remarksController,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 40),
//                       SizedBox(
//                         height: 50,
//                         width: 130,
//                         child: Obx(
//                           () => CommonFilledButton(
//                             onPressed: onTapSubmit,
//                             filledColor: AppColors.primary,
//                             child: controller.filterLoading.value
//                                 ? Padding(
//                                     padding: EdgeInsets.zero,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white,
//                                     ),
//                                   )
//                                 : Text(
//                                     'Submit',
//                                     style: GoogleFonts.publicSans(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 30),
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Color(0xFFDDE3E8)),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(height: 15),
//                             Padding(
//                               padding: EdgeInsets.only(left: 20),
//                               child: Text(
//                                 'Status History',
//                                 style: GoogleFonts.publicSans(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w600,
//                                   color: const Color(0xFF000000),
//                                 ),
//                               ),
//                             ),
//                             const Divider(height: 20, color: Color(0xFFDDE3E8)),
//                             CustomTable(
//                               isStatusTable: true,
//                               showTableContents: false,
//                               columns: controller.statusHistoryColumnList,
//                               dataRowMinHeight: 50,
//                               dataRowMaxHeight: double.infinity,
//                               rows: historyRows,
//                               childrens: [
//                                 (child, i) => Text(
//                                   child.toString(),
//                                   style: GoogleFonts.publicSans(
//                                     fontSize: 16,
//                                     color: Color(0xFF656772),
//                                   ),
//                                 ),
//                                 (child, i) => Text(
//                                   child.toString(),
//                                   style: GoogleFonts.publicSans(
//                                     fontSize: 16,
//                                     color: Color(0xFF656772),
//                                   ),
//                                 ),
//                                 (child, i) => ConstrainedBox(
//                                   constraints: BoxConstraints(maxWidth: 200),
//                                   child: Padding(
//                                     padding: EdgeInsetsGeometry.symmetric(
//                                       vertical: 5,
//                                     ),
//                                     child: Text(
//                                       child.toString(),
//                                       style: GoogleFonts.publicSans(
//                                         fontSize: 16,
//                                         color: Color(0xFF656772),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 (child, i) => ConstrainedBox(
//                                   constraints: BoxConstraints(maxWidth: 200),
//                                   child: Padding(
//                                     padding: EdgeInsetsGeometry.symmetric(
//                                       vertical: 5,
//                                     ),
//                                     child: Text(
//                                       child.toString(),
//                                       style: GoogleFonts.publicSans(
//                                         fontSize: 16,
//                                         color: Color(0xFF656772),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                               searchByOptions: [],
//                               onClickedPrevPage: () {},
//                               onClickedNextPage: () {},
//                               columnSpacing:
//                                   context.screenType() == ScreenType.Desktop
//                                   ? 30
//                                   : context.screenType() == ScreenType.Tablet
//                                   ? 40
//                                   : 60,
//                               listInfo: '',
//                               showLoading: loading,
//                               showPaginationButtons: false,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   )
//                 : Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Update Status",
//                             style: GoogleFonts.publicSans(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w600,
//                               color: const Color(0xFF000000),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close, color: Colors.red),
//                             onPressed: () => Navigator.of(context).pop(),
//                           ),
//                         ],
//                       ),
//                       const Divider(height: 20),
//                       SizedBox(height: 15),
//                       CommonDropdownTextfield<String>(
//                         label: "Status",
//                         items: controller.allStatuses
//                             .map(
//                               (e) => DropdownMenuItem<String>(
//                                 value: e,
//                                 child: Text(e),
//                               ),
//                             )
//                             .toList(),
//                         initialValue:
//                             controller.selectedStatusForUpdate.value.isEmpty
//                             ? null
//                             : controller.selectedStatusForUpdate.value,
//                         onChanged: (value) {
//                           controller.selectedStatusForUpdate.value =
//                               value ?? '';
//                         },
//                       ),
//                       SizedBox(height: 15),
//                       CommonTextfield(
//                         maxLines: 3,
//                         label: "Remarks",
//                         hintText: "Enter Here",
//                         controller: controller.remarksController,
//                       ),
//                       SizedBox(height: 30),
//                       SizedBox(
//                         height: 50,
//                         width: 130,
//                         child: Obx(
//                           () => CommonFilledButton(
//                             onPressed: onTapSubmit,
//                             filledColor: AppColors.primary,
//                             child: controller.filterLoading.value
//                                 ? Padding(
//                                     padding: EdgeInsets.zero,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white,
//                                     ),
//                                   )
//                                 : Text(
//                                     'Submit',
//                                     style: GoogleFonts.publicSans(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 30),
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Color(0xFFDDE3E8)),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(height: 15),
//                             Padding(
//                               padding: EdgeInsets.only(left: 20),
//                               child: Text(
//                                 'Status History',
//                                 style: GoogleFonts.publicSans(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w600,
//                                   color: const Color(0xFF000000),
//                                 ),
//                               ),
//                             ),
//                             const Divider(height: 20, color: Color(0xFFDDE3E8)),
//                             CustomTable(
//                               isStatusTable: true,
//                               showTableContents: false,
//                               columns: controller.statusHistoryColumnList,
//                               dataRowMinHeight: 50,
//                               dataRowMaxHeight: double.infinity,
//                               rows: historyRows,
//                               childrens: [
//                                 (child, i) => Text(
//                                   child.toString(),
//                                   style: GoogleFonts.publicSans(
//                                     fontSize: 16,
//                                     color: Color(0xFF656772),
//                                   ),
//                                 ),
//                                 (child, i) => Text(
//                                   child.toString(),
//                                   style: GoogleFonts.publicSans(
//                                     fontSize: 16,
//                                     color: Color(0xFF656772),
//                                   ),
//                                 ),
//                                 (child, i) => ConstrainedBox(
//                                   constraints: BoxConstraints(maxWidth: 200),
//                                   child: Padding(
//                                     padding: EdgeInsetsGeometry.symmetric(
//                                       vertical: 5,
//                                     ),
//                                     child: Text(
//                                       child.toString(),
//                                       style: GoogleFonts.publicSans(
//                                         fontSize: 16,
//                                         color: Color(0xFF656772),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 (child, i) => ConstrainedBox(
//                                   constraints: BoxConstraints(maxWidth: 200),
//                                   child: Padding(
//                                     padding: EdgeInsetsGeometry.symmetric(
//                                       vertical: 5,
//                                     ),
//                                     child: Text(
//                                       child.toString(),
//                                       style: GoogleFonts.publicSans(
//                                         fontSize: 16,
//                                         color: Color(0xFF656772),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                               searchByOptions: [],
//                               onClickedPrevPage: () {},
//                               onClickedNextPage: () {},
//                               columnSpacing:
//                                   context.screenType() == ScreenType.Desktop
//                                   ? 30
//                                   : context.screenType() == ScreenType.Tablet
//                                   ? 20
//                                   : 20,
//                               listInfo: '',
//                               showLoading: loading,
//                               showPaginationButtons: false,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     );
//   }
// }
