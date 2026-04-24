import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Button style for landing page buttons
enum LandingButtonStyle {
  primary,
  secondary,
  outline,
}

/// A reusable button for the landing pages
class LandingButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final LandingButtonStyle style;
  final double width;
  final double height;
  final bool isFullWidth;
  final IconData? icon;

  const LandingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = LandingButtonStyle.primary,
    this.width = 180,
    this.height = 54,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Button styling based on type
    ButtonStyle buttonStyle;
    switch (style) {
      case LandingButtonStyle.primary:
        buttonStyle = ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
        );
        break;
      case LandingButtonStyle.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
        );
        break;
      case LandingButtonStyle.outline:
        buttonStyle = ElevatedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
        );
        break;
    }

    final buttonWidget = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20.r),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : width.w,
      height: height.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: buttonWidget,
      ),
    );
  }
}
