import 'dart:developer';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Utility class to debug Facebook Auth issues
class FacebookAuthDebugger {
  /// Test Facebook login and print detailed errors
  static Future<void> testFacebookLogin() async {
    try {
      log('Starting Facebook login test...');

      // Check if FacebookAuth is properly initialized
      final instance = FacebookAuth.instance;
      log('Facebook Auth instance created');

      // Try to get current access token (if any)
      final AccessToken? currentToken = await instance.accessToken;
      log('Current access token: ${currentToken?.tokenString ?? 'None'}');

      // Try the login flow
      log('Attempting login...');
      final LoginResult result = await instance.login();

      // Process result
      switch (result.status) {
        case LoginStatus.success:
          log('Login successful');
          log('Access token: ${result.accessToken?.tokenString}');

          // Get user data
          final userData = await instance.getUserData();
          log('User data: $userData');
          break;

        case LoginStatus.cancelled:
          log('Login cancelled by user');
          break;

        case LoginStatus.failed:
          log('Login failed with message: ${result.message}');
          break;

        case LoginStatus.operationInProgress:
          log('Login operation already in progress');
          break;
      }
    } catch (e, stackTrace) {
      log('Exception during Facebook login: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Log out and clear Facebook session
  static Future<void> clearFacebookSession() async {
    try {
      await FacebookAuth.instance.logOut();
      log('Facebook session cleared');
    } catch (e) {
      log('Error clearing Facebook session: $e');
    }
  }
}
