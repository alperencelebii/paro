import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_fields/form_fields.dart';
import 'package:finance_track/features/auth/signup/cubit/signup_cubit.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/auth_field_widget.dart';

class SignupForm extends StatelessWidget {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state.submissionStatus == SubmissionStatus.error) {
          _showErrorDialog(context, 'Error signing up');
        } else if (state.submissionStatus == SubmissionStatus.success) {
          // On success, navigate to verify email screen using GoRouter
          // ignore: use_build_context_synchronously
          GoRouter.of(context).go('/');
        }
      },
      child: const _SignupFormView(),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Error'),
          content: SelectableText.rich(
            TextSpan(
              text: message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }
}

class _SignupFormView extends StatefulWidget {
  const _SignupFormView();

  @override
  State<_SignupFormView> createState() => _SignupFormViewState();
}

class _SignupFormViewState extends State<_SignupFormView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _obscurePassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title & Subtitle in a row to save vertical space
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Track expenses seamlessly',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Icon decoration to balance the layout
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 30.r,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 25.h),

          // Form Fields
          buildInputField(
            context: context,
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 20.r,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              final email = Email.dirty(value);
              return email.valid ? null : 'Please enter a valid email';
            },
          ),
          SizedBox(height: 12.h),

          buildInputField(
            context: context,
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            label: 'Username',
            hint: 'Enter your username',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.person_outline,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 20.r,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),
          SizedBox(height: 12.h),

          // Password Field
          BlocBuilder<SignUpCubit, SignUpState>(
            buildWhen: (previous, current) =>
                previous.password != current.password,
            builder: (context, state) {
              return ValueListenableBuilder(
                valueListenable: _obscurePassword,
                builder: (context, obscurePassword, _) {
                  return buildInputField(
                    context: context,
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    label: 'Password',
                    hint: 'Enter password',
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      size: 20.r,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        size: 20.r,
                      ),
                      onPressed: () {
                        _obscurePassword.value = !_obscurePassword.value;
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      final password = Password.dirty(value);
                      return password.valid ? null : 'Password is too weak';
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 20.h),

          // Signup Button
          BlocBuilder<SignUpCubit, SignUpState>(
            buildWhen: (previous, current) =>
                previous.submissionStatus != current.submissionStatus,
            builder: (context, state) {
              final isSubmitting = state.submissionStatus.isProgress;

              return SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  key: const Key('signupForm_continue_raisedButton'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final email = _emailController.text;
                            final password = _passwordController.text;
                            final userName = _usernameController.text;

                            context.read<SignUpCubit>().onSubmit(
                                  email: email,
                                  password: password,
                                  userName: userName,
                                );
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
