import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/features/profile/profile_edit/bloc/profile_edit_bloc.dart';

class EmailChangeForm extends StatefulWidget {
  final String initialEmail;

  const EmailChangeForm({
    super.key,
    required this.initialEmail,
  });

  @override
  State<EmailChangeForm> createState() => _EmailChangeFormState();
}

class _EmailChangeFormState extends State<EmailChangeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
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
                  'Update Email Address',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'You will receive a verification link at your new email address.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),
                _buildEmailField(state),
                SizedBox(height: 8.h),
                if (state.showErrorMessages && !state.isEmailValid)
                  _buildErrorText('Please enter a valid email address'),
                SizedBox(height: 16.h),
                _buildPasswordField(state),
                SizedBox(height: 8.h),
                if (state.showErrorMessages && !state.isCurrentPasswordValid)
                  _buildErrorText('Password must be at least 6 characters'),
                SizedBox(height: 32.h),
                _buildUpdateButton(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailField(ProfileEditState state) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your new email address',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
          size: 20.r,
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
        context.read<ProfileEditBloc>().add(ProfileEditEmailChanged(value));
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+')
            .hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(ProfileEditState state) {
    return ValueListenableBuilder(
      valueListenable: _obscurePassword,
      builder: (context, obscure, _) {
        return TextFormField(
          controller: _passwordController,
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
                _obscurePassword.value = !_obscurePassword.value;
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
                        ProfileEditEmailSubmitted(
                          email: _emailController.text,
                          currentPassword: _passwordController.text,
                        ),
                      );
                } else {
                  context.read<ProfileEditBloc>().add(
                        ProfileEditEmailChanged(_emailController.text),
                      );
                  context.read<ProfileEditBloc>().add(
                        ProfileEditCurrentPasswordChanged(
                          _passwordController.text,
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
                'Update Email',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
