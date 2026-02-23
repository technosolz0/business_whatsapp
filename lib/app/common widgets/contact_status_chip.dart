// Predefined chip variants for common use cases
import 'package:business_whatsapp/app/common%20widgets/custom_chip.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  // final bool isActive;
  final IconData? icon;

  const StatusChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      label: label,
      style: label == 'None'
          ? ChipStyle.secondary
          : label == 'Opted-In'
          ? ChipStyle.success
          : ChipStyle.error,
      icon: icon,
    );
  }
}
