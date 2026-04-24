import 'package:flutter/material.dart';

/// Custom notification to track bottom sheet visibility
class BottomSheetVisibilityNotification extends Notification {
  /// Whether the bottom sheet is visible
  final bool visible;

  /// Create a new notification with the given visibility state
  const BottomSheetVisibilityNotification(this.visible);
}
