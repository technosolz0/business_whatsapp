import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/charges_controller.dart';
import '../../../core/theme/app_colors.dart';

class ChargesView extends GetView<ChargesController> {
  const ChargesView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Charges Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your service charges and fees here.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                // Upload Dropdown Button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'sample') {
                      controller.downloadSampleCharges();
                    } else if (value == 'upload') {
                      controller.uploadCharges();
                    }
                  },
                  offset: const Offset(0, 45),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sample',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text('Sample Download'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'upload',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file, size: 20),
                          SizedBox(width: 8),
                          Text('Upload Charges'),
                        ],
                      ),
                    ),
                  ],
                  child: ElevatedButton.icon(
                    onPressed: null, // PopupMenuButton handles tap
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Download Button
                ElevatedButton.icon(
                  onPressed: () => controller.downloadCharges(),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
