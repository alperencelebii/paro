import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_fields/form_fields.dart';
import 'package:finance_track/features/auth/login/cubit/login_cubit.dart';

import '../../widgets/auth_field_widget.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _obscurePassword = ValueNotifier<bool>(true);
  final _rememberMe = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    _rememberMe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoginFormContent(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      emailFocusNode: _emailFocusNode,
      passwordFocusNode: _passwordFocusNode,
      obscurePassword: _obscurePassword,
      rememberMe: _rememberMe,
    );
  }
}

class _LoginFormContent extends StatelessWidget {
  const _LoginFormContent({
    required GlobalKey<FormState> formKey,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required FocusNode emailFocusNode,
    required FocusNode passwordFocusNode,
    required ValueNotifier<bool> obscurePassword,
    required ValueNotifier<bool> rememberMe,
  })  : _formKey = formKey,
        _emailController = emailController,
        _passwordController = passwordController,
        _emailFocusNode = emailFocusNode,
        _passwordFocusNode = passwordFocusNode,
        _obscurePassword = obscurePassword,
        _rememberMe = rememberMe;

  final GlobalKey<FormState> _formKey;
  final TextEditingController _emailController;
  final TextEditingController _passwordController;
  final FocusNode _emailFocusNode;
  final FocusNode _passwordFocusNode;
  final ValueNotifier<bool> _obscurePassword;
  final ValueNotifier<bool> _rememberMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<LoginCubit>().state;
    final isLoading = state.submissionStatus.isProgress;
    final hasError =
        state.submissionStatus.isError || state.submissionStatus.isTimeoutError;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign In',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Subtitle
                    Text(
                      'Continue to your account',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
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

          // Email Field
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
              return email.errorMessage;
            },
          ),
          SizedBox(height: 12.h),

          // Password Field
          ValueListenableBuilder(
            valueListenable: _obscurePassword,
            builder: (context, obscure, _) {
              return buildInputField(
                context: context,
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Password',
                hint: 'Enter your password',
                obscureText: obscure,
                textInputAction: TextInputAction.done,
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    size: 20.r,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  final password = Password.dirty(value);
                  return password.errorMessage;
                },
              );
            },
          ),

          // Error message
          if (hasError)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                state.submissionStatus.isTimeoutError
                    ? 'Connection timeout. Please try again.'
                    : 'Invalid email or password. Please try again.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),

          SizedBox(height: 12.h),

          // Remember me & Forgot Password
          Row(
            children: [
              ValueListenableBuilder(
                valueListenable: _rememberMe,
                builder: (context, remember, _) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: Checkbox(
                          value: remember,
                          onChanged: (value) {
                            _rememberMe.value = value ?? false;
                          },
                          activeColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Remember me',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  //
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Login Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            onPressed: isLoading
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      context
                          .read<LoginCubit>()
                          .onSubmit(email: email, password: password);
                    }
                  },
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Log In',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

//   Widget buildInputField({
//     required BuildContext context,
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     TextInputType? keyboardType,
//     TextInputAction? textInputAction,
//     bool obscureText = false,
//     Widget? suffixIcon,
//     required String? Function(String?) validator,
//   }) {
//     final theme = Theme.of(context);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           label,
//           style: theme.textTheme.bodySmall?.copyWith(
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         SizedBox(height: 4.h),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           textInputAction: textInputAction,
//           obscureText: obscureText,
//           style: theme.textTheme.bodyMedium,
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(color: Colors.black38),
//             suffixIcon: suffixIcon,
//             filled: true,
//             fillColor: Colors.grey[50],
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8.r),
//               borderSide: BorderSide(color: Colors.grey[200]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8.r),
//               borderSide: BorderSide(color: Colors.grey[200]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8.r),
//               borderSide: BorderSide(
//                 color: theme.colorScheme.primary,
//                 width: 1.5,
//               ),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8.r),
//               borderSide: BorderSide(
//                 color: theme.colorScheme.error,
//                 width: 1,
//               ),
//             ),
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: 12.w,
//               vertical: 12.h,
//             ),
//             isDense: true,
//           ),
//           validator: validator,
//         ),
//       ],
//     );
//   }
//
}
