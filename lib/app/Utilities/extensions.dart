import 'package:flutter/material.dart';

enum CustomScreenType { Phone, Tablet, Desktop, Watch }

extension CustomSizeExtension on BuildContext {
  CustomScreenType screenType() {
    double width = MediaQuery.sizeOf(this).width;

    if (width >= 1024) {
      return CustomScreenType.Desktop;
    } else if (width >= 768) {
      return CustomScreenType.Tablet;
    } else if (width < 480) {
      return CustomScreenType.Watch;
    } else {
      return CustomScreenType.Phone;
    }
  }
}
