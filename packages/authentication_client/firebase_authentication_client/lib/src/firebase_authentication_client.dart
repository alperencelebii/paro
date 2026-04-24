// ignore_for_file: inference_failure_on_instance_creation,
// lines_longer_than_80_chars, lines_longer_than_80_chars
// avoid_dynamic_calls
// public_member_api_docs, avoid_dynamic_calls, avoid_dynamic_calls
// deprecated_member_use, deprecated_member_use, deprecated_member_use
// deprecated_member_use
//, duplicate_ignore, avoid_dynamic_calls

import 'dart:async';
import 'dart:developer';

import 'package:authentication_client/authentication_client.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:token_storage/token_storage.dart';

/// {@template firebase_authentication_client}
/// A Firebase implementation of the [AuthenticationClient] interface.
/// {@endtemplate}
class FirebaseAuthenticationClient implements AuthenticationClient {
  /// {@macro firebase_authentication_client}
  FirebaseAuthenticationClient({
    required TokenStorage tokenStorage,
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _tokenStorage = tokenStorage,
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    // Listen to user changes
    user.listen(_onUserChanged);
  }

  final TokenStorage _tokenStorage;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Stream of [AuthenticationUser] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [AuthenticationUser.anonymous] if the user is not authenticated.
  @override
  Stream<AuthenticationUser> get user {
    return _firebaseAuth.userChanges().map((firebaseUser) {
      return firebaseUser == null
          ? AuthenticationUser.anonymous
          : firebaseUser.toUser;
    });
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleCanceled] if the flow is canceled by the user.
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  @override
  Future<void> logInWithGoogle() async {
    try {
      // Clean sign-out on each attempt to prevent issues
      // if (attempts > 1) {
      //   await _signOutCompletely();
      //   await Future.delayed(const Duration(milliseconds: 500));
      // }

      // // Check if we have a current user in Firebase already
      // final firebaseUser = _firebaseAuth.currentUser;
      // if (firebaseUser != null) {
      //   try {
      //     // Check if token is still valid
      //     await firebaseUser.getIdToken(true);
      //     log('User already signed in: ${firebaseUser.email}');
      //     return; // Already signed in
      //   } catch (e) {
      //     // Token refresh failed, continue with sign-in
      //     log('Token refresh failed, proceeding with sign-in: $e');
      //     await _signOutCompletely(); // Clear everything first
      //   }
      // }

      // Try to get silently signed-in user first to avoid repeated prompts
      GoogleSignInAccount? currentUser;
     await  _googleSignIn.disconnect();
      currentUser = await _googleSignIn.authenticate(scopeHint: [
  'email',
  'displayName',
  'photoURL',
  'https://www.googleapis.com/auth/contacts.readonly',]);
      log('Selected Email : ${currentUser.email}');
      log('Retrieved existing Google sign-in: ${currentUser.email}');
      //   // Use a safer timeout for interactive sign-in
      //   try {
      //     currentUser = await _googleSignIn.authenticate().timeout(
      //       const Duration(
      //         seconds: 60,
      //       ), // More generous timeout for release mode
      //       onTimeout: () {
      //         log('Google sign-in timed out');
      //         throw Exception('Sign in with Google timed out');
      //       },
      //     );
      //   } catch (e) {
      //     // Handle specific errors from the sign-in process
      //     if (e.toString().contains('12501') ||
      //         e.toString().toLowerCase().contains('canceled') ||
      //         e.toString().toLowerCase().contains('cancelled')) {
      //       log('Google sign-in was explicitly cancelled by user');
      //       throw LogInWithGoogleCanceled(
      //         Exception('Sign in with Google cancelled by user'),
      //       );
      //     }
      //     rethrow;
      //   }
      // }

      log('Getting Google authentication tokens for: ${currentUser.email}');
      final googleAuth = currentUser.authentication;

      // Verify we have valid tokens before proceeding
      // if (googleAuth.idToken == null) {
      //   log('Google sign-in failed: No ID token returned');

      //   if (attempts < maxAttempts) {
      //     log('Will retry Google sign-in...');
      //     continue;
      //   }

      //   // Clear state and throw
      //   await _signOutCompletely();

      //   throw LogInWithGoogleFailure(
      //     Exception('No ID token returned from Google'),
      //   );
      // }

      log('Creating Firebase credential with Google tokens');
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
//
      );

      // Sign in to Firebase with error handling
      log('Signing in to Firebase with Google credential');
      try {
        final userCredential =
            await _firebaseAuth.signInWithCredential(credential);

        final user = userCredential.user;
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        log('Firebase sign-in successful: ${user?.email}, isNewUser: $isNewUser');
        if (user != null) {
          // Update profile data if needed
          if (isNewUser ||
              user.displayName == null ||
              user.displayName!.isEmpty) {
            log('Updating user profile with Google data');
            try {
              await user.updateProfile(
                
                displayName: currentUser.displayName,
                photoURL: currentUser.photoUrl,
              );
            } catch (profileError) {
              log('Error updating profile, but sign-in successful: $profileError');
            }
          }
        }

        return; // Success
      } catch (firebaseError) {
        log('Firebase credential sign-in error: $firebaseError');

        // Check if user is actually signed in despite error
        final currentFirebaseUser = _firebaseAuth.currentUser;
        if (currentFirebaseUser != null) {
          log('User is signed in despite error: ${currentFirebaseUser.email}');
          return; // Sign-in was actually successful
        }

        // Handle specific error cases
        final errorString = firebaseError.toString().toLowerCase();

        if (errorString.contains('account-exists-with-different-credential')) {
          throw LogInWithGoogleFailure(
            Exception(
              'An account already exists with the same email from a different provider.',
            ),
          );
        } else if (errorString.contains('network')) {
          throw LogInWithGoogleFailure(
            Exception('Network error during sign-in. Check your connection.'),
          );
        }

        // // // Try alternative sign-in method if on last attempt
        // if (attempts >= maxAttempts) {
        //   log('All regular attempts failed, trying alternative method as last resort...');
        //   return _signInWithAlternativeMethod(currentUser);
        // }

        // Else continue to retry
        log('Will retry Google sign-in after error...');
      }
    } catch (e) {
      log('Catch Error $e');
    }

    // // If we get here, all attempts failed
    // throw LogInWithGoogleFailure(
    //   lastError ?? Exception('Multiple Google sign-in attempts failed'),
    // );
  }

