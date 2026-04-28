// ignore_for_file: public_member_api_docs

import 'package:finance_track/core/core.dart';
import 'package:flutter/material.dart';
import 'package:finance_track/core/localization/localization.dart';

class AppInfoSection extends StatelessWidget {
  const AppInfoSection({
    required this.info,
    required this.onPressed,
    required this.buttonLabel,
    super.key,
    this.icon,
  });

  final String info;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LocalizedText(
          info,
          textAlign: TextAlign.center,
          style: context.titleLarge,
        ),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(icon),
                ),
          label: LocalizedText(buttonLabel),
        ),
      ],
    );
  }
}
