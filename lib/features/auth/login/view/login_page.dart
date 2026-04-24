import 'package:finance_track/features/auth/auth_cubit/auth_cubit.dart';
import 'package:finance_track/features/auth/login/cubit/login_cubit.dart';
import 'package:finance_track/features/auth/login/widgets/login_footer.dart';
import 'package:finance_track/features/auth/login/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:user_repository/user_repository.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginCubit>(
          create: (context) => LoginCubit(
            userRepository: context.read<UserRepository>(),
          ),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
      ],
      child: const LoginContentPage(),
    );
  }
}

class LoginContentPage extends StatelessWidget {
  const LoginContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
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
                    // Login form with reduced padding
                    const LoginForm(),

                    // Small spacer
                    SizedBox(height: 25.h),

                    // Footer with social logins
                    const LoginFooter(),
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
