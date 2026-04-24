
import 'package:finance_track/features/auth/signup/cubit/signup_cubit.dart';
import 'package:finance_track/features/auth/widgets/social_button_compact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignupFooter extends StatelessWidget {
  const SignupFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider with 'Or' text
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              Expanded(child: Divider(thickness: 1, color: Colors.grey[200])),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'Or',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(thickness: 1, color: Colors.grey[200])),
            ],
          ),
        ),

        // Google button - now fills the full width
        SocialButtonCompact(
          icon: Icons.g_mobiledata,
          iconSize: 24.r,
          text: 'Google',
          iconColor: Colors.red[700]!,
          onPressed: () async {
            context.read<SignUpCubit>().onGoogleLogin();
          },
        ),
      ],
    );
  }
}
