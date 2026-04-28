import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'app_language.dart';

class LanguageState extends Equatable {
  const LanguageState({this.language = AppLanguage.system});

  final AppLanguage language;

  Locale? get locale => language.locale;

  LanguageState copyWith({AppLanguage? language}) {
    return LanguageState(language: language ?? this.language);
  }

  @override
  List<Object?> get props => [language];
}
