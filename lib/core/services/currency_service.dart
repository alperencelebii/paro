import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

/// Service for managing currency preferences
class CurrencyService {
  static const String _currencyCodeKey = 'currency_code';

  /// Default currency (Indian Rupee)
  static const Currency defaultCurrency = Currencies.inr;

  /// Get the saved currency from shared preferences
  Future<Currency> getSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_currencyCodeKey);

      if (currencyCode != null) {
        final currency = Currencies.fromCode(currencyCode);
        if (currency != null) {
          return currency;
        }
      }

      // If no currency is saved or the saved currency is invalid, return the default
      return defaultCurrency;
    } catch (e) {
      // In case of any error, return the default currency
      return defaultCurrency;
    }
  }

  /// Save the selected currency to shared preferences
  Future<bool> saveCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_currencyCodeKey, currency.code);
    } catch (e) {
      return false;
    }
  }
}
