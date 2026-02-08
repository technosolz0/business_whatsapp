import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'custom_button.dart';

class CommonActionButtons extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final String saveLabel;
  final String cancelLabel;
  final String backLabel;
  final bool showSave;
  final bool showCancel;
  final bool showBack;
  final bool isLoading;
  final bool isMobile;

  const CommonActionButtons({
    super.key,
    this.onSave,
    this.onCancel,
    this.onBack,
    this.saveLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.backLabel = 'Back',
    this.showSave = true,
    this.showCancel = true,
    this.showBack = false,
    this.isLoading = false,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // Back button (if shown)
    if (showBack) {
      children.add(
        CustomButton(
          label: backLabel,
          onPressed: onBack ?? () => Get.back(),
          type: ButtonType.secondary,
        ),
      );
      if (!isMobile) children.add(const SizedBox(width: 12));
    }

    // Cancel button (if shown)
    if (showCancel) {
      children.add(
        // Red outline cancel button
        Container(
          height: 44,
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(cancelLabel),
          ),
        ),
      );
      if (!isMobile) children.add(const SizedBox(width: 12));
    }

    // Save button (if shown)
    if (showSave && onSave != null) {
      children.add(
        CustomButton(
          label: saveLabel,
          onPressed: onSave!,
          type: ButtonType.primary,
          isLoading: isLoading,
        ),
      );
    }

    return isMobile
        ? Column(
            children: children.map((child) {
              if (child is SizedBox) return const SizedBox(height: 12);
              return child;
            }).toList(),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: children,
          );
  }
}
