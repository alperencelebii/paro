import 'package:finance_track/core/app_bloc/app_bloc.dart';
import 'package:finance_track/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../cubit/landing_cubit.dart';
import '../cubit/landing_state.dart';
import 'landing_page1.dart';
import 'landing_page2.dart';
import 'landing_page3.dart';
import 'package:finance_track/core/localization/localization.dart';

/// The main landing screen that hosts the three landing pages
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LandingCubit(),
      child: const _LandingScreenContent(),
    );
  }
}

class _LandingScreenContent extends StatefulWidget {
  const _LandingScreenContent();

  @override
  State<_LandingScreenContent> createState() => _LandingScreenContentState();
}

class _LandingScreenContentState extends State<_LandingScreenContent> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChange);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChange);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChange() {
    if (_pageController.page != null && !_pageController.page!.isNaN) {
      final page = _pageController.page!.round();
      context.read<LandingCubit>().setPage(page);
    }
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() {
    // ONLY change the AppBloc state - this will trigger navigation through the app's router
    context.read<AppBloc>().add(const AppSetFirstTime(isFirstTime: false));
    context.go(AppPaths.auth);
  }

  void _navigateToAuth() {
    // ONLY change the AppBloc state - this will trigger navigation through the app's router
    context.read<AppBloc>().add(const AppSetFirstTime(isFirstTime: false));
    context.go(AppPaths.auth);
  }

  void _getStarted() {
    // ONLY change the AppBloc state - this will trigger navigation through the app's router
    context.read<AppBloc>().add(const AppSetFirstTime(isFirstTime: false));
    context.go(AppPaths.auth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
        body: SafeArea(
      bottom: false, // We'll handle bottom padding in our navigation bar
      child: Stack(
        children: [
          // Gradient overlay for background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.primary.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),

          // Main content - adjusted to leave space for bottom navigation
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: 60.h), // Space for bottom navigation
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      LandingPage1(),
                      LandingPage2(),
                      LandingPage3(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Skip button
          Positioned(
            top: 16.h,
            right: 16.w,
            child: BlocBuilder<LandingCubit, LandingState>(
              builder: (context, state) {
                return AnimatedOpacity(
                  opacity: state.currentPage < 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: state.currentPage < 2
                      ? Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: _skipOnboarding,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LocalizedText('Geç',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12.r,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),

          // Page indicator - positioned above bottom navigation
          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: Center(
              child: BlocBuilder<LandingCubit, LandingState>(
                builder: (context, state) {
                  return _buildPageIndicator(theme, state.currentPage);
                },
              ),
            ),
          ),

          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BlocBuilder<LandingCubit, LandingState>(
              builder: (context, state) {
                return _buildBottomBar(theme, state.currentPage, bottomPadding);
              },
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildPageIndicator(ThemeData theme, int currentPage) {
    return Container(
      height: 20,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: index == currentPage ? 24.w : 10.w,
            height: 10.h,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.r),
              color: index == currentPage
                  ? theme.colorScheme.primary
                  : Colors.white,
              boxShadow: index == currentPage
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(
                duration: 300.ms,
                curve: Curves.easeOutBack,
              );
        }, growable: false),
      ),
    );
  }

  Widget _buildBottomBar(
      ThemeData theme, int currentPage, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left button (Sign In or Back)
          _buildNavigationButton(
            theme: theme,
            isOutlined: true,
            onTap: currentPage == 0
                ? _navigateToAuth
                : () => _navigateToPage(currentPage - 1),
            icon: currentPage == 0
                ? Icons.login_rounded
                : Icons.arrow_back_rounded,
            label: currentPage == 0 ? 'Giriş Yap' : 'Geri',
            flex: 1,
          ),

          SizedBox(width: 12.w),

          // Right button (Next, Continue, or Get Started)
          _buildNavigationButton(
            theme: theme,
            isOutlined: false,
            onTap: currentPage == 2
                ? _getStarted
                : () => _navigateToPage(currentPage + 1),
            icon: currentPage == 2
                ? Icons.rocket_launch_rounded
                : Icons.arrow_forward_rounded,
            label: currentPage == 0
                ? 'Sonraki'
                : currentPage == 1
                    ? 'Devam Et'
                    : 'Başlayın',
            color: currentPage == 2
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
            flex: 2,
            showIconAtEnd: true,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuint,
        );
  }

  Widget _buildNavigationButton({
    required ThemeData theme,
    required bool isOutlined,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    Color? color,
    int flex = 1,
    bool showIconAtEnd = false,
  }) {
    final buttonColor = color ?? theme.colorScheme.primary;

    return Expanded(
      flex: flex,
      child: SizedBox(
        height: 40.h,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOutlined ? Colors.white : buttonColor,
            foregroundColor: isOutlined ? buttonColor : Colors.white,
            elevation: isOutlined ? 1 : 4,
            shadowColor: buttonColor.withValues(alpha: 0.5),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: isOutlined
                  ? BorderSide(color: buttonColor, width: 1.5)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!showIconAtEnd) ...[
                Icon(
                  icon,
                  size: 16.r,
                ),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: LocalizedText(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              if (showIconAtEnd) ...[
                SizedBox(width: 6.w),
                Icon(
                  icon,
                  size: 16.r,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
