import 'package:flutter/material.dart';

class AdaptiveLayout {
  const AdaptiveLayout._();

  static bool useSideNavigation(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height && size.height < 600;
  }

  static double bottomContentPadding(BuildContext context) {
    return useSideNavigation(context) ? 18 : 96;
  }
}
