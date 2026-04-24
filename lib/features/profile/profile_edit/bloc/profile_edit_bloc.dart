// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_repository/user_repository.dart' as user_repo;

part 'profile_edit_event.dart';
part 'profile_edit_state.dart';

class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  final FirebaseAuth _firebaseAuth;

  ProfileEditBloc({
    required user_repo.UserRepository userRepository,
    FirebaseAuth? firebaseAuth,
  })  : 
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const ProfileEditState()) {
    on<ProfileEditNameChanged>(_onNameChanged);
    on<ProfileEditNameSubmitted>(_onNameSubmitted);
    on<ProfileEditEmailChanged>(_onEmailChanged);
    on<ProfileEditCurrentPasswordChanged>(_onCurrentPasswordChanged);
    on<ProfileEditEmailSubmitted>(_onEmailSubmitted);
    on<ProfileEditNewPasswordChanged>(_onNewPasswordChanged);
    on<ProfileEditConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<ProfileEditPasswordSubmitted>(_onPasswordSubmitted);
    on<ProfileEditOtpChanged>(_onOtpChanged);
    on<ProfileEditVerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<ProfileEditResendOtp>(_onResendOtp);
    on<ProfileEditReset>(_onReset);
  }

  void _onNameChanged(
    ProfileEditNameChanged event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(state.copyWith(
      name: event.name,
      status: ProfileEditStatus.initial,
      errorMessage: '',
    ));
  }

  Future<void> _onNameSubmitted(
    ProfileEditNameSubmitted event,
    Emitter<ProfileEditState> emit,
  ) async {
    // Don't proceed if name is invalid
    if (!state.isNameSubmissionValid) {
      return emit(state.copyWith(showErrorMessages: true));
    }

    // Show loading state
    emit(state.copyWith(
      status: ProfileEditStatus.loading,
      errorMessage: '',
    ));

    try {
      // Get current user
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Try to update name - returns true if it succeeded
      final nameUpdated = await _updateUserDisplayName(user, event.name);

      // If name update succeeded
      if (nameUpdated) {
        // Force a refresh of the user data
        await _refreshUserData();

        // Emit success state with the new name
        emit(state.copyWith(
          status: ProfileEditStatus.success,
          name: event.name,
          errorMessage: '',
        ));
        return;
      } else {
        // If name update failed but didn't throw an exception
        throw Exception('Failed to update display name');
      }
    } catch (e) {
      log('Error in name update process: $e');

      // If error contains PigeonUserInfo, the operation actually succeeded
      // despite the error - this is a known Firebase SDK issue
      if (e.toString().contains('PigeonUserInfo')) {
        log('PigeonUserInfo error but name likely updated successfully');

        // Force a refresh to ensure the UI shows the updated name
        await _refreshUserData();

        // This is treated as a success
        emit(state.copyWith(
          status: ProfileEditStatus.success,
          name: event.name,
          errorMessage: '',
        ));
      } else {
        // For any other error, emit failure state
        emit(state.copyWith(
          status: ProfileEditStatus.failure,
          errorMessage: _formatErrorMessage(e),
        ));
      }
    }
  }

  // Helper method to update display name with better error handling
  // Returns true if the name was updated successfully
  Future<bool> _updateUserDisplayName(User user, String name) async {
    try {
      // Store initial name to check if update succeeded
      final initialName = user.displayName;
      log('Attempting to update name from "$initialName" to "$name"');

      // Try to update the name - this calls the native Firebase SDK directly
      bool nameUpdated = false;
      Exception? capturedError;

      // APPROACH 1: Try native Firebase update method
      try {
        // This is the most direct method but can cause PigeonUserInfo error
        await _firebaseAuth.currentUser?.updateDisplayName(name);
        log('Name update API call succeeded');
        nameUpdated = true;
      } catch (e) {
        capturedError = e is Exception ? e : Exception(e.toString());
        log('Native update method failed: $e');

        // If it's PigeonUserInfo error, name might have been updated anyway
        if (e.toString().contains('PigeonUserInfo')) {
          log('PigeonUserInfo error encountered - will check if name updated anyway');
        }
      }

      // Check if name was actually updated regardless of error
      await user.reload();
      final currentName = _firebaseAuth.currentUser?.displayName;

      if (currentName == name) {
        log('Verified name was updated to: $currentName');
        return true;
      } else {
        log('Name NOT updated. Current name: $currentName');

        // APPROACH 2: If first method failed, try updateProfile
        if (!nameUpdated) {
          try {
            log('Trying alternative updateProfile method');
            await user.updateProfile(displayName: name);
            log('updateProfile method succeeded');

            // Verify the update
            await user.reload();
            final updatedName = _firebaseAuth.currentUser?.displayName;

            if (updatedName == name) {
              log('Name update confirmed: $updatedName');
              return true;
            } else {
              log('Name still not updated after updateProfile. Current: $updatedName');
            }
          } catch (e) {
            log('updateProfile method failed: $e');

            // Final check - even though this threw an error, did the name update?
            await user.reload();
            if (_firebaseAuth.currentUser?.displayName == name) {
              log('Name was updated despite errors in updateProfile');
              return true;
            }
          }
        }

        // Handle special cases where methods fail but name is updated
        if (capturedError != null &&
            capturedError.toString().contains('PigeonUserInfo')) {
          // For PigeonUserInfo errors, treat as success if name appears to have changed at all
          if (currentName != initialName) {
            log('Name was partially updated despite PigeonUserInfo error');
            return true;
          }
        }

        // If we get here, both methods failed to update the name
        return false;
      }
    } catch (e) {
      log('Unexpected error in _updateUserDisplayName: $e');
      return false;
    }
  }

  // Helper method to format error messages for user display
  String _formatErrorMessage(dynamic error) {
    // Handle the special PigeonUserInfo error case
    final String errorString = error.toString();
    if (errorString.contains('PigeonUserInfo')) {
      // This is not really an error - the update worked
      return 'Success! Your profile has been updated.';
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        // Authentication errors
        case 'wrong-password':
          return 'Incorrect password provided';
        case 'user-not-found':
          return 'User not found';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many requests. Try again later';
        case 'operation-not-allowed':
          return 'This operation is not allowed';
        case 'invalid-email':
          return 'Invalid email format';
        case 'email-already-in-use':
          return 'Email is already in use by another account';

        // Password errors
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password';

        // Authorization errors
        case 'requires-recent-login':
          return 'Please log in again to update your profile';

        // Network errors
        case 'network-request-failed':
          return 'Network error. Please check your connection';

        // Default case
        default:
          return error.message != null && error.message.toString().isNotEmpty
              ? 'Authentication error: ${error.message}'
              : 'An authentication error occurred';
      }
    }

    // Handle general exception types
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('PigeonUserInfo')) {
        return 'Success! Your profile has been updated.';
      }

      return message.length > 100 ? '${message.substring(0, 100)}...' : message;
    }

    // Convert to string but limit length for other error types
    final message = error.toString();
    return message.length > 100 ? '${message.substring(0, 100)}...' : message;
  }

  void _onEmailChanged(
    ProfileEditEmailChanged event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(state.copyWith(
      email: event.email,
      status: ProfileEditStatus.initial,
      errorMessage: '',
    ));
  }

  void _onCurrentPasswordChanged(
    ProfileEditCurrentPasswordChanged event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(state.copyWith(
      currentPassword: event.currentPassword,
      status: ProfileEditStatus.initial,
      errorMessage: '',
    ));
  }

  Future<void> _onEmailSubmitted(
    ProfileEditEmailSubmitted event,
    Emitter<ProfileEditState> emit,
  ) async {
    if (!state.isEmailSubmissionValid) {
      return emit(state.copyWith(showErrorMessages: true));
    }

    emit(state.copyWith(status: ProfileEditStatus.loading));

    try {
      // Reauthenticate the user to verify their current password
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Create credential with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: event.currentPassword,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);

      // Send email verification before update
      await user.verifyBeforeUpdateEmail(event.email);

      emit(state.copyWith(
        status: ProfileEditStatus.otpSent,
        email: event.email,
      ));
    } on FirebaseAuthException catch (e) {
      log('Firebase auth error updating email: $e');
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: _formatErrorMessage(e),
      ));
    } catch (e) {
      log('Error updating email: $e');
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: _formatErrorMessage(e),
      ));
    }
  }

  void _onNewPasswordChanged(
    ProfileEditNewPasswordChanged event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(state.copyWith(
      newPassword: event.newPassword,
      status: ProfileEditStatus.initial,
      errorMessage: '',
    ));
  }

  void _onConfirmPasswordChanged(
    ProfileEditConfirmPasswordChanged event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(state.copyWith(
      confirmPassword: event.confirmPassword,
      status: ProfileEditStatus.initial,
      errorMessage: '',
    ));
  }

  Future<void> _onPasswordSubmitted(
    ProfileEditPasswordSubmitted event,
    Emitter<ProfileEditState> emit,
  ) async {
    if (!state.isPasswordSubmissionValid) {
      return emit(state.copyWith(showErrorMessages: true));
    }

    emit(state.copyWith(status: ProfileEditStatus.loading));

    try {
      // Get current user
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Create credential with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: event.currentPassword,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(event.newPassword);

      // Refresh user data to update the app state
      await _refreshUserData();

      emit(state.copyWith(
        status: ProfileEditStatus.success,
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      ));
    } on FirebaseAuthException catch (e) {
      log('Firebase auth error updating password: $e');
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: _formatErrorMessage(e),
      ));
    } catch (e) {
      log('Error updating password: $e');
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: _formatErrorMessage(e),
      ));
    }
  }

  void _onOtpChanged(
    ProfileEditOtpChanged event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(state.copyWith(
      otp: event.otp,
      status: ProfileEditStatus.otpSent,
      errorMessage: '',
    ));
  }

  Future<void> _onVerifyOtpSubmitted(
    ProfileEditVerifyOtpSubmitted event,
    Emitter<ProfileEditState> emit,
  ) async {
    if (!state.isOtpSubmissionValid) {
      return emit(state.copyWith(showErrorMessages: true));
    }

    emit(state.copyWith(status: ProfileEditStatus.loading));

    try {
      // Note: Firebase handles email verification via email link
      // This is a placeholder for OTP verification flow
      // For Firebase email verification, users click on email links
      // We can check if email is verified after they confirm via email

      // For now, we'll simulate OTP verification success
      // Refresh user data to update the app state
      await _refreshUserData();

      emit(state.copyWith(
        status: ProfileEditStatus.otpVerified,
        otp: '',
      ));
    } catch (e) {
      log('Error verifying OTP: $e');
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: 'Failed to verify OTP: ${e.toString()}',
      ));
    }
  }

  Future<void> _onResendOtp(
    ProfileEditResendOtp event,
    Emitter<ProfileEditState> emit,
  ) async {
    emit(state.copyWith(status: ProfileEditStatus.loading));

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Resend email verification
      await user.verifyBeforeUpdateEmail(state.email);

      emit(state.copyWith(
        status: ProfileEditStatus.otpSent,
        errorMessage: '',
      ));
    } catch (e) {
      log('Error resending OTP: $e');
      emit(state.copyWith(
        status: ProfileEditStatus.failure,
        errorMessage: 'Failed to resend verification email: ${e.toString()}',
      ));
    }
  }

  void _onReset(
    ProfileEditReset event,
    Emitter<ProfileEditState> emit,
  ) {
    emit(const ProfileEditState());
  }

  /// Utility method to manually refresh user data
  Future<void> _refreshUserData() async {
    try {
      // Force Firebase Auth to reload the user
      await _firebaseAuth.currentUser?.reload();

      // This should trigger a user stream change in Firebase Auth
      // which will flow through to the UserRepository and then to AppBloc

      // As a backup, we can manually trigger an AppBloc update
      // by dispatching an AppUpdateAccountRequested event if needed
    } catch (e) {
      log('Error refreshing user data: $e');
    }
  }
}
