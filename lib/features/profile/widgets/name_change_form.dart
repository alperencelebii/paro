// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/features/profile/profile_edit/bloc/profile_edit_bloc.dart';

class NameChangeForm extends StatefulWidget {
  final String initialName;

  const NameChangeForm({
    super.key,
    required this.initialName,
  });

  @override
  State<NameChangeForm> createState() => _NameChangeFormState();
}

class _NameChangeFormState extends State<NameChangeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileEditBloc, ProfileEditState>(
      listener: (context, state) {
        if (!mounted) return;

        // Handle success or PigeonUserInfo "error" (which is actually success)
        if (state.status == ProfileEditStatus.success ||
            (state.status == ProfileEditStatus.failure &&
                state.errorMessage.contains('Success'))) {
          // Update app state with new name through AppBloc
          context.read<AppBloc>().add(
                AppUpdateAccountRequested(username: _nameController.text),
              );

          // Show success message before navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // Navigate back to profile page
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
        // Handle real error cases
        else if (state.status == ProfileEditStatus.failure &&
            !state.errorMessage.contains('Success')) {
          // Show user-friendly error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Display Name',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'This name will be visible to others in the app.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),
                _buildNameField(state),
                SizedBox(height: 8.h),
                if (state.showErrorMessages && !state.isNameValid)
                  _buildErrorText('Please enter a valid name'),
                SizedBox(height: 32.h),
                _buildUpdateButton(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameField(ProfileEditState state) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Display Name',
        hintText: 'Enter your display name',
        prefixIcon: Icon(
          Icons.person_outline,
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
        context.read<ProfileEditBloc>().add(ProfileEditNameChanged(value));
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
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
                  // Only update if name has changed
                  if (_nameController.text != widget.initialName) {
                    context.read<ProfileEditBloc>().add(
                          ProfileEditNameSubmitted(_nameController.text),
                        );
                  } else {
                    // Show message that no changes were made
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No changes were made to your name'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } else {
                  context.read<ProfileEditBloc>().add(
                        ProfileEditNameChanged(_nameController.text),
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
                'Update Name',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
