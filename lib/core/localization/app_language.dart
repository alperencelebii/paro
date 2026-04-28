import 'package:flutter/material.dart';

enum AppLanguage {
  system,
  english,
  turkish,
}

extension AppLanguageX on AppLanguage {
  Locale? get locale {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.turkish:
        return const Locale('tr');
    }
  }

  String get storageValue => name;

  static AppLanguage fromStorage(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.system,
    );
  }
}
