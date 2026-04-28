import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_language.dart';
import 'app_localizations.dart';
import 'language_cubit.dart';
import 'language_state.dart';
import 'package:finance_track/core/localization/localization.dart';

String languageLabel(AppLanguage language) {
  switch (language) {
    case AppLanguage.system:
      return AppLocalizations.tr('System Default');
    case AppLanguage.english:
      return AppLocalizations.tr('English');
    case AppLanguage.turkish:
      return AppLocalizations.tr('Turkish');
  }
}

Future<void> showLanguageSelectionDialog(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    AppLocalizations.tr('Language'),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...AppLanguage.values.map(
                    (language) => RadioListTile<AppLanguage>(
                      value: language,
                      groupValue: state.language,
                      title: LocalizedText(languageLabel(language)),
                      onChanged: (value) async {
                        if (value == null) return;
                        await context.read<LanguageCubit>().setLanguage(value);
                        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
