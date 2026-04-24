import 'package:finance_track/features/auth/auth_cubit/auth_cubit.dart';
import 'package:finance_track/features/auth/signup/cubit/signup_cubit.dart';
import 'package:finance_track/features/auth/signup/widgets/signup_footer.dart';
import 'package:finance_track/features/auth/signup/widgets/signup_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:user_repository/user_repository.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
        BlocProvider<SignUpCubit>(
          create: (context) =>
              SignUpCubit(userRepository: context.read<UserRepository>()),
        ),
      ],
      child: const SignupContentPage(),
    );
  }
}

class SignupContentPage extends StatelessWidget {
  const SignupContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top area with app icon - smaller vertical space
                    // Padding(
                    //   padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                    //   child: Icon(
                    //     Icons.account_balance_wallet_rounded,
                    //     size: 40.r,
                    //     color: theme.colorScheme.primary,
                    //   ),
                    // ),

                    SizedBox(height: 16.h),
                    // Signup form with reduced padding
                    const SignupForm(),

                    // Small spacer
                    SizedBox(height: 25.h),
                    // Footer with social logins
                    const SignupFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
