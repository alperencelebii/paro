import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helper class for responsive design using ScreenUtil
class ResponsiveUtils {
  /// Get a responsive font size based on screen width
  static double getFontSize(BuildContext context, double baseSize) {
    return baseSize.sp;
  }

  /// Get responsive padding based on screen width
  static EdgeInsetsGeometry getPadding(BuildContext context,
      {bool horizontal = true}) {
    if (horizontal) {
      return EdgeInsets.symmetric(horizontal: 16.w);
    } else {
      return EdgeInsets.all(16.r);
    }
  }

  /// Check if the device is a small screen
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if the device is a medium screen
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 600;
  }

  /// Check if the device is a large screen
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Get responsive card height
  static double getCardHeight(BuildContext context, double baseHeight) {
    return baseHeight.h;
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    return baseSize.r;
  }

  /// Get text style with responsive font size
  static TextStyle getResponsiveTextStyle(
      BuildContext context, TextStyle? baseStyle,
      {double? sizeFactor = 1.0}) {
    if (baseStyle == null) return const TextStyle();

    double fontSize = baseStyle.fontSize ?? 14.0;
    return baseStyle.copyWith(
      fontSize: (fontSize * (sizeFactor ?? 1.0)).sp,
    );
  }
}
