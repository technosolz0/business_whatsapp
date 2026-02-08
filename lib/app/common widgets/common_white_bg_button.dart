import 'package:flutter/material.dart';

class CommonWhiteBgButton extends StatelessWidget {
  void Function()? onPressed;
  Widget child;
  Color? borderColor;
  EdgeInsetsGeometry? padding;
  CommonWhiteBgButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor ?? Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: child,
    );
  }
}
