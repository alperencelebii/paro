// ignore_for_file: public_member_api_docs

import 'package:finance_track/core/colors/app_colors.dart';
import 'package:finance_track/core/constants/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:finance_track/core/localization/localization.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar(
    String text, {
    bool dismissible = true,
    Color color = AppColors.white,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior? behavior,
    SnackBarAction? snackBarAction,
    String? solution,
    DismissDirection dismissDirection = DismissDirection.down,
  }) =>
      ScaffoldMessenger.of(this)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: LocalizedText(
              text,
              style: const TextStyle().copyWith(color: AppColors.black),
            ),
            action: snackBarAction,
            behavior: behavior,
            backgroundColor: color,
            dismissDirection: dismissDirection,
            duration: duration,
          ),
          // customSnackBar(
          //   text,
          //   behavior: behavior,
          //   color: color,
          //   dismissDirection: dismissDirection,
          //   dismissible: dismissible,
          //   duration: duration,
          //   snackBarAction: snackBarAction,
          //   solution: solution,
          // ),
        );

  void showUndismissableSnackBar(
    String text, {
    String? solution,
    Color color = AppColors.white,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..clearSnackBars()
      ..showSnackBar(
        customSnackBar(
          text,
          behavior: SnackBarBehavior.floating,
          color: color,
          duration: const Duration(days: 1),
          snackBarAction: action,
          dismissible: false,
          solution: solution,
        ),
      );
  }

  void closeSnackBars() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }
}
