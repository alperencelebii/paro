import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(const LanguageState());

  static const String _storageKey = 'app_language';

  Future<void> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final language = AppLanguageX.fromStorage(preferences.getString(_storageKey));
    emit(LanguageState(language: language));
  }

  Future<void> setLanguage(AppLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, language.storageValue);
    emit(LanguageState(language: language));
  }
}
