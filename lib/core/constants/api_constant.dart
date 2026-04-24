import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String? get revenueCatApiKey => _readOptional('REVENUE_CAT_API_KEY');

  static String? get googleClientId => _readOptional('GOOGLE_CLIENT_ID');

  static String? _readOptional(String key) {
    // Check if dotenv is initialized before accessing it
    if (!dotenv.isInitialized) {
      if (kDebugMode) {
        debugPrint('Warning: dotenv is not initialized. Environment variable "$key" cannot be read.');
      }
      return null;
    }

    final value = dotenv.maybeGet(key);
    if (value == null || value.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('Environment variable "$key" is missing or empty.');
      }
      return null;
    }
    return value.trim();
  }
}
