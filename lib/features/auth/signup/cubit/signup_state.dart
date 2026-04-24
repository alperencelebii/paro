part of 'signup_cubit.dart';

enum SubmissionStatus {
  idle,
  inProgress,
  success,
  timeoutError,
  error;

  bool get isProgress => this == inProgress;
  bool get isSuccess => this == success;
  bool get isTimeoutError => this == SubmissionStatus.timeoutError;
  bool get isError => this == SubmissionStatus.error;
}

class SignUpState {
  const SignUpState._({
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.submissionStatus = SubmissionStatus.idle,
  });

  const SignUpState.initial() : this._();

  final Email email;
  final Password password;
  final SubmissionStatus submissionStatus;

  SignUpState copyWith({
    Email? email,
    Password? password,
    SubmissionStatus? submissionStatus,
  }) {
    return SignUpState._(
      email: email ?? this.email,
      password: password ?? this.password,
      submissionStatus: submissionStatus ?? this.submissionStatus,
    );
  }
}
