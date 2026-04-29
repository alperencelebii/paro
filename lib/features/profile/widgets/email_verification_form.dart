import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/features/profile/profile_edit/bloc/profile_edit_bloc.dart';
import 'package:finance_track/core/localization/localization.dart';

class EmailVerificationForm extends StatefulWidget {
  final String email;

  const EmailVerificationForm({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationForm> createState() => _EmailVerificationFormState();
}

class _EmailVerificationFormState extends State<EmailVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Verify Email'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ProfileEditBloc, ProfileEditState>(
        listener: (context, state) {
          if (state.status == ProfileEditStatus.otpVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: LocalizedText('Email verification successful'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Return to profile screen
          } else if (state.status == ProfileEditStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: LocalizedText(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Icon(
                        Icons.email_outlined,
                        color: const Color(0xFF1D4ED8),
                        size: 80.r,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    LocalizedText('Verify Your Email',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    LocalizedText('We\'ve sent a verification link to ${widget.email}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    LocalizedText('Please click the link in the email to verify your new email address.',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    LocalizedText('For testing purposes, please enter the verification code:',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildOtpField(state),
                    SizedBox(height: 8.h),
                    if (state.showErrorMessages && !state.isOtpValid)
                      _buildErrorText('Please enter a valid verification code'),
                    SizedBox(height: 32.h),
                    _buildVerifyButton(state),
                    SizedBox(height: 16.h),
                    _buildResendButton(state),
                    SizedBox(height: 24.h),
                    _buildHelpText(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpField(ProfileEditState state) {
    return TextFormField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: AppLocalizations.tr('Verification Code'),
        hintText: AppLocalizations.tr('Enter 6-digit code'),
        counterText: '',
        prefixIcon: Icon(
          Icons.security,
          color: const Color(0xFF1D4ED8).withValues(alpha: 0.7),
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
            color: Color(0xFF1D4ED8),
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
        context.read<ProfileEditBloc>().add(ProfileEditOtpChanged(value));
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.tr('Please enter verification code');
        }
        if (value.length != 6) {
          return AppLocalizations.tr('Code must be 6 digits');
        }
        return null;
      },
    );
  }

  Widget _buildErrorText(String message) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 4.h),
      child: LocalizedText(
        message,
        style: TextStyle(
          color: Colors.red[600],
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildVerifyButton(ProfileEditState state) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: state.status == ProfileEditStatus.loading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProfileEditBloc>().add(
                        ProfileEditVerifyOtpSubmitted(_otpController.text),
                      );
                } else {
                  context.read<ProfileEditBloc>().add(
                        ProfileEditOtpChanged(_otpController.text),
                      );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
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
            : LocalizedText('Verify',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton(ProfileEditState state) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: TextButton(
        onPressed: state.status == ProfileEditStatus.loading
            ? null
            : () {
                context.read<ProfileEditBloc>().add(ProfileEditResendOtp());
              },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1D4ED8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: const BorderSide(
              color: Color(0xFF1D4ED8),
              width: 1,
            ),
          ),
        ),
        child: LocalizedText('Resend Verification Link',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                LocalizedText('Important Information',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            LocalizedText('Firebase normally sends verification links by email which users must click to complete verification. The OTP input here is for demonstration purposes.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 8.h),
            LocalizedText('For testing, any 6-digit code will be accepted.',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
