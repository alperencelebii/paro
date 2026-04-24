// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:finance_track/core/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // Check authentication state after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkUpdateThenNavigate();
      }
    });
  }

  Future<void> _checkUpdateThenNavigate() async {
    try {
      // Mandatory update gate. If true, we navigate to update screen and stop flow.
      final intercepted =
          await UpdateService.instance.checkAndNavigateIfRequired(context);
      if (intercepted) return;

      // Continue with first-time and auth navigation
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('first_time_user') ?? true;

      if (!mounted) return;

      final appBloc = context.read<AppBloc>();
      appBloc.add(AppSetFirstTime(isFirstTime: isFirstTime));

      if (isFirstTime) {
        await prefs.setBool('first_time_user', false);
      }

      final isAuthenticated = appBloc.state.status == AppStatus.authenticated;
      if (isAuthenticated) {
        context.go(AppPaths.home);
      } else {
        context.go(AppPaths.landing);
      }
    } catch (e) {
      // In case of errors, fallback to landing page
      if (mounted) {
        context.go(AppPaths.landing);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Finance',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'Track',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
