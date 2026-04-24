part of 'profile_edit_bloc.dart';
enum ProfileEditStatus {
  initial,
  loading,
  success,
  otpSent,
  otpVerified,
  failure
}

class ProfileEditState extends Equatable {
  final ProfileEditStatus status;
  final String name;
  final String email;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final String otp;
  final String errorMessage;
  final bool showErrorMessages;

  const ProfileEditState({
    this.status = ProfileEditStatus.initial,
    this.name = '',
    this.email = '',
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.otp = '',
    this.errorMessage = '',
    this.showErrorMessages = false,
  });

  bool get isNameValid => name.isNotEmpty;
  bool get isEmailValid =>
      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  bool get isCurrentPasswordValid => currentPassword.length >= 6;
  bool get isNewPasswordValid => newPassword.length >= 6;
  bool get isConfirmPasswordValid => confirmPassword == newPassword;
  bool get isOtpValid => otp.length == 6;

  bool get isNameSubmissionValid => isNameValid;
  bool get isEmailSubmissionValid => isEmailValid && isCurrentPasswordValid;
  bool get isPasswordSubmissionValid =>
      isCurrentPasswordValid && isNewPasswordValid && isConfirmPasswordValid;
  bool get isOtpSubmissionValid => isOtpValid;

  ProfileEditState copyWith({
    ProfileEditStatus? status,
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    String? otp,
    String? errorMessage,
    bool? showErrorMessages,
  }) {
    return ProfileEditState(
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      otp: otp ?? this.otp,
      errorMessage: errorMessage ?? this.errorMessage,
      showErrorMessages: showErrorMessages ?? this.showErrorMessages,
    );
  }

  @override
  List<Object> get props => [
        status,
        name,
        email,
        currentPassword,
        newPassword,
        confirmPassword,
        otp,
        errorMessage,
        showErrorMessages,
      ];
}
