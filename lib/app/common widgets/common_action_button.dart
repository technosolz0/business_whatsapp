import 'package:flutter/material.dart';

class CommonActionButton extends StatelessWidget {
  const CommonActionButton({
    super.key,
    required this.enabled,
    required this.title,
    required this.asset,
    required this.onPressed,
  });
  final bool enabled;
  final String title;
  final String asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: !enabled ? "No $title Access" : title,
      child: IconButton(
        onPressed: !enabled ? null : onPressed,
        icon: Image.asset(
          asset,
          height: 20,
          width: 20,
          fit: BoxFit.cover,
          color: !enabled ? Colors.grey : null,
        ),
      ),
    );
  }
}