  /// Completely sign out from Firebase and Google
  Future<void> _signOutCompletely() async {
    try {
      log('Signing out completely from all services');

      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);

      log('Signed out completely');
    } catch (e) {
      log('Error during complete sign-out: $e');
      // Continue even if sign-out fails
    }
  }

  /// Signs out the current user which will emit
  /// [AuthenticationUser.anonymous] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  @override
  Future<void> logOut() async {
    try {
      await _signOutCompletely();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogOutFailure(error), stackTrace);
    }
  }

  /// Updates current user profile with optional provided [username].
  ///
  /// Throws a [UpdateProfileFailure] if an exception occurs.
  @override
  Future<void> updateProfile({
    String? username,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      await user?.updateDisplayName(username);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(UpdateProfileFailure(error), stackTrace);
    }
  }

  /// Deletes and signs out the user.
  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw DeleteAccountFailure(
          Exception('User is not authenticated'),
        );
      }

      await user.delete();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(DeleteAccountFailure(error), stackTrace);
    }
  }

  /// Updates the user token in [TokenStorage] if the user is authenticated.
  Future<void> _onUserChanged(AuthenticationUser user) async {
    if (!user.isAnonymous) {
      await _tokenStorage.saveToken(user.id);
    } else {
      await _tokenStorage.clearToken();
    }
  }

  @override
  Future<void> logInWithPassword({
    required String password,
    required String email,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      log('Login Success Email : $email');
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(LogInWithPasswordFailure(error), stackTrace);
    }
  }

  @override
  Future<void> signUpWithPassword({
    required String password,
    required String email,
    required String username,
    String? photo,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) throw const SignUpWithPasswordCanceled('User is null');
      await user.updateProfile(
        displayName: username,
        photoURL: photo,
      );
      // Send verification email for email/password signups
      try {
        await user.sendEmailVerification();
      } catch (e) {
        // Non-fatal; UI will provide resend functionality
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(SignUpWithPasswordFailure(error), stackTrace);
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required String password,
  }) async {
    // This method is intentionally disabled
    log('Email update functionality has been disabled');
    throw const UpdateEmailFailure('Email update functionality is disabled');
  }

  /// Facebook sign-in is not supported anymore
  @override
  Future<void> logInWithFacebook() async {
    throw LogInWithFacebookFailure(
      Exception(
        'Facebook authentication has been removed from this application.',
      ),
    );
  }
}

extension on firebase_auth.User {
  AuthenticationUser get toUser {
    return AuthenticationUser(
      id: uid,
      email: email,
      name: displayName,
      photo: photoURL,
      isNewUser: metadata.creationTime == metadata.lastSignInTime,
    );
  }
}

/// Extension to update the user profile
extension UpdateProfile on firebase_auth.User {
  /// Updates the user profile with optional
  ///  provided [displayName] and [photoURL].
  ///
  /// Throws a [UpdateProfileFailure] if an exception occurs.
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    await updateDisplayName(displayName);
    await updatePhotoURL(photoURL);
  }
}
