import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/features/profile/profile_edit/bloc/profile_edit_bloc.dart';

class PasswordChangeForm extends StatefulWidget {
  const PasswordChangeForm({super.key});

  @override
  State<PasswordChangeForm> createState() => _PasswordChangeFormState();
}

class _PasswordChangeFormState extends State<PasswordChangeForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ValueNotifier<bool> _obscureCurrentPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obscureNewPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obscureConfirmPassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _obscureCurrentPassword.dispose();
    _obscureNewPassword.dispose();
    _obscureConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileEditBloc, ProfileEditState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Create a new password that is at least 6 characters long.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),
                _buildCurrentPasswordField(state),
                SizedBox(height: 8.h),
                if (state.showErrorMessages && !state.isCurrentPasswordValid)
                  _buildErrorText('Password must be at least 6 characters'),
                SizedBox(height: 16.h),
                _buildNewPasswordField(state),
                SizedBox(height: 8.h),
                if (state.showErrorMessages && !state.isNewPasswordValid)
                  _buildErrorText('New password must be at least 6 characters'),
                SizedBox(height: 16.h),
                _buildConfirmPasswordField(state),
                SizedBox(height: 8.h),
                if (state.showErrorMessages && !state.isConfirmPasswordValid)
                  _buildErrorText('Passwords do not match'),
                SizedBox(height: 32.h),
                _buildUpdateButton(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentPasswordField(ProfileEditState state) {
    return ValueListenableBuilder(
      valueListenable: _obscureCurrentPassword,
      builder: (context, obscure, _) {
        return TextFormField(
          controller: _currentPasswordController,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Current Password',
            hintText: 'Enter your current password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
              size: 20.r,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
              },
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
                size: 20.r,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          onChanged: (value) {
            context.read<ProfileEditBloc>().add(
                  ProfileEditCurrentPasswordChanged(value),
                );
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your current password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildNewPasswordField(ProfileEditState state) {
    return ValueListenableBuilder(
      valueListenable: _obscureNewPassword,
      builder: (context, obscure, _) {
        return TextFormField(
          controller: _newPasswordController,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Enter your new password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
              size: 20.r,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                _obscureNewPassword.value = !_obscureNewPassword.value;
              },
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
                size: 20.r,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          onChanged: (value) {
            context.read<ProfileEditBloc>().add(
                  ProfileEditNewPasswordChanged(value),
                );
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your new password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildConfirmPasswordField(ProfileEditState state) {
    return ValueListenableBuilder(
      valueListenable: _obscureConfirmPassword,
      builder: (context, obscure, _) {
        return TextFormField(
          controller: _confirmPasswordController,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm your new password',
            prefixIcon: Icon(
              Icons.lock_outline,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
              size: 20.r,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
              },
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
                size: 20.r,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          onChanged: (value) {
            context.read<ProfileEditBloc>().add(
                  ProfileEditConfirmPasswordChanged(value),
                );
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your new password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildErrorText(String message) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 4.h),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.red[600],
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildUpdateButton(ProfileEditState state) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: state.status == ProfileEditStatus.loading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProfileEditBloc>().add(
                        ProfileEditPasswordSubmitted(
                          currentPassword: _currentPasswordController.text,
                          newPassword: _newPasswordController.text,
                        ),
                      );
                } else {
                  context.read<ProfileEditBloc>().add(
                        ProfileEditCurrentPasswordChanged(
                          _currentPasswordController.text,
                        ),
                      );
                  context.read<ProfileEditBloc>().add(
                        ProfileEditNewPasswordChanged(
                          _newPasswordController.text,
                        ),
                      );
                  context.read<ProfileEditBloc>().add(
                        ProfileEditConfirmPasswordChanged(
                          _confirmPasswordController.text,
                        ),
                      );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: state.status == ProfileEditStatus.loading
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Update Password',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
