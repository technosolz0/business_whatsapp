import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utilities/responsive.dart';
import '../controllers/custom_notifications_controller.dart';
import '../../../common widgets/custom_button.dart';

class CreateCustomNotificationView extends StatefulWidget {
  const CreateCustomNotificationView({super.key});

  @override
  State<CreateCustomNotificationView> createState() =>
      _CreateCustomNotificationViewState();
}

class _CreateCustomNotificationViewState
    extends State<CreateCustomNotificationView> {
  // Access controller via Get.find() since we aren't using GetView anymore directly,
  // or we can mixin. Or just find it.
  final CustomNotificationsController controller = Get.find();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(
          () => Text(
            controller.editingId.value.isEmpty
                ? 'Create Notification'
                : 'Edit Notification',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.offNamed(Routes.CUSTOM_NOTIFICATIONS),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Notification Type'),
                  const SizedBox(height: 8),
                  _buildTypeDropdown(context),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Message'),
                  const SizedBox(height: 8),
                  _buildMessageField(context),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Duration'),
                  const SizedBox(height: 8),
                  _buildDurationField(context),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Get.offNamed(Routes.CUSTOM_NOTIFICATIONS),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Obx(
                        () => CustomButton(
                          label: controller.editingId.value.isEmpty
                              ? 'Create'
                              : 'Update',
                          isLoading: controller.isLoading.value,
                          onPressed: () =>
                              controller.saveNotification(_formKey),
                          type: ButtonType.primary,
                          width: 120,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTypeDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final types = ['Info', 'Important', 'Critical'];

    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[300]!,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedType.value,
            isExpanded: true,
            dropdownColor: isDark ? AppColors.cardDark : Colors.white,
            items: types.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.getTypeColor(type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      type,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                controller.selectedType.value = newValue;
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller.messageController,
      maxLines: 4,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: 'Enter notification message',
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[300]!,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a message';
        }
        return null;
      },
    );
  }

  Widget _buildDurationField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final units = ['Days', 'Hours'];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controller.durationController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Duration',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter value';
              }
              if (int.tryParse(value) == null) {
                return 'Must be number';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedDurationUnit.value,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                  items: units.map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.selectedDurationUnit.value = newValue;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
