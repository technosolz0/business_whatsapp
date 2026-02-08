// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_dropdown_textfield.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
// import 'package:business_whatsapp/app/common%20widgets/common_white_bg_button.dart';
// import 'package:business_whatsapp/app/modules/call_log/controllers/call_log_controller.dart';
// import 'package:business_whatsapp/app/utilities/extensions.dart';

// class CallLogFilterDialog extends StatelessWidget {
//   CallLogFilterDialog({super.key, required this.onTapSubmit});
//   final VoidCallback onTapSubmit;

//   CallLogController controller = Get.find<CallLogController>();

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: Get.context!.screenType() == ScreenType.Desktop
//               ? 900
//               : Get.context!.screenType() == ScreenType.Tablet
//               ? 500
//               : 300,
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
//                             "Filters",
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
//                               label: "Client Name",
//                               items: controller.allClients
//                                   .map(
//                                     (e) => DropdownMenuItem<String>(
//                                       value: e.clientName,
//                                       child: Text(e.clientName ?? ''),
//                                     ),
//                                   )
//                                   .toList(),
//                               initialValue:
//                                   controller.selectedClient.value.isEmpty
//                                   ? null
//                                   : controller.selectedClient.value,
//                               onChanged: (value) {
//                                 controller.selectedClient.value = value ?? '';
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(
//                             child: CommonDropdownTextfield(
//                               label: "Engineer Name",
//                               items: controller.allEngineers
//                                   .map(
//                                     (e) => DropdownMenuItem<String>(
//                                       value: "${e.firstName} ${e.lastName}",
//                                       child: Text(
//                                         "${e.firstName} ${e.lastName}",
//                                       ),
//                                     ),
//                                   )
//                                   .toList(),
//                               initialValue:
//                                   controller.selectedEngineer.value.isEmpty
//                                   ? null
//                                   : controller.selectedEngineer.value,
//                               onChanged: (value) {
//                                 controller.selectedEngineer.value = value ?? '';
//                               },
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(
//                             child: CommonDropdownTextfield(
//                               label: "Status",
//                               items: controller.allStatuses
//                                   .map(
//                                     (e) => DropdownMenuItem<String>(
//                                       value: e,
//                                       child: Text(e.toString()),
//                                     ),
//                                   )
//                                   .toList(),
//                               initialValue:
//                                   controller
//                                       .selectedStatusForFilter
//                                       .value
//                                       .isEmpty
//                                   ? null
//                                   : controller.selectedStatusForFilter.value,
//                               onChanged: (value) {
//                                 controller.selectedStatusForFilter.value =
//                                     value ?? '';
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 15),
//                       const Divider(height: 20),
//                       Text(
//                         "Creation Date",
//                         style: GoogleFonts.publicSans(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 18,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Flexible(
//                             flex: 2,
//                             child: CommonTextfield(
//                               label: "From Date",
//                               hintText: 'DD-MMM-YYYY',
//                               readOnly: true,
//                               textInputAction: TextInputAction.next,
//                               controller: controller.creationFromDateController,
//                               onTap: () {
//                                 controller.pickDate(
//                                   context,
//                                   controller.creationFromDate,
//                                   controller.creationFromDateController,
//                                 );
//                               },
//                               suffixIcon: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Image.asset(
//                                   'assets/icons/calendar_icon.png',
//                                   height: 21,
//                                   width: 21,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(
//                             flex: 2,
//                             child: CommonTextfield(
//                               label: "To Date",
//                               hintText: 'DD-MMM-YYYY',
//                               readOnly: true,
//                               textInputAction: TextInputAction.next,
//                               controller: controller.creationToDateController,
//                               onTap: () {
//                                 controller.pickDate(
//                                   context,
//                                   controller.creationToDate,
//                                   controller.creationToDateController,
//                                 );
//                               },
//                               suffixIcon: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Image.asset(
//                                   'assets/icons/calendar_icon.png',
//                                   height: 21,
//                                   width: 21,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(flex: 2, child: SizedBox()),
//                         ],
//                       ),
//                       SizedBox(height: 15),
//                       const Divider(height: 20),
//                       Text(
//                         "Execution Date",
//                         style: GoogleFonts.publicSans(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 18,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Flexible(
//                             flex: 2,
//                             child: CommonTextfield(
//                               label: "From Date",
//                               hintText: 'DD-MMM-YYYY',
//                               readOnly: true,
//                               textInputAction: TextInputAction.next,
//                               controller:
//                                   controller.executionFromDateController,
//                               onTap: () {
//                                 controller.pickDate(
//                                   context,
//                                   controller.executionFromDate,
//                                   controller.executionFromDateController,
//                                 );
//                               },
//                               suffixIcon: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Image.asset(
//                                   'assets/icons/calendar_icon.png',
//                                   height: 21,
//                                   width: 21,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(
//                             flex: 2,
//                             child: CommonTextfield(
//                               label: "To Date",
//                               hintText: 'DD-MMM-YYYY',
//                               readOnly: true,
//                               textInputAction: TextInputAction.next,
//                               controller: controller.executionToDateController,
//                               onTap: () {
//                                 controller.pickDate(
//                                   context,
//                                   controller.executionToDate,
//                                   controller.executionToDateController,
//                                 );
//                               },
//                               suffixIcon: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Image.asset(
//                                   'assets/icons/calendar_icon.png',
//                                   height: 21,
//                                   width: 21,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           Flexible(flex: 2, child: SizedBox()),
//                         ],
//                       ),
//                       SizedBox(height: 40),
//                       Row(
//                         children: [
//                           SizedBox(
//                             height: 50,
//                             width: 130,
//                             child: CommonFilledButton(
//                               onPressed: onTapSubmit,
//                               filledColor: AppColors.primary,
//                               child: Text(
//                                 'Submit',
//                                 style: GoogleFonts.publicSans(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 20),
//                           SizedBox(
//                             height: 50,
//                             width: 110,
//                             child: CommonWhiteBgButton(
//                               onPressed: () {
//                                 controller.resetFilters();
//                               },
//                               borderColor: AppColors.primary,
//                               child: Text(
//                                 'Reset',
//                                 style: GoogleFonts.publicSans(
//                                   color: AppColors.primary,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
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
//                             "Filters",
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
//                       CommonDropdownTextfield(
//                         label: "Client Name",
//                         items: controller.allClients
//                             .map(
//                               (e) => DropdownMenuItem<String>(
//                                 value: e.clientName,
//                                 child: Text(e.clientName ?? ''),
//                               ),
//                             )
//                             .toList(),
//                         initialValue: controller.selectedClient.value.isEmpty
//                             ? null
//                             : controller.selectedClient.value,
//                         onChanged: (value) {
//                           controller.selectedClient.value = value ?? '';
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       CommonDropdownTextfield(
//                         label: "Engineer Name",
//                         items: controller.allEngineers
//                             .map(
//                               (e) => DropdownMenuItem<String>(
//                                 value: "${e.firstName} ${e.lastName}",
//                                 child: Text("${e.firstName} ${e.lastName}"),
//                               ),
//                             )
//                             .toList(),
//                         initialValue: controller.selectedEngineer.value.isEmpty
//                             ? null
//                             : controller.selectedEngineer.value,
//                         onChanged: (value) {
//                           controller.selectedEngineer.value = value ?? '';
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       CommonDropdownTextfield(
//                         label: "Status",
//                         items: controller.allStatuses
//                             .map(
//                               (e) => DropdownMenuItem<String>(
//                                 value: e,
//                                 child: Text(e.toString()),
//                               ),
//                             )
//                             .toList(),
//                         initialValue:
//                             controller.selectedStatusForFilter.value.isEmpty
//                             ? null
//                             : controller.selectedStatusForFilter.value,
//                         onChanged: (value) {
//                           controller.selectedStatusForFilter.value =
//                               value ?? '';
//                         },
//                       ),
//                       SizedBox(height: 15),
//                       const Divider(height: 20),
//                       Text(
//                         "Creation Date",
//                         style: GoogleFonts.publicSans(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 18,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       CommonTextfield(
//                         label: "From Date",
//                         hintText: 'DD-MMM-YYYY',
//                         readOnly: true,
//                         textInputAction: TextInputAction.next,
//                         controller: controller.creationFromDateController,
//                         onTap: () {
//                           controller.pickDate(
//                             context,
//                             controller.creationFromDate,
//                             controller.creationFromDateController,
//                           );
//                         },
//                         suffixIcon: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.asset(
//                             'assets/icons/calendar_icon.png',
//                             height: 21,
//                             width: 21,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       CommonTextfield(
//                         label: "To Date",
//                         hintText: 'DD-MMM-YYYY',
//                         readOnly: true,
//                         textInputAction: TextInputAction.next,
//                         controller: controller.creationToDateController,
//                         onTap: () {
//                           controller.pickDate(
//                             context,
//                             controller.creationToDate,
//                             controller.creationToDateController,
//                           );
//                         },
//                         suffixIcon: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.asset(
//                             'assets/icons/calendar_icon.png',
//                             height: 21,
//                             width: 21,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       const Divider(height: 20),
//                       Text(
//                         "Execution Date",
//                         style: GoogleFonts.publicSans(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 18,
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       CommonTextfield(
//                         label: "From Date",
//                         hintText: 'DD-MMM-YYYY',
//                         readOnly: true,
//                         textInputAction: TextInputAction.next,
//                         controller: controller.executionFromDateController,
//                         onTap: () {
//                           controller.pickDate(
//                             context,
//                             controller.executionFromDate,
//                             controller.executionFromDateController,
//                           );
//                         },
//                         suffixIcon: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.asset(
//                             'assets/icons/calendar_icon.png',
//                             height: 21,
//                             width: 21,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       CommonTextfield(
//                         label: "To Date",
//                         hintText: 'DD-MMM-YYYY',
//                         readOnly: true,
//                         textInputAction: TextInputAction.next,
//                         controller: controller.executionToDateController,
//                         onTap: () {
//                           controller.pickDate(
//                             context,
//                             controller.executionToDate,
//                             controller.executionToDateController,
//                           );
//                         },
//                         suffixIcon: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Image.asset(
//                             'assets/icons/calendar_icon.png',
//                             height: 21,
//                             width: 21,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 40),
//                       SizedBox(
//                         height: 40,
//                         width: double.infinity,
//                         child: CommonFilledButton(
//                           onPressed: onTapSubmit,
//                           filledColor: AppColors.primary,
//                           child: Text(
//                             'Submit',
//                             style: GoogleFonts.publicSans(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 15),
//                       SizedBox(
//                         height: 40,
//                         width: double.infinity,
//                         child: CommonWhiteBgButton(
//                           onPressed: () {
//                             controller.resetFilters();
//                           },
//                           borderColor: AppColors.primary,
//                           child: Text(
//                             'Reset',
//                             style: GoogleFonts.publicSans(
//                               color: AppColors.primary,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
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
