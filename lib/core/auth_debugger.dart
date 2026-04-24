import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Utility class to debug authentication issues
class AuthDebugger {
  /// Test Google Sign-in
  static Future<void> testGoogleSignIn() async {
    try {
      log('Starting Google Sign-in test...');

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Force sign out to avoid cached sessions
      await googleSignIn.signOut();
      log('Cleared previous Google session');

      // Check if already signed in after forced sign out (should be null)
      final GoogleSignInAccount currentUser = await googleSignIn.authenticate();
      log('Current Google user after sign out: ${currentUser.email}');

      // Try to sign in
      log('Attempting Google sign-in...');
      final GoogleSignInAccount account = await googleSignIn.authenticate();

      log('Google sign-in successful with email: ${account.email}');
      log('Display name: ${account.displayName}');
      log('User ID: ${account.id}');
      log('Photo URL: ${account.photoUrl ?? 'None'}');

      // Get auth tokens
      log('Getting auth tokens...');
      final GoogleSignInAuthentication auth = account.authentication;
      log('Access token received: ${auth.idToken != null}');
      log('ID token received: ${auth.idToken != null}');

      // Create Firebase credential
      log('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.idToken,
        idToken: auth.idToken,
      );

      // Sign in to Firebase
      log('Signing in to Firebase...');
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      log('Firebase sign-in successful with user: ${userCredential.user?.email}');
      log('Is new user: ${userCredential.additionalUserInfo?.isNewUser ?? false}');
      log('Provider ID: ${userCredential.additionalUserInfo?.providerId ?? 'Unknown'}');
    } catch (e, stackTrace) {
      log('Exception during Google sign-in: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Clear Google Sign-in session
  static Future<void> clearGoogleSession() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      log('Google session cleared');
    } catch (e) {
      log('Error clearing Google session: $e');
    }
  }

  /// Deep clean of all auth state
  static Future<void> deepCleanAuthState() async {
    try {
      log('Starting deep clean of authentication state');

      // Clear Google session
      await clearGoogleSession();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear persistence if possible
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.NONE);
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (e) {
        log('Error resetting Firebase persistence: $e');
      }

      log('Deep clean of authentication state completed');
    } catch (e) {
      log('Error during deep clean: $e');
    }
  }

  /// Test Firebase Auth status
  static void checkFirebaseAuthStatus() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      log('Current Firebase user: ${currentUser?.email ?? 'None (Not signed in)'}');

      if (currentUser != null) {
        log('User ID: ${currentUser.uid}');
        log('Email verified: ${currentUser.emailVerified}');
        log('Provider data: ${currentUser.providerData.map((p) => p.providerId).join(', ')}');
        log('Display name: ${currentUser.displayName ?? 'Not set'}');
        log('Photo URL: ${currentUser.photoURL ?? 'Not set'}');
        log('Creation time: ${currentUser.metadata.creationTime}');
        log('Last sign in time: ${currentUser.metadata.lastSignInTime}');
        log('Is anonymous: ${currentUser.isAnonymous}');
      }
    } catch (e) {
      log('Error checking Firebase auth status: $e');
    }
  }

  /// Handle the common PigeonUserDetails error
  static Future<bool> handlePigeonUserDetailsError() async {
    try {
      log('Checking if user is signed in despite PigeonUserDetails error...');

      // Check if user is actually signed in despite the error
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        log('User is signed in despite PigeonUserDetails error: ${user.email}');

        // Force token refresh to ensure authentication state is correctly updated
        try {
          await user.getIdToken(true);
          log('Successfully refreshed user token');
          return true;
        } catch (tokenError) {
          log('Error refreshing token: $tokenError');

          // Try deeper cleanup if token refresh fails
          await deepCleanAuthState();
        }
      } else {
        log('No user is signed in after PigeonUserDetails error');
      }
      return false;
    } catch (e) {
      log('Error handling PigeonUserDetails error: $e');
      return false;
    }
  }
}

/// Firebase Core class for checking initialization status
class FirebaseCore {
  static bool get isInitialized {
    try {
      // Access Firebase.app() will throw if not initialized
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
}
