import 'dart:async';
import 'package:finance_track/core/auth_debugger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_fields/form_fields.dart';
import 'package:user_repository/user_repository.dart';
part 'signup_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const SignUpState.initial());

  final UserRepository _userRepository;
  Future<void> onSubmit({
    required String email,
    required String password,
    required String userName,
  }) async {
    emit(state.copyWith(submissionStatus: SubmissionStatus.inProgress));
    try {
      await _userRepository.signUpWithPassword(
        email: email,
        password: password,
        username: userName,
      );
      if (isClosed) return;
      emit(state.copyWith(submissionStatus: SubmissionStatus.success));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      final submissionStatus = switch (error) {
        final TimeoutException _ => SubmissionStatus.timeoutError,
        _ => SubmissionStatus.error,
      };
      if (isClosed) return; // Check again before emitting
      emit(state.copyWith(submissionStatus: submissionStatus));
    }
  }

  Future<void> onGoogleLogin() async {
    emit(state.copyWith(submissionStatus: SubmissionStatus.inProgress));
    try {
      // Clear any previous Google sessions if there are issues
      await AuthDebugger.clearGoogleSession();
      await _userRepository.logInWithGoogle();
      emit(state.copyWith(submissionStatus: SubmissionStatus.success));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      final submissionStatus = switch (error) {
        final TimeoutException _ => SubmissionStatus.timeoutError,
        _ => SubmissionStatus.error,
      };
      emit(state.copyWith(submissionStatus: submissionStatus));
    }
  }
}
