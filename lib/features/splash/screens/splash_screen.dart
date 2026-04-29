// ignore_for_file: use_build_context_synchronously

import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/colors/app_colors.dart';
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

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkUpdateThenNavigate();
      }
    });
  }

  Future<void> _checkUpdateThenNavigate() async {
    try {
      final intercepted =
          await UpdateService.instance.checkAndNavigateIfRequired(context);
      if (intercepted) return;

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

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.darkBackground,
            ],
          ),
        ),
        child: Center(
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
                        width: 132,
                        height: 132,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.20),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/images/paro_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'PARO Cüzdan',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gelir, gider ve bütçe takibi',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
