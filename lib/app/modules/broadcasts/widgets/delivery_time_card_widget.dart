import 'package:adminpanel/app/modules/broadcasts/controllers/create_broadcast_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DeliveryTimeCardWidget extends StatelessWidget {
  final CreateBroadcastController controller;

  const DeliveryTimeCardWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Text(
              'Delivery Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // SEND IMMEDIATELY OPTION
                Obx(
                  () => IgnorePointer(
                    ignoring: controller.isPreview,
                    child: InkWell(
                      onTap: () => controller.isPreview
                          ? null
                          : controller.deliveryOption.value = 0,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: controller.deliveryOption.value == 0
                                ? const Color(0xFF137FEC)
                                : isDark
                                ? const Color(0xFF242424)
                                : const Color(0xFFD1D5DB),
                            width: controller.deliveryOption.value == 0 ? 2 : 1,
                          ),
                          color: controller.deliveryOption.value == 0
                              ? const Color(0xFF137FEC).withValues(alpha: 0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 0,
                              groupValue: controller.deliveryOption.value,
                              onChanged: controller.isPreview
                                  ? null
                                  : (value) => controller.deliveryOption.value =
                                        value ?? 0,

                              activeColor: const Color(0xFF137FEC),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Send Immediately',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFFE5E7EB)
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      if (controller.isPreview &&
                                          controller.completedAt.value != null)
                                        Text(
                                          DateFormat('MMM d, y h:mm a').format(
                                            controller.completedAt.value!,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your broadcast will be sent as soon as you confirm.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // SCHEDULE OPTION
                Obx(
                  () => IgnorePointer(
                    ignoring: controller.isPreview,
                    child: InkWell(
                      onTap: () => controller.isPreview
                          ? null
                          : controller.deliveryOption.value = 1,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: controller.deliveryOption.value == 1
                                ? const Color(0xFF137FEC)
                                : isDark
                                ? const Color(0xFF242424)
                                : const Color(0xFFD1D5DB),
                            width: controller.deliveryOption.value == 1 ? 2 : 1,
                          ),
                          color: controller.deliveryOption.value == 1
                              ? const Color(0xFF137FEC).withValues(alpha: 0.05)
                              : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Radio<int>(
                                  value: 1,
                                  groupValue: controller.deliveryOption.value,
                                  onChanged: controller.isPreview
                                      ? null
                                      : (value) =>
                                            controller.deliveryOption.value =
                                                value ?? 1,
                                  activeColor: const Color(0xFF137FEC),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Schedule for a specific time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFFE5E7EB)
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Choose a future date and time for delivery.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // SHOW DATE & TIME PICKERS ONLY IF SCHEDULED
                            if (controller.deliveryOption.value == 1) ...[
                              const SizedBox(height: 16),

                              Padding(
                                padding: const EdgeInsets.only(left: 48),
                                child: Row(
                                  children: [
                                    // DATE PICKER
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Date', isDark),
                                          const SizedBox(height: 4),
                                          Obx(
                                            () => InkWell(
                                              onTap: controller.isPreview
                                                  ? () {}
                                                  : () async {
                                                      final date = await showDatePicker(
                                                        context: context,
                                                        initialDate: controller
                                                            .selectedScheduleTime
                                                            .value,
                                                        firstDate:
                                                            DateTime.now(),
                                                        lastDate: DateTime.now()
                                                            .add(
                                                              const Duration(
                                                                days: 365,
                                                              ),
                                                            ),
                                                      );

                                                      if (date != null) {
                                                        final old = controller
                                                            .selectedScheduleTime
                                                            .value;

                                                        controller
                                                            .selectedScheduleTime
                                                            .value = DateTime(
                                                          date.year,
                                                          date.month,
                                                          date.day,
                                                          old.hour,
                                                          old.minute,
                                                        );
                                                      }
                                                    },
                                              child: _pickerBox(
                                                isDark,
                                                text:
                                                    "${controller.selectedScheduleTime.value.day}/${controller.selectedScheduleTime.value.month}/${controller.selectedScheduleTime.value.year}",
                                                icon: Icons.calendar_today,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // TIME PICKER
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Time', isDark),
                                          const SizedBox(height: 4),
                                          Obx(
                                            () => InkWell(
                                              onTap: controller.isPreview
                                                  ? () {}
                                                  : () async {
                                                      final picked = await showTimePicker(
                                                        context: context,
                                                        initialTime: TimeOfDay(
                                                          hour: controller
                                                              .selectedScheduleTime
                                                              .value
                                                              .hour,
                                                          minute: controller
                                                              .selectedScheduleTime
                                                              .value
                                                              .minute,
                                                        ),
                                                      );

                                                      if (picked != null) {
                                                        final old = controller
                                                            .selectedScheduleTime
                                                            .value;

                                                        controller
                                                            .selectedScheduleTime
                                                            .value = DateTime(
                                                          old.year,
                                                          old.month,
                                                          old.day,
                                                          picked.hour,
                                                          picked.minute,
                                                        );
                                                      }
                                                    },
                                              child: _pickerBox(
                                                isDark,
                                                text: TimeOfDay(
                                                  hour: controller
                                                      .selectedScheduleTime
                                                      .value
                                                      .hour,
                                                  minute: controller
                                                      .selectedScheduleTime
                                                      .value
                                                      .minute,
                                                ).format(context),
                                                icon: Icons.access_time,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      ),
    );
  }

  Widget _pickerBox(
    bool isDark, {
    required String text,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFD1D5DB),
        ),
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
            ),
          ),
          Icon(
            icon,
            size: 16,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}
