
part of 'profile_edit_bloc.dart';
abstract class ProfileEditEvent extends Equatable {
  const ProfileEditEvent();

  @override
  List<Object?> get props => [];
}

class ProfileEditNameChanged extends ProfileEditEvent {
  final String name;

  const ProfileEditNameChanged(this.name);

  @override
  List<Object> get props => [name];
}

class ProfileEditNameSubmitted extends ProfileEditEvent {
  final String name;

  const ProfileEditNameSubmitted(this.name);

  @override
  List<Object> get props => [name];
}

class ProfileEditEmailChanged extends ProfileEditEvent {
  final String email;

  const ProfileEditEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

class ProfileEditCurrentPasswordChanged extends ProfileEditEvent {
  final String currentPassword;

  const ProfileEditCurrentPasswordChanged(this.currentPassword);

  @override
  List<Object> get props => [currentPassword];
}

class ProfileEditEmailSubmitted extends ProfileEditEvent {
  final String email;
  final String currentPassword;

  const ProfileEditEmailSubmitted({
    required this.email,
    required this.currentPassword,
  });

  @override
  List<Object> get props => [email, currentPassword];
}

class ProfileEditNewPasswordChanged extends ProfileEditEvent {
  final String newPassword;

  const ProfileEditNewPasswordChanged(this.newPassword);

  @override
  List<Object> get props => [newPassword];
}

class ProfileEditConfirmPasswordChanged extends ProfileEditEvent {
  final String confirmPassword;

  const ProfileEditConfirmPasswordChanged(this.confirmPassword);

  @override
  List<Object> get props => [confirmPassword];
}

class ProfileEditPasswordSubmitted extends ProfileEditEvent {
  final String currentPassword;
  final String newPassword;

  const ProfileEditPasswordSubmitted({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}

class ProfileEditVerifyOtpSubmitted extends ProfileEditEvent {
  final String otp;

  const ProfileEditVerifyOtpSubmitted(this.otp);

  @override
  List<Object> get props => [otp];
}

class ProfileEditOtpChanged extends ProfileEditEvent {
  final String otp;

  const ProfileEditOtpChanged(this.otp);

  @override
  List<Object> get props => [otp];
}

class ProfileEditResendOtp extends ProfileEditEvent {}

class ProfileEditReset extends ProfileEditEvent {}
