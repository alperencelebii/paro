import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/spacing/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Custom snack bar
SnackBar customSnackBar(
  String text, {
  String? solution,
  bool dismissible = true,
  Color color = AppColors.white,
  Duration duration = const Duration(seconds: 4),
  SnackBarBehavior? behavior,
  SnackBarAction? snackBarAction,
  DismissDirection dismissDirection = DismissDirection.down,
}) {
  return SnackBar(
    dismissDirection: dismissible ? dismissDirection : DismissDirection.none,
    action: snackBarAction,
    duration: duration,
    behavior: behavior ?? SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.md + AppSpacing.xs),
    ),
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    content: solution == null
        ? LocalizedText(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          )
        : Column(
            children: [
              LocalizedText(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: color),
              ),
              LocalizedText(
                solution,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.brightGrey, fontSize: 14),
              ),
            ],
          ),
  );
}
