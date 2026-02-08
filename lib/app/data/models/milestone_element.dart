import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MilestoneElement {
  final String id;
  final String type; // 'text' or 'image'

  // Position and size
  final Rx<Offset> position;
  final Rx<Size> size;

  // Content
  final RxString content; // for text blocks
  final Rx<Uint8List?> imageBytes; // for image blocks

  // Text styling properties
  final RxString textAlign; // 'left', 'center', 'right'
  final RxString font;
  final RxInt fontSize;
  final Rx<Color> color;
  final RxBool isBold;
  final RxBool isItalic;

  MilestoneElement({
    required this.id,
    required this.type,
    Offset? initialPosition,
    Size? initialSize,
    String? initialContent,
    Uint8List? initialImageBytes,
    String? initialTextAlign,
    String? initialFont,
    int? initialFontSize,
    Color? initialColor,
    bool? initialIsBold,
    bool? initialIsItalic,
  }) : position = Rx<Offset>(initialPosition ?? const Offset(50, 50)),
       size = Rx<Size>(initialSize ?? const Size(200, 100)),
       content = RxString(initialContent ?? 'Double click to edit'),
       imageBytes = Rx<Uint8List?>(initialImageBytes),
       textAlign = RxString(initialTextAlign ?? 'left'),
       font = RxString(initialFont ?? 'Roboto'),
       fontSize = RxInt(initialFontSize ?? 16),
       color = Rx<Color>(initialColor ?? Colors.black),
       isBold = RxBool(initialIsBold ?? false),
       isItalic = RxBool(initialIsItalic ?? false);

  // Helper method to get TextAlign enum
  TextAlign get textAlignEnum {
    switch (textAlign.value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  // Helper method to get FontWeight
  FontWeight get fontWeight =>
      isBold.value ? FontWeight.bold : FontWeight.normal;

  // Helper method to get FontStyle
  FontStyle get fontStyle =>
      isItalic.value ? FontStyle.italic : FontStyle.normal;
}
