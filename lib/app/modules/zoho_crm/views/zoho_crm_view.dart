import 'package:business_whatsapp/app/common%20widgets/common_container.dart';
import 'package:business_whatsapp/app/common%20widgets/common_dropdown_textfield.dart';
import 'package:business_whatsapp/app/common%20widgets/common_outline_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/common%20widgets/common_filled_button.dart';
import 'package:business_whatsapp/app/common%20widgets/common_textfield.dart';
import 'package:business_whatsapp/app/common%20widgets/standard_page_layout.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:business_whatsapp/main.dart';
import '../controllers/zoho_crm_controller.dart';

class ZohoCrmView extends GetView<ZohoCrmController> {
  const ZohoCrmView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return StandardPageLayout(
      title: 'Zoho CRM',
      subtitle: 'Connect and sync your Zoho CRM contacts and leads.',
      showBackButton: true,
      onBack: () => Get.offNamed(Routes.SETTINGS),
      isContentScrollable: true,
      maxWidth: 1800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SvgPicture.asset(
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white : Colors.black,
                          BlendMode.srcIn,
                        ),
                        "assets/icons/chats/zoho.svg",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Zoho CRM Integration",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 48),

                // Info help box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "To get your credentials, visit the Zoho API Console and create a \"Server-based Application\" client.",
                              style: GoogleFonts.publicSans(
                                fontSize: 13,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                launchUrl(
                                  Uri.parse(
                                    "https://www.zoho.com/crm/developer/docs/api/v8/auth-request.html#self-client",
                                  ),
                                );
                              },
                              child: Text(
                                "Detailed setup guide",
                                style: GoogleFonts.publicSans(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SelectableText(
                              "Scopes: ZohoCRM.modules.ALL,ZohoSearch.securesearch.READ,ZohoCRM.settings.ALL,ZohoCRM.bulk.read,ZohoCRM.coql.READ",
                              style: GoogleFonts.publicSans(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                CommonTextfield(
                  label: 'Client ID',
                  isRequired: true,
                  controller: controller.clientIdController,
                  hintText: '1000.XXXX8901XXXX...',
                  prefixIcon: Icon(
                    Icons.vpn_key_outlined,
                    color: textSecondary.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 24),

                CommonTextfield(
                  label: 'Client Secret',
                  isRequired: true,
                  controller: controller.clientSecretController,
                  obscureText: true,
                  hintText: 'secretvalue123',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: textSecondary.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 24),

                Obx(
                  () => CommonDropdownTextfield<String>(
                    label: 'Zoho Data Center',
                    isRequired: true,
                    value: controller.selectedDataCenter.value,
                    items: controller.dataCenters.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    prefixIcon: Icon(
                      Icons.public,
                      color: textSecondary.withOpacity(0.5),
                      size: 20,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.selectedDataCenter.value = newValue;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                CommonTextfield(
                  label: 'Code',
                  isRequired: true,
                  controller: controller.zohoTokenController,
                  obscureText: true,
                  hintText: 'secretvalue123',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: textSecondary.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button & Status Message
                Obx(() {
                  final message = controller.statusMessage.value;
                  final type = controller.statusType.value;
                  final conn = isConnected.value;

                  Color bgColor = Colors.transparent;
                  Color borderColor = Colors.transparent;
                  Color iconColor = Colors.transparent;
                  IconData iconData = Icons.warning_rounded;
                  String displayMessage = message;

                  if (type == SnackType.SUCCESS) {
                    bgColor = const Color(0xFFE8F5E9);
                    borderColor = const Color(0xFFC8E6C9);
                    iconColor = const Color(0xFF4CAF50);
                  } else if (type == SnackType.ERROR ||
                      type == SnackType.INFO) {
                    bgColor = const Color(0xFFFFEBEE);
                    borderColor = const Color(0xFFFFCDD2);
                    iconColor = const Color(0xFFEF5350);
                  }

                  return Row(
                    children: [
                      conn
                          ? CommonFilledButton(
                              onPressed: controller.saveSettings,
                              label: 'Saved',
                              width: 160,
                              isLoading: controller.isLoading.value,
                            )
                          : CommonOutlineButton(
                              onPressed: controller.saveSettings,
                              label: 'Save & Test',
                              width: 160,
                              isLoading: controller.isLoading.value,
                            ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        // Triangle Pointer
                        CustomPaint(
                          size: const Size(10, 10),
                          painter: _TrianglePainter(bgColor, borderColor),
                        ),
                        // Message Bubble
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(iconData, color: iconColor, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                displayMessage,
                                style: GoogleFonts.publicSans(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 16),
                        // Default Connection Badge
                        Container(
                          // decoration: BoxDecoration(
                          //   color: conn ? Colors.green : Colors.red,
                          //   borderRadius: BorderRadius.circular(8),
                          // ),
                          // padding: const EdgeInsets.symmetric(
                          //   horizontal: 12,
                          //   vertical: 8,
                          // ),
                          // child: Text(
                          //   conn ? 'Connected' : 'Not Connected',
                          //   style: GoogleFonts.publicSans(
                          //     fontSize: 14,
                          //     color: Colors.white,
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color bgColor;
  final Color borderColor;

  _TrianglePainter(this.bgColor, this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height);
    // path.close(); // Don't close to avoid border on the right side

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
